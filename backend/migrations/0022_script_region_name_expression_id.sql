-- Bind scripts and regions to the canonical expression that carries their
-- primary name, enabling locale-scoped name resolution in the language
-- registry API (spec: 2026-08-15-localized-language-names-design.md).
-- Canonical expressions arrive with the seed data via scripts/language-reference.
ALTER TABLE scripts ADD COLUMN name_expression_id TEXT REFERENCES expressions(id);
ALTER TABLE regions ADD COLUMN name_expression_id TEXT REFERENCES expressions(id);
