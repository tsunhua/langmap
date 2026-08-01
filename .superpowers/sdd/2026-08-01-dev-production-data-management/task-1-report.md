# Task 1 Report

日期：2026-08-01
任務：建立資料管理 core 與安全 command boundary

## 實作摘要

- 新增 `scripts/db/manage.sh`，以 strict shell mode 解析 repository root，並固定 `exec python3 scripts/db/manage.py`。
- 新增 `scripts/db/manage.py`，只實作 Task 1 要求的 CLI dispatch stub：
  - environment 僅接受 `local`、`production`
  - local command 僅接受 `status`、`rebuild`、`verify`
  - production command 僅接受 `inventory`、`plan`、`apply`、`verify`、`restore`
  - `restore` 強制需要 bookmark，且拒絕未知 trailing args
- 新增 `scripts/db/lib/paths.py`，集中解析 repo root、backend、migrations、state、artifacts、operations、local D1 state 路徑，並提供 cleanup target safety validation。
- 新增 `scripts/db/lib/runner.py`，提供固定 argument array、captured stdout/stderr、timeout、redaction、非零退出即拋錯的 subprocess wrapper，且明確使用 `shell=False`。
- 新增 `scripts/db/tests/test_manage.py`，先以 CLI contract 驗證 RED，再覆蓋 `paths` 與 `runner` 的核心安全介面。
- 更新 `.gitignore`，忽略 `/scripts/db/state/`，並保留 tracked `README.md`。
- 新增 `scripts/db/state/README.md`，作為後續 task 共用 state 目錄說明。

## 提交 hash

`8b3a593`

## 測試命令與完整結果

### RED

命令：

```bash
python3 -m unittest discover -s scripts/db/tests -v
```

結果：

```text
test_local_accepts_only_supported_commands (test_manage.ManageCliTests) ... FAIL
test_production_accepts_only_supported_commands (test_manage.ManageCliTests) ... FAIL
test_rejects_unknown_environment (test_manage.ManageCliTests) ... FAIL
test_rejects_unknown_trailing_args (test_manage.ManageCliTests) ... FAIL
test_requires_environment_and_command (test_manage.ManageCliTests) ... FAIL
test_restore_accepts_exactly_one_bookmark (test_manage.ManageCliTests) ... FAIL
test_restore_requires_bookmark (test_manage.ManageCliTests) ... FAIL
test_discovers_expected_repository_paths (test_manage.ProjectPathsTests) ... FAIL
test_rejects_symlink_escape_cleanup_target (test_manage.ProjectPathsTests) ... FAIL
test_rejects_unsafe_cleanup_targets (test_manage.ProjectPathsTests) ... FAIL
test_run_command_captures_output (test_manage.RunnerTests) ... FAIL
test_run_command_redacts_sensitive_arguments_in_errors (test_manage.RunnerTests) ... FAIL

----------------------------------------------------------------------
Ran 12 tests in 0.283s

FAILED (failures=19)
```

說明：此輪失敗符合預期，因 `scripts/db/manage.py`、`scripts/db/lib/paths.py`、`scripts/db/lib/runner.py` 尚未建立。

### GREEN

命令：

```bash
python3 -m unittest discover -s scripts/db/tests -v
```

結果：

```text
test_local_accepts_only_supported_commands (test_manage.ManageCliTests) ... ok
test_production_accepts_only_supported_commands (test_manage.ManageCliTests) ... ok
test_rejects_unknown_environment (test_manage.ManageCliTests) ... ok
test_rejects_unknown_trailing_args (test_manage.ManageCliTests) ... ok
test_requires_environment_and_command (test_manage.ManageCliTests) ... ok
test_restore_accepts_exactly_one_bookmark (test_manage.ManageCliTests) ... ok
test_restore_requires_bookmark (test_manage.ManageCliTests) ... ok
test_discovers_expected_repository_paths (test_manage.ProjectPathsTests) ... ok
test_rejects_symlink_escape_cleanup_target (test_manage.ProjectPathsTests) ... ok
test_rejects_unsafe_cleanup_targets (test_manage.ProjectPathsTests) ... ok
test_run_command_captures_output (test_manage.RunnerTests) ... ok
test_run_command_redacts_sensitive_arguments_in_errors (test_manage.RunnerTests) ... ok

----------------------------------------------------------------------
Ran 12 tests in 0.820s

OK
```

### Self-check

命令：

```bash
git diff --check
```

結果：

```text
(no output)
```

## 未解決疑慮

- `ProjectPaths.ensure_safe_cleanup_target()` 目前已實作危險目標拒絕與可選 `allowed_root` 邊界；後續 task 在真正執行 local state 清理時，仍需明確傳入 `backend/.wrangler/state` 作為唯一允許根目錄，才能把 Task 1 的安全方向完整落地。
