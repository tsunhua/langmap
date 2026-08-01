# Task 5 Report — dev.sh bootstrap orchestrator

Date: Saturday, August 1, 2026

## 實作摘要

- 將 [dev.sh](/Users/lim/Documents/Code/tsunhua/langmap/dev.sh) 收斂為 bootstrap orchestrator：
  - 解析 `--rebuild`、`--no-rebuild`、`--port=...`。
  - 移除 table-count heuristic、inline DDL、registry direct load、migration `|| true`、廣泛 `pkill -f "wrangler dev"`。
  - 只保留 secret / dependency 檢查、repo 專屬 pidfile + command identity cleanup、`manage.sh local status|rebuild|verify` 決策、backend/frontend 啟動與 cleanup。
- 新增 [scripts/db/tests/test_dev_sh.py](/Users/lim/Documents/Code/tsunhua/langmap/scripts/db/tests/test_dev_sh.py)，以 PATH fake commands 驗證 shell orchestration。
- 更新 [README.md](/Users/lim/Documents/Code/tsunhua/langmap/README.md) 的 `./dev.sh` 使用入口。

## 變更檔案

- [dev.sh](/Users/lim/Documents/Code/tsunhua/langmap/dev.sh)
- [scripts/db/tests/test_dev_sh.py](/Users/lim/Documents/Code/tsunhua/langmap/scripts/db/tests/test_dev_sh.py)
- [README.md](/Users/lim/Documents/Code/tsunhua/langmap/README.md)

## TDD 記錄

### RED

Command:

```bash
python3 -m unittest scripts.db.tests.test_dev_sh -v
```

Historical result captured before the `dev.sh` rewrite on Saturday, August 1, 2026:

```text
test_bootstrap_failures_block_server_start (scripts.db.tests.test_dev_sh.DevShellTests) ...
test_fingerprint_hit_verifies_then_starts_servers (scripts.db.tests.test_dev_sh.DevShellTests) ... FAIL
...
KeyboardInterrupt
```

Notes:

- 當時的 legacy `dev.sh` 尚未呼叫 `manage.sh local status|rebuild|verify` 契約；
- 測試等待 fake orchestration event 時失敗，證明舊腳本不符合新 brief；
- 該次 RED run 在 legacy shell flow 卡住後被中止，所以只有「明確非綠燈」證據，沒有完整 6-case summary。此限制在此如實記錄，不補造完整 RED output。

### GREEN

Command:

```bash
python3 -m unittest scripts.db.tests.test_dev_sh -v
```

Result:

```text
test_bootstrap_failures_block_server_start (scripts.db.tests.test_dev_sh.DevShellTests) ... ok
test_fingerprint_hit_verifies_then_starts_servers (scripts.db.tests.test_dev_sh.DevShellTests) ... ok
test_fingerprint_miss_rebuilds_before_starting_servers (scripts.db.tests.test_dev_sh.DevShellTests) ... ok
test_force_rebuild_skips_status_and_starts_servers (scripts.db.tests.test_dev_sh.DevShellTests) ... ok
test_no_rebuild_fails_without_starting_servers (scripts.db.tests.test_dev_sh.DevShellTests) ... ok
test_port_forwarding_and_cleanup_only_stop_repo_owned_processes (scripts.db.tests.test_dev_sh.DevShellTests) ... ok

----------------------------------------------------------------------
Ran 6 tests in 8.229s

OK
```

Additional self-check:

```bash
python3 -m unittest scripts.db.tests.test_manage scripts.db.tests.test_local_rebuild scripts.db.tests.test_verify scripts.db.tests.test_fingerprint scripts.db.tests.test_dev_sh -v
```

Result summary:

```text
Ran 42 tests in 15.930s

OK
```

## Shell orchestration evidence

`scripts/db/tests/test_dev_sh.py` 覆蓋以下行為：

- fingerprint hit 時：先 `local status`，再 `local verify`，之後才啟動 backend/frontend。
- fingerprint miss 時：先 `local status`，再 `local rebuild`，不走 `local verify`。
- `--rebuild` 時：直接 `local rebuild`，不先跑 `status`。
- `--no-rebuild` 且需要重建時：只跑 `local status`，直接非零退出，不啟動任何服務。
- bootstrap / verify 失敗時：Wrangler 與 Vite 均不得啟動。
- `--port=9911` 時：backend 啟動命令含 `--port 9911`。
- cleanup 僅終止 repo-owned pidfile process，不誤殺 fake foreign process。

Representative fake log evidence from the fingerprint-hit path:

```text
manage	local status
manage	local verify
npx	wrangler dev --config /tmp/.../backend/wrangler.jsonc --persist-to /tmp/.../backend/.wrangler/state --port 8788
npx	vite --host --strictPort --config /tmp/.../web/vite.config.ts
server-start	backend	...
server-start	frontend	...
server-stop	frontend
server-stop	backend
```

## 真機 `./dev.sh --rebuild` evidence

Status: not completed; blocked and intentionally not retried further in this task closeout.

### Attempt 1 — sandboxed

Command:

```bash
./dev.sh --rebuild --port=8788
```

Observed failure:

```text
Error: listen EPERM: operation not permitted 127.0.0.1
...
Failed to write to log file ... '/Users/lim/Library/Preferences/.wrangler/logs/...'
```

Interpretation:

- 這不是 Task 5 orchestration 邏輯錯誤；
- 是 sandbox 對 Wrangler 本地 listen 與使用者目錄 log 寫入的環境限制。

### Attempt 2 — escalated

Command:

```bash
./dev.sh --rebuild --port=8788
```

Observed progress before manual stop:

```text
▶ 決定 local bootstrap 流程
▶ 依旗標強制重建 local D1
```

Then, after waiting, the run was manually interrupted. Stack trace showed it was still inside:

```text
scripts/db/manage.py -> rebuild_local_state() -> execute_file(... language-registry.sql)
```

Interpretation:

- 提權後不再是 `EPERM`；
- 但 `local rebuild` 在載入 `language-registry.sql` 階段長時間沒有完成輸出；
- 本 task 收尾依使用者指示停止長時間等待，未再繼續真機啟動。

### Second fingerprint-hit attempt

- 未執行完成。
- 因第一次真機 rebuild 尚未取得成功完成證據，所以沒有可信的第二次 fingerprint-hit evidence。
- 此項在本報告中明確標示為未完成，不宣稱完成。

## Git / workspace checks before commit

Command:

```bash
git status --short
git diff --check
```

Observed:

```text
 M README.md
 M dev.sh
?? scripts/db/tests/test_dev_sh.py
```

`git diff --check` produced no output.

## Commit

Commit message:

```text
refactor: make dev startup use reproducible data bootstrap
```

Commit hash:

```text
PENDING
```

This section will be updated after the commit is created.

## Remaining concerns

- 真機 `./dev.sh --rebuild` 與第二次 fingerprint-hit evidence 尚未完成；
- 目前對 Task 5 的高信心證據來自 fake orchestration tests 與 repo-level unittest 綠燈；
- 若後續需要補齊真機 evidence，應在允許 Wrangler listen / logging 且避免長時間 blocking 的環境中完成。
