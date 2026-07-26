export interface Bindings {
  DB: D1Database;
  ASSETS: { fetch: typeof fetch };
  SECRET_KEY: string;
}

export interface Variables {
  user?: { id: number; username: string; role: string };
}

export interface MappingGraphNode {
  expression_id: number;
  text: string;
  language_code: string;
  language_name: string | null;
  depth: number;
}

export interface MappingGraphEdge {
  edge_id: string;
  source_id: number;
  target_id: number;
  score: number;
  depth: number;
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
