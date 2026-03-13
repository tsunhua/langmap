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
    group_name TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_languages_code ON languages(code);
CREATE INDEX IF NOT EXISTS idx_languages_name ON languages(name);
CREATE INDEX IF NOT EXISTS idx_languages_is_active ON languages(is_active);

-- Expressions table
CREATE TABLE IF NOT EXISTS expressions (
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
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_expressions_text ON expressions(text);
CREATE INDEX IF NOT EXISTS idx_expressions_language_code ON expressions(language_code);
CREATE INDEX IF NOT EXISTS idx_expressions_tags ON expressions(tags);
CREATE INDEX IF NOT EXISTS idx_expressions_created_by ON expressions(created_by);

-- Meanings table
CREATE TABLE IF NOT EXISTS meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Expression-Meaning mapping table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS expression_meaning (
    id TEXT PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    meaning_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (meaning_id) REFERENCES meanings(id)
);

CREATE INDEX IF NOT EXISTS idx_expression_meaning_expression_id ON expression_meaning(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meaning_meaning_id ON expression_meaning(meaning_id);

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

CREATE INDEX IF NOT EXISTS idx_expression_versions_expression_id ON expression_versions(expression_id);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user', -- 'super_admin', 'admin', 'user'
    email_verified INTEGER NOT NULL DEFAULT 0, -- 邮箱验证状态
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Email verification tokens table
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_expires_at ON email_verification_tokens(expires_at);
