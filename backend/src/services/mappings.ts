import type { D1Database, D1PreparedStatement } from '@cloudflare/workers-types';
import type { EdgeRow, EdgeWithNeighborRow } from '../types/mapping';
import { ulid } from '../utils/ulid';
import { D1_WRITE_CHUNK_SIZE } from '../utils/limits';

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
  const ids = [...new Set(input.expression_ids.filter((id) => Boolean(id)))];
  if (ids.length < 2) throw new MappingError('VALIDATION_FAILED');

  const pairs: Array<[string, string]> = [];
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      const [lowId, highId] = canonicalizeEdgePair(ids[i], ids[j]);
      pairs.push([lowId, highId]);
    }
  }
  const results = await createEdgesForPairs(db, { pairs, source: input.source, created_by: input.created_by });
  return {
    edges: results.map((result) => result.edge),
    created_count: results.filter((result) => result.created).length,
  };
}

export async function createEdgesForPairs(
  db: D1Database,
  input: { pairs: Array<[string, string]>; source: string; created_by: number },
): Promise<Array<{ edge: EdgeRow; created: boolean }>> {
  const pairs: Array<{ lowId: string; highId: string; generatedId?: string }> = [];
  const seen = new Set<string>();
  for (const [a, b] of input.pairs) {
    const [lowId, highId] = canonicalizeEdgePair(a, b);
    const key = pairKey(lowId, highId);
    if (seen.has(key)) continue;
    seen.add(key);
    pairs.push({ lowId, highId });
  }
  if (pairs.length === 0) return [];

  const existingByPair = new Map<string, EdgeRow>();
  for (const chunk of chunkArray(pairs, D1_WRITE_CHUNK_SIZE)) {
    const where = chunk.map(() => '(expression_a_id = ? AND expression_b_id = ?)').join(' OR ');
    const bindings = chunk.flatMap((pair) => [pair.lowId, pair.highId]);
    const { results } = await db
      .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE ${where}`)
      .bind(...bindings)
      .all<EdgeRow>();
    for (const edge of results) existingByPair.set(pairKey(edge.expression_a_id, edge.expression_b_id), edge);
  }

  const statements: D1PreparedStatement[] = [];
  for (const pair of pairs) {
    if (existingByPair.has(pairKey(pair.lowId, pair.highId))) continue;
    pair.generatedId = ulid();
    statements.push(db.prepare(
      'INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)',
    ).bind(pair.generatedId, pair.lowId, pair.highId, input.source, input.created_by));
  }
  for (const chunk of chunkArray(statements, D1_WRITE_CHUNK_SIZE)) await db.batch(chunk);

  const edgesByPair = new Map<string, EdgeRow>();
  for (const chunk of chunkArray(pairs, D1_WRITE_CHUNK_SIZE)) {
    const where = chunk.map(() => '(expression_a_id = ? AND expression_b_id = ?)').join(' OR ');
    const bindings = chunk.flatMap((pair) => [pair.lowId, pair.highId]);
    const { results } = await db
      .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE ${where}`)
      .bind(...bindings)
      .all<EdgeRow>();
    for (const edge of results) edgesByPair.set(pairKey(edge.expression_a_id, edge.expression_b_id), edge);
  }

  return pairs.map((pair) => {
    const edge = edgesByPair.get(pairKey(pair.lowId, pair.highId));
    if (!edge) throw new MappingError('EDGE_CREATE_FAILED');
    return { edge, created: Boolean(pair.generatedId && edge.id === pair.generatedId) };
  });
}

function pairKey(lowId: string, highId: string): string {
  return `${lowId}\u0000${highId}`;
}

function chunkArray<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let index = 0; index < items.length; index += size) chunks.push(items.slice(index, index + size));
  return chunks;
}

export async function getExpressionMappings(
  db: D1Database,
  expressionId: string,
  query: { limit: number; offset: number },
): Promise<{ items: EdgeWithNeighborRow[]; total: number }> {
  const [countRow, page] = await Promise.all([
    db
    .prepare('SELECT COUNT(*) AS total FROM expression_edges WHERE expression_a_id = ? OR expression_b_id = ?')
    .bind(expressionId, expressionId)
    .first<{ total: number }>(),
    db
    .prepare(
      `SELECT e.id AS edge_id, n.id AS neighbor_id, n.lang_code AS neighbor_lang_code, n.text AS neighbor_text, e.score, e.source, e.created_at FROM expression_edges e JOIN expressions n ON n.id = CASE WHEN e.expression_a_id = ? THEN e.expression_b_id ELSE e.expression_a_id END WHERE e.expression_a_id = ? OR e.expression_b_id = ? ORDER BY e.score DESC, e.created_at ASC, e.id ASC LIMIT ? OFFSET ?`,
    )
    .bind(expressionId, expressionId, expressionId, query.limit, query.offset)
    .all<EdgeWithNeighborRow>(),
  ]);
  return { items: page.results, total: countRow?.total ?? 0 };
}
