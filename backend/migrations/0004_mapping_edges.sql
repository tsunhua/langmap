-- Mapping edges + split audit tables (spec §10.1, §10.2).

CREATE TABLE IF NOT EXISTS expression_edges (
  id TEXT PRIMARY KEY,
  expression_a_id TEXT NOT NULL,
  expression_b_id TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS expression_splits (
  id TEXT PRIMARY KEY,
  source_expression_id TEXT NOT NULL,
  target_expression_id TEXT NOT NULL,
  created_by INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS expression_split_moves (
  split_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  previous_a_id TEXT NOT NULL,
  previous_b_id TEXT NOT NULL,
  new_a_id TEXT NOT NULL,
  new_b_id TEXT NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id) REFERENCES expression_splits(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-split', 'system', 'LangMap split expressions');
