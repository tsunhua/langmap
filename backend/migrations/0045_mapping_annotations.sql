ALTER TABLE expression_edges
  ADD COLUMN annotations_json TEXT NOT NULL DEFAULT '[]';
