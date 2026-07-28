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

### 生產建立 v2 並只同步用戶資料

此流程直接在 Cloudflare D1 之間同步 `users` 與
`email_verification_tokens`，不需要先把舊資料庫完整下載到本地。
`setup` 只允許建立不存在的目標資料庫，成功後會把新
`database_id` 寫入 `backend/wrangler.jsonc` 並套用目前的
`backend/schema.sql`。如果資料庫已建立、但 config 仍是
`REPLACE_AFTER_CREATE`，再次執行 `setup` 會從遠端取得 ID 並接續未完成的
初始化；若 config 已有正式 ID，則會拒絕覆蓋。

```bash
cd scripts/v2

# 1. 建立 langmap-v2、寫入 binding 並建立 schema
./migrate.sh setup --remote

# 2. 從 langmap 同步用戶相關資料到 langmap-v2
./migrate.sh sync-users --remote

# 3. 核對主要表與 foreign key
./migrate.sh verify --remote
```

來源及目標名稱可以覆寫：

```bash
OLD_DB_NAME=langmap \
V2_DB_NAME=langmap-v2 \
./migrate.sh sync-users --remote
```

若目標已經有用戶資料，腳本預設中止，避免重複或誤覆蓋。只有確認要
替換時才使用：

```bash
./migrate.sh sync-users --remote --replace-users
```

`--replace-users` 會先刪除目標的驗證 token，再刪除目標用戶；如果目標
已有投票、手冊等引用用戶的資料，foreign key 會阻止刪除。正式切換前
應暫停註冊等寫入，再執行最後一次同步與核對。

也可以指定本地 v1 SQLite 作為來源；腳本會以唯讀模式載入，並驗證
`users`、`email_verification_tokens` 都存在：

```bash
./migrate.sh sync-users --remote \
  --source-local /absolute/path/to/v1.sqlite
```

若本地來源需要覆蓋目標已有的用戶資料：

```bash
./migrate.sh sync-users --remote \
  --source-local /absolute/path/to/v1.sqlite \
  --replace-users
```

### 完整 v1 → v2 資料遷移

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
cd backend
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

## 社群語言建立工作流

### Schema 與 registry 載入順序

本地或遠端資料庫初始化時，必須先套用 `backend/schema.sql`（或執行
migrations），**再**載入 `language-registry.sql`。registry SQL 包含
`languoids`、`language_subtags` 與明確 `languages` seed，這些資料有
foreign key 依賴（`languages.glottocode` → `languoids.glottocode`），
顛倒順序會導致 FK 違規。

### 明確 seed 取代組合展開

`languages` 表只包含明確指定的 seed 項目（第一方 UI locale、`und`、
`x-emoji`、`x-image` 及 `language_seed_profiles.json` 定義的 BCP 47
tag）。不再對所有 Glottolog languoids 批量生成 base tag、展開 major
regions 或為 Sinitic descendants 乘上 script。需要新語言時，由已登入
使用者透過 `POST /api/v2/languages` 建立。

### 離線重現 registry artifacts

`artifacts/language-registry-5.3/` 中的檔案可在無網路环境下重現：

```bash
cd scripts/v2
python3 sync_language_registry.py \
  --output artifacts/language-registry-5.3 \
  --offline
```

`--offline` 模式使用已下載的 raw artifact，不連線。重新生成後
`language-registry.sql` 的內容固定（排序與 upsert 語句），
重跑結果相同。

### 既有 canonical code 不變

migration 完成後，既有合法 `languages.code`（如 `en-US`、`zh-Hant-TW`、
`nan-Latn-TW-tailo`）保持不變。`expressions.language_code`、
`ui_locales.code` 等引用欄位同步更新至新表中的 canonical code。
只有少數不合法或非 canonical 的舊 code 才在 migration 中被明確映射。

### 測試指令

```bash
# Python 單元測試（語言資料驗證）
cd scripts/v2 && python3 -m unittest test_language_data.py

# TypeScript 單元測試（邊與手冊邏輯）
cd scripts/v2 && npm test

# 後端單元測試（不需要 dev server）
cd backend && npm test

# 後端整合測試（需要 dev server 在 localhost:8788）
cd backend && npm run test:integration

# 前端單元測試
cd web && npm test

# i18n key 完整性檢查
cd web && npm run i18n:check

# 完整 build
cd web && npm run build
# 或
./build.sh
```

整合測試依賴 `127.0.0.1:8788` 與本地 D1，執行前需先啟動 Worker
（`./dev.sh` 或 `npx wrangler dev`）。

## 注意事項

## Glottolog release tooling

三個工具的責任不同：

| 工具 | 用途 | 是否連線 |
|---|---|---:|
| `sync_language_registry.py` | 從官方來源同步並產生完整 registry artifact | 是；`--offline` 除外 |
| `glottolog_import.py` | 驗證 pinned `languoids.csv`，或 upsert 到 SQLite/D1 export | 否 |
| `language_migration.py` | 一次性驗證舊 code 到 canonical code 的人工映射 | 否 |

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

### 從官方 registry 同步全量資料

`sync_language_registry.py` 會從 Glottolog 5.3 與 IANA Language Subtag
Registry 下載官方原始檔，保留 raw artifact 與 SHA-256，並產生：

- `languoids.csv`：完全符合 `languoids` 表欄位，一個 Glottocode 一列。
- `iana-subtags.json`：完整 language、extlang、script、region、variant、
  grandfathered 與 redundant registry。
- `languages.csv`：符合 `languages` 單一 profile 表欄位；包含 seed
  profiles 指定的 BCP 47 tag，全域按 `code` 由 a 到 z 穩定排序。
- `manifest.json`：來源 URL、版本、IANA File-Date、checksum 與筆數。
- `online-code-migrations.json`：線上既有但非 canonical 的 code 到新 code
  的一次性遷移映射。

```bash
cd scripts/v2
python3 sync_language_registry.py \
  --output artifacts/language-registry-5.3
```

下載後可完全離線重現：

```bash
python3 sync_language_registry.py \
  --output artifacts/language-registry-5.3 \
  --offline
```

BCP 47 的 region、script、variant 是 content tag 屬性，不是 Glottolog
identity，因此不會複製進 `languoids`。展開規則保存在
`language_seed_profiles.json`：明確定義要產生的 BCP 47 language tag，
取代舊版的笛卡兒積展開。例如 `nan` 使用精確 script/region
組合，不共享地區集合，也不作交叉相乘。例如 `nan` 只生成
`nan-Latn-TW-tailo`、`nan-Latn-TW-pehoeji` 等。羅馬字
variant 另由 IANA 與線上 required code 生成。不另生成 `zh-Hant`、`zh-TW`
這類已有完整細分組合
的中間行。其他主要語言只生成列出的主要地區，例如 `en-US`、`en-GB`。
注音只限定生成 `zh-Bopo-TW`（純注音）與 `zh-Hanb-TW`（漢字搭配注音），
不套用到其他 Sinitic language 或 dialect。
registry 只輸出 profile 葉節點：有 region 展開時不保留 base，有
script/region 完整組合時不生成 script-only 或 region-only 中間標籤。
例如不生成 `yue`、`yue-HK`、`en`，只保留 `yue-Hant-HK`、`en-US` 等
完整項；`jyutping` variant 強制標記拉丁 script，生成
`yue-Latn-jyutping`，不生成 script 不明的 `yue-jyutping`。
IANA variant 的 `Prefix` 不保證包含書寫系統；`variant_scripts` 保存有來源
依據的補充，例如 Unifon、Ladin 各書寫標準及 Latgalian 1929/2007 正字法
均補為 `Latn`。這是 variant metadata，不以名稱猜測未知項目。
已有更具體線上標籤的 `nan-Latn-TW-tailo`／`pehoeji` 會取代無地區的
泛化 variant tag。
Glottolog Sinitic 分支下的其他 language 一律生成 `Hans`、`Hant`、`Latn`
三種 script；沒有獨立 ISO code 的 dialect 生成
`base-Hans/Hant/Latn-x-<glottocode>`，但不繼承任何 region。

`required_online_codes` 是硬性資料契約：現有線上詞句使用的 code 必須能解析
到指定 Glottocode 並出現在輸出。舊資料中的 `nan-TW-Latn-tailo` 與
`nan-TW-Latn-pehoeji` 因 script/region 次序不符合 BCP 47，分別遷移至
`nan-Latn-TW-tailo` 與 `nan-Latn-TW-pehoeji`，不作 runtime alias。

`x-emoji` 與 `x-image` 是 private-use-only 的非語言內容類型，不建立
Glottolog identity；輸出中的 `languoid_id` 為空，且預設不啟用。白名單只
允許這兩項，不接受任意 `x-*`。

- **遠端重建**（之後）：`wrangler d1 create langmap-v2` → 填 database_id → 遠端跑 schema.sql → 遠端載 v2-data.sql
- **prose 丟失**：舊手冊 Markdown 的非標記文字在遷移中被捨棄（新模型無 prose 欄位）
- **collections 不遷**：v2 砍除收藏功能
- **間接映射 / 折疊 / feed** 等查詢邏輯屬於下一份計畫（backend API）
