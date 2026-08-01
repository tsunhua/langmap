# Dev 與 Production 資料管理體系實作計畫

> 對應規格：`docs/superpowers/specs/2026-08-01-dev-production-data-management-design.md`
>
> 狀態：已實作（Task 1–10 完成）；production mutation 仍要求 operator 明確授權。

## 1. 交付目標

建立唯一日常資料管理入口：

```text
./dev.sh
./scripts/db/manage.sh local status|rebuild|verify
./scripts/db/manage.sh production inventory|plan|apply|verify|restore
```

Dev D1 可安全丟棄並由完整 schema、pinned language registry 與 system UI translation
bundle 重建。Production D1 只由唯一 operator 手動執行 forward migration、reference
sync 與 Time Travel restore，所有步驟具備 identity check、preflight、journal 與失敗即停。

## 2. 全域約束

- 先測試後實作；每個 task 先確認新增測試因缺少行為而失敗。
- 保留 `scripts/v2/migrate.sh` 作為 v1 → v2 歷史工具，不將其擴成日常入口。
- 不修改或重新命名已發布的 `backend/migrations/*.sql`。
- 不手工修改 generated reference artifacts；所有變更回到 source／generator。
- Production 指令不自動 deploy Worker，也不由 CI 自動執行。
- Production 不建立本地 export，只使用 Cloudflare D1 Time Travel bookmark。
- 不從 production 同步 users、expressions、contributions 或 community data 到 dev。
- 不執行 remote mutation，直到 production inventory 與 baseline 報告由 operator review。
- 所有 remote 測試使用 fake Wrangler fixture；真實 production 僅執行明確授權的唯讀 inventory。
- 清理 local state 時只允許已解析且等於 repo 下 `backend/.wrangler/state` 的路徑。
- Operation reports、locks、fingerprints 與 production inventory 放在 git ignored state 目錄。

## 3. 實作形狀

採用薄 shell wrapper 加 Python core：

```text
scripts/db/manage.sh       固定入口、strict shell、定位 repo
scripts/db/manage.py       command parsing 與流程協調
scripts/db/lib/            fingerprint、manifest、wrangler、verification modules
scripts/db/tests/          unittest 與 fake Wrangler fixtures
scripts/db/state/          git ignored operation state／reports
```

Python 僅使用標準函式庫。所有 subprocess 以 argument array 執行，不經 `shell=True`，
避免任意 SQL／command injection。SQL 只從版本控制內的批准檔案載入。

## 4. 依賴順序

```text
Task 1 management core
  → Task 2 migration lock + bootstrap fingerprint
    → Task 3 deterministic UI translation bundle
      → Task 4 local rebuild + verify
        → Task 5 dev.sh orchestration
          → Task 6 production inventory + baseline
            → Task 7 production plan
              → Task 8 production apply + journal
                → Task 9 restore
                  → Task 10 full verification + runbooks
```

## 5. Tasks

### Task 1：建立資料管理 core 與安全 command boundary

**Files**

- Create: `scripts/db/manage.sh`
- Create: `scripts/db/manage.py`
- Create: `scripts/db/lib/__init__.py`
- Create: `scripts/db/lib/paths.py`
- Create: `scripts/db/lib/runner.py`
- Create: `scripts/db/tests/test_manage.py`
- Modify: `.gitignore`

**Steps**

1. 先新增 CLI tests，確認：
   - 無 environment／command 時退出 2 並顯示 usage；
   - 只接受 `local`／`production`；
   - local 只接受 `status`／`rebuild`／`verify`；
   - production 只接受 `inventory`／`plan`／`apply`／`verify`／`restore`；
   - restore 缺 bookmark 時拒絕；
   - 不接受任意 SQL 或未知 trailing args。
2. 執行 `python3 -m unittest discover -s scripts/db/tests -v`，確認 RED。
3. 建立 strict `manage.sh`，只解析 repo root 並 `exec python3 manage.py`。
4. 在 `paths.py` 集中解析且驗證 repo root、backend、migration、artifact、local D1
   state、operation state 路徑；拒絕 `/`、home、repo root 與 symlink escape 作為清理目標。
5. 在 `runner.py` 建立 subprocess wrapper，固定 argument array、captured stdout/stderr、
   timeout、redaction 與非零即拋錯；禁止 `shell=True`。
6. `manage.py` 只完成 command dispatch stub，尚不修改資料。
7. `.gitignore` 加入 `/scripts/db/state/`，保留目錄說明文件則使用 `.gitkeep` 外的
   tracked README。
8. 重跑 tests 與 `git diff --check`。

**Commit**

```text
feat: add database management command boundary
```

### Task 2：建立 migration lock、fingerprint 與 operation lock

**Files**

- Create: `scripts/db/lib/migrations.py`
- Create: `scripts/db/lib/fingerprint.py`
- Create: `scripts/db/lib/locking.py`
- Create/Generate: `scripts/db/migration-lock.json`
- Create: `scripts/db/tests/test_migrations.py`
- Create: `scripts/db/tests/test_fingerprint.py`
- Create: `scripts/db/tests/fixtures/migrations/`

**Steps**

1. 先測試 migration discovery：穩定 filename 排序、只接受 `NNNN_name.sql`、拒絕
   duplicate sequence、gap policy 違反、空檔案與 symlink。
2. 先測試 migration lock：記錄 filename、SHA-256、size；已發布 checksum 改變或
   lock 缺檔都失敗；新增 migration 只在明確 `lock --update` 模式加入。
3. 先測試 fingerprint 包含：schema、migration lock、language manifest、UI bundle
   manifest、dev fixture version；只要其中一項改變，fingerprint 必須改變。
4. 先測試 operation lock：同環境第二個 process 失敗；stale lock 需顯示 owner／時間，
   不自動刪除；只有明確 unlock command 且 PID 不存在才可清理。
5. 實作純函式並生成當前 migration lock。初次 lock 明確標記 `baseline_created_at` 與
   Git commit，不修改 D1。
6. 在 `manage.py local status` 顯示 desired fingerprint、stored fingerprint、state
   existence 與 `rebuild_required`，不修改 local state。
7. 驗證兩次生成 lock／fingerprint deterministic。

**Commit**

```text
feat: track database migration and bootstrap integrity
```

### Task 3：生成 deterministic system UI translation bundle

**Files**

- Modify: `scripts/i18n/generate-i18n-sql.py`
- Create: `scripts/i18n/generate-bundle.py`
- Create: `scripts/i18n/artifacts/system-ui/manifest.json`
- Create: `scripts/i18n/artifacts/system-ui/system-ui.sql`
- Create: `scripts/i18n/test_generate_bundle.py`
- Modify: `scripts/i18n/test-import-all.sh`
- Modify: `scripts/i18n/README.md`

**Steps**

1. 先新增 tests，固定 source catalog 與 locale fixtures，涵蓋：
   - locales 與 keys 穩定排序；
   - deterministic expression／edge IDs；
   - SQL quote escaping；
   - unknown source key 使生成失敗，不再只 warning／skip；
   - duplicate deterministic ID collision 被偵測；
   - bundle manifest 包含 schema version、source checksums、locale／message／translation
     counts 與 output SHA-256；
   - 生成失敗不替換既有 artifact。
2. 將現有 generator 的 parsing／ID／SQL renderer 拆成可 import 純函式，不改既有
   translation 語義。
3. `generate-bundle.py` 一次讀取 `en.ts` 與四個 first-party translation JSON，產生
   單一 temporary SQL 與 manifest，驗證後 atomic replace。
4. SQL 先 upsert必要 locale metadata，再寫 source messages、translation expressions
   與 edges；不包含 delete。
5. Manifest 明確記錄 first-party project `langmap-web` 與 ownership scope。
6. 將 `import-all.sh` 改為 compatibility wrapper：local 使用 bundle；remote 顯示
   deprecation 並要求改用 production manager，不再直接逐 locale 寫 production。
7. 連續生成兩次確認 clean second diff，並以 temporary SQLite 載入兩次驗證 idempotent。

**Commit**

```text
feat: generate pinned system ui translation bundle
```

### Task 4：實作 disposable local rebuild 與完整 verification

**Files**

- Create: `scripts/db/lib/local.py`
- Create: `scripts/db/lib/verify.py`
- Create: `scripts/db/tests/test_local_rebuild.py`
- Create: `scripts/db/tests/test_verify.py`
- Create: `scripts/db/tests/fixtures/wrangler-local`
- Modify: `scripts/db/manage.py`

**Steps**

1. 先新增 fake Wrangler tests，確認 local rebuild 順序：
   - validate exact state path；
   - stop／確認沒有 active local writer；
   - 建立同 parent 的 temporary state；
   - 套用完整 `backend/schema.sql`；
   - 載入 language registry SQL；
   - 載入 system UI bundle；
   - 建立 `d1_migrations` baseline；
   - verify；
   - 成功後才 replace active state。
2. 測試任一步驟失敗時 active state 保持原樣，temporary state 被隔離並回報路徑；
   不使用半完成資料庫。
3. Baseline writer 必須從 migration lock 產生 `d1_migrations` rows，並在寫入前驗證
   完整 schema invariants；不得只按檔名盲目標記。
4. Verification 至少涵蓋：
   - schema objects；
   - migration names 與 checksums；
   - language manifest counts；
   - representative city count；
   - UI bundle locale／message／translation counts；
   - active locale policy；
   - orphan language、locale、message、edge count 為 0。
5. 實作 `local rebuild`、`local verify`，保存 fingerprint 與 verification report。
6. 使用 real temporary Wrangler state 執行一次 rebuild；再執行一次 verify。

**Commit**

```text
feat: rebuild and verify disposable local data
```

### Task 5：將 dev.sh 收斂為 bootstrap orchestrator

**Files**

- Modify: `dev.sh`
- Create: `scripts/db/tests/test_dev_sh.py`
- Modify: `README.md`

**Steps**

1. 先新增 shell orchestration tests，使用 PATH fake commands 驗證：
   - fingerprint 一致時只 `local verify` 後啟動；
   - fingerprint 不一致時執行 `local rebuild`；
   - `--rebuild` 強制重建；
   - `--no-rebuild` 在不一致時失敗；
   - bootstrap／verify 失敗時 Wrangler 與 Vite 均未啟動；
   - port forwarding 與 cleanup 行為維持。
2. 刪除 `dev.sh` 的 table count、inline DDL、migration `|| true` 與 registry 直載邏輯。
3. `dev.sh` 僅處理 secret／dependencies、停止本 repo 殘留 process、呼叫 manager、
   啟動 backend／frontend 與 signal cleanup。
4. Process cleanup 使用 pidfile／command identity，不以廣泛 `pkill -f "wrangler dev"`
   終止其他專案。
5. 實際執行 `./dev.sh --rebuild`，驗證 languages 與 system UI translations 已寫入。
6. 第二次啟動驗證 fingerprint hit，不重建 D1。

**Commit**

```text
refactor: make dev startup use reproducible data bootstrap
```

### Task 6：建立 production 唯讀 inventory 與受審 baseline

**Files**

- Create: `scripts/db/lib/production.py`
- Create: `scripts/db/lib/journal.py`
- Create: `scripts/db/production-baseline.json`
- Create: `scripts/db/tests/test_production_inventory.py`
- Create: `scripts/db/tests/fixtures/wrangler-production`
- Modify: `scripts/db/manage.py`

**Steps**

1. 先測試 production identity 必須同時匹配 config 中的 database name 與 UUID；任何
   缺失、placeholder、歧義或 mismatch 都阻擋。
2. 以 fake Wrangler 測試 `production inventory` 只執行 `info` 與 SELECT，不出現
   migration apply、INSERT、UPDATE、DELETE、restore 或 deploy。
3. Inventory 收集：database identity、table／index／trigger schema、`d1_migrations`、
   migration-relevant column、reference counts、ownership counts、核心 application row
   counts 與 orphan checks。
4. Inventory 寫入 git ignored report；console 只顯示摘要，不輸出 application row。
5. `production-baseline.json` 是版本控制內的批准契約，包含預期歷史 migration
   checksum 與 schema invariants，不包含 remote row counts、bookmark 或 credentials。
6. 新增 `baseline check` 純函式：只有 inventory schema 與全部 migration effects
   都符合時才允許將歷史 migration 視為已採用；不得直接寫 remote `d1_migrations`。
7. 真實 production 僅在 operator 明確授權後執行 inventory；本 task 預設只完成
   local fixture 與命令，不 mutation remote。

**Commit**

```text
feat: inventory production database state safely
```

### Task 7：實作 production plan 與 reference diff

**Files**

- Modify: `scripts/db/lib/production.py`
- Create: `scripts/db/lib/reference.py`
- Create: `scripts/db/tests/test_production_plan.py`
- Create: `scripts/db/tests/test_reference_diff.py`
- Modify: `scripts/db/manage.py`

**Steps**

1. 先測試 `production plan` 唯讀，並輸出：pending migrations、checksum status、
   schema preflight、language／UI bundle versions、insert／update／unchanged／manual-review
   counts 與 risk classification。
2. Reference diff 只能查詢受 ownership 管理的 key；不得把 artifact 缺少的 remote row
   列為 delete。
3. 對缺少可靠 ownership 的 table，plan 必須回報 blocked，而不是猜測。
4. Migration risk scanner 依批准 metadata 分類 additive、table rebuild、bulk update／
   delete、many-to-one merge；SQL text heuristic 只能提示，不作唯一安全判定。
5. 為高風險 migration 建立 sidecar metadata contract，例如
   `backend/migrations/0012_name.meta.json`，要求 preflight／postflight assertions。
6. Plan 生成 operation ID 與 JSON／human-readable report，不建立 bookmark、不寫 D1。
7. 用 fake Wrangler snapshot 比較 plan 前後，證明 remote state 未改變。

**Commit**

```text
feat: plan production data changes before execution
```

### Task 8：實作 production apply、bookmark 與 operation journal

**Files**

- Modify: `scripts/db/lib/production.py`
- Modify: `scripts/db/lib/journal.py`
- Create: `scripts/db/tests/test_production_apply.py`
- Create: `scripts/db/tests/fixtures/time-travel-bookmark.json`
- Modify: `scripts/db/manage.py`

**Steps**

1. 先測試 apply 必須有成功且未過期的 plan report、clean migration lock 與相同 Git
   commit；任一變化要求重跑 plan。
2. 測試先取得 Cloudflare Time Travel bookmark，再要求輸入完整 production database
   name；bookmark 失敗或確認不符時沒有任何 D1 mutation。
3. 測試執行順序固定為 migration → approved data migration → language bundle → UI
   bundle → verify；任一步非零即停止，後續 command 不執行。
4. Wrangler migration apply 後重新 inventory `d1_migrations`，不得只信 CLI exit code。
5. Reference sync 使用版本控制內 temporary execution files；不接受 command-line SQL。
6. Journal atomic append operation state，記錄 identity、Git commit、dirty status、plan、
   migration／bundle checksums、bookmark、row count reconciliation、result 與 failed stage。
7. Apply 成功只輸出「資料變更已驗證，可進行 deploy」，不自動呼叫 deploy。
8. 所有 tests 使用 fake Wrangler；不在 automated tests 呼叫真實 remote mutation。

**Commit**

```text
feat: apply production data changes with recovery bookmark
```

### Task 9：實作 Time Travel restore 與 restore 後驗證

**Files**

- Modify: `scripts/db/lib/production.py`
- Modify: `scripts/db/lib/journal.py`
- Create: `scripts/db/tests/test_production_restore.py`
- Modify: `scripts/db/manage.py`

**Steps**

1. 先測試 bookmark format、production identity、operation journal lookup 與確認字串。
2. Restore 前執行唯讀 current inventory，寫入 restore operation journal。
3. 呼叫官方 Time Travel restore；解析並記錄回傳的 `previous_bookmark`，讓錯誤 restore
   可再次恢復。
4. Restore 成功後強制執行完整 production verify；verify 失敗時明確回報 production
   state 需人工處理，不自動重放 migration／reference sync。
5. Restore command 不接受 timestamp shortcut；第一版只接受已記錄 bookmark，減少
   選錯時間的風險。
6. Fake tests 覆蓋 restore API 失敗、previous bookmark 缺失、verify 失敗與成功 journal。

**Commit**

```text
feat: restore production d1 from recorded bookmarks
```

### Task 10：完整驗證、runbooks 與舊入口收斂

**Files**

- Modify: `docs/superpowers/specs/2026-08-01-dev-production-data-management-design.md`
- Create: `docs/runbooks/database-migrations.md`
- Create: `docs/runbooks/reference-data-sync.md`
- Create: `docs/runbooks/dev-database.md`
- Create: `docs/runbooks/production-data-release.md`
- Create: `docs/runbooks/d1-time-travel-restore.md`
- Modify: `scripts/i18n/README.md`
- Modify: `scripts/v2/README.md`
- Modify: `backend/package.json`
- Modify: `README.md`

**Steps**

1. 文件明確區分：完整 schema、forward migration、data migration、reference sync、
   application data 與 v1 → v2 historical migration。
2. 五份 runbook 每份包含 prerequisite、plan、apply、verify、failure handling 與禁止事項。
3. `backend/package.json` 將直接 remote migration script 改名為 internal／dangerous，或
   移除 operator-facing alias；README 只推薦 manager 入口。
4. 更新設計 spec 狀態為「已實作」，列出實際命令與保留限制。
5. 執行：

   ```bash
   python3 -m unittest discover -s scripts/db/tests -v
   python3 scripts/v2/test_language_data.py
   python3 scripts/i18n/test_generate_bundle.py
   bash scripts/i18n/test-import-all.sh
   ./scripts/db/manage.sh local rebuild
   ./scripts/db/manage.sh local verify
   ./dev.sh --rebuild
   cd backend && npm test
   cd web && npm run build
   ./build.sh
   git diff --check
   ```

6. Backend integration tests 需 Worker `127.0.0.1:8788`；啟動後重跑完整 suite。
7. 驗證 desktop／mobile 基本頁面、languages、representative cities 與 locale message。
8. 用 fake Wrangler 執行 production inventory／plan／apply／restore 全流程，確認沒有
   真實 remote call。
9. 最終 code review 特別檢查 destructive path validation、production identity、
   bookmark-before-mutation、journal redaction、ownership boundary 與 fail-closed 行為。

**Commit**

```text
docs: document safe database operations
```

## 6. 首次導入與停止條件

首次 production 導入刻意分兩個人工 gate：

1. 實作完成後，只執行 `production inventory` 與 `production plan`。
2. Operator review inventory、baseline 與 plan 後，另行明確授權 `production apply`。

以下任一情況必須停止，不得以 fallback 繼續：

- production name／UUID 不匹配；
- `d1_migrations` 與 migration lock 不一致；
- 無法證明歷史 migration effects 已存在；
- migration checksum 改變；
- ownership 不明；
- Time Travel bookmark 取得失敗；
- plan 與 apply 的 Git commit／artifact checksum 不一致；
- preflight、SQL、reference reconciliation 或 postflight 失敗；
- local rebuild target 無法證明是本 repo 專屬 state。

## 7. 完成定義

- `./dev.sh` 不再含 inline DDL／DML 或 migration `|| true`。
- Dev 可一鍵重建，默認包含語言、代表性城市與 system UI translations。
- 指紋一致時 dev 不重建；不一致時行為符合 flags。
- Migration history 與 schema 可驗證，已發布 checksum 受 lock 保護。
- Production inventory／plan 唯讀且目標 identity 明確。
- Production apply 在任何 mutation 前取得並記錄 bookmark。
- Reference sync 不刪除缺失 row、不越過 ownership boundary。
- Restore 記錄 previous bookmark 並自動 verify。
- 所有操作入口、runbook、tests 與生成 artifacts 可由全新 checkout 重現。
