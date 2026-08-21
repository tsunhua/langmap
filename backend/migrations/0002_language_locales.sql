-- Language locale + sources tables (spec §7.2, §7.3).

INSERT OR IGNORE INTO languages (code, name_en) VALUES
  ('eng', 'English'), ('cmn', 'Mandarin Chinese');
INSERT OR IGNORE INTO scripts (code, name_en, direction) VALUES
  ('Latn', 'Latin', 'ltr'), ('Hans', 'Simplified', 'ltr'), ('Hant', 'Traditional', 'ltr');
INSERT OR IGNORE INTO regions (code, name_en) VALUES
  ('US', 'United States'), ('CN', 'China'), ('TW', 'Taiwan');

CREATE TABLE IF NOT EXISTS sources (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('publication', 'url', 'system')),
  name TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (type, name),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS language_locales (
  code TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  script_code TEXT NOT NULL,
  region_code TEXT NOT NULL,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, script_code, region_code, place_path),
  CHECK ((latitude IS NULL) = (longitude IS NULL)),
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (script_code) REFERENCES scripts(code),
  FOREIGN KEY (region_code) REFERENCES regions(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-seed', 'system', 'LangMap system seeds');

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('eng-Latn-US', 'eng', 'Latn', 'US', '', 'English (US)', 'English (US)', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hant-TW', 'cmn', 'Hant', 'TW', '', '臺灣華語', 'Taiwan Mandarin', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hans-CN', 'cmn', 'Hans', 'CN', '', '简体中文', 'Simplified Chinese', 'system-seed', 'seed:system-seed:1');
