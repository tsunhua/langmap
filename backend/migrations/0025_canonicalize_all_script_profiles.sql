-- 0025: Canonicalize the remaining script profiles.
-- Every seeded language used a bare content profile (e.g. `en`) or a regional
-- tag (e.g. `en-US`) instead of a full BCP 47 script tag. The canonical codes
-- are the script profiles in language_seed_profiles.json; rows written before
-- this migration move to the matching script profile. Children are rewritten
-- before their parent profile so FK checks stay valid.
PRAGMA foreign_keys = OFF;

UPDATE expressions
SET language_profile_code = CASE language_profile_code
  WHEN 'ar' THEN 'ar-Arab'
  WHEN 'bn' THEN 'bn-Beng'
  WHEN 'de' THEN 'de-Latn'
  WHEN 'en' THEN 'en-Latn'
  WHEN 'en-GB' THEN 'en-Latn-GB'
  WHEN 'en-US' THEN 'en-Latn-US'
  WHEN 'es' THEN 'es-Latn'
  WHEN 'fa' THEN 'fa-Arab'
  WHEN 'fr' THEN 'fr-Latn'
  WHEN 'hi' THEN 'hi-Deva'
  WHEN 'id' THEN 'id-Latn'
  WHEN 'it' THEN 'it-Latn'
  WHEN 'mr' THEN 'mr-Deva'
  WHEN 'pt' THEN 'pt-Latn'
  WHEN 'pt-BR' THEN 'pt-Latn-BR'
  WHEN 'ral' THEN 'ral-Latn'
  WHEN 'ru' THEN 'ru-Cyrl'
  WHEN 'swh' THEN 'swh-Latn'
  WHEN 'th' THEN 'th-Thai'
  WHEN 'tr' THEN 'tr-Latn'
  WHEN 'ur' THEN 'ur-Arab'
  WHEN 'vi' THEN 'vi-Latn'
  ELSE language_profile_code
END
WHERE language_profile_code IN (
  'ar', 'bn', 'de', 'en', 'en-GB', 'en-US', 'es', 'fa', 'fr', 'hi', 'id',
  'it', 'mr', 'pt', 'pt-BR', 'ral', 'ru', 'swh', 'th', 'tr', 'ur', 'vi'
);

UPDATE ui_locales
SET code = CASE code
  WHEN 'ar' THEN 'ar-Arab'
  WHEN 'bn' THEN 'bn-Beng'
  WHEN 'de' THEN 'de-Latn'
  WHEN 'en' THEN 'en-Latn'
  WHEN 'en-GB' THEN 'en-Latn-GB'
  WHEN 'en-US' THEN 'en-Latn-US'
  WHEN 'es' THEN 'es-Latn'
  WHEN 'fa' THEN 'fa-Arab'
  WHEN 'fr' THEN 'fr-Latn'
  WHEN 'hi' THEN 'hi-Deva'
  WHEN 'id' THEN 'id-Latn'
  WHEN 'it' THEN 'it-Latn'
  WHEN 'mr' THEN 'mr-Deva'
  WHEN 'pt' THEN 'pt-Latn'
  WHEN 'pt-BR' THEN 'pt-Latn-BR'
  WHEN 'ral' THEN 'ral-Latn'
  WHEN 'ru' THEN 'ru-Cyrl'
  WHEN 'swh' THEN 'swh-Latn'
  WHEN 'th' THEN 'th-Thai'
  WHEN 'tr' THEN 'tr-Latn'
  WHEN 'ur' THEN 'ur-Arab'
  WHEN 'vi' THEN 'vi-Latn'
  ELSE code
END
WHERE code IN (
  'ar', 'bn', 'de', 'en', 'en-GB', 'en-US', 'es', 'fa', 'fr', 'hi', 'id',
  'it', 'mr', 'pt', 'pt-BR', 'ral', 'ru', 'swh', 'th', 'tr', 'ur', 'vi'
);

UPDATE ui_locales
SET fallback_code = CASE fallback_code
  WHEN 'ar' THEN 'ar-Arab'
  WHEN 'bn' THEN 'bn-Beng'
  WHEN 'de' THEN 'de-Latn'
  WHEN 'en' THEN 'en-Latn'
  WHEN 'en-GB' THEN 'en-Latn-GB'
  WHEN 'en-US' THEN 'en-Latn-US'
  WHEN 'es' THEN 'es-Latn'
  WHEN 'fa' THEN 'fa-Arab'
  WHEN 'fr' THEN 'fr-Latn'
  WHEN 'hi' THEN 'hi-Deva'
  WHEN 'id' THEN 'id-Latn'
  WHEN 'it' THEN 'it-Latn'
  WHEN 'mr' THEN 'mr-Deva'
  WHEN 'pt' THEN 'pt-Latn'
  WHEN 'pt-BR' THEN 'pt-Latn-BR'
  WHEN 'ral' THEN 'ral-Latn'
  WHEN 'ru' THEN 'ru-Cyrl'
  WHEN 'swh' THEN 'swh-Latn'
  WHEN 'th' THEN 'th-Thai'
  WHEN 'tr' THEN 'tr-Latn'
  WHEN 'ur' THEN 'ur-Arab'
  WHEN 'vi' THEN 'vi-Latn'
  ELSE fallback_code
END
WHERE fallback_code IN (
  'ar', 'bn', 'de', 'en', 'en-GB', 'en-US', 'es', 'fa', 'fr', 'hi', 'id',
  'it', 'mr', 'pt', 'pt-BR', 'ral', 'ru', 'swh', 'th', 'tr', 'ur', 'vi'
);

UPDATE language_profiles
SET code = CASE code
  WHEN 'ar' THEN 'ar-Arab'
  WHEN 'bn' THEN 'bn-Beng'
  WHEN 'de' THEN 'de-Latn'
  WHEN 'en' THEN 'en-Latn'
  WHEN 'en-GB' THEN 'en-Latn-GB'
  WHEN 'en-US' THEN 'en-Latn-US'
  WHEN 'es' THEN 'es-Latn'
  WHEN 'fa' THEN 'fa-Arab'
  WHEN 'fr' THEN 'fr-Latn'
  WHEN 'hi' THEN 'hi-Deva'
  WHEN 'id' THEN 'id-Latn'
  WHEN 'it' THEN 'it-Latn'
  WHEN 'mr' THEN 'mr-Deva'
  WHEN 'pt' THEN 'pt-Latn'
  WHEN 'pt-BR' THEN 'pt-Latn-BR'
  WHEN 'ral' THEN 'ral-Latn'
  WHEN 'ru' THEN 'ru-Cyrl'
  WHEN 'swh' THEN 'swh-Latn'
  WHEN 'th' THEN 'th-Thai'
  WHEN 'tr' THEN 'tr-Latn'
  WHEN 'ur' THEN 'ur-Arab'
  WHEN 'vi' THEN 'vi-Latn'
  ELSE code
END
WHERE code IN (
  'ar', 'bn', 'de', 'en', 'en-GB', 'en-US', 'es', 'fa', 'fr', 'hi', 'id',
  'it', 'mr', 'pt', 'pt-BR', 'ral', 'ru', 'swh', 'th', 'tr', 'ur', 'vi'
);

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
