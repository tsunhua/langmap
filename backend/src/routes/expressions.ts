import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, created, internalError, notFoundCode, paginated, success } from '../utils/response';
import { ExpressionError, createExpression, createLocaleLink, getExpression, searchExpressions } from '../services/expressions';
import { ReadingError, createReading } from '../services/readings';
import { MappingError, createEdge, getExpressionMappings } from '../services/mappings';
import { getMappingGraph } from '../services/mappingGraph';
import { parseIntegerId, serializeIntegerId } from '../utils/ids';
import type { Bindings, Variables } from '../types';

const expressions = new Hono<{ Bindings: Bindings; Variables: Variables }>();
type Body = Record<string, unknown>;
function sourceOf(body: Body): { type: string; name: string } | undefined {
  if (body.source == null) return undefined;
  const source = body.source;
  if (typeof source !== 'object' || source === null || typeof (source as Body).type !== 'string' || typeof (source as Body).name !== 'string') throw new ExpressionError('INVALID_SOURCE');
  return { type: (source as Record<string, string>).type, name: (source as Record<string, string>).name };
}
const numberId = (value: string) => parseIntegerId(value);
const expressionDto = <T extends { id: number }>(row: T) => ({ ...row, id: serializeIntegerId(row.id) });

expressions.post('/', requireAuth, async (c) => {
  try {
    const body = await c.req.json<Body>().catch(() => ({})); const source = sourceOf(body);
    const result = await createExpression(c.env.DB, { lang_code: typeof body.lang_code === 'string' ? body.lang_code.trim() : '', text: typeof body.text === 'string' ? body.text : '', ...(typeof body.language_locale_code === 'string' ? { language_locale_code: body.language_locale_code.trim() } : {}), ...(typeof body.pos_mask === 'number' ? { pos_mask: body.pos_mask } : {}), ...(source ? { source } : {}), created_by: c.get('user')?.id ?? 0 });
    return (result.created ? created : success)(c, { ...result, expression: expressionDto(result.expression) });
  } catch (error) { return error instanceof ExpressionError ? badRequest(c, error.code) : (console.error('Create expression error:', error), internalError(c)); }
});

expressions.get('/search', async (c) => {
  const limit = Math.min(Math.max(Number(c.req.query('limit') ?? 20) || 20, 1), 50); const offset = Math.max(Number.parseInt(c.req.query('offset') ?? '0', 10) || 0, 0);
  const result = await searchExpressions(c.env.DB, { q: c.req.query('q') ?? '', lang_code: c.req.query('lang_code')?.toLowerCase(), limit, offset });
  return paginated(c, result.items.map(expressionDto), result.total, offset, limit);
});

expressions.get('/:id', async (c) => {
  const id = numberId(c.req.param('id')); if (!id) return badRequest(c, 'INVALID_EXPRESSION_ID');
  const result = await getExpression(c.env.DB, id); if (!result) return notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found');
  return success(c, { ...result, expression: expressionDto(result.expression), locales: result.locales.map((row) => ({ ...row, expression_id: serializeIntegerId(row.expression_id), locale_id: serializeIntegerId(row.locale_id) })), readings: result.readings.map((row) => ({ ...row, expression_id: serializeIntegerId(row.expression_id), locale_id: serializeIntegerId(row.locale_id) })) });
});

expressions.get('/:id/graph', async (c) => {
  const id = numberId(c.req.param('id')); if (!id) return badRequest(c, 'INVALID_EXPRESSION_ID');
  const rawHops = Number.parseInt(c.req.query('hops') ?? '1', 10); if (![1, 2, 3].includes(rawHops)) return badRequest(c, 'INVALID_HOPS');
  const graph = await getMappingGraph(c.env.DB, id, rawHops as 1 | 2 | 3, c.req.query('target_language')?.toLowerCase());
  if (!graph) return notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found');
  return success(c, { ...graph, root_id: serializeIntegerId(graph.root_id), nodes: graph.nodes.map((node) => ({ ...node, expression_id: serializeIntegerId(node.expression_id) })), edges: graph.edges.map((edge) => ({ ...edge, edge_id: serializeIntegerId(edge.edge_id), source_id: serializeIntegerId(edge.source_id), target_id: serializeIntegerId(edge.target_id) })) });
});

expressions.post('/:id/locales', requireAuth, async (c) => {
  const id = numberId(c.req.param('id')); if (!id) return badRequest(c, 'INVALID_EXPRESSION_ID'); const body = await c.req.json<Body>().catch(() => ({}));
  try { const result = await createLocaleLink(c.env.DB, { expression_id: id, language_locale_code: typeof body.language_locale_code === 'string' ? body.language_locale_code.trim() : '' }); return (result.created ? created : success)(c, result); }
  catch (error) { return error instanceof ExpressionError ? (error.code === 'EXPRESSION_NOT_FOUND' ? notFoundCode(c, error.code, 'Expression not found') : badRequest(c, error.code)) : internalError(c); }
});

expressions.post('/:id/readings', requireAuth, async (c) => {
  const id = numberId(c.req.param('id')); if (!id) return badRequest(c, 'INVALID_EXPRESSION_ID'); const body = await c.req.json<Body>().catch(() => ({}));
  try { const source = sourceOf(body); const result = await createReading(c.env.DB, { expression_id: id, language_locale_code: typeof body.language_locale_code === 'string' ? body.language_locale_code.trim() : '', scheme: typeof body.scheme === 'string' ? body.scheme.trim() : '', value: typeof body.value === 'string' ? body.value : '', ...(source ? { source } : {}), created_by: c.get('user')?.id ?? 0 }); return (result.created ? created : success)(c, { ...result, reading: { ...result.reading, expression_id: serializeIntegerId(result.reading.expression_id), locale_id: serializeIntegerId(result.reading.locale_id) } }); }
  catch (error) { return error instanceof ReadingError ? (error.code === 'EXPRESSION_NOT_FOUND' ? notFoundCode(c, error.code, 'Expression not found') : badRequest(c, error.code)) : internalError(c); }
});

expressions.post('/:id/mappings', requireAuth, async (c) => {
  const id = numberId(c.req.param('id')); if (!id) return badRequest(c, 'INVALID_EXPRESSION_ID'); const body = await c.req.json<Body>().catch(() => ({})); const target = typeof body.target_expression_id === 'string' ? numberId(body.target_expression_id) : null;
  if (!target) return badRequest(c, 'INVALID_EXPRESSION_ID');
  try { const result = await createEdge(c.env.DB, { expression_a_id: id, expression_b_id: target, relation_mask: typeof body.relation_mask === 'number' ? body.relation_mask : 1, created_by: c.get('user')?.id ?? 0 }); return (result.created ? created : success)(c, { ...result, edge: { ...result.edge, id: serializeIntegerId(result.edge.id), expression_a_id: serializeIntegerId(result.edge.expression_a_id), expression_b_id: serializeIntegerId(result.edge.expression_b_id) } }); }
  catch (error) { return error instanceof MappingError ? badRequest(c, error.code) : internalError(c); }
});

expressions.get('/:id/edges', async (c) => {
  const id = numberId(c.req.param('id')); if (!id) return badRequest(c, 'INVALID_EXPRESSION_ID'); const limit = Math.min(Math.max(Number(c.req.query('limit') ?? 20) || 20, 1), 50);
  const result = await getExpressionMappings(c.env.DB, id, { limit, cursor: c.req.query('cursor') });
  return success(c, { ...result, items: result.items.map((row) => ({ ...row, edge_id: serializeIntegerId(row.edge_id), neighbor_id: serializeIntegerId(row.neighbor_id) })) });
});

export default expressions;
