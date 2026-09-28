CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_expressions_text_trgm
  ON expressions USING GIN (text gin_trgm_ops);
