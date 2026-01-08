-- Fix script to remove 'langmap.' prefix from non-ASCII tags (e.g. Chinese tags)
-- This corrects the issue where "intro" tags like "入門" became "langmap.入門"

UPDATE expressions
SET tags = (
  SELECT json_group_array(tag)
  FROM (
    SELECT DISTINCT value as tag
    FROM json_each(expressions.tags)
    WHERE NOT (
       -- Filter out tags that start with langmap. AND contain non-ASCII chars
       value LIKE 'langmap.%' 
       AND length(substr(value, 9)) != length(cast(substr(value, 9) as blob))
    )
  )
)
WHERE tags LIKE '%langmap.%'
  -- Only run on rows that actually have incorrect tags
  AND EXISTS (
    SELECT 1 FROM json_each(expressions.tags)
    WHERE value LIKE 'langmap.%'
    AND length(substr(value, 9)) != length(cast(substr(value, 9) as blob))
  );
