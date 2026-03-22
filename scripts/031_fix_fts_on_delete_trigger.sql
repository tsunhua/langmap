-- Migration: Fix FTS on-delete trigger and clean up index
-- Date: 2026-03-22
-- Description: Drops the broken 'expressions_ad' trigger and replaces it with a correct one. 
--              Also cleans up any orphaned entries in the FTS index caused by the previous bug.

--------------------------------------------------------------------------------
-- 1. Fix Triggers
--------------------------------------------------------------------------------

-- Update INSERT trigger
DROP TRIGGER IF EXISTS expressions_ai;
CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN
  INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

-- Update DELETE trigger (The buggy one)
DROP TRIGGER IF EXISTS expressions_ad;
CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN
  -- Correct FTS5 delete command for external content
  INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES('delete', old.id, old.text);
END;

-- Update UPDATE trigger
DROP TRIGGER IF EXISTS expressions_au;
CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN
  INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES('delete', old.id, old.text);
  INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

--------------------------------------------------------------------------------
-- 2. Clean Up Corrupted Data
--------------------------------------------------------------------------------

-- Remove orphaned entries in FTS index (those re-inserted by the buggy trigger)
DELETE FROM expressions_fts WHERE rowid NOT IN (SELECT id FROM expressions);

-- Optimize FTS index
INSERT INTO expressions_fts(expressions_fts) VALUES('optimize');
