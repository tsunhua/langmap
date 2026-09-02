import { describe, expect, it } from 'vitest';
import { getLanguageDetail, listLanguageExpressions, listLanguagesWithContent } from '../src/services/languageContent';
import { parseLocaleHints } from '../src/services/localizedName';

type Handler = (params: unknown[]) => unknown;

function fakeD1(matchers: Array<{ sql: string; handler: Handler }>) {
  return {
    prepare(sql: string) {
      const entries = matchers.filter((m) => sql.includes(m.sql));
      return {
        bind(...params: unknown[]) {
          const entry = entries[0];
          return {
            async first<T>() { return (entry ? await entry.handler(params) : null) as T; },
            async all<T>() { const result = (entry ? await entry.handler(params) : { results: [] }) as { results?: unknown }; return { results: (result.results ?? []) as T[] }; },
          };
        },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

const LANGUAGE_ROW_SQL = 'SELECT id,code,name_en FROM languages WHERE code=?';
const LANGUAGE_IDENTITY_SQL = 'FROM languages WHERE code IN';
const EXPRESSIONS_SQL = 'SELECT id, text FROM expressions WHERE id IN';
const CANDIDATE_SQL = 'WITH candidate_rows AS';

describe('getLanguageDetail', () => {
  it('returns null for an unknown language code', async () => {
    const db = fakeD1([{ sql: LANGUAGE_ROW_SQL, handler: () => null }]);
    expect(await getLanguageDetail(db, 'zzz')).toBeNull();
  });

  it('labels locale, region and missing coordinates', async () => {
    const db = fakeD1([
      { sql: LANGUAGE_ROW_SQL, handler: () => ({ id: 1, code: 'cmn', name_en: 'Mandarin Chinese' }) },
      { sql: 'SELECT 1 FROM expression_edges g', handler: () => ({ total: 4 }) },
      { sql: 'FROM expression_readings r', handler: () => ({ total: 2 }) },
      { sql: 'SELECT COUNT(*) AS total FROM expressions e WHERE e.language_id=?', handler: () => ({ total: 7 }) },
      { sql: 'FROM language_locales ll LEFT JOIN regions r', handler: () => ({ results: [
        { code: 'cmn-Hans-CN', name: '普通话(CN)', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: null, region_longitude: null },
        { code: 'cmn-Hant-TW', name: '華語(TW)', name_en: 'Taiwan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: 23.7, region_longitude: 121 },
        { code: 'cmn-Hant-TW_Tainan', name: '臺南話', name_en: 'Tainan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: 'Tainan', locale_latitude: 22.99, locale_longitude: 120.2, region_latitude: 23.7, region_longitude: 121 },
      ] }) },
    ]);
    const detail = await getLanguageDetail(db, 'cmn');
    expect(detail?.name).toBe('Mandarin Chinese');
    expect(detail?.expression_count).toBe(7);
    expect(detail?.reading_count).toBe(2);
    expect(detail?.mapped_expression_count).toBe(4);
    expect(detail?.locales.map((locale) => locale.coordinate_source)).toEqual([null, 'region', 'locale']);
    expect(detail?.locales.map((locale) => locale.latitude)).toEqual([null, 23.7, 22.99]);
  });

  it('filters expression counts by the requested locale', async () => {
    let boundLocale = '';
    const db = {
      prepare(sql: string) {
        return {
          bind(...args: unknown[]) {
            boundLocale = typeof args[1] === 'string' ? args[1] : '';
            return {
              async first() {
                if (sql === LANGUAGE_ROW_SQL) return { id: 1, code: 'cmn', name_en: 'Mandarin Chinese' };
                if (sql.includes('FROM expression_edges')) return { total: boundLocale === 'cmn-Hans-CN' ? 1 : 4 };
                if (sql.includes('FROM expression_readings')) return { total: 2 };
                if (sql.includes('COUNT(*) AS total FROM expressions e')) return { total: boundLocale === 'cmn-Hans-CN' ? 3 : 7 };
                return null;
              },
              async all() {
                return { results: sql.includes('FROM language_locales ll') ? [
                  { code: 'cmn-Hans-CN', name: '普通话(CN)', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: null, region_longitude: null },
                ] : [] };
              },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;

    const filtered = await getLanguageDetail(db, 'cmn', {}, 'cmn-Hans-CN');
    expect(filtered?.expression_count).toBe(3);
    expect(filtered?.mapped_expression_count).toBe(1);
    const all = await getLanguageDetail(db, 'cmn');
    expect(all?.expression_count).toBe(7);
    expect(all?.mapped_expression_count).toBe(4);
  });
});

describe('listLanguagesWithContent', () => {
  it('returns paged summaries from language_statistics and resolves names by the UI locale', async () => {
    const db = fakeD1([
      { sql: 'COUNT(*) AS total FROM (', handler: () => ({ total: 2 }) },
      { sql: 'JOIN language_statistics s', handler: () => ({ results: [
        { code: 'cmn', name_en: 'Mandarin Chinese', expression_count: 3, locale_count: 2, active_ui_locale_count: 1 },
        { code: 'eng', name_en: 'English', expression_count: 300, locale_count: 1, active_ui_locale_count: 1 },
      ] }) },
      { sql: LANGUAGE_IDENTITY_SQL, handler: () => ({ results: [
        { code: 'cmn', name_expression_id: 101, name_en: 'Mandarin Chinese', name: null },
        { code: 'eng', name_expression_id: null, name_en: 'English', name: null },
      ] }) },
      { sql: EXPRESSIONS_SQL, handler: () => ({ results: [{ id: 101, text: 'Mandarin Chinese' }] }) },
      { sql: CANDIDATE_SQL, handler: () => ({ results: [{ source_id: 101, target_id: 201, target_text: '普通话', score: 1 }] }) },
    ]);
    const result = await listLanguagesWithContent(db, { q: '', sort: 'count', limit: 20, offset: 0, uiLocale: 'cmn-Hans-CN', secondaryUiLocale: '' });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.code)).toEqual(['cmn', 'eng']);
    expect(result.items[0].name).toBe('普通话');
    expect(result.items[1].name).toBe('英语');
  });

  it('falls back to name_en when no locale translation exists', async () => {
    const db = fakeD1([
      { sql: 'COUNT(*) AS total FROM (', handler: () => ({ total: 1 }) },
      { sql: 'JOIN language_statistics s', handler: () => ({ results: [
        { code: 'cmn', name_en: 'Some language', expression_count: 3, locale_count: 2, active_ui_locale_count: 1 },
      ] }) },
      { sql: LANGUAGE_IDENTITY_SQL, handler: () => ({ results: [
        { code: 'cmn', name_expression_id: 101, name_en: 'Some language', name: null },
      ] }) },
      { sql: EXPRESSIONS_SQL, handler: () => ({ results: [{ id: 101, text: 'Some language' }] }) },
      { sql: CANDIDATE_SQL, handler: () => ({ results: [] }) },
    ]);
    const result = await listLanguagesWithContent(db, { q: '', sort: 'count', limit: 20, offset: 0, uiLocale: 'cmn-Hans-CN', secondaryUiLocale: '' });
    expect(result.items[0].name).toBe('Some language');
  });

  it('applies the LIKE filter when a search query is present', async () => {
    const sqls: string[] = [];
    const db = fakeD1([
      { sql: 'COUNT(*) AS total FROM (', handler: () => { sqls.push('count'); return { total: 0 }; } },
      { sql: 'l.name_en LIKE ?', handler: () => { sqls.push('filter'); return { results: [] }; } },
    ]);
    await listLanguagesWithContent(db, { q: 'mand', sort: 'alpha', limit: 20, offset: 0, uiLocale: '', secondaryUiLocale: '' });
    expect(sqls).toContain('count');
    expect(sqls).toContain('filter');
  });
});

describe('listLanguageExpressions', () => {
  it('returns null when the language does not exist', async () => {
    const db = fakeD1([{ sql: 'SELECT id FROM languages WHERE code=?', handler: () => null }]);
    expect(await listLanguageExpressions(db, 'zzz', { q: '', locale: '', sort: 'hot', limit: 20, offset: 0, uiLocale: '', secondaryUiLocale: '' })).toBeNull();
  });

  it('supports stable hot, new and alphabetical ordering', async () => {
    const observedSql: string[] = [];
    const db = {
      prepare(sql: string) {
        observedSql.push(sql);
        return { bind() { return {
          async first() { return sql === 'SELECT id FROM languages WHERE code=?' ? { id: 1 } : { total: 0 }; },
          async all() { return { results: [] }; },
        }; } };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;

    for (const sort of ['hot', 'new', 'alpha'] as const) {
      await listLanguageExpressions(db, 'nan', { q: '', locale: '', sort, limit: 20, offset: 0, uiLocale: '', secondaryUiLocale: '' });
    }

    const pageQueries = observedSql.filter((sql) => sql.includes('SELECT e.id'));
    expect(pageQueries[0]).toContain('ORDER BY mapping_count DESC,e.text,e.homograph_index,e.id');
    expect(pageQueries[1]).toContain('ORDER BY e.created_at DESC,e.id');
    expect(pageQueries[2]).toContain('ORDER BY e.text,e.homograph_index,e.id');
  });

  it('filters by text and locale and computes reading/mapping counts', async () => {
    const db = fakeD1([
      { sql: 'SELECT id FROM languages WHERE code=?', handler: () => ({ id: 1 }) },
      { sql: 'SELECT COUNT(*) AS total FROM expressions e WHERE e.language_id=?', handler: () => ({ total: 1 }) },
      { sql: 'SELECT e.id,? AS lang_code', handler: () => ({ results: [
        { id: 5, lang_code: 'nan', text: '食', homograph_index: 1, created_at: 'x', reading_count: 2, mapping_count: 3, language_name: 'nan' },
      ] }) },
    ]);
    const result = await listLanguageExpressions(db, 'nan', { q: '食', locale: '', sort: 'hot', limit: 20, offset: 0, uiLocale: '', secondaryUiLocale: '' });
    expect(result?.total).toBe(1);
    expect(result?.items[0]).toMatchObject({ id: 5, text: '食', reading_count: 2, mapping_count: 3 });
  });
});
