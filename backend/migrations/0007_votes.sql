-- Vote records referencing mapping edges by ID (spec 10.1).

CREATE TABLE IF NOT EXISTS votes (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  vote INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (target_type IN ('edge')),
  CHECK (vote IN (-1, 1)),
  UNIQUE (user_id, target_type, target_id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_votes_target ON votes (target_type, target_id);
