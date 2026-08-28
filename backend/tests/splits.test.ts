import { describe, expect, it } from 'vitest';
import { splitExpression } from '../src/services/splits';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const batchSql: Array<{ sql: string; args: unknown[] }>[] = [];
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(...args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          __sql: sql,
          __args: args,
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
  return {
    prepare,
    batch: async (statements: Array<{ __sql?: string; __args?: unknown[] }>) => {
      batchSql.push(statements.map((statement) => ({ sql: statement.__sql ?? '', args: statement.__args ?? [] })));
      return [{ success: true }];
    },
    batchSql,
  } as unknown as import('@cloudflare/workers-types').D1Database & { batchSql: Array<{ sql: string; args: unknown[] }[]> };
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

const SOURCE_SQL = 'SELECT language_id,text,homograph_index,pos_mask,source_id FROM expressions WHERE id=?';
const MAX_IDX_SQL = 'SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE language_id=? AND text=?';
const TARGET_INSERT_SQL = 'INSERT INTO expressions(language_id,text,homograph_index,pos_mask,source_id,created_by) VALUES(?,?,?,?,?,?) RETURNING id';
const SPLIT_INSERT_SQL = 'INSERT INTO expression_splits(source_expression_id,target_expression_id,created_by) VALUES(?,?,?) RETURNING id';
const UPDATE_EDGE_SQL = 'UPDATE expression_edges SET expression_a_id=?,expression_b_id=? WHERE id=?';
const MOVE_INSERT_SQL = 'INSERT INTO expression_split_moves(split_id,edge_id) VALUES(?,?)';

const sourceExpression = { language_id: 1, text: '食', homograph_index: 1, pos_mask: 0, source_id: null };

function edgeQuery(edgeIds: number[]): string {
  return `SELECT id,expression_a_id,expression_b_id FROM expression_edges WHERE id IN (${edgeIds.map(() => '?').join(',')})`;
}

function successHandlers(edges: Array<{ id: number; expression_a_id: number; expression_b_id: number }>) {
  return {
    [SOURCE_SQL]: () => sourceExpression,
    [edgeQuery(edges.map((edge) => edge.id))]: () => ({ results: edges }),
    [MAX_IDX_SQL]: () => ({ max_idx: 1 }),
    [TARGET_INSERT_SQL]: () => ({ id: 2 }),
    [SPLIT_INSERT_SQL]: () => ({ id: 5 }),
  };
}

describe('splitExpression', () => {
  it('rejects empty edge_ids with EXPRESSION_SPLIT_EMPTY', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 1, edge_ids: [], created_by: 1 }))).toBe('EXPRESSION_SPLIT_EMPTY');
  });

  it('rejects an oversized edge_ids array before reading the database', async () => {
    let prepared = false;
    const db = fakeD1({});
    const originalPrepare = db.prepare;
    db.prepare = ((sql: string) => { prepared = true; return originalPrepare.call(db, sql); }) as typeof db.prepare;
    expect(await captureAsyncCode(() => splitExpression(db, {
      source_expression_id: 1,
      edge_ids: Array.from({ length: 101 }, (_, index) => index + 1),
      created_by: 1,
    }))).toBe('EXPRESSION_SPLIT_TOO_LARGE');
    expect(prepared).toBe(false);
  });

  it('rejects when source expression is missing with EXPRESSION_NOT_FOUND', async () => {
    const db = fakeD1({ [SOURCE_SQL]: () => null });
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 999, edge_ids: [10], created_by: 1 }))).toBe('EXPRESSION_NOT_FOUND');
  });

  it('rejects when an edge does not touch the source expression with EXPRESSION_SPLIT_EDGE_NOT_ADJACENT', async () => {
    const db = fakeD1({
      [SOURCE_SQL]: () => sourceExpression,
      [edgeQuery([10])]: () => ({ results: [] }),
    });
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 1, edge_ids: [10], created_by: 1 }))).toBe('EXPRESSION_SPLIT_EDGE_NOT_ADJACENT');
  });

  it('splits edges and creates a target expression with the next homograph index', async () => {
    const db = fakeD1(successHandlers([{ id: 10, expression_a_id: 2, expression_b_id: 1 }]));
    const result = await splitExpression(db, { source_expression_id: 1, edge_ids: [10], created_by: 5 });
    expect(result.split_id).toBe(5);
    expect(result.target_expression_id).toBe(2);
    expect(result.moved_edge_count).toBe(1);
    const statements = db.batchSql[0];
    expect(statements.map((statement) => statement.sql)).toEqual([UPDATE_EDGE_SQL, MOVE_INSERT_SQL]);
  });

  it('records a split move and re-points every moved edge at the target expression', async () => {
    const db = fakeD1(successHandlers([
      { id: 10, expression_a_id: 2, expression_b_id: 1 },
      { id: 11, expression_a_id: 3, expression_b_id: 1 },
    ]));
    const result = await splitExpression(db, { source_expression_id: 1, edge_ids: [10, 11], created_by: 5 });
    expect(result.moved_edge_count).toBe(2);
    const statements = db.batchSql[0];
    const updates = statements.filter((statement) => statement.sql === UPDATE_EDGE_SQL);
    expect(updates).toHaveLength(2);
    expect(updates[0].args).toEqual([2, 2, 10]);
    expect(updates[1].args).toEqual([2, 3, 11]);
    expect(statements.filter((statement) => statement.sql === MOVE_INSERT_SQL)).toHaveLength(2);
  });

  it('maps a UNIQUE constraint failure during the move to EXPRESSION_SPLIT_CONFLICT', async () => {
    const db = fakeD1(successHandlers([{ id: 10, expression_a_id: 2, expression_b_id: 1 }]));
    db.batch = async () => { throw new Error('D1_ERROR: UNIQUE constraint failed: expression_edges.id'); };
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 1, edge_ids: [10], created_by: 5 }))).toBe('EXPRESSION_SPLIT_CONFLICT');
  });
});
