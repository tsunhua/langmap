import { describe, expect, it } from 'vitest';
import {
  LanguageLocaleError,
  assertReferenceCodesExist,
  buildLanguageLocaleCode,
  parseLanguageLocaleCode,
} from '../src/services/languageIdentity';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() {
            return (await run()) as T;
          },
          async run() {
            return { success: true, meta: { changes: 1 } };
          },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureCode(fn: () => void): string {
  try {
    fn();
  } catch (error) {
    return (error as LanguageLocaleError).code;
  }
  return '';
}

async function captureAsyncCode(fn: () => Promise<void>): Promise<string> {
  try {
    await fn();
  } catch (error) {
    return (error as LanguageLocaleError).code;
  }
  return '';
}

describe('parseLanguageLocaleCode', () => {
  it('parses a top-level locale', () => {
    expect(parseLanguageLocaleCode('nan-Hant-TW')).toEqual({
      lang_code: 'nan',
      script_code: 'Hant',
      region_code: 'TW',
      place_segments: [],
    });
  });

  it('parses place segments', () => {
    expect(parseLanguageLocaleCode('nan-Hant-CN_Quanzhou_Nanan')).toEqual({
      lang_code: 'nan',
      script_code: 'Hant',
      region_code: 'CN',
      place_segments: ['Quanzhou', 'Nanan'],
    });
  });

  it('rejects malformed codes', () => {
    for (const bad of [
      '',
      'nan-Hant',
      'nan-hant-TW',
      'nan-Hant-tw',
      'nan-Hant-TW_',
      'nan-Hant-TW_New_York_2',
      'nan-Hant-TW_newyork',
    ]) {
      expect(parseLanguageLocaleCode(bad)).toBeNull();
    }
  });
});

describe('buildLanguageLocaleCode', () => {
  it('builds a code and lowercases lang', () => {
    expect(buildLanguageLocaleCode({ lang_code: 'NAN', script_code: 'Hant', region_code: 'TW' })).toBe('nan-Hant-TW');
  });

  it('joins place segments', () => {
    expect(
      buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hant', region_code: 'CN', place_segments: ['Quanzhou', 'Nanan'] })
    ).toBe('nan-Hant-CN_Quanzhou_Nanan');
  });

  it('throws stable error codes for invalid parts', () => {
    expect(captureCode(() => buildLanguageLocaleCode({ lang_code: 'nano', script_code: 'Hant', region_code: 'TW' }))).toBe('INVALID_LANG_CODE');
    expect(captureCode(() => buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hantt', region_code: 'TW' }))).toBe('INVALID_SCRIPT_CODE');
    expect(captureCode(() => buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hant', region_code: 't' }))).toBe('INVALID_REGION_CODE');
    expect(
      captureCode(() => buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hant', region_code: 'TW', place_segments: ['newyork'] }))
    ).toBe('INVALID_PLACE_SEGMENT');
  });
});

describe('assertReferenceCodesExist', () => {
  it('resolves when all reference codes exist', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT 1 FROM scripts WHERE code = ?': () => ({ ok: 1 }),
      'SELECT 1 FROM regions WHERE code = ?': () => ({ ok: 1 }),
    });
    await expect(assertReferenceCodesExist(db, 'nan', 'Hant', 'TW')).resolves.toBeUndefined();
  });

  it('throws INVALID_LANG_CODE when the language is missing', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => null,
      'SELECT 1 FROM scripts WHERE code = ?': () => ({ ok: 1 }),
      'SELECT 1 FROM regions WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => assertReferenceCodesExist(db, 'zzz', 'Hant', 'TW'))).toBe('INVALID_LANG_CODE');
  });
});
