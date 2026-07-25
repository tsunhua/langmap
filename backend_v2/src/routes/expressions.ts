import { Hono } from 'hono';
import { success, notFound } from '../utils/response';
import type { Bindings } from '../types';

const expressions = new Hono<{ Bindings: Bindings }>();

// GET /search — search for expression picker
expressions.get('/search', async (c) => {
  const q = c.req.query('q') || '';
  const lang = c.req.query('lang') || '';
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '10') || 10, 1), 50);

  let query = `SELECT id, text, language_code FROM expressions WHERE 1=1`;
  const params: (string | number)[] = [];

  if (q) {
    query += ` AND text LIKE ?`;
    params.push(`%${q}%`);
  }
  if (lang) {
    query += ` AND language_code = ?`;
    params.push(lang);
  }
  query += ` ORDER BY text LIMIT ?`;
  params.push(limit);

  const { results } = await c.env.DB.prepare(query).bind(...params).all();
  return success(c, results);
});

// GET /:id — expression detail
expressions.get('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  const expr = await c.env.DB.prepare(
    `SELECT e.*, l.name as language_name
     FROM expressions e LEFT JOIN languages l ON e.language_code = l.code
     WHERE e.id = ?`
  ).bind(id).first();
  if (!expr) return notFound(c, 'Expression');
  return success(c, expr);
});

// GET /:id/mappings — all mappings (1-2 hops)
expressions.get('/:id/mappings', async (c) => {
  const id = parseInt(c.req.param('id'));
  const hops = Math.min(Math.max(parseInt(c.req.query('hops') || '1') || 1, 1), 3);

  const { results: direct } = await c.env.DB.prepare(
    `SELECT ed.id as edge_id, ed.score,
      CASE WHEN ed.expression_a_id = ? THEN ed.expression_b_id ELSE ed.expression_a_id END as expression_id,
      e.text, e.language_code, l.name as language_name
     FROM expression_edges ed
     INNER JOIN expressions e ON e.id = CASE WHEN ed.expression_a_id = ? THEN ed.expression_b_id ELSE ed.expression_a_id END
     LEFT JOIN languages l ON e.language_code = l.code
     WHERE ed.expression_a_id = ? OR ed.expression_b_id = ?
     ORDER BY ed.score DESC`
  ).bind(id, id, id, id).all();

  const allMappings = direct.map((d: any) => ({ ...d, hops: 1 }));

  if (hops >= 2) {
    const directIds = new Set([id, ...direct.map((d: any) => d.expression_id)]);
    const idsJson = JSON.stringify([...directIds]);

    const { results: second } = await c.env.DB.prepare(
      `SELECT DISTINCT
        CASE WHEN ed.expression_a_id IN (SELECT value FROM json_each(?))
          THEN ed.expression_b_id ELSE ed.expression_a_id END as expression_id,
        e.text, e.language_code, l.name as language_name, ed.score
       FROM expression_edges ed
       INNER JOIN expressions e ON e.id = CASE WHEN ed.expression_a_id IN (SELECT value FROM json_each(?))
         THEN ed.expression_b_id ELSE ed.expression_a_id END
       LEFT JOIN languages l ON e.language_code = l.code
       WHERE (ed.expression_a_id IN (SELECT value FROM json_each(?))
           OR ed.expression_b_id IN (SELECT value FROM json_each(?)))
       ORDER BY ed.score DESC LIMIT 100`
    ).bind(idsJson, idsJson, idsJson, idsJson).all();

    allMappings.push(...second
      .filter((s: any) => !directIds.has(s.expression_id))
      .map((s: any) => ({ ...s, hops: 2, edge_id: null }))
    );
  }

  return success(c, allMappings);
});

export default expressions;
