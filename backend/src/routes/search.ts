import { Hono } from 'hono';
import { success, paginated } from '../utils/response';
import type { Bindings } from '../types';

const search = new Hono<{ Bindings: Bindings }>();

const SORT_MAP: Record<string, string> = {
  new: 'e.created_at DESC',
  alpha: 'e.text',
  hot: 'mapping_count DESC, e.text',
};

search.get('/expressions', async (c) => {
  const q = c.req.query('q') || '';
  const lang = c.req.query('lang') || '';
  const sort = c.req.query('sort') || 'new';
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '50') || 50, 1), 100);
  const offset = Math.max(parseInt(c.req.query('offset') || '0') || 0, 0);

  if (!q) return paginated(c, [], 0, 0, limit);

  const orderBy = SORT_MAP[sort] || SORT_MAP.new;

  let langFilter = '';
  const langParams: string[] = [];
  if (lang) {
    const langs = lang.split(',').map(l => l.trim()).filter(Boolean);
    if (langs.length) {
      langFilter = `AND e.language_profile_code IN (${langs.map(() => '?').join(',')})`;
      langParams.push(...langs);
    }
  }

  const { results } = await c.env.DB.prepare(
    `SELECT e.*,
      (SELECT COUNT(*) FROM expression_edges ed
       WHERE e.id = ed.expression_a_id OR e.id = ed.expression_b_id) as mapping_count
     FROM expressions e
     WHERE e.text LIKE ? ${langFilter}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`
  ).bind(`%${q}%`, ...langParams, limit, offset).all();

  const { count: total } = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM expressions e WHERE e.text LIKE ? ${langFilter}`
  ).bind(`%${q}%`, ...langParams).first<{ count: number }>();

  return paginated(c, results, total, offset, limit);
});

export default search;
