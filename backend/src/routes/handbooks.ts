import { Hono } from 'hono';
import { optionalAuth, requireAuth } from '../middleware/auth';
import { badRequest, created, forbidden, internalError, notFound, success } from '../utils/response';
import { parseLocaleHints, resolveLanguageNames } from '../services/localizedName';
import { ulid } from '../utils/ulid';
import { MAX_HANDBOOK_ITEMS, MAX_HANDBOOK_SECTIONS, exceedsLimit } from '../utils/limits';
import type { Bindings, Variables } from '../types';
import { dictionaryReleaseSchemaAvailable, releaseObjectEligibilityPredicate } from '../services/dictionaryReleaseEligibility';

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

function handbookSizeError(sections: Array<{ expressionIds: string[] }>): string | null {
  if (exceedsLimit(sections.length, MAX_HANDBOOK_SECTIONS)) return 'HANDBOOK_BATCH_TOO_LARGE';
  const itemCount = sections.reduce((total, section) => total + section.expressionIds.length, 0);
  if (exceedsLimit(itemCount, MAX_HANDBOOK_ITEMS)) return 'HANDBOOK_BATCH_TOO_LARGE';
  return null;
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
    'SELECT id, handbook_id, title, position, parent_section_id FROM handbook_sections WHERE handbook_id = ? ORDER BY position ASC, id ASC',
  ).bind(id).all<{ id: string }>();
  const sectionIds = sections.map((section) => section.id);
  const releaseTablesReady = await dictionaryReleaseSchemaAvailable(c.env.DB);
  const profilePredicate = releaseTablesReady
    ? ` AND ${releaseObjectEligibilityPredicate('locale_attestation', 'a.id')}`
    : '';
  const { results: items } = sectionIds.length
    ? await c.env.DB.prepare(
      `SELECT hi.section_id, hi.expression_id, hi.position, e.id, e.text, e.lang_code,
        (SELECT language_locale_code FROM expression_locale_attestations a WHERE a.expression_id = e.id${profilePredicate} ORDER BY CASE language_locale_code WHEN 'cmn-Hant-TW' THEN 0 ELSE 1 END, language_locale_code ASC, id ASC LIMIT 1) AS language_profile_code,
        (SELECT ll.name FROM language_locales ll WHERE ll.code = (SELECT language_locale_code FROM expression_locale_attestations a WHERE a.expression_id = e.id${profilePredicate} ORDER BY CASE language_locale_code WHEN 'cmn-Hant-TW' THEN 0 ELSE 1 END, language_locale_code ASC, id ASC LIMIT 1)) AS language_profile_name
       FROM handbook_section_items hi JOIN all_expression_rows e ON e.id = hi.expression_id
       WHERE hi.section_id IN (SELECT value FROM json_each(?))
       ORDER BY hi.section_id ASC, hi.position ASC, hi.expression_id ASC`,
    ).bind(JSON.stringify(sectionIds)).all()
    : { results: [] };
  const languageNames = await resolveLanguageNames(
    c.env.DB,
    items.map((item: { lang_code: string }) => item.lang_code),
    parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale')),
  );
  const withNames = (items as Array<{ section_id: string; lang_code: string; language_profile_name?: string | null }>).map((item) => ({
    ...item,
    language_name: item.language_profile_name || languageNames.get(item.lang_code) || '',
  }));
  return success(c, { ...handbook, sections: sections.map((section) => ({ ...section, items: withNames.filter((item) => item.section_id === section.id) })) });
});

handbooks.post('/', requireAuth, async (c) => {
  try {
    const body = await c.req.json().catch(() => ({})) as { title?: unknown; visibility?: unknown; status?: unknown; sections?: unknown };
    const title = typeof body.title === 'string' ? body.title.trim() : '';
    const sections = normalizeSections(body.sections);
    if (!title) return badRequest(c, 'VALIDATION_FAILED', 'title is required');
    if (!sections) return badRequest(c, 'VALIDATION_FAILED', 'sections must be an array');
    const sizeError = handbookSizeError(sections);
    if (sizeError) return badRequest(c, sizeError, `At most ${MAX_HANDBOOK_SECTIONS} sections and ${MAX_HANDBOOK_ITEMS} items are allowed`);
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
    if (sections) {
      const sizeError = handbookSizeError(sections);
      if (sizeError) return badRequest(c, sizeError, `At most ${MAX_HANDBOOK_SECTIONS} sections and ${MAX_HANDBOOK_ITEMS} items are allowed`);
    }
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
