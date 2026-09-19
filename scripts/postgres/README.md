# PostgreSQL 開發資料庫

所有命令使用 `DATABASE_URL`。首次建立空資料庫：

```bash
python3 scripts/postgres/manage.py init
python3 scripts/postgres/manage.py migrate
```

`init` 只在新資料庫執行 baseline 與共用 seed；日常變更新增到
`backend/postgres/migrations/`，再執行 `migrate`。每個 migration 以檔名和 SHA-256
記錄，內容改變會拒絕執行。
