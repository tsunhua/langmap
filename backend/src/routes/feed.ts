import { Hono } from 'hono';
import { success } from '../utils/response';
import type { Bindings } from '../types';

const feed = new Hono<{ Bindings: Bindings }>();

function parseLimit(value: string | undefined): number {
  const parsed = Number.parseInt(value ?? '20', 10);
  return Number.isFinite(parsed) ? Math.min(Math.max(parsed, 1), 100) : 20;
}

const EDGE_COLUMNS = `ed.id, ed.score, ed.source, ed.created_at,
  a.id AS a_id, a.text AS a_text, a.lang_code AS a_lang,
  b.id AS b_id, b.text AS b_text, b.lang_code AS b_lang`;

feed.get('/hot', async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT ${EDGE_COLUMNS}
     FROM expression_edges ed
     JOIN expressions a ON a.id = ed.expression_a_id
     JOIN expressions b ON b.id = ed.expression_b_id
     ORDER BY ed.score DESC, ed.created_at DESC, ed.id ASC
     LIMIT ?`,
  ).bind(parseLimit(c.req.query('limit'))).all();
  return success(c, results);
});

feed.get('/new', async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT * FROM (
       SELECT 'mapping' AS type, ed.id AS id, ed.created_at, u.username AS author,
              a.id AS a_id, b.id AS b_id,
              a.text AS left_text, a.lang_code AS left_lang,
              b.text AS right_text, b.lang_code AS right_lang
       FROM expression_edges ed
       JOIN expressions a ON a.id = ed.expression_a_id
       JOIN expressions b ON b.id = ed.expression_b_id
       LEFT JOIN users u ON u.id = ed.created_by
       UNION ALL
       SELECT 'expression' AS type, e.id, e.created_at, u.username AS author,
              NULL AS a_id, NULL AS b_id,
              e.text AS left_text, e.lang_code AS left_lang, NULL AS right_text, NULL AS right_lang
       FROM expressions e
       LEFT JOIN users u ON u.id = e.created_by
     ) ORDER BY created_at DESC, id ASC
     LIMIT ?`,
  ).bind(parseLimit(c.req.query('limit'))).all();
  return success(c, results);
});

export default feed;
