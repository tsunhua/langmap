import { describe, expect, it } from 'vitest';
import {
  LanguageLocaleError,
  assertReferenceCodesExist,
  buildLanguageLocaleCode,
  parseLanguageLocaleCode,
} from '../src/services/languageIdentity';
import { SourceError, findOrCreateSource } from '../src/services/sources';

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
            return handler ? await handler() : { success: true };
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

async function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  try {
    await fn();
  } catch (error) {
    return String((error as { code?: string }).code ?? '');
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

describe('findOrCreateSource', () => {
  it('returns the existing source id without inserting', async () => {
    let inserted = 0;
    const db = fakeD1({
      'SELECT id FROM sources WHERE type = ? AND name = ?': () => ({ id: 'existing-id' }),
      'INSERT INTO sources (id, type, name) VALUES (?, ?, ?)': () => {
        inserted += 1;
        return { success: true };
      },
    });
    await expect(findOrCreateSource(db, { type: 'url', name: '某辭典' })).resolves.toBe('existing-id');
    expect(inserted).toBe(0);
  });

  it('creates a source when missing and returns a new id', async () => {
    let inserted = 0;
    const db = fakeD1({
      'SELECT id FROM sources WHERE type = ? AND name = ?': () => null,
      'INSERT INTO sources (id, type, name) VALUES (?, ?, ?)': () => {
        inserted += 1;
        return { success: true };
      },
    });
    const id = await findOrCreateSource(db, { type: 'url', name: '某辭典' });
    expect(id).toBeTruthy();
    expect(inserted).toBe(1);
  });

  it('rejects unknown type and empty name with INVALID_SOURCE', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => findOrCreateSource(db, { type: 'wiki', name: 'x' }))).toBe('INVALID_SOURCE');
    expect(await captureAsyncCode(() => findOrCreateSource(db, { type: 'url', name: '   ' }))).toBe('INVALID_SOURCE');
  });
});
