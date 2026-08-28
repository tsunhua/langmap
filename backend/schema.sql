-- Canonical greenfield schema for local D1 rebuilds.
-- The 0039 migration is intentionally destructive and has the same contract.
PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS all_expression_readings;
DROP VIEW IF EXISTS all_expression_edges;
DROP VIEW IF EXISTS all_expression_rows;
DROP TABLE IF EXISTS expression_form_edge_features;
DROP TABLE IF EXISTS expression_form_edges;
DROP TABLE IF EXISTS morphological_features;
DROP TABLE IF EXISTS morphological_dimensions;
DROP TABLE IF EXISTS expression_split_moves;
DROP TABLE IF EXISTS expression_splits;
DROP TABLE IF EXISTS handbook_section_items;
DROP TABLE IF EXISTS handbook_sections;
DROP TABLE IF EXISTS handbook_votes;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS edge_votes;
DROP TABLE IF EXISTS ui_messages;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS user_preferences;
DROP TABLE IF EXISTS expression_readings;
DROP TABLE IF EXISTS expression_locale_links;
DROP TABLE IF EXISTS expression_edges;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS sources;
DROP TABLE IF EXISTS language_locales;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS scripts;
DROP TABLE IF EXISTS languages;
DROP TABLE IF EXISTS parts_of_speech;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  email_verified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE languages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  name_en TEXT NOT NULL,
  name_expression_id INTEGER REFERENCES expressions(id)
);

CREATE TABLE language_statistics (
  language_id INTEGER PRIMARY KEY,
  expression_count INTEGER NOT NULL DEFAULT 0,
  locale_count INTEGER NOT NULL DEFAULT 0,
  active_ui_locale_count INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
);

CREATE TABLE scripts (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl')),
  name_expression_id INTEGER REFERENCES expressions(id)
);

CREATE TABLE regions (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_expression_id INTEGER REFERENCES expressions(id),
  latitude REAL,
  longitude REAL,
  CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE TABLE language_locales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  language_id INTEGER NOT NULL,
  script_code TEXT,
  orthography TEXT,
  region_code TEXT,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  name_expression_id INTEGER REFERENCES expressions(id),
  latitude REAL,
  longitude REAL,
  CHECK ((latitude IS NULL) = (longitude IS NULL)),
  FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE RESTRICT,
  FOREIGN KEY (script_code) REFERENCES scripts(code) ON DELETE RESTRICT,
  FOREIGN KEY (region_code) REFERENCES regions(code) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_language_locales_identity
  ON language_locales(language_id, COALESCE(script_code, ''), COALESCE(orthography, ''), COALESCE(region_code, ''), place_path);

CREATE TABLE sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  UNIQUE (type, name)
);

CREATE TABLE parts_of_speech (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  sort_order INTEGER NOT NULL UNIQUE,
  bit_index INTEGER NOT NULL UNIQUE CHECK (bit_index BETWEEN 0 AND 62)
);

CREATE TABLE expressions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  language_id INTEGER NOT NULL,
  text TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  pos_mask INTEGER NOT NULL DEFAULT 0 CHECK (pos_mask >= 0),
  source_id INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (language_id, text, homograph_index),
  FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE RESTRICT,
  FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX idx_expressions_language_created ON expressions(language_id, created_at DESC);

CREATE TABLE expression_locale_links (
  expression_id INTEGER NOT NULL,
  locale_id INTEGER NOT NULL,
  PRIMARY KEY (expression_id, locale_id),
  FOREIGN KEY (expression_id) REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (locale_id) REFERENCES language_locales(id) ON DELETE RESTRICT
) WITHOUT ROWID;
CREATE INDEX idx_expression_locale_links_locale ON expression_locale_links(locale_id, expression_id);

CREATE TABLE expression_readings (
  expression_id INTEGER NOT NULL,
  locale_id INTEGER NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id INTEGER,
  PRIMARY KEY (expression_id, locale_id, scheme, value),
  FOREIGN KEY (expression_id) REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (locale_id) REFERENCES language_locales(id) ON DELETE RESTRICT,
  FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL
) WITHOUT ROWID;

CREATE TABLE expression_edges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  expression_a_id INTEGER NOT NULL,
  expression_b_id INTEGER NOT NULL,
  relation_mask INTEGER NOT NULL DEFAULT 1 CHECK (relation_mask BETWEEN 1 AND 7),
  score INTEGER NOT NULL DEFAULT 0,
  created_by INTEGER,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX idx_expression_edges_b_id ON expression_edges(expression_b_id);

CREATE TABLE edge_votes (
  user_id INTEGER NOT NULL,
  edge_id INTEGER NOT NULL,
  vote INTEGER NOT NULL CHECK (vote IN (-1, 1)),
  PRIMARY KEY (user_id, edge_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id) ON DELETE CASCADE
) WITHOUT ROWID;
CREATE INDEX idx_edge_votes_edge ON edge_votes(edge_id);

CREATE TABLE handbooks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'private')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  language_locale_id INTEGER,
  score INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (language_locale_id) REFERENCES language_locales(id) ON DELETE SET NULL
);
CREATE INDEX idx_handbooks_visibility_created ON handbooks(visibility, created_at DESC, id ASC);
CREATE INDEX idx_handbooks_visibility_score ON handbooks(visibility, score DESC, created_at DESC, id ASC);

CREATE TABLE handbook_votes (
  user_id INTEGER NOT NULL,
  handbook_id INTEGER NOT NULL,
  vote INTEGER NOT NULL CHECK (vote IN (-1, 1)),
  PRIMARY KEY (user_id, handbook_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE
) WITHOUT ROWID;
CREATE INDEX idx_handbook_votes_handbook ON handbook_votes(handbook_id);

CREATE TABLE handbook_sections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  handbook_id INTEGER NOT NULL,
  title TEXT,
  position INTEGER NOT NULL,
  parent_section_id INTEGER,
  UNIQUE (handbook_id, position),
  FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE
);
CREATE INDEX idx_handbook_sections_parent ON handbook_sections(handbook_id, parent_section_id, position, id);

CREATE TABLE handbook_section_items (
  section_id INTEGER NOT NULL,
  position INTEGER NOT NULL,
  expression_id INTEGER NOT NULL,
  PRIMARY KEY (section_id, position),
  UNIQUE (section_id, expression_id),
  FOREIGN KEY (section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE,
  FOREIGN KEY (expression_id) REFERENCES expressions(id) ON DELETE RESTRICT
) WITHOUT ROWID;

CREATE TABLE morphological_dimensions (
  code TEXT PRIMARY KEY,
  name_expression_id INTEGER NOT NULL,
  sort_order INTEGER NOT NULL UNIQUE,
  FOREIGN KEY (name_expression_id) REFERENCES expressions(id) ON DELETE RESTRICT
);
CREATE TABLE morphological_features (
  code TEXT PRIMARY KEY,
  dimension_code TEXT NOT NULL,
  name_expression_id INTEGER NOT NULL,
  sort_order INTEGER NOT NULL,
  UNIQUE (dimension_code, sort_order),
  FOREIGN KEY (dimension_code) REFERENCES morphological_dimensions(code) ON DELETE CASCADE,
  FOREIGN KEY (name_expression_id) REFERENCES expressions(id) ON DELETE RESTRICT
);

CREATE TABLE expression_form_edges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  form_id INTEGER NOT NULL,
  lemma_id INTEGER NOT NULL,
  created_by INTEGER,
  CHECK (form_id <> lemma_id),
  UNIQUE (form_id, lemma_id),
  FOREIGN KEY (form_id) REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (lemma_id) REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX idx_expression_form_edges_lemma_id ON expression_form_edges(lemma_id);
CREATE TRIGGER trg_expression_form_edges_no_reverse
BEFORE INSERT ON expression_form_edges
WHEN EXISTS (SELECT 1 FROM expression_form_edges WHERE form_id = NEW.lemma_id AND lemma_id = NEW.form_id)
BEGIN
  SELECT RAISE(ABORT, 'reverse expression form edge exists');
END;

CREATE TABLE expression_form_edge_features (
  edge_id INTEGER NOT NULL,
  feature_code TEXT NOT NULL,
  PRIMARY KEY (edge_id, feature_code),
  FOREIGN KEY (edge_id) REFERENCES expression_form_edges(id) ON DELETE CASCADE,
  FOREIGN KEY (feature_code) REFERENCES morphological_features(code) ON DELETE RESTRICT
) WITHOUT ROWID;

CREATE TABLE expression_splits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_expression_id INTEGER NOT NULL,
  target_expression_id INTEGER NOT NULL,
  created_by INTEGER,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id) ON DELETE RESTRICT,
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id) ON DELETE RESTRICT,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE expression_split_moves (
  split_id INTEGER NOT NULL,
  edge_id INTEGER NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id) REFERENCES expression_splits(id) ON DELETE CASCADE,
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id) ON DELETE RESTRICT
) WITHOUT ROWID;

CREATE TABLE ui_locales (
  project_id TEXT NOT NULL,
  locale_id INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  activation_source TEXT CHECK (activation_source IN ('system', 'auto', 'manual')),
  activated_at TEXT,
  activated_by INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, locale_id),
  FOREIGN KEY (locale_id) REFERENCES language_locales(id) ON DELETE RESTRICT,
  FOREIGN KEY (activated_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) WITHOUT ROWID;

CREATE TABLE ui_messages (
  project_id TEXT NOT NULL,
  message_key TEXT NOT NULL,
  source_expression_id INTEGER NOT NULL,
  source_text TEXT NOT NULL,
  placeholders_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'archived')),
  PRIMARY KEY (project_id, message_key),
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id) ON DELETE RESTRICT
) WITHOUT ROWID;
CREATE INDEX idx_ui_messages_source_expression ON ui_messages(project_id, status, source_expression_id);

CREATE TABLE user_preferences (
  user_id INTEGER NOT NULL,
  preference_key TEXT NOT NULL,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, preference_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) WITHOUT ROWID;

INSERT OR IGNORE INTO parts_of_speech(code, name_en, sort_order, bit_index) VALUES
  ('noun', 'Noun', 1, 0),
  ('proper-noun', 'Proper noun', 2, 1),
  ('verb', 'Verb', 3, 2),
  ('auxiliary', 'Auxiliary verb', 4, 3),
  ('adjective', 'Adjective', 5, 4),
  ('adverb', 'Adverb', 6, 5),
  ('pronoun', 'Pronoun', 7, 6),
  ('determiner', 'Determiner', 8, 7),
  ('numeral', 'Numeral', 9, 8),
  ('adposition', 'Adposition', 10, 9),
  ('conjunction', 'Conjunction', 11, 10),
  ('particle', 'Particle', 12, 11),
  ('interjection', 'Interjection', 13, 12),
  ('abbreviation', 'Abbreviation', 14, 13),
  ('phrase', 'Phrase', 15, 14);
