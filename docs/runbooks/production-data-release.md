# Production Data Release Runbook

## 前置條件

- reviewed Git commit、clean migration lock、production identity 與 approved baseline。
- local tests、local rebuild/verify、bundle checksum 均通過。
- operator 已審核 inventory 與 plan；本 runbook 不自動 deploy。

## Plan / Apply / Verify

```bash
./scripts/db/manage.sh production inventory
./scripts/db/manage.sh production plan
./scripts/db/manage.sh production apply \
  --plan scripts/db/state/production/plans/<operation-id>.json \
  --database-name <完整資料庫名稱> \
  --confirm-production <完整資料庫名稱>
```

apply 先取得並 journal bookmark，再按固定順序執行；成功訊息只表示資料變更已驗證，
仍須另行執行 deploy 流程。

## 失敗處理

讀取 `scripts/db/state/production/operations.jsonl` 與 plan report。bookmark 取得失敗、
identity mismatch、plan commit 改變、ownership 不明或 verify 失敗時停止並人工處理。

## 禁止事項

- 不繞過 plan、confirmation 或 bookmark gate。
- 不在 apply 腳本中呼叫 deploy。
- 不在沒有 postflight verify 的情況下宣告 release 成功。
