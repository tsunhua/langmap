import type { D1Database } from '@cloudflare/workers-types';
import type { MappingGraphEdge, MappingGraphNode, MappingGraphResponse } from '../types/mapping';

const DEFAULT_NODE_LIMIT = 200;

interface GraphEdgeRow {
  id: string;
  expression_a_id: string;
  expression_b_id: string;
  score: number;
  created_at: string;
  expression_a_text: string;
  expression_a_lang_code: string;
  expression_a_language_name: string | null;
  expression_b_text: string;
  expression_b_lang_code: string;
  expression_b_language_name: string | null;
}

function toNode(row: GraphEdgeRow, expressionId: string, depth: number): MappingGraphNode {
  const isA = row.expression_a_id === expressionId;
  const langCode = isA ? row.expression_a_lang_code : row.expression_b_lang_code;
  return {
    expression_id: expressionId,
    text: isA ? row.expression_a_text : row.expression_b_text,
    lang_code: langCode,
    language_name: (isA ? row.expression_a_language_name : row.expression_b_language_name) ?? langCode,
    depth,
  };
}

async function loadEdgesForFrontier(db: D1Database, frontier: readonly string[]): Promise<GraphEdgeRow[]> {
  const placeholders = frontier.map(() => '?').join(', ');
  const { results } = await db.prepare(
    `SELECT e.id, e.expression_a_id, e.expression_b_id, e.score, e.created_at,
      a.text AS expression_a_text, a.lang_code AS expression_a_lang_code, la.name_en AS expression_a_language_name,
      b.text AS expression_b_text, b.lang_code AS expression_b_lang_code, lb.name_en AS expression_b_language_name
     FROM expression_edges e
     JOIN expressions a ON a.id = e.expression_a_id
     JOIN expressions b ON b.id = e.expression_b_id
     LEFT JOIN languages la ON la.code = a.lang_code
     LEFT JOIN languages lb ON lb.code = b.lang_code
     WHERE e.expression_a_id IN (${placeholders}) OR e.expression_b_id IN (${placeholders})
     ORDER BY e.score DESC, e.created_at ASC, e.id ASC`,
  ).bind(...frontier, ...frontier).all<GraphEdgeRow>();
  return results;
}

export async function getMappingGraph(
  db: D1Database,
  rootId: string,
  hops: 1 | 2 | 3,
  nodeLimit = DEFAULT_NODE_LIMIT,
): Promise<MappingGraphResponse | null> {
  const root = await db.prepare(
    'SELECT e.id, e.text, e.lang_code, l.name_en AS language_name FROM expressions e LEFT JOIN languages l ON l.code = e.lang_code WHERE e.id = ?',
  ).bind(rootId).first<{ id: string; text: string; lang_code: string; language_name: string | null }>();
  if (!root) return null;

  const limit = Math.max(1, Math.min(nodeLimit, DEFAULT_NODE_LIMIT));
  const visited = new Set<string>([rootId]);
  const nodes: MappingGraphNode[] = [{
    expression_id: root.id,
    text: root.text,
    lang_code: root.lang_code,
    language_name: root.language_name ?? root.lang_code,
    depth: 0,
  }];
  const edges: MappingGraphEdge[] = [];
  const edgeIds = new Set<string>();
  const omitted = new Set<string>();
  const layerCounts: Record<number, number> = { 0: 1 };
  let frontier = [rootId];
  let resolvedHops: 0 | 1 | 2 | 3 = 0;

  for (let depth = 1; depth <= hops && frontier.length > 0; depth++) {
    const rows = await loadEdgesForFrontier(db, frontier);
    const next = new Set<string>();
    const frontierIds = new Set(frontier);
    for (const row of rows) {
      const touchesA = frontierIds.has(row.expression_a_id);
      const touchesB = frontierIds.has(row.expression_b_id);
      if (!touchesA && !touchesB) continue;
      if (!edgeIds.has(row.id)) {
        edgeIds.add(row.id);
        edges.push({
          edge_id: row.id,
          source_id: row.expression_a_id,
          target_id: row.expression_b_id,
          score: row.score,
          depth,
        });
      }
      const neighbors = touchesA && touchesB
        ? []
        : [touchesA ? row.expression_b_id : row.expression_a_id];
      for (const endpoint of neighbors) {
        if (visited.has(endpoint)) continue;
        if (visited.size >= limit) {
          omitted.add(endpoint);
          continue;
        }
        visited.add(endpoint);
        next.add(endpoint);
        nodes.push(toNode(row, endpoint, depth));
      }
    }
    if (rows.length > 0) resolvedHops = depth as 1 | 2 | 3;
    layerCounts[depth] = next.size;
    frontier = [...next].sort();
  }

  return {
    root_id: rootId,
    requested_hops: hops,
    resolved_hops: resolvedHops,
    nodes,
    edges,
    layer_counts: layerCounts,
    truncated: omitted.size > 0,
    omitted_count: omitted.size,
  };
}
