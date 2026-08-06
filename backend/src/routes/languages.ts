import { Hono } from 'hono';
import { success, notFound, paginated, badRequest, created, conflict, forbidden, tooManyRequests } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import { previewVariety, createVariety, PreviewVarietySchema, CreateVarietySchema, LanguageCreationError } from '../services/languageCreation';
import type { Bindings, Variables } from '../types';

const languages = new Hono<{ Bindings: Bindings; Variables: Variables }>();

languages.post('/preview', requireAuth, async (c) => {
  try {
    const body = await c.req.json();
    const result = await previewVariety(c.env.DB, body);
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
    const result = await createVariety(c.env.DB, user.id, body);
    return created(c, { variety: result.variety, profile: result.profile });
  } catch (err: unknown) {
    if (err instanceof LanguageCreationError) {
      if (err.code === 'RATE_LIMITED') return tooManyRequests(c, err.code, err.message);
      if (err.code === 'VARIETY_CODE_EXISTS' || err.code === 'PROFILE_CODE_EXISTS') {
        return conflict(c, err.code, err.message);
      }
      return badRequest(c, err.code, err.message);
    }
    if (err instanceof Error && err.name === 'ZodError') {
      return badRequest(c, 'VALIDATION_FAILED', err.message);
    }
    throw err;
  }
});

// GET / : language varieties aggregated (profile count + expression count per variety)
languages.get('/', async (c) => {
  const search = c.req.query('q') || c.req.query('search') || '';
  const level = c.req.query('level') || '';
  const script = c.req.query('script') || '';
  const sort = c.req.query('sort') || 'count';
  const limit = Math.min(Math.max(Number(c.req.query('limit') || 50) || 50, 1), 100);
  const offset = Math.max(Number(c.req.query('offset') || 0) || 0, 0);

  let query = `
    SELECT v.*,
      (SELECT COUNT(*) FROM language_profiles p WHERE p.language_variety_id = v.id) as profile_count,
      (SELECT COUNT(*) FROM expressions e
       JOIN language_profiles p ON p.code = e.language_profile_code
       WHERE p.language_variety_id = v.id) as expression_count
    FROM language_varieties v
    LEFT JOIN languoids g ON g.glottocode = v.glottocode`;
  const params: (string | number)[] = [];
  const filters: string[] = [];

  if (search) {
    const escapedSearch = search.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
    filters.push(`(v.name LIKE ? ESCAPE '\\' OR v.name_en LIKE ? ESCAPE '\\' OR v.code LIKE ? ESCAPE '\\' OR v.glottocode LIKE ? ESCAPE '\\' OR g.preferred_name LIKE ? ESCAPE '\\' OR g.iso639_3 LIKE ? ESCAPE '\\' OR v.alternate_names_json LIKE ? ESCAPE '\\')`);
    params.push(...Array(7).fill(`%${escapedSearch}%`));
  }
  if (level) { filters.push('g.level = ?'); params.push(level); }
  if (script) {
    filters.push(`v.id IN (SELECT language_variety_id FROM language_profiles WHERE script_code = ?)`);
    params.push(script);
  }
  if (filters.length) query += ` WHERE ${filters.join(' AND ')}`;

  const SORT_MAP: Record<string, string> = {
    count: 'expression_count DESC, v.name ASC, v.code ASC',
    alpha: 'v.name ASC, v.code ASC',
  };
  query += ` ORDER BY ${SORT_MAP[sort] || SORT_MAP.count} LIMIT ? OFFSET ?`;
  params.push(limit, offset);

  const { results } = await c.env.DB.prepare(query).bind(...params).all();

  const items = results.map((row: Record<string, unknown>) => ({
    id: row.id,
    code: row.code,
    name: row.name,
    name_en: row.name_en,
    description: row.description,
    glottocode: row.glottocode,
    origin: row.origin,
    profile_count: row.profile_count,
    expression_count: row.expression_count,
  }));

  return success(c, { items, limit, offset, has_more: results.length === limit });
});

// GET /:code : variety detail with profiles and counts
languages.get('/:code', async (c) => {
  const code = c.req.param('code');

  const variety = await c.env.DB.prepare(
    `SELECT v.* FROM language_varieties v WHERE v.code = ?`
  ).bind(code).first<Record<string, unknown>>();
  if (!variety) return notFound(c, 'Language variety');

  const profiles = await c.env.DB.prepare(
    `SELECT p.* FROM language_profiles p
     WHERE p.language_variety_id = ?
     ORDER BY p.name, p.code`
  ).bind(variety.id).all<Record<string, unknown>>();

  const expressionCount = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM expressions e
     JOIN language_profiles p ON p.code = e.language_profile_code
     WHERE p.language_variety_id = ?`
  ).bind(variety.id).first<{ count: number }>();

  const mappedCount = await c.env.DB.prepare(
    `SELECT COUNT(DISTINCT e.id) as count FROM expressions e
     JOIN language_profiles p ON p.code = e.language_profile_code
     INNER JOIN expression_edges ed ON e.id = ed.expression_a_id OR e.id = ed.expression_b_id
     WHERE p.language_variety_id = ?`
  ).bind(variety.id).first<{ count: number }>();

  // representative locations: pick first profile's locations (or all)
  const locations = await c.env.DB.prepare(
    `SELECT lc.city_name, lc.city_name_en, lc.city_name_localized, lc.territory_code, lc.script_code,
            lc.latitude, lc.longitude, lc.reference
     FROM language_locations lc
     WHERE lc.language_variety_id = ?
     ORDER BY lc.city_name ASC, lc.territory_code ASC`
  ).bind(variety.id).all();

  return success(c, {
    id: variety.id,
    code: variety.code,
    name: variety.name,
    name_en: variety.name_en,
    description: variety.description,
    glottocode: variety.glottocode,
    origin: variety.origin,
    community_reason: variety.community_reason,
    alternate_names_json: variety.alternate_names_json,
    references_json: variety.references_json,
    parent_languoid_id: variety.parent_languoid_id,
    profiles: profiles.results.map((p: Record<string, unknown>) => ({
      code: p.code,
      name: p.name,
      name_en: p.name_en,
      endonym: p.endonym || '',
      direction: p.direction,
      base_language: p.base_language,
      script_code: p.script_code,
      region_code: p.region_code,
    })),
    expression_count: expressionCount?.count || 0,
    mapped_expression_count: mappedCount?.count || 0,
    representative_cities: locations.results,
  });
});

// GET /:code/expressions : all expressions across all profiles of this variety
languages.get('/:code/expressions', async (c) => {
  const code = c.req.param('code');
  const sort = c.req.query('sort') || 'new';
  const script = c.req.query('script') || '';
  const limit = Math.min(Math.max(parseInt(c.req.query('limit') || '50') || 50, 1), 100);
  const offset = Math.max(parseInt(c.req.query('offset') || '0') || 0, 0);

  const variety = await c.env.DB.prepare(
    'SELECT id FROM language_varieties WHERE code = ?'
  ).bind(code).first<{ id: string }>();
  if (!variety) return notFound(c, 'Language variety');

  const EXPR_SORT_MAP: Record<string, string> = {
    new: 'e.created_at DESC',
    alpha: 'e.text',
    hot: 'mapping_count DESC, e.text',
  };
  const orderBy = EXPR_SORT_MAP[sort] || EXPR_SORT_MAP.new;

  const filters = ['p.language_variety_id = ?'];
  const params: (string | number)[] = [variety.id];
  if (script) {
    filters.push('p.script_code = ?');
    params.push(script);
  }
  const whereSql = filters.join(' AND ');

  const { results } = await c.env.DB.prepare(
    `SELECT e.*,
      (SELECT COUNT(*) FROM expression_edges ed
       WHERE e.id = ed.expression_a_id OR e.id = ed.expression_b_id) as mapping_count
     FROM expressions e
     JOIN language_profiles p ON p.code = e.language_profile_code
     WHERE ${whereSql}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`
  ).bind(...params, limit, offset).all();

  const { count: total } = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM expressions e
     JOIN language_profiles p ON p.code = e.language_profile_code
     WHERE ${whereSql}`
  ).bind(...params).first<{ count: number }>();

  return paginated(c, results, total, offset, limit);
});

export default languages;
