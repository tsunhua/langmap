-- Only first-party/source locales are enabled initially. Other imported locales
-- remain available for translation work but must not appear in the public switcher.
UPDATE ui_locales
SET status = 'draft', updated_at = CURRENT_TIMESTAMP
WHERE project_id = 'langmap-web'
  AND code NOT IN ('en-US', 'zh-Hant-TW', 'zh-Hans-CN');

UPDATE ui_locales
SET status = 'active', updated_at = CURRENT_TIMESTAMP
WHERE project_id = 'langmap-web'
  AND code IN ('en-US', 'zh-Hant-TW', 'zh-Hans-CN');
