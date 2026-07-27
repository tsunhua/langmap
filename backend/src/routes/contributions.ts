import { Hono } from 'hono';
import { success, badRequest } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import type { Bindings, Variables } from '../types';
import { expressionId as computeExpressionId, stableEdgeId } from '../utils/ids';
import { requireRegisteredLanguage } from '../services/languageRegistry';

const contributions = new Hono<{ Bindings: Bindings; Variables: Variables }>();

async function edgesForGroup(memberIds: number[]): Promise<{ id: string; a: number; b: number }[]> {
  const ids = [...new Set(memberIds)].sort((x, y) => x - y);
  const out: { id: string; a: number; b: number }[] = [];
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      const a = ids[i], b = ids[j];
      out.push({ id: await stableEdgeId(a, b), a, b });
    }
  }
  return out;
}

contributions.post('/batch', requireAuth, async (c) => {
  const user = c.get('user')!;
  const { expressions: exprs } = await c.req.json<{
    expressions: { lang: string; text: string; region?: string }[];
  }>();

  if (!exprs || exprs.length < 2) return badRequest(c, 'need_at_least_2_expressions');
  if (exprs.length > 50) return badRequest(c, 'too_many_expressions');

  const uniqueLangs = [...new Set(exprs.map(e => e.lang?.trim() || ''))];
  for (const lang of uniqueLangs) {
    if (!lang) {
      return badRequest(c, 'invalid_expression', 'Each expression needs non-empty text and language');
    }
    const reg = await requireRegisteredLanguage(c.env.DB, lang);
    if (!reg) {
      return badRequest(c, 'INVALID_LANGUAGE_CODE', 'language_code must reference a registered language', { codes: uniqueLangs });
    }
  }

  const exprIds: number[] = [];
  const statements: D1Statement[] = [];
  const seenExpressions = new Map<string, number>();

  for (const e of exprs) {
    const text = e.text?.trim() || '';
    const lang = e.lang?.trim() || '';

    if (!text || !lang) {
      return badRequest(c, 'invalid_expression', 'Each expression needs non-empty text and language');
    }

    const key = `${text}|${lang}`;
    const cachedId = seenExpressions.get(key);
    if (cachedId !== undefined) {
      exprIds.push(cachedId);
      continue;
    }

    const existing = await c.env.DB.prepare(
      `SELECT id FROM expressions WHERE text = ? AND language_code = ? LIMIT 1`
    ).bind(text, lang).first<{ id: number }>();

    const id = existing?.id ?? await computeExpressionId(lang, text);
    seenExpressions.set(key, id);
    exprIds.push(id);

    if (!existing) {
      statements.push(
        c.env.DB.prepare(
          `INSERT OR IGNORE INTO expressions (id, text, language_code, region_name, source_type, created_by, review_status)
           VALUES (?, ?, ?, ?, 'user', ?, 'pending')`
        ).bind(id, text, lang, e.region || null, user.username)
      );
    }
  }

  const edges = await edgesForGroup(exprIds);
  for (const edge of edges) {
    statements.push(
      c.env.DB.prepare(
        `INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by)
         VALUES (?, ?, ?, 0, 'batch', ?)`
      ).bind(edge.id, edge.a, edge.b, user.username)
    );
  }

  await c.env.DB.batch(statements);

  return success(c, {
    expressionCount: exprIds.length,
    mappingCount: edges.length,
    expressionIds: exprIds,
  });
});

export default contributions;
