-- 0024: Canonicalize the Japanese script profiles.
-- The bare `ja` content profile is replaced by the script profiles `ja-Jpan`
-- (standard kanji+kana mixed), `ja-Hani`, `ja-Hrkt`, and `ja-Latn`. Existing
-- rows were all written in standard Japanese, so they move to `ja-Jpan`.
-- Children are rewritten before their parent profile so FK checks stay valid.
PRAGMA foreign_keys = OFF;

UPDATE expressions
SET language_profile_code = 'ja-Jpan'
WHERE language_profile_code = 'ja';

UPDATE ui_locales
SET code = 'ja-Jpan'
WHERE code = 'ja';

UPDATE ui_locales
SET fallback_code = 'ja-Jpan'
WHERE fallback_code = 'ja';

UPDATE language_profiles
SET code = 'ja-Jpan'
WHERE code = 'ja';

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
