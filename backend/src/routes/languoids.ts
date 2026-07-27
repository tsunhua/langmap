import { Hono } from 'hono';
import { success, notFound, paginated } from '../utils/response';
import type { Bindings } from '../types';

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
  if (q) { where.push('(l.preferred_name LIKE ? OR l.glottocode LIKE ? OR l.iso639_3 LIKE ? OR c.code LIKE ?)'); params.push(`%${q}%`, `%${q}%`, `%${q}%`, `%${q}%`); }
  if (level) { where.push('l.level = ?'); params.push(level); }
  if (script) { where.push('c.script_code = ?'); params.push(script); }
  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const query = `SELECT l.*, c.code AS content_code FROM languoids l LEFT JOIN languages c ON c.glottocode = l.glottocode ${clause} ORDER BY l.preferred_name, l.id LIMIT ? OFFSET ?`;
  const { results } = await c.env.DB.prepare(query).bind(...params, limit, offset).all();
  const total = await c.env.DB.prepare(`SELECT COUNT(*) AS count FROM languoids l LEFT JOIN languages c ON c.glottocode = l.glottocode ${clause}`).bind(...params).first<{ count: number }>();
  return paginated(c, results, total?.count || 0, offset, limit);
});

export default languoids;
