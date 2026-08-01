# D1 Time Travel Restore Runbook

## 前置條件

- 只使用 operation journal 中記錄的 bookmark；不接受 timestamp shortcut。
- 確認 production database name 與 operator approval。
- 確認 restore 後預期的 migration/schema baseline。

## Restore / Verify

```bash
./scripts/db/manage.sh production restore <已記錄 bookmark> \
  --database-name <完整資料庫名稱> \
  --confirm-production <完整資料庫名稱>
```

restore 前先 inventory，官方回應的 `previous_bookmark` 會寫入 journal；restore 後
強制 inventory 與 baseline verify。

## 失敗處理

若 previous bookmark 缺失或 post-restore verify 失敗，狀態為
`needs_manual_intervention`。保留 current/previous bookmark，停止所有自動 migration、
reference sync 與 deploy；由 operator 重新評估。

## 禁止事項

- 不用猜測 timestamp 或自行拼接 bookmark。
- 不在 restore 失敗後自動重放 migration。
- 不把 restore 當成 deploy 或資料修復的替代品。
