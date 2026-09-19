# UI locale wide CSV

前端 UI locale 與 PostgreSQL 匯入共用一張 canonical 寬表：

```text
scripts/i18n/
  ui-locales.csv
  ui-locales.manifest.json
```

`ui-locales.csv` 的表頭是 `ENTRY_ID,NOTE,LOCALE_<locale>...`；每列的
`ENTRY_ID` 是穩定的 UI message key，各 locale 是欄位，不再為每個 locale
維護一份 JSON 或另一份 CSV。`ui-locales.manifest.json` 只保存 checksum、來源與欄位
metadata，不保存詞句內容。

## 產生與驗證

```bash
python3 scripts/i18n/generate-ui-csv.py
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest scripts/i18n/ui-locales.manifest.json --check
```

`generate-ui-csv.py` 只會正規化 row 順序、檢查欄位與刷新 manifest；編輯
UI locale 時直接修改 `data.csv`，不要新增 per-locale JSON／CSV。PG 匯入
使用相同的 manifest 與 CSV：

```bash
DATABASE_URL='postgresql://...' python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest scripts/i18n/ui-locales.manifest.json --apply
```

Web 的 `web/src/locales/project.ts` 也直接載入這張寬表，再按 locale 欄位
建立 Vue i18n catalog，因此 build 與資料庫不會各自維護一份翻譯來源。

## 規則

- 至少兩個非空 locale 值的 row 才能進入 canonical CSV。
- locale 欄位按 UTF-8 bytewise 排序；message value 使用 RFC 4180 quoting。
- `manifest.json` 是 metadata，不是可直接編輯的詞句資料；CSV checksum 改變
  時必須重新執行 generator。
- 不產生 SQL、JSONL、SQLite mirror 或 D1 staging。
