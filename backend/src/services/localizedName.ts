import type { D1Database } from '@cloudflare/workers-types';
import { parseLanguageLocaleCode } from './languageIdentity';

export interface LocaleHints { primary?: string; secondary?: string; }

interface IdentityRow { code: string; name_expression_id: number | null; name_en: string; name: string | null; }
interface CandidateRow { source_id: number; target_text: string; score: number; target_id: number; }

const LANGUAGE_SQL = 'SELECT code, name_expression_id, name_en, NULL AS name FROM languages WHERE code IN (SELECT value FROM json_each(?))';
const LOCALE_SQL = 'SELECT code, name_expression_id, name_en, name FROM language_locales WHERE code IN (SELECT value FROM json_each(?))';
const EXPRESSIONS_SQL = 'SELECT id, text FROM expressions WHERE id IN (SELECT value FROM json_each(?))';

// A name is only translated through a direct semantic edge whose target is
// attested in the requested full locale. The two UNION branches keep the
// canonical expression usable regardless of its numeric edge orientation.
// Driving from the source node ids (instead of the target language's
// expression table) keeps cost proportional to the edges around the handful of
// registry names, not to the target language size. CROSS JOIN prevents SQLite
// from reordering the scan back onto the (potentially huge) target language.
export const CANDIDATE_SQL = `WITH candidate_rows AS (
  SELECT value AS source_id FROM json_each(?)
)
SELECT candidate_rows.source_id, t.id AS target_id, t.text AS target_text, e.score
FROM candidate_rows
CROSS JOIN expression_edges e ON e.expression_a_id = candidate_rows.source_id
JOIN expressions t ON t.id = e.expression_b_id
WHERE e.score >= 0
  AND t.language_id = (SELECT language_id FROM language_locales WHERE code = ?)
  AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=t.id AND l.code=?)
UNION ALL
SELECT candidate_rows.source_id, t.id AS target_id, t.text AS target_text, e.score
FROM candidate_rows
CROSS JOIN expression_edges e ON e.expression_b_id = candidate_rows.source_id
JOIN expressions t ON t.id = e.expression_a_id
WHERE e.score >= 0
  AND t.language_id = (SELECT language_id FROM language_locales WHERE code = ?)
  AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=t.id AND l.code=?)`;

export function parseLocaleHints(primary?: string, secondary?: string): LocaleHints {
  const clean = (value?: string) => {
    const code = value?.trim();
    return code && parseLanguageLocaleCode(code) ? code : undefined;
  };
  const first = clean(primary); const second = clean(secondary);
  return { primary: first, secondary: second && second !== first ? second : undefined };
}

async function candidates(db: D1Database, ids: readonly number[], locale?: string): Promise<Map<number, string>> {
  if (!locale || ids.length === 0) return new Map();
  const json = JSON.stringify(ids);
  const { results } = await db.prepare(CANDIDATE_SQL).bind(json, locale, locale, locale, locale).all<CandidateRow>();
  const selected = new Map<number, CandidateRow>();
  for (const row of results) {
    const current = selected.get(row.source_id);
    if (!current || row.score > current.score || (row.score === current.score && row.target_id < current.target_id)) selected.set(row.source_id, row);
  }
  return new Map([...selected].map(([sourceId, row]) => [sourceId, row.target_text]));
}

export async function resolveNamesByExpressionIds(db: D1Database, ids: readonly number[], hints: LocaleHints): Promise<Map<number, { name: string; name_en: string }>> {
  const distinct = [...new Set(ids.filter((id) => Number.isInteger(id) && id > 0))];
  if (distinct.length === 0) return new Map();
  const { results } = await db.prepare(EXPRESSIONS_SQL).bind(JSON.stringify(distinct)).all<{ id: number; text: string }>();
  const primary = await candidates(db, distinct, hints.primary);
  const secondary = await candidates(db, distinct, hints.secondary);
  return new Map(results.map((row) => [row.id, { name: primary.get(row.id) ?? secondary.get(row.id) ?? row.text, name_en: row.text }]));
}

export async function resolveLanguageNames(db: D1Database, codes: readonly string[], hints: LocaleHints): Promise<Map<string, string>> {
  const distinct = [...new Set(codes.filter(Boolean))];
  if (distinct.length === 0) return new Map();
  const { results } = await db.prepare(LANGUAGE_SQL).bind(JSON.stringify(distinct)).all<IdentityRow>();
  const resolved = await resolveNamesByExpressionIds(db, results.flatMap((row) => row.name_expression_id ?? []), hints);
  return new Map(results.map((row) => [row.code, row.name_expression_id ? (resolved.get(row.name_expression_id)?.name ?? row.name_en) : row.name_en]));
}

export async function resolveLocaleNames(db: D1Database, codes: readonly string[], hints: LocaleHints): Promise<Map<string, string>> {
  const distinct = [...new Set(codes.filter(Boolean))];
  if (distinct.length === 0) return new Map();
  const { results } = await db.prepare(LOCALE_SQL).bind(JSON.stringify(distinct)).all<IdentityRow>();
  const resolved = await resolveNamesByExpressionIds(db, results.flatMap((row) => row.name_expression_id ?? []), hints);
  return new Map(results.map((row) => [row.code, row.name_expression_id ? (resolved.get(row.name_expression_id)?.name ?? row.name ?? row.name_en) : (row.name ?? row.name_en)]));
}
