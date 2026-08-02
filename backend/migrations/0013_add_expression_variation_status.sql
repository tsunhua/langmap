ALTER TABLE expressions
ADD COLUMN variation_status TEXT NOT NULL DEFAULT 'unclassified'
  CHECK (variation_status IN ('unclassified', 'shared', 'variant'));
