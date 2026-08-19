-- Add orthography field to language_locales table
-- This supports writing systems like POJ (Pe̍h-ōe-jī) and Tailo (Tâi-lô)
-- which are distinct from the base script (Latn)

ALTER TABLE language_locales ADD COLUMN orthography TEXT;

-- Update unique constraint to include orthography
-- SQLite doesn't support dropping constraints, so we need to recreate the table
CREATE TABLE language_locales_new (
  code TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  script_code TEXT NOT NULL,
  orthography TEXT,
  region_code TEXT NOT NULL,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  name_expression_id TEXT REFERENCES expressions(id),
  latitude REAL,
  longitude REAL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, script_code, orthography, region_code, place_path),
  CHECK ((latitude IS NULL) = (longitude IS NULL)),
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (script_code) REFERENCES scripts(code),
  FOREIGN KEY (region_code) REFERENCES regions(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

INSERT INTO language_locales_new SELECT * FROM language_locales;
DROP TABLE language_locales;
ALTER TABLE language_locales_new RENAME TO language_locales;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_language_locales_lang ON language_locales(lang_code);
CREATE INDEX IF NOT EXISTS idx_language_locales_script ON language_locales(script_code);
CREATE INDEX IF NOT EXISTS idx_language_locales_region ON language_locales(region_code);
