-- FTS Index Cleanup Script
-- This script removes orphaned entries from the expressions_fts table
-- Orphaned entries are those whose rowid does not exist in the expressions table

-- Run this script to clean up FTS index after manual database operations
-- or if you encounter issues with search returning non-existent expressions

-- Delete orphaned FTS entries
DELETE FROM expressions_fts
WHERE rowid NOT IN (SELECT id FROM expressions);

-- Verify the cleanup (optional - just displays the count)
-- SELECT COUNT(*) as remaining_fts_entries FROM expressions_fts;
-- SELECT COUNT(*) as remaining_expressions FROM expressions;
