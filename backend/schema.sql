-- ⚠ Local dev only: managed by scripts/db (manage.py local rebuild).
-- Must stay equivalent to backend/migrations/ applied in order (AGENTS.md).

DROP TABLE IF EXISTS expressions_fts;
DROP TABLE IF EXISTS handbook_section_items;
DROP TABLE IF EXISTS handbook_sections;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expression_edges;
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
