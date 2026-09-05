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
且不自動 deploy。每個 mutation stage 成功後會寫入 operation journal；舊 plan 沒有
`reference_artifacts` 欄位時維持 full-reference 行為。

```bash
./scripts/db/manage.sh production apply \
  --plan scripts/db/state/production/plans/<operation-id>.json \
  --database-name <完整資料庫名稱> \
  --confirm-production <完整資料庫名稱>
```

## 失敗處理

任一 preflight、checksum、SQL 或 postflight verify 失敗即停止；查看 operation journal
與 bookmark。暫時性失敗以同一 plan 重跑，已完成的 `migrations-applied`、`data-applied`
與 `references-applied` stage 不會再次執行，且沿用第一次 mutation 前的 bookmark。
若需回退，必須使用該 bookmark；不要手動重放後續 stage。

## 禁止事項

- 不直接執行 `wrangler d1 migrations apply --remote`。
- 不修改已發布 migration；新增 migration 並更新 lock。
- 不以 CLI exit code 代替 post-apply inventory/verify。
