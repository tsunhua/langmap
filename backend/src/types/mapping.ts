export interface EdgeRow {
  id: string;
  expression_a_id: string;
  expression_b_id: string;
  score: number;
  source: string;
  created_by: number | null;
  created_at: string;
}

export interface EdgeWithNeighborRow {
  edge_id: string;
  neighbor_id: string;
  neighbor_lang_code: string;
  neighbor_text: string;
  score: number;
  source: string;
  created_at: string;
}

export interface MappingGraphNode {
  expression_id: string;
  text: string;
  lang_code: string;
  language_profile_code: string | null;
  language_name: string;
  depth: number;
}

export interface MappingGraphEdge {
  edge_id: string;
  source_id: string;
  target_id: string;
  score: number;
  depth: number;
}

export interface MappingGraphResponse {
  root_id: string;
  requested_hops: 1 | 2 | 3;
  resolved_hops: 0 | 1 | 2 | 3;
  nodes: MappingGraphNode[];
  edges: MappingGraphEdge[];
  layer_counts: Record<number, number>;
  truncated: boolean;
  omitted_count: number;
}

export interface SplitRow {
  id: string;
  source_expression_id: string;
  target_expression_id: string;
  created_by: number;
  created_at: string;
}

export interface SplitMoveRow {
  split_id: string;
  edge_id: string;
  previous_a_id: string;
  previous_b_id: string;
  new_a_id: string;
  new_b_id: string;
}
