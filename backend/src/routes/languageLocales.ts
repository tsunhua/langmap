import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import {
  badRequest,
  conflict,
  created,
  internalError,
  notFound,
  paginated,
  success,
} from '../utils/response';
import {
  LanguageLocaleError,
  assertReferenceCodesExist,
  buildLanguageLocaleCode,
  escapeLike,
  parseLanguageLocaleCode,
  parseReferenceQuery,
} from '../services/languageIdentity';
import { SourceError, findOrCreateSource } from '../services/sources';
import type { LanguageLocaleRow } from '../types/language';
import type { Bindings, Variables } from '../types';

const LOCALE_COLUMNS = `code, lang_code, script_code, region_code, place_path, name, name_en, latitude, longitude, source_id, source_ref, created_by, created_at`;

const languageLocales = new Hono<{ Bindings: Bindings; Variables: Variables }>();

languageLocales.post('/', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const langCode = typeof body?.lang_code === 'string' ? body.lang_code.trim() : '';
    const scriptCode = typeof body?.script_code === 'string' ? body.script_code.trim() : '';
    const regionCode = typeof body?.region_code === 'string' ? body.region_code.trim() : '';
    const placeSegments = Array.isArray(body?.place_segments)
      ? body.place_segments.filter((segment: unknown): segment is string => typeof segment === 'string')
      : [];
    const name = typeof body?.name === 'string' ? body.name.trim() : '';
    const nameEn = typeof body?.name_en === 'string' ? body.name_en.trim() : '';
    const latitude = typeof body?.latitude === 'number' && Number.isFinite(body.latitude) ? body.latitude : null;
    const longitude = typeof body?.longitude === 'number' && Number.isFinite(body.longitude) ? body.longitude : null;

    if (!langCode || !scriptCode || !regionCode || !name || !nameEn) {
      return badRequest(c, 'VALIDATION_FAILED', 'lang_code, script_code, region_code, name and name_en are required');
    }
    if ((latitude === null) !== (longitude === null)) {
      return badRequest(c, 'VALIDATION_FAILED', 'latitude and longitude must be provided together');
    }

    let code: string;
    try {
      code = buildLanguageLocaleCode({ lang_code: langCode, script_code: scriptCode, region_code: regionCode, place_segments: placeSegments });
      await assertReferenceCodesExist(c.env.DB, langCode.toLowerCase(), scriptCode, regionCode);
    } catch (error) {
      if (error instanceof LanguageLocaleError) return badRequest(c, error.code, error.code);
      throw error;
    }

    let sourceId: string | null = null;
    let sourceRef: string | null = null;
    if (body?.source != null) {
      const source = body.source;
      if (typeof source !== 'object' || source === null || typeof source.type !== 'string' || typeof source.name !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source requires type and name');
      }
      if (source.ref != null && typeof source.ref !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source ref must be a string');
      }
      try {
        sourceId = await findOrCreateSource(c.env.DB, { type: source.type, name: source.name });
      } catch (error) {
        if (error instanceof SourceError) return badRequest(c, error.code, error.code);
        throw error;
      }
      sourceRef = typeof source.ref === 'string' && source.ref.trim() ? source.ref.trim() : null;
    }

    const placePath = placeSegments.join('_');
    const existing = await c.env.DB
      .prepare('SELECT code FROM language_locales WHERE lang_code = ? AND script_code = ? AND region_code = ? AND place_path = ?')
      .bind(langCode.toLowerCase(), scriptCode, regionCode, placePath)
      .first<{ code: string }>();
    if (existing) {
      return conflict(c, 'LANGUAGE_LOCALE_EXISTS', `Language locale ${existing.code} already exists`);
    }

    try {
      await c.env.DB.prepare(
        `INSERT INTO language_locales (code, lang_code, script_code, region_code, place_path, name, name_en, latitude, longitude, source_id, source_ref, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
      )
        .bind(code, langCode.toLowerCase(), scriptCode, regionCode, placePath, name, nameEn, latitude, longitude, sourceId, sourceRef, user?.id ?? null)
        .run();
    } catch (error) {
      if (String((error as { message?: string })?.message ?? '').includes('UNIQUE constraint failed')) {
        return conflict(c, 'LANGUAGE_LOCALE_EXISTS', `Language locale ${code} already exists`);
      }
      throw error;
    }

    const row = await c.env.DB
      .prepare(`SELECT ${LOCALE_COLUMNS} FROM language_locales WHERE code = ?`)
      .bind(code)
      .first<LanguageLocaleRow>();
    return created(c, row, 'Language locale created');
  } catch (error) {
    console.error('Create language locale error:', error);
    return internalError(c);
  }
});

languageLocales.get('/', async (c) => {
  const q = c.req.query('q') ?? '';
  const langCode = (c.req.query('lang_code') ?? '').toLowerCase();
  const scriptCode = c.req.query('script_code') ?? '';
  const regionCode = (c.req.query('region_code') ?? '').toUpperCase();
  const query = parseReferenceQuery({
    q,
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });

  const conditions: string[] = [];
  const params: (string | number)[] = [];
  if (langCode) {
    conditions.push('lang_code = ?');
    params.push(langCode);
  }
  if (scriptCode) {
    conditions.push('script_code = ?');
    params.push(scriptCode);
  }
  if (regionCode) {
    conditions.push('region_code = ?');
    params.push(regionCode);
  }
  if (query.q) {
    const escaped = escapeLike(query.q);
    conditions.push("(code LIKE ? ESCAPE '\\' OR name LIKE ? ESCAPE '\\' OR name_en LIKE ? ESCAPE '\\')");
    params.push(`%${escaped}%`, `%${escaped}%`, `%${escaped}%`);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countRow = await c.env.DB
    .prepare(`SELECT COUNT(*) AS total FROM language_locales ${where}`)
    .bind(...params)
    .first<{ total: number }>();
  const { results } = await c.env.DB
    .prepare(`SELECT ${LOCALE_COLUMNS} FROM language_locales ${where} ORDER BY code ASC LIMIT ? OFFSET ?`)
    .bind(...params, query.limit, query.offset)
    .all();
  return paginated(c, results as LanguageLocaleRow[], countRow?.total ?? 0, query.offset, query.limit);
});

languageLocales.get('/:code', async (c) => {
  const code = c.req.param('code');
  if (!parseLanguageLocaleCode(code)) {
    return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Malformed language locale code');
  }
  const row = await c.env.DB
    .prepare(`SELECT ${LOCALE_COLUMNS} FROM language_locales WHERE code = ?`)
    .bind(code)
    .first<LanguageLocaleRow>();
  if (!row) return notFound(c, 'Language locale');

  let coordinate_source: 'locale' | 'region' | null = null;
  let latitude = row.latitude;
  let longitude = row.longitude;
  if (latitude === null || longitude === null) {
    const region = await c.env.DB
      .prepare('SELECT latitude, longitude FROM regions WHERE code = ?')
      .bind(row.region_code)
      .first<{ latitude: number | null; longitude: number | null }>();
    if (region && region.latitude !== null && region.longitude !== null) {
      latitude = region.latitude;
      longitude = region.longitude;
      coordinate_source = 'region';
    }
  } else {
    coordinate_source = 'locale';
  }
  return success(c, { ...row, latitude, longitude, coordinate_source });
});

export default languageLocales;
