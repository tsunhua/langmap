ALTER TABLE handbooks ADD COLUMN managed_key TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_handbooks_managed_key
  ON handbooks(managed_key) WHERE managed_key IS NOT NULL;
