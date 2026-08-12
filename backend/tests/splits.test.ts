import { describe, expect, it } from 'vitest';
import { SplitError, splitExpression } from '../src/services/splits';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>, batchResult?: unknown) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
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
  return {
    prepare,
    batch: async () => batchResult ?? [{ success: true }],
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

const sourceExpression = {
  id: 'nan:aaaa', lang_code: 'nan', text: '食', text_hash: 'aaaa',
  homograph_index: 1, description: '', tags_json: '[]', source_id: null,
  source_ref: null, review_status: 'pending', created_by: 1,
  created_at: '2026-08-13', updated_at: '2026-08-13',
};

describe('splitExpression', () => {
  it('rejects empty edge_ids with EXPRESSION_SPLIT_EMPTY', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 'nan:aaaa', edge_ids: [], created_by: 1 }))).toBe('EXPRESSION_SPLIT_EMPTY');
  });

  it('rejects when source expression is missing with EXPRESSION_NOT_FOUND', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => null,
    });
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 'nan:missing', edge_ids: ['01EDGE'], created_by: 1 }))).toBe('EXPRESSION_NOT_FOUND');
  });

  it('rejects when an edge does not touch the source expression with EXPRESSION_SPLIT_EDGE_NOT_ADJACENT', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => sourceExpression,
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id IN (?)': () => ({ results: [] }),
    });
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 'nan:aaaa', edge_ids: ['01EDGE'], created_by: 1 }))).toBe('EXPRESSION_SPLIT_EDGE_NOT_ADJACENT');
  });

  it('splits edges and creates target expression with next homograph index', async () => {
    const edges = [
      { id: '01EDGE1', expression_a_id: 'eng:bbb', expression_b_id: 'nan:aaaa', score: 3, source: 'contribution', created_by: 1, created_at: '2026-08-13' },
    ];
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => sourceExpression,
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id IN (?)':
        () => ({ results: edges }),
      'SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE lang_code = ? AND text_hash = ?':
        () => ({ max_idx: 1 }),
    });
    const result = await splitExpression(db, { source_expression_id: 'nan:aaaa', edge_ids: ['01EDGE1'], created_by: 5 });
    expect(result.target_expression_id).toBe('nan:aaaa.2');
    expect(result.moved_edge_count).toBe(1);
  });
});
