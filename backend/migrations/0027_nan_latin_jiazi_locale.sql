INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, orthography, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('nan-Latn-CN_LufengJiazi', 'nan', 'Latn', NULL, 'CN', 'LufengJiazi', '陸豐甲子話（拉丁字）', 'Lufeng Jiazi Hokkien (Latin)', 'system-seed', 'seed:v1-migration:2026-08-20');

UPDATE expression_locale_attestations
SET language_locale_code = 'nan-Latn-CN_LufengJiazi'
WHERE language_locale_code = 'nan-Hant-CN_LufengJiazi'
  AND expression_id IN (
    SELECT id FROM expressions
    WHERE text NOT GLOB '*[一-龥]*'
      AND text GLOB '*[A-Za-z]*'
  );
