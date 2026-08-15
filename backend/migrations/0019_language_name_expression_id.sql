-- Bind each language and language locale to the canonical expression that
-- carries its primary name, enabling locale-scoped name resolution.
-- (spec: 2026-08-15-localized-language-names-design.md)
-- Nullable: rows without a canonical expression fall back to name_en /
-- self-name / code. Canonical expressions themselves arrive with the seed
-- data (second plan) via scripts/language-reference + scripts/db.
ALTER TABLE languages ADD COLUMN name_expression_id TEXT REFERENCES expressions(id);
ALTER TABLE language_locales ADD COLUMN name_expression_id TEXT REFERENCES expressions(id);
