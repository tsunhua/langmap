import { describe, expect, it } from 'vitest';
import { getLanguageDetail, listLanguageExpressions, listLanguagesWithContent } from '../src/services/languageContent';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  return {
    prepare(sql: string) {
      const handler = handlers[sql];
      return { bind() { return {
        async first<T>() { return (handler ? await handler() : null) as T; },
        async all<T>() { const result = (handler ? await handler() : { results: [] }) as { results?: unknown }; return { results: (result.results ?? []) as T[] }; },
      }; } };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

const LANGUAGE_ROW_SQL = 'SELECT code, name_en FROM languages WHERE code = ?';
const LANGUAGE_LOCALES_SQL = 'SELECT l.code, l.name, l.name_en, l.script_code, l.region_code, l.place_path, l.latitude AS locale_latitude, l.longitude AS locale_longitude, r.latitude AS region_latitude, r.longitude AS region_longitude FROM language_locales l LEFT JOIN regions r ON r.code = l.region_code WHERE l.lang_code = ? ORDER BY l.code ASC LIMIT 500';
const EXPRESSION_COUNT_SQL = 'SELECT COUNT(*) AS total FROM expressions WHERE lang_code = ?';
const READING_COUNT_SQL = 'SELECT COUNT(*) AS total FROM expression_readings WHERE expression_id IN (SELECT id FROM expressions WHERE lang_code = ?)';

describe('getLanguageDetail', () => {
  it('returns null for an unknown language code', async () => {
    expect(await getLanguageDetail(fakeD1({ [LANGUAGE_ROW_SQL]: () => null }), 'zzz')).toBeNull();
  });

  it('labels locale, region and missing coordinates', async () => {
    const db = fakeD1({
      [LANGUAGE_ROW_SQL]: () => ({ code: 'cmn', name_en: 'Mandarin Chinese' }),
      [LANGUAGE_LOCALES_SQL]: () => ({ results: [
        { code: 'cmn-Hans-CN', name: '简体中文', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: null, region_longitude: null },
        { code: 'cmn-Hant-TW', name: '臺灣華語', name_en: 'Taiwan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: 23.7, region_longitude: 121 },
        { code: 'cmn-Hant-TW_Tainan', name: '臺南話', name_en: 'Tainan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: 'Tainan', locale_latitude: 22.99, locale_longitude: 120.2, region_latitude: 23.7, region_longitude: 121 },
      ] }),
      [EXPRESSION_COUNT_SQL]: () => ({ total: 7 }),
      [READING_COUNT_SQL]: () => ({ total: 2 }),
    });
    const detail = await getLanguageDetail(db, 'cmn');
    expect(detail?.name).toBe('简体中文');
    expect(detail?.expression_count).toBe(7);
    expect(detail?.reading_count).toBe(2);
    expect(detail?.locales.map((locale) => locale.coordinate_source)).toEqual([null, 'region', 'locale']);
  });
});

describe('listLanguagesWithContent', () => {
  it('returns paged summaries', async () => {
    const db = { prepare(sql: string) { return { bind() { return {
      async first() { return { total: 2 }; },
      async all() { return { results: sql.includes('COUNT(*) AS total FROM (') ? [] : [
        { code: 'cmn', name_en: 'Mandarin Chinese', name: '臺灣華語', expression_count: 3, locale_count: 2, active_ui_locale_count: 1 },
        { code: 'eng', name_en: 'English', name: 'English', expression_count: 300, locale_count: 1, active_ui_locale_count: 1 },
      ] }; },
    }; } }; } } as unknown as import('@cloudflare/workers-types').D1Database;
    const result = await listLanguagesWithContent(db, { q: '', limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.code)).toEqual(['cmn', 'eng']);
  });
});

describe('listLanguageExpressions', () => {
  it('returns null when the language does not exist', async () => {
    expect(await listLanguageExpressions(fakeD1({ [LANGUAGE_ROW_SQL]: () => null }), 'zzz', { q: '', limit: 20, offset: 0 })).toBeNull();
  });
});
