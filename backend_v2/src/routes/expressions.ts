import { Hono } from 'hono';
import { success, notFound } from '../utils/response';
import { buildMappingGraph, parseMappingHops } from '../utils/mappingGraph';
import type { Bindings } from '../types';
import type { LoadEdges, LoadExpressions, NeighborRow, ExpressionRow } from '../utils/mappingGraph';

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

// GET /:id/mappings — graph of mappings within 1-3 hops from the root expression
expressions.get('/:id/mappings', async (c) => {
  const id = parseInt(c.req.param('id'));

  const root = await c.env.DB.prepare(
    `SELECT id FROM expressions WHERE id = ?`
  ).bind(id).first();
  if (!root) return notFound(c, 'Expression');

  const requestedHops = parseMappingHops(c.req.query('hops'));

  // D1 limits bound parameters per query. Keep chunks well under that ceiling.
  // loadEdges binds each id twice (two IN clauses), so its chunk is the smaller one.
  const EDGE_CHUNK = 40;
  const EXPR_CHUNK = 90;

  const loadEdges: LoadEdges = async (frontierIds: number[]): Promise<NeighborRow[]> => {
    if (frontierIds.length === 0) return [];
    const out: NeighborRow[] = [];
    for (let i = 0; i < frontierIds.length; i += EDGE_CHUNK) {
      const chunk = frontierIds.slice(i, i + EDGE_CHUNK);
      const placeholders = chunk.map(() => '?').join(',');
      const { results } = await c.env.DB.prepare(
        `SELECT id as edge_id, expression_a_id, expression_b_id, score
         FROM expression_edges
         WHERE expression_a_id IN (${placeholders}) OR expression_b_id IN (${placeholders})
         ORDER BY score DESC, id ASC`
      ).bind(...chunk, ...chunk).all<NeighborRow>();
      out.push(...results);
    }
    return out;
  };

  const loadExpressions: LoadExpressions = async (ids: number[]): Promise<ExpressionRow[]> => {
    if (ids.length === 0) return [];
    const out: ExpressionRow[] = [];
    for (let i = 0; i < ids.length; i += EXPR_CHUNK) {
      const chunk = ids.slice(i, i + EXPR_CHUNK);
      const placeholders = chunk.map(() => '?').join(',');
      const { results } = await c.env.DB.prepare(
        `SELECT e.id as expression_id, e.text, e.language_code, l.name as language_name
         FROM expressions e LEFT JOIN languages l ON e.language_code = l.code
         WHERE e.id IN (${placeholders})
         ORDER BY e.id ASC`
      ).bind(...chunk).all<ExpressionRow>();
      out.push(...results);
    }
    return out;
  };

  const graph = await buildMappingGraph(id, requestedHops, loadEdges, loadExpressions);
  return success(c, graph);
});

export default expressions;
