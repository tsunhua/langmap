import { describe, expect, it } from 'vitest';
import { getExpression } from '../src/services/expressions';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const queries: string[] = [];
  const prepare = (sql: string) => {
    queries.push(sql);
    const handler = handlers[sql] ?? Object.entries(handlers).find(
      ([registered]) => registered.replace(/\s+/g, ' ').trim() === sql.replace(/\s+/g, ' ').trim(),
    )?.[1];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T[] };
          },
        };
      },
    };
  };
  return { prepare, queries } as unknown as import('@cloudflare/workers-types').D1Database & { queries: string[] };
}

const EXPRESSION_BY_ID = 'SELECT e.id, e.language_id, l.code AS lang_code, e.text, e.homograph_index, e.pos_mask, e.source_id, e.created_by, e.created_at FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?';
const LOCALE_LINKS_SQL = 'SELECT x.expression_id,x.locale_id,l.code AS language_locale_code FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=? ORDER BY l.code';
const READINGS_SQL = 'SELECT r.expression_id, r.locale_id, l.code AS language_locale_code, r.scheme, r.value, r.source_id FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? ORDER BY l.code,r.scheme,r.value';
const POS_SQL = 'SELECT code,name_en FROM parts_of_speech WHERE (? & (1 << bit_index)) != 0 ORDER BY sort_order';
const SOURCES_SQL = 'SELECT source_id,source_marker FROM expression_sources WHERE expression_id=? ORDER BY source_id,source_marker';

const expressionRow = {
  id: 1, language_id: 1, lang_code: 'nan', text: '食', homograph_index: 1,
  pos_mask: 0, source_id: null, created_by: 1, created_at: '2026-08-13 00:00:00',
};

describe('getExpression', () => {
  it('returns readings in stable locale, scheme, value order with integer ids', async () => {
    const readingRows = [
      { expression_id: 1, locale_id: 1, language_locale_code: 'nan-Hant-CN', scheme: 'poj', value: 'tsia̍h', source_id: null },
      { expression_id: 1, locale_id: 2, language_locale_code: 'nan-Hant-TW', scheme: 'poj', value: 'chia̍h', source_id: null },
    ];
    const db = fakeD1({
      [EXPRESSION_BY_ID]: () => expressionRow,
      [LOCALE_LINKS_SQL]: () => ({ results: [] }),
      [READINGS_SQL]: () => ({ results: readingRows }),
      [POS_SQL]: () => ({ results: [] }),
    });

    const detail = await getExpression(db, 1);
    expect(detail?.readings[0]).toMatchObject({ expression_id: 1, language_locale_code: 'nan-Hant-CN', scheme: 'poj', value: 'tsia̍h' });
    expect(detail?.readings[1]).toMatchObject({ expression_id: 1, language_locale_code: 'nan-Hant-TW', scheme: 'poj', value: 'chia̍h' });
    expect(db.queries.find((sql) => sql.includes('FROM expression_readings'))).toContain(
      'ORDER BY l.code,r.scheme,r.value',
    );
  });

  it('maps expression sources to { source_id, marker } provenance pairs', async () => {
    const db = fakeD1({
      [EXPRESSION_BY_ID]: () => expressionRow,
      [LOCALE_LINKS_SQL]: () => ({ results: [] }),
      [READINGS_SQL]: () => ({ results: [] }),
      [POS_SQL]: () => ({ results: [] }),
      [SOURCES_SQL]: () => ({ results: [{ source_id: 7, source_marker: '2' }, { source_id: 7, source_marker: '' }] }),
    });

    const detail = await getExpression(db, 1);
    expect(detail?.sources).toEqual([{ source_id: 7, marker: '2' }, { source_id: 7, marker: null }]);
  });

  it('returns null for a missing expression', async () => {
    const db = fakeD1({ [EXPRESSION_BY_ID]: () => null });
    expect(await getExpression(db, 999)).toBeNull();
  });
});
