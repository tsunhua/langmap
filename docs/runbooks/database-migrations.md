# PostgreSQL migration runbook

## 前置條件

- `DATABASE_URL` 指向明確的目標 PostgreSQL database。
- migration 檔名與 checksum 未被修改；schema、effect 與回退方案已 code review。
- 先在隔離 database 套用 baseline、migration 與 backend tests。

## Init / migrate / verify

```bash
python3 scripts/postgres/manage.py init
python3 scripts/postgres/manage.py migrate
```

`manage.py` 以 `schema_migrations` 記錄檔名與 SHA-256；同一檔案 checksum 改變會停止，不會靜默重跑。每個 migration 在 transaction 中執行。

## 失敗處理

失敗時 transaction rollback；保留 migration log，修正為新的 migration 檔後重試。production PostgreSQL 的 backup／PITR 由部署環境負責，不以 Cloudflare D1 bookmark 代替。

## 禁止事項

- 不使用 `wrangler d1`、D1 migration 或 SQLite mirror。
- 不修改已套用 migration；新增 migration 並更新 checksum。
- 不把 production `DATABASE_URL` 放入 `.dev.vars`、CI log 或 commit。
