import type { D1Database } from '@cloudflare/workers-types';
import { escapeLike } from './languageIdentity';
import { parseLocaleHints, resolveLanguageNames, resolveLocaleNames, type LocaleHints } from './localizedName';

export interface LanguageContentSummary {
  code: string;
  name_en: string;
  name: string;
  expression_count: number;
  locale_count: number;
  active_ui_locale_count: number;
}

export interface LanguageLocaleSummary {
  code: string;
  name: string;
  name_en: string;
  display_name: string;
  script_code: string;
  region_code: string;
  place_path: string;
  latitude: number | null;
  longitude: number | null;
  coordinate_source: 'locale' | 'region' | null;
}

export interface LanguageDetail {
  code: string;
  name_en: string;
  name: string;
  expression_count: number;
  reading_count: number;
  mapped_expression_count: number;
  locales: LanguageLocaleSummary[];
}

export interface LanguageExpressionRow {
  id: string;
  lang_code: string;
  text: string;
  description: string;
  homograph_index: number;
  review_status: string;
  created_at: string;
  reading_count: number;
  mapping_count: number;
  language_name: string;
}

interface LocaleRow {
  code: string;
  name: string;
  name_en: string;
  script_code: string;
  region_code: string;
  place_path: string;
  locale_latitude: number | null;
  locale_longitude: number | null;
  region_latitude: number | null;
  region_longitude: number | null;
}

const LOCALE_LIST_LIMIT = 500;
const CONTENT_LANGUAGES_SELECT = "SELECT g.code AS code, g.name_en AS name_en, COALESCE((SELECT l2.name FROM language_locales l2 WHERE l2.code = ? AND l2.lang_code = g.code LIMIT 1), g.name_en) AS name, (SELECT COUNT(*) FROM expressions e WHERE e.lang_code = g.code) AS expression_count, (SELECT COUNT(*) FROM language_locales l3 WHERE l3.lang_code = g.code) AS locale_count, (SELECT COUNT(*) FROM ui_locales u JOIN language_locales l4 ON l4.code = u.language_locale_code WHERE l4.lang_code = g.code AND u.status = 'active') AS active_ui_locale_count FROM languages g WHERE (EXISTS (SELECT 1 FROM expressions e2 WHERE e2.lang_code = g.code) OR EXISTS (SELECT 1 FROM language_locales l5 WHERE l5.lang_code = g.code)) AND (? = '' OR g.code LIKE ? ESCAPE '\\' OR g.name_en LIKE ? ESCAPE '\\')";
const CONTENT_LANGUAGES_COUNT_SQL = `SELECT COUNT(*) AS total FROM (${CONTENT_LANGUAGES_SELECT})`;
const LANGUAGE_ROW_SQL = 'SELECT code, name_en FROM languages WHERE code = ?';
const LANGUAGE_LOCALES_SQL = `SELECT l.code, l.name, l.name_en, l.script_code, l.region_code, l.place_path, l.latitude AS locale_latitude, l.longitude AS locale_longitude, r.latitude AS region_latitude, r.longitude AS region_longitude FROM language_locales l LEFT JOIN regions r ON r.code = l.region_code WHERE l.lang_code = ? ORDER BY l.code ASC LIMIT ${LOCALE_LIST_LIMIT}`;
const EXPRESSION_COUNT_SQL = "SELECT COUNT(*) AS total FROM expressions e WHERE e.lang_code = ? AND (? = '' OR EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = e.id AND a.language_locale_code = ?))";
const READING_COUNT_SQL = 'SELECT COUNT(*) AS total FROM expression_readings WHERE expression_id IN (SELECT id FROM expressions WHERE lang_code = ?)';
const MAPPED_EXPRESSION_COUNT_SQL = "SELECT COUNT(*) AS total FROM expressions e WHERE e.lang_code = ? AND (? = '' OR EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = e.id AND a.language_locale_code = ?)) AND EXISTS (SELECT 1 FROM expression_edges g WHERE g.expression_a_id = e.id OR g.expression_b_id = e.id)";
const LANGUAGE_EXPRESSIONS_FILTER_SQL = "e.lang_code = ? AND (? = '' OR e.text LIKE ? ESCAPE '\\') AND (? = '' OR EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = e.id AND a.language_locale_code = ?))";
const LANGUAGE_EXPRESSIONS_COUNT_SQL = `SELECT COUNT(*) AS total FROM expressions e WHERE ${LANGUAGE_EXPRESSIONS_FILTER_SQL}`;
const LANGUAGE_EXPRESSIONS_SELECT_SQL = `SELECT e.id, e.lang_code, e.text, e.description, e.homograph_index, e.review_status, e.created_at, (SELECT COUNT(*) FROM expression_readings r WHERE r.expression_id = e.id) AS reading_count, (SELECT COUNT(*) FROM expression_edges g WHERE g.expression_a_id = e.id OR g.expression_b_id = e.id) AS mapping_count FROM expressions e WHERE ${LANGUAGE_EXPRESSIONS_FILTER_SQL}`;

function resolveCoordinate(row: LocaleRow): Pick<LanguageLocaleSummary, 'latitude' | 'longitude' | 'coordinate_source'> {
  if (row.locale_latitude !== null && row.locale_longitude !== null) return { latitude: row.locale_latitude, longitude: row.locale_longitude, coordinate_source: 'locale' };
  if (row.region_latitude !== null && row.region_longitude !== null) return { latitude: row.region_latitude, longitude: row.region_longitude, coordinate_source: 'region' };
  return { latitude: null, longitude: null, coordinate_source: null };
}

export async function listLanguagesWithContent(db: D1Database, query: { q: string; sort: 'count' | 'alpha'; limit: number; offset: number; uiLocale: string; secondaryUiLocale: string }): Promise<{ items: LanguageContentSummary[]; total: number }> {
  const q = query.q.trim();
  const uiLocale = query.uiLocale.trim();
  const like = q ? `%${escapeLike(q)}%` : '';
  const orderBy = query.sort === 'alpha' ? 'name ASC, code ASC' : 'expression_count DESC, code ASC';
  const [totalRow, pageResult] = await Promise.all([
    db.prepare(CONTENT_LANGUAGES_COUNT_SQL).bind(uiLocale, q, like, like).first<{ total: number }>(),
    db.prepare(`${CONTENT_LANGUAGES_SELECT} ORDER BY ${orderBy} LIMIT ? OFFSET ?`).bind(uiLocale, q, like, like, query.limit, query.offset).all<LanguageContentSummary>(),
  ]);
  const { results } = pageResult;
  const names = await resolveLanguageNames(
    db,
    results.map((item) => item.code),
    parseLocaleHints(uiLocale || undefined, query.secondaryUiLocale.trim() || undefined),
  );
  const localizedItems = await Promise.all(results.map(async (item) => {
    const resolved = names.get(item.code);
    if (resolved) return { ...item, name: resolved };
    const locale = await db.prepare('SELECT name FROM language_locales WHERE lang_code = ? ORDER BY code ASC LIMIT 1').bind(item.code).first<{ name: string | null }>();
    return { ...item, name: locale?.name || item.name_en };
  }));
  return { items: localizedItems, total: totalRow?.total ?? 0 };
}

export async function getLanguageDetail(db: D1Database, code: string, hints: LocaleHints = {}, locale = ''): Promise<LanguageDetail | null> {
  const language = await db.prepare(LANGUAGE_ROW_SQL).bind(code).first<{ code: string; name_en: string }>();
  if (!language) return null;
  const localeFilter = locale.trim();
  const { results: localeRows } = await db.prepare(LANGUAGE_LOCALES_SQL).bind(code).all<LocaleRow>();
  const expressionCount = await db.prepare(EXPRESSION_COUNT_SQL).bind(code, localeFilter, localeFilter).first<{ total: number }>();
  const readingCount = await db.prepare(READING_COUNT_SQL).bind(code).first<{ total: number }>();
  const mappedExpressionCount = await db.prepare(MAPPED_EXPRESSION_COUNT_SQL).bind(code, localeFilter, localeFilter).first<{ total: number }>();
  const localeNames = await resolveLocaleNames(db, localeRows.map((row) => row.code), hints);
  const languageNames = await resolveLanguageNames(db, [language.code], hints);
  const locales = localeRows.map((row) => ({ code: row.code, name: row.name, name_en: row.name_en, display_name: localeNames.get(row.code) ?? row.name, script_code: row.script_code, region_code: row.region_code, place_path: row.place_path, ...resolveCoordinate(row) }));
  // Yue currently has no dedicated language-name expression; use its canonical
  // locale name so the language page does not fall back to the English registry label.
  const localizedName = languageNames.get(language.code)
    ?? localeRows.find((row) => row.name)?.name
    ?? language.name_en;
  return { code: language.code, name_en: language.name_en, name: localizedName, expression_count: expressionCount?.total ?? 0, reading_count: readingCount?.total ?? 0, mapped_expression_count: mappedExpressionCount?.total ?? 0, locales };
}

export async function listLanguageExpressions(db: D1Database, code: string, query: { q: string; locale: string; sort: 'hot' | 'new' | 'alpha'; limit: number; offset: number; uiLocale: string; secondaryUiLocale: string }): Promise<{ items: LanguageExpressionRow[]; total: number } | null> {
  const language = await db.prepare(LANGUAGE_ROW_SQL).bind(code).first<{ code: string }>();
  if (!language) return null;
  const q = query.q.trim();
  const like = q ? `%${escapeLike(q)}%` : '';
  const locale = query.locale.trim();
  const filters = [code, q, like, locale, locale];
  const totalRow = await db.prepare(LANGUAGE_EXPRESSIONS_COUNT_SQL).bind(...filters).first<{ total: number }>();
  const orderBy = query.sort === 'hot'
    ? 'mapping_count DESC, e.text ASC, e.homograph_index ASC, e.id ASC'
    : query.sort === 'new'
      ? 'e.created_at DESC, e.id ASC'
      : 'e.text ASC, e.homograph_index ASC, e.id ASC';
  const { results } = await db.prepare(`${LANGUAGE_EXPRESSIONS_SELECT_SQL} ORDER BY ${orderBy} LIMIT ? OFFSET ?`).bind(...filters, query.limit, query.offset).all<LanguageExpressionRow>();
  const names = await resolveLanguageNames(
    db,
    [code],
    parseLocaleHints(query.uiLocale.trim() || undefined, query.secondaryUiLocale.trim() || undefined),
  );
  const language_name = names.get(code) ?? '';
  return { items: results.map((item) => ({ ...item, language_name })), total: totalRow?.total ?? 0 };
}
