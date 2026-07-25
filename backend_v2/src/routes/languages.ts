import { Hono } from 'hono';
import { success, notFound, paginated } from '../utils/response';
import type { Bindings } from '../types';

const languages = new Hono<{ Bindings: Bindings }>();

// GET /api/v2/languages — list all languages with expression counts
languages.get('/', async (c) => {
  const search = c.req.query('search') || '';
  const sort = c.req.query('sort') || 'count'; // count | alpha

  let query = `SELECT l.*, COALESCE(s.expression_count, 0) as expression_count
    FROM languages l LEFT JOIN language_stats s ON l.code = s.language_code`;
  const params: string[] = [];

  if (search) {
    query += ` WHERE l.name LIKE ? OR l.code LIKE ?`;
    params.push(`%${search}%`, `%${search}%`);
  }

  const SORT_MAP: Record<string, string> = {
    count: 'expression_count DESC, l.name',
    alpha: 'l.name',
  };
  query += ` ORDER BY ${SORT_MAP[sort] || SORT_MAP.count}`;

  const { results } = await c.env.DB.prepare(query).bind(...params).all();
  return success(c, results);
});

// GET /api/v2/languages/:code — language detail
languages.get('/:code', async (c) => {
  const code = c.req.param('code');
  const lang = await c.env.DB.prepare(
    `SELECT l.*, COALESCE(s.expression_count, 0) as expression_count
     FROM languages l LEFT JOIN language_stats s ON l.code = s.language_code
     WHERE l.code = ?`
  ).bind(code).first();
  if (!lang) return notFound(c, 'Language');

  const mappedCount = await c.env.DB.prepare(
    `SELECT COUNT(DISTINCT e.id) as count FROM expressions e
     INNER JOIN expression_edges ed ON e.id = ed.expression_a_id OR e.id = ed.expression_b_id
     WHERE e.language_code = ?`
  ).bind(code).first<{ count: number }>();

  return success(c, { ...lang, mapped_expression_count: mappedCount?.count || 0 });
});

// GET /api/v2/languages/:code/expressions — expressions in a language
languages.get('/:code/expressions', async (c) => {
  const code = c.req.param('code');
  const sort = c.req.query('sort') || 'new';
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '50') || 50, 1), 100);
  const offset = Math.max(parseInt(c.req.query('offset') || '0') || 0, 0);

  const EXPR_SORT_MAP: Record<string, string> = {
    new: 'e.created_at DESC',
    alpha: 'e.text',
    hot: 'mapping_count DESC, e.text',
  };
  const orderBy = EXPR_SORT_MAP[sort] || EXPR_SORT_MAP.new;

  const { results } = await c.env.DB.prepare(
    `SELECT e.*,
      (SELECT COUNT(*) FROM expression_edges ed
       WHERE e.id = ed.expression_a_id OR e.id = ed.expression_b_id) as mapping_count
     FROM expressions e
     WHERE e.language_code = ?
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`
  ).bind(code, limit, offset).all();

  const { count: total } = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM expressions WHERE language_code = ?`
  ).bind(code).first<{ count: number }>();

  return paginated(c, results, total, offset, limit);
});

export default languages;
