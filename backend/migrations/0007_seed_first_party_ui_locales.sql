-- First-party interface locales. The SELECT keeps this migration safe when the
-- pinned language registry has not been imported yet; the deployment gate runs
-- it again after the registry seed is present.
INSERT OR IGNORE INTO ui_locales
  (project_id, code, native_name, direction, fallback_code, status)
SELECT 'langmap-web', code,
       CASE code WHEN 'zh-Hant-TW' THEN '繁體中文（台灣）' ELSE '简体中文（中国）' END,
       'ltr', 'en', 'active'
FROM languages
WHERE code IN ('zh-Hant-TW', 'zh-Hans-CN');
