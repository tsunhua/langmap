-- Migration script to add 'langmap.' prefix to existing tags
-- This ensures all tags are namespaced correctly for the translation interface

-- Update expressions to prepend 'langmap.' to any tag that doesn't already have it
UPDATE expressions
SET tags = (
  SELECT json_group_array(tag)
  FROM (
    SELECT DISTINCT tag
    FROM (
      -- Select existing tags
      SELECT value as tag FROM json_each(expressions.tags)
      UNION ALL
      -- Select tags with prefix added, only if they don't already match the prefix pattern
      SELECT 'langmap.' || value as tag FROM json_each(expressions.tags)
      WHERE value NOT LIKE 'langmap.%'
    )
  )
)
WHERE tags IS NOT NULL 
  AND json_valid(tags) 
  AND tags != '[]';
