# Dev D1 Runbook

## 前置條件

- Node.js、npm 與 backend dependencies 已安裝。
- `backend/.dev.vars` 已設定；不把 secret 提交到 Git。

## 操作

```bash
# 第一次啟動，或 schema／registry fingerprint 確實變更時
./dev.sh
./scripts/db/manage.sh local status
./scripts/db/manage.sh local verify
```

`dev.sh` 預設依 fingerprint 判斷是否重建：fingerprint 命中時只做 verify，只有
fingerprint 變更時才 rebuild。重建會使用 schema、locked migrations、language registry、
system UI bundle 與本機開發帳號（`dev@example.com` / `dev`）建立 repo 專屬本地 D1，
成功驗證後才替換 active state。此帳號不進入 production migration。

### 只重啟服務

若 local D1 與服務都已正常，只是要重啟 Web/API，不要為了重啟反覆執行 rebuild。
保留現有服務即可；若確實需要重新啟動，執行一次 `./dev.sh`，讓 fingerprint 判斷
是否需要 rebuild。`--rebuild` 只用於明確要求丟棄並重建 local D1 的情況；`--no-rebuild`
是 CI／診斷用的 fail-closed 選項，不是繞過 schema 不一致的啟動模式。

詞典匯入後若要在本機查看，先完成一次 rebuild，再將 JSONL 匯入該 disposable local D1；
不要因為匯入資料而重建。若 schema／registry 在匯入後變更，應先完成變更、重建一次，
再重新匯入資料。

## 失敗處理

若 verify 失敗，保留 active state 不變；查看錯誤中的 temporary state，修正來源或
artifact 後重新執行 rebuild。不要手動對 active D1 套用部分 SQL。

## 禁止事項

- 不刪除其他專案的 Wrangler state 或 process。
- 不把 `.dev.vars`、`.wrangler/` 或 local report 提交。
- 不以 `--remote` 取代 local rebuild。
