import type { D1Database } from '@cloudflare/workers-types';

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
  scripts: ['code', 'name_en', 'direction'],
  regions: ['code', 'name_en', 'latitude', 'longitude'],
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
