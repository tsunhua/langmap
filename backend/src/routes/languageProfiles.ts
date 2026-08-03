import { Hono } from 'hono';
import { success, notFound, badRequest, created, conflict, forbidden } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import { createProfile, CreateProfileSchema, LanguageCreationError } from '../services/languageCreation';
import { requireVariety } from '../services/languageRegistry';
import type { Bindings, Variables } from '../types';

const languageProfiles = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// GET /language-profiles/:code : profile detail
languageProfiles.get('/:code', async (c) => {
  const code = c.req.param('code');
  const row = await c.env.DB.prepare(
    `SELECT p.*, v.code AS language_variety_code, v.name AS variety_name
     FROM language_profiles p
     JOIN language_varieties v ON v.id = p.language_variety_id
     WHERE p.code = ?`
  ).bind(code).first<Record<string, unknown>>();
  if (!row) return notFound(c, 'Language profile');
  return success(c, {
    code: row.code,
    language_variety_id: row.language_variety_id,
    language_variety_code: row.language_variety_code,
    variety_name: row.variety_name,
    name: row.name,
    name_en: row.name_en,
    direction: row.direction,
    base_language: row.base_language,
    script_code: row.script_code,
    region_code: row.region_code,
  });
});

// POST /language-profiles/:varietyCode : add a new profile to an existing variety
languageProfiles.post('/:varietyCode', requireAuth, async (c) => {
  const user = c.get('user');
  if (!user) return;

  try {
    const userRow = await c.env.DB.prepare(
      'SELECT email_verified FROM users WHERE id = ?'
    ).bind(user.id).first<{ email_verified: number }>();

    if (!userRow || userRow.email_verified !== 1) {
      return forbidden(c, 'VERIFIED_EMAIL_REQUIRED', 'Email verification required to create profiles');
    }

    const varietyCode = c.req.param('varietyCode');
    const variety = await requireVariety(c.env.DB, varietyCode);
    if (!variety) {
      return notFound(c, 'Language variety');
    }

    const body = await c.req.json();
    const result = await createProfile(c.env.DB, varietyCode, body);
    return created(c, { profile: result });
  } catch (err: unknown) {
    if (err instanceof LanguageCreationError) {
      if (err.code === 'PROFILE_CODE_EXISTS') return conflict(c, err.code, err.message);
      return badRequest(c, err.code, err.message);
    }
    if (err instanceof Error && err.name === 'ZodError') {
      return badRequest(c, 'VALIDATION_FAILED', err.message);
    }
    throw err;
  }
});

export default languageProfiles;
