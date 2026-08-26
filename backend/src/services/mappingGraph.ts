import type { D1Database } from '@cloudflare/workers-types';
import type { MappingGraphEdge, MappingGraphNode, MappingGraphResponse } from '../types/mapping';

const NODE_LIMIT = 200;
interface EdgeRow { id:number; expression_a_id:number; expression_b_id:number; relation_mask:number; score:number; }
interface NodeRow { id:number; text:string; lang_code:string; }

export async function getMappingGraph(db: D1Database, rootId: number, hops: 1 | 2 | 3, targetLanguage?: string): Promise<MappingGraphResponse | null> {
  const root = await db.prepare('SELECT e.id,e.text,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?').bind(rootId).first<NodeRow>();
  if (!root) return null;
  const nodes = new Map<number, MappingGraphNode>([[root.id, { expression_id: root.id, text: root.text, lang_code: root.lang_code, language_name: root.lang_code, depth: 0 }]]);
  const edges = new Map<number, MappingGraphEdge>(); let frontier = [rootId]; let omitted = 0; let resolved: 0 | 1 | 2 | 3 = 0;
  for (let depth = 1 as 1 | 2 | 3; depth <= hops && frontier.length; depth = (depth + 1) as 1 | 2 | 3) {
    const marks = frontier.map(() => '?').join(',');
    const result = await db.prepare(`SELECT id,expression_a_id,expression_b_id,relation_mask,score FROM expression_edges WHERE expression_a_id IN (${marks}) OR expression_b_id IN (${marks}) ORDER BY id`).bind(...frontier,...frontier).all<EdgeRow>();
    const neighbors = new Set<number>(); for (const edge of result.results) { neighbors.add(edge.expression_a_id); neighbors.add(edge.expression_b_id); }
    const unknown = [...neighbors].filter((id) => !nodes.has(id));
    const nodeRows = unknown.length ? await db.prepare(`SELECT e.id,e.text,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id IN (${unknown.map(() => '?').join(',')})`).bind(...unknown).all<NodeRow>() : { results: [] as NodeRow[] };
    const next: number[] = [];
    for (const row of nodeRows.results) {
      if (targetLanguage && depth === 1 && row.lang_code !== targetLanguage) continue;
      if (nodes.size >= NODE_LIMIT) { omitted++; continue; }
      nodes.set(row.id, { expression_id: row.id, text: row.text, lang_code: row.lang_code, language_name: row.lang_code, depth }); next.push(row.id);
    }
    for (const edge of result.results) {
      const a = nodes.get(edge.expression_a_id); const b = nodes.get(edge.expression_b_id);
      if (a && b) edges.set(edge.id, { edge_id: edge.id, source_id: edge.expression_a_id, target_id: edge.expression_b_id, relation_mask: edge.relation_mask, score: edge.score, depth });
    }
    frontier = next; resolved = depth;
  }
  const layer_counts: Record<number, number> = { 0: 1, 1: 0, 2: 0, 3: 0 }; for (const node of nodes.values()) layer_counts[node.depth] = (layer_counts[node.depth] ?? 0) + (node.depth ? 1 : 0);
  return { root_id: rootId, requested_hops: hops, resolved_hops: resolved, nodes: [...nodes.values()].sort((a,b) => a.depth-b.depth || a.expression_id-b.expression_id), edges: [...edges.values()].sort((a,b) => a.edge_id-b.edge_id), layer_counts, truncated: omitted > 0, omitted_count: omitted };
}
