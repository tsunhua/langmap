-- Shanghai Wu profile for Pott's 1913 Shanghai dialect dictionary.
-- IDs 128–135 are already allocated to Hakka locales in the
-- production-aligned mirror; 136 is the next available locale ID.
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 136, 'wuu-Hant-CN_Shanghai', id, 'Hant', 'CN', 'Shanghai', '上海話', 'Shanghai Wu'
FROM languages WHERE code = 'wuu';
