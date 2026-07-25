import { Hono } from 'hono';
import { success, created, notFound, badRequest, paginated, forbidden } from '../utils/response';
import { requireAuth, optionalAuth } from '../middleware/auth';
import type { Bindings, Variables } from '../types';

const handbooks = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// GET / — list public handbooks
handbooks.get('/', optionalAuth, async (c) => {
  const sort = c.req.query('sort') === 'hot' ? 'hot' : 'new';
  const search = c.req.query('search') || '';
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '20') || 20, 1), 100);
  const offset = Math.max(parseInt(c.req.query('offset') || '0') || 0, 0);

  let where = `WHERE h.visibility = 'public'`;
  const params: (string | number)[] = [];

  if (search) {
    where += ` AND h.title LIKE ?`;
    params.push(`%${search}%`);
  }

  const order = sort === 'hot' ? 'h.score DESC, h.created_at DESC' : 'h.created_at DESC';

  const countRow = await c.env.DB.prepare(
    `SELECT COUNT(*) as total FROM handbooks h ${where}`
  ).bind(...params).first<{ total: number }>();
  const total = countRow?.total || 0;

  const { results } = await c.env.DB.prepare(
    `SELECT h.id, h.title, h.visibility, h.score, h.created_at, h.updated_at,
      u.username as author_username,
      (SELECT COUNT(*) FROM handbook_sections WHERE handbook_id = h.id) as section_count,
      (SELECT COALESCE(SUM(cnt), 0) FROM (
        SELECT COUNT(*) as cnt FROM handbook_section_items hsi
        JOIN handbook_sections hs ON hs.id = hsi.section_id
        WHERE hs.handbook_id = h.id
      )) as expression_count
     FROM handbooks h
     JOIN users u ON u.id = h.user_id
     ${where}
     ORDER BY ${order}
     LIMIT ? OFFSET ?`
  ).bind(...params, limit, offset).all();

  return paginated(c, results, total, offset, limit);
});

// GET /:id — handbook detail
handbooks.get('/:id', optionalAuth, async (c) => {
  const id = parseInt(c.req.param('id'));

  const handbook = await c.env.DB.prepare(
    `SELECT h.*, u.username as author_username
     FROM handbooks h JOIN users u ON u.id = h.user_id
     WHERE h.id = ?`
  ).bind(id).first();
  if (!handbook) return notFound(c, 'Handbook');

  const { results: sections } = await c.env.DB.prepare(
    `SELECT * FROM handbook_sections WHERE handbook_id = ? ORDER BY position`
  ).bind(id).all();

  const sectionIds = sections.map((s: any) => s.id);
  let items: any[] = [];
  if (sectionIds.length > 0) {
    const idsJson = JSON.stringify(sectionIds);
    const { results } = await c.env.DB.prepare(
      `SELECT hsi.*, e.text, e.language_code, l.name as language_name
       FROM handbook_section_items hsi
       JOIN expressions e ON e.id = hsi.expression_id
       LEFT JOIN languages l ON e.language_code = l.code
       WHERE hsi.section_id IN (SELECT value FROM json_each(?))
       ORDER BY hsi.section_id, hsi.position`
    ).bind(idsJson).all();
    items = results;
  }

  const sectionsWithItems = sections.map((s: any) => ({
    ...s,
    items: items.filter((i: any) => i.section_id === s.id),
  }));

  return success(c, { ...handbook, sections: sectionsWithItems });
});

// POST / — create handbook
handbooks.post('/', requireAuth, async (c) => {
  const user = c.get('user')!;
  const body = await c.req.json<{
    title: string;
    visibility?: string;
    sections: { title: string; expressionIds: number[] }[];
  }>();

  if (!body.title) return badRequest(c, 'title_required');
  if (!body.sections || body.sections.length === 0) return badRequest(c, 'sections_required');

  const visibility = body.visibility === 'private' ? 'private' : 'public';

  const { meta } = await c.env.DB.prepare(
    `INSERT INTO handbooks (user_id, title, visibility) VALUES (?, ?, ?)`
  ).bind(user.id, body.title, visibility).run();
  const handbookId = meta.last_row_id;

  const statements: D1Statement[] = [];
  const sectionIds: number[] = [];

  for (let i = 0; i < body.sections.length; i++) {
    const sec = body.sections[i];
    const stmt = c.env.DB.prepare(
      `INSERT INTO handbook_sections (handbook_id, title, position) VALUES (?, ?, ?)`
    ).bind(handbookId, sec.title || null, i);
    statements.push(stmt);
  }

  const sectionResults = await c.env.DB.batch(statements);

  for (let i = 0; i < body.sections.length; i++) {
    const sec = body.sections[i];
    const sectionMeta = (sectionResults[i] as any)?.meta;
    const sectionId = sectionMeta?.last_row_id;
    if (!sectionId || !sec.expressionIds?.length) continue;

    const itemStatements: D1Statement[] = [];
    for (let j = 0; j < sec.expressionIds.length; j++) {
      itemStatements.push(
        c.env.DB.prepare(
          `INSERT OR IGNORE INTO handbook_section_items (section_id, expression_id, position) VALUES (?, ?, ?)`
        ).bind(sectionId, sec.expressionIds[j], j)
      );
    }
    await c.env.DB.batch(itemStatements);
  }

  return created(c, { id: Number(handbookId) });
});

// PUT /:id — update handbook
handbooks.put('/:id', requireAuth, async (c) => {
  const id = parseInt(c.req.param('id'));
  const user = c.get('user')!;

  const existing = await c.env.DB.prepare(
    `SELECT * FROM handbooks WHERE id = ?`
  ).bind(id).first();
  if (!existing) return notFound(c, 'Handbook');

  const hb = existing as any;
  if (hb.user_id !== user.id && user.role !== 'admin') return forbidden(c);

  const body = await c.req.json<{
    title?: string;
    visibility?: string;
    sections?: { title: string; expressionIds: number[] }[];
  }>();

  const updates: string[] = [];
  const params: (string | number)[] = [];
  if (body.title !== undefined) { updates.push('title = ?'); params.push(body.title); }
  if (body.visibility !== undefined) {
    updates.push('visibility = ?');
    params.push(body.visibility === 'private' ? 'private' : 'public');
  }
  updates.push('updated_at = datetime("now")');
  params.push(id);

  if (updates.length > 1) {
    await c.env.DB.prepare(
      `UPDATE handbooks SET ${updates.join(', ')} WHERE id = ?`
    ).bind(...params).run();
  }

  if (body.sections) {
    await c.env.DB.prepare(
      `DELETE FROM handbook_sections WHERE handbook_id = ?`
    ).bind(id).run();

    const statements: D1Statement[] = [];
    for (let i = 0; i < body.sections.length; i++) {
      const sec = body.sections[i];
      statements.push(
        c.env.DB.prepare(
          `INSERT INTO handbook_sections (handbook_id, title, position) VALUES (?, ?, ?)`
        ).bind(id, sec.title || null, i)
      );
    }
    const sectionResults = await c.env.DB.batch(statements);

    for (let i = 0; i < body.sections.length; i++) {
      const sec = body.sections[i];
      const sectionMeta = (sectionResults[i] as any)?.meta;
      const sectionId = sectionMeta?.last_row_id;
      if (!sectionId || !sec.expressionIds?.length) continue;

      const itemStatements: D1Statement[] = [];
      for (let j = 0; j < sec.expressionIds.length; j++) {
        itemStatements.push(
          c.env.DB.prepare(
            `INSERT OR IGNORE INTO handbook_section_items (section_id, expression_id, position) VALUES (?, ?, ?)`
          ).bind(sectionId, sec.expressionIds[j], j)
        );
      }
      await c.env.DB.batch(itemStatements);
    }
  }

  return success(c, { id });
});

// DELETE /:id — delete handbook
handbooks.delete('/:id', requireAuth, async (c) => {
  const id = parseInt(c.req.param('id'));
  const user = c.get('user')!;

  const existing = await c.env.DB.prepare(
    `SELECT * FROM handbooks WHERE id = ?`
  ).bind(id).first();
  if (!existing) return notFound(c, 'Handbook');

  const hb = existing as any;
  if (hb.user_id !== user.id && user.role !== 'admin') return forbidden(c);

  await c.env.DB.prepare(`DELETE FROM handbooks WHERE id = ?`).bind(id).run();
  return success(c, { deleted: true });
});

// POST /:id/vote — vote on handbook
handbooks.post('/:id/vote', requireAuth, async (c) => {
  const handbookId = c.req.param('id');
  const user = c.get('user')!;
  const { direction } = await c.req.json<{ direction: 'up' | 'down' }>();
  if (direction !== 'up' && direction !== 'down') return badRequest(c, 'invalid_direction');

  const vote = direction === 'up' ? 1 : -1;

  const existing = await c.env.DB.prepare(
    `SELECT id, vote FROM votes WHERE user_id = ? AND target_type = 'handbook' AND target_id = ?`
  ).bind(user.id, String(handbookId)).first<{ id: string; vote: number }>();

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
    const voteId = `${user.id}-handbook-${handbookId}`;
    await c.env.DB.prepare(
      `INSERT INTO votes (id, user_id, target_type, target_id, vote) VALUES (?, ?, 'handbook', ?, ?)`
    ).bind(voteId, user.id, String(handbookId), vote).run();
  }

  await c.env.DB.prepare(
    `UPDATE handbooks SET score = score + ? WHERE id = ?`
  ).bind(voteDelta, parseInt(handbookId)).run();

  const hb = await c.env.DB.prepare(
    `SELECT score FROM handbooks WHERE id = ?`
  ).bind(parseInt(handbookId)).first<{ score: number }>();

  return success(c, { score: hb?.score || 0 });
});

export default handbooks;
