import { describe, expect, it } from 'vitest';
import { validateLanguageTag, requireRegisteredLanguage } from '../src/services/languageRegistry';

interface FakeD1Row {
  [key: string]: unknown;
}

function fakeD1(rows: FakeD1Row[]) {
  return {
    prepare(sql: string) {
      return {
        bind(...args: unknown[]) {
          return {
            async first<T = FakeD1Row>(): Promise<T | null> {
              for (const row of rows) {
                if (matchRow(sql, args, row)) return row as T;
              }
              return null;
            },
            async all<T = FakeD1Row>(): Promise<{ results: T[] }> {
              return { results: rows.filter(r => matchRow(sql, args, r)) as T[] };
            },
          };
        },
      };
    },
  };
}

function matchRow(sql: string, args: unknown[], row: FakeD1Row): boolean {
  const typeMatch = sql.match(/type\s*=\s*'(\w+)'/);
  const type = typeMatch?.[1];
  if (type && row.type !== type) return false;

  const valueMatch = sql.match(/value\s*=\s*\?/);
  if (valueMatch && args.length > 0) {
    return row.value === args[0];
  }

  const codeMatch = sql.match(/code\s*=\s*\?/);
  if (codeMatch && args.length > 0) {
    return row.code === args[0];
  }

  return true;
}

describe('validateLanguageTag', () => {
  it('rejects unknown language subtag', async () => {
    const db = fakeD1([]);
    const result = await validateLanguageTag(db as any, {
      language: 'zzz',
      script: null,
      region: null,
      variants: [],
      private_use: [],
    });
    expect(result.warnings.some(w => w.includes('INVALID_LANGUAGE_SUBTAG'))).toBe(true);
  });

  it('rejects unknown script subtag', async () => {
    const db = fakeD1([
      { type: 'language', value: 'en', descriptions: '["English"]' },
    ]);
    const result = await validateLanguageTag(db as any, {
      language: 'en',
      script: 'Zzzz',
      region: null,
      variants: [],
      private_use: [],
    });
    expect(result.warnings.some(w => w.includes('INVALID_LANGUAGE_SUBTAG'))).toBe(true);
  });

  it('rejects unknown region subtag', async () => {
    const db = fakeD1([
      { type: 'language', value: 'en', descriptions: '["English"]' },
    ]);
    const result = await validateLanguageTag(db as any, {
      language: 'en',
      script: null,
      region: 'ZZ',
      variants: [],
      private_use: [],
    });
    expect(result.warnings.some(w => w.includes('INVALID_LANGUAGE_SUBTAG'))).toBe(true);
  });

  it('returns deprecated subtag with preferred value warning', async () => {
    const db = fakeD1([
      { type: 'language', value: 'zh', descriptions: '["Chinese"]', preferred_value: 'cmn', deprecated: '2024-01-01' },
    ]);
    const result = await validateLanguageTag(db as any, {
      language: 'zh',
      script: null,
      region: null,
      variants: [],
      private_use: [],
    });
    expect(result.warnings.some(w => w.includes('DEPRECATED') && w.includes('cmn'))).toBe(true);
  });

  it('rejects invalid variant prefix', async () => {
    const db = fakeD1([
      { type: 'language', value: 'en', descriptions: '["English"]' },
      { type: 'variant', value: 'abcde', descriptions: '[]', prefixes: '["fr"]', deprecated: null, preferred_value: null },
    ]);
    const result = await validateLanguageTag(db as any, {
      language: 'en',
      script: null,
      region: null,
      variants: ['abcde'],
      private_use: [],
    });
    expect(result.warnings.some(w => w.includes('INVALID_VARIANT_PREFIX'))).toBe(true);
  });

  it('derives rtl direction for Arab script', async () => {
    const db = fakeD1([
      { type: 'language', value: 'ar', descriptions: '["Arabic"]' },
      { type: 'script', value: 'Arab', descriptions: '["Arabic"]' },
    ]);
    const result = await validateLanguageTag(db as any, {
      language: 'ar',
      script: 'Arab',
      region: null,
      variants: [],
      private_use: [],
    });
    expect(result.direction).toBe('rtl');
  });

  it('derives ltr direction for non-Arab scripts', async () => {
    const db = fakeD1([
      { type: 'language', value: 'en', descriptions: '["English"]' },
      { type: 'script', value: 'Latn', descriptions: '["Latin"]' },
    ]);
    const result = await validateLanguageTag(db as any, {
      language: 'en',
      script: 'Latn',
      region: null,
      variants: [],
      private_use: [],
    });
    expect(result.direction).toBe('ltr');
  });
});

describe('requireRegisteredLanguage', () => {
  it('returns null for unregistered code', async () => {
    const db = fakeD1([]);
    const result = await requireRegisteredLanguage(db as any, 'zzz-Zzzz');
    expect(result).toBeNull();
  });

  it('returns language row for registered code', async () => {
    const db = fakeD1([
      { code: 'en', name: 'English', name_en: 'English', description: '', direction: 'ltr', base_language: 'en', script_code: null, region_code: null, variants: '[]', private_use: '[]', variety_key: 'en', glottocode: 'stan1293', origin: 'seed' },
    ]);
    const result = await requireRegisteredLanguage(db as any, 'en');
    expect(result).not.toBeNull();
    expect(result!.code).toBe('en');
    expect(result!.name).toBe('English');
  });
});
