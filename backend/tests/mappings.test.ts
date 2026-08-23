import { describe, expect, it } from 'vitest';
import {
  MappingError,
  canonicalizeEdgePair,
  createEdge,
  createEdgesBatch,
  getExpressionMappings,
} from '../src/services/mappings';
import type { EdgeRow } from '../src/types/mapping';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() {
            return (await run()) as T;
          },
          async run() {
            return handler ? await handler() : { success: true };
          },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

describe('canonicalizeEdgePair', () => {
  it('sorts two expression ids into ascending order', () => {
    expect(canonicalizeEdgePair('nan:bbb', 'eng:aaa')).toEqual(['eng:aaa', 'nan:bbb']);
    expect(canonicalizeEdgePair('eng:aaa', 'nan:bbb')).toEqual(['eng:aaa', 'nan:bbb']);
  });

  it('throws VALIDATION_FAILED for identical endpoints', () => {
    expect(() => canonicalizeEdgePair('nan:aaa', 'nan:aaa')).toThrow();
  });
});

describe('createEdge', () => {
  const mockEdge: EdgeRow = {
    id: '01HX', expression_a_id: 'eng:aaa', expression_b_id: 'nan:bbb',
    score: 0, source: 'contribution', created_by: 1, created_at: '2026-08-13 00:00:00',
  };

  it('creates a new edge with canonicalized pair', async () => {
    let inserted = false;
    const db = fakeD1({
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?':
        () => null,
      'INSERT INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)':
        () => { inserted = true; return { success: true }; },
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id = ?':
        () => mockEdge,
    });
    const result = await createEdge(db, { expression_a_id: 'nan:bbb', expression_b_id: 'eng:aaa', source: 'contribution', created_by: 1 });
    expect(result.created).toBe(true);
    expect(result.edge.expression_a_id).toBe('eng:aaa');
    expect(result.edge.expression_b_id).toBe('nan:bbb');
    expect(inserted).toBe(true);
  });

  it('reuses an existing edge when pair already exists', async () => {
    let inserted = false;
    const db = fakeD1({
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?':
        () => mockEdge,
      'INSERT INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)':
        () => { inserted = true; return { success: true }; },
    });
    const result = await createEdge(db, { expression_a_id: 'eng:aaa', expression_b_id: 'nan:bbb', source: 'contribution', created_by: 1 });
    expect(result.created).toBe(false);
    expect(result.edge.id).toBe('01HX');
    expect(inserted).toBe(false);
  });

  it('rejects identical endpoints with VALIDATION_FAILED', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createEdge(db, { expression_a_id: 'nan:aaa', expression_b_id: 'nan:aaa', source: 'x', created_by: 1 }))).toBe('VALIDATION_FAILED');
  });
});

describe('createEdgesBatch', () => {
  it('creates a clique from 3 expressions and dedups pairs', async () => {
    const rows = new Map<string, EdgeRow>();
    const db = {
      prepare(sql: string) {
        return {
          bind(...args: unknown[]) {
            return {
              async all<T>() {
                if (!sql.includes('WHERE (expression_a_id = ? AND expression_b_id = ?)')) return { results: [] as T[] };
                const results: EdgeRow[] = [];
                for (let index = 0; index < args.length; index += 2) {
                  const key = `${String(args[index])}\u0000${String(args[index + 1])}`;
                  const row = rows.get(key);
                  if (row) results.push(row);
                }
                return { results: results as T[] };
              },
              async run() {
                const id = String(args[0]);
                const lowId = String(args[1]);
                const highId = String(args[2]);
                rows.set(`${lowId}\u0000${highId}`, {
                  id, expression_a_id: lowId, expression_b_id: highId, score: 0,
                  source: 'contribution', created_by: 1, created_at: '2026-08-13',
                });
                return { success: true };
              },
            };
          },
        };
      },
      async batch(statements: Array<{ run(): Promise<unknown> }>) {
        return Promise.all(statements.map((statement) => statement.run()));
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    const result = await createEdgesBatch(db, { expression_ids: ['nan:a', 'nan:b', 'nan:c'], source: 'contribution', created_by: 1 });
    expect(result.edges).toHaveLength(3);
    expect(result.created_count).toBe(3);
  });

  it('rejects fewer than 2 expression ids', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createEdgesBatch(db, { expression_ids: ['nan:a'], source: 'x', created_by: 1 }))).toBe('VALIDATION_FAILED');
  });
});

describe('getExpressionMappings', () => {
  it('returns edges with neighbor info ordered by score desc then created_at then edge id', async () => {
    const items = [
      { edge_id: 'e2', neighbor_id: 'nan:b', neighbor_lang_code: 'nan', neighbor_text: '飯', score: 5, source: 'contribution', created_at: '2026-08-13' },
      { edge_id: 'e1', neighbor_id: 'eng:c', neighbor_lang_code: 'eng', neighbor_text: 'rice', score: 5, source: 'contribution', created_at: '2026-08-12' },
    ];
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expression_edges WHERE expression_a_id = ? OR expression_b_id = ?': () => ({ total: 2 }),
      'SELECT e.id AS edge_id, n.id AS neighbor_id, n.lang_code AS neighbor_lang_code, n.text AS neighbor_text, e.score, e.source, e.created_at FROM expression_edges e JOIN expressions n ON n.id = CASE WHEN e.expression_a_id = ? THEN e.expression_b_id ELSE e.expression_a_id END WHERE e.expression_a_id = ? OR e.expression_b_id = ? ORDER BY e.score DESC, e.created_at ASC, e.id ASC LIMIT ? OFFSET ?':
        () => ({ results: items }),
    });
    const result = await getExpressionMappings(db, 'nan:a', { limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items[0].edge_id).toBe('e2');
    expect(result.items[0].neighbor_text).toBe('飯');
  });

  it('returns empty for an expression with no edges', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expression_edges WHERE expression_a_id = ? OR expression_b_id = ?': () => ({ total: 0 }),
      'SELECT e.id AS edge_id, n.id AS neighbor_id, n.lang_code AS neighbor_lang_code, n.text AS neighbor_text, e.score, e.source, e.created_at FROM expression_edges e JOIN expressions n ON n.id = CASE WHEN e.expression_a_id = ? THEN e.expression_b_id ELSE e.expression_a_id END WHERE e.expression_a_id = ? OR e.expression_b_id = ? ORDER BY e.score DESC, e.created_at ASC, e.id ASC LIMIT ? OFFSET ?':
        () => ({ results: [] }),
    });
    const result = await getExpressionMappings(db, 'nan:lonely', { limit: 20, offset: 0 });
    expect(result.total).toBe(0);
    expect(result.items).toHaveLength(0);
  });
});
