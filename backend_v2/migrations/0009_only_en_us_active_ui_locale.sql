-- en-US is the sole built-in UI locale. Every other UI locale is translated
-- through expression mappings and remains draft until it meets activation policy.
UPDATE ui_locales
SET status = CASE WHEN code = 'en-US' THEN 'active' ELSE 'draft' END,
    updated_at = CURRENT_TIMESTAMP
WHERE project_id = 'langmap-web';
