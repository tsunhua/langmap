-- ⚠ Local dev only: managed by scripts/db (manage.py local rebuild).
-- Must stay equivalent to backend/migrations/ applied in order (AGENTS.md).

DROP TABLE IF EXISTS expressions_fts;
DROP TABLE IF EXISTS handbook_section_items;
DROP TABLE IF EXISTS handbook_sections;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expression_split_moves;
DROP TABLE IF EXISTS expression_splits;
DROP TABLE IF EXISTS expression_edges;
DROP TABLE IF EXISTS expression_readings;
DROP TABLE IF EXISTS user_preferences;
DROP TABLE IF EXISTS expression_locale_attestations;
DROP TABLE IF EXISTS expression_form_edge_features;
DROP TABLE IF EXISTS expression_form_edges;
DROP TABLE IF EXISTS morphological_features;
DROP TABLE IF EXISTS morphological_dimensions;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS ui_messages;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS language_locations;
DROP TABLE IF EXISTS language_profiles;
DROP TABLE IF EXISTS language_varieties;
DROP TABLE IF EXISTS language_subtags;
DROP TABLE IF EXISTS languoids;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS scripts;
DROP TABLE IF EXISTS languages;
DROP TABLE IF EXISTS language_locales;
DROP TABLE IF EXISTS sources;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

CREATE TABLE languages (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_expression_id TEXT REFERENCES expressions(id)
);

CREATE TABLE scripts (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_expression_id TEXT REFERENCES expressions(id),
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE regions (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_expression_id TEXT REFERENCES expressions(id),
    latitude REAL,
    longitude REAL,
    CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_scripts_code ON scripts(code);
CREATE INDEX idx_regions_code ON regions(code);

-- Language locale + sources tables (spec §7.2, §7.3).

CREATE TABLE sources (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('publication', 'url', 'system')),
  name TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (type, name),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE language_locales (
  code TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  script_code TEXT NOT NULL,
  orthography TEXT,
  region_code TEXT NOT NULL,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  name_expression_id TEXT REFERENCES expressions(id),
  latitude REAL,
  longitude REAL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, script_code, orthography, region_code, place_path),
  CHECK ((latitude IS NULL) = (longitude IS NULL)),
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (script_code) REFERENCES scripts(code),
  FOREIGN KEY (region_code) REFERENCES regions(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Expression identity + locale attestations (spec §8.4, §9.1).

CREATE TABLE expressions (
  id TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  text TEXT NOT NULL,
  text_hash TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  description TEXT NOT NULL DEFAULT '',
  tags_json TEXT NOT NULL DEFAULT '[]',
  source_id TEXT,
  source_ref TEXT,
  review_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending', 'approved', 'rejected')),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (lang_code, text, homograph_index),
  UNIQUE (lang_code, text_hash, homograph_index),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_expressions_created_at
  ON expressions(created_at DESC, id ASC);
CREATE INDEX idx_expressions_created_by_at
  ON expressions(created_by, created_at DESC, id ASC);

-- Registry seeds must follow the expressions table: languages and
-- language_locales reference expressions(id) for name_expression_id, and with
-- foreign_keys enabled a DML on a child table fails while the parent is absent.
-- schema.sql runs before scripts/language-reference/artifacts/language-reference.sql,
-- so the locale seeds below need these registry rows present to satisfy their FKs.
-- Values must match the generated artifact so INSERT OR IGNORE keeps final counts intact.

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-seed', 'system', 'LangMap system seeds');

INSERT OR IGNORE INTO languages (code, name_en) VALUES
  ('eng', 'English'),
  ('cmn', 'Mandarin Chinese'),
  ('nan', 'Min Nan Chinese (Hokkien)'),
  ('spa', 'Spanish'),
  ('jpn', 'Japanese'),
  ('yue', 'Yue Chinese'),
  ('wuu', 'Wu Chinese'),
  ('zha', 'Zhuang'),
  ('ral', 'Ralte'),
  ('swh', 'Swahili'),
  ('x-image', 'Image'),
  ('x-emoji', 'Emoji');

INSERT OR IGNORE INTO scripts (code, name_en, direction) VALUES
  ('Latn', 'Latin', 'ltr'),
  ('Hant', 'Han (Traditional variant)', 'ltr'),
  ('Hans', 'Han (Simplified variant)', 'ltr'),
  ('Jpan', 'Japanese (alias for Han + Hiragana + Katakana)', 'ltr');

INSERT OR IGNORE INTO regions (code, name_en, latitude, longitude) VALUES
  ('US', 'United States', 39.8, -98.6),
  ('TW', 'Taiwan, Province of China', 23.7, 121.0),
  ('CN', 'China', NULL, NULL),
  ('ES', 'Spain', NULL, NULL),
  ('JP', 'Japan', 36.2, 138.3),
  ('MY', 'Malaysia', NULL, NULL),
  ('HK', 'Hong Kong', 22.3964, 114.109),
  ('GB', 'United Kingdom', 51.5074, -0.1278),
  ('IN', 'India', 20.5937, 78.9629),
  ('TZ', 'Tanzania', -6.369, 34.8888);

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, orthography, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('eng-Latn-US', 'eng', 'Latn', NULL, 'US', '', 'English', 'English (US)', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hant-TW', 'cmn', 'Hant', NULL, 'TW', '', '華語', 'Taiwan Mandarin', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hans-CN', 'cmn', 'Hans', NULL, 'CN', '', '普通话', 'Simplified Chinese', 'system-seed', 'seed:system-seed:1'),
  ('nan-Hant-CN', 'nan', 'Hant', NULL, 'CN', '', '閩南語', 'Min Nan Chinese (Hokkien)', 'system-seed', 'seed:system-seed:1'),
  ('nan-Hans-CN', 'nan', 'Hans', NULL, 'CN', '', '闽南语', 'Min Nan Chinese (Hokkien)', 'system-seed', 'seed:system-seed:1'),
  ('nan-Hant-TW', 'nan', 'Hant', NULL, 'TW', '', '台語', 'Taiwanese Hokkien', 'system-seed', 'seed:system-seed:1'),
  ('nan-Hant-MY_Penang', 'nan', 'Hant', NULL, 'MY', 'Penang', '福建話', 'Penang Hokkien', 'system-seed', 'seed:system-seed:1'),
  ('spa-Latn-ES', 'spa', 'Latn', NULL, 'ES', '', 'Español', 'Spanish (Spain)', 'system-seed', 'seed:system-seed:1'),
  ('jpn-Jpan-JP', 'jpn', 'Jpan', NULL, 'JP', '', '日本語', 'Japanese (Japan)', 'system-seed', 'seed:system-seed:1'),
  ('yue-Hant-HK', 'yue', 'Hant', NULL, 'HK', '', '粵語', 'Cantonese', 'system-seed', 'seed:v1-migration:2026-08-19'),
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
  ('nan-Latn-CN_LufengJiazi', 'nan', 'Latn', NULL, 'CN', 'LufengJiazi', '陸豐甲子話（拉丁字）', 'Lufeng Jiazi Hokkien (Latin)', 'system-seed', 'seed:v1-migration:2026-08-20'),
  ('x-image-Latn-US', 'x-image', 'Latn', NULL, 'US', '', 'Image', 'Image', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('x-emoji-Latn-US', 'x-emoji', 'Latn', NULL, 'US', '', 'Emoji', 'Emoji', 'system-seed', 'seed:v1-migration:2026-08-19');

CREATE TABLE expression_locale_attestations (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (expression_id, language_locale_code),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Mapping edges + split audit tables (spec §10.1, §10.2).

CREATE TABLE expression_edges (
  id TEXT PRIMARY KEY,
  expression_a_id TEXT NOT NULL,
  expression_b_id TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_expression_edges_a_id ON expression_edges(expression_a_id);
CREATE INDEX idx_expression_edges_b_id ON expression_edges(expression_b_id);
CREATE INDEX idx_expression_edges_created_at
  ON expression_edges(created_at DESC, id ASC);
CREATE INDEX idx_expression_edges_score_feed
  ON expression_edges(score DESC, created_at DESC, id ASC);
CREATE INDEX idx_expression_edges_created_by_at
  ON expression_edges(created_by, created_at DESC, id ASC);

CREATE TABLE expression_splits (
  id TEXT PRIMARY KEY,
  source_expression_id TEXT NOT NULL,
  target_expression_id TEXT NOT NULL,
  created_by INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_split_moves (
  split_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  previous_a_id TEXT NOT NULL,
  previous_b_id TEXT NOT NULL,
  new_a_id TEXT NOT NULL,
  new_b_id TEXT NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id) REFERENCES expression_splits(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);

-- Morphological form-edge tables (spec §5.1, §5.2).

CREATE TABLE morphological_dimensions (
  code TEXT PRIMARY KEY,
  name_expression_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  UNIQUE (sort_order),
  FOREIGN KEY (name_expression_id) REFERENCES expressions(id)
);

CREATE TABLE morphological_features (
  code TEXT PRIMARY KEY,
  dimension_code TEXT NOT NULL,
  name_expression_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  UNIQUE (dimension_code, sort_order),
  FOREIGN KEY (dimension_code) REFERENCES morphological_dimensions(code),
  FOREIGN KEY (name_expression_id) REFERENCES expressions(id)
);

CREATE TABLE expression_form_edges (
  id TEXT PRIMARY KEY,
  form_id TEXT NOT NULL,
  lemma_id TEXT NOT NULL,
  pair_low TEXT NOT NULL,
  pair_high TEXT NOT NULL,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (form_id <> lemma_id),
  CHECK (pair_low < pair_high),
  UNIQUE (form_id, lemma_id),
  UNIQUE (pair_low, pair_high),
  FOREIGN KEY (form_id) REFERENCES expressions(id),
  FOREIGN KEY (lemma_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_form_edge_features (
  edge_id TEXT NOT NULL,
  feature_code TEXT NOT NULL,
  PRIMARY KEY (edge_id, feature_code),
  FOREIGN KEY (edge_id) REFERENCES expression_form_edges(id),
  FOREIGN KEY (feature_code) REFERENCES morphological_features(code)
);

CREATE INDEX idx_expression_form_edges_form_id ON expression_form_edges(form_id);
CREATE INDEX idx_expression_form_edges_lemma_id ON expression_form_edges(lemma_id);
CREATE INDEX idx_expression_form_edge_features_feature_code ON expression_form_edge_features(feature_code);

-- Morphological form-feature seed.
-- Generated by scripts/morphology/generate-form-feature-seed.py. Do not hand-edit hashes.
-- Spec: docs/superpowers/specs/2026-08-18-morphological-form-edges-design.md §6, §7.3

-- 1. Name expressions
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:c66jzruxv5b24p4jqx5jejmec4', 'cmn', 'て形', 'c66jzruxv5b24p4jqx5jejmec4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:2zy7u6a5mu7nylvnxwuasef6qu', 'cmn', '不定式', '2zy7u6a5mu7nylvnxwuasef6qu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:k5gohbnynxo4ytjnab6uxue6sa', 'cmn', '中性', 'k5gohbnynxo4ytjnab6uxue6sa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:bcsjwovwbktrk2x56mudce6ddm', 'cmn', '人称', 'bcsjwovwbktrk2x56mudce6ddm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:dkovaiw4i52hifjntk6usy42bq', 'cmn', '人称变体', 'dkovaiw4i52hifjntk6usy42bq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:24fojs3zea4utwkw5bjlpp7zcu', 'cmn', '人稱', '24fojs3zea4utwkw5bjlpp7zcu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:flgtrubcgfectvoytol3mzmbam', 'cmn', '人稱變體', 'flgtrubcgfectvoytol3mzmbam', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:2cgwmc354trdctpptwktwrwu7y', 'cmn', '体', '2cgwmc354trdctpptwktwrwu7y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:da5oimwndht4xgh5hxgwdytd6y', 'cmn', '使役', 'da5oimwndht4xgh5hxgwdytd6y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:vvse6hupvyupp5nh3rke4eczga', 'cmn', '动名词', 'vvse6hupvyupp5nh3rke4eczga', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:hod2yqtkawhh3mtbjdwc5bxicq', 'cmn', '動名詞', 'hod2yqtkawhh3mtbjdwc5bxicq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:lltftymz6m6vja3zxcd65nqsmi', 'cmn', '单数', 'lltftymz6m6vja3zxcd65nqsmi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:6tk45juy55v6re5ibbsq7c62cy', 'cmn', '可能形', '6tk45juy55v6re5ibbsq7c62cy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:aobeamvsioouy2737p7tvljvky', 'cmn', '否定', 'aobeamvsioouy2737p7tvljvky', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:lvsr2zmj3pqb4tphkx4buho7t4', 'cmn', '命令式', 'lvsr2zmj3pqb4tphkx4buho7t4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:uq6qhzypa366etd2opwzo3o4ye', 'cmn', '單數', 'uq6qhzypa366etd2opwzo3o4ye', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:xh5jzlt4cwo5ofxdp6zjrvby7y', 'cmn', '复数', 'xh5jzlt4cwo5ofxdp6zjrvby7y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:3mczuzrabtsiwos2u2ywujqz5u', 'cmn', '完成体', '3mczuzrabtsiwos2u2ywujqz5u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:x44jr6j4l6tf6pt7jvl2rx3c3u', 'cmn', '完成體', 'x44jr6j4l6tf6pt7jvl2rx3c3u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:cr3lwkvsv336z2niqx6osdtfm4', 'cmn', '将来时', 'cr3lwkvsv336z2niqx6osdtfm4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:6fjrrfdoi6qunbh34cpxf7oiii', 'cmn', '將來時', '6fjrrfdoi6qunbh34cpxf7oiii', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:lyogksg6s4jq7vb3i7mg3tid2e', 'cmn', '希望形', 'lyogksg6s4jq7vb3i7mg3tid2e', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:24x7bnmkhgofzo6yjc7ovakyae', 'cmn', '性', '24x7bnmkhgofzo6yjc7ovakyae', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:tmvyoxrf5k5hmi4amdqi5ofrje', 'cmn', '意志形', 'tmvyoxrf5k5hmi4amdqi5ofrje', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:erabvfpty3fj7mohw3ccd7jqky', 'cmn', '敬体', 'erabvfpty3fj7mohw3ccd7jqky', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:git4yi6unflukwnaclqkchre7m', 'cmn', '敬體', 'git4yi6unflukwnaclqkchre7m', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:vdpuaubpkw7mrczse54m7w4uyi', 'cmn', '数', 'vdpuaubpkw7mrczse54m7w4uyi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:7jkcip6as7u7ujej56xtrg5bei', 'cmn', '數', '7jkcip6as7u7ujej56xtrg5bei', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:7wmfzwl2bmqgvsopr2dk243jcu', 'cmn', '时态', '7wmfzwl2bmqgvsopr2dk243jcu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:73lso3ff5ionxazbocre662r5y', 'cmn', '時態', '73lso3ff5ionxazbocre662r5y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:4lgsvxy7qlo3zlttzrahimwidu', 'cmn', '最高級', '4lgsvxy7qlo3zlttzrahimwidu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:mk3zik3bbwikfcpa5ytpe3fy7y', 'cmn', '最高级', 'mk3zik3bbwikfcpa5ytpe3fy7y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:gidrdri32npdj6sozzecmdizsa', 'cmn', '未完成过去时', 'gidrdri32npdj6sozzecmdizsa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:hc5tkpbnsat7c723ze3qfbxsle', 'cmn', '未完成過去時', 'hc5tkpbnsat7c723ze3qfbxsle', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:pyoru3txba57ayytrynqop3rku', 'cmn', '条件式', 'pyoru3txba57ayytrynqop3rku', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:jrhqagkidupmlha6cyudxsjehy', 'cmn', '极性', 'jrhqagkidupmlha6cyudxsjehy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:a4p6ice3hahpjpefu35yeyhtq4', 'cmn', '构式', 'a4p6ice3hahpjpefu35yeyhtq4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:kkbeoujh7gdakkb5fos2xp67ri', 'cmn', '條件式', 'kkbeoujh7gdakkb5fos2xp67ri', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:d5fuu7ov5bt2njnc7txe45db2y', 'cmn', '極性', 'd5fuu7ov5bt2njnc7txe45db2y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:jzpdmcyixhdkluyf2ssbt3kfnu', 'cmn', '構式', 'jzpdmcyixhdkluyf2ssbt3kfnu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:dtq64a7rftpfskeuhv4oqi24cy', 'cmn', '比較級', 'dtq64a7rftpfskeuhv4oqi24cy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:dsprz75polhcc57ehw4paagw4q', 'cmn', '比较级', 'dsprz75polhcc57ehw4paagw4q', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:co5ud6hz266zgdaavf4twgsqey', 'cmn', '沃塞奥', 'co5ud6hz266zgdaavf4twgsqey', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:qr4uxbgrnw7izghwo6eztwxvfe', 'cmn', '沃塞奧', 'qr4uxbgrnw7izghwo6eztwxvfe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:zohopk5yik3ptg5k46ldabazvu', 'cmn', '现在时', 'zohopk5yik3ptg5k46ldabazvu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:5pm24e5xpovpdwoa4gxedfbyqa', 'cmn', '現在時', '5pm24e5xpovpdwoa4gxedfbyqa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:kblrpdh5idxy37vfvaeuo3o3ge', 'cmn', '直陈式', 'kblrpdh5idxy37vfvaeuo3o3ge', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:mqz6lkdopbshzcmpdbj4jkblhe', 'cmn', '直陳式', 'mqz6lkdopbshzcmpdbj4jkblhe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:efz2aip5oc4pr465kf4lgzitsu', 'cmn', '程度', 'efz2aip5oc4pr465kf4lgzitsu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:gizzz7ux7rzfiz56an5havffxy', 'cmn', '第一人称', 'gizzz7ux7rzfiz56an5havffxy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:dvkg324yzgrk4o32katpoaktia', 'cmn', '第一人稱', 'dvkg324yzgrk4o32katpoaktia', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:5sdjx4etnk2dsqophwni2qkciq', 'cmn', '第三人称', '5sdjx4etnk2dsqophwni2qkciq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:lnjsdly4l23oqsesb5gq3hdky4', 'cmn', '第三人稱', 'lnjsdly4l23oqsesb5gq3hdky4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:f6jg4ndqlpll5ebk2rpa23sbq4', 'cmn', '第二人称', 'f6jg4ndqlpll5ebk2rpa23sbq4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:ttk5sz3fjm62t554v5o444zqma', 'cmn', '第二人稱', 'ttk5sz3fjm62t554v5o444zqma', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:6mdianzhbhrfk7vb77ydm3bcpa', 'cmn', '虚拟式', '6mdianzhbhrfk7vb77ydm3bcpa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:edog6g5uiagz6vmkjln3l7pfv4', 'cmn', '虛擬式', 'edog6g5uiagz6vmkjln3l7pfv4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:aegiejchbuoygbipqofgdm2pia', 'cmn', '被动', 'aegiejchbuoygbipqofgdm2pia', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:gcqsvfnatqtvc7bkrcla456mu4', 'cmn', '被動', 'gcqsvfnatqtvc7bkrcla456mu4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:7rsmcklq3fwz2k3itnoc2r7gbu', 'cmn', '複數', '7rsmcklq3fwz2k3itnoc2r7gbu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:koyyh4lppt6atra42osn3myrsi', 'cmn', '語態', 'koyyh4lppt6atra42osn3myrsi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:lkgd4ivzly7eek6wrvaaq4y3qy', 'cmn', '語氣', 'lkgd4ivzly7eek6wrvaaq4y3qy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:p2rrfrbzpbl3y5iznrnu5lua44', 'cmn', '语态', 'p2rrfrbzpbl3y5iznrnu5lua44', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:wetyk3idrqdmyrh3iajqr7jooq', 'cmn', '语气', 'wetyk3idrqdmyrh3iajqr7jooq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:ixuhg7sgmogjbc6bddkbhm7tty', 'cmn', '过去分词', 'ixuhg7sgmogjbc6bddkbhm7tty', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:5nmk3haj5up6eqsb4ip7ibrkpq', 'cmn', '过去时', '5nmk3haj5up6eqsb4ip7ibrkpq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:fqyry4nwxhlaghulct5ife5hty', 'cmn', '进行体', 'fqyry4nwxhlaghulct5ife5hty', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:ulqkgcmxcf6zt6nuoj4x3xtlai', 'cmn', '進行體', 'ulqkgcmxcf6zt6nuoj4x3xtlai', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:pnldvmffu6pxfwpzd4qfbdzm7i', 'cmn', '過去分詞', 'pnldvmffu6pxfwpzd4qfbdzm7i', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:wor6jxshqlugbxvdeiyf4wrdxu', 'cmn', '過去時', 'wor6jxshqlugbxvdeiyf4wrdxu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:cihwazqg67meiwcfy6k74ewoei', 'cmn', '阳性', 'cihwazqg67meiwcfy6k74ewoei', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:5ancrep2vrwbo56pjphwikxuyi', 'cmn', '阴性', '5ancrep2vrwbo56pjphwikxuyi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:7d2r2rckpdynrp46lsfxbux7oi', 'cmn', '陰性', '7d2r2rckpdynrp46lsfxbux7oi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:gyi6ycde35t4en2f4pqduo6wlq', 'cmn', '陽性', 'gyi6ycde35t4en2f4pqduo6wlq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:f7xh54vqwc3e43aavx2q5exhxi', 'cmn', '非限定', 'f7xh54vqwc3e43aavx2q5exhxi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:2ryf36l6eam3lle3n4fchorfhe', 'cmn', '體', '2ryf36l6eam3lle3n4fchorfhe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:xwf7j4piyyxlc2w7ghx7pdzeky', 'eng', 'aspect', 'xwf7j4piyyxlc2w7ghx7pdzeky', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:753uwfpsgddx2ve6jdkfclgv5q', 'eng', 'causative', '753uwfpsgddx2ve6jdkfclgv5q', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:hasdtzxrxkwwsypa6uyw7m3gqi', 'eng', 'comparative', 'hasdtzxrxkwwsypa6uyw7m3gqi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:neu23lufdwcsf7gmzqongbmrde', 'eng', 'conditional', 'neu23lufdwcsf7gmzqongbmrde', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:pia232slriiijj5oxv7tevqibq', 'eng', 'construction', 'pia232slriiijj5oxv7tevqibq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:wmekp5b3xkhhuntloj2dfk4j64', 'eng', 'degree', 'wmekp5b3xkhhuntloj2dfk4j64', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:4xyzqfiheklogf4z5ft5d6nrby', 'eng', 'desiderative', '4xyzqfiheklogf4z5ft5d6nrby', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:lbfgrgfquwtbgh2o2hemqctxhu', 'eng', 'feminine', 'lbfgrgfquwtbgh2o2hemqctxhu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:zeg6ovhnorp3rbf6ox7ay3ivme', 'eng', 'first person', 'zeg6ovhnorp3rbf6ox7ay3ivme', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:5oz55cr5tjadmyjs5no6wwxujy', 'eng', 'future', '5oz55cr5tjadmyjs5no6wwxujy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:32p6v2ulm333u5eel3s7yflm3u', 'eng', 'gender', '32p6v2ulm333u5eel3s7yflm3u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:atnubdh2tfwp6232oqbfqf3upe', 'eng', 'gerund', 'atnubdh2tfwp6232oqbfqf3upe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:45zv7btefyxqaukllttb7op3yi', 'eng', 'imperative', '45zv7btefyxqaukllttb7op3yi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:a2ichma3h4bunfhgo7sqwp3pe4', 'eng', 'imperfect', 'a2ichma3h4bunfhgo7sqwp3pe4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:wifnbn2owvyvjwtlgjpq6ua5py', 'eng', 'indicative', 'wifnbn2owvyvjwtlgjpq6ua5py', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:ppmx7j4pesoxdhsjrkcukmojku', 'eng', 'infinitive', 'ppmx7j4pesoxdhsjrkcukmojku', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:waompmfgaewzmcxugv5b4j7s2e', 'eng', 'masculine', 'waompmfgaewzmcxugv5b4j7s2e', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:5yhe6me4tjdtc7jtis23zus5zm', 'eng', 'mood', '5yhe6me4tjdtc7jtis23zus5zm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:bhyesunpjtkqhb3ycx6tb6mohi', 'eng', 'negative', 'bhyesunpjtkqhb3ycx6tb6mohi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:32nygmumnjbv7vibww4frr6dse', 'eng', 'neuter', '32nygmumnjbv7vibww4frr6dse', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:cgatpi36ldhaqziawy6ieert3y', 'eng', 'non-finite', 'cgatpi36ldhaqziawy6ieert3y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:ckeg7hiaavnn6jgeav46eljrwi', 'eng', 'number', 'ckeg7hiaavnn6jgeav46eljrwi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:u7y5ppbbetpmydv7kr3i67v2bu', 'eng', 'passive', 'u7y5ppbbetpmydv7kr3i67v2bu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:qtgn7cuet754tdj2rjf7wcmz5u', 'eng', 'past', 'qtgn7cuet754tdj2rjf7wcmz5u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:pqfd3gfynco4jghxjongbrrkhe', 'eng', 'past participle', 'pqfd3gfynco4jghxjongbrrkhe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:7l7jp5666mulxvhra543sys2ri', 'eng', 'perfect', '7l7jp5666mulxvhra543sys2ri', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:hcub5b7hsyy6mav7l66ta7hc7q', 'eng', 'person', 'hcub5b7hsyy6mav7l66ta7hc7q', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:7kflfosiukcfqgoykqads5mfeq', 'eng', 'person variant', '7kflfosiukcfqgoykqads5mfeq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:mhkyzps3vuyeeyypka635kp2cu', 'eng', 'plural', 'mhkyzps3vuyeeyypka635kp2cu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:shebcvreljr747knbe6phxxfq4', 'eng', 'polarity', 'shebcvreljr747knbe6phxxfq4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:zljkqdpujy5l6j5xzrgcux4tfa', 'eng', 'polite', 'zljkqdpujy5l6j5xzrgcux4tfa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:ai4m3ife5ckcojo3fofsbxzpua', 'eng', 'politeness', 'ai4m3ife5ckcojo3fofsbxzpua', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:qg3lfsduw6dwidx2cqm6yjmeym', 'eng', 'potential', 'qg3lfsduw6dwidx2cqm6yjmeym', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:jvgh53rofdidzmw36ppwhhbssa', 'eng', 'present', 'jvgh53rofdidzmw36ppwhhbssa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 'eng', 'progressive', 'w7ad4nfyt2cbvrd4tbdcfvvrdm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:mzhdh2gtcxyrrg5opxlyvh54ue', 'eng', 'second person', 'mzhdh2gtcxyrrg5opxlyvh54ue', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:fuh6l3el6gavgwqpomvhbmag4u', 'eng', 'singular', 'fuh6l3el6gavgwqpomvhbmag4u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:2qutsxm4dt5lehrykmbvrg3lqi', 'eng', 'subjunctive', '2qutsxm4dt5lehrykmbvrg3lqi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:wntaq5qkvelmsg7mzsg5nuhywy', 'eng', 'superlative', 'wntaq5qkvelmsg7mzsg5nuhywy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:qrahsuwggsdsrryv6osjmydcva', 'eng', 'te-form', 'qrahsuwggsdsrryv6osjmydcva', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:324myjpqcqu5mjqfurbthk5chy', 'eng', 'tense', '324myjpqcqu5mjqfurbthk5chy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:5xo4wa56n2sotovvyl46coxbli', 'eng', 'third person', '5xo4wa56n2sotovvyl46coxbli', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 'eng', 'voice', 'yv6x5eqbs4elmfgjb6rwqxgwiq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:vb3b6iico6bxk7tzq3ydd3yw2a', 'eng', 'volitional', 'vb3b6iico6bxk7tzq3ydd3yw2a', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:mv6gf7grgchiywwhez2ihsqjhi', 'eng', 'voseo', 'mv6gf7grgchiywwhez2ihsqjhi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:c66jzruxv5b24p4jqx5jejmec4', 'jpn', 'て形', 'c66jzruxv5b24p4jqx5jejmec4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:k7f3vljozlsa6jcuzo4uel3aau', 'jpn', 'ボセオ', 'k7f3vljozlsa6jcuzo4uel3aau', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:qxf7entcjnubku7ttgkgvtiaa4', 'jpn', '一人称', 'qxf7entcjnubku7ttgkgvtiaa4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:7e4nwrdtovrtbydeujqw6tj7py', 'jpn', '丁寧', '7e4nwrdtovrtbydeujqw6tj7py', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:d4kttnmlnvfci4vs5etyijgqmy', 'jpn', '三人称', 'd4kttnmlnvfci4vs5etyijgqmy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:a3c72frqqtomfxyrnofitcqnde', 'jpn', '不定詞', 'a3c72frqqtomfxyrnofitcqnde', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:k5gohbnynxo4ytjnab6uxue6sa', 'jpn', '中性', 'k5gohbnynxo4ytjnab6uxue6sa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:hjieg2ww3mlc66rtesegjc5wrm', 'jpn', '二人称', 'hjieg2ww3mlc66rtesegjc5wrm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:bcsjwovwbktrk2x56mudce6ddm', 'jpn', '人称', 'bcsjwovwbktrk2x56mudce6ddm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:i2fnbahbgzviwdiad3sawrkbym', 'jpn', '人称の変異', 'i2fnbahbgzviwdiad3sawrkbym', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:da5oimwndht4xgh5hxgwdytd6y', 'jpn', '使役', 'da5oimwndht4xgh5hxgwdytd6y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:hod2yqtkawhh3mtbjdwc5bxicq', 'jpn', '動名詞', 'hod2yqtkawhh3mtbjdwc5bxicq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:62xdg7uypqxg7xp45quf6rbvt4', 'jpn', '単数', '62xdg7uypqxg7xp45quf6rbvt4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:it5acm4lzj7bkb4r5a7lnjsmtu', 'jpn', '受身', 'it5acm4lzj7bkb4r5a7lnjsmtu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:6tk45juy55v6re5ibbsq7c62cy', 'jpn', '可能形', '6tk45juy55v6re5ibbsq7c62cy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:aobeamvsioouy2737p7tvljvky', 'jpn', '否定', 'aobeamvsioouy2737p7tvljvky', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:pi7fevx6kyz5g7uagbzbn7dy5i', 'jpn', '命令法', 'pi7fevx6kyz5g7uagbzbn7dy5i', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:nj772e5y77mnmxazdgl3ona67u', 'jpn', '女性', 'nj772e5y77mnmxazdgl3ona67u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:caywhfcuamxsplxdjuknq3pudq', 'jpn', '完了', 'caywhfcuamxsplxdjuknq3pudq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:lyogksg6s4jq7vb3i7mg3tid2e', 'jpn', '希望形', 'lyogksg6s4jq7vb3i7mg3tid2e', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:24x7bnmkhgofzo6yjc7ovakyae', 'jpn', '性', '24x7bnmkhgofzo6yjc7ovakyae', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:7ncsq6vobui62w6quj7n7hvoze', 'jpn', '意向形', '7ncsq6vobui62w6quj7n7hvoze', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:ycttytuyfkl6ocnvu452njuhpi', 'jpn', '態', 'ycttytuyfkl6ocnvu452njuhpi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:l4jfbt5fn3hfcfjeqixkgr5x2a', 'jpn', '接続法', 'l4jfbt5fn3hfcfjeqixkgr5x2a', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:vdpuaubpkw7mrczse54m7w4uyi', 'jpn', '数', 'vdpuaubpkw7mrczse54m7w4uyi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:d2j272jyfwch3eak7kfmvttfwi', 'jpn', '時制', 'd2j272jyfwch3eak7kfmvttfwi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:r2t3fv37ejghztr5z5iyldnnva', 'jpn', '最上級', 'r2t3fv37ejghztr5z5iyldnnva', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:rvpa3zhmbrrnqum7lhy5ijgapa', 'jpn', '未完了過去', 'rvpa3zhmbrrnqum7lhy5ijgapa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:dwqwkup7t4o5vhumkuaiihclji', 'jpn', '未来', 'dwqwkup7t4o5vhumkuaiihclji', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:gzcwqgg4zqypsyvpmbxyu5uiwe', 'jpn', '条件法', 'gzcwqgg4zqypsyvpmbxyu5uiwe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:d5fuu7ov5bt2njnc7txe45db2y', 'jpn', '極性', 'd5fuu7ov5bt2njnc7txe45db2y', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:dtq64a7rftpfskeuhv4oqi24cy', 'jpn', '比較級', 'dtq64a7rftpfskeuhv4oqi24cy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:zaxaimnu4uy7lgjitx7u4qbpqu', 'jpn', '法', 'zaxaimnu4uy7lgjitx7u4qbpqu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:7nkjaitlaf6jjhqpfbx2k5zise', 'jpn', '活用形', '7nkjaitlaf6jjhqpfbx2k5zise', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:qoxn3u3vfbmaw4h45bi4qpbmye', 'jpn', '現在', 'qoxn3u3vfbmaw4h45bi4qpbmye', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:f7ngwv6ikx4r5fqen3ucvyue2e', 'jpn', '男性', 'f7ngwv6ikx4r5fqen3ucvyue2e', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:jnejsoqelogwmt76r2t3e6g7pm', 'jpn', '直説法', 'jnejsoqelogwmt76r2t3e6g7pm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:rg7vv2xblbkoximss4xl4vlr44', 'jpn', '相', 'rg7vv2xblbkoximss4xl4vlr44', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:efz2aip5oc4pr465kf4lgzitsu', 'jpn', '程度', 'efz2aip5oc4pr465kf4lgzitsu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:vxh7jdjpyo7pzk5pw55oq6eski', 'jpn', '複数', 'vxh7jdjpyo7pzk5pw55oq6eski', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:cnfhjhl4ivbsmnrs2opyulmf6e', 'jpn', '進行形', 'cnfhjhl4ivbsmnrs2opyulmf6e', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:hfeo4pa7rnh6ho6bxazwonkyju', 'jpn', '過去', 'hfeo4pa7rnh6ho6bxazwonkyju', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:pnldvmffu6pxfwpzd4qfbdzm7i', 'jpn', '過去分詞', 'pnldvmffu6pxfwpzd4qfbdzm7i', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:mpsbythkeclgxmmbwrnc7hblza', 'jpn', '非定形', 'mpsbythkeclgxmmbwrnc7hblza', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:7k2b4s4jmsfwo76bm76khxmzfa', 'spa', 'aspecto', '7k2b4s4jmsfwo76bm76khxmzfa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:thhgzshyyxs4ydz55qnpabrcn4', 'spa', 'causativo', 'thhgzshyyxs4ydz55qnpabrcn4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:nxe5zwddyhgdvannx2aws5h6f4', 'spa', 'comparativo', 'nxe5zwddyhgdvannx2aws5h6f4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:3z7ptvrlbafcribicpisqvk5w4', 'spa', 'condicional', '3z7ptvrlbafcribicpisqvk5w4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:7jdj3efc7wc3lged2rexkqvcju', 'spa', 'construcción', '7jdj3efc7wc3lged2rexkqvcju', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:etq6uigppdrvkzmkrlzjkx5bxe', 'spa', 'cortesía', 'etq6uigppdrvkzmkrlzjkx5bxe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:mzsgezbbynmk3w5h5ys7swjjie', 'spa', 'cortés', 'mzsgezbbynmk3w5h5ys7swjjie', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:4tvkptwv2nsj5c6ri3gy2k4y2u', 'spa', 'desiderativo', '4tvkptwv2nsj5c6ri3gy2k4y2u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:6gjj7wviiy2srbnwdlktn25i5u', 'spa', 'femenino', '6gjj7wviiy2srbnwdlktn25i5u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:6pdgm6q7txl3akavgtterizqhy', 'spa', 'forma te', '6pdgm6q7txl3akavgtterizqhy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:6fz6dfp3j2fy3jmlv43vgi3xki', 'spa', 'futuro', '6fz6dfp3j2fy3jmlv43vgi3xki', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:o7bcwsdmneav7eircbj7qxfwfa', 'spa', 'gerundio', 'o7bcwsdmneav7eircbj7qxfwfa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:ueedje6pkusl4uo2drci2fhgdy', 'spa', 'grado', 'ueedje6pkusl4uo2drci2fhgdy', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:w2vaif22daj2ctxbj4tkbrad7m', 'spa', 'género', 'w2vaif22daj2ctxbj4tkbrad7m', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:jegkillvrydfnf7d6a4zlz7wi4', 'spa', 'imperativo', 'jegkillvrydfnf7d6a4zlz7wi4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:rofygqttmu5g3tkyul7b7r4tnu', 'spa', 'imperfecto', 'rofygqttmu5g3tkyul7b7r4tnu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:wcndbpyz46bgqpiz3bb2rknzwa', 'spa', 'indicativo', 'wcndbpyz46bgqpiz3bb2rknzwa', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:w7iqepal6txv4zm636loj5c5le', 'spa', 'infinitivo', 'w7iqepal6txv4zm636loj5c5le', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:flat3lzfk2h5bgxv4tedrhdjhq', 'spa', 'masculino', 'flat3lzfk2h5bgxv4tedrhdjhq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:asuszk2rwp2ekrj2xxd3ogfu5q', 'spa', 'modo', 'asuszk2rwp2ekrj2xxd3ogfu5q', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:tinahathlrholguoozhlwfdywm', 'spa', 'negativo', 'tinahathlrholguoozhlwfdywm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:yvvtytayq7vwdvjnam4thf4f6u', 'spa', 'neutro', 'yvvtytayq7vwdvjnam4thf4f6u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:jz3tr2gk4oslqgl45uzdzghpx4', 'spa', 'no finito', 'jz3tr2gk4oslqgl45uzdzghpx4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:qsdru5qlec24gozn5shuyaeyhm', 'spa', 'número', 'qsdru5qlec24gozn5shuyaeyhm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:ml3tt2bjxaessevpz6siiup42q', 'spa', 'participio', 'ml3tt2bjxaessevpz6siiup42q', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:xl6q3ogtiop72cjypoblwhj2r4', 'spa', 'pasivo', 'xl6q3ogtiop72cjypoblwhj2r4', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:44cyx33k5jgr24gr7kggbhgh5a', 'spa', 'perfecto', '44cyx33k5jgr24gr7kggbhgh5a', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:l2avfbv4uwkekszjd45qguhmei', 'spa', 'persona', 'l2avfbv4uwkekszjd45qguhmei', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:mhkyzps3vuyeeyypka635kp2cu', 'spa', 'plural', 'mhkyzps3vuyeeyypka635kp2cu', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:verl66hhj2ygpqknazd5dq2vkm', 'spa', 'polaridad', 'verl66hhj2ygpqknazd5dq2vkm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:hucics3fsazkw5en45dqdntj24', 'spa', 'potencial', 'hucics3fsazkw5en45dqdntj24', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:suelbqpf3u523owcyrfbxlzgcq', 'spa', 'presente', 'suelbqpf3u523owcyrfbxlzgcq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:cvwikz7iic5eng2dgrtjqae22i', 'spa', 'pretérito', 'cvwikz7iic5eng2dgrtjqae22i', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:r5nmq3bzvth6ahexdwsrjmg2my', 'spa', 'primera persona', 'r5nmq3bzvth6ahexdwsrjmg2my', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:lfml2glesbfbfwtd4jbl5k3kdm', 'spa', 'progresivo', 'lfml2glesbfbfwtd4jbl5k3kdm', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:itfqt3z5ve6bu2jecaa3zg43ra', 'spa', 'segunda persona', 'itfqt3z5ve6bu2jecaa3zg43ra', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:fuh6l3el6gavgwqpomvhbmag4u', 'spa', 'singular', 'fuh6l3el6gavgwqpomvhbmag4u', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:ni552wtosnywadr6izxzjy3qwi', 'spa', 'subjuntivo', 'ni552wtosnywadr6izxzjy3qwi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:4qewfx6v73lgcvmemcngulsbxe', 'spa', 'superlativo', '4qewfx6v73lgcvmemcngulsbxe', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:tyg6j7fx2fty6ehflfllfdxmye', 'spa', 'tercera persona', 'tyg6j7fx2fty6ehflfllfdxmye', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:mzvj6z3bp6pzvqto7rx2qcph3i', 'spa', 'tiempo', 'mzvj6z3bp6pzvqto7rx2qcph3i', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:bqauzm4pmzpvijbvxsotnrjxju', 'spa', 'variante de persona', 'bqauzm4pmzpvijbvxsotnrjxju', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:iev7egb2lutc6laegry6pmacym', 'spa', 'volitivo', 'iev7egb2lutc6laegry6pmacym', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:mv6gf7grgchiywwhez2ihsqjhi', 'spa', 'voseo', 'mv6gf7grgchiywwhez2ihsqjhi', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:gfy7272slvdygdd2n6qmi4gbui', 'spa', 'voz', 'gfy7272slvdygdd2n6qmi4gbui', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn', '肯定', 'p4egshpg447re5bxiwwnnwxy6a', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'eng', 'positive', 'v6totkz2yzlu2uhgwvtu2xtwzq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:p4egshpg447re5bxiwwnnwxy6a', 'jpn', '肯定', 'p4egshpg447re5bxiwwnnwxy6a', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:hx77yb5rwmqekcrr3tkqrm7skq', 'spa', 'positivo', 'hx77yb5rwmqekcrr3tkqrm7skq', 1, '', '[]', NULL, NULL, 'approved', NULL);

-- 2. Locale attestations
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:24x7bnmkhgofzo6yjc7ovakyae', 'cmn:24x7bnmkhgofzo6yjc7ovakyae', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:2cgwmc354trdctpptwktwrwu7y', 'cmn:2cgwmc354trdctpptwktwrwu7y', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:2zy7u6a5mu7nylvnxwuasef6qu', 'cmn:2zy7u6a5mu7nylvnxwuasef6qu', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:3mczuzrabtsiwos2u2ywujqz5u', 'cmn:3mczuzrabtsiwos2u2ywujqz5u', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:5ancrep2vrwbo56pjphwikxuyi', 'cmn:5ancrep2vrwbo56pjphwikxuyi', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:5nmk3haj5up6eqsb4ip7ibrkpq', 'cmn:5nmk3haj5up6eqsb4ip7ibrkpq', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:5sdjx4etnk2dsqophwni2qkciq', 'cmn:5sdjx4etnk2dsqophwni2qkciq', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:6mdianzhbhrfk7vb77ydm3bcpa', 'cmn:6mdianzhbhrfk7vb77ydm3bcpa', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:6tk45juy55v6re5ibbsq7c62cy', 'cmn:6tk45juy55v6re5ibbsq7c62cy', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:7wmfzwl2bmqgvsopr2dk243jcu', 'cmn:7wmfzwl2bmqgvsopr2dk243jcu', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:a4p6ice3hahpjpefu35yeyhtq4', 'cmn:a4p6ice3hahpjpefu35yeyhtq4', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:aegiejchbuoygbipqofgdm2pia', 'cmn:aegiejchbuoygbipqofgdm2pia', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:aobeamvsioouy2737p7tvljvky', 'cmn:aobeamvsioouy2737p7tvljvky', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:bcsjwovwbktrk2x56mudce6ddm', 'cmn:bcsjwovwbktrk2x56mudce6ddm', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:c66jzruxv5b24p4jqx5jejmec4', 'cmn:c66jzruxv5b24p4jqx5jejmec4', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:cihwazqg67meiwcfy6k74ewoei', 'cmn:cihwazqg67meiwcfy6k74ewoei', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:co5ud6hz266zgdaavf4twgsqey', 'cmn:co5ud6hz266zgdaavf4twgsqey', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:cr3lwkvsv336z2niqx6osdtfm4', 'cmn:cr3lwkvsv336z2niqx6osdtfm4', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:da5oimwndht4xgh5hxgwdytd6y', 'cmn:da5oimwndht4xgh5hxgwdytd6y', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:dkovaiw4i52hifjntk6usy42bq', 'cmn:dkovaiw4i52hifjntk6usy42bq', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:dsprz75polhcc57ehw4paagw4q', 'cmn:dsprz75polhcc57ehw4paagw4q', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:efz2aip5oc4pr465kf4lgzitsu', 'cmn:efz2aip5oc4pr465kf4lgzitsu', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:erabvfpty3fj7mohw3ccd7jqky', 'cmn:erabvfpty3fj7mohw3ccd7jqky', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:f6jg4ndqlpll5ebk2rpa23sbq4', 'cmn:f6jg4ndqlpll5ebk2rpa23sbq4', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:f7xh54vqwc3e43aavx2q5exhxi', 'cmn:f7xh54vqwc3e43aavx2q5exhxi', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:fqyry4nwxhlaghulct5ife5hty', 'cmn:fqyry4nwxhlaghulct5ife5hty', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:gidrdri32npdj6sozzecmdizsa', 'cmn:gidrdri32npdj6sozzecmdizsa', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:gizzz7ux7rzfiz56an5havffxy', 'cmn:gizzz7ux7rzfiz56an5havffxy', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:ixuhg7sgmogjbc6bddkbhm7tty', 'cmn:ixuhg7sgmogjbc6bddkbhm7tty', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:jrhqagkidupmlha6cyudxsjehy', 'cmn:jrhqagkidupmlha6cyudxsjehy', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:k5gohbnynxo4ytjnab6uxue6sa', 'cmn:k5gohbnynxo4ytjnab6uxue6sa', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:kblrpdh5idxy37vfvaeuo3o3ge', 'cmn:kblrpdh5idxy37vfvaeuo3o3ge', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:lltftymz6m6vja3zxcd65nqsmi', 'cmn:lltftymz6m6vja3zxcd65nqsmi', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:lvsr2zmj3pqb4tphkx4buho7t4', 'cmn:lvsr2zmj3pqb4tphkx4buho7t4', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:lyogksg6s4jq7vb3i7mg3tid2e', 'cmn:lyogksg6s4jq7vb3i7mg3tid2e', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:mk3zik3bbwikfcpa5ytpe3fy7y', 'cmn:mk3zik3bbwikfcpa5ytpe3fy7y', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:p2rrfrbzpbl3y5iznrnu5lua44', 'cmn:p2rrfrbzpbl3y5iznrnu5lua44', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:pyoru3txba57ayytrynqop3rku', 'cmn:pyoru3txba57ayytrynqop3rku', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:tmvyoxrf5k5hmi4amdqi5ofrje', 'cmn:tmvyoxrf5k5hmi4amdqi5ofrje', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:vdpuaubpkw7mrczse54m7w4uyi', 'cmn:vdpuaubpkw7mrczse54m7w4uyi', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:vvse6hupvyupp5nh3rke4eczga', 'cmn:vvse6hupvyupp5nh3rke4eczga', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:wetyk3idrqdmyrh3iajqr7jooq', 'cmn:wetyk3idrqdmyrh3iajqr7jooq', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:xh5jzlt4cwo5ofxdp6zjrvby7y', 'cmn:xh5jzlt4cwo5ofxdp6zjrvby7y', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:zohopk5yik3ptg5k46ldabazvu', 'cmn:zohopk5yik3ptg5k46ldabazvu', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:24fojs3zea4utwkw5bjlpp7zcu', 'cmn:24fojs3zea4utwkw5bjlpp7zcu', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:24x7bnmkhgofzo6yjc7ovakyae', 'cmn:24x7bnmkhgofzo6yjc7ovakyae', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:2ryf36l6eam3lle3n4fchorfhe', 'cmn:2ryf36l6eam3lle3n4fchorfhe', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:2zy7u6a5mu7nylvnxwuasef6qu', 'cmn:2zy7u6a5mu7nylvnxwuasef6qu', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:4lgsvxy7qlo3zlttzrahimwidu', 'cmn:4lgsvxy7qlo3zlttzrahimwidu', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:5pm24e5xpovpdwoa4gxedfbyqa', 'cmn:5pm24e5xpovpdwoa4gxedfbyqa', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:6fjrrfdoi6qunbh34cpxf7oiii', 'cmn:6fjrrfdoi6qunbh34cpxf7oiii', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:6tk45juy55v6re5ibbsq7c62cy', 'cmn:6tk45juy55v6re5ibbsq7c62cy', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:73lso3ff5ionxazbocre662r5y', 'cmn:73lso3ff5ionxazbocre662r5y', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:7d2r2rckpdynrp46lsfxbux7oi', 'cmn:7d2r2rckpdynrp46lsfxbux7oi', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:7jkcip6as7u7ujej56xtrg5bei', 'cmn:7jkcip6as7u7ujej56xtrg5bei', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:7rsmcklq3fwz2k3itnoc2r7gbu', 'cmn:7rsmcklq3fwz2k3itnoc2r7gbu', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:aobeamvsioouy2737p7tvljvky', 'cmn:aobeamvsioouy2737p7tvljvky', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:c66jzruxv5b24p4jqx5jejmec4', 'cmn:c66jzruxv5b24p4jqx5jejmec4', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:d5fuu7ov5bt2njnc7txe45db2y', 'cmn:d5fuu7ov5bt2njnc7txe45db2y', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:da5oimwndht4xgh5hxgwdytd6y', 'cmn:da5oimwndht4xgh5hxgwdytd6y', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:dtq64a7rftpfskeuhv4oqi24cy', 'cmn:dtq64a7rftpfskeuhv4oqi24cy', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:dvkg324yzgrk4o32katpoaktia', 'cmn:dvkg324yzgrk4o32katpoaktia', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:edog6g5uiagz6vmkjln3l7pfv4', 'cmn:edog6g5uiagz6vmkjln3l7pfv4', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:efz2aip5oc4pr465kf4lgzitsu', 'cmn:efz2aip5oc4pr465kf4lgzitsu', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:f7xh54vqwc3e43aavx2q5exhxi', 'cmn:f7xh54vqwc3e43aavx2q5exhxi', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:flgtrubcgfectvoytol3mzmbam', 'cmn:flgtrubcgfectvoytol3mzmbam', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:gcqsvfnatqtvc7bkrcla456mu4', 'cmn:gcqsvfnatqtvc7bkrcla456mu4', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:git4yi6unflukwnaclqkchre7m', 'cmn:git4yi6unflukwnaclqkchre7m', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:gyi6ycde35t4en2f4pqduo6wlq', 'cmn:gyi6ycde35t4en2f4pqduo6wlq', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:hc5tkpbnsat7c723ze3qfbxsle', 'cmn:hc5tkpbnsat7c723ze3qfbxsle', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:hod2yqtkawhh3mtbjdwc5bxicq', 'cmn:hod2yqtkawhh3mtbjdwc5bxicq', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:jzpdmcyixhdkluyf2ssbt3kfnu', 'cmn:jzpdmcyixhdkluyf2ssbt3kfnu', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:k5gohbnynxo4ytjnab6uxue6sa', 'cmn:k5gohbnynxo4ytjnab6uxue6sa', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:kkbeoujh7gdakkb5fos2xp67ri', 'cmn:kkbeoujh7gdakkb5fos2xp67ri', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:koyyh4lppt6atra42osn3myrsi', 'cmn:koyyh4lppt6atra42osn3myrsi', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:lkgd4ivzly7eek6wrvaaq4y3qy', 'cmn:lkgd4ivzly7eek6wrvaaq4y3qy', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:lnjsdly4l23oqsesb5gq3hdky4', 'cmn:lnjsdly4l23oqsesb5gq3hdky4', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:lvsr2zmj3pqb4tphkx4buho7t4', 'cmn:lvsr2zmj3pqb4tphkx4buho7t4', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:lyogksg6s4jq7vb3i7mg3tid2e', 'cmn:lyogksg6s4jq7vb3i7mg3tid2e', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:mqz6lkdopbshzcmpdbj4jkblhe', 'cmn:mqz6lkdopbshzcmpdbj4jkblhe', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:pnldvmffu6pxfwpzd4qfbdzm7i', 'cmn:pnldvmffu6pxfwpzd4qfbdzm7i', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:qr4uxbgrnw7izghwo6eztwxvfe', 'cmn:qr4uxbgrnw7izghwo6eztwxvfe', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:tmvyoxrf5k5hmi4amdqi5ofrje', 'cmn:tmvyoxrf5k5hmi4amdqi5ofrje', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:ttk5sz3fjm62t554v5o444zqma', 'cmn:ttk5sz3fjm62t554v5o444zqma', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:ulqkgcmxcf6zt6nuoj4x3xtlai', 'cmn:ulqkgcmxcf6zt6nuoj4x3xtlai', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:uq6qhzypa366etd2opwzo3o4ye', 'cmn:uq6qhzypa366etd2opwzo3o4ye', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:wor6jxshqlugbxvdeiyf4wrdxu', 'cmn:wor6jxshqlugbxvdeiyf4wrdxu', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:x44jr6j4l6tf6pt7jvl2rx3c3u', 'cmn:x44jr6j4l6tf6pt7jvl2rx3c3u', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:2qutsxm4dt5lehrykmbvrg3lqi', 'eng:2qutsxm4dt5lehrykmbvrg3lqi', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:324myjpqcqu5mjqfurbthk5chy', 'eng:324myjpqcqu5mjqfurbthk5chy', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:32nygmumnjbv7vibww4frr6dse', 'eng:32nygmumnjbv7vibww4frr6dse', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:32p6v2ulm333u5eel3s7yflm3u', 'eng:32p6v2ulm333u5eel3s7yflm3u', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:45zv7btefyxqaukllttb7op3yi', 'eng:45zv7btefyxqaukllttb7op3yi', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:4xyzqfiheklogf4z5ft5d6nrby', 'eng:4xyzqfiheklogf4z5ft5d6nrby', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:5oz55cr5tjadmyjs5no6wwxujy', 'eng:5oz55cr5tjadmyjs5no6wwxujy', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:5xo4wa56n2sotovvyl46coxbli', 'eng:5xo4wa56n2sotovvyl46coxbli', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:5yhe6me4tjdtc7jtis23zus5zm', 'eng:5yhe6me4tjdtc7jtis23zus5zm', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:753uwfpsgddx2ve6jdkfclgv5q', 'eng:753uwfpsgddx2ve6jdkfclgv5q', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:7kflfosiukcfqgoykqads5mfeq', 'eng:7kflfosiukcfqgoykqads5mfeq', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:7l7jp5666mulxvhra543sys2ri', 'eng:7l7jp5666mulxvhra543sys2ri', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:a2ichma3h4bunfhgo7sqwp3pe4', 'eng:a2ichma3h4bunfhgo7sqwp3pe4', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:ai4m3ife5ckcojo3fofsbxzpua', 'eng:ai4m3ife5ckcojo3fofsbxzpua', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:atnubdh2tfwp6232oqbfqf3upe', 'eng:atnubdh2tfwp6232oqbfqf3upe', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:bhyesunpjtkqhb3ycx6tb6mohi', 'eng:bhyesunpjtkqhb3ycx6tb6mohi', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:cgatpi36ldhaqziawy6ieert3y', 'eng:cgatpi36ldhaqziawy6ieert3y', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:ckeg7hiaavnn6jgeav46eljrwi', 'eng:ckeg7hiaavnn6jgeav46eljrwi', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:fuh6l3el6gavgwqpomvhbmag4u', 'eng:fuh6l3el6gavgwqpomvhbmag4u', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:hasdtzxrxkwwsypa6uyw7m3gqi', 'eng:hasdtzxrxkwwsypa6uyw7m3gqi', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:hcub5b7hsyy6mav7l66ta7hc7q', 'eng:hcub5b7hsyy6mav7l66ta7hc7q', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:jvgh53rofdidzmw36ppwhhbssa', 'eng:jvgh53rofdidzmw36ppwhhbssa', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:lbfgrgfquwtbgh2o2hemqctxhu', 'eng:lbfgrgfquwtbgh2o2hemqctxhu', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:mhkyzps3vuyeeyypka635kp2cu', 'eng:mhkyzps3vuyeeyypka635kp2cu', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:mv6gf7grgchiywwhez2ihsqjhi', 'eng:mv6gf7grgchiywwhez2ihsqjhi', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:mzhdh2gtcxyrrg5opxlyvh54ue', 'eng:mzhdh2gtcxyrrg5opxlyvh54ue', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:neu23lufdwcsf7gmzqongbmrde', 'eng:neu23lufdwcsf7gmzqongbmrde', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:pia232slriiijj5oxv7tevqibq', 'eng:pia232slriiijj5oxv7tevqibq', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:ppmx7j4pesoxdhsjrkcukmojku', 'eng:ppmx7j4pesoxdhsjrkcukmojku', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:pqfd3gfynco4jghxjongbrrkhe', 'eng:pqfd3gfynco4jghxjongbrrkhe', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:qg3lfsduw6dwidx2cqm6yjmeym', 'eng:qg3lfsduw6dwidx2cqm6yjmeym', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:qrahsuwggsdsrryv6osjmydcva', 'eng:qrahsuwggsdsrryv6osjmydcva', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:qtgn7cuet754tdj2rjf7wcmz5u', 'eng:qtgn7cuet754tdj2rjf7wcmz5u', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:shebcvreljr747knbe6phxxfq4', 'eng:shebcvreljr747knbe6phxxfq4', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:u7y5ppbbetpmydv7kr3i67v2bu', 'eng:u7y5ppbbetpmydv7kr3i67v2bu', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:vb3b6iico6bxk7tzq3ydd3yw2a', 'eng:vb3b6iico6bxk7tzq3ydd3yw2a', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 'eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:waompmfgaewzmcxugv5b4j7s2e', 'eng:waompmfgaewzmcxugv5b4j7s2e', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:wifnbn2owvyvjwtlgjpq6ua5py', 'eng:wifnbn2owvyvjwtlgjpq6ua5py', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:wmekp5b3xkhhuntloj2dfk4j64', 'eng:wmekp5b3xkhhuntloj2dfk4j64', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:wntaq5qkvelmsg7mzsg5nuhywy', 'eng:wntaq5qkvelmsg7mzsg5nuhywy', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:xwf7j4piyyxlc2w7ghx7pdzeky', 'eng:xwf7j4piyyxlc2w7ghx7pdzeky', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 'eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:zeg6ovhnorp3rbf6ox7ay3ivme', 'eng:zeg6ovhnorp3rbf6ox7ay3ivme', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:zljkqdpujy5l6j5xzrgcux4tfa', 'eng:zljkqdpujy5l6j5xzrgcux4tfa', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:24x7bnmkhgofzo6yjc7ovakyae', 'jpn:24x7bnmkhgofzo6yjc7ovakyae', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:62xdg7uypqxg7xp45quf6rbvt4', 'jpn:62xdg7uypqxg7xp45quf6rbvt4', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:6tk45juy55v6re5ibbsq7c62cy', 'jpn:6tk45juy55v6re5ibbsq7c62cy', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:7e4nwrdtovrtbydeujqw6tj7py', 'jpn:7e4nwrdtovrtbydeujqw6tj7py', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:7ncsq6vobui62w6quj7n7hvoze', 'jpn:7ncsq6vobui62w6quj7n7hvoze', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:7nkjaitlaf6jjhqpfbx2k5zise', 'jpn:7nkjaitlaf6jjhqpfbx2k5zise', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:a3c72frqqtomfxyrnofitcqnde', 'jpn:a3c72frqqtomfxyrnofitcqnde', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:aobeamvsioouy2737p7tvljvky', 'jpn:aobeamvsioouy2737p7tvljvky', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:bcsjwovwbktrk2x56mudce6ddm', 'jpn:bcsjwovwbktrk2x56mudce6ddm', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:c66jzruxv5b24p4jqx5jejmec4', 'jpn:c66jzruxv5b24p4jqx5jejmec4', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:caywhfcuamxsplxdjuknq3pudq', 'jpn:caywhfcuamxsplxdjuknq3pudq', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:cnfhjhl4ivbsmnrs2opyulmf6e', 'jpn:cnfhjhl4ivbsmnrs2opyulmf6e', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:d2j272jyfwch3eak7kfmvttfwi', 'jpn:d2j272jyfwch3eak7kfmvttfwi', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:d4kttnmlnvfci4vs5etyijgqmy', 'jpn:d4kttnmlnvfci4vs5etyijgqmy', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:d5fuu7ov5bt2njnc7txe45db2y', 'jpn:d5fuu7ov5bt2njnc7txe45db2y', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:da5oimwndht4xgh5hxgwdytd6y', 'jpn:da5oimwndht4xgh5hxgwdytd6y', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:dtq64a7rftpfskeuhv4oqi24cy', 'jpn:dtq64a7rftpfskeuhv4oqi24cy', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:dwqwkup7t4o5vhumkuaiihclji', 'jpn:dwqwkup7t4o5vhumkuaiihclji', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:efz2aip5oc4pr465kf4lgzitsu', 'jpn:efz2aip5oc4pr465kf4lgzitsu', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:f7ngwv6ikx4r5fqen3ucvyue2e', 'jpn:f7ngwv6ikx4r5fqen3ucvyue2e', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:gzcwqgg4zqypsyvpmbxyu5uiwe', 'jpn:gzcwqgg4zqypsyvpmbxyu5uiwe', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:hfeo4pa7rnh6ho6bxazwonkyju', 'jpn:hfeo4pa7rnh6ho6bxazwonkyju', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:hjieg2ww3mlc66rtesegjc5wrm', 'jpn:hjieg2ww3mlc66rtesegjc5wrm', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:hod2yqtkawhh3mtbjdwc5bxicq', 'jpn:hod2yqtkawhh3mtbjdwc5bxicq', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:i2fnbahbgzviwdiad3sawrkbym', 'jpn:i2fnbahbgzviwdiad3sawrkbym', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:it5acm4lzj7bkb4r5a7lnjsmtu', 'jpn:it5acm4lzj7bkb4r5a7lnjsmtu', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:jnejsoqelogwmt76r2t3e6g7pm', 'jpn:jnejsoqelogwmt76r2t3e6g7pm', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:k5gohbnynxo4ytjnab6uxue6sa', 'jpn:k5gohbnynxo4ytjnab6uxue6sa', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:k7f3vljozlsa6jcuzo4uel3aau', 'jpn:k7f3vljozlsa6jcuzo4uel3aau', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:l4jfbt5fn3hfcfjeqixkgr5x2a', 'jpn:l4jfbt5fn3hfcfjeqixkgr5x2a', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:lyogksg6s4jq7vb3i7mg3tid2e', 'jpn:lyogksg6s4jq7vb3i7mg3tid2e', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:mpsbythkeclgxmmbwrnc7hblza', 'jpn:mpsbythkeclgxmmbwrnc7hblza', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:nj772e5y77mnmxazdgl3ona67u', 'jpn:nj772e5y77mnmxazdgl3ona67u', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:pi7fevx6kyz5g7uagbzbn7dy5i', 'jpn:pi7fevx6kyz5g7uagbzbn7dy5i', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:pnldvmffu6pxfwpzd4qfbdzm7i', 'jpn:pnldvmffu6pxfwpzd4qfbdzm7i', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:qoxn3u3vfbmaw4h45bi4qpbmye', 'jpn:qoxn3u3vfbmaw4h45bi4qpbmye', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:qxf7entcjnubku7ttgkgvtiaa4', 'jpn:qxf7entcjnubku7ttgkgvtiaa4', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:r2t3fv37ejghztr5z5iyldnnva', 'jpn:r2t3fv37ejghztr5z5iyldnnva', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:rg7vv2xblbkoximss4xl4vlr44', 'jpn:rg7vv2xblbkoximss4xl4vlr44', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:rvpa3zhmbrrnqum7lhy5ijgapa', 'jpn:rvpa3zhmbrrnqum7lhy5ijgapa', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:vdpuaubpkw7mrczse54m7w4uyi', 'jpn:vdpuaubpkw7mrczse54m7w4uyi', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:vxh7jdjpyo7pzk5pw55oq6eski', 'jpn:vxh7jdjpyo7pzk5pw55oq6eski', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:ycttytuyfkl6ocnvu452njuhpi', 'jpn:ycttytuyfkl6ocnvu452njuhpi', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:zaxaimnu4uy7lgjitx7u4qbpqu', 'jpn:zaxaimnu4uy7lgjitx7u4qbpqu', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:3z7ptvrlbafcribicpisqvk5w4', 'spa:3z7ptvrlbafcribicpisqvk5w4', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:44cyx33k5jgr24gr7kggbhgh5a', 'spa:44cyx33k5jgr24gr7kggbhgh5a', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:4qewfx6v73lgcvmemcngulsbxe', 'spa:4qewfx6v73lgcvmemcngulsbxe', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:4tvkptwv2nsj5c6ri3gy2k4y2u', 'spa:4tvkptwv2nsj5c6ri3gy2k4y2u', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:6fz6dfp3j2fy3jmlv43vgi3xki', 'spa:6fz6dfp3j2fy3jmlv43vgi3xki', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:6gjj7wviiy2srbnwdlktn25i5u', 'spa:6gjj7wviiy2srbnwdlktn25i5u', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:6pdgm6q7txl3akavgtterizqhy', 'spa:6pdgm6q7txl3akavgtterizqhy', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:7jdj3efc7wc3lged2rexkqvcju', 'spa:7jdj3efc7wc3lged2rexkqvcju', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:7k2b4s4jmsfwo76bm76khxmzfa', 'spa:7k2b4s4jmsfwo76bm76khxmzfa', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:asuszk2rwp2ekrj2xxd3ogfu5q', 'spa:asuszk2rwp2ekrj2xxd3ogfu5q', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:bqauzm4pmzpvijbvxsotnrjxju', 'spa:bqauzm4pmzpvijbvxsotnrjxju', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:cvwikz7iic5eng2dgrtjqae22i', 'spa:cvwikz7iic5eng2dgrtjqae22i', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:etq6uigppdrvkzmkrlzjkx5bxe', 'spa:etq6uigppdrvkzmkrlzjkx5bxe', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:flat3lzfk2h5bgxv4tedrhdjhq', 'spa:flat3lzfk2h5bgxv4tedrhdjhq', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:fuh6l3el6gavgwqpomvhbmag4u', 'spa:fuh6l3el6gavgwqpomvhbmag4u', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:gfy7272slvdygdd2n6qmi4gbui', 'spa:gfy7272slvdygdd2n6qmi4gbui', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:hucics3fsazkw5en45dqdntj24', 'spa:hucics3fsazkw5en45dqdntj24', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:iev7egb2lutc6laegry6pmacym', 'spa:iev7egb2lutc6laegry6pmacym', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:itfqt3z5ve6bu2jecaa3zg43ra', 'spa:itfqt3z5ve6bu2jecaa3zg43ra', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:jegkillvrydfnf7d6a4zlz7wi4', 'spa:jegkillvrydfnf7d6a4zlz7wi4', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:jz3tr2gk4oslqgl45uzdzghpx4', 'spa:jz3tr2gk4oslqgl45uzdzghpx4', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:l2avfbv4uwkekszjd45qguhmei', 'spa:l2avfbv4uwkekszjd45qguhmei', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:lfml2glesbfbfwtd4jbl5k3kdm', 'spa:lfml2glesbfbfwtd4jbl5k3kdm', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:mhkyzps3vuyeeyypka635kp2cu', 'spa:mhkyzps3vuyeeyypka635kp2cu', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:ml3tt2bjxaessevpz6siiup42q', 'spa:ml3tt2bjxaessevpz6siiup42q', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:mv6gf7grgchiywwhez2ihsqjhi', 'spa:mv6gf7grgchiywwhez2ihsqjhi', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:mzsgezbbynmk3w5h5ys7swjjie', 'spa:mzsgezbbynmk3w5h5ys7swjjie', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:mzvj6z3bp6pzvqto7rx2qcph3i', 'spa:mzvj6z3bp6pzvqto7rx2qcph3i', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:ni552wtosnywadr6izxzjy3qwi', 'spa:ni552wtosnywadr6izxzjy3qwi', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:nxe5zwddyhgdvannx2aws5h6f4', 'spa:nxe5zwddyhgdvannx2aws5h6f4', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:o7bcwsdmneav7eircbj7qxfwfa', 'spa:o7bcwsdmneav7eircbj7qxfwfa', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:qsdru5qlec24gozn5shuyaeyhm', 'spa:qsdru5qlec24gozn5shuyaeyhm', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:r5nmq3bzvth6ahexdwsrjmg2my', 'spa:r5nmq3bzvth6ahexdwsrjmg2my', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:rofygqttmu5g3tkyul7b7r4tnu', 'spa:rofygqttmu5g3tkyul7b7r4tnu', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:suelbqpf3u523owcyrfbxlzgcq', 'spa:suelbqpf3u523owcyrfbxlzgcq', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:thhgzshyyxs4ydz55qnpabrcn4', 'spa:thhgzshyyxs4ydz55qnpabrcn4', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:tinahathlrholguoozhlwfdywm', 'spa:tinahathlrholguoozhlwfdywm', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:tyg6j7fx2fty6ehflfllfdxmye', 'spa:tyg6j7fx2fty6ehflfllfdxmye', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:ueedje6pkusl4uo2drci2fhgdy', 'spa:ueedje6pkusl4uo2drci2fhgdy', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:verl66hhj2ygpqknazd5dq2vkm', 'spa:verl66hhj2ygpqknazd5dq2vkm', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:w2vaif22daj2ctxbj4tkbrad7m', 'spa:w2vaif22daj2ctxbj4tkbrad7m', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:w7iqepal6txv4zm636loj5c5le', 'spa:w7iqepal6txv4zm636loj5c5le', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:wcndbpyz46bgqpiz3bb2rknzwa', 'spa:wcndbpyz46bgqpiz3bb2rknzwa', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:xl6q3ogtiop72cjypoblwhj2r4', 'spa:xl6q3ogtiop72cjypoblwhj2r4', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:yvvtytayq7vwdvjnam4thf4f6u', 'spa:yvvtytayq7vwdvjnam4thf4f6u', 'spa-Latn-ES', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:p4egshpg447re5bxiwwnnwxy6a', 'jpn:p4egshpg447re5bxiwwnnwxy6a', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:hx77yb5rwmqekcrr3tkqrm7skq', 'spa:hx77yb5rwmqekcrr3tkqrm7skq', 'spa-Latn-ES', NULL, NULL, NULL);

-- 3. Translation edges (source=seed)
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:24fojs3zea4utwkw5bjlpp7zcu:eng:hcub5b7hsyy6mav7l66ta7hc7q', 'cmn:24fojs3zea4utwkw5bjlpp7zcu', 'eng:hcub5b7hsyy6mav7l66ta7hc7q', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:24x7bnmkhgofzo6yjc7ovakyae:eng:32p6v2ulm333u5eel3s7yflm3u', 'cmn:24x7bnmkhgofzo6yjc7ovakyae', 'eng:32p6v2ulm333u5eel3s7yflm3u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:2cgwmc354trdctpptwktwrwu7y:eng:xwf7j4piyyxlc2w7ghx7pdzeky', 'cmn:2cgwmc354trdctpptwktwrwu7y', 'eng:xwf7j4piyyxlc2w7ghx7pdzeky', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:2ryf36l6eam3lle3n4fchorfhe:eng:xwf7j4piyyxlc2w7ghx7pdzeky', 'cmn:2ryf36l6eam3lle3n4fchorfhe', 'eng:xwf7j4piyyxlc2w7ghx7pdzeky', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:2zy7u6a5mu7nylvnxwuasef6qu:eng:ppmx7j4pesoxdhsjrkcukmojku', 'cmn:2zy7u6a5mu7nylvnxwuasef6qu', 'eng:ppmx7j4pesoxdhsjrkcukmojku', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:3mczuzrabtsiwos2u2ywujqz5u:eng:7l7jp5666mulxvhra543sys2ri', 'cmn:3mczuzrabtsiwos2u2ywujqz5u', 'eng:7l7jp5666mulxvhra543sys2ri', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:4lgsvxy7qlo3zlttzrahimwidu:eng:wntaq5qkvelmsg7mzsg5nuhywy', 'cmn:4lgsvxy7qlo3zlttzrahimwidu', 'eng:wntaq5qkvelmsg7mzsg5nuhywy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:5ancrep2vrwbo56pjphwikxuyi:eng:lbfgrgfquwtbgh2o2hemqctxhu', 'cmn:5ancrep2vrwbo56pjphwikxuyi', 'eng:lbfgrgfquwtbgh2o2hemqctxhu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:5nmk3haj5up6eqsb4ip7ibrkpq:eng:qtgn7cuet754tdj2rjf7wcmz5u', 'cmn:5nmk3haj5up6eqsb4ip7ibrkpq', 'eng:qtgn7cuet754tdj2rjf7wcmz5u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:5pm24e5xpovpdwoa4gxedfbyqa:eng:jvgh53rofdidzmw36ppwhhbssa', 'cmn:5pm24e5xpovpdwoa4gxedfbyqa', 'eng:jvgh53rofdidzmw36ppwhhbssa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:5sdjx4etnk2dsqophwni2qkciq:eng:5xo4wa56n2sotovvyl46coxbli', 'cmn:5sdjx4etnk2dsqophwni2qkciq', 'eng:5xo4wa56n2sotovvyl46coxbli', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:6fjrrfdoi6qunbh34cpxf7oiii:eng:5oz55cr5tjadmyjs5no6wwxujy', 'cmn:6fjrrfdoi6qunbh34cpxf7oiii', 'eng:5oz55cr5tjadmyjs5no6wwxujy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:6mdianzhbhrfk7vb77ydm3bcpa:eng:2qutsxm4dt5lehrykmbvrg3lqi', 'cmn:6mdianzhbhrfk7vb77ydm3bcpa', 'eng:2qutsxm4dt5lehrykmbvrg3lqi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:6tk45juy55v6re5ibbsq7c62cy:eng:qg3lfsduw6dwidx2cqm6yjmeym', 'cmn:6tk45juy55v6re5ibbsq7c62cy', 'eng:qg3lfsduw6dwidx2cqm6yjmeym', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:73lso3ff5ionxazbocre662r5y:eng:324myjpqcqu5mjqfurbthk5chy', 'cmn:73lso3ff5ionxazbocre662r5y', 'eng:324myjpqcqu5mjqfurbthk5chy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:7d2r2rckpdynrp46lsfxbux7oi:eng:lbfgrgfquwtbgh2o2hemqctxhu', 'cmn:7d2r2rckpdynrp46lsfxbux7oi', 'eng:lbfgrgfquwtbgh2o2hemqctxhu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:7jkcip6as7u7ujej56xtrg5bei:eng:ckeg7hiaavnn6jgeav46eljrwi', 'cmn:7jkcip6as7u7ujej56xtrg5bei', 'eng:ckeg7hiaavnn6jgeav46eljrwi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:7rsmcklq3fwz2k3itnoc2r7gbu:eng:mhkyzps3vuyeeyypka635kp2cu', 'cmn:7rsmcklq3fwz2k3itnoc2r7gbu', 'eng:mhkyzps3vuyeeyypka635kp2cu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:7wmfzwl2bmqgvsopr2dk243jcu:eng:324myjpqcqu5mjqfurbthk5chy', 'cmn:7wmfzwl2bmqgvsopr2dk243jcu', 'eng:324myjpqcqu5mjqfurbthk5chy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:a4p6ice3hahpjpefu35yeyhtq4:eng:pia232slriiijj5oxv7tevqibq', 'cmn:a4p6ice3hahpjpefu35yeyhtq4', 'eng:pia232slriiijj5oxv7tevqibq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:aegiejchbuoygbipqofgdm2pia:eng:u7y5ppbbetpmydv7kr3i67v2bu', 'cmn:aegiejchbuoygbipqofgdm2pia', 'eng:u7y5ppbbetpmydv7kr3i67v2bu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:aobeamvsioouy2737p7tvljvky:eng:bhyesunpjtkqhb3ycx6tb6mohi', 'cmn:aobeamvsioouy2737p7tvljvky', 'eng:bhyesunpjtkqhb3ycx6tb6mohi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:bcsjwovwbktrk2x56mudce6ddm:eng:hcub5b7hsyy6mav7l66ta7hc7q', 'cmn:bcsjwovwbktrk2x56mudce6ddm', 'eng:hcub5b7hsyy6mav7l66ta7hc7q', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:c66jzruxv5b24p4jqx5jejmec4:eng:qrahsuwggsdsrryv6osjmydcva', 'cmn:c66jzruxv5b24p4jqx5jejmec4', 'eng:qrahsuwggsdsrryv6osjmydcva', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:cihwazqg67meiwcfy6k74ewoei:eng:waompmfgaewzmcxugv5b4j7s2e', 'cmn:cihwazqg67meiwcfy6k74ewoei', 'eng:waompmfgaewzmcxugv5b4j7s2e', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:co5ud6hz266zgdaavf4twgsqey:eng:mv6gf7grgchiywwhez2ihsqjhi', 'cmn:co5ud6hz266zgdaavf4twgsqey', 'eng:mv6gf7grgchiywwhez2ihsqjhi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:cr3lwkvsv336z2niqx6osdtfm4:eng:5oz55cr5tjadmyjs5no6wwxujy', 'cmn:cr3lwkvsv336z2niqx6osdtfm4', 'eng:5oz55cr5tjadmyjs5no6wwxujy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:d5fuu7ov5bt2njnc7txe45db2y:eng:shebcvreljr747knbe6phxxfq4', 'cmn:d5fuu7ov5bt2njnc7txe45db2y', 'eng:shebcvreljr747knbe6phxxfq4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:da5oimwndht4xgh5hxgwdytd6y:eng:753uwfpsgddx2ve6jdkfclgv5q', 'cmn:da5oimwndht4xgh5hxgwdytd6y', 'eng:753uwfpsgddx2ve6jdkfclgv5q', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:dkovaiw4i52hifjntk6usy42bq:eng:7kflfosiukcfqgoykqads5mfeq', 'cmn:dkovaiw4i52hifjntk6usy42bq', 'eng:7kflfosiukcfqgoykqads5mfeq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:dsprz75polhcc57ehw4paagw4q:eng:hasdtzxrxkwwsypa6uyw7m3gqi', 'cmn:dsprz75polhcc57ehw4paagw4q', 'eng:hasdtzxrxkwwsypa6uyw7m3gqi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:dtq64a7rftpfskeuhv4oqi24cy:eng:hasdtzxrxkwwsypa6uyw7m3gqi', 'cmn:dtq64a7rftpfskeuhv4oqi24cy', 'eng:hasdtzxrxkwwsypa6uyw7m3gqi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:dvkg324yzgrk4o32katpoaktia:eng:zeg6ovhnorp3rbf6ox7ay3ivme', 'cmn:dvkg324yzgrk4o32katpoaktia', 'eng:zeg6ovhnorp3rbf6ox7ay3ivme', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:edog6g5uiagz6vmkjln3l7pfv4:eng:2qutsxm4dt5lehrykmbvrg3lqi', 'cmn:edog6g5uiagz6vmkjln3l7pfv4', 'eng:2qutsxm4dt5lehrykmbvrg3lqi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:efz2aip5oc4pr465kf4lgzitsu:eng:wmekp5b3xkhhuntloj2dfk4j64', 'cmn:efz2aip5oc4pr465kf4lgzitsu', 'eng:wmekp5b3xkhhuntloj2dfk4j64', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:erabvfpty3fj7mohw3ccd7jqky:eng:ai4m3ife5ckcojo3fofsbxzpua', 'cmn:erabvfpty3fj7mohw3ccd7jqky', 'eng:ai4m3ife5ckcojo3fofsbxzpua', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:erabvfpty3fj7mohw3ccd7jqky:eng:zljkqdpujy5l6j5xzrgcux4tfa', 'cmn:erabvfpty3fj7mohw3ccd7jqky', 'eng:zljkqdpujy5l6j5xzrgcux4tfa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:f6jg4ndqlpll5ebk2rpa23sbq4:eng:mzhdh2gtcxyrrg5opxlyvh54ue', 'cmn:f6jg4ndqlpll5ebk2rpa23sbq4', 'eng:mzhdh2gtcxyrrg5opxlyvh54ue', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:f7xh54vqwc3e43aavx2q5exhxi:eng:cgatpi36ldhaqziawy6ieert3y', 'cmn:f7xh54vqwc3e43aavx2q5exhxi', 'eng:cgatpi36ldhaqziawy6ieert3y', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:flgtrubcgfectvoytol3mzmbam:eng:7kflfosiukcfqgoykqads5mfeq', 'cmn:flgtrubcgfectvoytol3mzmbam', 'eng:7kflfosiukcfqgoykqads5mfeq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:fqyry4nwxhlaghulct5ife5hty:eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 'cmn:fqyry4nwxhlaghulct5ife5hty', 'eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:gcqsvfnatqtvc7bkrcla456mu4:eng:u7y5ppbbetpmydv7kr3i67v2bu', 'cmn:gcqsvfnatqtvc7bkrcla456mu4', 'eng:u7y5ppbbetpmydv7kr3i67v2bu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:gidrdri32npdj6sozzecmdizsa:eng:a2ichma3h4bunfhgo7sqwp3pe4', 'cmn:gidrdri32npdj6sozzecmdizsa', 'eng:a2ichma3h4bunfhgo7sqwp3pe4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:git4yi6unflukwnaclqkchre7m:eng:ai4m3ife5ckcojo3fofsbxzpua', 'cmn:git4yi6unflukwnaclqkchre7m', 'eng:ai4m3ife5ckcojo3fofsbxzpua', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:git4yi6unflukwnaclqkchre7m:eng:zljkqdpujy5l6j5xzrgcux4tfa', 'cmn:git4yi6unflukwnaclqkchre7m', 'eng:zljkqdpujy5l6j5xzrgcux4tfa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:gizzz7ux7rzfiz56an5havffxy:eng:zeg6ovhnorp3rbf6ox7ay3ivme', 'cmn:gizzz7ux7rzfiz56an5havffxy', 'eng:zeg6ovhnorp3rbf6ox7ay3ivme', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:gyi6ycde35t4en2f4pqduo6wlq:eng:waompmfgaewzmcxugv5b4j7s2e', 'cmn:gyi6ycde35t4en2f4pqduo6wlq', 'eng:waompmfgaewzmcxugv5b4j7s2e', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:hc5tkpbnsat7c723ze3qfbxsle:eng:a2ichma3h4bunfhgo7sqwp3pe4', 'cmn:hc5tkpbnsat7c723ze3qfbxsle', 'eng:a2ichma3h4bunfhgo7sqwp3pe4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:hod2yqtkawhh3mtbjdwc5bxicq:eng:atnubdh2tfwp6232oqbfqf3upe', 'cmn:hod2yqtkawhh3mtbjdwc5bxicq', 'eng:atnubdh2tfwp6232oqbfqf3upe', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:ixuhg7sgmogjbc6bddkbhm7tty:eng:pqfd3gfynco4jghxjongbrrkhe', 'cmn:ixuhg7sgmogjbc6bddkbhm7tty', 'eng:pqfd3gfynco4jghxjongbrrkhe', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:jrhqagkidupmlha6cyudxsjehy:eng:shebcvreljr747knbe6phxxfq4', 'cmn:jrhqagkidupmlha6cyudxsjehy', 'eng:shebcvreljr747knbe6phxxfq4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:jzpdmcyixhdkluyf2ssbt3kfnu:eng:pia232slriiijj5oxv7tevqibq', 'cmn:jzpdmcyixhdkluyf2ssbt3kfnu', 'eng:pia232slriiijj5oxv7tevqibq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:k5gohbnynxo4ytjnab6uxue6sa:eng:32nygmumnjbv7vibww4frr6dse', 'cmn:k5gohbnynxo4ytjnab6uxue6sa', 'eng:32nygmumnjbv7vibww4frr6dse', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:kblrpdh5idxy37vfvaeuo3o3ge:eng:wifnbn2owvyvjwtlgjpq6ua5py', 'cmn:kblrpdh5idxy37vfvaeuo3o3ge', 'eng:wifnbn2owvyvjwtlgjpq6ua5py', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:kkbeoujh7gdakkb5fos2xp67ri:eng:neu23lufdwcsf7gmzqongbmrde', 'cmn:kkbeoujh7gdakkb5fos2xp67ri', 'eng:neu23lufdwcsf7gmzqongbmrde', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:koyyh4lppt6atra42osn3myrsi:eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 'cmn:koyyh4lppt6atra42osn3myrsi', 'eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:lkgd4ivzly7eek6wrvaaq4y3qy:eng:5yhe6me4tjdtc7jtis23zus5zm', 'cmn:lkgd4ivzly7eek6wrvaaq4y3qy', 'eng:5yhe6me4tjdtc7jtis23zus5zm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:lltftymz6m6vja3zxcd65nqsmi:eng:fuh6l3el6gavgwqpomvhbmag4u', 'cmn:lltftymz6m6vja3zxcd65nqsmi', 'eng:fuh6l3el6gavgwqpomvhbmag4u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:lnjsdly4l23oqsesb5gq3hdky4:eng:5xo4wa56n2sotovvyl46coxbli', 'cmn:lnjsdly4l23oqsesb5gq3hdky4', 'eng:5xo4wa56n2sotovvyl46coxbli', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:lvsr2zmj3pqb4tphkx4buho7t4:eng:45zv7btefyxqaukllttb7op3yi', 'cmn:lvsr2zmj3pqb4tphkx4buho7t4', 'eng:45zv7btefyxqaukllttb7op3yi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:lyogksg6s4jq7vb3i7mg3tid2e:eng:4xyzqfiheklogf4z5ft5d6nrby', 'cmn:lyogksg6s4jq7vb3i7mg3tid2e', 'eng:4xyzqfiheklogf4z5ft5d6nrby', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:mk3zik3bbwikfcpa5ytpe3fy7y:eng:wntaq5qkvelmsg7mzsg5nuhywy', 'cmn:mk3zik3bbwikfcpa5ytpe3fy7y', 'eng:wntaq5qkvelmsg7mzsg5nuhywy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:mqz6lkdopbshzcmpdbj4jkblhe:eng:wifnbn2owvyvjwtlgjpq6ua5py', 'cmn:mqz6lkdopbshzcmpdbj4jkblhe', 'eng:wifnbn2owvyvjwtlgjpq6ua5py', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:p2rrfrbzpbl3y5iznrnu5lua44:eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 'cmn:p2rrfrbzpbl3y5iznrnu5lua44', 'eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:pnldvmffu6pxfwpzd4qfbdzm7i:eng:pqfd3gfynco4jghxjongbrrkhe', 'cmn:pnldvmffu6pxfwpzd4qfbdzm7i', 'eng:pqfd3gfynco4jghxjongbrrkhe', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:pyoru3txba57ayytrynqop3rku:eng:neu23lufdwcsf7gmzqongbmrde', 'cmn:pyoru3txba57ayytrynqop3rku', 'eng:neu23lufdwcsf7gmzqongbmrde', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:qr4uxbgrnw7izghwo6eztwxvfe:eng:mv6gf7grgchiywwhez2ihsqjhi', 'cmn:qr4uxbgrnw7izghwo6eztwxvfe', 'eng:mv6gf7grgchiywwhez2ihsqjhi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:tmvyoxrf5k5hmi4amdqi5ofrje:eng:vb3b6iico6bxk7tzq3ydd3yw2a', 'cmn:tmvyoxrf5k5hmi4amdqi5ofrje', 'eng:vb3b6iico6bxk7tzq3ydd3yw2a', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:ttk5sz3fjm62t554v5o444zqma:eng:mzhdh2gtcxyrrg5opxlyvh54ue', 'cmn:ttk5sz3fjm62t554v5o444zqma', 'eng:mzhdh2gtcxyrrg5opxlyvh54ue', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:ulqkgcmxcf6zt6nuoj4x3xtlai:eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 'cmn:ulqkgcmxcf6zt6nuoj4x3xtlai', 'eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:uq6qhzypa366etd2opwzo3o4ye:eng:fuh6l3el6gavgwqpomvhbmag4u', 'cmn:uq6qhzypa366etd2opwzo3o4ye', 'eng:fuh6l3el6gavgwqpomvhbmag4u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:vdpuaubpkw7mrczse54m7w4uyi:eng:ckeg7hiaavnn6jgeav46eljrwi', 'cmn:vdpuaubpkw7mrczse54m7w4uyi', 'eng:ckeg7hiaavnn6jgeav46eljrwi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:vvse6hupvyupp5nh3rke4eczga:eng:atnubdh2tfwp6232oqbfqf3upe', 'cmn:vvse6hupvyupp5nh3rke4eczga', 'eng:atnubdh2tfwp6232oqbfqf3upe', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:wetyk3idrqdmyrh3iajqr7jooq:eng:5yhe6me4tjdtc7jtis23zus5zm', 'cmn:wetyk3idrqdmyrh3iajqr7jooq', 'eng:5yhe6me4tjdtc7jtis23zus5zm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:wor6jxshqlugbxvdeiyf4wrdxu:eng:qtgn7cuet754tdj2rjf7wcmz5u', 'cmn:wor6jxshqlugbxvdeiyf4wrdxu', 'eng:qtgn7cuet754tdj2rjf7wcmz5u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:x44jr6j4l6tf6pt7jvl2rx3c3u:eng:7l7jp5666mulxvhra543sys2ri', 'cmn:x44jr6j4l6tf6pt7jvl2rx3c3u', 'eng:7l7jp5666mulxvhra543sys2ri', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:xh5jzlt4cwo5ofxdp6zjrvby7y:eng:mhkyzps3vuyeeyypka635kp2cu', 'cmn:xh5jzlt4cwo5ofxdp6zjrvby7y', 'eng:mhkyzps3vuyeeyypka635kp2cu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:zohopk5yik3ptg5k46ldabazvu:eng:jvgh53rofdidzmw36ppwhhbssa', 'cmn:zohopk5yik3ptg5k46ldabazvu', 'eng:jvgh53rofdidzmw36ppwhhbssa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:2qutsxm4dt5lehrykmbvrg3lqi:jpn:l4jfbt5fn3hfcfjeqixkgr5x2a', 'eng:2qutsxm4dt5lehrykmbvrg3lqi', 'jpn:l4jfbt5fn3hfcfjeqixkgr5x2a', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:2qutsxm4dt5lehrykmbvrg3lqi:spa:ni552wtosnywadr6izxzjy3qwi', 'eng:2qutsxm4dt5lehrykmbvrg3lqi', 'spa:ni552wtosnywadr6izxzjy3qwi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:324myjpqcqu5mjqfurbthk5chy:jpn:d2j272jyfwch3eak7kfmvttfwi', 'eng:324myjpqcqu5mjqfurbthk5chy', 'jpn:d2j272jyfwch3eak7kfmvttfwi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:324myjpqcqu5mjqfurbthk5chy:spa:mzvj6z3bp6pzvqto7rx2qcph3i', 'eng:324myjpqcqu5mjqfurbthk5chy', 'spa:mzvj6z3bp6pzvqto7rx2qcph3i', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:32nygmumnjbv7vibww4frr6dse:jpn:k5gohbnynxo4ytjnab6uxue6sa', 'eng:32nygmumnjbv7vibww4frr6dse', 'jpn:k5gohbnynxo4ytjnab6uxue6sa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:32nygmumnjbv7vibww4frr6dse:spa:yvvtytayq7vwdvjnam4thf4f6u', 'eng:32nygmumnjbv7vibww4frr6dse', 'spa:yvvtytayq7vwdvjnam4thf4f6u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:32p6v2ulm333u5eel3s7yflm3u:jpn:24x7bnmkhgofzo6yjc7ovakyae', 'eng:32p6v2ulm333u5eel3s7yflm3u', 'jpn:24x7bnmkhgofzo6yjc7ovakyae', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:32p6v2ulm333u5eel3s7yflm3u:spa:w2vaif22daj2ctxbj4tkbrad7m', 'eng:32p6v2ulm333u5eel3s7yflm3u', 'spa:w2vaif22daj2ctxbj4tkbrad7m', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:45zv7btefyxqaukllttb7op3yi:jpn:pi7fevx6kyz5g7uagbzbn7dy5i', 'eng:45zv7btefyxqaukllttb7op3yi', 'jpn:pi7fevx6kyz5g7uagbzbn7dy5i', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:45zv7btefyxqaukllttb7op3yi:spa:jegkillvrydfnf7d6a4zlz7wi4', 'eng:45zv7btefyxqaukllttb7op3yi', 'spa:jegkillvrydfnf7d6a4zlz7wi4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:4xyzqfiheklogf4z5ft5d6nrby:jpn:lyogksg6s4jq7vb3i7mg3tid2e', 'eng:4xyzqfiheklogf4z5ft5d6nrby', 'jpn:lyogksg6s4jq7vb3i7mg3tid2e', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:4xyzqfiheklogf4z5ft5d6nrby:spa:4tvkptwv2nsj5c6ri3gy2k4y2u', 'eng:4xyzqfiheklogf4z5ft5d6nrby', 'spa:4tvkptwv2nsj5c6ri3gy2k4y2u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:5oz55cr5tjadmyjs5no6wwxujy:jpn:dwqwkup7t4o5vhumkuaiihclji', 'eng:5oz55cr5tjadmyjs5no6wwxujy', 'jpn:dwqwkup7t4o5vhumkuaiihclji', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:5oz55cr5tjadmyjs5no6wwxujy:spa:6fz6dfp3j2fy3jmlv43vgi3xki', 'eng:5oz55cr5tjadmyjs5no6wwxujy', 'spa:6fz6dfp3j2fy3jmlv43vgi3xki', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:5xo4wa56n2sotovvyl46coxbli:jpn:d4kttnmlnvfci4vs5etyijgqmy', 'eng:5xo4wa56n2sotovvyl46coxbli', 'jpn:d4kttnmlnvfci4vs5etyijgqmy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:5xo4wa56n2sotovvyl46coxbli:spa:tyg6j7fx2fty6ehflfllfdxmye', 'eng:5xo4wa56n2sotovvyl46coxbli', 'spa:tyg6j7fx2fty6ehflfllfdxmye', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:5yhe6me4tjdtc7jtis23zus5zm:jpn:zaxaimnu4uy7lgjitx7u4qbpqu', 'eng:5yhe6me4tjdtc7jtis23zus5zm', 'jpn:zaxaimnu4uy7lgjitx7u4qbpqu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:5yhe6me4tjdtc7jtis23zus5zm:spa:asuszk2rwp2ekrj2xxd3ogfu5q', 'eng:5yhe6me4tjdtc7jtis23zus5zm', 'spa:asuszk2rwp2ekrj2xxd3ogfu5q', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:753uwfpsgddx2ve6jdkfclgv5q:jpn:da5oimwndht4xgh5hxgwdytd6y', 'eng:753uwfpsgddx2ve6jdkfclgv5q', 'jpn:da5oimwndht4xgh5hxgwdytd6y', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:753uwfpsgddx2ve6jdkfclgv5q:spa:thhgzshyyxs4ydz55qnpabrcn4', 'eng:753uwfpsgddx2ve6jdkfclgv5q', 'spa:thhgzshyyxs4ydz55qnpabrcn4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:7kflfosiukcfqgoykqads5mfeq:jpn:i2fnbahbgzviwdiad3sawrkbym', 'eng:7kflfosiukcfqgoykqads5mfeq', 'jpn:i2fnbahbgzviwdiad3sawrkbym', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:7kflfosiukcfqgoykqads5mfeq:spa:bqauzm4pmzpvijbvxsotnrjxju', 'eng:7kflfosiukcfqgoykqads5mfeq', 'spa:bqauzm4pmzpvijbvxsotnrjxju', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:7l7jp5666mulxvhra543sys2ri:jpn:caywhfcuamxsplxdjuknq3pudq', 'eng:7l7jp5666mulxvhra543sys2ri', 'jpn:caywhfcuamxsplxdjuknq3pudq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:7l7jp5666mulxvhra543sys2ri:spa:44cyx33k5jgr24gr7kggbhgh5a', 'eng:7l7jp5666mulxvhra543sys2ri', 'spa:44cyx33k5jgr24gr7kggbhgh5a', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:a2ichma3h4bunfhgo7sqwp3pe4:jpn:rvpa3zhmbrrnqum7lhy5ijgapa', 'eng:a2ichma3h4bunfhgo7sqwp3pe4', 'jpn:rvpa3zhmbrrnqum7lhy5ijgapa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:a2ichma3h4bunfhgo7sqwp3pe4:spa:rofygqttmu5g3tkyul7b7r4tnu', 'eng:a2ichma3h4bunfhgo7sqwp3pe4', 'spa:rofygqttmu5g3tkyul7b7r4tnu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:ai4m3ife5ckcojo3fofsbxzpua:jpn:7e4nwrdtovrtbydeujqw6tj7py', 'eng:ai4m3ife5ckcojo3fofsbxzpua', 'jpn:7e4nwrdtovrtbydeujqw6tj7py', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:ai4m3ife5ckcojo3fofsbxzpua:spa:etq6uigppdrvkzmkrlzjkx5bxe', 'eng:ai4m3ife5ckcojo3fofsbxzpua', 'spa:etq6uigppdrvkzmkrlzjkx5bxe', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:atnubdh2tfwp6232oqbfqf3upe:jpn:hod2yqtkawhh3mtbjdwc5bxicq', 'eng:atnubdh2tfwp6232oqbfqf3upe', 'jpn:hod2yqtkawhh3mtbjdwc5bxicq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:atnubdh2tfwp6232oqbfqf3upe:spa:o7bcwsdmneav7eircbj7qxfwfa', 'eng:atnubdh2tfwp6232oqbfqf3upe', 'spa:o7bcwsdmneav7eircbj7qxfwfa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:bhyesunpjtkqhb3ycx6tb6mohi:jpn:aobeamvsioouy2737p7tvljvky', 'eng:bhyesunpjtkqhb3ycx6tb6mohi', 'jpn:aobeamvsioouy2737p7tvljvky', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:bhyesunpjtkqhb3ycx6tb6mohi:spa:tinahathlrholguoozhlwfdywm', 'eng:bhyesunpjtkqhb3ycx6tb6mohi', 'spa:tinahathlrholguoozhlwfdywm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:cgatpi36ldhaqziawy6ieert3y:jpn:mpsbythkeclgxmmbwrnc7hblza', 'eng:cgatpi36ldhaqziawy6ieert3y', 'jpn:mpsbythkeclgxmmbwrnc7hblza', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:cgatpi36ldhaqziawy6ieert3y:spa:jz3tr2gk4oslqgl45uzdzghpx4', 'eng:cgatpi36ldhaqziawy6ieert3y', 'spa:jz3tr2gk4oslqgl45uzdzghpx4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:ckeg7hiaavnn6jgeav46eljrwi:jpn:vdpuaubpkw7mrczse54m7w4uyi', 'eng:ckeg7hiaavnn6jgeav46eljrwi', 'jpn:vdpuaubpkw7mrczse54m7w4uyi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:ckeg7hiaavnn6jgeav46eljrwi:spa:qsdru5qlec24gozn5shuyaeyhm', 'eng:ckeg7hiaavnn6jgeav46eljrwi', 'spa:qsdru5qlec24gozn5shuyaeyhm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:fuh6l3el6gavgwqpomvhbmag4u:jpn:62xdg7uypqxg7xp45quf6rbvt4', 'eng:fuh6l3el6gavgwqpomvhbmag4u', 'jpn:62xdg7uypqxg7xp45quf6rbvt4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:fuh6l3el6gavgwqpomvhbmag4u:spa:fuh6l3el6gavgwqpomvhbmag4u', 'eng:fuh6l3el6gavgwqpomvhbmag4u', 'spa:fuh6l3el6gavgwqpomvhbmag4u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:hasdtzxrxkwwsypa6uyw7m3gqi:jpn:dtq64a7rftpfskeuhv4oqi24cy', 'eng:hasdtzxrxkwwsypa6uyw7m3gqi', 'jpn:dtq64a7rftpfskeuhv4oqi24cy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:hasdtzxrxkwwsypa6uyw7m3gqi:spa:nxe5zwddyhgdvannx2aws5h6f4', 'eng:hasdtzxrxkwwsypa6uyw7m3gqi', 'spa:nxe5zwddyhgdvannx2aws5h6f4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:hcub5b7hsyy6mav7l66ta7hc7q:jpn:bcsjwovwbktrk2x56mudce6ddm', 'eng:hcub5b7hsyy6mav7l66ta7hc7q', 'jpn:bcsjwovwbktrk2x56mudce6ddm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:hcub5b7hsyy6mav7l66ta7hc7q:spa:l2avfbv4uwkekszjd45qguhmei', 'eng:hcub5b7hsyy6mav7l66ta7hc7q', 'spa:l2avfbv4uwkekszjd45qguhmei', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:jvgh53rofdidzmw36ppwhhbssa:jpn:qoxn3u3vfbmaw4h45bi4qpbmye', 'eng:jvgh53rofdidzmw36ppwhhbssa', 'jpn:qoxn3u3vfbmaw4h45bi4qpbmye', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:jvgh53rofdidzmw36ppwhhbssa:spa:suelbqpf3u523owcyrfbxlzgcq', 'eng:jvgh53rofdidzmw36ppwhhbssa', 'spa:suelbqpf3u523owcyrfbxlzgcq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:lbfgrgfquwtbgh2o2hemqctxhu:jpn:nj772e5y77mnmxazdgl3ona67u', 'eng:lbfgrgfquwtbgh2o2hemqctxhu', 'jpn:nj772e5y77mnmxazdgl3ona67u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:lbfgrgfquwtbgh2o2hemqctxhu:spa:6gjj7wviiy2srbnwdlktn25i5u', 'eng:lbfgrgfquwtbgh2o2hemqctxhu', 'spa:6gjj7wviiy2srbnwdlktn25i5u', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:mhkyzps3vuyeeyypka635kp2cu:jpn:vxh7jdjpyo7pzk5pw55oq6eski', 'eng:mhkyzps3vuyeeyypka635kp2cu', 'jpn:vxh7jdjpyo7pzk5pw55oq6eski', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:mhkyzps3vuyeeyypka635kp2cu:spa:mhkyzps3vuyeeyypka635kp2cu', 'eng:mhkyzps3vuyeeyypka635kp2cu', 'spa:mhkyzps3vuyeeyypka635kp2cu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:mv6gf7grgchiywwhez2ihsqjhi:jpn:k7f3vljozlsa6jcuzo4uel3aau', 'eng:mv6gf7grgchiywwhez2ihsqjhi', 'jpn:k7f3vljozlsa6jcuzo4uel3aau', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:mv6gf7grgchiywwhez2ihsqjhi:spa:mv6gf7grgchiywwhez2ihsqjhi', 'eng:mv6gf7grgchiywwhez2ihsqjhi', 'spa:mv6gf7grgchiywwhez2ihsqjhi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:mzhdh2gtcxyrrg5opxlyvh54ue:jpn:hjieg2ww3mlc66rtesegjc5wrm', 'eng:mzhdh2gtcxyrrg5opxlyvh54ue', 'jpn:hjieg2ww3mlc66rtesegjc5wrm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:mzhdh2gtcxyrrg5opxlyvh54ue:spa:itfqt3z5ve6bu2jecaa3zg43ra', 'eng:mzhdh2gtcxyrrg5opxlyvh54ue', 'spa:itfqt3z5ve6bu2jecaa3zg43ra', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:neu23lufdwcsf7gmzqongbmrde:jpn:gzcwqgg4zqypsyvpmbxyu5uiwe', 'eng:neu23lufdwcsf7gmzqongbmrde', 'jpn:gzcwqgg4zqypsyvpmbxyu5uiwe', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:neu23lufdwcsf7gmzqongbmrde:spa:3z7ptvrlbafcribicpisqvk5w4', 'eng:neu23lufdwcsf7gmzqongbmrde', 'spa:3z7ptvrlbafcribicpisqvk5w4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:pia232slriiijj5oxv7tevqibq:jpn:7nkjaitlaf6jjhqpfbx2k5zise', 'eng:pia232slriiijj5oxv7tevqibq', 'jpn:7nkjaitlaf6jjhqpfbx2k5zise', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:pia232slriiijj5oxv7tevqibq:spa:7jdj3efc7wc3lged2rexkqvcju', 'eng:pia232slriiijj5oxv7tevqibq', 'spa:7jdj3efc7wc3lged2rexkqvcju', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:ppmx7j4pesoxdhsjrkcukmojku:jpn:a3c72frqqtomfxyrnofitcqnde', 'eng:ppmx7j4pesoxdhsjrkcukmojku', 'jpn:a3c72frqqtomfxyrnofitcqnde', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:ppmx7j4pesoxdhsjrkcukmojku:spa:w7iqepal6txv4zm636loj5c5le', 'eng:ppmx7j4pesoxdhsjrkcukmojku', 'spa:w7iqepal6txv4zm636loj5c5le', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:pqfd3gfynco4jghxjongbrrkhe:jpn:pnldvmffu6pxfwpzd4qfbdzm7i', 'eng:pqfd3gfynco4jghxjongbrrkhe', 'jpn:pnldvmffu6pxfwpzd4qfbdzm7i', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:pqfd3gfynco4jghxjongbrrkhe:spa:ml3tt2bjxaessevpz6siiup42q', 'eng:pqfd3gfynco4jghxjongbrrkhe', 'spa:ml3tt2bjxaessevpz6siiup42q', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:qg3lfsduw6dwidx2cqm6yjmeym:jpn:6tk45juy55v6re5ibbsq7c62cy', 'eng:qg3lfsduw6dwidx2cqm6yjmeym', 'jpn:6tk45juy55v6re5ibbsq7c62cy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:qg3lfsduw6dwidx2cqm6yjmeym:spa:hucics3fsazkw5en45dqdntj24', 'eng:qg3lfsduw6dwidx2cqm6yjmeym', 'spa:hucics3fsazkw5en45dqdntj24', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:qrahsuwggsdsrryv6osjmydcva:jpn:c66jzruxv5b24p4jqx5jejmec4', 'eng:qrahsuwggsdsrryv6osjmydcva', 'jpn:c66jzruxv5b24p4jqx5jejmec4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:qrahsuwggsdsrryv6osjmydcva:spa:6pdgm6q7txl3akavgtterizqhy', 'eng:qrahsuwggsdsrryv6osjmydcva', 'spa:6pdgm6q7txl3akavgtterizqhy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:qtgn7cuet754tdj2rjf7wcmz5u:jpn:hfeo4pa7rnh6ho6bxazwonkyju', 'eng:qtgn7cuet754tdj2rjf7wcmz5u', 'jpn:hfeo4pa7rnh6ho6bxazwonkyju', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:qtgn7cuet754tdj2rjf7wcmz5u:spa:cvwikz7iic5eng2dgrtjqae22i', 'eng:qtgn7cuet754tdj2rjf7wcmz5u', 'spa:cvwikz7iic5eng2dgrtjqae22i', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:shebcvreljr747knbe6phxxfq4:jpn:d5fuu7ov5bt2njnc7txe45db2y', 'eng:shebcvreljr747knbe6phxxfq4', 'jpn:d5fuu7ov5bt2njnc7txe45db2y', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:shebcvreljr747knbe6phxxfq4:spa:verl66hhj2ygpqknazd5dq2vkm', 'eng:shebcvreljr747knbe6phxxfq4', 'spa:verl66hhj2ygpqknazd5dq2vkm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:u7y5ppbbetpmydv7kr3i67v2bu:jpn:it5acm4lzj7bkb4r5a7lnjsmtu', 'eng:u7y5ppbbetpmydv7kr3i67v2bu', 'jpn:it5acm4lzj7bkb4r5a7lnjsmtu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:u7y5ppbbetpmydv7kr3i67v2bu:spa:xl6q3ogtiop72cjypoblwhj2r4', 'eng:u7y5ppbbetpmydv7kr3i67v2bu', 'spa:xl6q3ogtiop72cjypoblwhj2r4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:vb3b6iico6bxk7tzq3ydd3yw2a:jpn:7ncsq6vobui62w6quj7n7hvoze', 'eng:vb3b6iico6bxk7tzq3ydd3yw2a', 'jpn:7ncsq6vobui62w6quj7n7hvoze', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:vb3b6iico6bxk7tzq3ydd3yw2a:spa:iev7egb2lutc6laegry6pmacym', 'eng:vb3b6iico6bxk7tzq3ydd3yw2a', 'spa:iev7egb2lutc6laegry6pmacym', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:w7ad4nfyt2cbvrd4tbdcfvvrdm:jpn:cnfhjhl4ivbsmnrs2opyulmf6e', 'eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 'jpn:cnfhjhl4ivbsmnrs2opyulmf6e', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:w7ad4nfyt2cbvrd4tbdcfvvrdm:spa:lfml2glesbfbfwtd4jbl5k3kdm', 'eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 'spa:lfml2glesbfbfwtd4jbl5k3kdm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:waompmfgaewzmcxugv5b4j7s2e:jpn:f7ngwv6ikx4r5fqen3ucvyue2e', 'eng:waompmfgaewzmcxugv5b4j7s2e', 'jpn:f7ngwv6ikx4r5fqen3ucvyue2e', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:waompmfgaewzmcxugv5b4j7s2e:spa:flat3lzfk2h5bgxv4tedrhdjhq', 'eng:waompmfgaewzmcxugv5b4j7s2e', 'spa:flat3lzfk2h5bgxv4tedrhdjhq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:wifnbn2owvyvjwtlgjpq6ua5py:jpn:jnejsoqelogwmt76r2t3e6g7pm', 'eng:wifnbn2owvyvjwtlgjpq6ua5py', 'jpn:jnejsoqelogwmt76r2t3e6g7pm', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:wifnbn2owvyvjwtlgjpq6ua5py:spa:wcndbpyz46bgqpiz3bb2rknzwa', 'eng:wifnbn2owvyvjwtlgjpq6ua5py', 'spa:wcndbpyz46bgqpiz3bb2rknzwa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:wmekp5b3xkhhuntloj2dfk4j64:jpn:efz2aip5oc4pr465kf4lgzitsu', 'eng:wmekp5b3xkhhuntloj2dfk4j64', 'jpn:efz2aip5oc4pr465kf4lgzitsu', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:wmekp5b3xkhhuntloj2dfk4j64:spa:ueedje6pkusl4uo2drci2fhgdy', 'eng:wmekp5b3xkhhuntloj2dfk4j64', 'spa:ueedje6pkusl4uo2drci2fhgdy', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:wntaq5qkvelmsg7mzsg5nuhywy:jpn:r2t3fv37ejghztr5z5iyldnnva', 'eng:wntaq5qkvelmsg7mzsg5nuhywy', 'jpn:r2t3fv37ejghztr5z5iyldnnva', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:wntaq5qkvelmsg7mzsg5nuhywy:spa:4qewfx6v73lgcvmemcngulsbxe', 'eng:wntaq5qkvelmsg7mzsg5nuhywy', 'spa:4qewfx6v73lgcvmemcngulsbxe', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:xwf7j4piyyxlc2w7ghx7pdzeky:jpn:rg7vv2xblbkoximss4xl4vlr44', 'eng:xwf7j4piyyxlc2w7ghx7pdzeky', 'jpn:rg7vv2xblbkoximss4xl4vlr44', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:xwf7j4piyyxlc2w7ghx7pdzeky:spa:7k2b4s4jmsfwo76bm76khxmzfa', 'eng:xwf7j4piyyxlc2w7ghx7pdzeky', 'spa:7k2b4s4jmsfwo76bm76khxmzfa', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:yv6x5eqbs4elmfgjb6rwqxgwiq:jpn:ycttytuyfkl6ocnvu452njuhpi', 'eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 'jpn:ycttytuyfkl6ocnvu452njuhpi', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:yv6x5eqbs4elmfgjb6rwqxgwiq:spa:gfy7272slvdygdd2n6qmi4gbui', 'eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 'spa:gfy7272slvdygdd2n6qmi4gbui', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:zeg6ovhnorp3rbf6ox7ay3ivme:jpn:qxf7entcjnubku7ttgkgvtiaa4', 'eng:zeg6ovhnorp3rbf6ox7ay3ivme', 'jpn:qxf7entcjnubku7ttgkgvtiaa4', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:zeg6ovhnorp3rbf6ox7ay3ivme:spa:r5nmq3bzvth6ahexdwsrjmg2my', 'eng:zeg6ovhnorp3rbf6ox7ay3ivme', 'spa:r5nmq3bzvth6ahexdwsrjmg2my', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:zljkqdpujy5l6j5xzrgcux4tfa:jpn:7e4nwrdtovrtbydeujqw6tj7py', 'eng:zljkqdpujy5l6j5xzrgcux4tfa', 'jpn:7e4nwrdtovrtbydeujqw6tj7py', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:zljkqdpujy5l6j5xzrgcux4tfa:spa:mzsgezbbynmk3w5h5ys7swjjie', 'eng:zljkqdpujy5l6j5xzrgcux4tfa', 'spa:mzsgezbbynmk3w5h5ys7swjjie', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:p4egshpg447re5bxiwwnnwxy6a:eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'cmn:p4egshpg447re5bxiwwnnwxy6a', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:v6totkz2yzlu2uhgwvtu2xtwzq:jpn:p4egshpg447re5bxiwwnnwxy6a', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'jpn:p4egshpg447re5bxiwwnnwxy6a', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:v6totkz2yzlu2uhgwvtu2xtwzq:spa:hx77yb5rwmqekcrr3tkqrm7skq', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'spa:hx77yb5rwmqekcrr3tkqrm7skq', 0, 'seed', NULL);

-- 4. Morphological dimensions
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('gender', 'eng:32p6v2ulm333u5eel3s7yflm3u', 10);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('number', 'eng:ckeg7hiaavnn6jgeav46eljrwi', 20);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('person', 'eng:hcub5b7hsyy6mav7l66ta7hc7q', 30);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('tense', 'eng:324myjpqcqu5mjqfurbthk5chy', 40);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('mood', 'eng:5yhe6me4tjdtc7jtis23zus5zm', 50);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('nonfinite', 'eng:cgatpi36ldhaqziawy6ieert3y', 60);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('degree', 'eng:wmekp5b3xkhhuntloj2dfk4j64', 70);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('polarity', 'eng:shebcvreljr747knbe6phxxfq4', 80);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('politeness', 'eng:ai4m3ife5ckcojo3fofsbxzpua', 90);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('voice', 'eng:yv6x5eqbs4elmfgjb6rwqxgwiq', 100);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('construction', 'eng:pia232slriiijj5oxv7tevqibq', 110);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('aspect', 'eng:xwf7j4piyyxlc2w7ghx7pdzeky', 120);
INSERT OR IGNORE INTO morphological_dimensions (code, name_expression_id, sort_order) VALUES ('person-variant', 'eng:7kflfosiukcfqgoykqads5mfeq', 130);

-- 5. Morphological features
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('masculine', 'gender', 'eng:waompmfgaewzmcxugv5b4j7s2e', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('feminine', 'gender', 'eng:lbfgrgfquwtbgh2o2hemqctxhu', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('neuter', 'gender', 'eng:32nygmumnjbv7vibww4frr6dse', 3);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('singular', 'number', 'eng:fuh6l3el6gavgwqpomvhbmag4u', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('plural', 'number', 'eng:mhkyzps3vuyeeyypka635kp2cu', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('person-1', 'person', 'eng:zeg6ovhnorp3rbf6ox7ay3ivme', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('person-2', 'person', 'eng:mzhdh2gtcxyrrg5opxlyvh54ue', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('person-3', 'person', 'eng:5xo4wa56n2sotovvyl46coxbli', 3);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('present', 'tense', 'eng:jvgh53rofdidzmw36ppwhhbssa', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('past', 'tense', 'eng:qtgn7cuet754tdj2rjf7wcmz5u', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('imperfect', 'tense', 'eng:a2ichma3h4bunfhgo7sqwp3pe4', 3);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('future', 'tense', 'eng:5oz55cr5tjadmyjs5no6wwxujy', 4);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('indicative', 'mood', 'eng:wifnbn2owvyvjwtlgjpq6ua5py', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('subjunctive', 'mood', 'eng:2qutsxm4dt5lehrykmbvrg3lqi', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('imperative', 'mood', 'eng:45zv7btefyxqaukllttb7op3yi', 3);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('conditional', 'mood', 'eng:neu23lufdwcsf7gmzqongbmrde', 4);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('infinitive', 'nonfinite', 'eng:ppmx7j4pesoxdhsjrkcukmojku', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('gerund', 'nonfinite', 'eng:atnubdh2tfwp6232oqbfqf3upe', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('past-participle', 'nonfinite', 'eng:pqfd3gfynco4jghxjongbrrkhe', 3);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('comparative', 'degree', 'eng:hasdtzxrxkwwsypa6uyw7m3gqi', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('superlative', 'degree', 'eng:wntaq5qkvelmsg7mzsg5nuhywy', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('negative', 'polarity', 'eng:bhyesunpjtkqhb3ycx6tb6mohi', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('positive', 'polarity', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('polite', 'politeness', 'eng:zljkqdpujy5l6j5xzrgcux4tfa', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('passive', 'voice', 'eng:u7y5ppbbetpmydv7kr3i67v2bu', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('causative', 'voice', 'eng:753uwfpsgddx2ve6jdkfclgv5q', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('te-form', 'construction', 'eng:qrahsuwggsdsrryv6osjmydcva', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('potential', 'construction', 'eng:qg3lfsduw6dwidx2cqm6yjmeym', 2);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('volitional', 'construction', 'eng:vb3b6iico6bxk7tzq3ydd3yw2a', 3);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('desiderative', 'construction', 'eng:4xyzqfiheklogf4z5ft5d6nrby', 4);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('progressive', 'construction', 'eng:w7ad4nfyt2cbvrd4tbdcfvvrdm', 5);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('perfect', 'aspect', 'eng:7l7jp5666mulxvhra543sys2ri', 1);
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('voseo', 'person-variant', 'eng:mv6gf7grgchiywwhez2ihsqjhi', 1);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-split', 'system', 'LangMap split expressions');

-- Expression readings + user preferences (spec §9.2, §11).

CREATE TABLE expression_readings (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (expression_id, language_locale_code, scheme, value, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE user_preferences (
  user_id INTEGER NOT NULL,
  preference_key TEXT NOT NULL,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, preference_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- UI localization tables (spec §12.1, §12.2).

CREATE TABLE ui_locales (
  project_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  activation_source TEXT
    CHECK (activation_source IN ('system', 'auto', 'manual')),
  activated_at TEXT,
  activated_by INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, language_locale_code),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (activated_by) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE ui_messages (
  project_id TEXT NOT NULL,
  message_key TEXT NOT NULL,
  source_expression_id TEXT NOT NULL,
  source_text TEXT NOT NULL,
  placeholders_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, message_key),
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);

CREATE INDEX idx_ui_messages_source_expression
  ON ui_messages(project_id, status, source_expression_id);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-ui', 'system', 'LangMap UI source copy');

INSERT OR IGNORE INTO ui_locales (project_id, language_locale_code, status, mapping_revision, activation_source, activated_at)
VALUES ('langmap-web', 'eng-Latn-US', 'active', 0, 'system', CURRENT_TIMESTAMP);

-- Vote records referencing mapping edges by ID (spec 10.1).

CREATE TABLE votes (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  vote INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (target_type IN ('edge')),
  CHECK (vote IN (-1, 1)),
  UNIQUE (user_id, target_type, target_id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_votes_target ON votes (target_type, target_id);
CREATE INDEX idx_votes_user_created_at
  ON votes(user_id, created_at DESC, target_id);

-- Handbooks preserve curated expression collections using application-generated TEXT IDs.

CREATE TABLE handbooks (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  language_profile_code TEXT,
  visibility TEXT NOT NULL DEFAULT 'public'
    CHECK (visibility IN ('public', 'private')),
  status TEXT NOT NULL DEFAULT 'published'
    CHECK (status IN ('draft', 'published')),
  score INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
  ,FOREIGN KEY (language_profile_code) REFERENCES language_locales(code)
);

CREATE TABLE handbook_sections (
  id TEXT PRIMARY KEY,
  handbook_id TEXT NOT NULL,
  title TEXT,
  position INTEGER NOT NULL,
  parent_section_id TEXT,
  FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE,
  UNIQUE (handbook_id, position)
);

CREATE TABLE handbook_section_items (
  section_id TEXT NOT NULL,
  expression_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY (section_id, expression_id),
  UNIQUE (section_id, position),
  FOREIGN KEY (section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE,
  FOREIGN KEY (expression_id) REFERENCES expressions(id)
);

CREATE INDEX idx_handbooks_visibility_created ON handbooks(visibility, created_at DESC, id ASC);
CREATE INDEX idx_handbooks_score ON handbooks(score DESC, created_at DESC, id ASC);
CREATE INDEX idx_handbooks_user_created_at
  ON handbooks(user_id, created_at DESC, id ASC);
CREATE INDEX idx_handbook_sections_handbook ON handbook_sections(handbook_id, position ASC, id ASC);
CREATE INDEX idx_handbook_sections_parent ON handbook_sections(handbook_id, parent_section_id, position ASC, id ASC);
CREATE INDEX idx_handbook_section_items_section ON handbook_section_items(section_id, position ASC, expression_id ASC);
