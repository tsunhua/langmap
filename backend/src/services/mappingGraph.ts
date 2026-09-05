import type { D1Database } from '@cloudflare/workers-types';
import type { EdgeSourceMarker, MappingGraphEdge, MappingGraphNode, MappingGraphResponse } from '../types/mapping';

const NODE_LIMIT = 200;
const SQLITE_BIND_CHUNK = 80;
// Edge adjacency uses the frontier twice in its OR predicate, so keep the
// effective bind count below D1's SQLite variable limit.
const EDGE_BIND_CHUNK = 40;
// Example-only edges remain queryable as evidence, but must not create a
// semantic neighbour or inflate the direct/indirect mapping graph.
const DIRECT_RELATION_MASK = 1 | 2;
interface EdgeRow { id:number; expression_a_id:number; expression_b_id:number; relation_mask:number; score:number; }
interface NodeRow { id:number; text:string; lang_code:string; }

/** Parses a comma-separated language filter (e.g. "eng,cmn-Hant") into a lowercase code set. */
function parseTargetLanguages(value: string | undefined): Set<string> {
  return new Set((value ?? '').split(',').map((code) => code.trim().toLowerCase()).filter(Boolean));
}

export async function getMappingGraph(db: D1Database, rootId: number, hops: 1 | 2 | 3, targetLanguage?: string): Promise<MappingGraphResponse | null> {
  // Filtering applies at every hop so traversal never hops through excluded languages.
  const targetLanguages = parseTargetLanguages(targetLanguage);
  const root = await db.prepare('SELECT e.id,e.text,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?').bind(rootId).first<NodeRow>();
  if (!root) return null;
  const nodes = new Map<number, MappingGraphNode>([[root.id, { expression_id: root.id, text: root.text, lang_code: root.lang_code, language_name: root.lang_code, depth: 0 }]]);
  const edges = new Map<number, MappingGraphEdge>(); let frontier = [rootId]; let omitted = 0; let resolved: 0 | 1 | 2 | 3 = 0;
  for (let depth = 1 as 1 | 2 | 3; depth <= hops && frontier.length; depth = (depth + 1) as 1 | 2 | 3) {
    const edgeResults: EdgeRow[] = [];
    for (let offset = 0; offset < frontier.length; offset += EDGE_BIND_CHUNK) {
      const chunk = frontier.slice(offset, offset + EDGE_BIND_CHUNK);
      const marks = chunk.map(() => '?').join(',');
      const result = await db.prepare(`SELECT id,expression_a_id,expression_b_id,relation_mask,score FROM expression_edges WHERE (expression_a_id IN (${marks}) OR expression_b_id IN (${marks})) AND (relation_mask & ${DIRECT_RELATION_MASK}) <> 0 ORDER BY id`).bind(...chunk, ...chunk).all<EdgeRow>();
      edgeResults.push(...result.results);
    }
    edgeResults.sort((a, b) => a.id - b.id);
    const result = { results: edgeResults };
    const neighbors = new Set<number>(); for (const edge of result.results) { neighbors.add(edge.expression_a_id); neighbors.add(edge.expression_b_id); }
    const unknown = [...neighbors].filter((id) => !nodes.has(id));
    const nodeRows: { results: NodeRow[] } = { results: [] };
    for (let offset = 0; offset < unknown.length; offset += SQLITE_BIND_CHUNK) {
      const chunk = unknown.slice(offset, offset + SQLITE_BIND_CHUNK);
      const rows = await db.prepare(`SELECT e.id,e.text,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id IN (${chunk.map(() => '?').join(',')})`).bind(...chunk).all<NodeRow>();
      nodeRows.results.push(...rows.results);
    }
    const next: number[] = [];
    for (const row of nodeRows.results) {
      // The root anchor is kept regardless; every other hop must be in the filtered set.
      if (targetLanguages.size && !targetLanguages.has(row.lang_code)) continue;
      if (nodes.size >= NODE_LIMIT) { omitted++; continue; }
      nodes.set(row.id, { expression_id: row.id, text: row.text, lang_code: row.lang_code, language_name: row.lang_code, depth }); next.push(row.id);
    }
    for (const edge of result.results) {
      const a = nodes.get(edge.expression_a_id); const b = nodes.get(edge.expression_b_id);
      if (a && b) edges.set(edge.id, { edge_id: edge.id, source_id: edge.expression_a_id, target_id: edge.expression_b_id, relation_mask: edge.relation_mask, score: edge.score, depth, sources: [] });
    }
    frontier = next; resolved = depth;
  }
  const edgeIds = [...edges.keys()];
  if (edgeIds.length) {
    // Edge provenance is optional: pre-migration databases keep an empty list instead of failing the whole graph.
    try {
      const markerRows: { edge_id:number; source_id:number; source_marker:string }[] = [];
      for (let offset = 0; offset < edgeIds.length; offset += SQLITE_BIND_CHUNK) {
        const chunk = edgeIds.slice(offset, offset + SQLITE_BIND_CHUNK);
        const rows = await db.prepare(`SELECT edge_id,source_id,source_marker FROM expression_edge_sources WHERE edge_id IN (${chunk.map(() => '?').join(',')}) ORDER BY edge_id,source_id,source_marker`).bind(...chunk).all<{ edge_id:number; source_id:number; source_marker:string }>();
        markerRows.push(...rows.results);
      }
      markerRows.sort((a, b) => a.edge_id - b.edge_id || a.source_id - b.source_id || a.source_marker.localeCompare(b.source_marker));
      const byEdge = new Map<number, EdgeSourceMarker[]>();
      for (const row of markerRows) {
        const markers = byEdge.get(row.edge_id) ?? [];
        markers.push({ source_id: row.source_id, marker: row.source_marker || null });
        byEdge.set(row.edge_id, markers);
      }
      for (const edge of edges.values()) edge.sources = byEdge.get(edge.edge_id) ?? [];
    } catch {
      // Leave sources empty when the provenance tables are absent.
    }
  }
  const layer_counts: Record<number, number> = { 0: 1, 1: 0, 2: 0, 3: 0 }; for (const node of nodes.values()) layer_counts[node.depth] = (layer_counts[node.depth] ?? 0) + (node.depth ? 1 : 0);
  return { root_id: rootId, requested_hops: hops, resolved_hops: resolved, nodes: [...nodes.values()].sort((a,b) => a.depth-b.depth || a.expression_id-b.expression_id), edges: [...edges.values()].sort((a,b) => a.edge_id-b.edge_id), layer_counts, truncated: omitted > 0, omitted_count: omitted };
}
