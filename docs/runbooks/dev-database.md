# PostgreSQL development runbook

## 前置條件

- Node.js、npm 與 backend dependencies 已安裝。
- 已安裝 PostgreSQL（macOS 可選 Homebrew）；程式本身不依賴 Homebrew 或 `psql`。
- `backend/.dev.vars` 設定 `DATABASE_URL` 與 `SECRET_KEY`，不把 secret 提交到 Git。

## 建立與啟動

macOS 可用 Homebrew 建立本機 PostgreSQL（程式與跨 OS importer 不依賴 Homebrew）：

```bash
brew install postgresql@17
brew services start postgresql@17
createdb langmap
```

再設定 `DATABASE_URL=postgresql:///langmap`，套用 baseline：

```bash
python3 scripts/postgres/manage.py init
python3 scripts/postgres/manage.py migrate
./dev.sh
```

`dev.sh` 只檢查 `DATABASE_URL` 並啟動 Worker／Vite，不會清除或重建資料庫。若需隔離測試，請建立獨立 database，套用同一份
`backend/postgres/schema.sql`，不要使用 production URL。

## 詞典匯入

```bash
python3 scripts/dictionary/import_mapping_csv_pg.py --manifest /path/to/manifest.json --check
DATABASE_URL='postgresql://...' python3 scripts/dictionary/import_mapping_csv_pg.py --manifest /path/to/manifest.json --apply
```

`--apply` 是單一 transaction；checksum、表頭、registry 與 source ownership 任一項失敗即 rollback。

## 失敗處理

保留 PostgreSQL log 與 importer summary，修正來源 CSV／manifest 後以同一份 artifact 重跑。不要手動刪除 production rows，也不要把 `.dev.vars`、database dump 或 local runtime state 提交。
