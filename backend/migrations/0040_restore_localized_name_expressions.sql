-- Restore the expression/edge-backed localized-name model after the compact
-- integer storage cutover.  Bindings are nullable until the registry seed is
-- applied, so existing rows retain their English/self-name fallback.
ALTER TABLE languages ADD COLUMN name_expression_id INTEGER REFERENCES expressions(id);
ALTER TABLE language_locales ADD COLUMN name_expression_id INTEGER REFERENCES expressions(id);
ALTER TABLE scripts ADD COLUMN name_expression_id INTEGER REFERENCES expressions(id);
ALTER TABLE regions ADD COLUMN name_expression_id INTEGER REFERENCES expressions(id);
