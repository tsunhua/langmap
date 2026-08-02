-- Separate language content identity from representative geography.
-- Region subtags remain only for reviewed content conventions.
PRAGMA defer_foreign_keys = ON;

CREATE TEMP TABLE _canonical_language_codes (
  old_code TEXT PRIMARY KEY,
  new_code TEXT NOT NULL,
  base_language TEXT NOT NULL,
  script_code TEXT NOT NULL DEFAULT '',
  region_code TEXT NOT NULL DEFAULT ''
);

INSERT INTO _canonical_language_codes (old_code, new_code, base_language, script_code, region_code) VALUES
  ('zh-Hans-CN', 'zh-Hans', 'zh', 'Hans', ''),
  ('zh-Hant-TW', 'zh-Hant', 'zh', 'Hant', ''),
  ('zh-Hant-HK', 'zh-Hant', 'zh', 'Hant', ''),
  ('zh-Hant-MO', 'zh-Hant', 'zh', 'Hant', ''),
  ('ar-SA', 'ar', 'ar', '', ''),
  ('bn-BD', 'bn', 'bn', '', ''),
  ('de-DE', 'de', 'de', '', ''),
  ('es-ES', 'es', 'es', '', ''),
  ('fa-IR', 'fa', 'fa', '', ''),
  ('fr-FR', 'fr', 'fr', '', ''),
  ('hi-IN', 'hi', 'hi', '', ''),
  ('id-ID', 'id', 'id', '', ''),
  ('it-IT', 'it', 'it', '', ''),
  ('ja-JP', 'ja', 'ja', '', ''),
  ('ko-CN', 'ko', 'ko', '', ''),
  ('mr-IN', 'mr', 'mr', '', ''),
  ('pa-PK', 'pa-Guru', 'pa', 'Guru', ''),
  ('ru-RU', 'ru', 'ru', '', ''),
  ('th-TH', 'th', 'th', '', ''),
  ('tr-TR', 'tr', 'tr', '', ''),
  ('ur-PK', 'ur', 'ur', '', ''),
  ('vi-VN', 'vi', 'vi', '', ''),
  ('wuu-Hant-CN', 'wuu-Hant', 'wuu', 'Hant', ''),
  ('wuu-Hans-CN', 'wuu-Hans', 'wuu', 'Hans', ''),
  ('yue-Hant-HK', 'yue-Hant', 'yue', 'Hant', ''),
  ('yue-Hant-MO', 'yue-Hant', 'yue', 'Hant', ''),
  ('yue-Hans-CN', 'yue-Hans', 'yue', 'Hans', ''),
  ('hsn-Hant-CN', 'hsn-Hant', 'hsn', 'Hant', ''),
  ('hsn-Hans-CN', 'hsn-Hans', 'hsn', 'Hans', ''),
  ('hak-Hant-TW', 'hak-Hant', 'hak', 'Hant', ''),
  ('hak-Hans-CN', 'hak-Hans', 'hak', 'Hans', ''),
  ('cdo-Hant-CN', 'cdo-Hant', 'cdo', 'Hant', ''),
  ('cdo-Hans-CN', 'cdo-Hans', 'cdo', 'Hans', ''),
  ('mnp-Hant-CN', 'mnp-Hant', 'mnp', 'Hant', ''),
  ('mnp-Hans-CN', 'mnp-Hans', 'mnp', 'Hans', ''),
  ('nan-Hans-CN', 'nan-Hans', 'nan', 'Hans', ''),
  ('nan-Hant-TW', 'nan-Hant', 'nan', 'Hant', ''),
  ('bo-Tibt-CN', 'bo-Tibt', 'bo', 'Tibt', ''),
  ('ug-Arab-CN', 'ug-Arab', 'ug', 'Arab', ''),
  ('mn-Mong-CN', 'mn-Mong', 'mn', 'Mong', ''),
  ('mn-Cyrl-MN', 'mn-Cyrl', 'mn', 'Cyrl', ''),
  ('kk-Arab-CN', 'kk-Arab', 'kk', 'Arab', ''),
  ('kk-Cyrl-KZ', 'kk-Cyrl', 'kk', 'Cyrl', ''),
  ('ky-Arab-CN', 'ky-Arab', 'ky', 'Arab', ''),
  ('ky-Cyrl-KG', 'ky-Cyrl', 'ky', 'Cyrl', ''),
  ('za-Latn-CN', 'za-Latn', 'za', 'Latn', '');

-- Create every canonical target before moving foreign-key references. The
-- registry import that follows this migration refreshes curated names and
-- metadata; this copy makes the migration independently safe and rerunnable.
INSERT OR IGNORE INTO languages (
  code, name, name_en, description, direction, base_language, script_code,
  region_code, variants_json, private_use_json, variety_key, glottocode,
  origin, community_reason, alternate_names_json, references_json,
  parent_languoid_id, latitude, longitude, created_by, created_at,
  updated_by, updated_at
)
SELECT
  mapping.new_code, source.name, source.name_en, source.description,
  source.direction, mapping.base_language, mapping.script_code,
  mapping.region_code, source.variants_json, source.private_use_json,
  CASE WHEN source.glottocode IS NULL THEN 'system:' || mapping.new_code
       ELSE source.variety_key END,
  source.glottocode, source.origin, source.community_reason,
  source.alternate_names_json, source.references_json,
  source.parent_languoid_id, source.latitude, source.longitude,
  source.created_by, source.created_at, source.updated_by, source.updated_at
FROM _canonical_language_codes AS mapping
JOIN languages AS source ON source.code = mapping.old_code
ORDER BY mapping.new_code, mapping.old_code;

-- Merge UI locale rows before removing old locale keys. This also handles a
-- reviewed many-to-one mapping without violating the composite primary key.
INSERT INTO ui_locales (
  project_id, code, native_name, direction, fallback_code, status,
  mapping_revision, created_by, created_at, updated_by, updated_at
)
SELECT
  locale.project_id, mapping.new_code, locale.native_name, locale.direction,
  locale.fallback_code, locale.status, locale.mapping_revision,
  locale.created_by, locale.created_at, locale.updated_by, locale.updated_at
FROM ui_locales AS locale
JOIN _canonical_language_codes AS mapping ON mapping.old_code = locale.code
WHERE mapping.old_code <> mapping.new_code
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status,
  mapping_revision = MAX(ui_locales.mapping_revision, excluded.mapping_revision),
  updated_at = excluded.updated_at;

UPDATE ui_locales
SET fallback_code = (
  SELECT mapping.new_code
  FROM _canonical_language_codes AS mapping
  WHERE mapping.old_code = ui_locales.fallback_code
)
WHERE fallback_code IN (SELECT old_code FROM _canonical_language_codes);

DELETE FROM ui_locales
WHERE code IN (SELECT old_code FROM _canonical_language_codes WHERE old_code <> new_code);

UPDATE expressions
SET language_code = (
  SELECT mapping.new_code
  FROM _canonical_language_codes AS mapping
  WHERE mapping.old_code = expressions.language_code
)
WHERE language_code IN (SELECT old_code FROM _canonical_language_codes);

CREATE TEMP TABLE _canonical_language_stats AS
SELECT
  COALESCE(mapping.new_code, stats.language_code) AS language_code,
  SUM(stats.expression_count) AS expression_count
FROM language_stats AS stats
LEFT JOIN _canonical_language_codes AS mapping ON mapping.old_code = stats.language_code
GROUP BY COALESCE(mapping.new_code, stats.language_code);

DELETE FROM language_stats;
INSERT INTO language_stats (language_code, expression_count)
SELECT language_code, expression_count
FROM _canonical_language_stats
ORDER BY language_code;
DROP TABLE _canonical_language_stats;

DELETE FROM languages
WHERE code IN (SELECT old_code FROM _canonical_language_codes WHERE old_code <> new_code);

CREATE TEMP TABLE _canonical_language_check (
  ok INTEGER NOT NULL CHECK (ok = 1)
);
INSERT INTO _canonical_language_check (ok)
SELECT CASE WHEN
  NOT EXISTS (
    SELECT 1 FROM expressions
    WHERE language_code IN (SELECT old_code FROM _canonical_language_codes)
  )
  AND NOT EXISTS (
    SELECT 1 FROM ui_locales
    WHERE code IN (SELECT old_code FROM _canonical_language_codes WHERE old_code <> new_code)
  )
  AND NOT EXISTS (
    SELECT 1 FROM language_stats
    WHERE language_code IN (SELECT old_code FROM _canonical_language_codes)
  )
  AND NOT EXISTS (SELECT 1 FROM pragma_foreign_key_check)
THEN 1 ELSE 0 END;

DROP TABLE _canonical_language_check;
DROP TABLE _canonical_language_codes;
