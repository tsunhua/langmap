-- Greenfield baseline for the ISO 639-3 language code redesign (spec §6, §16).
-- Replaces all former language-profile era migrations.

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Reference registries (spec §6.1). Read-only at runtime (spec §6.2).

CREATE TABLE IF NOT EXISTS languages (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS scripts (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE IF NOT EXISTS regions (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE INDEX IF NOT EXISTS idx_languages_code ON languages(code);
CREATE INDEX IF NOT EXISTS idx_scripts_code ON scripts(code);
CREATE INDEX IF NOT EXISTS idx_regions_code ON regions(code);
