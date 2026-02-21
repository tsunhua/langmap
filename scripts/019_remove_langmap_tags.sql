-- Remove all tags that start with 'langmap.' prefix from expressions table
-- This script cleans up the langmap system tags from the database

UPDATE expressions
SET tags = (
  SELECT json_group_array(tag)
  FROM (
    SELECT DISTINCT value as tag
    FROM json_each(expressions.tags)
    WHERE NOT (
       -- Filter out tags that start with langmap.
       value LIKE 'langmap.%'
    )
    ORDER BY tag
  )
)
WHERE tags LIKE '%langmap.%'
  -- Only run on rows that actually have langmap. tags
  AND EXISTS (
    SELECT 1 FROM json_each(expressions.tags)
    WHERE value LIKE 'langmap.%'
  );
