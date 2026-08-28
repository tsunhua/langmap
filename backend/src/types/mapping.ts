export interface EdgeRow {
  id: number;
  expression_a_id: number;
  expression_b_id: number;
  relation_mask: number;
  score: number;
  created_by: number | null;
}

export interface EdgeWithNeighborRow {
  edge_id: number;
  neighbor_id: number;
  neighbor_lang_code: string;
  neighbor_text: string;
  relation_mask: number;
  score: number;
}

export interface MappingGraphNode {
  expression_id: number;
  text: string;
  lang_code: string;
  language_name: string;
  depth: number;
}

export interface MappingGraphEdge {
  edge_id: number;
  source_id: number;
  target_id: number;
  relation_mask: number;
  score: number;
  depth: number;
  sources: EdgeSourceMarker[];
}

export interface EdgeSourceMarker {
  source_id: number;
  marker: string | null;
}

export interface MappingGraphResponse {
  root_id: number;
  requested_hops: 1 | 2 | 3;
  resolved_hops: 0 | 1 | 2 | 3;
  nodes: MappingGraphNode[];
  edges: MappingGraphEdge[];
  layer_counts: Record<number, number>;
  truncated: boolean;
  omitted_count: number;
}

export interface SplitRow {
  id: number;
  source_expression_id: number;
  target_expression_id: number;
  created_by: number | null;
}

export interface SplitMoveRow {
  split_id: number;
  edge_id: number;
}
