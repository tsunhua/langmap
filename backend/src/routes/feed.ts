import { Hono } from 'hono';
import { success } from '../utils/response';
import type { Bindings } from '../types';

const feed = new Hono<{ Bindings: Bindings }>();

feed.get('/hot', async (c) => {
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '20') || 20, 1), 50);
  const { results } = await c.env.DB.prepare(
    `SELECT ed.id as edge_id, ed.expression_a_id as id, ed.score, ed.source,
      a.id as a_id, a.text as a_text, a.language_code as a_lang,
      b.id as b_id, b.text as b_text, b.language_code as b_lang,
      (SELECT COUNT(DISTINCT e2.region_code) FROM expressions e2 WHERE e2.id IN (ed.expression_a_id, ed.expression_b_id) AND e2.region_code IS NOT NULL) as region_count
     FROM expression_edges ed
     INNER JOIN expressions a ON ed.expression_a_id = a.id
     INNER JOIN expressions b ON ed.expression_b_id = b.id
     WHERE ed.score > 0
     ORDER BY ed.score DESC
     LIMIT ?`
  ).bind(limit).all();
  return success(c, results);
});

feed.get('/new', async (c) => {
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '20') || 20, 1), 50);
  const { results } = await c.env.DB.prepare(
    `SELECT * FROM (
       SELECT 'mapping' as type, CAST(ed.expression_a_id AS TEXT) as id,
         ed.created_at as created_at, ed.created_by as author,
         a.text as left_text, a.language_code as left_lang,
         b.text as right_text, b.language_code as right_lang,
         (SELECT COUNT(DISTINCT e2.region_code) FROM expressions e2
          WHERE e2.id IN (ed.expression_a_id, ed.expression_b_id)
          AND e2.region_code IS NOT NULL) as region_count
       FROM expression_edges ed
       INNER JOIN expressions a ON ed.expression_a_id = a.id
       INNER JOIN expressions b ON ed.expression_b_id = b.id

       UNION ALL

       SELECT 'expression' as type, CAST(e.id AS TEXT) as id,
         e.created_at as created_at, e.created_by as author,
         e.text as left_text, e.language_code as left_lang,
         NULL as right_text, NULL as right_lang, 0 as region_count
       FROM expressions e
     )
     ORDER BY created_at DESC, type ASC, id DESC
     LIMIT ?`
  ).bind(limit).all();
  return success(c, results);
});

export default feed;
