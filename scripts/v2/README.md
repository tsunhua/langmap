# LangMap v2 Migration Tooling

從舊版 D1（meanings 組模型）遷移到 v2 D1（pairwise edges 模型）。

## 架構

```
scripts/v2/
├── lib/
│   ├── edges.ts          # 純函式：組 → 完全圖邊
│   ├── edges.test.ts     # 3 tests
│   ├── handbook.ts       # 純函式：Markdown → 章節 + 有序詞句
│   ├── handbook.test.ts  # 4 tests
│   └── fixture.sql       # 小型測試資料
├── migrate.ts            # 遷移 runner
├── v2-data.sql           # 輸出（gitignored）
├── package.json
└── tsconfig.json
```

## 使用方式

### 1. 同步遠端舊資料到本地

```bash
cd backend

# 逐表匯出（因 FTS5 限制，wrangler d1 export 無法直接用）
TABLES="languages expressions expression_versions expression_meaning meanings users email_verification_tokens language_stats ui_locales handbooks handbook_pages collections collection_items"
for t in $TABLES; do
  npx wrangler d1 export langmap --remote --table="$t" --no-schema --output="remote-${t}.sql"
done

# 合併（FK 順序）
cat remote-languages.sql remote-users.sql remote-expressions.sql \
    remote-expression_versions.sql remote-meanings.sql remote-expression_meaning.sql \
    remote-collections.sql remote-collection_items.sql remote-handbooks.sql \
    remote-handbook_pages.sql remote-language_stats.sql remote-ui_locales.sql \
    remote-email_verification_tokens.sql > remote-old.sql

# 載入本地舊 D1
npx wrangler d1 execute langmap --local --file=../scripts/init-db.sql
# 補欄位（本地 schema 可能缺少遠端有的欄位）
sqlite3 "$(find .wrangler/state/v3/d1 -name '*.sqlite' | grep -v cache | head -1)" \
  "ALTER TABLE expressions ADD COLUMN meaning_id INTEGER;
   ALTER TABLE expression_versions ADD COLUMN meaning_id INTEGER;
   ALTER TABLE handbooks ADD COLUMN instruction_lang_prefix TEXT;
   DROP TRIGGER IF EXISTS expressions_ai;
   DROP TRIGGER IF EXISTS expressions_ad;
   DROP TRIGGER IF EXISTS expressions_au;
   DROP TABLE IF EXISTS expressions_fts;"
# 載入資料
sqlite3 "$(find .wrangler/state/v3/d1 -name '*.sqlite' | grep -v cache | head -1)" < remote-old.sql
# 重建 FTS
sqlite3 "$(find .wrangler/state/v3/d1 -name '*.sqlite' | grep -v cache | head -1)" \
  "CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(text, content='expressions', content_rowid='id', tokenize='unicode61');
   INSERT INTO expressions_fts(rowid, text) SELECT id, text FROM expressions;"
```

### 2. 跑遷移

```bash
cd scripts/v2
OLDDB="/path/to/backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/xxx.sqlite"
npx tsx migrate.ts "$OLDDB" ./v2-data.sql
```

### 3. 載入 v2 D1

```bash
cd backend_v2
npx wrangler d1 execute langmap-v2 --local --file=./schema.sql
# 用 sqlite3 直接載入（wrangler 對大檔案有 SQLITE_TOOBIG 限制）
V2DB="$(find .wrangler/state/v3/d1 -name '*.sqlite' | grep -v cache | tail -1)"
# 先 drop FTS triggers（避免觸發器阻擋 expression INSERT）
sqlite3 "$V2DB" "DROP TRIGGER IF EXISTS expressions_ai; DROP TRIGGER IF EXISTS expressions_ad; DROP TRIGGER IF EXISTS expressions_au; DROP TABLE IF EXISTS expressions_fts;"
sqlite3 "$V2DB" < ../scripts/v2/v2-data.sql
# 重建 FTS
sqlite3 "$V2DB" "CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(text, content='expressions', content_rowid='id', tokenize='unicode61');
  CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
  CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); END;
  CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
  INSERT INTO expressions_fts(rowid, text) SELECT id, text FROM expressions;"
```

### 4. 驗證

```bash
V2DB="$(find .wrangler/state/v3/d1 -name '*.sqlite' | grep -v cache | tail -1)"
sqlite3 "$V2DB" "SELECT count(*) FROM expressions; SELECT count(*) FROM expression_edges; SELECT count(*) FROM handbooks; SELECT count(*) FROM handbook_section_items;"
```

## 驗證結果（真實資料）

| 表 | 舊 D1 | v2 D1 |
|---|---|---|
| expressions | 91,625 | 91,625 |
| meanings | 25,599 | — (dropped) |
| expression_meaning | 76,724 | — (dropped) |
| expression_edges | — | 112,860 |
| handbooks | 4 | 4 |
| handbook_pages | 2 | — (dropped) |
| handbook_sections | — | 65 |
| handbook_section_items | — | 1,767 |
| missing-tags-skipped | — | 2 |

- **edges**: 112,860 = Σ(每組 N(N−1)/2)，跨組去重
- **missing-tags-skipped**: 2 = 舊手冊標記的 (text,lang) 在 expressions 查不到（可能 lang 預設不符或該表達式已刪）
- **items**: 1,767 = 舊手冊 Markdown 中抽出的有序詞句引用

## 注意事項

- **遠端重建**（之後）：`wrangler d1 create langmap-v2` → 填 database_id → 遠端跑 schema.sql → 遠端載 v2-data.sql
- **prose 丟失**：舊手冊 Markdown 的非標記文字在遷移中被捨棄（新模型無 prose 欄位）
- **collections 不遷**：v2 砍除收藏功能
- **間接映射 / 折疊 / feed** 等查詢邏輯屬於下一份計畫（backend_v2 API）
