-- Find nan-x-cha expressions that have same text AND same tags as zh-TW
-- Step 1: Preview affected expressions
SELECT 
  nan.id as nan_id,
  nan.text as nan_text,
  nan.meaning_id as nan_meaning_id,
  nan.tags as nan_tags,
  zh.id as zh_id,
  zh.text as zh_text,
  zh.meaning_id as zh_meaning_id,
  zh.tags as zh_tags
FROM expressions nan
JOIN collection_items ci_nan ON nan.id = ci_nan.expression_id
JOIN collections c_nan ON ci_nan.collection_id = c_nan.id
JOIN expressions zh ON nan.tags = zh.tags
JOIN collection_items ci_zh ON zh.id = ci_zh.expression_id
JOIN collections c_zh ON ci_zh.collection_id = c_zh.id
WHERE c_nan.name = 'langmap'
  AND c_zh.name = 'langmap'
  AND nan.language_code = 'nan-x-cha'
  AND zh.language_code = 'zh-TW'
  AND nan.text = zh.text;

-- Step 2: Delete nan-x-cha expressions that are duplicates of zh-TW
DELETE FROM expressions
WHERE id IN (
  SELECT nan.id
  FROM expressions nan
  JOIN collection_items ci_nan ON nan.id = ci_nan.expression_id
  JOIN collections c_nan ON ci_nan.collection_id = c_nan.id
  JOIN expressions zh ON nan.tags = zh.tags
  JOIN collection_items ci_zh ON zh.id = ci_zh.expression_id
  JOIN collections c_zh ON ci_zh.collection_id = c_zh.id
  WHERE c_nan.name = 'langmap'
    AND c_zh.name = 'langmap'
    AND nan.language_code = 'nan-x-cha'
    AND zh.language_code = 'zh-TW'
    AND nan.text = zh.text
);
