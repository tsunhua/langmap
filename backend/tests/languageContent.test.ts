import { describe, expect, it } from 'vitest';
import { getLanguageDetail, listLanguageExpressions, listLanguagesWithContent } from '../src/services/languageContent';
import { parseLocaleHints } from '../src/services/localizedName';

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
const IDENTITY_LANGUAGE_SQL = 'SELECT code, name_expression_id, name_en, (SELECT l.name FROM language_locales l WHERE l.lang_code = languages.code ORDER BY l.code ASC LIMIT 1) AS name FROM languages WHERE code IN (SELECT value FROM json_each(?))';
const IDENTITY_LOCALE_SQL = 'SELECT code, name_expression_id, name_en, name FROM language_locales WHERE code IN (SELECT value FROM json_each(?))';
const LANGUAGE_LOCALES_SQL = 'SELECT l.code, l.name, l.name_en, l.script_code, l.region_code, l.place_path, l.latitude AS locale_latitude, l.longitude AS locale_longitude, r.latitude AS region_latitude, r.longitude AS region_longitude FROM language_locales l LEFT JOIN regions r ON r.code = l.region_code WHERE l.lang_code = ? ORDER BY l.code ASC LIMIT 500';
const EXPRESSION_COUNT_SQL = "SELECT COUNT(*) AS total FROM all_expression_rows e WHERE e.lang_code = ? AND (? = '' OR EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = e.id AND a.language_locale_code = ?))";
const READING_COUNT_SQL = 'SELECT COUNT(*) AS total FROM all_expression_readings WHERE expression_id IN (SELECT id FROM all_expression_rows WHERE lang_code = ?)';
const MAPPED_EXPRESSION_COUNT_SQL = "SELECT COUNT(*) AS total FROM all_expression_rows e WHERE e.lang_code = ? AND (? = '' OR EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = e.id AND a.language_locale_code = ?)) AND EXISTS (SELECT 1 FROM all_expression_edges g WHERE g.expression_a_id = e.id OR g.expression_b_id = e.id)";

describe('getLanguageDetail', () => {
  it('returns null for an unknown language code', async () => {
    expect(await getLanguageDetail(fakeD1({ [LANGUAGE_ROW_SQL]: () => null }), 'zzz')).toBeNull();
  });

  it('labels locale, region and missing coordinates', async () => {
    const db = fakeD1({
      [LANGUAGE_ROW_SQL]: () => ({ code: 'cmn', name_en: 'Mandarin Chinese' }),
      [IDENTITY_LANGUAGE_SQL]: () => ({ results: [{ code: 'cmn', name_expression_id: null, name_en: 'Mandarin Chinese', name: null }] }),
      [LANGUAGE_LOCALES_SQL]: () => ({ results: [
        { code: 'cmn-Hans-CN', name: '普通话(CN)', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: null, region_longitude: null },
        { code: 'cmn-Hant-TW', name: '華語(TW)', name_en: 'Taiwan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: 23.7, region_longitude: 121 },
        { code: 'cmn-Hant-TW_Tainan', name: '臺南話', name_en: 'Tainan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: 'Tainan', locale_latitude: 22.99, locale_longitude: 120.2, region_latitude: 23.7, region_longitude: 121 },
      ] }),
      [EXPRESSION_COUNT_SQL]: () => ({ total: 7 }),
      [READING_COUNT_SQL]: () => ({ total: 2 }),
      [MAPPED_EXPRESSION_COUNT_SQL]: () => ({ total: 4 }),
    });
    const detail = await getLanguageDetail(db, 'cmn');
    expect(detail?.name).toBe('Mandarin Chinese');
    expect(detail?.expression_count).toBe(7);
    expect(detail?.reading_count).toBe(2);
    expect(detail?.mapped_expression_count).toBe(4);
    expect(detail?.locales.map((locale) => locale.coordinate_source)).toEqual([null, 'region', 'locale']);
  });

  it('adds display_name for locales via the shared resolver', async () => {
    const db = fakeD1({
      [LANGUAGE_ROW_SQL]: () => ({ code: 'cmn', name_en: 'Mandarin Chinese' }),
      [IDENTITY_LANGUAGE_SQL]: () => ({ results: [{ code: 'cmn', name_expression_id: null, name_en: 'Mandarin Chinese', name: null }] }),
      [IDENTITY_LOCALE_SQL]: () => ({ results: [{ code: 'cmn-Hans-CN', name_expression_id: null, name_en: 'Simplified Chinese', name: '普通话(CN)' }] }),
      [LANGUAGE_LOCALES_SQL]: () => ({ results: [
        { code: 'cmn-Hans-CN', name: '普通话(CN)', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: null, region_longitude: null },
      ] }),
      [EXPRESSION_COUNT_SQL]: () => ({ total: 7 }),
      [READING_COUNT_SQL]: () => ({ total: 2 }),
      [MAPPED_EXPRESSION_COUNT_SQL]: () => ({ total: 4 }),
    });
    const detail = await getLanguageDetail(db, 'cmn', parseLocaleHints('cmn-Hans-CN'));
    expect(detail?.name).toBe('普通话');
    expect(detail?.locales[0].display_name).toBe('普通话(CN)');
    expect(detail?.locales[0].name).toBe('普通话(CN)');
  });

  it('filters expression counts by the requested locale attestation', async () => {
    let boundLocale = '';
    const db = {
      prepare(sql: string) {
        return {
          bind(...args: unknown[]) {
            boundLocale = typeof args[2] === 'string' ? args[2] : '';
            return {
              async first() {
                if (sql === LANGUAGE_ROW_SQL) return { code: 'cmn', name_en: 'Mandarin Chinese' };
                if (sql === EXPRESSION_COUNT_SQL) return { total: boundLocale === 'cmn-Hans-CN' ? 3 : 7 };
                if (sql === READING_COUNT_SQL) return { total: 2 };
                if (sql === MAPPED_EXPRESSION_COUNT_SQL) return { total: boundLocale === 'cmn-Hans-CN' ? 1 : 4 };
                return null;
              },
              async all() {
                return {
                  results: sql === LANGUAGE_LOCALES_SQL ? [
                    { code: 'cmn-Hans-CN', name: '普通话(CN)', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: null, region_longitude: null },
                  ] : [],
                };
              },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;

    const filtered = await getLanguageDetail(db, 'cmn', undefined, 'cmn-Hans-CN');
    expect(filtered?.expression_count).toBe(3);
    expect(filtered?.mapped_expression_count).toBe(1);
    const all = await getLanguageDetail(db, 'cmn');
    expect(all?.expression_count).toBe(7);
    expect(all?.mapped_expression_count).toBe(4);
  });
});

describe('listLanguagesWithContent', () => {
  it('returns paged summaries and resolves display names by the UI locale', async () => {
    const db = {
      prepare(sql: string) {
        return {
          bind(uiLocale: string) {
            return {
              async first() { return { total: 2 }; },
              async all() {
                if (sql.includes('COUNT(*) AS total FROM (')) return { results: [] };
                const cmnName = uiLocale === 'cmn-Hans-CN' ? '普通话' : uiLocale === 'cmn-Hant-TW' ? '華語' : 'Mandarin Chinese';
                return { results: [
                  { code: 'cmn', name_en: 'Mandarin Chinese', name: cmnName, expression_count: 3, locale_count: 2, active_ui_locale_count: 1 },
                  { code: 'eng', name_en: 'English', name: 'English', expression_count: 300, locale_count: 1, active_ui_locale_count: 1 },
                ] };
              },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    const result = await listLanguagesWithContent(db, { q: '', sort: 'count', limit: 20, offset: 0, uiLocale: 'cmn-Hant-TW', secondaryUiLocale: '' });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.code)).toEqual(['cmn', 'eng']);
    expect(result.items[0].name).toBe('華語');
  });

  it('resolves language name via the shared resolver', async () => {
    const db = {
      prepare(sql: string) {
        return {
          bind(uiLocale: string) {
            return {
              async first() { return { total: 2 }; },
              async all() {
                if (sql.includes('COUNT(*) AS total FROM (')) return { results: [] };
                const cmnName = uiLocale === 'cmn-Hans-CN' ? '普通话' : uiLocale === 'cmn-Hant-TW' ? '華語' : 'Mandarin Chinese';
                return { results: [
                  { code: 'cmn', name_en: 'Mandarin Chinese', name: cmnName, expression_count: 3, locale_count: 2, active_ui_locale_count: 1 },
                  { code: 'eng', name_en: 'English', name: 'English', expression_count: 300, locale_count: 1, active_ui_locale_count: 1 },
                ] };
              },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    const result = await listLanguagesWithContent(db, { q: '', sort: 'count', limit: 20, offset: 0, uiLocale: 'cmn-Hans-CN', secondaryUiLocale: '' });
    expect(result.total).toBe(2);
    expect(result.items[0].code).toBe('cmn');
    expect(result.items[0].name).toBe('普通话');
  });
});

describe('listLanguageExpressions', () => {
  it('returns null when the language does not exist', async () => {
    expect(await listLanguageExpressions(fakeD1({ [LANGUAGE_ROW_SQL]: () => null }), 'zzz', { q: '', locale: '', sort: 'hot', limit: 20, offset: 0, uiLocale: '', secondaryUiLocale: '' })).toBeNull();
  });

  it('supports stable hot, new and alphabetical ordering', async () => {
    const observedSql: string[] = [];
    const db = {
      prepare(sql: string) {
        observedSql.push(sql);
        return { bind() { return {
          async first() { return sql === LANGUAGE_ROW_SQL ? { code: 'nan' } : { total: 0 }; },
          async all() { return { results: [] }; },
        }; } };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;

    for (const sort of ['hot', 'new', 'alpha'] as const) {
      await listLanguageExpressions(db, 'nan', { q: '', locale: '', sort, limit: 20, offset: 0, uiLocale: '', secondaryUiLocale: '' });
    }

    const pageQueries = observedSql.filter((sql) => sql.includes('SELECT e.id'));
    expect(pageQueries[0]).toContain('ORDER BY mapping_count DESC, e.text ASC, e.homograph_index ASC, e.id ASC');
    expect(pageQueries[1]).toContain('ORDER BY e.created_at DESC, e.id ASC');
    expect(pageQueries[2]).toContain('ORDER BY e.text ASC, e.homograph_index ASC, e.id ASC');
  });
});
