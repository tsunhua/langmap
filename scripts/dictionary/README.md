# Dictionary mapping importer

將 dictionary CSV 的詞句提交到本地 LangMap API。一般語言欄位會建立 expression 並參與 mapping；`cmn-Bopo-zhuyin` 與 `cmn-Latn-pinyin` 會寫成 `cmn` expression 的 readings，不會建立獨立節點。

## Structured JSONL staging

Structured JSONL v2 先寫入離線 staging SQLite，再產生可審查的 preview artifact；此流程不直接產生或執行 SQL：

```bash
python3 scripts/dictionary/manage.py stage \
  '/Users/lim/Documents/Code/tsunhua/dictionary/export/structured-jsonl/Traditional Chinese - English Idioms.jsonl' \
  --database /tmp/langmap-dictionary/staging.sqlite
```

使用 stage 指令輸出的 `release_id` 產生 preview：

```bash
python3 scripts/dictionary/manage.py preview \
  --database /tmp/langmap-dictionary/staging.sqlite \
  --release release-... \
  --output /tmp/langmap-dictionary/preview
python3 scripts/dictionary/manage.py inspect \
  --database /tmp/langmap-dictionary/staging.sqlite \
  --release release-...
```

Preview 包含排序穩定的 `manifest.json`、`bindings.jsonl`、`quarantine.jsonl` 與 `quality-report.json`。釋義、標籤、關係、例句與詞性均保留在 staging；preview 只輸出可供後續發布的詞句綁定。舊的 flat importer 只保留遷移提示，請使用上述 `manage.py`。

### 高信心合併與本地 D1

`reconcile run` 會對候選執行兩次輸入順序不同的 provider 判定；只有兩次都是
`merge`、達到設定的信心門檻、沒有 blocker 且至少有兩個 evidence code 的候選會
自動回寫為同一個 staging cluster。其餘候選保持分離：

```bash
python3 scripts/dictionary/manage.py reconcile run \
  --database /tmp/langmap-dictionary/staging.sqlite \
  --release release-... \
  --config scripts/dictionary/config/reconciliation.json \
  --gold scripts/dictionary/gold/holdout.jsonl \
  --provider-command python3 path/to/provider.py
```

完成 reconciliation 後可直接集合式匯入本地 D1：

```bash
python3 scripts/dictionary/manage.py local-import \
  --database /tmp/langmap-dictionary/staging.sqlite \
  --release release-... \
  --d1-database /tmp/langmap-dictionary/d1.sqlite
```

若以空白本地 D1 優先節省空間，使用 packed catalog：

```bash
python3 scripts/dictionary/manage.py local-import \
  --database /tmp/langmap-dictionary/staging.sqlite \
  --release release-... \
  --d1-database /tmp/langmap-dictionary/d1.sqlite \
  --packed
```

`--packed` 只寫入整數鍵的詞句、mapping、reading，以及語言／locale codebook 與詞性 bitmask；claim、cluster、
AI 判定及其他抽取欄位仍保存在 staging。此模式要求新的 dictionary catalog，適合
全量重建；不會把舊 catalog 與新 release 疊加。

### 小檔案優先的增量匯入

全量資料不要一次建立單一 staging 交易；使用增量入口，每部 JSONL 各自提交，完成一部就能在本地 API 查到：

```bash
D1=$(find backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject \
  -maxdepth 1 -type f -name '*.sqlite' ! -name metadata.sqlite -print -quit)
python3 scripts/dictionary/incremental_import.py \
  --input-dir /Volumes/DATA/langmap-structured-jsonl \
  --d1-database "$D1" \
  --state /Volumes/DATA/langmap-incremental-state.json \
  --staging-root /Volumes/DATA/langmap-staging-parts \
  --batch-size 5000 \
  --commit-every 20000
```

檔案會依 `(bytes, filename)` 小到大排序；狀態檔以輸入 SHA-256 與 release ID 判斷是否已成功，重跑會跳過已完成檔案。每行 stdout JSON 都包含耗時、`entries_per_second`、`mb_per_second`、D1 前後計數與檔案大小。成功後預設刪除該部暫存 staging；原始 JSONL 不會刪除。若只做第一部基準測試，加上 `--limit-files 1`；若要保留暫存抽取欄位，加上 `--keep-staging`。

此增量模式使用 `--packed --append` 的等價行為逐部追加 integer codebook；不執行跨檔案 AI 合併。要做跨檔案高信心合併，仍需保留完整 staging release 後另行執行 reconciliation，再發布新的整體 release。

若要把 mirror、delta、postflight manifest 與 production plan 串成同一個可重跑入口，使用
`release_dictionary.py`。預設只準備 release，不會修改 production；加入 `--apply` 時仍必須
提供完全相同的 `--database-name` 與 `--confirm-production`：

```bash
python3 scripts/dictionary/release_dictionary.py \
  --input-dir /Volumes/DATA/langmap-structured-jsonl \
  --d1-database scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --state scripts/db/state/backup/import-state/<release>.json \
  --staging-root /tmp/langmap-dictionary-staging \
  --snapshot-root scripts/db/state/backup/snapshots \
  --release-name <NNN>-<topic> \
  --refresh-language-statistics
```

成功後輸出會包含 delta、manifest 與 plan 路徑；重跑同一批輸入會沿用 importer 的 state
與 before snapshot。大型資料可加 `--split`，讓 production apply 使用有限大小的 SQL
批次。`--apply` 成功後會以同一份 delta idempotently replay 回 mirror 並執行外鍵檢查；不包含
Web deploy。

## 修復舊版例句 mapping

若舊版 importer 曾把例句翻譯誤接到 headword，可先用目前的 Structured JSONL 重新匯入
mirror，再以來源驅動腳本產生可審核的 repair SQL：

```bash
python3 scripts/dictionary/repair_example_edges.py \
  --jsonl "/Volumes/DATA/langmap-structured-jsonl/Simplified Chinese - English.jsonl" \
  --mirror scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --output scripts/db/state/backup/delta/<topic>-repair.split.sql \
  --report scripts/db/state/backup/delta/<topic>-repair.report.json
```

腳本只會移除能由同一份來源明確識別的 headword→例句翻譯 claim，並把正確的例句 edge
保留為 relation bit `4`；無法安全判定的 legacy claim 只寫入 report，不會自動刪除。
新增的 expression／edge 仍須使用 `export_dictionary_delta.py` 產生 additions delta，
並在 managed production plan 中按 additions→repair 順序發布。

一般模式會寫入既有 expression／edge 表，適合相容性 fixture。packed 模式的 read-only
compatibility views 讓 API 仍可用原有 expression／edge DTO；一般使用者寫入仍走既有
通用表。

若某條舊 source claim 已不在目前 JSONL、但已由人工抽查確認為污染，可使用 targeted
模式，只核實指定 edge 在 mirror 中仍由該 source 聲明，不重新掃描整份 JSONL：

```bash
python3 scripts/dictionary/repair_example_edges.py \
  --jsonl "/Volumes/DATA/langmap-structured-jsonl/Simplified Chinese - English.jsonl" \
  --mirror scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --output scripts/db/state/backup/delta/<topic>-targeted-repair.split.sql \
  --report scripts/db/state/backup/delta/<topic>-targeted-repair.report.json \
  --only-remove-unmatched-edge \
  --remove-unmatched-edge <edge-id>
```

`--remove-unmatched-edge` 是明確批准清單；targeted 模式不會刪除未列出的 claim，且
必須在 managed production plan/apply 中發布。

驗證 `cod` 三個同形詞保持分離：

```bash
python3 -m pytest scripts/dictionary/tests/test_cod_clusters.py -v
```

先查看 payload，不寫入資料庫：

```bash
python3 scripts/dictionary/import_mappings.py \
  '/Users/lim/Documents/Code/tsunhua/dictionary/export/Traditional Chinese - English.csv' \
  --max-rows 20 --dry-run
```

本地 Worker 啟動後，使用臨時本地帳號提交小批次：

```bash
python3 scripts/dictionary/import_mappings.py \
  '/Users/lim/Documents/Code/tsunhua/dictionary/export/Traditional Chinese - English.csv' \
  --max-rows 20 --email dev@example.com --password dev
```

也可先取得 JWT，再用 `--token`，避免在命令列留下密碼：

```bash
python3 scripts/dictionary/import_mappings.py path/to/file.csv \
  --token "$LANGMAP_TOKEN" --max-rows 20
```

重要參數：

- `--base-url`：預設 `http://127.0.0.1:8788`
- `--offset`、`--max-rows`：續跑或限制測試範圍
- `--reading-locale`：讀音所屬 locale，預設 `cmn-Hant-TW`
- `--encoding`：預設 `utf-8-sig`

腳本每一 CSV 行獨立建立 expressions，再只在不同語言之間建立 mapping，避免同一語言的多個義項被直接相連；成功取得華語 expression ID 後再提交該行的注音／拼音 readings。重跑時 API 的 expression、mapping、reading 去重機制會避免重複資料。
