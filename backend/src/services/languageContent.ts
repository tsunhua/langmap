import type { D1Database } from '@cloudflare/workers-types';
import { escapeLike } from './languageIdentity';

export interface LanguageContentSummary { code: string; name_en: string; name: string; expression_count: number; locale_count: number; active_ui_locale_count: number; }
export interface LanguageLocaleSummary { code: string; name: string; name_en: string; display_name: string; script_code: string | null; region_code: string | null; place_path: string; latitude: number | null; longitude: number | null; coordinate_source: 'locale' | 'region' | null; }
export interface LanguageDetail { code: string; name_en: string; name: string; expression_count: number; reading_count: number; mapped_expression_count: number; locales: LanguageLocaleSummary[]; }
export interface LanguageExpressionRow { id: number; lang_code: string; text: string; homograph_index: number; created_at: string; reading_count: number; mapping_count: number; language_name: string; }

export async function listLanguagesWithContent(db: D1Database, query: { q: string; sort: 'count' | 'alpha'; limit: number; offset: number; uiLocale: string; secondaryUiLocale: string }): Promise<{ items: LanguageContentSummary[]; total: number }> {
  const q = query.q.trim(); const where = q ? "WHERE l.code LIKE ? ESCAPE '\\' OR l.name_en LIKE ? ESCAPE '\\'" : ''; const params = q ? [`%${escapeLike(q)}%`, `%${escapeLike(q)}%`] : [];
  const base = `SELECT l.code,l.name_en,l.name_en AS name,COUNT(DISTINCT e.id) AS expression_count,COUNT(DISTINCT ll.id) AS locale_count,COUNT(DISTINCT u.locale_id) AS active_ui_locale_count FROM languages l LEFT JOIN expressions e ON e.language_id=l.id LEFT JOIN language_locales ll ON ll.language_id=l.id LEFT JOIN ui_locales u ON u.locale_id=ll.id AND u.status='active' ${where} GROUP BY l.id HAVING COUNT(e.id)>0 OR COUNT(ll.id)>0`;
  const count = await db.prepare(`SELECT COUNT(*) AS total FROM (${base})`).bind(...params).first<{ total: number }>(); const order = query.sort === 'alpha' ? 'l.name_en,l.code' : 'expression_count DESC,l.code'; const rows = await db.prepare(`${base} ORDER BY ${order} LIMIT ? OFFSET ?`).bind(...params, query.limit, query.offset).all<LanguageContentSummary>();
  return { items: rows.results, total: count?.total ?? 0 };
}

export async function getLanguageDetail(db: D1Database, code: string, _hints = {}, locale = ''): Promise<LanguageDetail | null> {
  const language = await db.prepare('SELECT id,code,name_en FROM languages WHERE code=?').bind(code).first<{ id:number;code:string;name_en:string }>(); if (!language) return null;
  const localeFilter = locale ? 'AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales ll ON ll.id=x.locale_id WHERE x.expression_id=e.id AND ll.code=?)' : ''; const args: Array<string|number> = [language.id]; if (locale) args.push(locale);
  const [expressions, readings, mapped, localeRows] = await Promise.all([
    db.prepare(`SELECT COUNT(*) AS total FROM expressions e WHERE e.language_id=? ${localeFilter}`).bind(...args).first<{total:number}>(),
    db.prepare('SELECT COUNT(*) AS total FROM expression_readings r JOIN expressions e ON e.id=r.expression_id WHERE e.language_id=?').bind(language.id).first<{total:number}>(),
    db.prepare(`SELECT COUNT(*) AS total FROM expressions e WHERE e.language_id=? ${localeFilter} AND EXISTS (SELECT 1 FROM expression_edges g WHERE g.expression_a_id=e.id OR g.expression_b_id=e.id)`).bind(...args).first<{total:number}>(),
    db.prepare('SELECT ll.code,ll.name,ll.name_en,ll.script_code,ll.region_code,ll.place_path,ll.latitude AS locale_latitude,ll.longitude AS locale_longitude,r.latitude AS region_latitude,r.longitude AS region_longitude FROM language_locales ll LEFT JOIN regions r ON r.code=ll.region_code WHERE ll.language_id=? ORDER BY ll.code').bind(language.id).all<any>(),
  ]);
  const locales = localeRows.results.map((row) => ({ code: row.code, name: row.name, name_en: row.name_en, display_name: row.name, script_code: row.script_code, region_code: row.region_code, place_path: row.place_path, latitude: row.locale_latitude ?? row.region_latitude, longitude: row.locale_longitude ?? row.region_longitude, coordinate_source: row.locale_latitude !== null ? 'locale' : row.region_latitude !== null ? 'region' : null }));
  return { code: language.code, name_en: language.name_en, name: language.name_en, expression_count: expressions?.total ?? 0, reading_count: readings?.total ?? 0, mapped_expression_count: mapped?.total ?? 0, locales };
}

export async function listLanguageExpressions(db: D1Database, code: string, query: { q: string; locale: string; sort: 'hot' | 'new' | 'alpha'; limit: number; offset: number; uiLocale: string; secondaryUiLocale: string }): Promise<{ items: LanguageExpressionRow[]; total: number } | null> {
  const language = await db.prepare('SELECT id FROM languages WHERE code=?').bind(code).first<{id:number}>(); if (!language) return null;
  const where = ['e.language_id=?']; const args: Array<string|number>=[language.id]; if (query.q) { where.push("e.text LIKE ? ESCAPE '\\'"); args.push(`%${escapeLike(query.q)}%`); } if (query.locale) { where.push('EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales ll ON ll.id=x.locale_id WHERE x.expression_id=e.id AND ll.code=?)');args.push(query.locale); }
  const filter=where.join(' AND '); const count=await db.prepare(`SELECT COUNT(*) AS total FROM expressions e WHERE ${filter}`).bind(...args).first<{total:number}>(); const select=`SELECT e.id,? AS lang_code,e.text,e.homograph_index,e.created_at,(SELECT COUNT(*) FROM expression_readings r WHERE r.expression_id=e.id) AS reading_count,(SELECT COUNT(*) FROM expression_edges g WHERE g.expression_a_id=e.id OR g.expression_b_id=e.id) AS mapping_count,? AS language_name FROM expressions e WHERE ${filter}`; const order=query.sort==='hot'?'mapping_count DESC,e.text,e.homograph_index,e.id':query.sort==='new'?'e.created_at DESC,e.id':'e.text,e.homograph_index,e.id'; const rows=await db.prepare(`${select} ORDER BY ${order} LIMIT ? OFFSET ?`).bind(code,code,...args,query.limit,query.offset).all<LanguageExpressionRow>();
  return { items: rows.results, total: count?.total ?? 0 };
}
