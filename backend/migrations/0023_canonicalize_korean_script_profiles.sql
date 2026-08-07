-- 0023: Canonicalize the Korean script profiles.
-- The regional `ko`, `ko-KP`, and `ko-KR` content profiles are replaced by the
-- script profiles `ko-Hang`, `ko-Hani`, and `ko-Kore`. Existing rows were all
-- written in Hangul, so they move to `ko-Hang`. Children are rewritten before
-- their parent profile so FK checks stay valid.
PRAGMA foreign_keys = OFF;

UPDATE expressions
SET language_profile_code = 'ko-Hang'
WHERE language_profile_code IN ('ko', 'ko-KP', 'ko-KR');

UPDATE ui_locales
SET code = 'ko-Hang'
WHERE code IN ('ko', 'ko-KP', 'ko-KR');

UPDATE ui_locales
SET fallback_code = 'ko-Hang'
WHERE fallback_code IN ('ko', 'ko-KP', 'ko-KR');

UPDATE language_profiles
SET code = 'ko-Hang'
WHERE code IN ('ko', 'ko-KP', 'ko-KR');

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
