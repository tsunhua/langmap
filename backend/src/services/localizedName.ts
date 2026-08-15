import type { D1Database } from '@cloudflare/workers-types';
import { parseLanguageLocaleCode } from './languageIdentity';

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

const IDENTITY_LANGUAGE_SQL =
  'SELECT code, name_expression_id, name_en, NULL AS name FROM languages WHERE code IN (SELECT value FROM json_each(?))';
const IDENTITY_LOCALE_SQL =
  'SELECT code, name_expression_id, name_en, name FROM language_locales WHERE code IN (SELECT value FROM json_each(?))';
const LOCALE_LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';
export const CANDIDATE_SQL = `SELECT src.id AS source_id, t.id AS target_id, t.text AS target_text, e.score, e.created_at
FROM expression_edges e
JOIN expressions src ON src.id = e.expression_a_id OR src.id = e.expression_b_id
JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = src.id THEN e.expression_b_id ELSE e.expression_a_id END
WHERE src.id IN (SELECT value FROM json_each(?))
  AND e.score >= 0
  AND t.lang_code = ?
  AND EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = t.id AND a.language_locale_code = ?)
ORDER BY src.id ASC, e.score DESC, e.created_at ASC, t.id ASC`;

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
  const langCodes = new Map<string, string>();
  for (const localeCode of localeCodes) {
    const row = await db.prepare(LOCALE_LANG_SQL).bind(localeCode).first<{ lang_code: string }>();
    if (row) langCodes.set(localeCode, row.lang_code);
  }
  return langCodes;
}

async function loadCandidateMap(
  db: D1Database,
  sourceIds: readonly string[],
  langCode: string,
  localeCode: string,
): Promise<Map<string, string>> {
  if (sourceIds.length === 0 || !langCode) return new Map();
  const { results } = await db.prepare(CANDIDATE_SQL).bind(JSON.stringify(sourceIds), langCode, localeCode).all<CandidateRow>();
  const selected = new Map<string, string>();
  for (const row of results) {
    if (selected.has(row.source_id)) continue;
    selected.set(row.source_id, row.target_text);
  }
  return selected;
}

function fallbackName(kind: IdentityKind, row: IdentityRow | undefined, identityCode: string): string {
  if (!row) return identityCode;
  if (kind === 'language') return row.name_en || identityCode;
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
  const localeCodes = parseLocaleCodes(hints);
  const sourceIds = [
    ...new Set(requests.map((r) => identities.get(r.identityCode)?.name_expression_id).filter((id): id is string => Boolean(id))),
  ];

  const localeLangCodes = localeCodes.length > 0 ? await loadLocaleLangCodes(db, localeCodes) : new Map<string, string>();
  const primaryMap = localeCodes.length > 0
    ? await loadCandidateMap(db, sourceIds, localeLangCodes.get(localeCodes[0]) ?? '', localeCodes[0])
    : new Map<string, string>();
  const secondaryMap = localeCodes.length > 1
    ? await loadCandidateMap(db, sourceIds, localeLangCodes.get(localeCodes[1]) ?? '', localeCodes[1])
    : new Map<string, string>();

  for (const request of requests) {
    const row = identities.get(request.identityCode);
    const expressionId = row?.name_expression_id;
    const resolved = expressionId ? (primaryMap.get(expressionId) ?? secondaryMap.get(expressionId)) : undefined;
    results.set(request.identityCode, {
      lang_code: request.langCode,
      name: resolved ?? fallbackName(request.kind, row, request.identityCode),
      name_en: row?.name_en ?? request.identityCode,
      resolved_from:
        expressionId && primaryMap.has(expressionId)
          ? 'primary'
          : expressionId && secondaryMap.has(expressionId)
            ? 'secondary'
            : 'fallback',
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
