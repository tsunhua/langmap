import type { Database } from '../src/db/database';
import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import expressions from '../src/routes/expressions';
import { splitExpression } from '../src/services/splits';

type Handler = () => unknown;

type DatabaseMock = import('../src/db/database').Database & { sqlLog: string[] };

function fakeDatabase(handlers: Record<string, Handler>): DatabaseMock {
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
  return { prepare, batch, sqlLog } as unknown as DatabaseMock;
}

const EXPRESSION_COLUMNS = 'e.id, e.language_id, l.code AS lang_code, e.text, e.homograph_index, e.pos_mask, e.source_id, e.created_by, e.created_at';
const KEY_SQL = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text=? AND e.homograph_index=?`;
const GET_BY_ID = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?`;
const LOCALE_LINKS_SQL = 'SELECT x.expression_id,x.locale_id,l.code AS language_locale_code,l.name AS locale_display_name FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=? ORDER BY l.code';
const READINGS_SQL = 'SELECT r.expression_id, r.locale_id, l.code AS language_locale_code,l.name AS locale_display_name, r.scheme, r.value, r.source_id FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? ORDER BY l.code,r.scheme,r.value';
const POS_SQL = 'SELECT code,name_en FROM parts_of_speech WHERE (? & (1 << bit_index)) != 0 ORDER BY sort_order';
const SOURCES_SQL = 'SELECT source_id,source_marker FROM expression_sources WHERE expression_id=? ORDER BY source_id,source_marker';

function keyDb(row: unknown) {
  return fakeDatabase({
    [KEY_SQL]: () => row,
    [GET_BY_ID]: () => row,
    [LOCALE_LINKS_SQL]: () => ({ results: [] }),
    [READINGS_SQL]: () => ({ results: [] }),
    [POS_SQL]: () => ({ results: [] }),
    [SOURCES_SQL]: () => ({ results: [] }),
  });
}

function app(db: DatabaseMock) {
  const application = new Hono<{ Bindings: { DB: import('../src/db/database').Database; SECRET_KEY: string } }>();
  application.route('/expressions', expressions);
  return application;
}

const row = {
  id: 7, language_id: 1, lang_code: 'en', text: 'hello', homograph_index: 1,
  pos_mask: 0, source_id: null, created_by: 1, created_at: '2026-08-12 00:00:00',
};

describe('GET /expressions/:lang/:text', () => {
  it('resolves an expression by text key', async () => {
    const db = keyDb(row);
    const response = await app(db).request('http://example.test/expressions/en/hello', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { expression: { id: string; homograph_index: number } } };
    expect(body.data.expression.id).toBe('7');
    expect(body.data.expression.homograph_index).toBe(1);
  });

  it('parses the homograph suffix', async () => {
    const db = keyDb({ ...row, id: 9, homograph_index: 2 });
    const response = await app(db).request('http://example.test/expressions/en/hello~2', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { expression: { id: string; homograph_index: number } } };
    expect(body.data.expression.id).toBe('9');
    expect(body.data.expression.homograph_index).toBe(2);
  });

  it('keeps encoded slashes inside the text segment', async () => {
    const db = keyDb({ ...row, text: 'hello/world' });
    const response = await app(db).request('http://example.test/expressions/en/hello%2Fworld', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { expression: { text: string } } };
    expect(body.data.expression.text).toBe('hello/world');
  });

  it('returns 404 when the key does not resolve', async () => {
    const db = keyDb(null);
    const response = await app(db).request('http://example.test/expressions/en/missing', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(404);
    const body = await response.json() as { error: string };
    expect(body.error).toBe('EXPRESSION_NOT_FOUND');
  });

  it('returns 400 for an invalid language segment', async () => {
    const db = keyDb(row);
    const response = await app(db).request('http://example.test/expressions/e%3An/hello', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(400);
    const body = await response.json() as { error: string };
    expect(body.error).toBe('INVALID_EXPRESSION_KEY');
  });

  it('resolves texts that collide with the graph sub-resource literal', async () => {
    const db = fakeDatabase({
      [KEY_SQL]: () => ({ ...row, text: 'graph' }),
      'SELECT e.id,e.text,e.homograph_index,l.code AS lang_code,l.name_en AS language_name FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?':
        () => ({ id: 7, text: 'graph', lang_code: 'en', language_name: 'English', homograph_index: 1 }),
    });
    const response = await app(db).request('http://example.test/expressions/en/graph', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { nodes: Array<{ text: string; depth: number }> } };
    expect(body.data.nodes[0]).toMatchObject({ text: 'graph', depth: 0 });
  });
});

describe('split target key fields', () => {
  it('returns the target expression natural key', async () => {
    const db = fakeDatabase({
      'SELECT e.language_id,e.text,e.homograph_index,e.pos_mask,e.source_id,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?':
        () => ({ language_id: 1, text: 'hello', homograph_index: 1, pos_mask: 0, source_id: null, lang_code: 'en' }),
      'SELECT id,expression_a_id,expression_b_id FROM expression_edges WHERE id IN (?)':
        () => ({ results: [{ id: 5, expression_a_id: 1, expression_b_id: 7 }] }),
      'SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE language_id=? AND text=?':
        () => ({ max_idx: 1 }),
      'INSERT INTO expressions(language_id,text,homograph_index,pos_mask,source_id,created_by) VALUES(?,?,?,?,?,?) RETURNING id':
        () => ({ id: 9 }),
      'INSERT INTO expression_splits(source_expression_id,target_expression_id,created_by) VALUES(?,?,?) RETURNING id':
        () => ({ id: 3 }),
      'INSERT INTO expression_split_moves(split_id,edge_id) VALUES(?,?)': () => ({ success: true }),
      'UPDATE expression_edges SET expression_a_id=?,expression_b_id=? WHERE id=?': () => ({ success: true }),
    });
    const result = await splitExpression(db, { source_expression_id: 1, edge_ids: [5], created_by: 1 });
    expect(result.target).toEqual({ lang_code: 'en', text: 'hello', homograph_index: 2 });
    expect(result.target_expression_id).toBe(9);
  });
});
