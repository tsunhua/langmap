-- Teochew Hokkien place profiles kept the orthography only in
-- language_locales.orthography, while the importer reads the orthography out of
-- the locale code and treats a code that omits it as unspecified.  The two
-- disagreed, so the importer rejected these rows.  Put the orthography into the
-- code where the grammar reads it and keep the existing locale ids, so every
-- expression_locale_links / expression_readings / ui_locales / handbooks
-- reference stays valid.

DO $$
DECLARE
  target text;
  owner_id bigint;
BEGIN
  FOREACH target IN ARRAY ARRAY[
    'nan-Latn_PUJ-CN_Chaozhou',
    'nan-Latn_PUJ-CN_Swatow',
    'nan-Latn_DP-CN_Chaozhou'
  ] LOOP
    SELECT id INTO owner_id FROM language_locales WHERE code = target;
    IF owner_id IS NOT NULL THEN
      RAISE EXCEPTION 'target locale code % is already used by language_locales.id %',
        target, owner_id;
    END IF;
  END LOOP;
END $$;

UPDATE language_locales
   SET code = 'nan-Latn_PUJ-CN_Chaozhou'
 WHERE code = 'nan-Latn-CN_Chaozhou'
   AND orthography = 'PUJ';

UPDATE language_locales
   SET code = 'nan-Latn_PUJ-CN_Swatow'
 WHERE code = 'nan-Latn-CN_Swatow'
   AND orthography = 'PUJ';

UPDATE language_locales
   SET code = 'nan-Latn_DP-CN_Chaozhou',
       place_path = 'Chaozhou'
 WHERE code = 'nan-Latn-CN_Chaozhou_DP'
   AND orthography = 'DP';
