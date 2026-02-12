-- LangMap De-normalization & Materialized Stats
-- Date: 2026-02-12
-- Goal: Eliminate COUNT(*) subqueries and heavy aggregations

--------------------------------------------------------------------------------
-- 1. Collections Table De-normalization
--------------------------------------------------------------------------------
-- Add items_count column
ALTER TABLE collections ADD COLUMN items_count INTEGER DEFAULT 0;

-- Initialize items_count for existing collections
UPDATE collections SET items_count = (
  SELECT COUNT(*) 
  FROM collection_items ci 
  WHERE ci.collection_id = collections.id
);

--------------------------------------------------------------------------------
-- 2. Materialized Statistics Table
--------------------------------------------------------------------------------
-- Create language_stats table
CREATE TABLE IF NOT EXISTS language_stats (
  language_code TEXT PRIMARY KEY,
  expression_count INTEGER DEFAULT 0
);

-- Initialize language_stats with current counts
INSERT OR REPLACE INTO language_stats (language_code, expression_count)
SELECT language_code, COUNT(*)
FROM expressions
GROUP BY language_code;
