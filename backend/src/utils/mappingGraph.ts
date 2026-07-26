import type {
  MappingGraphEdge,
  MappingGraphNode,
  MappingGraphResponse,
} from '../types';

export interface NeighborRow {
  edge_id: string;
  expression_a_id: number;
  expression_b_id: number;
  score: number;
}

export interface ExpressionRow {
  expression_id: number;
  text: string;
  language_code: string;
  language_name: string | null;
}

export type LoadEdges = (frontierIds: number[]) => Promise<NeighborRow[]>;
export type LoadExpressions = (ids: number[]) => Promise<ExpressionRow[]>;

const HOPS_MIN = 1;
const HOPS_MAX = 3;

export function parseMappingHops(value: string | undefined): 1 | 2 | 3 {
  if (value === undefined || value === '') return 1;
  const n = Number(value);
  if (!Number.isFinite(n)) return 1;
  const int = Math.trunc(n);
  if (int < HOPS_MIN) return 1;
  if (int > HOPS_MAX) return 3;
  return int as 1 | 2 | 3;
}

export async function buildMappingGraph(
  rootId: number,
  requestedHops: 1 | 2 | 3,
  loadEdges: LoadEdges,
  loadExpressions: LoadExpressions,
  maxNodes = 200,
): Promise<MappingGraphResponse> {
  const nodes = new Map<number, MappingGraphNode>();
  const depthOf = new Map<number, number>();
  const edges = new Map<string, MappingGraphEdge>();

  const rootRows = await loadExpressions([rootId]);
  const rootRow = rootRows.find((r) => r.expression_id === rootId);
  const root: MappingGraphNode = {
    expression_id: rootId,
    text: rootRow?.text ?? '',
    language_code: rootRow?.language_code ?? '',
    language_name: rootRow?.language_name ?? null,
    depth: 0,
  };
  nodes.set(rootId, root);
  depthOf.set(rootId, 0);

  let frontier: number[] = [rootId];
  let truncated = false;
  let omittedCount = 0;

  for (let depth = 1; depth <= requestedHops; depth++) {
    if (frontier.length === 0) break;

    const rawEdges = await loadEdges(frontier);

    // Pass A: collect new neighbor ids (the endpoint of each edge not yet discovered).
    const newIds: number[] = [];
    const newIdSet = new Set<number>();
    for (const e of rawEdges) {
      for (const cid of [e.expression_a_id, e.expression_b_id]) {
        if (depthOf.has(cid) || newIdSet.has(cid)) continue;
        newIdSet.add(cid);
        newIds.push(cid);
      }
    }

    // Pass B: fetch expressions for new ids and register as many as the cap allows.
    let addedThisLayer = 0;
    if (newIds.length > 0) {
      const rows = await loadExpressions(newIds);
      const rowMap = new Map(rows.map((r) => [r.expression_id, r]));
      for (const id of newIds) {
        if (nodes.size >= maxNodes) {
          truncated = true;
          break;
        }
        const row = rowMap.get(id);
        if (!row) continue;
        nodes.set(id, {
          expression_id: id,
          text: row.text,
          language_code: row.language_code,
          language_name: row.language_name,
          depth,
        });
        depthOf.set(id, depth);
        addedThisLayer++;
      }
      if (truncated) {
        omittedCount = newIds.length - addedThisLayer;
      }
    }

    // Pass C: record edges whose both endpoints are now registered, dedup by edge_id.
    for (const e of rawEdges) {
      if (edges.has(e.edge_id)) continue;
      const da = depthOf.get(e.expression_a_id);
      const db = depthOf.get(e.expression_b_id);
      if (da === undefined || db === undefined) continue;

      let sourceId: number;
      let targetId: number;
      if (da < db) {
        sourceId = e.expression_a_id;
        targetId = e.expression_b_id;
      } else if (db < da) {
        sourceId = e.expression_b_id;
        targetId = e.expression_a_id;
      } else {
        // same depth: stable direction by smaller expression id
        if (e.expression_a_id <= e.expression_b_id) {
          sourceId = e.expression_a_id;
          targetId = e.expression_b_id;
        } else {
          sourceId = e.expression_b_id;
          targetId = e.expression_a_id;
        }
      }

      edges.set(e.edge_id, {
        edge_id: e.edge_id,
        source_id: sourceId,
        target_id: targetId,
        score: e.score,
        depth: Math.max(da, db),
      });
    }

    if (truncated) break;
    frontier = newIds.filter((id) => depthOf.has(id));
  }

  const resolvedHops = (() => {
    let max = 0;
    for (const d of depthOf.values()) if (d > max) max = d;
    return max as 0 | 1 | 2 | 3;
  })();

  const layerCounts: Record<number, number> = {};
  for (const node of nodes.values()) {
    layerCounts[node.depth] = (layerCounts[node.depth] ?? 0) + 1;
  }

  const sortedNodes = [...nodes.values()].sort((a, b) => {
    if (a.depth !== b.depth) return a.depth - b.depth;
    return a.expression_id - b.expression_id;
  });

  const sortedEdges = [...edges.values()].sort((a, b) => {
    if (a.depth !== b.depth) return a.depth - b.depth;
    if (a.source_id !== b.source_id) return a.source_id - b.source_id;
    if (a.target_id !== b.target_id) return a.target_id - b.target_id;
    return a.edge_id.localeCompare(b.edge_id);
  });

  return {
    root_id: rootId,
    requested_hops: requestedHops,
    resolved_hops: resolvedHops,
    nodes: sortedNodes,
    edges: sortedEdges,
    layer_counts: layerCounts,
    truncated,
    omitted_count: omittedCount,
  };
}
