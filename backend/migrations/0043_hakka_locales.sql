-- Register the seven Taiwan Hakka locale profiles for the structured export at
-- the same integer IDs the dictionary delta assigns, so every later carrier
-- (data delta, reference bundle) becomes an INSERT OR IGNORE no-op.
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 128, 'hak-Hant-TW', id, 'Hant', 'TW', '', 'hak-Hant-TW', 'hak-Hant-TW'
FROM languages WHERE code = 'hak';
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 129, 'hak-Hant-TW_Zhaoan', id, 'Hant', 'TW', 'Zhaoan', '客語（詔安腔）', 'Hakka Chinese (Zhaoan)'
FROM languages WHERE code = 'hak';
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 131, 'hak-Hant-TW_Dapu', id, 'Hant', 'TW', 'Dapu', '客語（大埔腔）', 'Hakka Chinese (Dapu)'
FROM languages WHERE code = 'hak';
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 132, 'hak-Hant-TW_Jaoping', id, 'Hant', 'TW', 'Jaoping', '客語（饒平腔）', 'Hakka Chinese (Jaoping)'
FROM languages WHERE code = 'hak';
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 133, 'hak-Hant-TW_SouthernSixian', id, 'Hant', 'TW', 'SouthernSixian', '客語（南四縣腔）', 'Hakka Chinese (Southern Sixian)'
FROM languages WHERE code = 'hak';
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 134, 'hak-Hant-TW_Sixian', id, 'Hant', 'TW', 'Sixian', '客語（四縣腔）', 'Hakka Chinese (Sixian)'
FROM languages WHERE code = 'hak';
INSERT OR IGNORE INTO language_locales
  (id, code, language_id, script_code, region_code, place_path, name, name_en)
SELECT 135, 'hak-Hant-TW_Hailu', id, 'Hant', 'TW', 'Hailu', '客語（海陸腔）', 'Hakka Chinese (Hailu)'
FROM languages WHERE code = 'hak';