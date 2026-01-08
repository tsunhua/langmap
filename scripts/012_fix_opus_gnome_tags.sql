-- Fix script to remove incorrect 'langmap.opus' and 'langmap.gnome' tags
-- These tags were incorrectly prefixed during migration and need to be removed.

UPDATE expressions
SET tags = (
  SELECT json_group_array(value)
  FROM json_each(expressions.tags)
  WHERE value NOT IN ('langmap.opus', 'langmap.gnome')
)
WHERE EXISTS (
  SELECT 1
  FROM json_each(expressions.tags)
  WHERE value IN ('langmap.opus', 'langmap.gnome')
);
