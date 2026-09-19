# Reference data sync runbook

參考資料目前直接由版本控制來源產生 canonical CSV，再透過 PostgreSQL importer
同步；不再使用 D1、SQLite staging、SQL seed 或詞句 JSON。

## UI locale

`scripts/i18n/ui-locales.csv` 是唯一的 UI 詞句來源，欄位採
`ENTRY_ID,NOTE,LOCALE_<locale>...` 寬表；`ui-locales.manifest.json` 只保存 checksum
與來源 metadata。重新產生或檢查：

```bash
python3 scripts/i18n/generate-ui-csv.py
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest scripts/i18n/ui-locales.manifest.json --check
```

## 語言與詞典

- language／script／region registry：`scripts/language-reference/generate.py`。
- morphology registry：`scripts/morphology/`。
- dictionary repo 產生的 `csv/<source-key>/data.csv`：先以 importer 的 `--check` 驗證，
  再在明確的 `DATABASE_URL` 下使用 `--apply`。

來源修正回 dictionary adapter 後重新產生 CSV；不要在前端、SQL 或資料庫內寫例外。

## 禁止事項

- 不新增 SQLite、D1 staging、JSONL 或 per-locale UI CSV。
- 不把 manifest metadata 當成詞句資料來源。
