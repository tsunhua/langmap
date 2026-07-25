import { Hono } from 'hono';
import { success, badRequest } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import type { Bindings, Variables } from '../types';

const contributions = new Hono<{ Bindings: Bindings; Variables: Variables }>();

function fnv1a(str: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = (hash * 0x01000193) >>> 0;
  }
  return hash;
}

function edgesForGroup(memberIds: number[]): { id: string; a: number; b: number }[] {
  const ids = [...new Set(memberIds)].sort((x, y) => x - y);
  const out: { id: string; a: number; b: number }[] = [];
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      const a = ids[i], b = ids[j];
      out.push({ id: `${a}-${b}`, a, b });
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

  const exprIds: number[] = [];
  const statements: D1Statement[] = [];

  for (const e of exprs) {
    const id = fnv1a(`${e.text}|${e.lang}`);
    exprIds.push(id);
    statements.push(
      c.env.DB.prepare(
        `INSERT OR IGNORE INTO expressions (id, text, language_code, region_name, source_type, created_by, review_status)
         VALUES (?, ?, ?, ?, 'user', ?, 'pending')`
      ).bind(id, e.text, e.lang, e.region || null, user.username)
    );
  }

  const edges = edgesForGroup(exprIds);
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
