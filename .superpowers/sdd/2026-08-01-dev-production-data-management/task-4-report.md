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

## Reviewer findings follow-up（2026-08-01）

### 實作補強摘要

- `scripts/db/lib/local.py`
  - 將 active state 切換改為 transactional swap：
    - 先 snapshot 既有 metadata；
    - 先把新 fingerprint / verification report 寫到 staged metadata；
    - 若已有 active state，先 rename 到 sibling backup；
    - 再把 temp state rename 成 active；
    - 最後才以 `os.replace()` commit metadata；
    - swap 後任一步失敗都會 rollback active state 與 metadata；
    - 只有整體成功才清理 backup。
- `scripts/db/lib/verify.py`
  - schema invariant 從「硬編碼少數 table/trigger」提升為完整 schema object set：
    - `table`
    - `virtual_table`
    - `index`
    - `trigger`
  - baseline 與 verify 都以 `(kind, name, normalized_sql)` 完整集合比對。
  - migration lock 驗證不再只是把 checksum 抄進 report，而是先驗 `filename/size/sha256` 全部一致；任何 repo drift 或 lock tamper 都直接 fail，並統一轉成 `LocalVerificationError`。
- 測試補強
  - `test_rebuild_restores_active_state_and_metadata_when_post_swap_write_fails`
  - `test_verify_rejects_missing_expected_index_before_baseline`
  - `test_verify_rejects_missing_expected_trigger_before_baseline`
  - `test_verify_rejects_missing_expected_virtual_table_before_baseline`
  - `test_verify_rejects_repo_migration_checksum_drift`
  - `test_verify_rejects_tampered_lock_checksum`
  - `test_rejects_allowed_root_sibling_escape`

### Reviewer-fix TDD

RED（reviewer findings focused suite）：

```bash
python3 -m unittest scripts.db.tests.test_local_rebuild scripts.db.tests.test_verify -v
```

結果：

```text
FAIL: test_rebuild_restores_active_state_and_metadata_when_post_swap_write_fails
AssertionError: LocalRebuildError not raised
```

root cause：

- 當時唯一仍然 RED 的 case 不是 rollback 邏輯本身，而是測試把失敗打在 staging `_write_json`，沒有真正覆蓋 reviewer 要求的「swap 後 metadata commit 失敗」。

GREEN（修正測試注入點、補 schema/checksum/object coverage 後）：

```bash
python3 -m unittest scripts.db.tests.test_local_rebuild scripts.db.tests.test_verify -v
```

結果：

```text
Ran 11 tests in 3.557s

OK
```

完整驗證：

```bash
python3 -m unittest discover -s scripts/db/tests -v
git diff --check
```

結果：

```text
Ran 43 tests in 5.350s

OK
```

- `git diff --check` 無輸出，exit code 0。

### fake Wrangler / rollback / baseline 證據

- `test_rebuild_restores_active_state_and_metadata_when_post_swap_write_fails`
  - 以 monkeypatch 對 post-swap `_replace_path()` 第二次 metadata replace 強制失敗；
  - 驗證：
    - 舊 active state sentinel `keep.txt` 內容仍為 `old-active`；
    - 舊 fingerprint 仍為 `{"fingerprint":"old"}`；
    - 舊 verification report 仍為 `{"status":"old"}`；
    - `state-backup-*` sibling 不殘留。
- `test_verify_rejects_missing_expected_index_before_baseline`
- `test_verify_rejects_missing_expected_trigger_before_baseline`
- `test_verify_rejects_missing_expected_virtual_table_before_baseline`
  - 三者都使用 fake Wrangler skip fixture 製造 schema object 缺失；
  - rebuild 皆必須 fail；
  - 並確認 temp sqlite 中不存在 `d1_migrations` table，證明 baseline 沒有先被盲寫。
- `test_verify_rejects_repo_migration_checksum_drift`
  - 直接改寫 repo migration 內容，verify 必須 fail。
- `test_verify_rejects_tampered_lock_checksum`
  - 直接篡改 `migration-lock.json` 的 `sha256`，verify 必須 fail。
- `test_rejects_allowed_root_sibling_escape`
  - 驗證 `allowed_root=paths.local_d1_state_dir` 時，sibling path 仍被拒絕。

### real temporary Wrangler（本輪 reviewer follow-up）

本輪使用的真實 Wrangler binary：

```text
/Users/lim/Documents/Code/tsunhua/langmap/backend/node_modules/.bin/wrangler
```

所有 real probe 都只使用 `/private/tmp/langmap-task4-real-*`，沒有碰 `backend/.wrangler/state`，且將 `HOME` / `XDG_CONFIG_HOME` / `XDG_DATA_HOME` / `WRANGLER_LOG_PATH` 全部導到同一個 temporary root。

1. 沙箱內完整 rebuild + verify probe

Command:

```bash
python3 -c '... rebuild_local_state(...); verify_local_environment(...) ...'
```

Result:

```text
{"probe_root":"/private/tmp/langmap-task4-real-4ajdbjmg","error_type":"LocalRebuildError","error":"Error: listen EPERM: operation not permitted 127.0.0.1 ...","temp_state_dir":"/private/tmp/langmap-task4-real-4ajdbjmg/local-d1-rebuild-uzi9zfqb"}
```

2. 非沙箱 bounded probe（20 秒上限）

Command:

```bash
python3 -c '... signal.alarm(20); rebuild_local_state(...); verify_local_environment(...) ...'
```

Result:

```text
{"probe_root":"/private/tmp/langmap-task4-real-5i9qgue9","error_type":"LocalRebuildError","error":"real wrangler probe timed out after 20s","temp_state_dir":"/private/tmp/langmap-task4-real-5i9qgue9/local-d1-rebuild-p4s1hx9d"}
```

後續只讀檢查：

- `wrangler.log` 顯示：
  - 第一個 `d1 execute --file backend/schema.sql` 已成功；
  - `78 commands executed successfully`；
  - 第二個 `d1 execute --file scripts/v2/artifacts/language-registry-5.3/language-registry.sql` 開始後，在 20 秒上限內未完成。
- timeout 時 temporary sqlite 仍已存在：
  - `/private/tmp/langmap-task4-real-5i9qgue9/local-d1-rebuild-p4s1hx9d/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite`
- 只讀檢查顯示 timeout 前 DB 內已有 partial schema：
  - tables = 22
  - indexes = 34
  - triggers = 3
  - sample tables 含 `expression_edges`、`expressions`、`expressions_fts`。

## 未解決疑慮

- 真 Wrangler 的 full rebuild + verify 仍無法在目前桌面環境中穩定完成：
  - 沙箱內會遭遇 `listen EPERM 127.0.0.1`；
  - 非沙箱 bounded probe 雖可越過該權限點，但在 language registry 匯入階段 20 秒內未完成。
- 因此本次 GREEN 仍以 fake Wrangler fixture 為可重複驗證主體；real Wrangler 已按 reviewer 要求嘗試並完整記錄實際阻塞結果。
