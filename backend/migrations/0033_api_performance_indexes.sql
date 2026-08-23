-- Keep high-volume feed and user activity queries index-backed.
CREATE INDEX IF NOT EXISTS idx_expression_edges_score_feed
  ON expression_edges(score DESC, created_at DESC, id ASC);

CREATE INDEX IF NOT EXISTS idx_expressions_created_by_at
  ON expressions(created_by, created_at DESC, id ASC);

CREATE INDEX IF NOT EXISTS idx_expression_edges_created_by_at
  ON expression_edges(created_by, created_at DESC, id ASC);

CREATE INDEX IF NOT EXISTS idx_handbooks_user_created_at
  ON handbooks(user_id, created_at DESC, id ASC);

CREATE INDEX IF NOT EXISTS idx_votes_user_created_at
  ON votes(user_id, created_at DESC, target_id);
