import type { LanguageSubtags, CanonicalLanguageTag, LanguageRow } from '../types/language';
import { canonicalizeLanguageTag } from '../utils/languageCode';

const RTL_SCRIPTS = new Set([
  'Arab', 'Hebr', 'Thaa', 'Nkoo', 'Adlm', 'Rohg', 'Mand', 'Syrc',
  'Cprt', 'Phnx', 'Lyci', 'Lydi', 'Khar', 'Brah', 'Sarb', 'Samr',
]);

interface D1Statement {
  bind(...args: unknown[]): {
    first<T = Record<string, unknown>>(): Promise<T | null>;
    all<T = Record<string, unknown>>(): Promise<{ results: T[] }>;
  };
}

interface D1Database {
  prepare(sql: string): D1Statement;
}

interface SubtagRow {
  type: string;
  value: string;
  descriptions: string;
  prefixes: string;
  preferred_value: string | null;
  suppress_script: string | null;
  deprecated: string | null;
}

export async function validateLanguageTag(
  db: D1Database,
  input: LanguageSubtags,
): Promise<{
  tag: CanonicalLanguageTag | null;
  warnings: string[];
  direction: 'ltr' | 'rtl';
}> {
  const tag = canonicalizeLanguageTag(input);
  if (!tag) {
    return { tag: null, warnings: ['INVALID_LANGUAGE_SUBTAG: malformed tag'], direction: 'ltr' };
  }

  const warnings: string[] = [];
  let direction: 'ltr' | 'rtl' = 'ltr';

  const langRow = await db.prepare(
    "SELECT * FROM language_subtags WHERE type = 'language' AND value = ?"
  ).bind(tag.language).first<SubtagRow>();

  if (!langRow) {
    warnings.push(`INVALID_LANGUAGE_SUBTAG: ${tag.language}`);
  } else if (langRow.deprecated && langRow.preferred_value) {
    warnings.push(`DEPRECATED: ${tag.language} → ${langRow.preferred_value}`);
  }

  if (tag.script) {
    const scriptRow = await db.prepare(
      "SELECT * FROM language_subtags WHERE type = 'script' AND value = ?"
    ).bind(tag.script).first<SubtagRow>();

    if (!scriptRow) {
      warnings.push(`INVALID_LANGUAGE_SUBTAG: script ${tag.script}`);
    } else if (RTL_SCRIPTS.has(tag.script)) {
      direction = 'rtl';
    } else if (scriptRow.deprecated && scriptRow.preferred_value) {
      warnings.push(`DEPRECATED: script ${tag.script} → ${scriptRow.preferred_value}`);
    }
  }

  if (tag.region) {
    const regionRow = await db.prepare(
      "SELECT * FROM language_subtags WHERE type = 'region' AND value = ?"
    ).bind(tag.region).first<SubtagRow>();

    if (!regionRow) {
      warnings.push(`INVALID_LANGUAGE_SUBTAG: region ${tag.region}`);
    } else if (regionRow.deprecated && regionRow.preferred_value) {
      warnings.push(`DEPRECATED: region ${tag.region} → ${regionRow.preferred_value}`);
    }
  }

  for (const variant of tag.variants) {
    const variantRow = await db.prepare(
      "SELECT * FROM language_subtags WHERE type = 'variant' AND value = ?"
    ).bind(variant).first<SubtagRow>();

    if (!variantRow) {
      warnings.push(`INVALID_LANGUAGE_SUBTAG: variant ${variant}`);
    } else {
      let prefixes: string[] = [];
      try {
        prefixes = JSON.parse(variantRow.prefixes || '[]');
      } catch {
        warnings.push(`SERVER_DATA_ERROR: malformed prefixes for variant ${variant}`);
        continue;
      }
      if (prefixes.length > 0) {
        const canonicalPrefix = buildCanonicalPrefix(tag);
        const matched = prefixes.some(p => p.toLowerCase() === canonicalPrefix.toLowerCase());
        if (!matched) {
          warnings.push(`INVALID_VARIANT_PREFIX: ${variant} not valid for ${canonicalPrefix}`);
        }
      }
    }
  }

  return { tag, warnings, direction };
}

function buildCanonicalPrefix(tag: CanonicalLanguageTag): string {
  const parts: string[] = [tag.language];
  if (tag.script) parts.push(tag.script);
  if (tag.region) parts.push(tag.region);
  return parts.join('-');
}

export async function requireRegisteredLanguage(
  db: D1Database,
  code: string,
): Promise<LanguageRow | null> {
  const row = await db.prepare(
    'SELECT * FROM languages WHERE code = ?'
  ).bind(code).first<Record<string, unknown>>();

  if (!row) return null;

  return {
    code: row.code as string,
    name: row.name as string,
    name_en: row.name_en as string | null,
    description: (row.description as string) ?? '',
    direction: (row.direction as 'ltr' | 'rtl') ?? 'ltr',
    base_language: (row.base_language as string) ?? code.split('-')[0],
    script_code: row.script_code as string | null,
    region_code: row.region_code as string | null,
    variants: safeJsonParse(row.variants_json as string | null, []),
    private_use: safeJsonParse(row.private_use_json as string | null, []),
    variety_key: (row.variety_key as string) ?? code,
    glottocode: row.glottocode as string | null,
    origin: (row.origin as LanguageRow['origin']) ?? 'seed',
  };
}

function safeJsonParse<T>(value: string | null, fallback: T): T {
  if (!value) return fallback;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}
