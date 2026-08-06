-- 0020: Add localized city names to language_locations.
-- The local-language name of a representative city can differ by script
-- (e.g. cmn-Hans vs cmn-Hant), so variants are stored as a JSON object keyed
-- by content profile code, e.g. {"cmn-Hans": "北京", "cmn-Hant": "北京"}.
-- Forward-only: applied once, tracked by the d1_migrations table.
ALTER TABLE language_locations ADD COLUMN city_name_localized TEXT NOT NULL DEFAULT '{}';
