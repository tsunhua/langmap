-- LangMap 本地開發資料庫 schema（合併 001～043 遷移後的最終樣貌）
-- Usage: cd backend && npx wrangler d1 execute langmap --local --file=../scripts/init-db.sql
--
-- 只建表＋索引＋FTS；資料由 dev.sh 從 002_populate_languages.sql / 028_migrate_ui_locales.sql 同步進來。
-- ⚠ 僅供本地：此檔會 DROP 既有資料表，切勿用於遠端（遠端請改跑 scripts/0NN_*.sql 遷移檔）。
-- 當 schema 累積新遷移時，記得回頭把欄位／資料表補進這裡，讓本地與遠端一致。

--------------------------------------------------------------------------------
-- 0. 清空（順序：先觸發器與 FTS，再子表，再父表）
--------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS expressions_ai;
DROP TRIGGER IF EXISTS expressions_ad;
DROP TRIGGER IF EXISTS expressions_au;
DROP TABLE IF EXISTS expressions_fts;
DROP TABLE IF EXISTS handbook_pages;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS language_stats;
DROP TABLE IF EXISTS collection_items;
DROP TABLE IF EXISTS collections;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS expression_meaning;
DROP TABLE IF EXISTS meanings;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS languages;

--------------------------------------------------------------------------------
-- 1. 核心表
--------------------------------------------------------------------------------

-- 語言（001 ＋ 003 group_name）
CREATE TABLE languages (
    id INTEGER PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    direction TEXT DEFAULT 'ltr',
    is_active INTEGER DEFAULT 0,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    group_name TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_languages_name ON languages(name);
CREATE INDEX idx_languages_is_active ON languages(is_active);
CREATE INDEX idx_languages_active_name ON languages(is_active, name);

-- 詞句（001 ＋ 030 移除 meaning_id ＋ 040 新增 desc）
CREATE TABLE expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    language_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    tags TEXT,
    source_type TEXT DEFAULT 'user',
    source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    desc TEXT DEFAULT NULL
);
CREATE INDEX idx_expressions_text ON expressions(text);
CREATE INDEX idx_expressions_language_code ON expressions(language_code);
CREATE INDEX idx_expressions_tags ON expressions(tags);
CREATE INDEX idx_expressions_created_by ON expressions(created_by);
CREATE INDEX idx_expressions_lang_text ON expressions(language_code, text);

-- 詞句歷史版本（001 ＋ 040 新增 desc）
CREATE TABLE expression_versions (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    region_name TEXT,
    region_latitude TEXT,
    region_longitude TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    desc TEXT DEFAULT NULL
);
CREATE INDEX idx_expression_versions_expression_id ON expression_versions(expression_id);
CREATE INDEX idx_expr_versions_id_created ON expression_versions(expression_id, created_at DESC);

-- 語義（meanings）與詞句的多對多關聯（025）
CREATE TABLE meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expression_meaning (
    id TEXT PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    meaning_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (meaning_id) REFERENCES meanings(id)
);
CREATE INDEX idx_expression_meaning_expression_id ON expression_meaning(expression_id);
CREATE INDEX idx_expression_meaning_meaning_id ON expression_meaning(meaning_id);

-- 使用者與信箱驗證（001）
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',            -- 'super_admin', 'admin', 'user'
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

CREATE TABLE email_verification_tokens (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_tokens_expires_at ON email_verification_tokens(expires_at);

--------------------------------------------------------------------------------
-- 2. 收藏集（005 ＋ 014 items_count）
--------------------------------------------------------------------------------

CREATE TABLE collections (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_public INTEGER DEFAULT 0,
    items_count INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_collections_user_id ON collections(user_id);
CREATE INDEX idx_collections_name ON collections(name);
CREATE INDEX idx_collections_is_public_created ON collections(is_public, created_at DESC);
CREATE INDEX idx_collections_user_created ON collections(user_id, created_at DESC);

CREATE TABLE collection_items (
    id INTEGER PRIMARY KEY NOT NULL,
    collection_id INTEGER NOT NULL,
    expression_id INTEGER NOT NULL,
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, expression_id)
);
CREATE INDEX idx_collection_items_collection_id ON collection_items(collection_id);
CREATE INDEX idx_collection_items_expression_id ON collection_items(expression_id);
CREATE INDEX idx_collection_items_query ON collection_items(collection_id, created_at DESC);

--------------------------------------------------------------------------------
-- 3. 反正規化統計（014）
--------------------------------------------------------------------------------

CREATE TABLE language_stats (
    language_code TEXT PRIMARY KEY,
    expression_count INTEGER DEFAULT 0
);

--------------------------------------------------------------------------------
-- 4. 全文搜尋 FTS5（015 ＋ 031 trigger 修正）
--    external-content 模式，指向 expressions；觸發器維持索引同步。
--------------------------------------------------------------------------------

CREATE VIRTUAL TABLE expressions_fts USING fts5(
    text,
    content='expressions',
    content_rowid='id',
    tokenize='unicode61'
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

--------------------------------------------------------------------------------
-- 5. 學習手冊（024 ＋ 026 renders ＋ 029 lang_colors ＋ 043 author/published_at/has_pages）
--------------------------------------------------------------------------------

CREATE TABLE handbooks (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    content TEXT NOT NULL,
    source_lang TEXT,
    target_lang TEXT,
    is_public INTEGER DEFAULT 0,
    renders TEXT DEFAULT '{}',
    lang_colors TEXT DEFAULT '{}',
    author TEXT DEFAULT NULL,
    published_at TEXT DEFAULT NULL,
    has_pages INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_handbooks_user_id ON handbooks(user_id);
CREATE INDEX idx_handbooks_is_public_created ON handbooks(is_public, created_at DESC);
CREATE INDEX idx_handbooks_user_created ON handbooks(user_id, created_at DESC);

CREATE TABLE handbook_pages (
    id INTEGER PRIMARY KEY NOT NULL,
    handbook_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 0,
    renders TEXT DEFAULT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE
);
CREATE INDEX idx_handbook_pages_handbook_id ON handbook_pages(handbook_id);
CREATE INDEX idx_handbook_pages_handbook_sort ON handbook_pages(handbook_id, sort_order);

--------------------------------------------------------------------------------
-- 6. 介面語系（028，取代舊的 expressions-based UI 翻譯）
--------------------------------------------------------------------------------

CREATE TABLE ui_locales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    language_code TEXT UNIQUE NOT NULL,
    locale_json TEXT NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ui_locales_language_code ON ui_locales(language_code);

--------------------------------------------------------------------------------
-- 7. 本地開發種子帳號（僅本地；email 已驗證，角色 super_admin）
--    帳號：admin / 密碼：admin123
--------------------------------------------------------------------------------
INSERT INTO users (id, username, email, password_hash, role, email_verified)
VALUES (1, 'admin', 'admin@langmap.io', '$2b$10$YQSbPntowPpl8NZS99V9Q.k.m4yZGmexTQr6q8ekKtK3dzdkzxQUe', 'super_admin', 1);
