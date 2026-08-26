import { describe, expect, it } from 'vitest';
import {
  MappingError,
  canonicalizeEdgePair,
  createEdge,
  decodeMappingCursor,
  encodeMappingCursor,
  getExpressionMappings,
} from '../src/services/mappings';

describe('numeric mapping identity', () => {
  it('canonicalizes a pair by integer order', () => {
    expect(canonicalizeEdgePair(9, 2)).toEqual([2, 9]);
    expect(() => canonicalizeEdgePair(2, 2)).toThrowError(MappingError);
  });

  it('round-trips phase cursors and rejects malformed input', () => {
    expect(decodeMappingCursor(encodeMappingCursor({ phase: 'a', key: 2056 }))).toEqual({ phase: 'a', key: 2056 });
    expect(decodeMappingCursor('b:9')).toEqual({ phase: 'b', key: 9 });
    expect(decodeMappingCursor('b:0')).toEqual({ phase: 'b', key: 0 });
    expect(decodeMappingCursor('a:0')).toBeNull();
    expect(decodeMappingCursor('x:2')).toBeNull();
  });
});

describe('createEdge', () => {
  it('ORs a new relation into an existing canonical pair', async () => {
    const updates: unknown[][] = [];
    const existing = { id: 7, expression_a_id: 2, expression_b_id: 9, relation_mask: 1, score: 0, created_by: 3 };
    const db = {
      prepare(sql: string) {
        return { bind(...args: unknown[]) { return {
          async first() { return sql.startsWith('SELECT') ? existing : null; },
          async run() { updates.push(args); return { success: true }; },
        }; } };
      },
    } as unknown as D1Database;

    const result = await createEdge(db, {
      expression_a_id: 9,
      expression_b_id: 2,
      relation_mask: 4,
      created_by: 3,
    });

    expect(result.created).toBe(false);
    expect(result.edge.relation_mask).toBe(5);
    expect(updates).toEqual([[5, 7]]);
  });
});

describe('getExpressionMappings', () => {
  it('continues from the a-side index into the b-side index without OFFSET', async () => {
    const statements: string[] = [];
    const db = {
      prepare(sql: string) {
        statements.push(sql);
        return { bind() { return { async all() {
          if (sql.includes('e.expression_a_id = ?')) {
            return { results: [{ edge_id: 10, neighbor_id: 3, neighbor_lang_code: 'eng', neighbor_text: 'cod', relation_mask: 1, score: 0 }] };
          }
          return { results: [{ edge_id: 11, neighbor_id: 1, neighbor_lang_code: 'cmn', neighbor_text: '鱈魚', relation_mask: 1, score: 0 }] };
        } }; } };
      },
    } as unknown as D1Database;

    const result = await getExpressionMappings(db, 2, { limit: 2, cursor: null });

    expect(result.items.map((item) => item.edge_id)).toEqual([10, 11]);
    expect(result.has_more).toBe(false);
    expect(result.next_cursor).toBeNull();
    expect(statements).toHaveLength(2);
    expect(statements.every((sql) => !/OFFSET|ORDER BY\s+e\.score/i.test(sql))).toBe(true);
  });
});
