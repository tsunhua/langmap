import type { D1Database } from '@cloudflare/workers-types';
import type { LanguageLocaleParts } from '../types/language';

export type ReferenceTable = 'languages' | 'scripts' | 'regions';

export interface ReferenceQuery {
  q: string;
  limit: number;
  offset: number;
}

export interface ReferenceListResult {
  items: Record<string, unknown>[];
  total: number;
}

const COLUMNS: Record<ReferenceTable, readonly string[]> = {
  languages: ['code', 'name_en'],
  scripts: ['code', 'name_en', 'name_expression_id', 'direction'],
  regions: ['code', 'name_en', 'name_expression_id', 'latitude', 'longitude'],
};

const MAX_LIMIT = 50;
const MAX_Q = 80;

export function parseReferenceQuery(params: {
  q?: string;
  limit?: string;
  offset?: string;
}): ReferenceQuery {
  const limitRaw = Number(params.limit ?? '20');
  const limit = Math.min(
    Math.max(Number.isFinite(limitRaw) ? limitRaw : 20, 1),
    MAX_LIMIT,
  );
  const offset = Math.max(parseInt(params.offset ?? '0') || 0, 0);
  const q = (params.q ?? '').slice(0, MAX_Q);
  return { q, limit, offset };
}

export function escapeLike(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

export async function queryReferenceTable(
  db: D1Database,
  table: ReferenceTable,
  query: ReferenceQuery,
): Promise<ReferenceListResult> {
  const cols = COLUMNS[table].join(', ');
  const escapedQ = escapeLike(query.q);
  const where = escapedQ
    ? `WHERE code LIKE ? ESCAPE '\\' OR name_en LIKE ? ESCAPE '\\'`
    : '';
  const baseParams: (string | number)[] = escapedQ
    ? [`%${escapedQ}%`, `%${escapedQ}%`]
    : [];

  const countRow = await db
    .prepare(`SELECT COUNT(*) as total FROM ${table} ${where}`)
    .bind(...baseParams)
    .first<{ total: number }>();
  const total = countRow?.total ?? 0;

  const order = escapedQ
    ? `ORDER BY CASE WHEN code = ? COLLATE NOCASE THEN 0 WHEN code LIKE ? ESCAPE '\\' THEN 1 ELSE 2 END, code ASC LIMIT ? OFFSET ?`
    : `ORDER BY code ASC LIMIT ? OFFSET ?`;

  const selectParams = [...baseParams];
  if (escapedQ) selectParams.push(query.q, `${escapedQ}%`);
  selectParams.push(query.limit, query.offset);

  const { results } = await db
    .prepare(`SELECT ${cols} FROM ${table} ${where} ${order}`)
    .bind(...selectParams)
    .all();
  return { items: results as Record<string, unknown>[], total };
}

const LANG_CODE_RE = /^[a-z]{3}$/;
const SCRIPT_CODE_RE = /^[A-Z][a-z]{3}$/;
const REGION_CODE_RE = /^[A-Z]{2}$/;
const PLACE_SEGMENT_RE = /^[A-Z][A-Za-z]*$/;
const ORTHOGRAPHY_RE = /^[A-Z][A-Za-z]*$/;

export class LanguageLocaleError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'LanguageLocaleError';
  }
}

export function buildLanguageLocaleCode(input: {
  lang_code: string;
  script_code: string;
  orthography?: string;
  region_code: string;
  place_segments?: string[];
}): string {
  const lang = input.lang_code.toLowerCase();
  const script = input.script_code;
  const orthography = input.orthography;
  const region = input.region_code;
  const segments = input.place_segments ?? [];
  
  // 验证
  if (!LANG_CODE_RE.test(lang)) throw new LanguageLocaleError('INVALID_LANG_CODE');
  if (!SCRIPT_CODE_RE.test(script)) throw new LanguageLocaleError('INVALID_SCRIPT_CODE');
  if (orthography && !ORTHOGRAPHY_RE.test(orthography)) throw new LanguageLocaleError('INVALID_ORTHOGRAPHY');
  if (!REGION_CODE_RE.test(region)) throw new LanguageLocaleError('INVALID_REGION_CODE');
  for (const segment of segments) {
    if (!PLACE_SEGMENT_RE.test(segment)) throw new LanguageLocaleError('INVALID_PLACE_SEGMENT');
  }
  
  // 构建 code
  const scriptPart = orthography ? `${script}_${orthography}` : script;
  const placePart = segments.length > 0 ? `_${segments.join('_')}` : '';
  
  return `${lang}-${scriptPart}-${region}${placePart}`;
}

export function parseLanguageLocaleCode(code: string): LanguageLocaleParts | null {
  if (!code) return null;
  
  // 按 - 分割，得到 lang, script[_orthography], region[_place_segments]
  const dashParts = code.split('-');
  
  // 必須有至少 3 個部分：lang, script, region
  if (dashParts.length < 3) return null;
  
  const lang = dashParts[0];
  const scriptWithOrth = dashParts[1];
  const regionWithPlaces = dashParts[2];
  
  // 驗證 lang
  if (!LANG_CODE_RE.test(lang)) return null;
  
  // 解析 script 和可選的 orthography
  let script: string;
  let orthography: string | undefined;
  
  if (scriptWithOrth.includes('_')) {
    const scriptParts = scriptWithOrth.split('_');
    if (scriptParts.length !== 2) return null;
    script = scriptParts[0];
    orthography = scriptParts[1];
  } else {
    script = scriptWithOrth;
  }
  
  // 驗證 script
  if (!SCRIPT_CODE_RE.test(script)) return null;
  
  // 驗證 orthography（如果有）
  if (orthography && !ORTHOGRAPHY_RE.test(orthography)) return null;
  
  // 解析 region 和 place segments
  const regionParts = regionWithPlaces.split('_');
  const region = regionParts[0];
  const placeSegments = regionParts.slice(1);
  
  // 驗證 region
  if (!REGION_CODE_RE.test(region)) return null;
  
  // 驗證 place segments
  if (placeSegments.some(s => !PLACE_SEGMENT_RE.test(s))) return null;
  
  // 處理 dashParts 中剩餘的部分（如果有更多 place segments）
  const additionalPlaces = dashParts.slice(3);
  if (additionalPlaces.some(s => !PLACE_SEGMENT_RE.test(s))) return null;
  
  return {
    lang_code: lang,
    script_code: script,
    orthography,
    region_code: region,
    place_segments: [...placeSegments, ...additionalPlaces],
  };
}

export async function assertReferenceCodesExist(
  db: D1Database,
  langCode: string,
  scriptCode: string,
  regionCode: string,
): Promise<void> {
  const lang = await db.prepare('SELECT 1 FROM languages WHERE code = ?').bind(langCode).first();
  if (!lang) throw new LanguageLocaleError('INVALID_LANG_CODE');
  const script = await db.prepare('SELECT 1 FROM scripts WHERE code = ?').bind(scriptCode).first();
  if (!script) throw new LanguageLocaleError('INVALID_SCRIPT_CODE');
  const region = await db.prepare('SELECT 1 FROM regions WHERE code = ?').bind(regionCode).first();
  if (!region) throw new LanguageLocaleError('INVALID_REGION_CODE');
}
