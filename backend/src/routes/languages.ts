import { Hono } from 'hono';
import { success, notFound, paginated, badRequest, created, conflict, forbidden, tooManyRequests } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import { previewLanguage, createLanguage, PreviewRequestSchema, CreateRequestSchema, LanguageCreationError } from '../services/languageCreation';
import type { Bindings, Variables } from '../types';

const languages = new Hono<{ Bindings: Bindings; Variables: Variables }>();

languages.post('/preview', requireAuth, async (c) => {
  try {
    const body = await c.req.json();
    const result = await previewLanguage(c.env.DB, body);
    return success(c, result);
  } catch (err: unknown) {
    if (err instanceof LanguageCreationError) {
      return badRequest(c, err.code, err.message);
    }
    if (err instanceof Error && err.name === 'ZodError') {
      return badRequest(c, 'VALIDATION_FAILED', err.message);
    }
    throw err;
  }
});

languages.post('/', requireAuth, async (c) => {
  const user = c.get('user');
  if (!user) return;

  try {
    const userRow = await c.env.DB.prepare(
      'SELECT email_verified FROM users WHERE id = ?'
    ).bind(user.id).first<{ email_verified: number }>();

    if (!userRow || userRow.email_verified !== 1) {
      return forbidden(c, 'VERIFIED_EMAIL_REQUIRED', 'Email verification required to create languages');
    }

    const body = await c.req.json();
    const result = await createLanguage(c.env.DB, user.id, body);
    return created(c, { language: result });
  } catch (err: unknown) {
    if (err instanceof LanguageCreationError) {
      if (err.code === 'RATE_LIMITED') return tooManyRequests(c, err.code, err.message);
      if (err.code === 'LANGUAGE_CODE_EXISTS') return conflict(c, err.code, err.message);
      return badRequest(c, err.code, err.message);
    }
    if (err instanceof Error && err.name === 'ZodError') {
      return badRequest(c, 'VALIDATION_FAILED', err.message);
    }
    throw err;
  }
});

languages.get('/', async (c) => {
  const search = c.req.query('q') || c.req.query('search') || '';
  const level = c.req.query('level') || '';
  const script = c.req.query('script') || '';
  const sort = c.req.query('sort') || 'count';
  const limit = Math.min(Math.max(Number(c.req.query('limit') || 50) || 50, 1), 100);
  const offset = Math.max(Number(c.req.query('offset') || 0) || 0, 0);

  let query = `SELECT l.*,
    (SELECT COUNT(*) FROM expressions e WHERE e.language_code = l.code) as expression_count
    FROM languages l
    LEFT JOIN languoids g ON g.glottocode = l.glottocode`;
  const params: (string | number)[] = [];
  const filters: string[] = [];

  if (search) {
    const escapedSearch = search.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
    filters.push(`(l.name LIKE ? ESCAPE '\\' OR l.name_en LIKE ? ESCAPE '\\' OR l.code LIKE ? ESCAPE '\\' OR l.glottocode LIKE ? ESCAPE '\\' OR g.preferred_name LIKE ? ESCAPE '\\' OR g.iso639_3 LIKE ? ESCAPE '\\' OR l.alternate_names_json LIKE ? ESCAPE '\\')`);
    params.push(...Array(7).fill(`%${escapedSearch}%`));
  }
  if (level) { filters.push('g.level = ?'); params.push(level); }
  if (script) { filters.push('l.script_code = ?'); params.push(script); }
  if (filters.length) query += ` WHERE ${filters.join(' AND ')}`;

  const SORT_MAP: Record<string, string> = {
    count: 'expression_count DESC, l.name ASC, l.code ASC',
    alpha: 'l.name ASC, l.code ASC',
  };
  query += ` ORDER BY ${SORT_MAP[sort] || SORT_MAP.count} LIMIT ? OFFSET ?`;
  params.push(limit, offset);

  const { results } = await c.env.DB.prepare(query).bind(...params).all();

  const items = results.map((row: Record<string, unknown>) => ({
    code: row.code,
    name: row.name,
    name_en: row.name_en,
    description: row.description,
    direction: row.direction,
    base_language: row.base_language,
    script_code: row.script_code,
    region_code: row.region_code,
    variety_key: row.variety_key,
    glottocode: row.glottocode,
    origin: row.origin,
    expression_count: row.expression_count,
  }));

  return success(c, { items, limit, offset, has_more: results.length === limit });
});

languages.get('/:code', async (c) => {
  const code = c.req.param('code');
  const lang = await c.env.DB.prepare(
    `SELECT l.*,
       (SELECT COUNT(*) FROM expressions e WHERE e.language_code = l.code) as expression_count
     FROM languages l
     WHERE l.code = ?`
  ).bind(code).first();
  if (!lang) return notFound(c, 'Language');

  const mappedCount = await c.env.DB.prepare(
    `SELECT COUNT(DISTINCT e.id) as count FROM expressions e
     INNER JOIN expression_edges ed ON e.id = ed.expression_a_id OR e.id = ed.expression_b_id
     WHERE e.language_code = ?`
  ).bind(code).first<{ count: number }>();

  const locations = await c.env.DB.prepare(
    `SELECT city_name, city_name_en, territory_code, script_code, latitude, longitude, reference
     FROM language_locations
     WHERE variety_key = ? AND (script_code = ? OR script_code = '')
     ORDER BY city_name ASC, territory_code ASC`
  ).bind((lang as Record<string, unknown>).variety_key, (lang as Record<string, unknown>).script_code || '').all();

  const l = lang as Record<string, unknown>;
  return success(c, {
    code: l.code,
    name: l.name,
    name_en: l.name_en,
    description: l.description,
    direction: l.direction,
    base_language: l.base_language,
    script_code: l.script_code,
    region_code: l.region_code,
    variety_key: l.variety_key,
    glottocode: l.glottocode,
    origin: l.origin,
    expression_count: l.expression_count,
    representative_cities: locations.results,
    mapped_expression_count: mappedCount?.count || 0,
  });
});

languages.get('/:code/expressions', async (c) => {
  const code = c.req.param('code');
  const sort = c.req.query('sort') || 'new';
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '50') || 50, 1), 100);
  const offset = Math.max(parseInt(c.req.query('offset') || '0') || 0, 0);

  const EXPR_SORT_MAP: Record<string, string> = {
    new: 'e.created_at DESC',
    alpha: 'e.text',
    hot: 'mapping_count DESC, e.text',
  };
  const orderBy = EXPR_SORT_MAP[sort] || EXPR_SORT_MAP.new;

  const { results } = await c.env.DB.prepare(
    `SELECT e.*,
      (SELECT COUNT(*) FROM expression_edges ed
       WHERE e.id = ed.expression_a_id OR e.id = ed.expression_b_id) as mapping_count
     FROM expressions e
     WHERE e.language_code = ?
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`
  ).bind(code, limit, offset).all();

  const { count: total } = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM expressions WHERE language_code = ?`
  ).bind(code).first<{ count: number }>();

  return paginated(c, results, total, offset, limit);
});

export default languages;
