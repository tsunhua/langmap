ALTER TABLE expression_sources
  ADD COLUMN IF NOT EXISTS pos_mask BIGINT NOT NULL DEFAULT 0;

ALTER TABLE expression_sources
  DROP CONSTRAINT IF EXISTS expression_sources_pos_mask_check;

ALTER TABLE expression_sources
  ADD CONSTRAINT expression_sources_pos_mask_check CHECK (pos_mask >= 0);
