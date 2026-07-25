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
DROP TABLE IF EXISTS language_stats;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS languages;

--------------------------------------------------------------------------------
-- 1. Core tables
--------------------------------------------------------------------------------

CREATE TABLE languages (
    id INTEGER PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT DEFAULT NULL,
    direction TEXT DEFAULT 'ltr',
    is_active INTEGER DEFAULT 0,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    group_name TEXT,
    family TEXT DEFAULT NULL,
    status_text TEXT DEFAULT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_languages_name ON languages(name);
CREATE INDEX idx_languages_is_active ON languages(is_active);
CREATE INDEX idx_languages_active_name ON languages(is_active, name);

CREATE TABLE expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    language_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    tags TEXT,
    source_type TEXT DEFAULT 'user',
    source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    meaning_id INTEGER,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    desc TEXT DEFAULT NULL
);
CREATE INDEX idx_expressions_text ON expressions(text);
CREATE INDEX idx_expressions_language_code ON expressions(language_code);
CREATE INDEX idx_expressions_tags ON expressions(tags);
CREATE INDEX idx_expressions_created_by ON expressions(created_by);
CREATE INDEX idx_expressions_lang_text ON expressions(language_code, text);
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

CREATE TABLE language_stats (
    language_code TEXT PRIMARY KEY,
    expression_count INTEGER DEFAULT 0
);

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
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    language_code TEXT UNIQUE NOT NULL,
    locale_json TEXT NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ui_locales_language_code ON ui_locales(language_code);

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
