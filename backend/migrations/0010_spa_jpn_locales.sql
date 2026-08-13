-- Bare representative locales for Spanish (spa) and Japanese (jpn), matching the
-- lang-script-region convention seeded for eng/cmn/nan in 0001/0009. Required so
-- the managed system-ui bundle can activate spa-Latn-ES / jpn-Jpan-JP ui_locales
-- and so seeded UI translations for those locales resolve.
--
-- Registry rows (languages/scripts/regions) are INSERT OR IGNORE because production
-- databases already seed them via the language-reference artifact; including them
-- here keeps the migration self-sufficient for any environment.

INSERT OR IGNORE INTO languages (code, name_en) VALUES
  ('spa', 'Spanish'),
  ('jpn', 'Japanese');

INSERT OR IGNORE INTO scripts (code, name_en, direction) VALUES
  ('Jpan', 'Japanese (alias for Han + Hiragana + Katakana)', 'ltr');

INSERT OR IGNORE INTO regions (code, name_en, latitude, longitude) VALUES
  ('ES', 'Spain', NULL, NULL),
  ('JP', 'Japan', 36.2, 138.3);

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('spa-Latn-ES', 'spa', 'Latn', 'ES', '', 'Español (España)', 'Spanish (Spain)', 'system-seed', 'seed:system-seed:1'),
  ('jpn-Jpan-JP', 'jpn', 'Jpan', 'JP', '', '日本語（日本）', 'Japanese (Japan)', 'system-seed', 'seed:system-seed:1');
