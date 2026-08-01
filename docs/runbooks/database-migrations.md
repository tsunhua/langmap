# Database Migration Runbook

## 前置條件

- migration 檔名連號且已通過 `scripts/db/migration-lock.json` checksum 驗證。
- schema、migration effect 與 rollback/Time Travel 方案已 code review。
- 先在 local rebuild 與 tests 驗證。

## Plan / Apply / Verify

```bash
./scripts/db/manage.sh production inventory
./scripts/db/manage.sh production plan
```

只有 operator 審核 plan 後，才可使用 plan 指定的 production apply gate。apply 會先
取得 bookmark，依 migration → approved data → reference bundles → verify 順序執行，
且不自動 deploy。

```bash
./scripts/db/manage.sh production apply \
  --plan scripts/db/state/production/plans/<operation-id>.json \
  --database-name <完整資料庫名稱> \
  --confirm-production <完整資料庫名稱>
```

## 失敗處理

任一 preflight、checksum、SQL 或 postflight verify 失敗即停止；查看 operation journal
與 bookmark，交由 operator 決定是否 restore。不要手動重放後續 stage。

## 禁止事項

- 不直接執行 `wrangler d1 migrations apply --remote`。
- 不修改已發布 migration；新增 migration 並更新 lock。
- 不以 CLI exit code 代替 post-apply inventory/verify。
