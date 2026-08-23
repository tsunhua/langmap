import type { D1Database, D1PreparedStatement } from '@cloudflare/workers-types';

export interface BundleEntry {
  key: string;
  text: string;
  resolved_from: 'primary' | 'secondary' | 'source';
}

export class LocalizationError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'LocalizationError';
  }
}

interface CandidateRow {
  message_key: string;
  placeholders_json: string;
  source_text: string;
  target_id: string;
  target_text: string;
  edge_id: string;
  score: number;
  created_at: string;
}

const AUTO_ACTIVATION_THRESHOLD = 0.60;

const TOTAL_MESSAGES_SQL = 'SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ?';

const LOCALE_LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';

const LOCALE_ROW_SQL = 'SELECT status, activation_source FROM ui_locales WHERE project_id = ? AND language_locale_code = ?';

const ACTIVE_MESSAGES_SQL = 'SELECT message_key, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? ORDER BY message_key ASC';

export const CANDIDATE_SQL = `WITH candidate_rows AS (
  SELECT m.message_key, m.placeholders_json, m.source_text, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at
  FROM ui_messages m
  JOIN expression_edges e ON e.expression_a_id = m.source_expression_id
  JOIN expressions t ON t.id = e.expression_b_id
  WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND t.lang_code = ?
    AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?)
  UNION ALL
  SELECT m.message_key, m.placeholders_json, m.source_text, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at
  FROM ui_messages m
  JOIN expression_edges e ON e.expression_b_id = m.source_expression_id
  JOIN expressions t ON t.id = e.expression_a_id
  WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND t.lang_code = ?
    AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?)
), ranked AS (
  SELECT candidate_rows.*, ROW_NUMBER() OVER (
    PARTITION BY message_key
    ORDER BY score DESC, created_at ASC, target_id ASC
  ) AS candidate_rank
  FROM candidate_rows
)
SELECT message_key, placeholders_json, source_text, target_id, target_text, edge_id, score, created_at
FROM ranked
WHERE candidate_rank <= 5
ORDER BY message_key ASC, score DESC, created_at ASC, target_id ASC`;

const EXPRESSION_LANGS_SQL = 'SELECT DISTINCT lang_code FROM expressions WHERE id IN (SELECT value FROM json_each(?)) ORDER BY lang_code ASC';

const PROJECT_LOCALES_FOR_LANG_SQL = 'SELECT language_locale_code FROM ui_locales WHERE project_id = ? AND language_locale_code LIKE ? ORDER BY language_locale_code ASC LIMIT 200';

function extractPlaceholders(text: string): string[] {
  return Array.from(text.matchAll(/\{(\w+)\}/g)).map((m) => m[1]).sort();
}

function placeholdersMatch(placeholdersJson: string, targetText: string): boolean {
  let sourcePlaceholders: string[];
  try {
    const parsed: unknown = JSON.parse(placeholdersJson);
    sourcePlaceholders = Array.isArray(parsed) ? (parsed as string[]).slice().sort() : [];
  } catch {
    return false;
  }
  return JSON.stringify(sourcePlaceholders) === JSON.stringify(extractPlaceholders(targetText));
}

async function loadCandidates(
  db: D1Database,
  projectId: string,
  localeCode: string,
): Promise<Map<string, string>> {
  const langRow = await db
    .prepare(LOCALE_LANG_SQL)
    .bind(localeCode)
    .first<{ lang_code: string }>();
  if (!langRow) return new Map();

  return loadCandidatesForLanguage(db, projectId, localeCode, langRow.lang_code);
}

async function loadCandidatesForLanguage(
  db: D1Database,
  projectId: string,
  localeCode: string,
  langCode: string,
): Promise<Map<string, string>> {

  const { results } = await db
    .prepare(CANDIDATE_SQL)
    .bind(projectId, 'active', langCode, localeCode, projectId, 'active', langCode, localeCode)
    .all<CandidateRow>();

  const candidates = new Map<string, string>();
  for (const row of results) {
    if (candidates.has(row.message_key)) continue;
    if (!placeholdersMatch(row.placeholders_json, row.target_text)) continue;
    candidates.set(row.message_key, row.target_text);
  }
  return candidates;
}

export async function computeCoverage(
  db: D1Database,
  projectId: string,
  languageLocaleCode: string,
): Promise<{ coverage: number; total: number; translated: number }> {
  const totalRow = await db
    .prepare(TOTAL_MESSAGES_SQL)
    .bind(projectId, 'active')
    .first<{ total: number }>();
  const total = totalRow?.total ?? 0;
  if (total === 0) return { coverage: 0, total: 0, translated: 0 };

  const candidates = await loadCandidates(db, projectId, languageLocaleCode);
  const translated = candidates.size;
  return { coverage: translated / total, total, translated };
}

export async function recalculateLocale(
  db: D1Database,
  projectId: string,
  languageLocaleCode: string,
): Promise<void> {
  const { coverage } = await computeCoverage(db, projectId, languageLocaleCode);

  const locale = await db
    .prepare(LOCALE_ROW_SQL)
    .bind(projectId, languageLocaleCode)
    .first<{ status: string; activation_source: string | null }>();

  if (!locale) return;

  if (locale.status === 'draft' && coverage >= AUTO_ACTIVATION_THRESHOLD) {
    await db
      .prepare(
        "UPDATE ui_locales SET status = 'active', activation_source = 'auto', activated_at = CURRENT_TIMESTAMP, mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ? AND status = 'draft'",
      )
      .bind(projectId, languageLocaleCode)
      .run();
    return;
  }

  await db
    .prepare(
      'UPDATE ui_locales SET mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?',
    )
    .bind(projectId, languageLocaleCode)
    .run();
}

export async function recalculateForExpressions(
  db: D1Database,
  projectId: string,
  expressionIds: string[],
): Promise<void> {
  for (const code of await listAffectedUiLocaleCodes(db, projectId, expressionIds)) {
    await recalculateLocale(db, projectId, code);
  }
}

export async function listAffectedUiLocaleCodes(
  db: D1Database,
  projectId: string,
  expressionIds: readonly string[],
): Promise<string[]> {
  const unique = Array.from(new Set(expressionIds.filter(Boolean))).sort();
  if (unique.length === 0) return [];

  const { results: langRows } = await db
    .prepare(EXPRESSION_LANGS_SQL)
    .bind(JSON.stringify(unique))
    .all<{ lang_code: string }>();

  const localeCodes = new Set<string>();
  for (const row of langRows) {
    const { results: localeRows } = await db
      .prepare(PROJECT_LOCALES_FOR_LANG_SQL)
      .bind(projectId, `${row.lang_code}-%`)
      .all<{ language_locale_code: string }>();
    for (const locale of localeRows) localeCodes.add(locale.language_locale_code);
  }
  return Array.from(localeCodes).sort();
}

export function prepareRevisionBumps(
  db: D1Database,
  projectId: string,
  localeCodes: readonly string[],
): D1PreparedStatement[] {
  return Array.from(new Set(localeCodes.filter(Boolean)))
    .sort()
    .map((code) => db
      .prepare('UPDATE ui_locales SET mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, code));
}

export async function activateLocale(
  db: D1Database,
  projectId: string,
  code: string,
  source: 'auto' | 'manual',
  userId: number,
): Promise<void> {
  const locale = await db
    .prepare(LOCALE_ROW_SQL)
    .bind(projectId, code)
    .first<{ status: string; activation_source: string | null }>();

  if (!locale) throw new LocalizationError('UI_LOCALE_NOT_FOUND');
  if (locale.status === 'archived') throw new LocalizationError('UI_LOCALE_ARCHIVED');
  if (locale.status === 'active') throw new LocalizationError('UI_LOCALE_ALREADY_ACTIVE');

  await db
    .prepare(
      "UPDATE ui_locales SET status = 'active', activation_source = ?, activated_at = CURRENT_TIMESTAMP, activated_by = ?, mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?",
    )
    .bind(source, userId, projectId, code)
    .run();
}

export async function archiveLocale(
  db: D1Database,
  projectId: string,
  code: string,
  _userId: number,
): Promise<void> {
  const locale = await db
    .prepare(LOCALE_ROW_SQL)
    .bind(projectId, code)
    .first<{ status: string; activation_source: string | null }>();

  if (!locale) throw new LocalizationError('UI_LOCALE_NOT_FOUND');
  if (locale.activation_source === 'system') throw new LocalizationError('UI_LOCALE_SYSTEM_LOCKED');

  await db
    .prepare(
      "UPDATE ui_locales SET status = 'archived', mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?",
    )
    .bind(projectId, code)
    .run();
}

async function findCandidate(
  db: D1Database,
  projectId: string,
  localeCode: string,
): Promise<Map<string, string>> {
  const locale = await db
    .prepare('SELECT u.status, l.lang_code FROM ui_locales u JOIN language_locales l ON l.code = u.language_locale_code WHERE u.project_id = ? AND u.language_locale_code = ?')
    .bind(projectId, localeCode)
    .first<{ status: string; lang_code: string }>();
  if (locale?.status !== 'active') return new Map();
  return loadCandidatesForLanguage(db, projectId, localeCode, locale.lang_code);
}

export async function resolveBundle(
  db: D1Database,
  projectId: string,
  primary?: string,
  secondary?: string,
): Promise<BundleEntry[]> {
  const [messageResult, primaryCandidates, secondaryCandidates] = await Promise.all([
    db
      .prepare(ACTIVE_MESSAGES_SQL)
      .bind(projectId, 'active')
      .all<{ message_key: string; source_text: string; placeholders_json: string }>(),
    primary ? findCandidate(db, projectId, primary) : Promise.resolve(new Map<string, string>()),
    secondary ? findCandidate(db, projectId, secondary) : Promise.resolve(new Map<string, string>()),
  ]);
  const { results: messages } = messageResult;

  return messages.map((m) => {
    const primaryText = primaryCandidates.get(m.message_key);
    if (primaryText !== undefined) {
      return { key: m.message_key, text: primaryText, resolved_from: 'primary' as const };
    }
    const secondaryText = secondaryCandidates.get(m.message_key);
    if (secondaryText !== undefined) {
      return { key: m.message_key, text: secondaryText, resolved_from: 'secondary' as const };
    }
    return { key: m.message_key, text: m.source_text, resolved_from: 'source' as const };
  });
}
