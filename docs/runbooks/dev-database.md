# Dev D1 Runbook

## 前置條件

- Node.js、npm 與 backend dependencies 已安裝。
- `backend/.dev.vars` 已設定；不把 secret 提交到 Git。

## 操作

```bash
./dev.sh --rebuild
./scripts/db/manage.sh local status
./scripts/db/manage.sh local verify
```

`dev.sh` 預設依 fingerprint 判斷是否重建；`--no-rebuild` 可在 CI 或診斷時禁止
自動重建。重建會使用 schema、locked migrations、language registry 與 system UI
bundle 建立 repo 專屬本地 D1，成功驗證後才替換 active state。

## 失敗處理

若 verify 失敗，保留 active state 不變；查看錯誤中的 temporary state，修正來源或
artifact 後重新執行 rebuild。不要手動對 active D1 套用部分 SQL。

## 禁止事項

- 不刪除其他專案的 Wrangler state 或 process。
- 不把 `.dev.vars`、`.wrangler/` 或 local report 提交。
- 不以 `--remote` 取代 local rebuild。
