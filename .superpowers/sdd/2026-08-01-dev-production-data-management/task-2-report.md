# Task 2 Report

日期：2026-08-01
任務：建立 migration lock、fingerprint 與 operation lock

## 實作摘要

- 新增 `scripts/db/lib/migrations.py`：
  - 驗證 migration discovery 只接受 `NNNN_name.sql`。
  - 以穩定檔名排序產生 migration metadata，記錄 sequence、filename、size、SHA-256。
  - 拒絕 duplicate sequence、gap、empty file 與 symlink。
  - 提供 `sync_migration_lock()`，在非 update 模式下拒絕缺 lock、已發布 checksum/size 變更與未鎖定新 migration；在 update 模式下只追加新 migration，並保留 baseline metadata。
- 新增 `scripts/db/lib/fingerprint.py`：
  - 以 `backend/schema.sql`、`scripts/db/migration-lock.json`、language manifest、UI bundle manifest、dev fixture version 組成 deterministic bootstrap fingerprint。
  - `manage.py local status` 會輸出 `desired_fingerprint`、`stored_fingerprint`、`state_exists`、`rebuild_required`，且不寫入 local state。
  - 目前 dev fixture version 先以 `scripts/v2/fixtures/language-migration.json` 的 `fixture_version`，若不存在則回退 `manifest_version`；若 manifest 缺失則標記為 `missing`。
- 新增 `scripts/db/lib/locking.py`：
  - 以原子檔案建立 operation lock。
  - 同環境第二個 process 會失敗，錯誤訊息包含既有 owner 與 created_at。
  - stale lock 不會在 acquire 時自動刪除；只有顯式 unlock 且 PID 已不存在才可清理。
- 擴充 `scripts/db/lib/paths.py`：
  - 補上 migration lock、local fingerprint、language manifest、UI bundle manifest 等路徑。
- 生成版本控制內的 deterministic lock：`scripts/db/migration-lock.json`
  - baseline metadata：`baseline_created_at = 2026-08-01T00:00:00Z`
  - baseline Git commit：`aa384e42`
- 新增測試：
  - `scripts/db/tests/test_migrations.py`
  - `scripts/db/tests/test_fingerprint.py`
  - `scripts/db/tests/fixtures/migrations/`

## 提交 hash

`3d32829f`

## TDD RED / GREEN 命令與完整結果

### RED

命令：

```bash
python3 -m unittest scripts.db.tests.test_migrations scripts.db.tests.test_fingerprint -v
```

結果：

```text
test_migrations (unittest.loader._FailedTest) ... ERROR
test_fingerprint (unittest.loader._FailedTest) ... ERROR

======================================================================
ERROR: test_migrations (unittest.loader._FailedTest)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_migrations
Traceback (most recent call last):
  File "/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/unittest/loader.py", line 154, in loadTestsFromName
    module = __import__(module_name)
  File "/Users/lim/Documents/Code/tsunhua/langmap/scripts/db/tests/test_migrations.py", line 19, in <module>
    from lib import migrations as migrations_lib  # noqa: E402
ImportError: cannot import name 'migrations' from 'lib' (/Users/lim/Documents/Code/tsunhua/langmap/scripts/db/lib/__init__.py)


======================================================================
ERROR: test_fingerprint (unittest.loader._FailedTest)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_fingerprint
Traceback (most recent call last):
  File "/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/unittest/loader.py", line 154, in loadTestsFromName
    module = __import__(module_name)
  File "/Users/lim/Documents/Code/tsunhua/langmap/scripts/db/tests/test_fingerprint.py", line 20, in <module>
    from lib import fingerprint as fingerprint_lib  # noqa: E402
ImportError: cannot import name 'fingerprint' from 'lib' (/Users/lim/Documents/Code/tsunhua/langmap/scripts/db/lib/__init__.py)


----------------------------------------------------------------------
Ran 2 tests in 0.000s

FAILED (errors=2)
```

說明：此輪失敗符合預期，因 Task 2 新模組與 `local status` 行為尚未存在。

### GREEN

命令：

```bash
python3 -m unittest scripts.db.tests.test_migrations scripts.db.tests.test_fingerprint -v
python3 -m unittest discover -s scripts/db/tests -v
python3 - <<'PY'
import sys
from pathlib import Path
repo = Path('/Users/lim/Documents/Code/tsunhua/langmap')
sys.path.insert(0, str(repo / 'scripts' / 'db'))
from lib.paths import ProjectPaths
from lib.fingerprint import compute_bootstrap_fingerprint, default_fingerprint_inputs
from lib.migrations import sync_migration_lock
paths = ProjectPaths.discover(repo)
first = sync_migration_lock(paths.migrations_dir, paths.migration_lock_path, update=True, baseline_created_at='2026-08-01T00:00:00Z', git_commit='aa384e42')
second = sync_migration_lock(paths.migrations_dir, paths.migration_lock_path, update=True, baseline_created_at='2026-08-01T00:00:00Z', git_commit='aa384e42')
print(first == second)
print(compute_bootstrap_fingerprint(default_fingerprint_inputs(paths)))
print(compute_bootstrap_fingerprint(default_fingerprint_inputs(paths)))
PY
git diff --check
```

結果：

```text
test_discover_migrations_returns_sorted_metadata (scripts.db.tests.test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_duplicate_sequence (scripts.db.tests.test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_empty_file (scripts.db.tests.test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_gap_after_first_sequence (scripts.db.tests.test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_invalid_filename (scripts.db.tests.test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_symlink (scripts.db.tests.test_migrations.MigrationDiscoveryTests) ... ok
test_sync_lock_adds_new_migration_only_in_update_mode (scripts.db.tests.test_migrations.MigrationLockTests) ... ok
test_sync_lock_rejects_missing_locked_migration (scripts.db.tests.test_migrations.MigrationLockTests) ... ok
test_sync_lock_rejects_published_checksum_changes (scripts.db.tests.test_migrations.MigrationLockTests) ... ok
test_sync_lock_requires_existing_file_unless_update_mode (scripts.db.tests.test_migrations.MigrationLockTests) ... ok
test_fingerprint_changes_when_any_input_changes (scripts.db.tests.test_fingerprint.FingerprintTests) ... ok
test_fingerprint_is_deterministic_for_same_inputs (scripts.db.tests.test_fingerprint.FingerprintTests) ... ok
test_local_status_reports_rebuild_required_without_mutating_state (scripts.db.tests.test_fingerprint.LocalStatusTests) ... ok
test_second_process_is_rejected_with_owner_and_time (scripts.db.tests.test_fingerprint.OperationLockTests) ... ok
test_unlock_stale_lock_requires_missing_pid (scripts.db.tests.test_fingerprint.OperationLockTests) ... ok

----------------------------------------------------------------------
Ran 15 tests in 0.085s

OK

test_fingerprint_changes_when_any_input_changes (test_fingerprint.FingerprintTests) ... ok
test_fingerprint_is_deterministic_for_same_inputs (test_fingerprint.FingerprintTests) ... ok
test_local_status_reports_rebuild_required_without_mutating_state (test_fingerprint.LocalStatusTests) ... ok
test_second_process_is_rejected_with_owner_and_time (test_fingerprint.OperationLockTests) ... ok
test_unlock_stale_lock_requires_missing_pid (test_fingerprint.OperationLockTests) ... ok
test_local_accepts_only_supported_commands (test_manage.ManageCliTests) ... ok
test_production_accepts_only_supported_commands (test_manage.ManageCliTests) ... ok
test_rejects_unknown_environment (test_manage.ManageCliTests) ... ok
test_rejects_unknown_trailing_args (test_manage.ManageCliTests) ... ok
test_requires_environment_and_command (test_manage.ManageCliTests) ... ok
test_restore_accepts_exactly_one_bookmark (test_manage.ManageCliTests) ... ok
test_restore_requires_bookmark (test_manage.ManageCliTests) ... ok
test_discovers_expected_repository_paths (test_manage.ProjectPathsTests) ... ok
test_rejects_cleanup_target_inside_symlinked_parent_directory (test_manage.ProjectPathsTests) ... ok
test_rejects_symlink_escape_cleanup_target (test_manage.ProjectPathsTests) ... ok
test_rejects_unsafe_cleanup_targets (test_manage.ProjectPathsTests) ... ok
test_run_command_captures_output (test_manage.RunnerTests) ... ok
test_run_command_redacts_sensitive_arguments_in_errors (test_manage.RunnerTests) ... ok
test_discover_migrations_returns_sorted_metadata (test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_duplicate_sequence (test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_empty_file (test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_gap_after_first_sequence (test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_invalid_filename (test_migrations.MigrationDiscoveryTests) ... ok
test_discover_rejects_symlink (test_migrations.MigrationDiscoveryTests) ... ok
test_sync_lock_adds_new_migration_only_in_update_mode (test_migrations.MigrationLockTests) ... ok
test_sync_lock_rejects_missing_locked_migration (test_migrations.MigrationLockTests) ... ok
test_sync_lock_rejects_published_checksum_changes (test_migrations.MigrationLockTests) ... ok
test_sync_lock_requires_existing_file_unless_update_mode (test_migrations.MigrationLockTests) ... ok

----------------------------------------------------------------------
Ran 28 tests in 0.963s

OK

True
14bc5f6119f3b0c9762aace20b407c43b841df1ea35ead8a7d2d366988dcf3df
14bc5f6119f3b0c9762aace20b407c43b841df1ea35ead8a7d2d366988dcf3df

(git diff --check produced no output)
```

## 未解決疑慮

- `dev fixture version` 目前先以 `scripts/v2/fixtures/language-migration.json` 的版本欄位作為 fallback；之後若 Task 4/Task 5 定義專用 fixture manifest，fingerprint input 應切到該明確來源。
- `manage.py local status` 目前只報告 fingerprint / state 狀態，不會建立或修復 state；這符合 Task 2 範圍，但後續 task 需要接上實際 rebuild / verify 流程。
