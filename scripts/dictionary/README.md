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
