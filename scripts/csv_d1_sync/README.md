# CSV 清洗與 D1 同步

流程分為兩個獨立步驟：

1. 資料集 cleaner：把不規範表頭與內容轉成標準 CSV。
2. D1 同步器：只讀標準 CSV，抽取詞句、建立映射並批次寫入 local／remote D1。

## 標準 CSV 契約

- 所有表頭必須是語言代碼，例如 `en-US`、`zh-Hant-TW`、`nan-TW-Latn-pehoeji`。
- 同一列中的非空詞句互為映射。
- 同一語言若有多個變體，在儲存格內以 ` | ` 分隔。
- 檔案使用 UTF-8；空白儲存格表示該列沒有該語言詞句。

```csv
en-US,zh-Hant-TW,ja-JP
hello,你好,こんにちは
thank you,謝謝,ありがとう
```

同步器若遇到非語言代碼表頭會直接拒絕，要求先執行 cleaner。

## 清洗 ChhoeTaigi

`chhoe-taigi` 是目前第一個資料集專屬 cleaner。它負責：

- 把 `PojUnicode`、`KipUnicode`、`HoaBun`、`EngBun` 等異形表頭映射成語言代碼。
- 清除 BOM、零寬空白，執行 Unicode NFC 與空白正規化。
- 依來源欄位規則拆分 `/`、`\`、`／`、`，`、`、` 等變體分隔符。
- 把 `戲單(票)` 等括號替代展開成 `戲單`、`戲票`。
- 把 `girdle, belt, ribbon` 等列舉拆成三個獨立值。
- 移除英文句尾的 `（i.e. ...）`、`（Cf. ...）` 等補充說明。
- 清除詞句前後的 `€` 等來源異常符號。
- 把詞條與對齊例句分別輸出為標準列。
- 對同一儲存格內的變體去重，以 ` | ` 保留在同一組對應中。

```bash
cd /Users/lim/Documents/Code/tsunhua/langmap

python3 scripts/csv_d1_sync/clean_csv.py chhoe-taigi \
  scripts/csv_d1_sync/data/ChhoeTaigi_TaioanPehoeKichhooGiku.csv \
  scripts/csv_d1_sync/data/ChhoeTaigi_TaioanPehoeKichhooGiku.cleaned.csv
```

新增其他來源時，在 `cleaners/` 實作 `CsvCleaner`，並註冊到
`clean_csv.py` 的 `CLEANERS`，不需修改 D1 同步器。

## 同步到 local D1

同步器會先檢查 schema。local D1 完全空白時會自動執行 `backend/schema.sql`；
若已有其他資料表但缺少 v2 schema，則會停止以避免覆寫。

```bash
python3 scripts/csv_d1_sync/csv_d1_sync.py \
  scripts/csv_d1_sync/data/ChhoeTaigi_TaioanPehoeKichhooGiku.cleaned.csv \
  --tag '1956 台灣白話基礎語句' \
  --source-ref 'ChhoeTaigi_TaioanPehoeKichhooGiku.csv' \
  --local
```

local 預設固定使用 `backend/.wrangler/state`，與 `dev.sh` 的 Wrangler 資料庫
相同。如需指定另一套隔離狀態：

```bash
python3 scripts/csv_d1_sync/csv_d1_sync.py data.cleaned.csv \
  --local \
  --persist-to /tmp/langmap-isolated-state
```

## 同步到 remote D1

先確認 `backend/wrangler.jsonc` 已填入正式 `database_id`，並完成
`wrangler login`：

```bash
python3 scripts/csv_d1_sync/csv_d1_sync.py \
  /tmp/chhoe-taigi.cleaned.csv \
  --tag '1956 台灣白話基礎語句' \
  --source-ref 'ChhoeTaigi_TaioanPehoeKichhooGiku.csv' \
  --database langmap-v2 \
  --remote
```

預設每批 1,000 筆。若 remote 單次請求過大，可加上 `--batch-size 100`
使用較保守的批次大小。

## 只生成並檢查 SQL

```bash
python3 scripts/csv_d1_sync/csv_d1_sync.py data.cleaned.csv \
  --local \
  --dry-run \
  --output-dir /tmp/langmap-import
```

輸出包含先執行的 `expressions-*.sql`、後執行的 `edges-*.sql`，以及記錄筆數
與批次順序的 `manifest.json`。詞句 ID 是 JavaScript 安全的 53-bit 分段整數：
高 16-bit 是 `lang_code` 的 SHA-256 派生前綴，低 37-bit 是詞句文本的
SHA-256 派生 ID。映射兩端按 ID 排序，並使用 `INSERT OR IGNORE`，因此同一份
資料可重跑且不覆寫既有內容。

## 為每個語言指定 tag 與 created_by

`--tag` 只能對整批詞句套同一個 tag。若不同語言需要不同 tag、或不同語言的
`created_by` 要指向不同 contributor，改用兩個 CSV 對應表：

```csv
# lang_tags.csv
lang,tag
cieh-tc,1956 台灣白話基礎語句
emoji,emoji-set
zyg-jx,壯語錦繡
```

```csv
# lang_authors.csv
lang,created_by
cieh-tc,user-abc
emoji,user-xyz
```

```bash
python3 scripts/csv_d1_sync/csv_d1_sync.py data.cleaned.csv \
  --local \
  --lang-tags scripts/csv_d1_sync/data/lang_tags.csv \
  --lang-authors scripts/csv_d1_sync/data/lang_authors.csv \
  --created-by system
```

規則：

- `--lang-tags` 存在時忽略 `--tag`；表中未列出的語言 `tags` 欄寫入 `NULL`。
- `--lang-authors` 表中未列出的語言，`expressions.created_by` fallback 到
  `--created-by`（預設 `system`）。
- `expression_edges.created_by` 一律使用 `--created-by`；跨語言邊無法對到
  單一語言作者。
- 兩個 CSV 欄位固定：`lang,tag` 與 `lang,created_by`；同 `lang` 出現衝突值
  會直接報錯。

