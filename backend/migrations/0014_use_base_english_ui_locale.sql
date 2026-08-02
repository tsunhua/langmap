INSERT INTO ui_locales (
  project_id, code, native_name, direction, fallback_code, status,
  mapping_revision, created_by, created_at, updated_by, updated_at
)
SELECT
  project_id, 'en', 'English', direction, NULL, status,
  mapping_revision, created_by, created_at, updated_by, updated_at
FROM ui_locales
WHERE code = 'en-US'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = 'English',
  direction = excluded.direction,
  fallback_code = NULL,
  status = excluded.status,
  mapping_revision = MAX(ui_locales.mapping_revision, excluded.mapping_revision),
  updated_at = CURRENT_TIMESTAMP;

UPDATE ui_locales
SET fallback_code = 'en', updated_at = CURRENT_TIMESTAMP
WHERE fallback_code = 'en-US';

DELETE FROM ui_locales WHERE code = 'en-US';
