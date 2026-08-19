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

export class LanguageLocaleError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'LanguageLocaleError';
  }
}

export function buildLanguageLocaleCode(input: {
  lang_code: string;
  script_code: string;
  region_code: string;
  place_segments?: string[];
}): string {
  const lang = input.lang_code.toLowerCase();
  const script = input.script_code;
  const region = input.region_code;
  const segments = input.place_segments ?? [];
  if (!LANG_CODE_RE.test(lang)) throw new LanguageLocaleError('INVALID_LANG_CODE');
  if (!SCRIPT_CODE_RE.test(script)) throw new LanguageLocaleError('INVALID_SCRIPT_CODE');
  if (!REGION_CODE_RE.test(region)) throw new LanguageLocaleError('INVALID_REGION_CODE');
  for (const segment of segments) {
    if (!PLACE_SEGMENT_RE.test(segment)) throw new LanguageLocaleError('INVALID_PLACE_SEGMENT');
  }
  const placePath = segments.join('_');
  return `${lang}-${script}-${region}${placePath ? `_${placePath}` : ''}`;
}

export function parseLanguageLocaleCode(code: string): LanguageLocaleParts | null {
  if (!code) return null;
  const [head, ...segments] = code.split('_');
  const match = /^([a-z]{3})-([A-Z][a-z]{3})-([A-Z]{2})$/.exec(head ?? '');
  if (!match) return null;
  if (segments.some((segment) => segment === '' || !PLACE_SEGMENT_RE.test(segment))) return null;
  return {
    lang_code: match[1],
    script_code: match[2],
    region_code: match[3],
    place_segments: segments,
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
