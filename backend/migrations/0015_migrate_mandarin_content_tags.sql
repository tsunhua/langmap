-- Mandarin content was tagged with the `zh` macrolanguage, which also covers
-- Yue, Min Nan, Hakka and Wu. Move it onto the precise `cmn` subtag so the
-- stored content tag matches the single languoid it actually describes.
PRAGMA defer_foreign_keys = ON;

CREATE TEMP TABLE _mandarin_language_codes (
  old_code TEXT PRIMARY KEY,
  new_code TEXT NOT NULL,
  base_language TEXT NOT NULL,
  script_code TEXT NOT NULL DEFAULT '',
  region_code TEXT NOT NULL DEFAULT '',
  -- The registry import refreshes `languages.name`, but `ui_locales.native_name`
  -- is outside its scope, so the locale display name has to travel with the
  -- code here. Both names read "Huayu" and differ only in script: `cmn-Hans`
  -- also covers Singapore, where 普通话 would be the wrong self-designation.
  locale_native_name TEXT NOT NULL
);

INSERT INTO _mandarin_language_codes
  (old_code, new_code, base_language, script_code, region_code, locale_native_name)
VALUES
  ('zh-Hans', 'cmn-Hans', 'cmn', 'Hans', '', '华语'),
  ('zh-Hant', 'cmn-Hant', 'cmn', 'Hant', '', '華語');

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
FROM _mandarin_language_codes AS mapping
JOIN languages AS source ON source.code = mapping.old_code
ORDER BY mapping.new_code, mapping.old_code;

-- Merge UI locale rows before removing the old locale keys, because
-- ui_locales.code references languages(code).
INSERT INTO ui_locales (
  project_id, code, native_name, direction, fallback_code, status,
  mapping_revision, created_by, created_at, updated_by, updated_at
)
SELECT
  locale.project_id, mapping.new_code, mapping.locale_native_name,
  locale.direction, locale.fallback_code, locale.status,
  locale.mapping_revision, locale.created_by, locale.created_at,
  locale.updated_by, locale.updated_at
FROM ui_locales AS locale
JOIN _mandarin_language_codes AS mapping ON mapping.old_code = locale.code
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status,
  mapping_revision = MAX(ui_locales.mapping_revision, excluded.mapping_revision),
  updated_at = excluded.updated_at;

UPDATE ui_locales
SET fallback_code = (
  SELECT mapping.new_code
  FROM _mandarin_language_codes AS mapping
  WHERE mapping.old_code = ui_locales.fallback_code
)
WHERE fallback_code IN (SELECT old_code FROM _mandarin_language_codes);

DELETE FROM ui_locales
WHERE code IN (SELECT old_code FROM _mandarin_language_codes);

-- On a rerun the targets already carry the migrated name, so restate it
-- independently of the legacy rows that no longer exist.
UPDATE ui_locales
SET native_name = (
  SELECT mapping.locale_native_name
  FROM _mandarin_language_codes AS mapping
  WHERE mapping.new_code = ui_locales.code
)
WHERE code IN (SELECT new_code FROM _mandarin_language_codes)
  AND native_name <> (
    SELECT mapping.locale_native_name
    FROM _mandarin_language_codes AS mapping
    WHERE mapping.new_code = ui_locales.code
  );

UPDATE expressions
SET language_code = (
  SELECT mapping.new_code
  FROM _mandarin_language_codes AS mapping
  WHERE mapping.old_code = expressions.language_code
)
WHERE language_code IN (SELECT old_code FROM _mandarin_language_codes);

-- Fold the legacy statistics rows into their canonical target instead of
-- dropping them, so a pre-existing count is not silently lost.
CREATE TEMP TABLE _mandarin_language_stats AS
SELECT
  COALESCE(mapping.new_code, stats.language_code) AS language_code,
  SUM(stats.expression_count) AS expression_count
FROM language_stats AS stats
LEFT JOIN _mandarin_language_codes AS mapping ON mapping.old_code = stats.language_code
GROUP BY COALESCE(mapping.new_code, stats.language_code);

DELETE FROM language_stats;
INSERT INTO language_stats (language_code, expression_count)
SELECT language_code, expression_count
FROM _mandarin_language_stats
ORDER BY language_code;
DROP TABLE _mandarin_language_stats;

DELETE FROM languages
WHERE code IN (SELECT old_code FROM _mandarin_language_codes);

CREATE TEMP TABLE _mandarin_language_check (
  ok INTEGER NOT NULL CHECK (ok = 1)
);
INSERT INTO _mandarin_language_check (ok)
SELECT CASE WHEN
  NOT EXISTS (
    SELECT 1 FROM expressions
    WHERE language_code IN (SELECT old_code FROM _mandarin_language_codes)
  )
  AND NOT EXISTS (
    SELECT 1 FROM ui_locales
    WHERE code IN (SELECT old_code FROM _mandarin_language_codes)
       OR fallback_code IN (SELECT old_code FROM _mandarin_language_codes)
  )
  AND NOT EXISTS (
    SELECT 1 FROM language_stats
    WHERE language_code IN (SELECT old_code FROM _mandarin_language_codes)
  )
  AND NOT EXISTS (
    SELECT 1 FROM languages
    WHERE code IN (SELECT old_code FROM _mandarin_language_codes)
  )
  AND NOT EXISTS (SELECT 1 FROM pragma_foreign_key_check)
THEN 1 ELSE 0 END;

DROP TABLE _mandarin_language_check;
DROP TABLE _mandarin_language_codes;
