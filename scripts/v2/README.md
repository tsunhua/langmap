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

## Glottolog release tooling

`glottolog_import.py` 只接受 repository 內（或 CI artifact）的 pinned
CLDF/CSV，不會在執行時連線下載資料。release 下載、簽名/來源審查與
checksum 固定應在 CI job 完成；import job 只讀取該 artifact。建議 artifact
至少包含官方 release 的 `languoids.csv`、checksum 檔與下載來源，並把實際
SHA-256 傳入命令：

```bash
# 例：先由 CI 下載並檢查官方 archived release（不要讓應用程式 runtime 下載）
# curl --fail --location --output artifacts/glottolog-5.3/languoids.csv <官方固定 URL>
# sha256sum --check artifacts/glottolog-5.3/SHA256SUMS

python3 glottolog_import.py path/to/languoids.csv \
  --source-version 5.3 \
  --expected-sha256 "<SHA256SUMS 中的值>" \
  --source-url "<官方 archived release URL>" \
  --manifest glottolog-5.3.manifest.json
```

輸出的 manifest 是本次輸入的可重現紀錄（release、格式、檔名、SHA-256、
row count、Glottocode count 與來源 URL），應與 dataset 一起保存並提交。若
checksum 不符，命令會在解析前 fail fast；不應以重新下載或猜測另一版本繼續。

正式寫入資料庫前先在 staging database 執行相同命令（省略 `--database` 只
會驗證及輸出 manifest）。有既有資料庫時，import 會先計算 `added`、`updated`、
`retired`、`unchanged` diff，再在單一 transaction upsert；可用輸出統計作為
部署 gate。release 中消失的 id 只會標記 `retired`，不會改指其他 languoid。

若需要更新 SQLite/D1 export，會在單一 transaction 內 upsert，重跑結果
相同；本 release 消失的 id 只會標記 `retired`，不會改指其他 languoid：

```bash
python3 glottolog_import.py path/to/languoids.csv \
  --source-version 5.3 --database path/to/local.sqlite
```

一次性的舊語言碼 manifest 使用獨立驗證器；它不會猜測 script、region 或
Glottocode，也不會產生 runtime alias：

```bash
python3 language_migration.py fixtures/language-migration.json \
  --codes observed-language-codes.txt
```

正式匯入前應先通過驗證器與人工 review；`fixtures/` 僅供測試，不代表完整
Glottolog release。

- **遠端重建**（之後）：`wrangler d1 create langmap-v2` → 填 database_id → 遠端跑 schema.sql → 遠端載 v2-data.sql
- **prose 丟失**：舊手冊 Markdown 的非標記文字在遷移中被捨棄（新模型無 prose 欄位）
- **collections 不遷**：v2 砍除收藏功能
- **間接映射 / 折疊 / feed** 等查詢邏輯屬於下一份計畫（backend_v2 API）
