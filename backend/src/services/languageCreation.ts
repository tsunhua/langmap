import { z } from 'zod';
import { canonicalizeLanguageTag } from '../utils/languageCode';
import { validateLanguageTag } from './languageRegistry';
import { ulid } from '../utils/ulid';
import type { LanguageSubtags, VarietyRow, ProfileRow, VarietyPreview } from '../types/language';

const MAX_NAME = 120;
const MAX_DESCRIPTION = 2000;
const MAX_ALTERNATE_NAMES = 20;
const MAX_REFERENCES = 5;
const MAX_VARIANTS = 5;
const MAX_PRIVATE_USE = 5;
const MAX_PRIVATE_SUBTAG = 80;
const DAILY_LIMIT = 10;

const SubtagsSchema = z.object({
  language: z.string().min(1).max(8),
  script: z.string().max(4).nullable().default(null),
  region: z.string().max(2).nullable().default(null),
  variants: z.array(z.string().max(8)).max(MAX_VARIANTS).default([]),
  private_use: z.array(z.string().max(MAX_PRIVATE_SUBTAG)).max(MAX_PRIVATE_USE).default([]),
});

const VarietyMetadataSchema = z.object({
  name: z.string().min(1).max(MAX_NAME),
  name_en: z.string().max(MAX_NAME).nullable().default(null),
  description: z.string().min(1).max(MAX_DESCRIPTION),
  reason: z.enum(['missing_from_glottolog', 'community_specific', 'emerging_variety', 'other']),
  alternate_names: z.array(z.string().max(MAX_NAME)).max(MAX_ALTERNATE_NAMES).default([]),
  references: z.array(z.string().url().startsWith('https://')).max(MAX_REFERENCES).default([]),
  parent_languoid_id: z.string().nullable().default(null),
});

const ProfileMetadataSchema = z.object({
  name: z.string().min(1).max(MAX_NAME).optional(),
  name_en: z.string().max(MAX_NAME).nullable().default(null),
});

export const PreviewVarietySchema = z.object({
  subtags: SubtagsSchema,
  glottocode: z.string().nullable().default(null),
  variety: VarietyMetadataSchema,
  profile: ProfileMetadataSchema.default({}),
});

export const CreateVarietySchema = z.object({
  subtags: SubtagsSchema,
  glottocode: z.string().nullable().default(null),
  variety: VarietyMetadataSchema,
  profile: ProfileMetadataSchema.default({}),
});

export const CreateProfileSchema = z.object({
  subtags: SubtagsSchema,
  profile: ProfileMetadataSchema,
});

const SCRIPT_NAME_RE = /^(tradition|simplified|繁體|简体|简|繁)$/i;

interface D1Statement {
  bind(...args: unknown[]): {
    first<T = Record<string, unknown>>(): Promise<T | null>;
    all<T = Record<string, unknown>>(): Promise<{ results: T[] }>;
    run(): Promise<{ meta: { changes: number } }>;
  };
}

interface D1Database {
  prepare(sql: string): D1Statement;
  batch(statements: D1Statement[]): Promise<unknown[]>;
}

function escapeLike(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

function safeJsonParse<T>(value: string | null, fallback: T): T {
  if (!value) return fallback;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}

function rowToVariety(row: Record<string, unknown>): VarietyRow {
  return {
    id: row.id as string,
    code: row.code as string,
    name: row.name as string,
    name_en: (row.name_en as string | null) ?? null,
    description: (row.description as string) ?? '',
    glottocode: (row.glottocode as string | null) ?? null,
    origin: (row.origin as VarietyRow['origin']) ?? 'seed',
    community_reason: (row.community_reason as string | null) ?? null,
    alternate_names: safeJsonParse(row.alternate_names_json as string | null, []),
    references: safeJsonParse(row.references_json as string | null, []),
    parent_languoid_id: (row.parent_languoid_id as string | null) ?? null,
  };
}

function rowToProfile(row: Record<string, unknown>): ProfileRow {
  const code = row.code as string;
  return {
    code,
    language_variety_id: row.language_variety_id as string,
    language_variety_code: (row.language_variety_code as string) ?? '',
    name: row.name as string,
    name_en: (row.name_en as string | null) ?? null,
    direction: (row.direction as 'ltr' | 'rtl') ?? 'ltr',
    base_language: (row.base_language as string) ?? code.split('-')[0],
    script_code: (row.script_code as string | null) || null,
    region_code: (row.region_code as string | null) || null,
    variants: safeJsonParse(row.variants_json as string | null, []),
    private_use: safeJsonParse(row.private_use_json as string | null, []),
  };
}

function deriveVarietyCode(subtags: LanguageSubtags): string {
  if (subtags.private_use.length > 0) {
    return `${subtags.language}-x-${subtags.private_use[0]}`;
  }
  return subtags.language;
}

function deriveBaseLanguage(language: string): string {
  return language.split('-')[0];
}

function buildProfileCode(tag: { code: string }): string {
  return tag.code;
}

function warnScriptName(tag: LanguageSubtags): string | null {
  if (tag.script && SCRIPT_NAME_RE.test(tag.script)) {
    return `SCRIPT_MISUSE: script subtag '${tag.script}' is a human-readable name, not a BCP 47 script code`;
  }
  for (const v of tag.variants) {
    if (SCRIPT_NAME_RE.test(v)) {
      return `SCRIPT_MISUSE: variant subtag '${v}' is a human-readable name, not a BCP 47 subtag`;
    }
  }
  return null;
}

export class LanguageCreationError extends Error {
  constructor(
    public code: string,
    message: string,
  ) {
    super(message);
    this.name = 'LanguageCreationError';
  }
}

export async function previewVariety(
  db: D1Database,
  body: unknown,
): Promise<VarietyPreview> {
  const parsed = PreviewVarietySchema.parse(body);
  const { subtags, glottocode, variety: meta } = parsed;

  const tag = canonicalizeLanguageTag(subtags);
  if (!tag) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', 'Malformed language tag');
  }

  const registryResult = await validateLanguageTag(db, subtags);
  const warnings = [...registryResult.warnings];

  const hasCriticalWarning = warnings.some(w =>
    w.startsWith('INVALID_LANGUAGE_SUBTAG') || w.startsWith('INVALID_VARIANT_PREFIX')
  );
  if (hasCriticalWarning) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', warnings[0] || 'Invalid subtag');
  }

  const scriptWarning = warnScriptName(subtags);
  if (scriptWarning) {
    warnings.push(scriptWarning);
  }

  const direction = registryResult.direction;
  const varietyCode = deriveVarietyCode(subtags);
  const profileCode = buildProfileCode(tag);

  const existingVarietyRow = await db.prepare(
    'SELECT * FROM language_varieties WHERE code = ?'
  ).bind(varietyCode).first<Record<string, unknown>>();
  const existingVariety = existingVarietyRow ? rowToVariety(existingVarietyRow) : null;

  const existingProfileRow = await db.prepare(
    'SELECT * FROM language_profiles WHERE code = ?'
  ).bind(profileCode).first<Record<string, unknown>>();
  const existingProfile = existingProfileRow ? rowToProfile(existingProfileRow) : null;

  let profilesOfVariety: ProfileRow[] = [];
  if (existingVariety) {
    const profilesResult = await db.prepare(
      `SELECT p.*, v.code AS language_variety_code
       FROM language_profiles p JOIN language_varieties v ON v.id = p.language_variety_id
       WHERE p.language_variety_id = ?
       ORDER BY p.name, p.code`
    ).bind(existingVariety.id).all<Record<string, unknown>>();
    profilesOfVariety = profilesResult.results.map(rowToProfile);
  }

  let similarVarieties: VarietyRow[] = [];
  const escapedName = escapeLike(meta.name);
  const similarResult = await db.prepare(
    'SELECT * FROM language_varieties WHERE name LIKE ? ESCAPE \'\\\' OR name_en LIKE ? ESCAPE \'\\\' ORDER BY name, code LIMIT 10'
  ).bind(`%${escapedName}%`, `%${escapedName}%`).all<Record<string, unknown>>();
  similarVarieties = similarResult.results.map(rowToVariety);

  const requiredMetadata: string[] = ['name', 'description'];
  if (!glottocode) {
    requiredMetadata.push('reason');
  }

  return {
    canonical_profile_code: profileCode,
    direction,
    warnings,
    existing_variety: existingVariety,
    existing_profile: existingProfile,
    profiles_of_variety: profilesOfVariety,
    similar_varieties: similarVarieties,
    required_metadata: requiredMetadata,
  };
}

export async function createVariety(
  db: D1Database,
  userId: number,
  body: unknown,
): Promise<{ variety: VarietyRow; profile: ProfileRow }> {
  const parsed = CreateVarietySchema.parse(body);
  const { subtags, glottocode, variety: meta } = parsed;

  const tag = canonicalizeLanguageTag(subtags);
  if (!tag) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', 'Malformed language tag');
  }

  const registryResult = await validateLanguageTag(db, subtags);
  if (registryResult.tag === null) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', registryResult.warnings[0] || 'Invalid subtag');
  }

  const scriptWarning = warnScriptName(subtags);
  if (scriptWarning) {
    throw new LanguageCreationError('SCRIPT_MISUSE', scriptWarning);
  }

  const varietyCode = deriveVarietyCode(subtags);
  const profileCode = buildProfileCode(tag);
  const varietyId = ulid();
  const baseLanguage = deriveBaseLanguage(tag.language);
  const direction = registryResult.direction;

  const existingVariety = await db.prepare(
    'SELECT 1 FROM language_varieties WHERE code = ?'
  ).bind(varietyCode).first();
  if (existingVariety) {
    throw new LanguageCreationError('VARIETY_CODE_EXISTS', `Variety code ${varietyCode} already exists`);
  }

  const existingProfile = await db.prepare(
    'SELECT 1 FROM language_profiles WHERE code = ?'
  ).bind(profileCode).first();
  if (existingProfile) {
    throw new LanguageCreationError('PROFILE_CODE_EXISTS', `Profile code ${profileCode} already exists`);
  }

  const dailyCount = await db.prepare(
    `SELECT COUNT(*) AS count FROM language_varieties
     WHERE created_by = ? AND created_at >= datetime('now', '-1 day')`
  ).bind(String(userId)).first<{ count: number }>();
  if (dailyCount && dailyCount.count >= DAILY_LIMIT) {
    throw new LanguageCreationError('RATE_LIMITED', `Daily limit of ${DAILY_LIMIT} varieties reached`);
  }

  const insertVariety = db.prepare(
    `INSERT INTO language_varieties (
      id, code, name, name_en, description, glottocode, origin,
      community_reason, alternate_names_json, references_json,
      parent_languoid_id, created_by
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(
    varietyId, varietyCode, meta.name, meta.name_en, meta.description,
    glottocode, 'community', meta.reason,
    JSON.stringify(meta.alternate_names), JSON.stringify(meta.references),
    meta.parent_languoid_id, String(userId),
  );

  const insertProfile = db.prepare(
    `INSERT INTO language_profiles (
      code, language_variety_id, name, name_en, direction, base_language,
      script_code, region_code, variants_json, private_use_json
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(
    profileCode, varietyId,
    meta.name, meta.name_en, direction, baseLanguage,
    tag.script, tag.region,
    JSON.stringify(tag.variants), JSON.stringify(tag.private_use),
  );

  try {
    await db.batch([insertVariety, insertProfile]);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (/UNIQUE constraint failed.*language_varieties/i.test(msg)) {
      throw new LanguageCreationError('VARIETY_CODE_EXISTS', `Variety code ${varietyCode} already exists`);
    }
    if (/UNIQUE constraint failed.*language_profiles/i.test(msg)) {
      throw new LanguageCreationError('PROFILE_CODE_EXISTS', `Profile code ${profileCode} already exists`);
    }
    throw e;
  }

  const createdVariety = await db.prepare(
    'SELECT * FROM language_varieties WHERE code = ?'
  ).bind(varietyCode).first<Record<string, unknown>>();
  const createdProfile = await db.prepare(
    `SELECT p.*, v.code AS language_variety_code
     FROM language_profiles p JOIN language_varieties v ON v.id = p.language_variety_id
     WHERE p.code = ?`
  ).bind(profileCode).first<Record<string, unknown>>();

  if (!createdVariety || !createdProfile) {
    throw new LanguageCreationError('INTERNAL_ERROR', 'Failed to load created variety/profile');
  }

  return {
    variety: rowToVariety(createdVariety),
    profile: rowToProfile(createdProfile),
  };
}

export async function createProfile(
  db: D1Database,
  varietyCode: string,
  body: unknown,
): Promise<ProfileRow> {
  const parsed = CreateProfileSchema.parse(body);
  const { subtags, profile: profileMeta } = parsed;

  const tag = canonicalizeLanguageTag(subtags);
  if (!tag) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', 'Malformed language tag');
  }

  const registryResult = await validateLanguageTag(db, subtags);
  if (registryResult.tag === null) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', registryResult.warnings[0] || 'Invalid subtag');
  }

  const scriptWarning = warnScriptName(subtags);
  if (scriptWarning) {
    throw new LanguageCreationError('SCRIPT_MISUSE', scriptWarning);
  }

  const varietyRow = await db.prepare(
    'SELECT * FROM language_varieties WHERE code = ?'
  ).bind(varietyCode).first<Record<string, unknown>>();
  if (!varietyRow) {
    throw new LanguageCreationError('VARIETY_NOT_FOUND', `Variety ${varietyCode} not found`);
  }

  const profileCode = buildProfileCode(tag);
  const baseLanguage = deriveBaseLanguage(tag.language);
  const direction = registryResult.direction;

  const existingProfile = await db.prepare(
    'SELECT 1 FROM language_profiles WHERE code = ?'
  ).bind(profileCode).first();
  if (existingProfile) {
    throw new LanguageCreationError('PROFILE_CODE_EXISTS', `Profile code ${profileCode} already exists`);
  }

  try {
    await db.prepare(
      `INSERT INTO language_profiles (
        code, language_variety_id, name, name_en, direction, base_language,
        script_code, region_code, variants_json, private_use_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      profileCode, varietyRow.id,
      profileMeta.name ?? varietyRow.name as string, profileMeta.name_en,
      direction, baseLanguage,
      tag.script, tag.region,
      JSON.stringify(tag.variants), JSON.stringify(tag.private_use),
    ).run();
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (/UNIQUE constraint failed.*language_profiles/i.test(msg)) {
      throw new LanguageCreationError('PROFILE_CODE_EXISTS', `Profile code ${profileCode} already exists`);
    }
    throw e;
  }

  const createdProfile = await db.prepare(
    `SELECT p.*, v.code AS language_variety_code
     FROM language_profiles p JOIN language_varieties v ON v.id = p.language_variety_id
     WHERE p.code = ?`
  ).bind(profileCode).first<Record<string, unknown>>();

  if (!createdProfile) {
    throw new LanguageCreationError('INTERNAL_ERROR', 'Failed to load created profile');
  }

  return rowToProfile(createdProfile);
}
