import { Hono } from 'hono';
import { optionalAuth, requireAuth } from '../middleware/auth';
import { badRequest, created, forbidden, internalError, notFound, success } from '../utils/response';
import { ulid } from '../utils/ulid';
import type { Bindings, Variables } from '../types';

interface SectionInput { title?: unknown; expressionIds?: unknown }

function page(value: string | undefined, fallback: number, maximum: number): number {
  const parsed = Number.parseInt(value ?? String(fallback), 10);
  return Number.isFinite(parsed) ? Math.min(Math.max(parsed, 1), maximum) : fallback;
}

function offset(value: string | undefined): number {
  const parsed = Number.parseInt(value ?? '0', 10);
  return Number.isFinite(parsed) ? Math.max(parsed, 0) : 0;
}

function normalizeSections(raw: unknown): Array<{ title: string | null; expressionIds: string[] }> | null {
  if (!Array.isArray(raw)) return null;
  return raw.map((section) => {
    const input = section as SectionInput;
    const expressionIds = Array.isArray(input?.expressionIds)
      ? input.expressionIds.filter((id): id is string => typeof id === 'string' && id.trim().length > 0)
      : [];
    return { title: typeof input?.title === 'string' && input.title.trim() ? input.title.trim() : null, expressionIds: [...new Set(expressionIds)] };
  });
}

const handbooks = new Hono<{ Bindings: Bindings; Variables: Variables }>();

handbooks.get('/', optionalAuth, async (c) => {
  const sort = c.req.query('sort') === 'hot' ? 'hot' : 'new';
  const limit = page(c.req.query('limit'), 20, 100);
  const skip = offset(c.req.query('offset') ?? c.req.query('skip'));
  const search = (c.req.query('search') ?? '').trim();
  const where = `WHERE h.visibility = 'public'${search ? " AND h.title LIKE ? ESCAPE '\\'" : ''}`;
  const params = search ? [`%${search.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_')}%`] : [];
  const order = sort === 'hot' ? 'h.score DESC, h.created_at DESC, h.id ASC' : 'h.created_at DESC, h.id ASC';
  const count = await c.env.DB.prepare(`SELECT COUNT(*) AS total FROM handbooks h ${where}`).bind(...params).first<{ total: number }>();
  const { results } = await c.env.DB.prepare(
    `SELECT h.id, h.title, h.visibility, h.status, h.score, h.created_at, h.updated_at,
       u.username AS author_username,
       (SELECT COUNT(*) FROM handbook_sections hs WHERE hs.handbook_id = h.id) AS section_count,
       (SELECT COUNT(*) FROM handbook_section_items hi JOIN handbook_sections hs ON hs.id = hi.section_id WHERE hs.handbook_id = h.id) AS expression_count
     FROM handbooks h JOIN users u ON u.id = h.user_id ${where}
     ORDER BY ${order} LIMIT ? OFFSET ?`,
  ).bind(...params, limit, skip).all();
  return c.json({ success: true, data: { items: results, total: count?.total ?? 0, skip, limit, hasMore: skip + limit < (count?.total ?? 0) } });
});

handbooks.get('/:id', optionalAuth, async (c) => {
  const id = c.req.param('id');
  const handbook = await c.env.DB.prepare(
    `SELECT h.*, u.username AS author_username FROM handbooks h JOIN users u ON u.id = h.user_id WHERE h.id = ?`,
  ).bind(id).first<{ id: string; user_id: number; visibility: string }>();
  if (!handbook) return notFound(c, 'Handbook');
  const user = c.get('user');
  if (handbook.visibility === 'private' && user?.id !== handbook.user_id && user?.role !== 'admin') return notFound(c, 'Handbook');
  const { results: sections } = await c.env.DB.prepare(
    'SELECT id, handbook_id, title, position FROM handbook_sections WHERE handbook_id = ? ORDER BY position ASC, id ASC',
  ).bind(id).all<{ id: string }>();
  const sectionIds = sections.map((section) => section.id);
  const { results: items } = sectionIds.length
    ? await c.env.DB.prepare(
      `SELECT hi.section_id, hi.expression_id, hi.position, e.id, e.text, e.lang_code, l.name_en AS language_name
       FROM handbook_section_items hi JOIN expressions e ON e.id = hi.expression_id
       LEFT JOIN languages l ON l.code = e.lang_code
       WHERE hi.section_id IN (SELECT value FROM json_each(?))
       ORDER BY hi.section_id ASC, hi.position ASC, hi.expression_id ASC`,
    ).bind(JSON.stringify(sectionIds)).all()
    : { results: [] };
  return success(c, { ...handbook, sections: sections.map((section) => ({ ...section, items: items.filter((item: { section_id: string }) => item.section_id === section.id) })) });
});

handbooks.post('/', requireAuth, async (c) => {
  try {
    const body = await c.req.json().catch(() => ({})) as { title?: unknown; visibility?: unknown; status?: unknown; sections?: unknown };
    const title = typeof body.title === 'string' ? body.title.trim() : '';
    const sections = normalizeSections(body.sections);
    if (!title) return badRequest(c, 'VALIDATION_FAILED', 'title is required');
    if (!sections) return badRequest(c, 'VALIDATION_FAILED', 'sections must be an array');
    const id = ulid();
    const statements = [c.env.DB.prepare('INSERT INTO handbooks (id, user_id, title, visibility, status) VALUES (?, ?, ?, ?, ?)')
      .bind(id, c.get('user')!.id, title, body.visibility === 'private' ? 'private' : 'public', body.status === 'draft' ? 'draft' : 'published')];
    for (const [position, section] of sections.entries()) {
      const sectionId = ulid();
      statements.push(c.env.DB.prepare('INSERT INTO handbook_sections (id, handbook_id, title, position) VALUES (?, ?, ?, ?)').bind(sectionId, id, section.title, position));
      for (const [itemPosition, expressionId] of section.expressionIds.entries()) {
        statements.push(c.env.DB.prepare('INSERT INTO handbook_section_items (section_id, expression_id, position) VALUES (?, ?, ?)').bind(sectionId, expressionId, itemPosition));
      }
    }
    await c.env.DB.batch(statements);
    return created(c, { id }, 'Handbook created');
  } catch (error) {
    console.error('Create handbook error:', error);
    return internalError(c);
  }
});

handbooks.put('/:id', requireAuth, async (c) => {
  try {
    const id = c.req.param('id');
    const existing = await c.env.DB.prepare('SELECT user_id FROM handbooks WHERE id = ?').bind(id).first<{ user_id: number }>();
    if (!existing) return notFound(c, 'Handbook');
    const user = c.get('user')!;
    if (existing.user_id !== user.id && user.role !== 'admin') return forbidden(c);
    const body = await c.req.json().catch(() => ({})) as { title?: unknown; visibility?: unknown; status?: unknown; sections?: unknown };
    const sections = body.sections === undefined ? undefined : normalizeSections(body.sections);
    if (sections === null) return badRequest(c, 'VALIDATION_FAILED', 'sections must be an array');
    const title = typeof body.title === 'string' ? body.title.trim() : undefined;
    if (title === '') return badRequest(c, 'VALIDATION_FAILED', 'title is required');
    const statements = [c.env.DB.prepare(
      `UPDATE handbooks SET title = COALESCE(?, title), visibility = COALESCE(?, visibility), status = COALESCE(?, status), updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
    ).bind(title ?? null, body.visibility === undefined ? null : body.visibility === 'private' ? 'private' : 'public', body.status === undefined ? null : body.status === 'draft' ? 'draft' : 'published', id)];
    if (sections) {
      statements.push(c.env.DB.prepare('DELETE FROM handbook_sections WHERE handbook_id = ?').bind(id));
      for (const [position, section] of sections.entries()) {
        const sectionId = ulid();
        statements.push(c.env.DB.prepare('INSERT INTO handbook_sections (id, handbook_id, title, position) VALUES (?, ?, ?, ?)').bind(sectionId, id, section.title, position));
        for (const [itemPosition, expressionId] of section.expressionIds.entries()) statements.push(c.env.DB.prepare('INSERT INTO handbook_section_items (section_id, expression_id, position) VALUES (?, ?, ?)').bind(sectionId, expressionId, itemPosition));
      }
    }
    await c.env.DB.batch(statements);
    return success(c, { id }, 'Handbook updated');
  } catch (error) {
    console.error('Update handbook error:', error);
    return internalError(c);
  }
});

handbooks.delete('/:id', requireAuth, async (c) => {
  try {
    const id = c.req.param('id');
    const existing = await c.env.DB.prepare('SELECT user_id FROM handbooks WHERE id = ?').bind(id).first<{ user_id: number }>();
    if (!existing) return notFound(c, 'Handbook');
    const user = c.get('user')!;
    if (existing.user_id !== user.id && user.role !== 'admin') return forbidden(c);
    await c.env.DB.prepare('DELETE FROM handbooks WHERE id = ?').bind(id).run();
    return success(c, { deleted: true });
  } catch (error) {
    console.error('Delete handbook error:', error);
    return internalError(c);
  }
});

export default handbooks;
