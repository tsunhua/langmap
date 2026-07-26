import { Hono } from 'hono';
import { success, badRequest, notFound } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import type { Bindings, Variables } from '../types';

const mappings = new Hono<{ Bindings: Bindings; Variables: Variables }>();

mappings.post('/:id/vote', requireAuth, async (c) => {
  const edgeId = c.req.param('id');
  const user = c.get('user')!;
  const { direction } = await c.req.json<{ direction: 'up' | 'down' }>();
  if (direction !== 'up' && direction !== 'down') return badRequest(c, 'invalid_direction');

  const vote = direction === 'up' ? 1 : -1;

  const existing = await c.env.DB.prepare(
    `SELECT id, vote FROM votes WHERE user_id = ? AND target_type = 'mapping' AND target_id = ?`
  ).bind(user.id, edgeId).first<{ id: number; vote: number }>();

  let voteDelta = vote;
  if (existing) {
    if (existing.vote === vote) {
      await c.env.DB.prepare(`DELETE FROM votes WHERE id = ?`).bind(existing.id).run();
      voteDelta = -vote;
    } else {
      await c.env.DB.prepare(`UPDATE votes SET vote = ? WHERE id = ?`).bind(vote, existing.id).run();
      voteDelta = vote * 2;
    }
  } else {
    const voteId = `${user.id}-mapping-${edgeId}`;
    await c.env.DB.prepare(
      `INSERT INTO votes (id, user_id, target_type, target_id, vote) VALUES (?, ?, 'mapping', ?, ?)`
    ).bind(voteId, user.id, edgeId, vote).run();
  }

  await c.env.DB.prepare(
    `UPDATE expression_edges SET score = score + ? WHERE id = ?`
  ).bind(voteDelta, edgeId).run();

  // UI bundles are cached by locale revision; a vote can change their winner.
  await c.env.DB.prepare(
    `UPDATE ui_locales SET mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP
     WHERE (project_id, code) IN (
       SELECT m.project_id, te.language_code
       FROM ui_messages m
       JOIN expression_edges ed ON ed.id = ?
       JOIN expressions te ON te.id = CASE
         WHEN ed.expression_a_id = m.source_expression_id THEN ed.expression_b_id
         ELSE ed.expression_a_id END
       WHERE m.status = 'active'
     )`
  ).bind(edgeId).run();

  const edge = await c.env.DB.prepare(
    `SELECT score FROM expression_edges WHERE id = ?`
  ).bind(edgeId).first<{ score: number }>();

  return success(c, { score: edge?.score || 0 });
});

export default mappings;
