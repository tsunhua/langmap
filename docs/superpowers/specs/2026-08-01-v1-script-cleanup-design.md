# V1 腳本清理設計

## 狀態

本文件描述預定清理範圍，尚未實作。實作前須另行提出並確認執行計畫。

## 目標

移除現行 LangMap V2 不再使用的 V1 歷史腳本、一次性資料修復工具與舊資料匯入程式，同時保留可將既有 V1 資料庫完整遷移至 V2 所需的工具與資料。

## 判定原則

以現存 V1 資料庫作為遷移輸入，不要求從原始資料重建完整 V1 歷史。檔案符合以下任一條件時保留：

1. 被 `scripts/v2/migrate.sh`、`scripts/v2/migrate.ts`、`dev.sh` 或相關測試直接或間接使用。
2. 用於建立 V1 staging database，以承接無 schema 的遠端分表匯出。
3. 屬於目前仍使用的獨立維護流程，例如網站介面翻譯匯入。
4. 是本機資料、遷移中間產物、依賴、建置輸出或工具 cache；本次一律保留，不以使用時間推定是否可刪。

不被 V1→V2 遷移流程使用、只曾建立或修復 V1 歷史狀態的檔案可以刪除。

## 保留範圍

- `scripts/init-db.sql`：建立本機 V1 staging schema，供無 schema 的遠端分表 SQL 匯入。
- `scripts/v2/` 的全部已追蹤內容：包含 migration runner、轉換函式、fixture、語言 registry、人工 migration manifest、測試及必要資料。
- `scripts/i18n/`：2026-07-29 至 2026-07-30 加入的現行介面翻譯匯入流程。
- `backend/schema.sql` 與 `backend/migrations/`。
- `dev.sh`、`build.sh`。
- 被 Git 忽略的 `scripts/v2/remote-*.sql`、`scripts/v2/remote-old.sql` 與 `scripts/v2/v2-data.sql`。
- 所有依賴、build output、本機資料庫狀態與工具 cache。
- `.dev.vars` 等本機開發設定。

## 刪除範圍

### 已追蹤的歷史檔案

- 根層 `scripts/001_*` 至 `scripts/043_*` 的歷史 schema、migration、資料修復與輔助檔，但不包含 `scripts/init-db.sql`、`scripts/i18n/` 或 `scripts/v2/`。
- `scripts/migrate.sh`。
- `scripts/migrate_i18n_tags.js`。
- `scripts/cleanup_fts.sql`。
- `scripts/004_opus_data/`。
- `scripts/025_batch_add_expressions/`。
- `scripts/csv_d1_sync/`。
- 沒有對應根層 `package.json` 的根層 `package-lock.json`。

實作計畫必須把上述模式展開為明確檔案清單，再執行刪除，避免 glob 誤傷保留內容。

### 純垃圾檔

- `.DS_Store`。
- `__pycache__/`。
- `*.pyc`。

純垃圾清理不得擴張為一般 cache 清理。

## 明確非目標

本次不得刪除或清空：

- `.opencode/`。
- `.ruff_cache/`。
- `.venv/`。
- 任一 `node_modules/`。
- `web/dist/`。
- `backend/public/`。
- `backend/.wrangler/`。
- `backend/backend/`。
- `.dev.vars`。
- 任何未追蹤的 migration SQL、SQLite database 或遷移中間資料。

本次不修改 V1→V2 的資料模型、轉換行為、API 契約或前後端功能。

## 文檔策略

- 更新 `scripts/v2/README.md`，確保現行遷移步驟只引用保留檔案。
- 檢查並按需更新 `README.md` 與 `docs/README.md` 的現行入口。
- `docs/plans/`、`docs/design/` 與 `docs/superpowers/plans/` 是歷史設計紀錄，不逐條改寫；其中對已刪腳本的引用仍代表當時狀態。
- `.gitignore` 只在純垃圾未被現有規則涵蓋時最小修改，不加入任何主動清除 cache 的機制。

## 執行安全

- 刪除前確認工作樹狀態，保留使用者既有未提交變更。
- 已追蹤檔案使用精確路徑刪除，不以寬泛 glob 或遞迴命令直接操作。
- 未追蹤垃圾檔只處理已明確核准的三種類型。
- 不連線或修改遠端 D1。
- 不清空、重建或寫入真實本機 V1/V2 database。
- 若候選檔案與現行程式仍有有效引用，停止刪除該檔並重新評估。

## 驗證

依序執行：

1. 清理前執行 `scripts/v2` 的 TypeScript 與 Python 基準測試。
2. 展開並核對精確刪除清單。
3. 執行核准的刪除與必要文檔更新。
4. 搜尋有效程式與現行文檔中的失效引用。
5. 執行 `scripts/v2` TypeScript 測試。
6. 執行 `scripts/v2` Python 語言資料測試。
7. 執行 `cd web && npm run build`。
8. 執行 `git diff --check`。
9. 若 repository fixture 足以完成離線遷移，執行 fixture migration；不得使用真實本機或遠端資料庫補足驗證。

後端整合測試需要運行中的本機 Worker 與 D1；若清理未修改後端程式或 schema，可不列為必要驗收。若實作期間出現後端相關變更，則須補跑相關測試。

## 驗收標準

- 核准的 V1 歷史腳本與純垃圾已移除。
- 所有明確保留的 cache、依賴、build output、本機 D1 狀態與遷移中間資料保持不變。
- V1→V2 遷移入口及其必要依賴仍完整存在。
- 現行文檔沒有指向已刪檔案的操作步驟。
- 必要測試、前端 build 與 `git diff --check` 通過；無法執行的驗證有明確原因與剩餘風險。

## 恢復

已追蹤檔案可從清理前 Git commit 恢復。純垃圾檔不提供恢復保證。由於未追蹤的資料庫、遷移中間資料與 cache 均不在刪除範圍，本次不需要為它們建立額外備份。
