# Dev 與 Production 資料管理體系設計

> 狀態：已實作（Task 1–10 完成）；production mutation 仍要求 operator 明確授權。
>
> 範圍：Cloudflare D1 schema migration、reference data 同步、dev bootstrap、
> production 操作與回復。本文不改變應用程式的資料模型。

## 1. 背景與問題

LangMap 目前同時使用 `backend/schema.sql`、`backend/migrations/`、`dev.sh` 內嵌
SQL、`scripts/v2/migrate.sh`、語言 registry artifacts 與 i18n 匯入腳本管理
資料庫。各入口對 schema、migration history 與資料 ownership 的理解不一致。

既有本地 D1 已有完整 schema，但 `d1_migrations` 為空。Wrangler 因而嘗試從
`0002_add_name_en.sql` 重跑歷史 migration，遇到已存在的 `name_en` 後失敗；
`dev.sh` 又以 `|| true` 忽略錯誤，後續 D1 操作撞上 SQLite lock。這表示目前
啟動流程會猜測資料庫狀態，無法提供可重現的 dev 環境，也不足以安全操作
production。

本設計採用分層生命週期：dev D1 可丟棄並重建；production D1 長期保存，只由
唯一 operator 手動執行受版本控制的 migration 與同步腳本。

## 2. 目標

- 一條命令建立可直接開發的 local D1，包含語言與系統 UI 翻譯。
- schema、reference data、application data 與 environment state 各有唯一修改入口。
- production 變更可預檢、可追溯、失敗即停，且執行前具有官方回復點。
- migration history 與實際 schema 始終一致，不再以 table count 猜測版本。
- reference sync deterministic、idempotent，且不覆寫 application／community data。
- dev 與 production 共用同一份版本控制來源，但採取不同生命週期。

## 3. 非目標

- 不建立多人審批、CI 自動套用 production migration 或角色權限工作流。
- 不從 production 自動複製 users、expressions 或 contributions 到 dev。
- 不建立本地 production export；回復使用 Cloudflare D1 Time Travel。
- 不為已發布 migration 建立一般化 down migration。
- 不在本項目新增 staging；日後新增時沿用 production 流程並使用獨立 D1。

## 4. 資料層與單一真實來源

### 4.1 Schema

- `backend/schema.sql` 是新資料庫的完整最終結構，只用於建立空資料庫。
- `backend/migrations/*.sql` 是既有 production schema 前進的唯一方式。
- 每次 schema 變更必須同時更新完整 schema 並新增 migration。
- 已發布 migration 不得修改、重命名或刪除；工具記錄並核對其 checksum。
- production migration 採 forward-only。一般錯誤以 corrective migration 修正。
- 不相容變更採 expand／migrate／contract，避免同一次部署先刪除舊欄位。

### 4.2 Reference data

Reference data 包含：

- 語言 profiles、languoids、IANA subtags、代表性城市；
- 第一方 UI locale metadata、message definitions、翻譯 expressions 與 mappings；
- 其他明確標記為 `seed` 或 `system` 的 pinned data。

Reference data 遵循：

```text
source → deterministic artifact → database sync
```

只有 source 可以人工編輯。generator 輸出帶 schema version、來源版本、row count
與 checksum 的 artifact。production 只載入已提交的 pinned artifact，不在部署時
下載最新外部資料。

### 4.3 Application data

Users、expressions、contributions、community languages 與其他 runtime 產生的資料
屬於 application data。dev rebuild、reference sync 與一般部署不得用來源 bundle
覆寫、清空或回灌這些資料。必要變更必須使用明確、可審核的 data migration。

### 4.4 Environment state

- Dev D1 可丟棄，只由統一 bootstrap 建立，不維護舊 local schema 相容性。
- Production D1 長期保存，只允許受版本控制的 migration、data migration 與
  reference sync 修改。
- Production database name 與 UUID 必須同時匹配批准的設定，不能僅依 shell
  environment variable 推斷目標。

## 5. Dev bootstrap

### 5.1 固定流程

`./dev.sh` 執行以下流程：

1. 停止本 repo 殘留的 Wrangler／Worker process。
2. 取得 operation lock，避免兩個 bootstrap 同時操作 local D1。
3. 清除並重建本 repo 專屬的 local D1 state。
4. 使用 `backend/schema.sql` 建立完整 schema。
5. 建立與當前 migration 集合一致的 local migration baseline。
6. 載入 pinned language registry bundle。
7. 載入第一方 system UI locale 與 translation bundle。
8. 視需要載入版本控制內的 dev fixture；預設不拉 production data。
9. 執行 bootstrap verification。
10. 全部成功後才啟動 Worker 與 Vite。

任何步驟失敗立即停止，不允許 `|| true`、後備 schema 猜測或 inline 修補 SQL。
`dev.sh` 只協調流程，資料庫操作委託統一管理工具。

### 5.2 指紋與重建條件

Dev state 保存一個 bootstrap fingerprint，至少涵蓋：

- `backend/schema.sql` checksum；
- migration filename 與 checksum；
- language registry manifest／artifact checksum；
- system UI translation bundle checksum；
- dev fixture version。

預設行為：

- fingerprint 相同：直接啟動服務；
- fingerprint 不同或 state 不完整：自動重建；
- `./dev.sh --rebuild`：強制重建；
- `./dev.sh --no-rebuild`：不允許重建，若 fingerprint 不一致則明確失敗。

### 5.3 Bootstrap verification

啟動前至少確認：

- 所有必要 table、index、trigger 與 FTS 結構存在；
- migration baseline 完整且無未知 migration；
- language、languoid、subtag 與 representative city 筆數符合 manifest；
- 第一方 locale、active locale、message keys 與 translation mappings 符合 bundle；
- 沒有 orphan language／locale／mapping reference；
- `/health`、languages、locale messages 與代表性城市 smoke checks 可通過。

## 6. Production 操作流程

### 6.1 Operator 模型

Production 由唯一 operator 手動操作，不由 CI/CD 自動套用 migration。所有操作
經單一工具，例如：

```bash
./scripts/db/manage.sh production plan
./scripts/db/manage.sh production apply
./scripts/db/manage.sh production verify
./scripts/db/manage.sh production restore <bookmark>
```

Production 必須顯式寫出環境名稱；工具不提供默認 production 模式，也不接受
任意 SQL 字串作為參數。

### 6.2 Plan

`plan` 完全唯讀：

- 確認 database name 與 UUID；
- 顯示已套用與待套用 migration；
- 比對已發布 migration checksum；
- 執行 schema／data preflight；
- 顯示 reference sync 的 insert、update、unchanged 與需人工處理筆數；
- 分類 additive、table rebuild、bulk update/delete、many-to-one merge 等風險；
- 產生 operation ID 與 execution plan，但不修改 D1。

一般 reference sync 不提供隱式 delete。需要退役 seed 時，以明確 data migration
執行，並在 plan 中顯示引用與 row count 影響。

### 6.3 Apply

`apply` 依序：

1. 重新核對 production database name 與 UUID。
2. 取得 Cloudflare D1 Time Travel bookmark。
3. 將 bookmark、operation ID、Git commit 與預檢結果寫入 operation journal。
4. 要求 operator 輸入指定 production database name 確認。
5. 依 filename 順序執行 schema migrations。
6. 執行已批准的 data migrations。
7. 同步 pinned reference bundles。
8. 執行 postflight assertions 與 row count reconciliation。
9. 完成 journal；全部成功後才允許部署 Worker。

無法取得 bookmark、identity 不符、歷史 checksum 改變、preflight 失敗或任何 SQL
失敗時立即停止，不繼續下一階段。

推薦發布順序：

```text
bookmark → preflight → schema/data migration → reference sync
→ verification → Worker deploy → API smoke test
```

### 6.4 Restore

`restore <bookmark>` 必須：

1. 核對 database name 與 UUID；
2. 顯示目標 bookmark 與相關 operation journal；
3. 再次要求 production identity confirmation；
4. 使用 Cloudflare D1 Time Travel restore；
5. 記錄 restore 回傳的 previous bookmark；
6. 自動執行完整 production verify；
7. 不自動重放失敗 operation。

本設計不建立本地 production export。一般錯誤優先 forward-fix；只有嚴重資料
破壞或無法安全 forward-fix 時才使用整庫 restore。

## 7. Reference bundle 與同步契約

### 7.1 Artifact contract

每個 bundle manifest 至少包含：

- `bundle_type` 與 `schema_version`；
- source file／release versions；
- generator version 或 Git commit；
- 各資料集 row count；
- 每個 artifact 的 SHA-256；
- deterministic sort contract。

Generator 必須可離線重現；同一輸入連續生成兩次不得產生 diff。生成失敗不得
留下 partial artifact 或更新 manifest。

### 7.2 Ownership boundary

- Sync 只能修改具有明確 `seed`／`system` ownership 的 row。
- `community` 與 runtime application rows 不參與一般 sync。
- 若現有 table 無法可靠區分 ownership，必須先以 migration 補足 ownership，不能
  透過名稱、code prefix 或「不在 artifact 裡」推測。
- Sync 預設為 idempotent upsert；缺少於 bundle 的 row 不等於應刪除。
- Schema version 不相容時立即停止，要求先執行 migration。

### 7.3 System UI translation bundle

Locale metadata、message definitions、第一方 translations 與 mappings 共同形成
一個 pinned bundle。Dev bootstrap 默認完整載入；production sync 只管理第一方
project／locale 範圍。

Bundle 缺少 translation 時保留 fallback，不刪除 production expression。同步後
驗證 active locale policy、source key 完整性、translation coverage 與 orphan
mapping count。

## 8. Operation journal

Journal 存在 git ignored 的本地 reports 目錄，不寫入 D1，避免資料庫 restore 時
操作紀錄一起倒退。Journal 不包含 token、credentials 或 application row 內容。

每次 production operation 記錄：

- operation ID、command、開始／結束時間與結果；
- database name、UUID 與環境；
- Git commit、dirty-worktree 狀態；
- migration filenames 與 checksums；
- reference bundle versions 與 checksums；
- preflight／postflight row counts；
- Time Travel bookmark；
- 若曾 restore，記錄 previous bookmark；
- 失敗階段與可重跑條件。

## 9. 工具邊界

### 9.1 `dev.sh`

- 只處理依賴、bootstrap 決策與啟動服務。
- 不包含 DDL／DML、不猜測 schema、不吞 migration 錯誤。
- 透過 `manage.sh local status/rebuild/verify` 管理資料。

### 9.2 `scripts/db/manage.sh`

Local commands：

- `local status`
- `local rebuild`
- `local verify`

Production commands：

- `production plan`
- `production apply`
- `production verify`
- `production restore <bookmark>`

工具必須使用明確路徑與 database identity，取得 operation lock，隔離本次 temporary
files，且只清理由本次 operation 建立的檔案。

### 9.3 既有工具收斂

- `scripts/v2/migrate.sh` 保留為 v1 → v2 一次性歷史資料遷移工具，不作為日常
  schema／reference 管理入口。
- `scripts/i18n/import-all.sh` 的生成與匯入能力收斂到 UI translation bundle；
  production 不再直接逐 locale 執行零散匯入。
- `backend/package.json` 的 migration scripts 可作為底層 command，但操作人員文件
  只暴露 `manage.sh`。

## 10. 錯誤處理與安全規則

- 所有腳本使用 strict mode，任何未處理錯誤立即非零退出。
- 禁止 `|| true` 忽略 migration／sync／verification 錯誤。
- 禁止以 table count、單一欄位或成功讀取作為 schema version 判定。
- 禁止模糊 glob、未解析環境變數與任意 SQL command passthrough。
- Production destructive operation 必須在 plan 中分類並再次確認。
- 同一 environment 同時間只允許一個管理 operation。
- Worker／Vite 不得在 bootstrap 或 migration 尚未完成時啟動。
- Production apply 不自動 deploy；資料驗證成功後由 operator 明確執行部署。

## 11. 測試與驗收

### 11.1 Automated tests

- 臨時 SQLite 從零載入 schema、language bundle 與 UI bundle。
- 每個 migration 以「前一版本 fixture → 下一版本」驗證 schema 與資料 invariants。
- 已發布 migration checksum 改變會被拒絕。
- Reference generator deterministic，sync 可重跑且 ownership boundary 不被突破。
- Dev fingerprint 未變時不重建；改變時重建；`--no-rebuild` 明確失敗。
- Production plan 以 fake Wrangler fixture 驗證為唯讀。
- Apply wrapper 驗證 identity、bookmark、確認字串、失敗即停與 journal。
- Restore wrapper 驗證 bookmark、previous bookmark 與 post-restore verification。

### 11.2 End-to-end acceptance

1. 全新 checkout 執行 `./dev.sh` 可建立 local D1 並啟動服務。
2. Dev 預設包含 pinned languages、representative cities 與 system UI translations。
3. 修改 schema／migration／reference source 後，dev fingerprint 觸發重建。
4. Local D1 不再出現「schema 已存在但 migration history 為空」的混合狀態。
5. Production plan 不寫入 D1，並顯示準確的 migration／sync 差異。
6. Production apply 無 bookmark 時拒絕執行。
7. 任一 migration／sync／verification 失敗時不執行後續階段或 deploy。
8. Production verify 可確認 schema、migration、reference 與核心 application data
   invariants。
9. Operation journal 足以識別操作版本、目標、回復 bookmark 與失敗階段。

## 12. 操作文件

實作需同步提供五條 runbook：

1. 新增 schema migration；
2. 更新 language／UI reference data；
3. Dev rebuild 與 fingerprint troubleshooting；
4. Production plan／apply／verify／deploy；
5. Time Travel restore 與 restore 後驗證。

## 13. 導入順序與相容策略

1. 建立 management core、manifest 與 verification，不先修改 production。
2. 建立 deterministic UI translation bundle。
3. 將 `dev.sh` 切換為 disposable rebuild 與 fingerprint。
4. 以全新 local D1 驗證完整 bootstrap。
5. 對現有 production 執行唯讀 inventory，建立可信 migration baseline。
6. 首次 production `plan` 只產生報告，由 operator review。
7. Baseline 確認後才啟用 production apply／restore。
8. 最後移除日常流程對零散 i18n import 與 inline SQL 修補的依賴。

Production baseline 是一次性的受控導入：必須核對現有 schema、migration 內容與
關鍵資料 invariants 後，才記錄哪些歷史 migration 已實際反映。不得只因檔名較舊
就直接插入 `d1_migrations`。

## 14. 參考資料

- [Cloudflare D1 Time Travel](https://developers.cloudflare.com/d1/reference/time-travel/)
- [Cloudflare D1 Wrangler commands](https://developers.cloudflare.com/d1/wrangler-commands/)
- [Cloudflare D1 import and export](https://developers.cloudflare.com/d1/best-practices/import-export-data/)
