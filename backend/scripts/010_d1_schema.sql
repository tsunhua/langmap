-- Cloudflare D1 Schema for LangMap Application
-- This SQL script creates all necessary tables for the LangMap application

-- Languages table
CREATE TABLE IF NOT EXISTS languages (
    id INTEGER PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    created_by INTEGER,
    created_at TEXT DEFAULT (datetime('now')),
    updated_by INTEGER,
    updated_at TEXT DEFAULT (datetime('now'))
);

-- Meanings table
CREATE TABLE IF NOT EXISTS meanings (
    id INTEGER PRIMARY KEY,
    gloss TEXT UNIQUE,
    description TEXT,
    tags TEXT,
    created_by INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Expressions table
CREATE TABLE IF NOT EXISTS expressions (
    id INTEGER PRIMARY KEY,
    text TEXT NOT NULL,
    language_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    meaning_id INTEGER,
    tags TEXT,
    source_type TEXT DEFAULT 'user',
    review_status TEXT DEFAULT 'pending',
    auto_approved INTEGER DEFAULT 0,
    created_by INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Expression versions table
CREATE TABLE IF NOT EXISTS expression_versions (
    id INTEGER PRIMARY KEY,
    expression_id INTEGER,
    language TEXT NOT NULL,
    region_name TEXT,
    region_latitude TEXT,
    region_longitude TEXT,
    country_code TEXT,
    country_name TEXT,
    text TEXT NOT NULL,
    source_type TEXT DEFAULT 'user',
    created_by INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    review_status TEXT DEFAULT 'pending',
    auto_approved INTEGER DEFAULT 0
);

-- Expression-Meaning relationships table
CREATE TABLE IF NOT EXISTS expression_meanings (
    id INTEGER PRIMARY KEY,
    expression_id INTEGER NOT NULL,
    meaning_id INTEGER NOT NULL,
    note TEXT,
    parent_version_id INTEGER,
    created_by INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_languages_code ON languages(code);
CREATE INDEX IF NOT EXISTS idx_languages_name ON languages(name);
CREATE INDEX IF NOT EXISTS idx_meanings_gloss ON meanings(gloss);
CREATE INDEX IF NOT EXISTS idx_expressions_text ON expressions(text);
CREATE INDEX IF NOT EXISTS idx_expressions_language_code ON expressions(language_code);
CREATE INDEX IF NOT EXISTS idx_expressions_created_at ON expressions(created_at);
CREATE INDEX IF NOT EXISTS idx_expression_versions_expression_id ON expression_versions(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meanings_expression_id ON expression_meanings(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meanings_meaning_id ON expression_meanings(meaning_id);
