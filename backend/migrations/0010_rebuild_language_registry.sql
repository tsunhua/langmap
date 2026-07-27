-- 0010: Rebuild languages to single-profile schema.
-- One-time D1 migration: legacy columns → single-profile languages table.
PRAGMA foreign_keys = OFF;

-- 1. Create new tables alongside the old ones.
CREATE TABLE IF NOT EXISTS language_subtags (
    type TEXT NOT NULL,
    value TEXT NOT NULL,
    descriptions TEXT NOT NULL DEFAULT '[]',
    prefixes TEXT NOT NULL DEFAULT '[]',
    preferred_value TEXT,
    suppress_script TEXT,
    deprecated TEXT,
    PRIMARY KEY (type, value)
);

CREATE TABLE IF NOT EXISTS languages_new (
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    description TEXT,
    direction TEXT DEFAULT 'ltr',
    base_language TEXT,
    script_code TEXT,
    region_code TEXT,
    variants_json TEXT,
    private_use_json TEXT,
    variety_key TEXT NOT NULL,
    glottocode TEXT,
    origin TEXT NOT NULL DEFAULT 'seed',
    community_reason TEXT,
    alternate_names_json TEXT,
    references_json TEXT,
    parent_languoid_id TEXT,
    latitude REAL,
    longitude REAL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 2. Explicitly update the two known noncanonical online tags.
UPDATE expressions
SET language_code = 'nan-Latn-TW-tailo'
WHERE language_code = 'nan-TW-Latn-tailo';

UPDATE expressions
SET language_code = 'nan-Latn-TW-pehoeji'
WHERE language_code = 'nan-TW-Latn-pehoeji';

UPDATE language_stats
SET language_code = 'nan-Latn-TW-tailo'
WHERE language_code = 'nan-TW-Latn-tailo';

UPDATE language_stats
SET language_code = 'nan-Latn-TW-pehoeji'
WHERE language_code = 'nan-TW-Latn-pehoeji';

UPDATE ui_locales
SET code = 'nan-Latn-TW-tailo'
WHERE code = 'nan-TW-Latn-tailo';

UPDATE ui_locales
SET code = 'nan-Latn-TW-pehoeji'
WHERE code = 'nan-TW-Latn-pehoeji';

-- 3. Drop unmapped child rows referencing legacy codes not carried forward.
--    Codes in the old `languages` table that are NOT in the explicit mapping
--    (nan-TW-Latn-tailo → nan-Latn-TW-tailo, nan-TW-Latn-pehoeji →
--    nan-Latn-TW-pehoeji) will not appear in languages_new.  Remove any
--    child rows still pointing at those unmapped legacy codes.
DELETE FROM expressions
WHERE language_code NOT IN (
    SELECT CASE
      WHEN code = 'nan-TW-Latn-tailo' THEN 'nan-Latn-TW-tailo'
      WHEN code = 'nan-TW-Latn-pehoeji' THEN 'nan-Latn-TW-pehoeji'
      ELSE code
    END
    FROM languages
);

DELETE FROM language_stats
WHERE language_code NOT IN (
    SELECT CASE
      WHEN code = 'nan-TW-Latn-tailo' THEN 'nan-Latn-TW-tailo'
      WHEN code = 'nan-TW-Latn-pehoeji' THEN 'nan-Latn-TW-pehoeji'
      ELSE code
    END
    FROM languages
);

DELETE FROM ui_locales
WHERE code NOT IN (
    SELECT CASE
      WHEN code = 'nan-TW-Latn-tailo' THEN 'nan-Latn-TW-tailo'
      WHEN code = 'nan-TW-Latn-pehoeji' THEN 'nan-Latn-TW-pehoeji'
      ELSE code
    END
    FROM languages
);

-- 4. Copy legacy rows into languages_new, applying canonical mappings.
INSERT OR REPLACE INTO languages_new (
    code, name, name_en, description, direction, base_language,
    script_code, region_code, variants_json, private_use_json,
    variety_key, glottocode, origin, community_reason,
    alternate_names_json, references_json, parent_languoid_id,
    latitude, longitude, created_by, created_at, updated_by, updated_at
)
SELECT
    CASE
      WHEN code = 'nan-TW-Latn-tailo' THEN 'nan-Latn-TW-tailo'
      WHEN code = 'nan-TW-Latn-pehoeji' THEN 'nan-Latn-TW-pehoeji'
      ELSE code
    END AS code,
    name, name_en, description, direction, base_language,
    script_code, region_code, variants_json, private_use_json,
    COALESCE(
      variety_key,
      CASE WHEN glottocode IS NOT NULL AND glottocode != ''
        THEN 'glotto:' || glottocode
        ELSE 'migration:' || code
      END
    ) AS variety_key,
    glottocode,
    COALESCE(origin, 'seed') AS origin,
    community_reason, alternate_names_json, references_json,
    parent_languoid_id, latitude, longitude,
    created_by, created_at, updated_by, updated_at
FROM languages;

-- 5. Drop old table and promote the new one.
DROP TABLE IF EXISTS languages;
ALTER TABLE languages_new RENAME TO languages;

-- 6. Recreate indexes.
CREATE INDEX IF NOT EXISTS idx_languages_name ON languages(name);
CREATE INDEX IF NOT EXISTS idx_languages_variety_key ON languages(variety_key);
CREATE INDEX IF NOT EXISTS idx_languages_glottocode ON languages(glottocode);
CREATE INDEX IF NOT EXISTS idx_languages_base_script_region
  ON languages(base_language, script_code, region_code);
CREATE INDEX IF NOT EXISTS idx_language_subtags_search
  ON language_subtags(type, value);

-- 7. Re-enable foreign keys and abort if any referenced code is absent.
PRAGMA foreign_keys = ON;

CREATE TEMPORARY TABLE IF NOT EXISTS _migration_check (ok INTEGER);
DELETE FROM _migration_check;
INSERT INTO _migration_check (ok) VALUES (
    CASE WHEN (
        SELECT COUNT(*) FROM expressions e
        WHERE NOT EXISTS (SELECT 1 FROM languages l WHERE l.code = e.language_code)
    ) > 0 THEN 0
    WHEN (
        SELECT COUNT(*) FROM ui_locales u
        WHERE NOT EXISTS (SELECT 1 FROM languages l WHERE l.code = u.code)
    ) > 0 THEN 0
    ELSE 1
    END
);
SELECT CASE WHEN ok = 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM _migration_check;
-- This CHECK will abort if any referenced code is absent:
CREATE TABLE _migration_check_final AS SELECT ok FROM _migration_check;
SELECT CASE
    WHEN (SELECT ok FROM _migration_check_final) = 1 THEN 'migration succeeded'
    ELSE CAST(1/0 AS TEXT)
END;
DROP TABLE _migration_check_final;
DROP TABLE _migration_check;
