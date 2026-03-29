-- Replace literal '{TAG_JSON}' with correct tag value and deduplicate

UPDATE expressions
SET tags = (
    SELECT json_group_array(DISTINCT value)
    FROM (
        SELECT CASE WHEN value = '{TAG_JSON}' THEN '"1956 台灣白話基礎語句"' ELSE value END AS value
        FROM json_each(COALESCE(tags, '[]'))
    )
)
WHERE source_type = 'dictionary' AND tags LIKE '%{TAG_JSON}%';
