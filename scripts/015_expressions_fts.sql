-- LangMap FTS5 Full-Text Search Implementation
-- Date: 2026-02-12
-- Goal: Drastically reduce Rows Read for fuzzy search and enable prefix matching

--------------------------------------------------------------------------------
-- 1. Create FTS5 Virtual Table (External Content Mode)
--------------------------------------------------------------------------------
-- This table points to the 'expressions' table for its content to save space
CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(
    text,
    content='expressions',
    content_rowid='id',
    tokenize='unicode61'
);

--------------------------------------------------------------------------------
-- 2. Initial Data Population
--------------------------------------------------------------------------------
INSERT INTO expressions_fts(rowid, text)
SELECT id, text FROM expressions;

--------------------------------------------------------------------------------
-- 3. Maintenance Triggers
--------------------------------------------------------------------------------
-- Keep the FTS index in sync with the primary expressions table

-- Sync on INSERT
DROP TRIGGER IF EXISTS expressions_ai;
CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN
  INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

-- Sync on DELETE
DROP TRIGGER IF EXISTS expressions_ad;
CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN
  INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES('delete', old.id, old.text);
END;

-- Sync on UPDATE
DROP TRIGGER IF EXISTS expressions_au;
CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN
  INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES('delete', old.id, old.text);
  INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

--------------------------------------------------------------------------------
-- 4. Optimization: Rebuild FTS Index
--------------------------------------------------------------------------------
INSERT INTO expressions_fts(expressions_fts) VALUES('optimize');
