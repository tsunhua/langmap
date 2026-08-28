import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import languageLocales from '../src/routes/languageLocales';
import languageRegistry from '../src/routes/languageRegistry';
import type { Bindings } from '../src/types';

type RowResult = { results?: unknown[] };

function fakeD1(handlers: Array<[string, () => RowResult | { total: number } | Record<string, unknown> | null]>) {
  const find = (sql: string) => {
    const hit = handlers.find(([key]) => sql.includes(key));
    return hit ? hit[1] : undefined;
  };
  return {
    prepare(sql: string) {
      const handler = find(sql);
      const run = async () => (handler ? await handler() : { results: [] });
      return {
        bind(..._args: unknown[]) {
          return {
            async first<T>() {
              const result = (await run()) as T | undefined;
              return result ?? null;
            },
            async all<T>() {
              const result = (await run()) as RowResult;
              return { results: (result?.results ?? []) as T[] };
            },
          };
        },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

function makeApp(db: import('@cloudflare/workers-types').D1Database) {
  const app = new Hono<{ Bindings: Bindings }>();
  app.route('/language-locales', languageLocales);
  app.route('/language-registry', languageRegistry);
  return (path: string) => app.request(path, {}, { DB: db } as Bindings);
}

describe('language registry routes', () => {
  it('returns language items with name defaulting to name_en', async () => {
    const db = fakeD1([
      ['SELECT COUNT(*) as total FROM languages', () => ({ total: 2 })],
      ['SELECT code, name_en FROM languages', () => ({ results: [
        { code: 'cmn', name_en: 'Mandarin Chinese' },
        { code: 'eng', name_en: 'English' },
      ] })],
    ]);
    const request = makeApp(db);
    const res = await request('/language-registry/languages?limit=5');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name: string; name_en: string }>; total: number } };
    expect(body.data.total).toBe(2);
    const byCode = new Map(body.data.items.map((item) => [item.code, item]));
    expect(byCode.get('cmn')?.name).toBe('Mandarin Chinese');
    expect(byCode.get('cmn')?.name_en).toBe('Mandarin Chinese');
  });

  it('supports a LIKE search filter on registry items', async () => {
    const db = fakeD1([
      ['SELECT COUNT(*) as total FROM languages', () => ({ total: 1 })],
      ['SELECT code, name_en FROM languages', () => ({ results: [{ code: 'cmn', name_en: 'Mandarin Chinese' }] })],
    ]);
    const request = makeApp(db);
    const res = await request('/language-registry/languages?q=mand&limit=5');
    expect(res.status).toBe(200);
  });

  it('lists scripts and regions with name defaulting to name_en', async () => {
    const db = fakeD1([
      ['SELECT COUNT(*) as total FROM scripts', () => ({ total: 2 })],
      ['SELECT code, name_en, direction FROM scripts', () => ({ results: [
        { code: 'Latn', name_en: 'Latin', direction: 'ltr' },
        { code: 'Hang', name_en: 'Hangul (Hangŭl, Hangeul)', direction: 'ltr' },
      ] })],
      ['SELECT COUNT(*) as total FROM regions', () => ({ total: 1 })],
      ['SELECT code, name_en, latitude, longitude FROM regions', () => ({ results: [
        { code: 'TW', name_en: 'Taiwan', latitude: 23.7, longitude: 121 },
      ] })],
    ]);
    const request = makeApp(db);
    const scripts = await request('/language-registry/scripts?limit=5');
    const scriptsBody = await scripts.json() as { data: { items: Array<{ code: string; name: string }> } };
    const byCode = new Map(scriptsBody.data.items.map((item) => [item.code, item.name]));
    expect(byCode.get('Latn')).toBe('Latin');
    expect(byCode.get('Hang')).toBe('Hangul (Hangŭl, Hangeul)');

    const regions = await request('/language-registry/regions?limit=5');
    const regionsBody = await regions.json() as { data: { items: Array<{ code: string; name: string }> } };
    expect(regionsBody.data.items[0].name).toBe('Taiwan');
  });

  it('handles a malformed ui_locale without erroring', async () => {
    const db = fakeD1([
      ['SELECT COUNT(*) as total FROM languages', () => ({ total: 1 })],
      ['SELECT code, name_en FROM languages', () => ({ results: [{ code: 'eng', name_en: 'English' }] })],
    ]);
    const request = makeApp(db);
    const res = await request('/language-registry/languages?limit=5&ui_locale=bad-locale!!');
    expect(res.status).toBe(200);
  });
});

describe('language locales routes', () => {
  it('lists locale rows with code, self-name and name_en', async () => {
    const db = fakeD1([
      ['SELECT COUNT(*) AS total FROM language_locales', () => ({ total: 2 })],
      ['FROM language_locales ll JOIN languages l', () => ({ results: [
        { id: 1, code: 'cmn-Hans-CN', lang_code: 'cmn', script_code: 'Hans', orthography: null, region_code: 'CN', place_path: '', name: '普通话', name_en: 'Simplified Chinese', latitude: null, longitude: null },
        { id: 2, code: 'cmn-Hant-TW', lang_code: 'cmn', script_code: 'Hant', orthography: null, region_code: 'TW', place_path: '', name: '華語', name_en: 'Taiwan Mandarin', latitude: null, longitude: null },
      ] })],
    ]);
    const request = makeApp(db);
    const res = await request('/language-locales?limit=5');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name: string; name_en: string }> } };
    const byCode = new Map(body.data.items.map((item) => [item.code, item]));
    expect(byCode.get('cmn-Hans-CN')?.name).toBe('普通话');
    expect(byCode.get('cmn-Hans-CN')?.name_en).toBe('Simplified Chinese');
    expect(byCode.get('cmn-Hant-TW')?.name).toBe('華語');
  });

  it('returns a single locale detail with resolved coordinates', async () => {
    const db = fakeD1([
      ['FROM language_locales ll JOIN languages l ON l.id=ll.language_id LEFT JOIN regions r', () => ({
        code: 'cmn-Hans-CN', lang_code: 'cmn', script_code: 'Hans', orthography: null, region_code: 'CN', place_path: '', name: '普通话', name_en: 'Simplified Chinese', latitude: null, longitude: null, resolved_latitude: 39.9, resolved_longitude: 116.4, coordinate_source: 'region',
      })],
    ]);
    const request = makeApp(db);
    const res = await request('/language-locales/cmn-Hans-CN');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { code: string; name: string; coordinate_source: string | null; resolved_latitude: number | null } };
    expect(body.data.code).toBe('cmn-Hans-CN');
    expect(body.data.name).toBe('普通话');
    expect(body.data.coordinate_source).toBe('region');
    expect(body.data.resolved_latitude).toBe(39.9);
  });

  it('rejects an invalid locale code with INVALID_LANGUAGE_LOCALE_CODE', async () => {
    const db = fakeD1([]);
    const request = makeApp(db);
    const res = await request('/language-locales/not-a-code');
    expect(res.status).toBe(400);
    const body = await res.json() as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });
});
