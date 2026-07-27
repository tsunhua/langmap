import { Hono } from 'hono';
import { success, notFound, badRequest, paginated } from '../utils/response';
import type { Bindings } from '../types';

interface LanguoidRow {
  id: string;
  glottocode: string;
  preferred_name: string;
  level: string;
  iso639_3: string | null;
  parent_id: string | null;
  latitude: number | null;
  longitude: number | null;
  status: string;
  source_version: string;
}

interface LanguageProfileRow {
  code: string;
  name: string;
  script_code: string | null;
  region_code: string | null;
  glottocode: string | null;
}

const languoids = new Hono<{ Bindings: Bindings }>();

languoids.get('/:id', async (c) => {
  const id = c.req.param('id');
  const row = await c.env.DB.prepare(
    `SELECT l.*, p.preferred_name AS parent_name
     FROM languoids l LEFT JOIN languoids p ON p.id = l.parent_id WHERE l.id = ?`
  ).bind(id).first();
  return row ? success(c, row) : notFound(c, 'Languoid');
});

languoids.get('/', async (c) => {
  const q = (c.req.query('q') || '').trim();
  const level = c.req.query('level') || '';
  const script = c.req.query('script') || '';
  const limit = Math.min(Math.max(Number(c.req.query('limit') || 50) || 50, 1), 100);
  const offset = Math.max(Number(c.req.query('offset') || 0) || 0, 0);

  const where: string[] = [];
  const params: (string | number)[] = [];

  if (q) {
    const isExactGlottocode = /^[a-z]{4}\d{4}$/.test(q) && q.length === 8;
    if (q.length < 2 && !isExactGlottocode) {
      return badRequest(c, 'QUERY_TOO_SHORT', 'Search query must be at least 2 characters');
    }
    where.push('(l.preferred_name LIKE ? OR l.glottocode LIKE ? OR l.iso639_3 LIKE ?)');
    params.push(`%${q}%`, `%${q}%`, `%${q}%`);
  }
  if (level) { where.push('l.level = ?'); params.push(level); }
  if (script) { where.push('c.script_code = ?'); params.push(script); }

  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';

  const langQuery = `
    SELECT l.*
    FROM languoids l
    LEFT JOIN languages c ON c.glottocode = l.glottocode
    ${clause}
    ORDER BY l.preferred_name ASC, l.id ASC
    LIMIT ? OFFSET ?
  `;
  const { results: languoids } = await c.env.DB.prepare(langQuery).bind(...params, limit, offset).all<LanguoidRow>();

  const countQuery = `SELECT COUNT(DISTINCT l.id) AS count FROM languoids l LEFT JOIN languages c ON c.glottocode = l.glottocode ${clause}`;
  const total = await c.env.DB.prepare(countQuery).bind(...params).first<{ count: number }>();

  if (languoids.length === 0) {
    return paginated(c, [], total?.count || 0, offset, limit);
  }

  const glottocodes = languoids.map(l => l.glottocode);
  const placeholders = glottocodes.map(() => '?').join(',');
  const profileResult = await c.env.DB.prepare(
    `SELECT code, name, script_code, region_code, glottocode
     FROM languages WHERE glottocode IN (${placeholders})
     ORDER BY name ASC, code ASC`
  ).bind(...glottocodes).all<LanguageProfileRow>();

  const profilesByGc = new Map<string, LanguageProfileRow[]>();
  for (const p of profileResult.results) {
    if (!p.glottocode) continue;
    if (!profilesByGc.has(p.glottocode)) profilesByGc.set(p.glottocode, []);
    profilesByGc.get(p.glottocode)!.push(p);
  }

  const items = languoids.map(l => ({
    ...l,
    profiles: profilesByGc.get(l.glottocode) || [],
  }));

  return paginated(c, items, total?.count || 0, offset, limit);
});

export default languoids;
