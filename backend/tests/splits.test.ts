import { describe, expect, it } from 'vitest';
import { SplitError, splitExpression } from '../src/services/splits';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>, batchResult?: unknown) {
  const batchSql: string[][] = [];
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          __sql: sql,
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
    batch: async (statements: Array<{ __sql?: string }>) => {
      batchSql.push(statements.map((statement) => statement.__sql ?? ''));
      return batchResult ?? [{ success: true }];
    },
    batchSql,
  } as unknown as import('@cloudflare/workers-types').D1Database & { batchSql: string[][] };
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

  it('rejects an oversized edge_ids array before reading the database', async () => {
    let prepared = false;
    const db = fakeD1({});
    const originalPrepare = db.prepare;
    db.prepare = ((sql: string) => { prepared = true; return originalPrepare.call(db, sql); }) as typeof db.prepare;
    expect(await captureAsyncCode(() => splitExpression(db, {
      source_expression_id: 'nan:aaaa',
      edge_ids: Array.from({ length: 101 }, (_, index) => `edge-${index}`),
      created_by: 1,
    }))).toBe('EXPRESSION_SPLIT_TOO_LARGE');
    expect(prepared).toBe(false);
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

  it('bumps revisions for source and every moved opposite endpoint language', async () => {
    const edges = [
      { id: '01EDGE1', expression_a_id: 'eng:bbb', expression_b_id: 'nan:aaaa', score: 3, source: 'contribution', created_by: 1, created_at: '2026-08-13' },
      { id: '01EDGE2', expression_a_id: 'jpn:ccc', expression_b_id: 'nan:aaaa', score: 0, source: 'contribution', created_by: 1, created_at: '2026-08-13' },
    ];
    const expressionLangSql = 'SELECT DISTINCT lang_code FROM expressions WHERE id IN (SELECT value FROM json_each(?)) ORDER BY lang_code ASC';
    const localeSql = 'SELECT language_locale_code FROM ui_locales WHERE project_id = ? AND language_locale_code LIKE ? ORDER BY language_locale_code ASC LIMIT 200';
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?': () => sourceExpression,
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id IN (?, ?)': () => ({ results: edges }),
      'SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE lang_code = ? AND text_hash = ?': () => ({ max_idx: 1 }),
      [expressionLangSql]: () => ({ results: [{ lang_code: 'eng' }, { lang_code: 'jpn' }, { lang_code: 'nan' }] }),
      [localeSql]: () => ({ results: [{ language_locale_code: 'eng-Latn-US' }, { language_locale_code: 'jpn-Jpan-JP' }, { language_locale_code: 'nan-Hant-TW' }] }),
    });

    await splitExpression(db, { source_expression_id: 'nan:aaaa', edge_ids: ['01EDGE1', '01EDGE2'], created_by: 5 });

    const revisionSql = 'UPDATE ui_locales SET mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?';
    expect(db.batchSql[0].filter((sql) => sql === revisionSql)).toHaveLength(3);
  });
});
