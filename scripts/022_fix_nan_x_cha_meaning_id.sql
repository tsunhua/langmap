-- Delete nan-x-cha expressions with langmap tags but NULL/self meaning_id

-- Step 1: Preview affected expressions
SELECT 
  e.id,
  e.text,
  e.language_code,
  e.meaning_id,
  e.tags
FROM expressions e
JOIN collection_items ci ON e.id = ci.expression_id
JOIN collections c ON ci.collection_id = c.id
WHERE c.name = 'langmap'
  AND e.language_code = 'nan-x-cha'
  AND e.tags LIKE '%"langmap.%' ESCAPE '!'
  AND (e.meaning_id IS NULL OR e.meaning_id = e.id);

-- Step 2: Delete affected expressions
DELETE FROM expressions
WHERE id IN (
  SELECT e.id
  FROM expressions e
  JOIN collection_items ci ON e.id = ci.expression_id
  JOIN collections c ON ci.collection_id = c.id
  WHERE c.name = 'langmap'
    AND e.language_code = 'nan-x-cha'
    AND e.tags LIKE '%"langmap.%' ESCAPE '!'
    AND (e.meaning_id IS NULL OR e.meaning_id = e.id)
);
