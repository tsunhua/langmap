-- Add Penang Hokkien (Southeast Asian Hokkien, Malaysia). Region MY already
-- exists in the live database; this seed only adds the locale.

INSERT OR IGNORE INTO regions (code, name_en, latitude, longitude)
VALUES ('MY', 'Malaysia', NULL, NULL);

INSERT INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('nan-Hant-MY_Penang', 'nan', 'Hant', 'MY', 'Penang', '福建話', 'Penang Hokkien', 'system-seed', 'seed:system-seed:1');
