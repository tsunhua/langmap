# Task 4 Report — disposable local rebuild 與完整 verification

## 實作摘要

- 新增 `scripts/db/lib/local.py`
  - 實作 `rebuild_local_state()`：
    - 僅以 `paths.local_d1_state_dir` 為唯一 active local D1 state 目標。
    - 呼叫 `ProjectPaths.ensure_safe_cleanup_target(..., allowed_root=paths.local_d1_state_dir, allow_exact_root=True)` 驗證 exact target。
    - 使用 sibling temporary state 目錄完成 schema → language registry → system UI bundle → `d1_migrations` baseline → verify。
    - verify 成功後才 swap active state。
    - 失敗時保留 active state，不使用半完成資料庫，並把 temporary state 路徑附在例外上。
  - 實作 `verify_local_environment()` 供 `manage.py local verify` dispatch 使用。
- 新增 `scripts/db/lib/verify.py`
  - 實作 local Wrangler executor。
  - 實作 schema object 驗證（table/index/trigger/FTS）。
  - 實作 `d1_migrations` baseline writer，先驗 schema invariants，再依 `migration-lock.json` 產生 rows。
  - 實作 verification report：
    - migration names/checksums；
    - language/languoid/subtag/representative city counts；
    - UI locale/message/translation counts；
    - active locale policy；
    - orphan language/locale/message/edge counts。
- 修改 `scripts/db/lib/paths.py`
  - `language_manifest_path` 改指向 pinned artifact manifest。
  - 新增 schema / artifact / report / lock 路徑 helpers。
  - 修正 `ensure_safe_cleanup_target()` 讓 `allowed_root == exact cleanup target` 成為合法情況，同時仍拒絕 root 與 symlink escape。
- 修改 `scripts/db/lib/runner.py`
  - subprocess env 改為 `os.environ` 上疊加 overrides，避免 fake Wrangler 執行時遺失基本環境。
- 修改 `scripts/db/manage.py`
  - `local status` / `local rebuild` / `local verify` 改為真 dispatch，不再共用 stub handler。
- 新增測試
  - `scripts/db/tests/test_local_rebuild.py`
  - `scripts/db/tests/test_verify.py`
  - `scripts/db/tests/fixtures/wrangler-local`
- 修改 `scripts/db/tests/test_manage.py`
  - `local rebuild/verify` CLI 測試改用 temp fixture repo + fake Wrangler 驗證 dispatch，不再誤觸真 Wrangler sandbox 限制。

## Commit

- Conventional Commit: `feat: rebuild and verify disposable local data`
- Commit hash: `cfdcc24`

## TDD RED / GREEN

### RED 1

Command:

```bash
python3 -m unittest scripts.db.tests.test_local_rebuild scripts.db.tests.test_verify -v
```

Result:

- 5 errors
- 失敗原因：
  - `ensure_safe_cleanup_target(... allowed_root=paths.local_d1_state_dir)` 把 exact target parent 視為 escape，導致所有 rebuild/verify 測試在 cleanup target 驗證即失敗。

### RED 2

同一指令重跑後：

- 1 failure, 3 errors
- 已通過：
  - `test_rebuild_refuses_to_write_baseline_when_schema_invariants_fail`
- 失敗原因：
  - verify count mismatch；
  - fake Wrangler stderr 被缺失環境變數產生的 Python warning 蓋過；
  - `system-ui.sql` failure 訊息未正確浮現。

### RED 3

同一指令重跑後：

- 5 errors
- 原因：
  - `verify.py` 中一段 Python 3.9 不接受的 f-string quoting 語法錯誤。

### GREEN

Command:

```bash
python3 -m unittest scripts.db.tests.test_local_rebuild scripts.db.tests.test_verify -v
```

Result:

```text
Ran 5 tests in 1.720s

OK
```

## Full verification

Command:

```bash
python3 -m unittest discover -s scripts/db/tests -v
```

Result:

```text
Ran 36 tests in 3.463s

OK
```

Command:

```bash
git diff --check
```

Result:

- 無輸出
- exit code 0

## fake Wrangler failure-preserves-active-state 證據

測試：

- `test_rebuild_failure_preserves_active_state_and_exposes_temp_dir`

驗證內容：

- 先在 active state 放入 sentinel 檔案 `keep.txt`。
- 令 fake Wrangler 在 `system-ui.sql` 步驟強制失敗。
- rebuild 應拋出 `LocalRebuildError`。
- 驗證：
  - active state 中的 sentinel 仍存在；
  - temporary state 目錄被保留下來；
  - 例外訊息含 `system-ui.sql`；
  - 沒有把半完成 temporary state swap 成 active state。

## verification 證據

測試：

- `test_verify_reports_expected_counts_and_zero_orphans`

fixture verification report 驗證值：

- languages = 4
- languoids = 3
- language_subtags = 3
- language_locations = 2
- ui_locales = 2
- ui_messages = 2
- ui_translation_mappings = 4
- active locale codes = `["es-ES", "zh-Hant-TW"]`
- orphan languages = 0
- orphan locales = 0
- orphan messages = 0
- orphan edges = 0

另外：

- `test_verify_rejects_unknown_migration_rows` 驗證多出的 `d1_migrations` row 會讓 verify fail。
- `test_local_accepts_only_supported_commands` 驗證 `manage.py` 的 `local rebuild` / `local verify` dispatch 會經由 temp fixture repo + fake Wrangler 成功執行。

## real temporary Wrangler 結果

本任務沒有把 real temporary Wrangler 當作 GREEN gate，原因如下：

1. 在目前桌面沙箱環境中，真 Wrangler 會嘗試：
   - 寫入 `/Users/lim/Library/Preferences/.wrangler/logs/...`
   - 在 `127.0.0.1` 開 listener
2. 這會觸發：
   - `EPERM: operation not permitted`
   - `listen EPERM: operation not permitted 127.0.0.1`
3. 因此不適合作為穩定、可重複的本地 GREEN 條件。

已做的短時間 real probe：

- 使用受控 temporary state 路徑 `/private/tmp/langmap-task4-probe.EroV1Q`
  - `wrangler d1 execute ... --file backend/schema.sql`
  - `wrangler d1 execute ... --file language-registry.sql`
  - `wrangler d1 execute ... --file system-ui.sql`
  - 以上短 probe 可成功執行。
- 使用另一個 throwaway temp state 執行：

```bash
wrangler d1 migrations apply ... --local --persist-to /private/tmp/langmap-task4-migrations.HX1qj0
```

結果：

- Wrangler 嘗試套用既有 migration；
- 在沒有 baseline 的空 local DB 上失敗於 `0002_add_name_en.sql`；
- 錯誤：`no such table: languages: SQLITE_ERROR`

此 probe 反而驗證了 Task 4 的核心需求：若沒有先建立受控 baseline，Wrangler 會錯把既有 published migrations 視為待套用。

## 未解決疑慮

- 真 Wrangler 在目前環境仍受 sandbox / desktop 權限限制，不適合拿來做穩定 GREEN；本次以 fake Wrangler fixture 完成可重複測試，並在此明確記錄限制。
