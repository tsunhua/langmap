import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, conflict, created, internalError, notFound, paginated, success } from '../utils/response';
import { LanguageLocaleError, assertReferenceCodesExist, buildLanguageLocaleCode, escapeLike, parseLanguageLocaleCode, parseReferenceQuery } from '../services/languageIdentity';
import type { Bindings, Variables } from '../types';

const languageLocales = new Hono<{ Bindings: Bindings; Variables: Variables }>();
const COLUMNS = 'll.id,ll.code,l.code AS lang_code,ll.script_code,ll.orthography,ll.region_code,ll.place_path,ll.name,ll.name_en,ll.latitude,ll.longitude';

languageLocales.post('/', requireAuth, async (c) => {
  try {
    const body = await c.req.json<Record<string, unknown>>().catch(() => ({})); const lang = typeof body.lang_code === 'string' ? body.lang_code.trim().toLowerCase() : ''; const script = typeof body.script_code === 'string' ? body.script_code.trim() : ''; const region = typeof body.region_code === 'string' ? body.region_code.trim() : ''; const name = typeof body.name === 'string' ? body.name.trim() : ''; const nameEn = typeof body.name_en === 'string' ? body.name_en.trim() : ''; const segments = Array.isArray(body.place_segments) && body.place_segments.every((x) => typeof x === 'string') ? body.place_segments : [];
    if (!lang || !script || !region || !name || !nameEn) return badRequest(c, 'VALIDATION_FAILED');
    const latitude = typeof body.latitude === 'number' && Number.isFinite(body.latitude) ? body.latitude : null; const longitude = typeof body.longitude === 'number' && Number.isFinite(body.longitude) ? body.longitude : null; if ((latitude === null) !== (longitude === null)) return badRequest(c, 'VALIDATION_FAILED');
    let code: string; try { code = buildLanguageLocaleCode({ lang_code: lang, script_code: script, region_code: region, place_segments: segments }); await assertReferenceCodesExist(c.env.DB, lang, script, region); } catch (error) { return error instanceof LanguageLocaleError ? badRequest(c, error.code) : internalError(c); }
    const language = await c.env.DB.prepare('SELECT id FROM languages WHERE code=?').bind(lang).first<{id:number}>(); if (!language) return badRequest(c, 'INVALID_LANG_CODE');
    try { await c.env.DB.prepare('INSERT INTO language_locales(code,language_id,script_code,region_code,place_path,name,name_en,latitude,longitude) VALUES(?,?,?,?,?,?,?,?,?)').bind(code,language.id,script,region,segments.join('_'),name,nameEn,latitude,longitude).run(); } catch (error) { if (String(error).includes('UNIQUE constraint failed')) return conflict(c, 'LANGUAGE_LOCALE_EXISTS'); throw error; }
    const row = await c.env.DB.prepare(`SELECT ${COLUMNS} FROM language_locales ll JOIN languages l ON l.id=ll.language_id WHERE ll.code=?`).bind(code).first(); return created(c,row);
  } catch (error) { console.error('Create language locale error:', error); return internalError(c); }
});

languageLocales.get('/', async (c) => {
  const query = parseReferenceQuery({ q: c.req.query('q'), limit: c.req.query('limit'), offset: c.req.query('skip') ?? c.req.query('offset') }); const where: string[]=[]; const args:Array<string|number>=[];
  for (const [column,value] of [['l.code',(c.req.query('lang_code') ?? '').toLowerCase()],['ll.script_code',c.req.query('script_code') ?? ''],['ll.region_code',(c.req.query('region_code') ?? '').toUpperCase()]] as const) if (value) { where.push(`${column}=?`); args.push(value); }
  if (query.q) { const like=`%${escapeLike(query.q)}%`; where.push("(ll.code LIKE ? ESCAPE '\\' OR ll.name LIKE ? ESCAPE '\\' OR ll.name_en LIKE ? ESCAPE '\\')"); args.push(like,like,like); }
  const clause=where.length?`WHERE ${where.join(' AND ')}`:''; const count=await c.env.DB.prepare(`SELECT COUNT(*) AS total FROM language_locales ll JOIN languages l ON l.id=ll.language_id ${clause}`).bind(...args).first<{total:number}>(); const rows=await c.env.DB.prepare(`SELECT ${COLUMNS} FROM language_locales ll JOIN languages l ON l.id=ll.language_id ${clause} ORDER BY ll.code LIMIT ? OFFSET ?`).bind(...args,query.limit,query.offset).all(); return paginated(c,rows.results,count?.total ?? 0,query.offset,query.limit);
});

languageLocales.get('/:code', async (c) => {
  const code=c.req.param('code'); if (!parseLanguageLocaleCode(code)) return badRequest(c,'INVALID_LANGUAGE_LOCALE_CODE'); const row=await c.env.DB.prepare(`SELECT ${COLUMNS},COALESCE(ll.latitude,r.latitude) AS resolved_latitude,COALESCE(ll.longitude,r.longitude) AS resolved_longitude,CASE WHEN ll.latitude IS NOT NULL THEN 'locale' WHEN r.latitude IS NOT NULL THEN 'region' ELSE NULL END AS coordinate_source FROM language_locales ll JOIN languages l ON l.id=ll.language_id LEFT JOIN regions r ON r.code=ll.region_code WHERE ll.code=?`).bind(code).first(); if(!row) return notFound(c,'Language locale'); return success(c,row);
});
export default languageLocales;
