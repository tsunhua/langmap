-- LangMap Migration: Remove obsolete meaning_id column from expressions table
-- Date: 2026-03-13
-- Description: Delete the obsolete meaning_id column from expressions table
--              This field has been replaced by the expression_meaning table
-- 执行：npx wrangler d1 execute langmap --remote --file=../scripts/030_remove_meaning_id.sql --y

--------------------------------------------------------------------------------
-- 1. Drop the obsolete index on meaning_id (if it still exists)
--------------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_expressions_meaning_id;

--------------------------------------------------------------------------------
-- 2. Drop the obsolete meaning_id column from expressions table
--------------------------------------------------------------------------------
-- Note: SQLite doesn't support ALTER TABLE DROP COLUMN directly
-- We need to recreate the table without the column and copy data

-- Step 1: Create a new expressions table without meaning_id
CREATE TABLE IF NOT EXISTS expressions_new (
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

-- Step 2: Copy data from old table to new table (excluding meaning_id)
INSERT INTO expressions_new (
    id, text, audio_url, language_code, region_code, region_name, region_latitude,
    region_longitude, tags, source_type, source_ref, review_status, created_by,
    created_at, updated_by, updated_at
)
SELECT
    id, text, audio_url, language_code, region_code, region_name, region_latitude,
    region_longitude, tags, source_type, source_ref, review_status, created_by,
    created_at, updated_by, updated_at
FROM expressions;

-- Step 3: Drop the old table
DROP TABLE expressions;

-- Step 4: Rename the new table to expressions
ALTER TABLE expressions_new RENAME TO expressions;

-- Step 5: Recreate indexes
CREATE INDEX IF NOT EXISTS idx_expressions_text ON expressions(text);
CREATE INDEX IF NOT EXISTS idx_expressions_language_code ON expressions(language_code);
CREATE INDEX IF NOT EXISTS idx_expressions_tags ON expressions(tags);
CREATE INDEX IF NOT EXISTS idx_expressions_created_by ON expressions(created_by);
