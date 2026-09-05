import type { D1Database } from '@cloudflare/workers-types';
import type { EdgeRow, EdgeWithNeighborRow } from '../types/mapping';

const EDGE_COLUMNS = 'id, expression_a_id, expression_b_id, relation_mask, score, created_by';
// Example-only edges are retained as dictionary evidence, but are not direct
// semantic mappings for the mapping list.
const DIRECT_RELATION_MASK = 1 | 2;

export class MappingError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'MappingError';
  }
}

export interface MappingCursor {
  phase: 'a' | 'b';
  key: number;
}

export function encodeMappingCursor(cursor: MappingCursor): string {
  return `${cursor.phase}:${cursor.key}`;
}

export function decodeMappingCursor(value: string | null | undefined): MappingCursor | null {
  if (!value) return null;
  const match = /^([ab]):(0|[1-9]\d*)$/.exec(value);
  if (!match) return null;
  const key = Number(match[2]);
  const phase = match[1] as 'a' | 'b';
  return Number.isSafeInteger(key) && (key > 0 || phase === 'b') ? { phase, key } : null;
}

export function canonicalizeEdgePair(a: number, b: number): [number, number] {
  if (!Number.isSafeInteger(a) || !Number.isSafeInteger(b) || a <= 0 || b <= 0 || a === b) {
    throw new MappingError('VALIDATION_FAILED');
  }
  return a < b ? [a, b] : [b, a];
}

function validateRelationMask(value: number): void {
  if (!Number.isInteger(value) || value < 1 || value > 7) throw new MappingError('INVALID_RELATION_MASK');
}

export async function createEdge(
  db: D1Database,
  input: { expression_a_id: number; expression_b_id: number; relation_mask?: number; created_by: number },
): Promise<{ edge: EdgeRow; created: boolean }> {
  const [lowId, highId] = canonicalizeEdgePair(input.expression_a_id, input.expression_b_id);
  const relationMask = input.relation_mask ?? 1;
  validateRelationMask(relationMask);

  const existing = await db
    .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?`)
    .bind(lowId, highId)
    .first<EdgeRow>();
  if (existing) {
    const combined = existing.relation_mask | relationMask;
    if (combined !== existing.relation_mask) {
      await db.prepare('UPDATE expression_edges SET relation_mask = ? WHERE id = ?').bind(combined, existing.id).run();
    }
    return { edge: { ...existing, relation_mask: combined }, created: false };
  }

  const inserted = await db
    .prepare(`INSERT INTO expression_edges (expression_a_id, expression_b_id, relation_mask, created_by)
      VALUES (?, ?, ?, ?) RETURNING ${EDGE_COLUMNS}`)
    .bind(lowId, highId, relationMask, input.created_by)
    .first<EdgeRow>();
  if (!inserted) throw new MappingError('EDGE_CREATE_FAILED');
  return { edge: inserted, created: true };
}

export async function createEdgesBatch(
  db: D1Database,
  input: { expression_ids: number[]; relation_mask?: number; created_by: number },
): Promise<{ edges: EdgeRow[]; created_count: number }> {
  const ids = [...new Set(input.expression_ids)];
  if (ids.length < 2) throw new MappingError('VALIDATION_FAILED');
  const edges: EdgeRow[] = [];
  let createdCount = 0;
  for (let left = 0; left < ids.length; left += 1) {
    for (let right = left + 1; right < ids.length; right += 1) {
      const result = await createEdge(db, {
        expression_a_id: ids[left],
        expression_b_id: ids[right],
        relation_mask: input.relation_mask,
        created_by: input.created_by,
      });
      edges.push(result.edge);
      if (result.created) createdCount += 1;
    }
  }
  return { edges, created_count: createdCount };
}

export async function createEdgesForPairs(
  db: D1Database,
  input: { pairs: Array<[number, number]>; relation_mask?: number; created_by: number },
): Promise<Array<{ edge: EdgeRow; created: boolean }>> {
  const seen = new Set<string>();
  const results: Array<{ edge: EdgeRow; created: boolean }> = [];
  for (const [left, right] of input.pairs) {
    const pair = canonicalizeEdgePair(left, right);
    const key = `${pair[0]}:${pair[1]}`;
    if (seen.has(key)) continue;
    seen.add(key);
    results.push(await createEdge(db, {
      expression_a_id: pair[0],
      expression_b_id: pair[1],
      relation_mask: input.relation_mask,
      created_by: input.created_by,
    }));
  }
  return results;
}

const A_SIDE_SQL = `SELECT e.id AS edge_id, n.id AS neighbor_id, l.code AS neighbor_lang_code,
  n.text AS neighbor_text, e.relation_mask, e.score
 FROM expression_edges e
 JOIN expressions n ON n.id = e.expression_b_id
 JOIN languages l ON l.id = n.language_id
 WHERE e.expression_a_id = ? AND e.expression_b_id > ? AND (e.relation_mask & ${DIRECT_RELATION_MASK}) <> 0
 ORDER BY e.expression_b_id ASC
 LIMIT ?`;

const B_SIDE_SQL = `SELECT e.id AS edge_id, n.id AS neighbor_id, l.code AS neighbor_lang_code,
  n.text AS neighbor_text, e.relation_mask, e.score
 FROM expression_edges e
 JOIN expressions n ON n.id = e.expression_a_id
 JOIN languages l ON l.id = n.language_id
 WHERE e.expression_b_id = ? AND e.id > ? AND (e.relation_mask & ${DIRECT_RELATION_MASK}) <> 0
 ORDER BY e.id ASC
 LIMIT ?`;

export async function getExpressionMappings(
  db: D1Database,
  expressionId: number,
  query: { limit: number; cursor?: string | null },
): Promise<{ items: EdgeWithNeighborRow[]; next_cursor: string | null; has_more: boolean }> {
  const limit = Math.max(1, Math.min(100, Math.trunc(query.limit)));
  const cursor = decodeMappingCursor(query.cursor);
  if (query.cursor && !cursor) throw new MappingError('INVALID_CURSOR');

  if (cursor?.phase === 'b') {
    const { results } = await db.prepare(B_SIDE_SQL).bind(expressionId, cursor.key, limit + 1).all<EdgeWithNeighborRow>();
    const items = results.slice(0, limit);
    return {
      items,
      has_more: results.length > limit,
      next_cursor: results.length > limit && items.length
        ? encodeMappingCursor({ phase: 'b', key: items[items.length - 1].edge_id })
        : null,
    };
  }

  const aKey = cursor?.key ?? 0;
  const { results: aRows } = await db.prepare(A_SIDE_SQL).bind(expressionId, aKey, limit + 1).all<EdgeWithNeighborRow>();
  if (aRows.length > limit) {
    const items = aRows.slice(0, limit);
    return {
      items,
      has_more: true,
      next_cursor: encodeMappingCursor({ phase: 'a', key: items[items.length - 1].neighbor_id }),
    };
  }

  const remaining = limit - aRows.length;
  const { results: bRows } = await db.prepare(B_SIDE_SQL).bind(expressionId, 0, remaining + 1).all<EdgeWithNeighborRow>();
  const bItems = bRows.slice(0, remaining);
  const items = [...aRows, ...bItems];
  const hasMore = bRows.length > remaining;
  return {
    items,
    has_more: hasMore,
    next_cursor: hasMore
      ? encodeMappingCursor({ phase: 'b', key: bItems.length ? bItems[bItems.length - 1].edge_id : 0 })
      : null,
  };
}
