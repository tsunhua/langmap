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
