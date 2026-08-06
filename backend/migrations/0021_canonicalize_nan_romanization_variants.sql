-- 0021: Canonicalize Taiwanese Hokkien romanization variants.
-- The IANA registry registers both `pehoeji` and `tailo` variants with
-- Prefix `nan-Latn` (no region).  The earlier `nan-Latn-TW-{pehoeji,tailo}`
-- tags carried an unregistered region in front of the variant, so any data
-- using them is moved to the canonical `nan-Latn-{pehoeji,tailo}` tags.
-- Children are rewritten before their parent profile so FK checks stay valid.
PRAGMA foreign_keys = OFF;

UPDATE expressions
SET language_profile_code = 'nan-Latn-pehoeji'
WHERE language_profile_code = 'nan-Latn-TW-pehoeji';

UPDATE expressions
SET language_profile_code = 'nan-Latn-tailo'
WHERE language_profile_code = 'nan-Latn-TW-tailo';

UPDATE ui_locales
SET code = 'nan-Latn-pehoeji'
WHERE code = 'nan-Latn-TW-pehoeji';

UPDATE ui_locales
SET code = 'nan-Latn-tailo'
WHERE code = 'nan-Latn-TW-tailo';

UPDATE ui_locales
SET fallback_code = 'nan-Latn-pehoeji'
WHERE fallback_code = 'nan-Latn-TW-pehoeji';

UPDATE ui_locales
SET fallback_code = 'nan-Latn-tailo'
WHERE fallback_code = 'nan-Latn-TW-tailo';

UPDATE language_profiles
SET code = 'nan-Latn-pehoeji'
WHERE code = 'nan-Latn-TW-pehoeji';

UPDATE language_profiles
SET code = 'nan-Latn-tailo'
WHERE code = 'nan-Latn-TW-tailo';

PRAGMA foreign_keys = ON;

CREATE TEMPORARY TABLE IF NOT EXISTS _migration_check (ok INTEGER);
DELETE FROM _migration_check;
INSERT INTO _migration_check (ok) VALUES (
    CASE WHEN (
        SELECT COUNT(*) FROM expressions e
        WHERE NOT EXISTS (SELECT 1 FROM language_profiles p WHERE p.code = e.language_profile_code)
    ) > 0 THEN 0
    WHEN (
        SELECT COUNT(*) FROM ui_locales u
        WHERE NOT EXISTS (SELECT 1 FROM language_profiles p WHERE p.code = u.code)
    ) > 0 THEN 0
    ELSE 1
    END
);
SELECT CASE WHEN ok = 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM _migration_check;
CREATE TABLE _migration_check_final AS SELECT ok FROM _migration_check;
SELECT CASE
    WHEN (SELECT ok FROM _migration_check_final) = 1 THEN 'migration succeeded'
    ELSE CAST(1/0 AS TEXT)
END;
DROP TABLE _migration_check_final;
DROP TABLE _migration_check;
