import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import languageLocales from '../src/routes/languageLocales';
import languageRegistry from '../src/routes/languageRegistry';
import { CANDIDATE_SQL } from '../src/services/localizedName';
import type { Bindings } from '../src/types';

type RowResult = { results?: unknown[] };

function fakeD1(handlers: Array<[string, () => RowResult | { total: number } | unknown]>) {
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

const LANGUAGE_IDENTITY_SQL = 'SELECT code, name_expression_id, name_en';
const LOCALE_IDENTITY_SQL = 'SELECT code, name_expression_id, name_en, name FROM language_locales';
const LOCALE_LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';
const LANGUAGE_LIST_SQL = 'SELECT code, name_en FROM languages';
const LANGUAGE_COUNT_SQL = 'SELECT COUNT(*) as total FROM languages';
const LOCALE_LIST_SQL = 'code, lang_code, script_code, region_code, place_path, name, name_en, latitude, longitude, source_id, source_ref, created_by, created_at FROM language_locales';
const LOCALE_COUNT_SQL = 'SELECT COUNT(*) AS total FROM language_locales';
const LOCALE_ROW_SQL = 'FROM language_locales WHERE code = ?';

describe('language registry localized names', () => {
  it('adds resolved name to language items and falls back to name_en without a binding', async () => {
    const db = fakeD1([
      [LANGUAGE_COUNT_SQL, () => ({ total: 2 })],
      [LANGUAGE_LIST_SQL, () => ({ results: [
        { code: 'cmn', name_en: 'Mandarin Chinese' },
        { code: 'eng', name_en: 'English' },
      ] })],
      [LANGUAGE_IDENTITY_SQL, () => ({ results: [
        { code: 'cmn', name_expression_id: 'expr-cmn', name_en: 'Mandarin Chinese', name: null },
        { code: 'eng', name_expression_id: null, name_en: 'English', name: null },
      ] })],
      [LOCALE_LANG_SQL, () => ({ lang_code: 'cmn' })],
      [CANDIDATE_SQL, () => ({ results: [{ source_id: 'expr-cmn', target_id: 't', target_text: '普通话', score: 1, created_at: 'x' }] })],
    ]);
    const request = makeApp(db);

    const hans = await request('/language-registry/languages?limit=5&ui_locale=cmn-Hans-CN');
    expect(hans.status).toBe(200);
    const body = await hans.json() as { data: { items: Array<{ code: string; name: string; name_en: string }> } };
    const byCode = new Map(body.data.items.map((item) => [item.code, item]));
    expect(byCode.get('cmn')?.name).toBe('普通话');
    expect(byCode.get('cmn')?.name_en).toBe('Mandarin Chinese');
    expect(byCode.get('eng')?.name).toBe('English');

    const neutral = await request('/language-registry/languages?limit=5');
    const neutralBody = await neutral.json() as { data: { items: Array<{ code: string; name: string }> } };
    expect(new Map(neutralBody.data.items.map((item) => [item.code, item.name])).get('cmn')).toBe('Mandarin Chinese');
  });

  it('does not attach name to scripts or regions', async () => {
    const db = fakeD1([
      ['SELECT COUNT(*) as total FROM scripts', () => ({ total: 1 })],
      ['SELECT code, name_en, direction FROM scripts', () => ({ results: [{ code: 'Latn', name_en: 'Latin', direction: 'ltr' }] })],
      ['SELECT COUNT(*) as total FROM regions', () => ({ total: 1 })],
      ['SELECT code, name_en, latitude, longitude FROM regions', () => ({ results: [{ code: 'TW', name_en: 'Taiwan', latitude: 23.7, longitude: 121 }] })],
    ]);
    const request = makeApp(db);

    const scripts = await request('/language-registry/scripts?limit=5');
    const scriptsBody = await scripts.json() as { data: { items: Array<Record<string, unknown>> } };
    expect(scriptsBody.data.items[0]).not.toHaveProperty('name');

    const regions = await request('/language-registry/regions?limit=5');
    const regionsBody = await regions.json() as { data: { items: Array<Record<string, unknown>> } };
    expect(regionsBody.data.items[0]).not.toHaveProperty('name');
  });

  it('ignores malformed ui_locale without erroring', async () => {
    const db = fakeD1([
      [LANGUAGE_COUNT_SQL, () => ({ total: 1 })],
      [LANGUAGE_LIST_SQL, () => ({ results: [{ code: 'eng', name_en: 'English' }] })],
      [LANGUAGE_IDENTITY_SQL, () => ({ results: [{ code: 'eng', name_expression_id: null, name_en: 'English', name: null }] })],
    ]);
    const request = makeApp(db);
    const res = await request('/language-registry/languages?limit=5&ui_locale=bad-locale!!');
    expect(res.status).toBe(200);
  });
});

describe('language locales localized names', () => {
  it('adds display_name to list rows and falls back to the self-name', async () => {
    const db = fakeD1([
      [LOCALE_COUNT_SQL, () => ({ total: 2 })],
      [LOCALE_LIST_SQL, () => ({ results: [
        { code: 'cmn-Hans-CN', lang_code: 'cmn', script_code: 'Hans', region_code: 'CN', place_path: '', name: '普通话', name_en: 'Simplified Chinese', latitude: null, longitude: null, source_id: null, source_ref: null, created_by: null, created_at: 'x' },
        { code: 'cmn-Hant-TW', lang_code: 'cmn', script_code: 'Hant', region_code: 'TW', place_path: '', name: '華語', name_en: 'Taiwan Mandarin', latitude: null, longitude: null, source_id: null, source_ref: null, created_by: null, created_at: 'x' },
      ] })],
      [LOCALE_IDENTITY_SQL, () => ({ results: [
        { code: 'cmn-Hans-CN', name_expression_id: null, name_en: 'Simplified Chinese', name: '普通话' },
        { code: 'cmn-Hant-TW', name_expression_id: null, name_en: 'Taiwan Mandarin', name: '華語' },
      ] })],
    ]);
    const request = makeApp(db);

    const res = await request('/language-locales?limit=5&ui_locale=cmn-Hans-CN');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name: string; display_name: string }> } };
    const byCode = new Map(body.data.items.map((item) => [item.code, item]));
    expect(byCode.get('cmn-Hans-CN')?.name).toBe('普通话');
    expect(byCode.get('cmn-Hans-CN')?.display_name).toBe('普通话');
    expect(byCode.get('cmn-Hant-TW')?.display_name).toBe('華語');
  });

  it('adds display_name to a single locale detail', async () => {
    const db = fakeD1([
      [LOCALE_ROW_SQL, () => ({ code: 'cmn-Hans-CN', lang_code: 'cmn', script_code: 'Hans', region_code: 'CN', place_path: '', name: '普通话', name_en: 'Simplified Chinese', latitude: 39.9, longitude: 116.4, source_id: null, source_ref: null, created_by: null, created_at: 'x' })],
      [LOCALE_IDENTITY_SQL, () => ({ results: [{ code: 'cmn-Hans-CN', name_expression_id: null, name_en: 'Simplified Chinese', name: '普通话' }] })],
    ]);
    const request = makeApp(db);

    const res = await request('/language-locales/cmn-Hans-CN?ui_locale=cmn-Hans-CN');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { code: string; name: string; display_name: string; coordinate_source: string | null } };
    expect(body.data.code).toBe('cmn-Hans-CN');
    expect(body.data.name).toBe('普通话');
    expect(body.data.display_name).toBe('普通话');
    expect(body.data.coordinate_source).toBe('locale');
  });
});
