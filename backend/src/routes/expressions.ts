import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import {
  badRequest,
  conflict,
  created,
  forbidden,
  internalError,
  paginated,
  success,
} from '../utils/response';
import { ExpressionError, createExpression, createLocaleAttestation, getExpression, searchExpressions } from '../services/expressions';
import { MappingError, createEdge, getExpressionMappings } from '../services/mappings';
import { ReadingError, createReading } from '../services/readings';
import { SplitError, splitExpression } from '../services/splits';
import { parseReferenceQuery } from '../services/languageIdentity';
import type { Bindings, Variables } from '../types';

const languageLocales = new Hono<{ Bindings: Bindings; Variables: Variables }>();

languageLocales.post('/', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const langCode = typeof body?.lang_code === 'string' ? body.lang_code.trim() : '';
    const text = typeof body?.text === 'string' ? body.text : '';
    const languageLocaleCode = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    try {
      const result = await createExpression(c.env.DB, {
        lang_code: langCode,
        text,
        ...(languageLocaleCode ? { language_locale_code: languageLocaleCode } : {}),
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Expression created') : success(c, result, 'Expression already exists');
    } catch (error) {
      if (error instanceof ExpressionError) {
        if (error.code === 'EXPRESSION_HASH_COLLISION') return conflict(c, error.code, error.code);
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Create expression error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create expression');
  }
});

languageLocales.get('/search', async (c) => {
  const query = parseReferenceQuery({
    q: c.req.query('q') ?? '',
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });
  const langCode = (c.req.query('lang_code') ?? '').toLowerCase();
  const result = await searchExpressions(c.env.DB, { ...query, lang_code: langCode || undefined });
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languageLocales.get('/:id', async (c) => {
  const id = c.req.param('id');
  const result = await getExpression(c.env.DB, id);
  if (!result) {
    return c.json({ success: false, error: 'EXPRESSION_NOT_FOUND', message: 'Expression not found' }, 404);
  }
  return success(c, result);
});

languageLocales.post('/:id/locale-attestations', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const languageLocaleCode = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    if (!languageLocaleCode) {
      return badRequest(c, 'VALIDATION_FAILED', 'language_locale_code is required');
    }
    let source: { type: string; name: string; ref?: string } | undefined;
    if (body?.source != null) {
      const s = body.source;
      if (typeof s !== 'object' || s === null || typeof s.type !== 'string' || typeof s.name !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source requires type and name');
      }
      if (s.ref != null && typeof s.ref !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source ref must be a string');
      }
      source = { type: s.type, name: s.name };
      if (typeof s.ref === 'string') source.ref = s.ref;
    }
    try {
      const result = await createLocaleAttestation(c.env.DB, {
        expression_id: id,
        language_locale_code: languageLocaleCode,
        ...(source ? { source } : {}),
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Attestation created') : success(c, result, 'Attestation already exists');
    } catch (error) {
      if (error instanceof ExpressionError) {
        if (error.code === 'EXPRESSION_NOT_FOUND') {
          return c.json({ success: false, error: error.code, message: 'Expression not found' }, 404);
        }
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Create attestation error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create attestation');
  }
});

languageLocales.post('/:id/readings', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const languageLocaleCode = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    const scheme = typeof body?.scheme === 'string' ? body.scheme.trim() : '';
    const value = typeof body?.value === 'string' ? body.value : '';
    if (!languageLocaleCode || !scheme || !value) {
      return badRequest(c, 'VALIDATION_FAILED', 'language_locale_code, scheme and value are required');
    }
    let source: { type: string; name: string; ref?: string } | undefined;
    if (body?.source != null) {
      const s = body.source;
      if (typeof s !== 'object' || s === null || typeof s.type !== 'string' || typeof s.name !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source requires type and name');
      }
      source = { type: s.type, name: s.name };
      if (typeof s.ref === 'string') source.ref = s.ref;
    }
    try {
      const result = await createReading(c.env.DB, {
        expression_id: id,
        language_locale_code: languageLocaleCode,
        scheme,
        value,
        ...(source ? { source } : {}),
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Reading created') : success(c, result, 'Reading already exists');
    } catch (error) {
      if (error instanceof ReadingError) {
        if (error.code === 'EXPRESSION_NOT_FOUND') return c.json({ success: false, error: error.code, message: 'Expression not found' }, 404);
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Create reading error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create reading');
  }
});

languageLocales.post('/:id/mappings', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const targetExpressionId = typeof body?.target_expression_id === 'string' ? body.target_expression_id.trim() : '';
    const source = typeof body?.source === 'string' ? body.source.trim() : '';
    if (!targetExpressionId || !source) {
      return badRequest(c, 'VALIDATION_FAILED', 'target_expression_id and source are required');
    }
    try {
      const result = await createEdge(c.env.DB, {
        expression_a_id: id,
        expression_b_id: targetExpressionId,
        source,
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Edge created') : success(c, result, 'Edge already exists');
    } catch (error) {
      if (error instanceof MappingError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Create edge error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create edge');
  }
});

languageLocales.get('/:id/mappings', async (c) => {
  const id = c.req.param('id') ?? '';
  const query = parseReferenceQuery({
    q: '',
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });
  const result = await getExpressionMappings(c.env.DB, id, { limit: query.limit, offset: query.offset });
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languageLocales.post('/:id/split', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (user?.role !== 'admin') return forbidden(c, 'FORBIDDEN', 'Split requires admin role');
    const id = c.req.param('id') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const edgeIds = Array.isArray(body?.edge_ids) ? body.edge_ids.filter((e: unknown): e is string => typeof e === 'string') : [];
    try {
      const result = await splitExpression(c.env.DB, {
        source_expression_id: id,
        edge_ids: edgeIds,
        created_by: user?.id ?? 0,
      });
      return success(c, result, 'Expression split completed');
    } catch (error) {
      if (error instanceof SplitError) {
        if (error.code === 'EXPRESSION_NOT_FOUND') return c.json({ success: false, error: error.code, message: 'Expression not found' }, 404);
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Split expression error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to split expression');
  }
});

export default languageLocales;
