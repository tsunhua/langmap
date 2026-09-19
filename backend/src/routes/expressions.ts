import { Hono } from 'hono';
import { optionalAuth, requireAuth } from '../middleware/auth';
import { badRequest, created, forbidden, internalError, notFoundCode, paginated, success, unauthorized } from '../utils/response';
import { ExpressionError, createExpression, createLocaleLink, getExpression, searchExpressions } from '../services/expressions';
import { ReadingError, createReading } from '../services/readings';
import { MappingError, createEdge, getExpressionMappings } from '../services/mappings';
import { SplitError, splitExpression } from '../services/splits';
import { getMappingGraph } from '../services/mappingGraph';
import { parseExpressionKey, resolveExpressionKey } from '../services/expressionKeys';
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

type RouteContext = Parameters<Parameters<typeof expressions.get>[1]>[0];
type TargetResult = { id: number } | { response: Response };

async function resolveKeyRow(c: RouteContext, lang: string, text: string, invalidCode: string): Promise<TargetResult> {
  const key = parseExpressionKey(lang, text);
  if (!key) return { response: badRequest(c, invalidCode) };
  const row = await resolveExpressionKey(c.env.DB, key);
  return row ? { id: row.id } : { response: notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found') };
}

// Every expression endpoint accepts both the legacy numeric id and the stable
// text key (`/:lang/:text`); the key survives id renumbering across migrations.
async function resolveTarget(c: RouteContext, form: 'id' | 'key'): Promise<TargetResult> {
  if (form === 'id') {
    const id = numberId(c.req.param('id'));
    return id ? { id } : { response: badRequest(c, 'INVALID_EXPRESSION_ID') };
  }
  return resolveKeyRow(c, c.req.param('lang'), c.req.param('text'), 'INVALID_EXPRESSION_KEY');
}

// Hono matches colliding patterns in registration order, and the two-segment
// sub-resource routes (/:id/graph, /:id/edges, ...) are registered before
// GET /:lang/:text. A key whose text segment IS the literal — e.g. /en/graph —
// therefore lands on the sub-resource route; fall back to key resolution so
// those expressions stay addressable.
async function resolveTargetWithLiteral(c: RouteContext, literal: string): Promise<TargetResult> {
  const id = numberId(c.req.param('id'));
  if (id) return { id };
  return resolveKeyRow(c, c.req.param('id'), literal, 'INVALID_EXPRESSION_ID');
}

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
  const target = await resolveTarget(c, 'id');
  return 'response' in target ? target.response : showExpression(c, target.id);
});

async function showExpression(c: RouteContext, id: number) {
  const result = await getExpression(c.env.DB, id); if (!result) return notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found');
  return success(c, { ...result, expression: expressionDto(result.expression), locales: result.locales.map((row) => ({ ...row, expression_id: serializeIntegerId(row.expression_id), locale_id: serializeIntegerId(row.locale_id) })), readings: result.readings.map((row) => ({ ...row, expression_id: serializeIntegerId(row.expression_id), locale_id: serializeIntegerId(row.locale_id) })), sources: result.sources.map((row) => ({ ...row, source_id: serializeIntegerId(row.source_id) })) });
}

async function showGraph(c: RouteContext, id: number) {
  const rawHops = Number.parseInt(c.req.query('hops') ?? '1', 10); if (![1, 2, 3].includes(rawHops)) return badRequest(c, 'INVALID_HOPS');
  if (rawHops === 3 && !c.get('user')) return unauthorized(c, 'AUTH_REQUIRED', 'Authentication is required for 3-hop graphs');
  const graph = await getMappingGraph(c.env.DB, id, rawHops as 1 | 2 | 3, c.req.query('target_language')?.toLowerCase());
  if (!graph) return notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found');
  return success(c, { ...graph, root_id: serializeIntegerId(graph.root_id), nodes: graph.nodes.map((node) => ({ ...node, expression_id: serializeIntegerId(node.expression_id) })), edges: graph.edges.map((edge) => ({ ...edge, edge_id: serializeIntegerId(edge.edge_id), source_id: serializeIntegerId(edge.source_id), target_id: serializeIntegerId(edge.target_id), sources: edge.sources.map((item) => ({ ...item, source_id: serializeIntegerId(item.source_id) })), annotations: (edge.annotations ?? []).map((item) => ({ ...item, source_id: item.source_id == null ? null : serializeIntegerId(item.source_id) })) })) });
}

expressions.get('/:id/graph', optionalAuth, async (c) => {
  const target = await resolveTargetWithLiteral(c, 'graph');
  return 'response' in target ? target.response : showGraph(c, target.id);
});
expressions.get('/:lang/:text/graph', optionalAuth, async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : showGraph(c, target.id);
});

async function addLocaleLink(c: RouteContext, id: number) {
  const body = await c.req.json<Body>().catch(() => ({}));
  try { const result = await createLocaleLink(c.env.DB, { expression_id: id, language_locale_code: typeof body.language_locale_code === 'string' ? body.language_locale_code.trim() : '' }); return (result.created ? created : success)(c, result); }
  catch (error) { return error instanceof ExpressionError ? (error.code === 'EXPRESSION_NOT_FOUND' ? notFoundCode(c, error.code, 'Expression not found') : badRequest(c, error.code)) : internalError(c); }
}

expressions.post('/:id/locales', requireAuth, async (c) => {
  const target = await resolveTargetWithLiteral(c, 'locales');
  return 'response' in target ? target.response : addLocaleLink(c, target.id);
});
expressions.post('/:lang/:text/locales', requireAuth, async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : addLocaleLink(c, target.id);
});

async function addReading(c: RouteContext, id: number) {
  const body = await c.req.json<Body>().catch(() => ({}));
  try { const source = sourceOf(body); const result = await createReading(c.env.DB, { expression_id: id, language_locale_code: typeof body.language_locale_code === 'string' ? body.language_locale_code.trim() : '', scheme: typeof body.scheme === 'string' ? body.scheme.trim() : '', value: typeof body.value === 'string' ? body.value : '', ...(source ? { source } : {}), created_by: c.get('user')?.id ?? 0 }); return (result.created ? created : success)(c, result); }
  catch (error) { return error instanceof ReadingError ? (error.code === 'EXPRESSION_NOT_FOUND' ? notFoundCode(c, error.code, 'Expression not found') : badRequest(c, error.code)) : internalError(c); }
}

expressions.post('/:id/readings', requireAuth, async (c) => {
  const target = await resolveTargetWithLiteral(c, 'readings');
  return 'response' in target ? target.response : addReading(c, target.id);
});
expressions.post('/:lang/:text/readings', requireAuth, async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : addReading(c, target.id);
});

async function addMapping(c: RouteContext, id: number) {
  const body = await c.req.json<Body>().catch(() => ({})); const target = typeof body.target_expression_id === 'string' ? numberId(body.target_expression_id) : null;
  if (!target) return badRequest(c, 'INVALID_EXPRESSION_ID');
  try { const result = await createEdge(c.env.DB, { expression_a_id: id, expression_b_id: target, relation_mask: typeof body.relation_mask === 'number' ? body.relation_mask : 1, created_by: c.get('user')?.id ?? 0 }); return (result.created ? created : success)(c, { ...result, edge: { ...result.edge, id: serializeIntegerId(result.edge.id), expression_a_id: serializeIntegerId(result.edge.expression_a_id), expression_b_id: serializeIntegerId(result.edge.expression_b_id) } }); }
  catch (error) { return error instanceof MappingError ? badRequest(c, error.code) : internalError(c); }
}

expressions.post('/:id/mappings', requireAuth, async (c) => {
  const target = await resolveTargetWithLiteral(c, 'mappings');
  return 'response' in target ? target.response : addMapping(c, target.id);
});
expressions.post('/:lang/:text/mappings', requireAuth, async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : addMapping(c, target.id);
});

async function runSplit(c: RouteContext, id: number) {
  if (c.get('user')?.role !== 'admin') return forbidden(c);
  const body = await c.req.json<Body>().catch(() => ({}));
  const edge_ids: number[] = [];
  if (Array.isArray(body.edge_ids)) {
    for (const value of body.edge_ids) {
      const parsed = typeof value === 'number' ? value : (typeof value === 'string' ? parseIntegerId(value) : null);
      if (parsed !== null) edge_ids.push(parsed);
    }
  }
  try {
    const result = await splitExpression(c.env.DB, { source_expression_id: id, edge_ids, created_by: c.get('user')?.id ?? 0 });
    return success(c, { ...result, split_id: serializeIntegerId(result.split_id), target_expression_id: serializeIntegerId(result.target_expression_id), target: result.target });
  } catch (error) { return error instanceof SplitError ? badRequest(c, error.code) : internalError(c); }
}

expressions.post('/:id/split', requireAuth, async (c) => {
  const target = await resolveTargetWithLiteral(c, 'split');
  return 'response' in target ? target.response : runSplit(c, target.id);
});
expressions.post('/:lang/:text/split', requireAuth, async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : runSplit(c, target.id);
});

async function showEdges(c: RouteContext, id: number) {
  const limit = Math.min(Math.max(Number(c.req.query('limit') ?? 20) || 20, 1), 50);
  const result = await getExpressionMappings(c.env.DB, id, { limit, cursor: c.req.query('cursor') });
  return success(c, { ...result, items: result.items.map((row) => ({ ...row, edge_id: serializeIntegerId(row.edge_id), neighbor_id: serializeIntegerId(row.neighbor_id) })) });
}

expressions.get('/:id/edges', async (c) => {
  const target = await resolveTargetWithLiteral(c, 'edges');
  return 'response' in target ? target.response : showEdges(c, target.id);
});
expressions.get('/:lang/:text/edges', async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : showEdges(c, target.id);
});

// Registered last so the two-segment sub-resource routes above keep winning
// their literal collisions (see resolveTargetWithLiteral).
expressions.get('/:lang/:text', async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : showExpression(c, target.id);
});

export default expressions;
