import type { D1Database } from '@cloudflare/workers-types';
import { parseLanguageLocaleCode } from './languageIdentity';
import { dictionaryReleaseSchemaAvailable, edgeEligibilityPredicate, releaseObjectEligibilityPredicate } from './dictionaryReleaseEligibility';

export type IdentityKind = 'language' | 'locale';

export interface LocalizedNameRequest {
  kind: IdentityKind;
  langCode: string;
  identityCode: string;
}

export interface LocalizedNameResult {
  lang_code: string;
  name: string;
  name_en: string;
  resolved_from: 'primary' | 'secondary' | 'fallback';
}

export interface LocaleHints {
  primary?: string;
  secondary?: string;
}

interface IdentityRow {
  code: string;
  name_expression_id: string | null;
  name_en: string;
  name: string | null;
}

interface CandidateRow {
  source_id: string;
  target_id: string;
  target_text: string;
  score: number;
  created_at: string;
}

// Language-level names must not fall back to one of the language's regional locales.
const LANGUAGE_NAME_OVERRIDES: Record<string, Record<string, string>> = {
  cmn: { 'cmn-Hant-TW': '華語', 'cmn-Hans-CN': '普通话' },
  nan: { 'cmn-Hant-TW': '閩南語', 'cmn-Hans-CN': '闽南语' },
  wuu: { 'cmn-Hant-TW': '吳語', 'cmn-Hans-CN': '吴语' },
  yue: { 'cmn-Hant-TW': '粵語', 'cmn-Hans-CN': '粤语' },
  zha: { 'cmn-Hant-TW': '壯語', 'cmn-Hans-CN': '壮语' },
};

const IDENTITY_LANGUAGE_SQL =
  'SELECT code, name_expression_id, name_en, (SELECT l.name FROM language_locales l WHERE l.lang_code = languages.code ORDER BY l.code ASC LIMIT 1) AS name FROM languages WHERE code IN (SELECT value FROM json_each(?))';
const IDENTITY_LOCALE_SQL =
  'SELECT code, name_expression_id, name_en, name FROM language_locales WHERE code IN (SELECT value FROM json_each(?))';
const LOCALE_LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';
export const CANDIDATE_SQL = `WITH candidate_rows AS (
  SELECT src.id AS source_id, t.id AS target_id, t.text AS target_text, e.score, e.created_at
  FROM expression_edges e
  JOIN expressions src ON src.id = e.expression_a_id
  JOIN expressions t ON t.id = e.expression_b_id
  WHERE e.expression_a_id IN (SELECT value FROM json_each(?))
    AND e.score >= 0
    AND t.lang_code = ?
    AND EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = t.id AND a.language_locale_code = ?)
  UNION ALL
  SELECT src.id AS source_id, t.id AS target_id, t.text AS target_text, e.score, e.created_at
  FROM expression_edges e
  JOIN expressions src ON src.id = e.expression_b_id
  JOIN expressions t ON t.id = e.expression_a_id
  WHERE e.expression_b_id IN (SELECT value FROM json_each(?))
    AND e.score >= 0
    AND t.lang_code = ?
    AND EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = t.id AND a.language_locale_code = ?)
), ranked AS (
  SELECT candidate_rows.*, ROW_NUMBER() OVER (
    PARTITION BY source_id
    ORDER BY score DESC, created_at ASC, target_id ASC
  ) AS candidate_rank
  FROM candidate_rows
)
SELECT source_id, target_id, target_text, score, created_at
FROM ranked
WHERE candidate_rank = 1
ORDER BY source_id ASC, score DESC, created_at ASC, target_id ASC`;

export function parseLocaleHints(primary: string | undefined, secondary: string | undefined): LocaleHints {
  const cleaned = (value: string | undefined): string | undefined => {
    const trimmed = value?.trim() ?? '';
    return trimmed && parseLanguageLocaleCode(trimmed) ? trimmed : undefined;
  };
  const primaryCleaned = cleaned(primary);
  const secondaryCleaned = cleaned(secondary);
  return {
    primary: primaryCleaned,
    secondary: secondaryCleaned && secondaryCleaned !== primaryCleaned ? secondaryCleaned : undefined,
  };
}

function parseLocaleCodes(hints: LocaleHints): string[] {
  const seen = new Set<string>();
  const codes: string[] = [];
  for (const value of [hints.primary, hints.secondary]) {
    if (!value) continue;
    if (!parseLanguageLocaleCode(value) || seen.has(value)) continue;
    seen.add(value);
    codes.push(value);
  }
  return codes;
}

async function loadIdentities(db: D1Database, requests: readonly LocalizedNameRequest[]): Promise<Map<string, IdentityRow>> {
  const languageCodes = [...new Set(requests.filter((r) => r.kind === 'language').map((r) => r.identityCode))];
  const localeCodes = [...new Set(requests.filter((r) => r.kind === 'locale').map((r) => r.identityCode))];
  const identities = new Map<string, IdentityRow>();
  if (languageCodes.length > 0) {
    const { results } = await db.prepare(IDENTITY_LANGUAGE_SQL).bind(JSON.stringify(languageCodes)).all<IdentityRow>();
    for (const row of results) identities.set(row.code, row);
  }
  if (localeCodes.length > 0) {
    const { results } = await db.prepare(IDENTITY_LOCALE_SQL).bind(JSON.stringify(localeCodes)).all<IdentityRow>();
    for (const row of results) identities.set(row.code, row);
  }
  return identities;
}

async function loadLocaleLangCodes(db: D1Database, localeCodes: readonly string[]): Promise<Map<string, string>> {
  const rows = await Promise.all(localeCodes.map(async (localeCode) => ({
    localeCode,
    row: await db.prepare(LOCALE_LANG_SQL).bind(localeCode).first<{ lang_code: string }>(),
  })));
  const langCodes = new Map<string, string>();
  for (const { localeCode, row } of rows) if (row) langCodes.set(localeCode, row.lang_code);
  return langCodes;
}

async function loadCandidateMap(
  db: D1Database,
  sourceIds: readonly string[],
  langCode: string,
  localeCode: string,
): Promise<Map<string, string>> {
  if (sourceIds.length === 0 || !langCode) return new Map();
  const bindings = [JSON.stringify(sourceIds), langCode, localeCode, JSON.stringify(sourceIds), langCode, localeCode];
  const releaseTablesReady = await dictionaryReleaseSchemaAvailable(db);
  const candidateSql = releaseTablesReady
    ? CANDIDATE_SQL
      .replaceAll('    AND e.score >= 0', `    AND ${edgeEligibilityPredicate('e')}\n    AND e.score >= 0`)
      .replaceAll('AND a.language_locale_code = ?)', `AND a.language_locale_code = ? AND ${releaseObjectEligibilityPredicate('locale_attestation', 'a.id')})`)
    : CANDIDATE_SQL;
  const { results } = await db.prepare(candidateSql).bind(...bindings).all<CandidateRow>();
  const selected = new Map<string, string>();
  for (const row of results) {
    if (selected.has(row.source_id)) continue;
    selected.set(row.source_id, row.target_text);
  }
  return selected;
}

const EXPRESSIONS_SQL = 'SELECT id, text FROM expressions WHERE id IN (SELECT value FROM json_each(?))';

interface ExpressionNameResolution {
  name: string;
  name_en: string;
  resolved_from: 'primary' | 'secondary' | 'fallback';
}

async function resolveExpressionDisplayNames(
  db: D1Database,
  ids: readonly string[],
  hints: LocaleHints,
): Promise<Map<string, ExpressionNameResolution>> {
  const results = new Map<string, ExpressionNameResolution>();
  const distinct = [...new Set(ids.filter(Boolean))];
  if (distinct.length === 0) return results;
  const localeCodes = parseLocaleCodes(hints);

  const [expressionResult, localeLangCodes] = await Promise.all([
    db
      .prepare(EXPRESSIONS_SQL)
      .bind(JSON.stringify(distinct))
      .all<{ id: string; text: string }>(),
    localeCodes.length > 0 ? loadLocaleLangCodes(db, localeCodes) : Promise.resolve(new Map<string, string>()),
  ]);
  const { results: expressionRows } = expressionResult;
  const expressions = new Map(expressionRows.map((row) => [row.id, row.text]));

  const primaryMap = localeCodes.length > 0
    ? await loadCandidateMap(db, distinct, localeLangCodes.get(localeCodes[0]) ?? '', localeCodes[0])
    : new Map<string, string>();
  const secondaryMap = localeCodes.length > 1
    ? await loadCandidateMap(db, distinct, localeLangCodes.get(localeCodes[1]) ?? '', localeCodes[1])
    : new Map<string, string>();

  for (const id of distinct) {
    const text = expressions.get(id);
    const primary = primaryMap.get(id);
    const secondary = secondaryMap.get(id);
    if (primary !== undefined) {
      results.set(id, { name: primary, name_en: text ?? '', resolved_from: 'primary' });
      continue;
    }
    if (secondary !== undefined) {
      results.set(id, { name: secondary, name_en: text ?? '', resolved_from: 'secondary' });
      continue;
    }
    if (text === undefined) continue;
    results.set(id, { name: text, name_en: text, resolved_from: 'fallback' });
  }
  return results;
}

export async function resolveNamesByExpressionIds(
  db: D1Database,
  ids: readonly string[],
  hints: LocaleHints,
): Promise<Map<string, { name: string; name_en: string }>> {
  const resolved = await resolveExpressionDisplayNames(db, ids, hints);
  return new Map([...resolved].map(([id, { name, name_en }]) => [id, { name, name_en }]));
}

function fallbackName(kind: IdentityKind, row: IdentityRow | undefined, identityCode: string): string {
  if (!row) return identityCode;
  if (kind === 'language') return row.name_en || row.name || identityCode;
  return row.name || row.name_en || identityCode;
}

export async function resolveLocalizedNames(
  db: D1Database,
  requests: readonly LocalizedNameRequest[],
  hints: LocaleHints,
): Promise<Map<string, LocalizedNameResult>> {
  const results = new Map<string, LocalizedNameResult>();
  if (requests.length === 0) return results;

  const identities = await loadIdentities(db, requests);
  const sourceIds = [
    ...new Set(requests.map((r) => identities.get(r.identityCode)?.name_expression_id).filter((id): id is string => Boolean(id))),
  ];
  const resolvedNames = await resolveExpressionDisplayNames(db, sourceIds, hints);

  for (const request of requests) {
    const row = identities.get(request.identityCode);
    const isSelfLocale = request.kind === 'locale'
      && (request.identityCode === hints.primary || request.identityCode === hints.secondary);
    if (isSelfLocale && row?.name) {
      results.set(request.identityCode, {
        lang_code: request.langCode,
        name: row.name,
        name_en: row.name_en,
        resolved_from: 'primary',
      });
      continue;
    }
    const expressionId = row?.name_expression_id;
    const resolved = expressionId ? resolvedNames.get(expressionId) : undefined;
    const translated = resolved && resolved.resolved_from !== 'fallback' ? resolved.name : undefined;
    const override = request.kind === 'language'
      ? LANGUAGE_NAME_OVERRIDES[request.identityCode]?.[hints.primary ?? '']
        ?? LANGUAGE_NAME_OVERRIDES[request.identityCode]?.[hints.secondary ?? '']
      : undefined;
    results.set(request.identityCode, {
      lang_code: request.langCode,
      name: translated ?? override ?? fallbackName(request.kind, row, request.identityCode),
      name_en: row?.name_en ?? request.identityCode,
      resolved_from: resolved && resolved.resolved_from !== 'fallback' ? resolved.resolved_from : override ? 'primary' : 'fallback',
    });
  }
  return results;
}

export async function resolveLanguageNames(
  db: D1Database,
  langCodes: readonly string[],
  hints: LocaleHints,
): Promise<Map<string, string>> {
  const distinct = [...new Set(langCodes.map((c) => c.trim()).filter(Boolean))];
  if (distinct.length === 0) return new Map();
  const resolved = await resolveLocalizedNames(
    db,
    distinct.map((code) => ({ kind: 'language' as const, langCode: code, identityCode: code })),
    hints,
  );
  return new Map([...resolved].map(([code, result]) => [code, result.name]));
}

export async function resolveLocaleNames(
  db: D1Database,
  localeCodes: readonly string[],
  hints: LocaleHints,
): Promise<Map<string, string>> {
  const distinct = [...new Set(localeCodes.map((c) => c.trim()).filter(Boolean))];
  if (distinct.length === 0) return new Map();
  const resolved = await resolveLocalizedNames(
    db,
    distinct.map((code) => ({ kind: 'locale' as const, langCode: '', identityCode: code })),
    hints,
  );
  return new Map([...resolved].map(([code, result]) => [code, result.name]));
}
