-- Cloudflare D1 Schema for LangMap Application
-- This SQL script creates all necessary tables for the LangMap application

-- Languages table
CREATE TABLE IF NOT EXISTS languages (
    id INTEGER PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    direction TEXT DEFAULT 'ltr',
    is_active INTEGER DEFAULT 0,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Meanings table
CREATE TABLE IF NOT EXISTS meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    gloss TEXT UNIQUE NOT NULL,
    description TEXT,
    tags TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Expressions table
CREATE TABLE IF NOT EXISTS expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL NOT NULL,
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
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Expression versions table
CREATE TABLE IF NOT EXISTS expression_versions (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    region_name TEXT,
    region_latitude TEXT,
    region_longitude TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Expression-Meaning relationships table
CREATE TABLE IF NOT EXISTS expression_meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    meaning_id INTEGER NOT NULL,
    note TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_languages_code ON languages(code);
CREATE INDEX IF NOT EXISTS idx_languages_name ON languages(name);
CREATE INDEX IF NOT EXISTS idx_languages_is_active ON languages(is_active);
CREATE INDEX IF NOT EXISTS idx_meanings_gloss ON meanings(gloss);
CREATE INDEX IF NOT EXISTS idx_expressions_text ON expressions(text);
CREATE INDEX IF NOT EXISTS idx_expressions_language_code ON expressions(language_code);
CREATE INDEX IF NOT EXISTS idx_expression_versions_expression_id ON expression_versions(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meanings_expression_id ON expression_meanings(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meanings_meaning_id ON expression_meanings(meaning_id);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user', -- 'super_admin', 'admin', 'user'
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
