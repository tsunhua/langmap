import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, created, internalError, unauthorized } from '../utils/response';
import { ExpressionError, createExpression } from '../services/expressions';
import { MappingError, createEdgesBatch } from '../services/mappings';
import type { Bindings, Variables } from '../types';

const contributions = new Hono<{ Bindings: Bindings; Variables: Variables }>();

interface ExpressionInput {
  lang_code: string;
  text: string;
  language_locale_code?: string;
}

function parseExpressionInputs(raw: unknown): ExpressionInput[] {
  if (!Array.isArray(raw)) return [];
  const out: ExpressionInput[] = [];
  for (const item of raw) {
    const entry = item as { lang_code?: unknown; text?: unknown; language_locale_code?: unknown };
    const langCode = typeof entry?.lang_code === 'string' ? entry.lang_code.trim() : '';
    const text = typeof entry?.text === 'string' ? entry.text : '';
    if (!langCode || !text.trim()) continue;
    const localeCode = typeof entry?.language_locale_code === 'string' ? entry.language_locale_code.trim() : '';
    out.push({ lang_code: langCode, text, ...(localeCode ? { language_locale_code: localeCode } : {}) });
  }
  return out;
}

// Keep the former /batch endpoint working while the collection endpoint becomes canonical.
contributions.post('/', requireAuth, async (c) => {
  const url = new URL(c.req.url);
  url.pathname = `${url.pathname.replace(/\/$/, '')}/batch`;
  return contributions.fetch(new Request(url, c.req.raw), c.env, c.executionCtx);
});

contributions.post('/batch', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const body = await c.req.json().catch(() => ({}));
    const inputs = parseExpressionInputs((body as { expressions?: unknown })?.expressions);

    if (inputs.length < 2) {
      return badRequest(c, 'CONTRIBUTION_TOO_FEW_EXPRESSIONS', 'At least two valid expressions are required');
    }

    const expressionIds: string[] = [];
    const expressions: unknown[] = [];
    try {
      for (const input of inputs) {
        const result = await createExpression(c.env.DB, { ...input, created_by: user.id });
        expressionIds.push(result.expression.id);
        expressions.push({ expression: result.expression, created: result.created });
      }
    } catch (error) {
      if (error instanceof ExpressionError) return badRequest(c, error.code, error.code);
      throw error;
    }

    const uniqueIds = Array.from(new Set(expressionIds));
    if (uniqueIds.length < 2) {
      return badRequest(c, 'CONTRIBUTION_TOO_FEW_EXPRESSIONS', 'Expressions resolved to fewer than two distinct entries');
    }

    try {
      const edgeResult = await createEdgesBatch(c.env.DB, {
        expression_ids: uniqueIds,
        source: 'contribution',
        created_by: user.id,
      });
      return created(
        c,
        {
          expressions,
          edges: edgeResult.edges,
          created_edge_count: edgeResult.created_count,
        },
        'Contribution batch created',
      );
    } catch (error) {
      if (error instanceof MappingError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Contribution batch error:', error);
    return internalError(c);
  }
});

export default contributions;
