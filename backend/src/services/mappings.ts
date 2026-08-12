import type { D1Database } from '@cloudflare/workers-types';
import type { EdgeRow, EdgeWithNeighborRow } from '../types/mapping';
import { ulid } from '../utils/ulid';

const EDGE_COLUMNS = `id, expression_a_id, expression_b_id, score, source, created_by, created_at`;

export class MappingError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'MappingError';
  }
}

export function canonicalizeEdgePair(a: string, b: string): [string, string] {
  if (!a || !b || a === b) throw new MappingError('VALIDATION_FAILED');
  return a < b ? [a, b] : [b, a];
}

export async function createEdge(
  db: D1Database,
  input: { expression_a_id: string; expression_b_id: string; source: string; created_by: number },
): Promise<{ edge: EdgeRow; created: boolean }> {
  const [lowId, highId] = canonicalizeEdgePair(input.expression_a_id, input.expression_b_id);

  const existing = await db
    .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?`)
    .bind(lowId, highId)
    .first<EdgeRow>();
  if (existing) return { edge: existing, created: false };

  const id = ulid();
  await db
    .prepare('INSERT INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)')
    .bind(id, lowId, highId, input.source, input.created_by)
    .run();

  const edge = await db
    .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE id = ?`)
    .bind(id)
    .first<EdgeRow>();
  return { edge: edge as EdgeRow, created: true };
}

export async function createEdgesBatch(
  db: D1Database,
  input: { expression_ids: string[]; source: string; created_by: number },
): Promise<{ edges: EdgeRow[]; created_count: number }> {
  const ids = input.expression_ids;
  if (ids.length < 2) throw new MappingError('VALIDATION_FAILED');

  const edges: EdgeRow[] = [];
  let createdCount = 0;
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      const result = await createEdge(db, {
        expression_a_id: ids[i],
        expression_b_id: ids[j],
        source: input.source,
        created_by: input.created_by,
      });
      edges.push(result.edge);
      if (result.created) createdCount++;
    }
  }
  return { edges, created_count: createdCount };
}

export async function getExpressionMappings(
  db: D1Database,
  expressionId: string,
  query: { limit: number; offset: number },
): Promise<{ items: EdgeWithNeighborRow[]; total: number }> {
  const countRow = await db
    .prepare('SELECT COUNT(*) AS total FROM expression_edges WHERE expression_a_id = ? OR expression_b_id = ?')
    .bind(expressionId, expressionId)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(
      `SELECT e.id AS edge_id, n.id AS neighbor_id, n.lang_code AS neighbor_lang_code, n.text AS neighbor_text, e.score, e.source, e.created_at FROM expression_edges e JOIN expressions n ON n.id = CASE WHEN e.expression_a_id = ? THEN e.expression_b_id ELSE e.expression_a_id END WHERE e.expression_a_id = ? OR e.expression_b_id = ? ORDER BY e.score DESC, e.created_at ASC, e.id ASC LIMIT ? OFFSET ?`,
    )
    .bind(expressionId, expressionId, expressionId, query.limit, query.offset)
    .all<EdgeWithNeighborRow>();
  return { items: results, total: countRow?.total ?? 0 };
}
