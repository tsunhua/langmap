import { describe, expect, it } from 'vitest';
import { parseReferenceQuery, queryReferenceTable, escapeLike, buildLanguageLocaleCode, parseLanguageLocaleCode } from '../src/services/languageIdentity';

describe('parseReferenceQuery', () => {
  it('clamps limit into [1,50] and offsets to >=0', () => {
    expect(parseReferenceQuery({ limit: '999' }).limit).toBe(50);
    expect(parseReferenceQuery({ limit: '0' }).limit).toBe(1);
    expect(parseReferenceQuery({ limit: 'abc' }).limit).toBe(20);
    expect(parseReferenceQuery({ offset: '-5' }).offset).toBe(0);
  });

  it('truncates q to 80 chars', () => {
    expect(parseReferenceQuery({ q: 'x'.repeat(200) }).q).toHaveLength(80);
    expect(parseReferenceQuery({}).q).toBe('');
  });
});

describe('escapeLike', () => {
  it('escapes backslash, percent and underscore', () => {
    expect(escapeLike('a\\b%c_d')).toBe('a\\\\b\\%c\\_d');
  });
});

describe('queryReferenceTable', () => {
  function fakeD1(rows: Record<string, unknown>[], total: number) {
    const prepare = (sql: string) => ({
      bind(..._args: unknown[]) {
        return {
          async first<T>() {
            return { total } as unknown as T;
          },
          async all<T>() {
            return { results: rows as unknown as T[] };
          },
        };
      },
    });
    return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
  }

  it('returns items and total from D1', async () => {
    const db = fakeD1([{ code: 'eng', name_en: 'English' }], 1);
    const result = await queryReferenceTable(db, 'languages', { q: '', limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items[0]).toEqual({ code: 'eng', name_en: 'English' });
  });
});

describe('buildLanguageLocaleCode', () => {
  it('builds code without orthography', () => {
    expect(buildLanguageLocaleCode({
      lang_code: 'nan',
      script_code: 'Latn',
      region_code: 'TW',
    })).toBe('nan-Latn-TW');
  });

  it('builds code with orthography', () => {
    expect(buildLanguageLocaleCode({
      lang_code: 'nan',
      script_code: 'Latn',
      orthography: 'Pehoeji',
      region_code: 'TW',
    })).toBe('nan-Latn_Pehoeji-TW');
  });

  it('builds code with orthography and place segments', () => {
    expect(buildLanguageLocaleCode({
      lang_code: 'nan',
      script_code: 'Latn',
      orthography: 'Tailo',
      region_code: 'TW',
      place_segments: ['Tainan'],
    })).toBe('nan-Latn_Tailo-TW_Tainan');
  });

  it('builds code with place segments but no orthography', () => {
    expect(buildLanguageLocaleCode({
      lang_code: 'wuu',
      script_code: 'Hans',
      region_code: 'CN',
      place_segments: ['Wenzhou'],
    })).toBe('wuu-Hans-CN_Wenzhou');
  });

  it('rejects invalid orthography format', () => {
    expect(() => buildLanguageLocaleCode({
      lang_code: 'nan',
      script_code: 'Latn',
      orthography: 'pehoeji', // lowercase, invalid
      region_code: 'TW',
    })).toThrow('INVALID_ORTHOGRAPHY');
  });
});

describe('parseLanguageLocaleCode', () => {
  it('accepts the reserved image and emoji content locales', () => {
    expect(parseLanguageLocaleCode('x-image-Latn-US')?.lang_code).toBe('x-image');
    expect(parseLanguageLocaleCode('x-emoji-Latn-US')?.lang_code).toBe('x-emoji');
  });

  it('parses code without orthography', () => {
    const result = parseLanguageLocaleCode('nan-Latn-TW');
    expect(result).toEqual({
      lang_code: 'nan',
      script_code: 'Latn',
      orthography: undefined,
      region_code: 'TW',
      place_segments: [],
    });
  });

  it('parses code with orthography', () => {
    const result = parseLanguageLocaleCode('nan-Latn_Pehoeji-TW');
    expect(result).toEqual({
      lang_code: 'nan',
      script_code: 'Latn',
      orthography: 'Pehoeji',
      region_code: 'TW',
      place_segments: [],
    });
  });

  it('parses code with orthography and place segments', () => {
    const result = parseLanguageLocaleCode('nan-Latn_Tailo-TW_Tainan');
    expect(result).toEqual({
      lang_code: 'nan',
      script_code: 'Latn',
      orthography: 'Tailo',
      region_code: 'TW',
      place_segments: ['Tainan'],
    });
  });

  it('parses code with place segments but no orthography', () => {
    const result = parseLanguageLocaleCode('wuu-Hans-CN_Wenzhou');
    expect(result).toEqual({
      lang_code: 'wuu',
      script_code: 'Hans',
      orthography: undefined,
      region_code: 'CN',
      place_segments: ['Wenzhou'],
    });
  });

  it('returns null for invalid code', () => {
    expect(parseLanguageLocaleCode('invalid')).toBeNull();
    expect(parseLanguageLocaleCode('nan-Latn')).toBeNull();
    // Note: nan-Latn-TW_Pehoeji is syntactically valid (Pehoeji as place segment),
    // but semantically wrong (Pehoeji is an orthography, not a place).
    // The parser cannot distinguish this syntactically.
  });
});
