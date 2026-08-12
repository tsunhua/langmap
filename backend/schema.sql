-- ⚠ Local dev only: managed by scripts/db (manage.py local rebuild).
-- Must stay equivalent to backend/migrations/ applied in order (AGENTS.md).

DROP TABLE IF EXISTS expressions_fts;
DROP TABLE IF EXISTS handbook_section_items;
DROP TABLE IF EXISTS handbook_sections;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expression_split_moves;
DROP TABLE IF EXISTS expression_splits;
DROP TABLE IF EXISTS expression_edges;
DROP TABLE IF EXISTS expression_readings;
DROP TABLE IF EXISTS user_preferences;
DROP TABLE IF EXISTS expression_locale_attestations;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS ui_messages;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS language_locations;
DROP TABLE IF EXISTS language_profiles;
DROP TABLE IF EXISTS language_varieties;
DROP TABLE IF EXISTS language_subtags;
DROP TABLE IF EXISTS languoids;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS scripts;
DROP TABLE IF EXISTS languages;
DROP TABLE IF EXISTS language_locales;
DROP TABLE IF EXISTS sources;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

CREATE TABLE languages (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL
);

CREATE TABLE scripts (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE regions (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_scripts_code ON scripts(code);
CREATE INDEX idx_regions_code ON regions(code);

-- Language locale + sources tables (spec §7.2, §7.3).

CREATE TABLE sources (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('publication', 'url', 'system')),
  name TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (type, name),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE language_locales (
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

-- schema.sql runs before scripts/language-reference/artifacts/language-reference.sql,
-- so the locale seeds below need these registry rows present to satisfy their FKs.
-- Values must match the generated artifact so INSERT OR IGNORE keeps final counts intact.

INSERT OR IGNORE INTO languages (code, name_en) VALUES
  ('eng', 'English'),
  ('cmn', 'Mandarin Chinese');

INSERT OR IGNORE INTO scripts (code, name_en, direction) VALUES
  ('Latn', 'Latin', 'ltr'),
  ('Hant', 'Han (Traditional variant)', 'ltr'),
  ('Hans', 'Han (Simplified variant)', 'ltr');

INSERT OR IGNORE INTO regions (code, name_en, latitude, longitude) VALUES
  ('US', 'United States', 39.8, -98.6),
  ('TW', 'Taiwan, Province of China', 23.7, 121.0),
  ('CN', 'China', NULL, NULL);

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('eng-Latn-US', 'eng', 'Latn', 'US', '', 'English (US)', 'English (US)', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hant-TW', 'cmn', 'Hant', 'TW', '', '臺灣華語', 'Taiwan Mandarin', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hans-CN', 'cmn', 'Hans', 'CN', '', '简体中文', 'Simplified Chinese', 'system-seed', 'seed:system-seed:1');

-- Expression identity + locale attestations (spec §8.4, §9.1).

CREATE TABLE expressions (
  id TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  text TEXT NOT NULL,
  text_hash TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  description TEXT NOT NULL DEFAULT '',
  tags_json TEXT NOT NULL DEFAULT '[]',
  source_id TEXT,
  source_ref TEXT,
  review_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending', 'approved', 'rejected')),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (lang_code, text, homograph_index),
  UNIQUE (lang_code, text_hash, homograph_index),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_locale_attestations (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (expression_id, language_locale_code, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Mapping edges + split audit tables (spec §10.1, §10.2).

CREATE TABLE expression_edges (
  id TEXT PRIMARY KEY,
  expression_a_id TEXT NOT NULL,
  expression_b_id TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_splits (
  id TEXT PRIMARY KEY,
  source_expression_id TEXT NOT NULL,
  target_expression_id TEXT NOT NULL,
  created_by INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_split_moves (
  split_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  previous_a_id TEXT NOT NULL,
  previous_b_id TEXT NOT NULL,
  new_a_id TEXT NOT NULL,
  new_b_id TEXT NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id) REFERENCES expression_splits(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-split', 'system', 'LangMap split expressions');

-- Expression readings + user preferences (spec §9.2, §11).

CREATE TABLE expression_readings (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (expression_id, language_locale_code, scheme, value, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE user_preferences (
  user_id INTEGER NOT NULL,
  preference_key TEXT NOT NULL,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, preference_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- UI localization tables (spec §12.1, §12.2).

CREATE TABLE ui_locales (
  project_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  activation_source TEXT
    CHECK (activation_source IN ('system', 'auto', 'manual')),
  activated_at TEXT,
  activated_by INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, language_locale_code),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (activated_by) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE ui_messages (
  project_id TEXT NOT NULL,
  message_key TEXT NOT NULL,
  source_expression_id TEXT NOT NULL,
  source_text TEXT NOT NULL,
  placeholders_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, message_key),
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-ui', 'system', 'LangMap UI source copy');

INSERT OR IGNORE INTO ui_locales (project_id, language_locale_code, status, mapping_revision, activation_source, activated_at)
VALUES ('langmap-web', 'eng-Latn-US', 'active', 0, 'system', CURRENT_TIMESTAMP);
