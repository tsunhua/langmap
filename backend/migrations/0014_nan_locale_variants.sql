-- nan: add the Hans (Simplified) variant so the language detail page has two
-- scripts to switch between (spec: 2026-08-14-language-detail-variety-selector),
-- correct the Taiwanese name to 台語 (with the Hokkien English alias), and
-- remove test-generated locales (example.test) that pollute local databases.

INSERT INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('nan-Hans-CN', 'nan', 'Hans', 'CN', '', '闽南语', 'Min Nan Chinese (Simplified)', 'system-seed', 'seed:system-seed:1');

UPDATE language_locales
SET name = '台語', name_en = 'Taiwanese Hokkien'
WHERE code = 'nan-Hant-TW';

DELETE FROM language_locales WHERE source_ref LIKE 'https://example.test/%';
