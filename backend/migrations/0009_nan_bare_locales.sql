-- Bare representative locales for Min Nan Chinese (nan), matching the
-- lang-script-region convention already seeded for eng (eng-Latn-US) and cmn
-- (cmn-Hant-TW, cmn-Hans-CN). Without these, creating expressions or locale
-- attestations against nan-Hant-CN / nan-Hant-TW fails with
-- INVALID_LANGUAGE_LOCALE_CODE because only place-qualified nan locales exist.

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('nan-Hant-CN', 'nan', 'Hant', 'CN', '', '閩南語（中國）', 'Min Nan Chinese (China)', 'system-seed', 'seed:system-seed:1'),
  ('nan-Hant-TW', 'nan', 'Hant', 'TW', '', '閩南語（臺灣）', 'Min Nan Chinese (Taiwan)', 'system-seed', 'seed:system-seed:1');
