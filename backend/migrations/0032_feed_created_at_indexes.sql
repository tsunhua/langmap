-- Keep each branch of the latest feed index-backed before the final merge.
CREATE INDEX IF NOT EXISTS idx_expressions_created_at
  ON expressions(created_at DESC, id ASC);

CREATE INDEX IF NOT EXISTS idx_expression_edges_created_at
  ON expression_edges(created_at DESC, id ASC);
