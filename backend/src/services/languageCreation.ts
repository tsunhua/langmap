import { z } from 'zod';
import { canonicalizeLanguageTag } from '../utils/languageCode';
import { validateLanguageTag, requireRegisteredLanguage } from './languageRegistry';
import type { LanguageSubtags, LanguageRow, LanguagePreview } from '../types/language';

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

const LanguageMetadataSchema = z.object({
  name: z.string().min(1).max(MAX_NAME),
  name_en: z.string().max(MAX_NAME).nullable().default(null),
  description: z.string().min(1).max(MAX_DESCRIPTION),
  reason: z.enum(['missing_from_glottolog', 'community_specific', 'emerging_variety', 'other']),
  alternate_names: z.array(z.string().max(MAX_NAME)).max(MAX_ALTERNATE_NAMES).default([]),
  references: z.array(z.string().url().startsWith('https://')).max(MAX_REFERENCES).default([]),
  parent_languoid_id: z.string().nullable().default(null),
  latitude: z.number().min(-90).max(90).nullable().default(null),
  longitude: z.number().min(-180).max(180).nullable().default(null),
});

export const PreviewRequestSchema = z.object({
  subtags: SubtagsSchema,
  glottocode: z.string().nullable().default(null),
  language: LanguageMetadataSchema,
});

export const CreateRequestSchema = z.object({
  subtags: SubtagsSchema,
  glottocode: z.string().nullable().default(null),
  language: LanguageMetadataSchema,
});

interface D1Statement {
  bind(...args: unknown[]): {
    first<T = Record<string, unknown>>(): Promise<T | null>;
    all<T = Record<string, unknown>>(): Promise<{ results: T[] }>;
    run(): Promise<{ meta: { changes: number } }>;
  };
}

interface D1Database {
  prepare(sql: string): D1Statement;
}

function safeJsonParse<T>(value: string | null, fallback: T): T {
  if (!value) return fallback;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}

function rowToLanguageRow(row: Record<string, unknown>): LanguageRow {
  return {
    code: row.code as string,
    name: row.name as string,
    name_en: row.name_en as string | null,
    description: (row.description as string) ?? '',
    direction: (row.direction as 'ltr' | 'rtl') ?? 'ltr',
    base_language: (row.base_language as string) ?? (row.code as string).split('-')[0],
    script_code: row.script_code as string | null,
    region_code: row.region_code as string | null,
    variants: safeJsonParse(row.variants_json as string | null, []),
    private_use: safeJsonParse(row.private_use_json as string | null, []),
    variety_key: (row.variety_key as string) ?? (row.code as string),
    glottocode: row.glottocode as string | null,
    origin: (row.origin as LanguageRow['origin']) ?? 'seed',
  };
}

function deriveVarietyKey(glottocode: string | null): string {
  return glottocode
    ? `glotto:${glottocode}`
    : `community:${crypto.randomUUID()}`;
}

function deriveBaseLanguage(language: string): string {
  return language.split('-')[0];
}

export async function previewLanguage(
  db: D1Database,
  body: unknown,
): Promise<LanguagePreview> {
  const parsed = PreviewRequestSchema.parse(body);
  const { subtags, glottocode, language: meta } = parsed;

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

  const direction = registryResult.direction;

  const existing = await db.prepare(
    'SELECT * FROM languages WHERE code = ?'
  ).bind(tag.code).first<Record<string, unknown>>();

  const existingLanguage = existing ? rowToLanguageRow(existing) : null;

  let profiles: LanguageRow[] = [];
  if (glottocode) {
    const profileResult = await db.prepare(
      'SELECT * FROM languages WHERE glottocode = ? ORDER BY name, code'
    ).bind(glottocode).all<Record<string, unknown>>();
    profiles = profileResult.results.map(rowToLanguageRow);
  }

  const similarResult = await db.prepare(
    'SELECT * FROM languages WHERE name LIKE ? OR name_en LIKE ? ORDER BY name, code LIMIT 10'
  ).bind(`%${meta.name}%`, `%${meta.name}%`).all<Record<string, unknown>>();
  const similar = similarResult.results.map(rowToLanguageRow);

  const requiredMetadata: string[] = [];
  requiredMetadata.push('name');
  requiredMetadata.push('description');
  if (!glottocode) {
    requiredMetadata.push('reason');
  }

  return {
    canonical_code: tag.code,
    direction,
    warnings,
    existing_language: existingLanguage,
    profiles,
    similar,
    required_metadata: requiredMetadata,
  };
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

export async function createLanguage(
  db: D1Database,
  userId: number,
  body: unknown,
): Promise<LanguageRow> {
  const parsed = CreateRequestSchema.parse(body);
  const { subtags, glottocode, language: meta } = parsed;

  const tag = canonicalizeLanguageTag(subtags);
  if (!tag) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', 'Malformed language tag');
  }

  const registryResult = await validateLanguageTag(db, subtags);
  if (registryResult.tag === null) {
    throw new LanguageCreationError('INVALID_LANGUAGE_SUBTAG', registryResult.warnings[0] || 'Invalid subtag');
  }

  const varietyKey = deriveVarietyKey(glottocode);
  const baseLanguage = deriveBaseLanguage(tag.language);

  const existing = await db.prepare(
    'SELECT 1 FROM languages WHERE code = ?'
  ).bind(tag.code).first();
  if (existing) {
    throw new LanguageCreationError('LANGUAGE_CODE_EXISTS', `Language code ${tag.code} already exists`);
  }

  const insertResult = await db.prepare(
    `INSERT INTO languages (
      code, name, name_en, description, direction, base_language,
      script_code, region_code, variants_json, private_use_json,
      variety_key, glottocode, origin, community_reason,
      alternate_names_json, references_json, parent_languoid_id,
      latitude, longitude, created_by
    )
    SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
    WHERE (
      SELECT COUNT(*) FROM languages
      WHERE created_by = ? AND created_at >= datetime('now', '-1 day')
    ) < ?`
  ).bind(
    tag.code,
    meta.name,
    meta.name_en,
    meta.description,
    registryResult.direction,
    baseLanguage,
    tag.script,
    tag.region,
    JSON.stringify(tag.variants),
    JSON.stringify(tag.private_use),
    varietyKey,
    glottocode,
    'community',
    meta.reason,
    JSON.stringify(meta.alternate_names),
    JSON.stringify(meta.references),
    meta.parent_languoid_id,
    meta.latitude,
    meta.longitude,
    String(userId),
    String(userId),
    DAILY_LIMIT,
  ).run();

  if (insertResult.meta.changes === 0) {
    throw new LanguageCreationError('RATE_LIMITED', `Daily limit of ${DAILY_LIMIT} languages reached`);
  }

  const created = await db.prepare(
    'SELECT * FROM languages WHERE code = ?'
  ).bind(tag.code).first<Record<string, unknown>>();

  if (!created) {
    throw new LanguageCreationError('INTERNAL_ERROR', 'Failed to load created language');
  }

  return rowToLanguageRow(created);
}
