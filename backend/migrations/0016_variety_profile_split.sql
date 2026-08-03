-- 0016: Split single-table languages into language_varieties + language_profiles.
-- Forward-only, rerunnable. spec §12.2.3, §12.3. Backout = restore pre-migration backup.
PRAGMA defer_foreign_keys = ON;

-- 1. old variety_key -> (variety_id, variety_code). Seed IDs are version-controlled.
CREATE TEMP TABLE IF NOT EXISTS _variety_map (
  old_key TEXT PRIMARY KEY,
  variety_id TEXT NOT NULL,
  variety_code TEXT NOT NULL
);
INSERT OR IGNORE INTO _variety_map (old_key, variety_id, variety_code) VALUES
  ('system:und',      '01K1GWHD00GDH6PD5WC00HDQD7',  'und'),
  ('system:x-emoji',  '01K1GWHD00XZAH2DGKAY11J2X7',  'x-emoji'),
  ('system:x-image',  '01K1GWHD00F7FBYAQV8WEKA135',  'x-image'),
  ('system:fa',       '01K1GWHD00X8BRJJA1WAS53Q51',  'fa'),
  ('system:za-Latn',  '01K1GWHD00BB9YR14G68HXS3H1',  'za'),
  ('system:mn-Mong',  '01K1GWHD009CN2616Y0SCY67WF',  'mn'),
  ('system:mn-Cyrl',  '01K1GWHD009CN2616Y0SCY67WF',  'mn'),
  ('glotto:stan1293', '01K1GWHD001Z1VXEKX6Q1PEMH6',  'en'),
  ('glotto:swah1253', '01K1GWHD00X9MVHHWSZYYM1B2Y',  'swh'),
  ('glotto:ralt1242', '01K1GWHD00X1HXGAFVSRKXTHF2',  'ral'),
  ('glotto:yang1286', '01K1GWHD00F5JPB0CDWHJRFQ6R',  'zyg'),
  ('glotto:ouji1238', '01K1GWHD00ZNBSD4ETW6QYGHDK',  'wuu-x-ouji1238'),
  ('glotto:taiz1238', '01K1GWHD001EST811PWDB56762',  'wuu-x-taiz1238'),
  ('glotto:chao1238', '01K1GWHD00SK6PB7FMMTJYA62J',  'nan-x-chao1238'),
  ('glotto:minn1241', '01K1GWHD00SMQPS4JYFY690ASC',  'nan'),
  ('glotto:mand1415', '01K1GWHD00NMQC20PMZV031H78',  'cmn'),
  ('glotto:stan1318', '01K1GWHD005HX5VM8BRKQQCJD9',  'ar'),
  ('glotto:beng1280', '01K1GWHD00QQYESMP4K7GFBNJZ',  'bn'),
  ('glotto:stan1295', '01K1GWHD00NHYJTK7WVNVC9TZM',  'de'),
  ('glotto:stan1288', '01K1GWHD00AXX4SZ3A9R25J6CQ',  'es'),
  ('glotto:stan1290', '01K1GWHD00K4EH8FK4MPMY466J',  'fr'),
  ('glotto:hind1269', '01K1GWHD00229V3ETFHZ4V7GZG',  'hi'),
  ('glotto:indo1316', '01K1GWHD00WAHCW7XG1FKE0N3P',  'id'),
  ('glotto:ital1282', '01K1GWHD00B485N7Y5MXA8Y00A',  'it'),
  ('glotto:nucl1643', '01K1GWHD000DXGMDG05PJ4T2E4',  'ja'),
  ('glotto:kore1280', '01K1GWHD00CWEB07YTCHE2FXGV',  'ko'),
  ('glotto:mara1378', '01K1GWHD00XBQFHB2F4R0T1DR4',  'mr'),
  ('glotto:panj1256', '01K1GWHD00VS94XSBN1BQKV7E3',  'pa'),
  ('glotto:port1283', '01K1GWHD004R4BD1X7J8MGTBN9',  'pt'),
  ('glotto:russ1263', '01K1GWHD00CS00JR0Y2S1J3KVK',  'ru'),
  ('glotto:thai1261', '01K1GWHD00NPTA1MPM1ZAPX3XD',  'th'),
  ('glotto:nucl1301', '01K1GWHD00AF6SA0DAKY6FPNCQ',  'tr'),
  ('glotto:urdu1245', '01K1GWHD00NSRB1JSTEYQRYVTS',  'ur'),
  ('glotto:viet1252', '01K1GWHD000C6NPBGV1F3RNTDM',  'vi'),
  ('glotto:wuch1236', '01K1GWHD0025B1MXK1M98WQK3Z',  'wuu'),
  ('glotto:yuec1235', '01K1GWHD0039ZDYQQ6DNA6F4TS',  'yue'),
  ('glotto:xian1251', '01K1GWHD00JGND3KPZC9JYAXD5',  'hsn'),
  ('glotto:hakk1236', '01K1GWHD00C6XD8MQE0CVQS028',  'hak'),
  ('glotto:mind1253', '01K1GWHD00VVTZNFAZAB7SWPDY',  'cdo'),
  ('glotto:minb1236', '01K1GWHD00DFZEPRHD3AP7C028',  'mnp'),
  ('glotto:tibe1272', '01K1GWHD00WDR06XJVBKS1DFR6',  'bo'),
  ('glotto:uigh1240', '01K1GWHD00FTRQT82PTBE0A274',  'ug'),
  ('glotto:kaza1248', '01K1GWHD00N8ZKG7NFZN8BNTZM',  'kk'),
  ('glotto:kirg1245', '01K1GWHD002Z2VYS90STAZ4TY5',  'ky'),
  ('glotto:jiny1235', '01K1GWHD00KWTC0V9NCJS1THRW',  'cjy'),
  ('glotto:ganc1239', '01K1GWHD005469S094YTAWG6M8',  'gan'),
  ('glotto:minz1235', '01K1GWHD00JSHYJDH9H58PMH49',  'czo'),
  ('glotto:puxi1243', '01K1GWHD00J5RYZ74NPQ5N48XC',  'cpx'),
  ('glotto:nort3268', '01K1GWHD00TEN6QB2KD3B1WPHZ',  'cnp'),
  ('glotto:sout3250', '01K1GWHD00YF6DTZ9RX5WQ3ZTN',  'csp');

-- 2. Create new tables (verbatim from schema.sql).
CREATE TABLE IF NOT EXISTS language_varieties (
    id TEXT PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    description TEXT NOT NULL DEFAULT '',
    glottocode TEXT,
    origin TEXT NOT NULL
      CHECK (origin IN ('seed', 'glottolog', 'community', 'system')),
    community_reason TEXT,
    alternate_names_json TEXT NOT NULL DEFAULT '[]',
    references_json TEXT NOT NULL DEFAULT '[]',
    parent_languoid_id TEXT,
    created_by TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (glottocode) REFERENCES languoids(glottocode),
    FOREIGN KEY (parent_languoid_id) REFERENCES languoids(id)
);
CREATE TABLE IF NOT EXISTS language_profiles (
    code TEXT PRIMARY KEY NOT NULL,
    language_variety_id TEXT NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl')),
    base_language TEXT NOT NULL,
    script_code TEXT,
    region_code TEXT,
    variants_json TEXT NOT NULL DEFAULT '[]',
    private_use_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)
);
CREATE INDEX IF NOT EXISTS idx_language_varieties_name ON language_varieties(name);
CREATE INDEX IF NOT EXISTS idx_language_varieties_glottocode ON language_varieties(glottocode);
CREATE INDEX IF NOT EXISTS idx_language_profiles_variety
  ON language_profiles(language_variety_id);
CREATE INDEX IF NOT EXISTS idx_language_profiles_base_script_region
  ON language_profiles(base_language, script_code, region_code);

-- 3. Seed varieties: one per distinct old_key in _variety_map; COALESCE metadata
--    from the first languages row carrying that old variety_key.
INSERT OR IGNORE INTO language_varieties
  (id, code, name, name_en, description, glottocode, origin, community_reason,
   alternate_names_json, references_json, parent_languoid_id, created_at, updated_at)
SELECT m.variety_id, m.variety_code,
  COALESCE((SELECT name FROM languages WHERE variety_key=m.old_key ORDER BY code LIMIT 1), m.variety_code),
  (SELECT name_en FROM languages WHERE variety_key=m.old_key ORDER BY code LIMIT 1),
  COALESCE((SELECT description FROM languages WHERE variety_key=m.old_key LIMIT 1), ''),
  (SELECT glottocode FROM languages WHERE variety_key=m.old_key AND glottocode IS NOT NULL AND glottocode!='' LIMIT 1),
  COALESCE((SELECT origin FROM languages WHERE variety_key=m.old_key LIMIT 1), 'seed'),
  COALESCE((SELECT community_reason FROM languages WHERE variety_key=m.old_key LIMIT 1), ''),
  COALESCE((SELECT alternate_names_json FROM languages WHERE variety_key=m.old_key ORDER BY code LIMIT 1), '[]'),
  COALESCE((SELECT references_json FROM languages WHERE variety_key=m.old_key LIMIT 1), '[]'),
  (SELECT parent_languoid_id FROM languages WHERE variety_key=m.old_key AND parent_languoid_id IS NOT NULL LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM _variety_map m
WHERE NOT EXISTS (SELECT 1 FROM language_varieties v WHERE v.id=m.variety_id);

-- 4. Fallback: old variety_keys not in _variety_map (community/test). Each gets
--    its own variety with a placeholder id 'comm-<old_key>'; registry rebuild
--    (re-sync) later replaces seed varieties cleanly. spec §12.1.3.
INSERT OR IGNORE INTO language_varieties
  (id, code, name, name_en, description, glottocode, origin, community_reason,
   alternate_names_json, references_json, parent_languoid_id, created_at, updated_at)
SELECT 'comm-' || l.variety_key,
  CASE WHEN instr(l.variety_key,':')>0 THEN substr(l.variety_key, instr(l.variety_key,':')+1)
       ELSE 'x-' || lower(hex(randomblob(4))) END,
  (SELECT name FROM languages WHERE variety_key=l.variety_key ORDER BY code LIMIT 1),
  (SELECT name_en FROM languages WHERE variety_key=l.variety_key LIMIT 1),
  COALESCE((SELECT description FROM languages WHERE variety_key=l.variety_key LIMIT 1),''),
  (SELECT glottocode FROM languages WHERE variety_key=l.variety_key AND glottocode IS NOT NULL LIMIT 1),
  'community',
  COALESCE((SELECT community_reason FROM languages WHERE variety_key=l.variety_key LIMIT 1),''),
  COALESCE((SELECT alternate_names_json FROM languages WHERE variety_key=l.variety_key LIMIT 1),'[]'),
  '[]',
  (SELECT parent_languoid_id FROM languages WHERE variety_key=l.variety_key LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM (SELECT DISTINCT variety_key FROM languages) l
WHERE NOT EXISTS (SELECT 1 FROM _variety_map m WHERE m.old_key=l.variety_key)
  AND NOT EXISTS (SELECT 1 FROM language_varieties v WHERE v.id='comm-'||l.variety_key);

-- 5. Profiles: one per old languages row, code unchanged (spec §12.1.4). Profile
--    name derived from script; name_en carried from old row.
INSERT OR IGNORE INTO language_profiles
  (code, language_variety_id, name, name_en, direction, base_language, script_code,
   region_code, variants_json, private_use_json, created_at, updated_at)
SELECT l.code,
  COALESCE((SELECT m.variety_id FROM _variety_map m WHERE m.old_key=l.variety_key), 'comm-'||l.variety_key),
  CASE l.script_code
    WHEN 'Hans' THEN '簡體' WHEN 'Hant' THEN '繁體' WHEN 'Latn' THEN '拉丁'
    WHEN 'Cyrl' THEN '西里爾' WHEN 'Arab' THEN '阿拉伯文' WHEN 'Mong' THEN '傳統蒙古文'
    WHEN 'Tibt' THEN '藏文' WHEN 'Guru' THEN '古木奇文' ELSE '標準' END,
  l.name_en,
  COALESCE(l.direction,'ltr'),
  COALESCE(l.base_language, substr(l.code, 1, instr(l.code||'-','-')-1)),
  l.script_code, l.region_code,
  COALESCE(l.variants_json,'[]'), COALESCE(l.private_use_json,'[]'),
  COALESCE(l.created_at, CURRENT_TIMESTAMP), COALESCE(l.updated_at, CURRENT_TIMESTAMP)
FROM languages l
WHERE NOT EXISTS (SELECT 1 FROM language_profiles p WHERE p.code=l.code);

-- 6. Rebuild expressions with renamed FK column. Drop FTS triggers first; they
--    reference expressions by name and must be recreated on the rebuilt table.
DROP TRIGGER IF EXISTS expressions_ai;
DROP TRIGGER IF EXISTS expressions_ad;
DROP TRIGGER IF EXISTS expressions_au;

CREATE TABLE IF NOT EXISTS expressions_new (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    language_profile_code TEXT NOT NULL,
    region_code TEXT, region_name TEXT, region_latitude REAL, region_longitude REAL,
    tags TEXT, source_type TEXT DEFAULT 'user', source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    variation_status TEXT NOT NULL DEFAULT 'unclassified'
      CHECK (variation_status IN ('unclassified','shared','variant')),
    meaning_id INTEGER, created_by TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT, updated_at TEXT DEFAULT CURRENT_TIMESTAMP, desc TEXT DEFAULT NULL,
    FOREIGN KEY (language_profile_code) REFERENCES language_profiles(code)
);

INSERT OR IGNORE INTO expressions_new
  (id, text, audio_url, language_profile_code, region_code, region_name,
   region_latitude, region_longitude, tags, source_type, source_ref,
   review_status, variation_status, meaning_id, created_by, created_at,
   updated_by, updated_at, desc)
SELECT id, text, audio_url, language_code, region_code, region_name,
       region_latitude, region_longitude, tags, source_type, source_ref,
       review_status, variation_status, meaning_id, created_by, created_at,
       updated_by, updated_at, desc
FROM expressions;

DROP TABLE expressions;
ALTER TABLE expressions_new RENAME TO expressions;
CREATE INDEX IF NOT EXISTS idx_expressions_text ON expressions(text);
CREATE INDEX IF NOT EXISTS idx_expressions_language_profile ON expressions(language_profile_code);
CREATE INDEX IF NOT EXISTS idx_expressions_tags ON expressions(tags);
CREATE INDEX IF NOT EXISTS idx_expressions_created_by ON expressions(created_by);
CREATE INDEX IF NOT EXISTS idx_expressions_lang_text ON expressions(language_profile_code, text);
CREATE INDEX IF NOT EXISTS idx_expressions_meaning_id ON expressions(meaning_id);

-- 7. Rebuild language_locations with variety id FK.
CREATE TABLE IF NOT EXISTS language_locations_new (
    language_variety_id TEXT NOT NULL,
    city_name TEXT NOT NULL, city_name_en TEXT,
    territory_code TEXT NOT NULL, script_code TEXT NOT NULL DEFAULT '',
    latitude REAL NOT NULL, longitude REAL NOT NULL, reference TEXT NOT NULL,
    PRIMARY KEY (language_variety_id, city_name, territory_code, script_code),
    FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)
);
INSERT OR IGNORE INTO language_locations_new
  (language_variety_id, city_name, city_name_en, territory_code, script_code, latitude, longitude, reference)
SELECT COALESCE((SELECT m.variety_id FROM _variety_map m WHERE m.old_key=ll.variety_key), 'comm-'||ll.variety_key),
       city_name, city_name_en, territory_code, script_code, latitude, longitude, reference
FROM language_locations ll;
DROP TABLE language_locations;
ALTER TABLE language_locations_new RENAME TO language_locations;
CREATE INDEX IF NOT EXISTS idx_language_locations_variety ON language_locations(language_variety_id);
CREATE INDEX IF NOT EXISTS idx_language_locations_city ON language_locations(city_name, territory_code);

-- 8. Rebuild ui_locales FK target -> language_profiles(code).
CREATE TABLE IF NOT EXISTS ui_locales_new (
    project_id TEXT NOT NULL, code TEXT NOT NULL,
    native_name TEXT NOT NULL,
    direction TEXT NOT NULL DEFAULT 'ltr' CHECK (direction IN ('ltr','rtl')),
    fallback_code TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','draft','archived')),
    mapping_revision INTEGER NOT NULL DEFAULT 0,
    created_by TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, code),
    FOREIGN KEY (code) REFERENCES language_profiles(code),
    FOREIGN KEY (project_id, fallback_code) REFERENCES ui_locales(project_id, code)
);
INSERT OR IGNORE INTO ui_locales_new
  (project_id, code, native_name, direction, fallback_code, status, mapping_revision,
   created_by, created_at, updated_by, updated_at)
SELECT project_id, code, native_name, direction, fallback_code, status,
       mapping_revision, created_by, created_at, updated_by, updated_at
FROM ui_locales;
DROP TABLE ui_locales;
ALTER TABLE ui_locales_new RENAME TO ui_locales;
CREATE INDEX IF NOT EXISTS idx_ui_locales_code ON ui_locales(code);

-- 9. Drop obsolete tables.
DROP TABLE IF EXISTS language_stats;
DROP TABLE languages;

-- 10. Recreate FTS triggers on the rebuilt expressions table.
CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(
    text, content='expressions', content_rowid='id', tokenize='unicode61'
);
CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;
CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
END;
CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

-- 11. Verify: no orphan references survive (spec §14.1). Aborts via 1/0 on failure.
CREATE TEMP TABLE IF NOT EXISTS _check (ok INTEGER NOT NULL CHECK (ok = 1));
INSERT INTO _check (ok)
SELECT CASE WHEN
  NOT EXISTS (SELECT 1 FROM expressions e WHERE NOT EXISTS
      (SELECT 1 FROM language_profiles p WHERE p.code=e.language_profile_code))
  AND NOT EXISTS (SELECT 1 FROM ui_locales u WHERE NOT EXISTS
      (SELECT 1 FROM language_profiles p WHERE p.code=u.code))
  AND NOT EXISTS (SELECT 1 FROM language_profiles p WHERE NOT EXISTS
      (SELECT 1 FROM language_varieties v WHERE v.id=p.language_variety_id))
  AND NOT EXISTS (SELECT 1 FROM language_locations ll WHERE NOT EXISTS
      (SELECT 1 FROM language_varieties v WHERE v.id=ll.language_variety_id))
  AND NOT EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name IN ('languages','language_stats'))
  AND (SELECT COUNT(*) FROM language_varieties) > 0
THEN 1 ELSE 0 END;
DROP TABLE _check;
DROP TABLE _variety_map;
