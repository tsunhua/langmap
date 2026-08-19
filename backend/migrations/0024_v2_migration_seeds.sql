-- 2026-08-19: V1→V2 遷移所需之 region/language/locale seeds
-- 新增 regions: HK, GB, IN, TZ
-- 新增 languages: yue, wuu, zha, ral, swh, x-image, x-emoji
-- 新增 language_locales: 對應 v1 遷移映射

INSERT OR IGNORE INTO regions (code, name_en, latitude, longitude) VALUES
  ('HK', 'Hong Kong', 22.3964, 114.109),
  ('GB', 'United Kingdom', 51.5074, -0.1278),
  ('IN', 'India', 20.5937, 78.9629),
  ('TZ', 'Tanzania', -6.369, 34.8888);

INSERT OR IGNORE INTO languages (code, name_en) VALUES
  ('yue', 'Yue Chinese'),
  ('wuu', 'Wu Chinese'),
  ('zha', 'Zhuang'),
  ('ral', 'Ralte'),
  ('swh', 'Swahili'),
  ('x-image', 'Image'),
  ('x-emoji', 'Emoji');

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, orthography, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('yue-Hant-HK', 'yue', 'Hant', NULL, 'HK', '', '廣東話', 'Cantonese', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('wuu-Hant-CN_Taizhou', 'wuu', 'Hant', NULL, 'CN', 'Taizhou', '台州話', 'Taizhou Wu', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('wuu-Hans-CN_Wenzhou', 'wuu', 'Hans', NULL, 'CN', 'Wenzhou', '温州话', 'Wenzhou Wu', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('zha-Latn-CN_Jingxi', 'zha', 'Latn', NULL, 'CN', 'Jingxi', '靖西壮语', 'Jingxi Zhuang', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('ral-Latn-IN', 'ral', 'Latn', NULL, 'IN', '', 'Ralte', 'Ralte', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('swh-Latn-TZ', 'swh', 'Latn', NULL, 'TZ', '', 'Kiswahili', 'Swahili', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('eng-Latn-GB', 'eng', 'Latn', NULL, 'GB', '', 'English', 'English (UK)', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Latn_Pehoeji-TW', 'nan', 'Latn', 'Pehoeji', 'TW', '', '白話字', 'POJ', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Latn_Tailo-TW', 'nan', 'Latn', 'Tailo', 'TW', '', '臺羅', 'Tailo', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Hant-CN_Chaozhou', 'nan', 'Hant', NULL, 'CN', 'Chaozhou', '潮州話', 'Chaozhou Hokkien', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Hant-CN_LufengJiazi', 'nan', 'Hant', NULL, 'CN', 'LufengJiazi', '陸豐甲子話', 'Lufeng Jiazi Hokkien', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('x-image-Latn-US', 'x-image', 'Latn', NULL, 'US', '', 'Image', 'Image', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('x-emoji-Latn-US', 'x-emoji', 'Latn', NULL, 'US', '', 'Emoji', 'Emoji', 'system-seed', 'seed:v1-migration:2026-08-19');
