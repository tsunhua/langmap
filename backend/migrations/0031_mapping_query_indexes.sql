-- Keep graph traversal, feed joins, and localized message candidates index-backed
-- as the expression and edge tables grow.
CREATE INDEX IF NOT EXISTS idx_expression_edges_a_id
  ON expression_edges(expression_a_id);

CREATE INDEX IF NOT EXISTS idx_expression_edges_b_id
  ON expression_edges(expression_b_id);

CREATE INDEX IF NOT EXISTS idx_ui_messages_source_expression
  ON ui_messages(project_id, status, source_expression_id);
