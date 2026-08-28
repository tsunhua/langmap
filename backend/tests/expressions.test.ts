import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import expressions from '../src/routes/expressions';
import {
  createExpression,
  createLocaleLink,
  getExpression,
  searchExpressions,
} from '../src/services/expressions';
import type { ExpressionRow } from '../src/types/expression';

type Handler = () => unknown;

type D1Mock = import('@cloudflare/workers-types').D1Database & {
  sqlLog: string[];
};

function fakeD1(handlers: Record<string, Handler>): D1Mock {
  const sqlLog: string[] = [];
  const prepare = (sql: string) => {
    sqlLog.push(sql);
    const handler = handlers[sql] ?? Object.entries(handlers).find(
      ([registered]) => registered.replace(/\s+/g, ' ').trim() === sql.replace(/\s+/g, ' ').trim(),
    )?.[1];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async run() { return handler ? await handler() : { success: true }; },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  const batch = async (statements: Array<{ run(): Promise<unknown> }>) => Promise.all(statements.map((statement) => statement.run()));
  return { prepare, batch, sqlLog } as unknown as D1Mock;
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

const normalize = (sql: string) => sql.replace(/\s+/g, ' ').trim();

const EXPRESSION_COLUMNS = 'e.id, e.language_id, l.code AS lang_code, e.text, e.homograph_index, e.pos_mask, e.source_id, e.created_by, e.created_at';
const GET_BY_ID = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?`;
const GET_BY_TEXT = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.language_id=? AND e.text=? AND e.homograph_index=1`;
const LOCALE_LINKS_SQL = 'SELECT x.expression_id,x.locale_id,l.code AS language_locale_code FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=? ORDER BY l.code';
const READINGS_SQL = 'SELECT r.expression_id, r.locale_id, l.code AS language_locale_code, r.scheme, r.value, r.source_id FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? ORDER BY l.code,r.scheme,r.value';
const POS_SQL = 'SELECT code,name_en FROM parts_of_speech WHERE (? & (1 << bit_index)) != 0 ORDER BY sort_order';
const SEARCH_ORDER = 'ORDER BY e.text,e.homograph_index,e.id LIMIT ? OFFSET ?';
const SEARCH_BY_LANG_TERM = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text>=? AND e.text<? ${SEARCH_ORDER}`;
const SEARCH_BY_LANG = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? ${SEARCH_ORDER}`;
const SEARCH_ALL = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id ${SEARCH_ORDER}`;

const existingRow: ExpressionRow = {
  id: 1, language_id: 1, lang_code: 'nan', text: '食', homograph_index: 1,
  pos_mask: 0, source_id: null, created_by: 1, created_at: '2026-08-12 00:00:00',
};

describe('createExpression', () => {
  it('creates a new expression with the next integer id', async () => {
    const createdRow: ExpressionRow = { ...existingRow, id: 4 };
    const insertCalled: string[] = [];
    const db = fakeD1({
      'SELECT id FROM languages WHERE code=?': () => ({ id: 1 }),
      [GET_BY_TEXT]: () => null,
      'INSERT INTO expressions(language_id,text,pos_mask,source_id,created_by) VALUES(?,?,?,?,?) RETURNING id':
        () => { insertCalled.push('insert'); return { id: 4 }; },
      'INSERT INTO language_statistics(language_id, expression_count, updated_at) VALUES (?, 1, CURRENT_TIMESTAMP)\n    ON CONFLICT(language_id) DO UPDATE SET expression_count=expression_count+1, updated_at=CURRENT_TIMESTAMP':
        () => ({ success: true }),
      [GET_BY_ID]: () => createdRow,
    });
    const result = await createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 });
    expect(result.created).toBe(true);
    expect(result.expression.id).toBe(4);
    expect(insertCalled).toHaveLength(1);
  });

  it('reuses an existing expression when the canonical text matches', async () => {
    const db = fakeD1({
      'SELECT id FROM languages WHERE code=?': () => ({ id: 1 }),
      [GET_BY_TEXT]: () => existingRow,
    });
    const result = await createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 });
    expect(result.created).toBe(false);
    expect(result.expression.id).toBe(1);
  });

  it('links the requested locale when reusing an expression', async () => {
    const inserted: string[] = [];
    const db = fakeD1({
      'SELECT id FROM languages WHERE code=?': () => ({ id: 1 }),
      'SELECT id FROM language_locales WHERE code=? AND language_id=?': () => ({ id: 2 }),
      [GET_BY_TEXT]: () => existingRow,
      'INSERT OR IGNORE INTO expression_locale_links(expression_id, locale_id) VALUES (?, ?)':
        () => { inserted.push('locale'); return { success: true }; },
    });
    const result = await createExpression(db, {
      lang_code: 'nan', text: '食', language_locale_code: 'nan-Hant-TW', created_by: 1,
    });
    expect(result.created).toBe(false);
    expect(inserted).toEqual(['locale']);
  });

  it('rejects an unknown lang_code with INVALID_LANG_CODE', async () => {
    const db = fakeD1({ 'SELECT id FROM languages WHERE code=?': () => null });
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'zzz', text: '食', created_by: 1 }))).toBe(
      'INVALID_LANG_CODE',
    );
  });

  it('rejects an unknown language_locale_code with INVALID_LANGUAGE_LOCALE_CODE', async () => {
    const db = fakeD1({
      'SELECT id FROM languages WHERE code=?': () => ({ id: 1 }),
      'SELECT id FROM language_locales WHERE code=? AND language_id=?': () => null,
    });
    expect(await captureAsyncCode(() => createExpression(db, {
      lang_code: 'nan', text: '食', language_locale_code: 'nan-Hant-ZZ', created_by: 1,
    }))).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('rejects empty canonical text with VALIDATION_FAILED', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'nan', text: '   ', created_by: 1 }))).toBe(
      'VALIDATION_FAILED',
    );
  });
});

describe('searchExpressions', () => {
  it('returns items ordered by text and a total', async () => {
    const rows = [
      { ...existingRow, id: 1, text: '食' },
      { ...existingRow, id: 2, text: '食飯' },
    ];
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text>=? AND e.text<?':
        () => ({ total: 2 }),
      [SEARCH_BY_LANG_TERM]: () => ({ results: rows }),
    });
    const result = await searchExpressions(db, { q: '食', lang_code: 'nan', limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.text)).toEqual(['食', '食飯']);
  });

  it('filters by lang_code when provided', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=?':
        () => ({ total: 1 }),
      [SEARCH_BY_LANG]: () => ({ results: [] }),
    });
    const result = await searchExpressions(db, { q: '', lang_code: 'nan', limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items).toHaveLength(0);
  });

  it('returns all items ordered by text when no filter is supplied', async () => {
    const rows = [{ ...existingRow, id: 1, text: '厝' }, { ...existingRow, id: 2, text: '家' }];
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expressions e JOIN languages l ON l.id=e.language_id':
        () => ({ total: 2 }),
      [SEARCH_ALL]: () => ({ results: rows }),
    });
    const result = await searchExpressions(db, { q: '', limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.text)).toEqual(['厝', '家']);
    expect(db.sqlLog.some((sql) => normalize(sql) === normalize(SEARCH_ALL))).toBe(true);
  });
});

describe('getExpression', () => {
  it('returns the expression with sorted locales and integer ids', async () => {
    const db = fakeD1({
      [GET_BY_ID]: () => existingRow,
      [LOCALE_LINKS_SQL]: () => ({ results: [
        { expression_id: 1, locale_id: 1, language_locale_code: 'nan-Hant-CN' },
        { expression_id: 1, locale_id: 2, language_locale_code: 'nan-Hant-TW' },
      ] }),
      [READINGS_SQL]: () => ({ results: [] }),
      [POS_SQL]: () => ({ results: [{ code: 'n', name_en: 'Noun' }] }),
    });
    const result = await getExpression(db, 1);
    expect(result).not.toBeNull();
    expect(result?.expression.id).toBe(1);
    expect(db.sqlLog.some((sql) => normalize(sql) === normalize(LOCALE_LINKS_SQL))).toBe(true);
    expect(result?.locales.map((row) => row.language_locale_code)).toEqual(['nan-Hant-CN', 'nan-Hant-TW']);
    expect(result?.parts_of_speech).toEqual([{ code: 'n', name_en: 'Noun' }]);
    expect(result?.sources).toEqual([]);
  });

  it('returns null for a missing expression', async () => {
    const db = fakeD1({ [GET_BY_ID]: () => null });
    expect(await getExpression(db, 999)).toBeNull();
  });
});

describe('createLocaleLink', () => {
  it('creates a locale link and reports created=true', async () => {
    const db = fakeD1({
      'SELECT id FROM expressions WHERE id=?': () => ({ id: 1 }),
      'SELECT id FROM language_locales WHERE code=?': () => ({ id: 2 }),
      'SELECT 1 FROM expression_locale_links WHERE expression_id=? AND locale_id=?': () => null,
      'INSERT INTO expression_locale_links(expression_id,locale_id) VALUES (?,?)': () => ({ success: true }),
    });
    const result = await createLocaleLink(db, { expression_id: 1, language_locale_code: 'nan-Hant-TW' });
    expect(result.created).toBe(true);
    expect(result.locale).toEqual({ expression_id: 1, locale_id: 2, language_locale_code: 'nan-Hant-TW' });
  });

  it('reuses an existing link with created=false', async () => {
    const db = fakeD1({
      'SELECT id FROM expressions WHERE id=?': () => ({ id: 1 }),
      'SELECT id FROM language_locales WHERE code=?': () => ({ id: 2 }),
      'SELECT 1 FROM expression_locale_links WHERE expression_id=? AND locale_id=?': () => ({ ok: 1 }),
    });
    const result = await createLocaleLink(db, { expression_id: 1, language_locale_code: 'nan-Hant-TW' });
    expect(result.created).toBe(false);
  });

  it('throws EXPRESSION_NOT_FOUND for a missing expression', async () => {
    const db = fakeD1({ 'SELECT id FROM expressions WHERE id=?': () => null });
    expect(await captureAsyncCode(() => createLocaleLink(db, { expression_id: 999, language_locale_code: 'nan-Hant-TW' }))).toBe(
      'EXPRESSION_NOT_FOUND',
    );
  });

  it('throws INVALID_LANGUAGE_LOCALE_CODE for an unknown locale', async () => {
    const db = fakeD1({
      'SELECT id FROM expressions WHERE id=?': () => ({ id: 1 }),
      'SELECT id FROM language_locales WHERE code=?': () => null,
    });
    expect(await captureAsyncCode(() => createLocaleLink(db, { expression_id: 1, language_locale_code: 'nan-Hant-ZZ' }))).toBe(
      'INVALID_LANGUAGE_LOCALE_CODE',
    );
  });
});

describe('expressions route GET /:id', () => {
  it('serializes integer ids in the detail response', async () => {
    function fakeDb(): import('@cloudflare/workers-types').D1Database {
      return {
        prepare(sql: string) {
          return {
            bind(..._args: unknown[]) {
              return {
                async first() {
                  if (sql.includes('ORDER BY l.code,r.scheme,r.value') || sql.includes('FROM expression_locale_links')) return null;
                  if (sql.includes('FROM expressions e JOIN languages l') && sql.includes('WHERE e.id=?')) {
                    return existingRow;
                  }
                  return null;
                },
                async all() {
                  if (sql.includes('FROM expression_locale_links')) {
                    return { results: [{ expression_id: 1, locale_id: 2, language_locale_code: 'nan-Hant-TW' }] };
                  }
                  if (sql.includes('FROM expression_readings')) {
                    return { results: [{ expression_id: 1, locale_id: 2, language_locale_code: 'nan-Hant-TW', scheme: 'poj', value: 'chia̍h', source_id: null }] };
                  }
                  if (sql.includes('FROM parts_of_speech')) {
                    return { results: [{ code: 'n', name_en: 'Noun' }] };
                  }
                  return { results: [] };
                },
              };
            },
          };
        },
      } as unknown as import('@cloudflare/workers-types').D1Database;
    }

    const app = new Hono<{ Bindings: { DB: import('@cloudflare/workers-types').D1Database; SECRET_KEY: string } }>();
    app.route('/expressions', expressions);
    const response = await app.request('http://example.test/expressions/1', undefined, { DB: fakeDb(), SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { expression: { id: string }; locales: Array<{ expression_id: string; locale_id: string }>; readings: Array<{ expression_id: string; locale_id: string }> } };
    expect(body.data.expression.id).toBe('1');
    expect(body.data.locales[0]).toEqual({ expression_id: '1', locale_id: '2', language_locale_code: 'nan-Hant-TW' });
    expect(body.data.readings[0]).toEqual({ expression_id: '1', locale_id: '2', language_locale_code: 'nan-Hant-TW', scheme: 'poj', value: 'chia̍h', source_id: null });
  });
});
