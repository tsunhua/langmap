-- LangMap v2 schema — pairwise expression edges replacing meaning groups
-- Usage: wrangler d1 execute langmap-v2 --local --file=./schema.sql
--
-- ⚠ Local dev only: this file DROPs existing tables.

--------------------------------------------------------------------------------
-- 0. Cleanup (order: triggers → FTS → child → parent)
--------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS expressions_ai;
DROP TRIGGER IF EXISTS expressions_ad;
DROP TRIGGER IF EXISTS expressions_au;
DROP TABLE IF EXISTS expressions_fts;
DROP TABLE IF EXISTS handbook_section_items;
DROP TABLE IF EXISTS handbook_sections;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS expression_edges;
DROP TABLE IF EXISTS handbook_pages;
DROP TABLE IF EXISTS collection_items;
DROP TABLE IF EXISTS collections;
DROP TABLE IF EXISTS expression_meaning;
DROP TABLE IF EXISTS meanings;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS ui_messages;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS language_locations;
DROP TABLE IF EXISTS language_profiles;
DROP TABLE IF EXISTS language_varieties;
DROP TABLE IF EXISTS language_subtags;
DROP TABLE IF EXISTS languoids;

--------------------------------------------------------------------------------
-- 1. Core tables
--------------------------------------------------------------------------------

CREATE TABLE languoids (
    id TEXT PRIMARY KEY NOT NULL,
    glottocode TEXT UNIQUE NOT NULL,
    preferred_name TEXT NOT NULL,
    level TEXT NOT NULL CHECK (level IN ('family', 'language', 'dialect')),
    iso639_3 TEXT,
    parent_id TEXT,
    latitude REAL,
    longitude REAL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'retired')),
    source_version TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES languoids(id)
);
CREATE INDEX idx_languoids_glottocode ON languoids(glottocode);
CREATE INDEX idx_languoids_iso639_3 ON languoids(iso639_3);

CREATE TABLE language_subtags (
    type TEXT NOT NULL,
    value TEXT NOT NULL,
    descriptions TEXT NOT NULL DEFAULT '[]',
    prefixes TEXT NOT NULL DEFAULT '[]',
    preferred_value TEXT,
    suppress_script TEXT,
    deprecated TEXT,
    PRIMARY KEY (type, value)
);
CREATE INDEX idx_language_subtags_search
  ON language_subtags(type, value);

CREATE TABLE language_varieties (
    id TEXT PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    description TEXT NOT NULL DEFAULT '',
    glottocode TEXT,
    origin TEXT NOT NULL
      CHECK (origin IN ('seed', 'glottolog', 'community', 'system')),
    community_reason TEXT,
    alternate_names_json TEXT NOT NULL DEFAULT '[]',
    references_json TEXT NOT NULL DEFAULT '[]',
    parent_languoid_id TEXT,
    created_by TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (glottocode) REFERENCES languoids(glottocode),
    FOREIGN KEY (parent_languoid_id) REFERENCES languoids(id)
);
CREATE INDEX idx_language_varieties_name ON language_varieties(name);
CREATE INDEX idx_language_varieties_glottocode ON language_varieties(glottocode);

CREATE TABLE language_profiles (
    code TEXT PRIMARY KEY NOT NULL,
    language_variety_id TEXT NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    endonym TEXT NOT NULL DEFAULT '',
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl')),
    base_language TEXT NOT NULL,
    script_code TEXT,
    region_code TEXT,
    variants_json TEXT NOT NULL DEFAULT '[]',
    private_use_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)
);
CREATE INDEX idx_language_profiles_variety
  ON language_profiles(language_variety_id);
CREATE INDEX idx_language_profiles_base_script_region
  ON language_profiles(base_language, script_code, region_code);

CREATE TABLE language_locations (
    language_variety_id TEXT NOT NULL,
    city_name TEXT NOT NULL,
    city_name_en TEXT,
    city_name_localized TEXT NOT NULL DEFAULT '{}',
    territory_code TEXT NOT NULL,
    script_code TEXT NOT NULL DEFAULT '',
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    reference TEXT NOT NULL,
    PRIMARY KEY (language_variety_id, city_name, territory_code, script_code),
    FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)
);
CREATE INDEX idx_language_locations_variety
  ON language_locations(language_variety_id);
CREATE INDEX idx_language_locations_city
  ON language_locations(city_name, territory_code);

CREATE TABLE expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    language_profile_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    tags TEXT,
    source_type TEXT DEFAULT 'user',
    source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    variation_status TEXT NOT NULL DEFAULT 'unclassified'
      CHECK (variation_status IN ('unclassified', 'shared', 'variant')),
    meaning_id INTEGER,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    desc TEXT DEFAULT NULL,
    FOREIGN KEY (language_profile_code) REFERENCES language_profiles(code)
);
CREATE INDEX idx_expressions_text ON expressions(text);
CREATE INDEX idx_expressions_language_profile ON expressions(language_profile_code);
CREATE INDEX idx_expressions_tags ON expressions(tags);
CREATE INDEX idx_expressions_created_by ON expressions(created_by);
CREATE INDEX idx_expressions_lang_text ON expressions(language_profile_code, text);
CREATE INDEX idx_expressions_meaning_id ON expressions(meaning_id);

CREATE TABLE expression_versions (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    region_name TEXT,
    region_latitude TEXT,
    region_longitude TEXT,
    meaning_id INTEGER,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    desc TEXT DEFAULT NULL
);
CREATE INDEX idx_expression_versions_expression_id ON expression_versions(expression_id);
CREATE INDEX idx_expr_versions_id_created ON expression_versions(expression_id, created_at DESC);
CREATE INDEX idx_expression_versions_meaning_id ON expression_versions(meaning_id);

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

CREATE TABLE email_verification_tokens (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_tokens_expires_at ON email_verification_tokens(expires_at);

--------------------------------------------------------------------------------
-- 2. New: pairwise expression edges
--------------------------------------------------------------------------------

CREATE TABLE expression_edges (
    id TEXT PRIMARY KEY,
    expression_a_id INTEGER NOT NULL,
    expression_b_id INTEGER NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'batch',
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(expression_a_id, expression_b_id),
    FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
    FOREIGN KEY (expression_b_id) REFERENCES expressions(id)
);
CREATE INDEX idx_expression_edges_a_id ON expression_edges(expression_a_id);
CREATE INDEX idx_expression_edges_b_id ON expression_edges(expression_b_id);
CREATE INDEX idx_expression_edges_score ON expression_edges(score DESC);

--------------------------------------------------------------------------------
-- 3. New: unified voting
--------------------------------------------------------------------------------

CREATE TABLE votes (
    id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    vote INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, target_type, target_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_votes_target ON votes(target_type, target_id);
CREATE INDEX idx_votes_user ON votes(user_id);

--------------------------------------------------------------------------------
-- 4. New: handbooks (simplified, no markdown prose)
--------------------------------------------------------------------------------

CREATE TABLE handbooks (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    visibility TEXT NOT NULL DEFAULT 'public',
    status TEXT NOT NULL DEFAULT 'published',
    score INTEGER NOT NULL DEFAULT 0,
    created_at TEXT,
    updated_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_handbooks_visibility_created ON handbooks(visibility, created_at DESC);
CREATE INDEX idx_handbooks_score ON handbooks(score DESC);
CREATE INDEX idx_handbooks_user ON handbooks(user_id);

CREATE TABLE handbook_sections (
    id INTEGER PRIMARY KEY,
    handbook_id INTEGER NOT NULL,
    title TEXT,
    position INTEGER NOT NULL,
    created_at TEXT,
    FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE
);
CREATE INDEX idx_handbook_sections_handbook ON handbook_sections(handbook_id, position);

CREATE TABLE handbook_section_items (
    id INTEGER PRIMARY KEY,
    section_id INTEGER NOT NULL,
    expression_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    created_at TEXT,
    UNIQUE(section_id, expression_id),
    FOREIGN KEY (section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE,
    FOREIGN KEY (expression_id) REFERENCES expressions(id)
);
CREATE INDEX idx_handbook_section_items_section ON handbook_section_items(section_id, position);

--------------------------------------------------------------------------------
-- 5. UI locales
--------------------------------------------------------------------------------

CREATE TABLE ui_locales (
    project_id TEXT NOT NULL,
    code TEXT NOT NULL,
    native_name TEXT NOT NULL,
    direction TEXT NOT NULL DEFAULT 'ltr' CHECK (direction IN ('ltr', 'rtl')),
    fallback_code TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'draft', 'archived')),
    mapping_revision INTEGER NOT NULL DEFAULT 0,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    ,PRIMARY KEY (project_id, code)
    ,FOREIGN KEY (code) REFERENCES language_profiles(code)
    ,FOREIGN KEY (project_id, fallback_code) REFERENCES ui_locales(project_id, code)
);
CREATE INDEX idx_ui_locales_code ON ui_locales(code);

CREATE TABLE ui_messages (
    project_id TEXT NOT NULL,
    key TEXT NOT NULL,
    description TEXT,
    scope TEXT NOT NULL DEFAULT 'global',
    message_format TEXT NOT NULL DEFAULT 'text',
    source_expression_id INTEGER NOT NULL,
    placeholders_json TEXT,
    source_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'retired')),
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, key),
    FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);
CREATE INDEX idx_ui_messages_source ON ui_messages(project_id, source_expression_id);

--------------------------------------------------------------------------------
-- 6. FTS5 on expressions
--------------------------------------------------------------------------------

CREATE VIRTUAL TABLE expressions_fts USING fts5(
    text,
    content='expressions',
    content_rowid='id',
    tokenize='unicode61'
);

CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
END;

CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;
