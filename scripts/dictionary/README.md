# Dictionary mapping importer

將 dictionary CSV 的詞句提交到本地 LangMap API。一般語言欄位會建立 expression 並參與 mapping；`cmn-Bopo-zhuyin` 與 `cmn-Latn-pinyin` 會寫成 `cmn` expression 的 readings，不會建立獨立節點。

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
