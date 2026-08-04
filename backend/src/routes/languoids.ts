import { Hono } from 'hono';
import { success, notFound, badRequest, paginated } from '../utils/response';
import type { Bindings } from '../types';

interface LanguoidRow {
  id: string;
  glottocode: string;
  preferred_name: string;
  level: string;
  iso639_3: string | null;
  parent_id: string | null;
  latitude: number | null;
  longitude: number | null;
  status: string;
  source_version: string;
}

interface LanguageProfileRow {
  code: string;
  name: string;
  script_code: string | null;
  region_code: string | null;
  glottocode: string | null;
}

const languoids = new Hono<{ Bindings: Bindings }>();

function escapeLike(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

function parseDescriptions(value: unknown): string[] {
  if (typeof value !== 'string') return [];
  try {
    const parsed: unknown = JSON.parse(value);
    return Array.isArray(parsed) && parsed.every(item => typeof item === 'string') ? parsed : [];
  } catch {
    return [];
  }
}

languoids.get('/:id', async (c) => {
  const id = c.req.param('id');
  const row = await c.env.DB.prepare(
    `SELECT l.*, p.preferred_name AS parent_name
     FROM languoids l LEFT JOIN languoids p ON p.id = l.parent_id WHERE l.id = ?`
  ).bind(id).first();
  return row ? success(c, row) : notFound(c, 'Languoid');
});

languoids.get('/', async (c) => {
  const q = (c.req.query('q') || '').trim();
  const level = c.req.query('level') || '';
  const script = c.req.query('script') || '';
  const matchable = c.req.query('matchable') === '1';
  const limit = Math.min(Math.max(Number(c.req.query('limit') || 50) || 50, 1), 100);
  const offset = Math.max(Number(c.req.query('offset') || 0) || 0, 0);

  const where: string[] = [];
  const params: (string | number)[] = [];
  let searchTerms: string[] = [];

  if (q) {
    const isExactGlottocode = /^[a-z]{4}\d{4}$/.test(q) && q.length === 8;
    if (q.length < 2 && !isExactGlottocode) {
      return badRequest(c, 'QUERY_TOO_SHORT', 'Search query must be at least 2 characters');
    }

    const registrySubtag = await c.env.DB.prepare(
      `SELECT descriptions FROM language_subtags
       WHERE type = 'language' AND value = ? COLLATE NOCASE`
    ).bind(q).first<{ descriptions: string }>();
    searchTerms = [...new Set([q, ...parseDescriptions(registrySubtag?.descriptions)]
      .map(term => term.trim())
      .filter(Boolean))];

    const termClauses = searchTerms.map(
      () => '(l.preferred_name LIKE ? ESCAPE \'\\\' OR l.glottocode LIKE ? ESCAPE \'\\\' OR l.iso639_3 LIKE ? ESCAPE \'\\\')'
    );
    where.push(`(${termClauses.join(' OR ')})`);
    for (const term of searchTerms) {
      const contains = `%${escapeLike(term)}%`;
      params.push(contains, contains, contains);
    }
  }
  if (level) { where.push('l.level = ?'); params.push(level); }
  if (script) { where.push('c.script_code = ?'); params.push(script); }
  if (matchable) { where.push("l.level IN ('language', 'dialect')"); }

  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  let orderBy = 'l.preferred_name ASC, l.id ASC';
  const orderParams: string[] = [];
  if (searchTerms.length > 0) {
    const exactClauses = searchTerms.map(
      () => '(l.preferred_name = ? COLLATE NOCASE OR l.glottocode = ? COLLATE NOCASE OR l.iso639_3 = ? COLLATE NOCASE)'
    );
    const prefixClauses = searchTerms.map(
      () => '(l.preferred_name LIKE ? ESCAPE \'\\\' OR l.glottocode LIKE ? ESCAPE \'\\\' OR l.iso639_3 LIKE ? ESCAPE \'\\\')'
    );
    for (const term of searchTerms) orderParams.push(term, term, term);
    for (const term of searchTerms) {
      const prefix = `${escapeLike(term)}%`;
      orderParams.push(prefix, prefix, prefix);
    }
    orderBy = `CASE
      WHEN ${exactClauses.join(' OR ')} THEN 0
      WHEN ${prefixClauses.join(' OR ')} THEN 1
      ELSE 2
    END,
    CASE l.level WHEN 'language' THEN 0 WHEN 'dialect' THEN 1 ELSE 2 END,
    l.preferred_name ASC, l.id ASC`;
  }

  const joinClause = `
    LEFT JOIN language_varieties v ON v.glottocode = l.glottocode
    LEFT JOIN language_profiles c ON c.language_variety_id = v.id
  `;
  const langQuery = `
    SELECT l.*
    FROM languoids l
    ${joinClause}
    ${clause}
    ORDER BY ${orderBy}
    LIMIT ? OFFSET ?
  `;
  const { results: languoids } = await c.env.DB.prepare(langQuery)
    .bind(...params, ...orderParams, limit, offset)
    .all<LanguoidRow>();

  const countQuery = `SELECT COUNT(DISTINCT l.id) AS count FROM languoids l ${joinClause} ${clause}`;
  const total = await c.env.DB.prepare(countQuery).bind(...params).first<{ count: number }>();

  if (languoids.length === 0) {
    return paginated(c, [], total?.count || 0, offset, limit);
  }

  const glottocodes = languoids.map(l => l.glottocode);
  const placeholders = glottocodes.map(() => '?').join(',');
  const profileResult = await c.env.DB.prepare(
    `SELECT p.code, p.name, p.script_code, p.region_code, v.glottocode
     FROM language_profiles p
     JOIN language_varieties v ON v.id = p.language_variety_id
     WHERE v.glottocode IN (${placeholders})
     ORDER BY p.name ASC, p.code ASC`
  ).bind(...glottocodes).all<LanguageProfileRow>();

  const profilesByGc = new Map<string, LanguageProfileRow[]>();
  for (const p of profileResult.results) {
    if (!p.glottocode) continue;
    if (!profilesByGc.has(p.glottocode)) profilesByGc.set(p.glottocode, []);
    profilesByGc.get(p.glottocode)!.push(p);
  }

  const items = languoids.map(l => ({
    ...l,
    profiles: profilesByGc.get(l.glottocode) || [],
  }));

  return paginated(c, items, total?.count || 0, offset, limit);
});

export default languoids;
