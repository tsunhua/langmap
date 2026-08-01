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

Implementation commit hash:

```text
23005ad
```

## Remaining concerns

- 真機 `./dev.sh --rebuild` 與第二次 fingerprint-hit evidence 尚未完成；
- 目前對 Task 5 的高信心證據來自 fake orchestration tests 與 repo-level unittest 綠燈；
- 若後續需要補齊真機 evidence，應在允許 Wrangler listen / logging 且避免長時間 blocking 的環境中完成。

## Reviewer follow-up addendum — Saturday, August 1, 2026

### Additional focused test hardening

To lock out broad process cleanup regressions, `scripts/db/tests/test_dev_sh.py` now asserts that the fake `pkill`
binary is never called in every orchestration path. If `dev.sh` reintroduces `pkill -f ...`, the shell test suite now
fails.

Focused rerun:

```text
Ran 6 tests in 8.165s

OK
```

Relevant full rerun:

```text
Ran 42 tests in 15.949s

OK
```

### Real local rebuild attempt with current timeout=120 manager

Command:

```bash
bash -x ./dev.sh --rebuild --port=8791
```

Observed trace before manager handoff:

```text
+ BACKEND_PORT=8791
+ FORCE_REBUILD=1
...
+ step '依旗標強制重建 local D1'
+ manage.sh local rebuild
```

Observed terminal failure after the bounded wait:

```text
lib.verify.LocalVerificationError: count mismatch, translation ownership mismatch, orphan references detected
...
lib.local.LocalRebuildError: count mismatch, translation ownership mismatch, orphan references detected
❌ dev.sh 失敗：第 173 行
```

Interpretation:

- 這次已不是 sandbox `EPERM`；
- 也不是無界等待；`manage.sh local rebuild` 在 timeout=120 內返回了明確失敗；
- 失敗點是 local rebuild 完成資料載入後，verification 直接拒絕 baseline，因而 `dev.sh` 沒有進入 Wrangler/Vite startup；
- 因為第一輪真機 rebuild 未成功，所以本 reviewer finding 要求的「成功啟動後 bounded stop」證據在目前 repo local state 上無法誠實聲稱完成。

### Second launch / fingerprint-hit follow-up

Read-only status check after the failed rebuild attempt:

```bash
./scripts/db/manage.sh local status
```

Observed result:

```json
{"environment":"local","command":"status","repo_root":"/Users/lim/Documents/Code/tsunhua/langmap","desired_fingerprint":"4b4aaf72d68f2a551c83eb0d5b0c5df663a7cc37678e7761442894a118cba5d8","stored_fingerprint":null,"state_exists":true,"rebuild_required":true}
```

Interpretation:

- `stored_fingerprint` 仍為 `null`，表示 failed rebuild 沒有建立成功 baseline metadata；
- `rebuild_required` 仍為 `true`，所以第二輪 `./dev.sh --port=<another port>` 不會是 fingerprint-hit / `local verify` 路徑，而只會再次走 rebuild；
- 為避免重複長時間 real rebuild 且仍無法滿足 reviewer 要求，本次沒有偽造第二輪啟動證據，而是如實記錄前置條件未成立。

## Reviewer follow-up addendum 2 — isolated `/private/tmp` checkout

Date: Saturday, August 1, 2026

### Isolation strategy

為避免影響另一個專案 `backend_v2` 的 Wrangler 殘留程序（8788），真機 evidence 改在受控 isolated checkout 進行：

- isolated root: `/private/tmp/langmap-task5-isolated.9ezGnR`
- copied source: `dev.sh`、`backend/`、`web/`、`scripts/`
- shared read-only dependencies:
  - `backend/node_modules -> /Users/lim/Documents/Code/tsunhua/langmap/backend/node_modules`
  - `web/node_modules -> /Users/lim/Documents/Code/tsunhua/langmap/web/node_modules`
- isolated logs: `WRANGLER_LOG_PATH=/private/tmp/langmap-task5-isolated.9ezGnR/wrangler-logs`
- isolated local state: defaulted inside the isolated checkout under `backend/.wrangler/state`

### First isolated attempt — wrapper setup failure

Command:

```bash
bash -x ./dev.sh --rebuild --port=8795
```

Initial isolated wrapper configuration accidentally set `WRANGLER_LOG=debug`, which polluted Wrangler `--json`
stdout. In the same attempt, isolated `backend/.env` was also absent, causing extra warning output.

Observed failure:

```text
LocalRebuildError: invalid wrangler JSON output: 🪵  Writing logs to ".../wrangler-logs/..."
.env file not found at ".../backend/.env"
```

Action taken:

- removed `WRANGLER_LOG=debug`
- created an empty isolated `backend/.env`

This was a wrapper/setup issue, not the final real-dev verdict.

### Corrected isolated rebuild attempt — actual real-dev result

Command:

```bash
bash -x ./dev.sh --rebuild --port=8795
```

Bounded Python subprocess wrapper summary:

```json
{
  "root": "/private/tmp/langmap-task5-isolated.9ezGnR",
  "startup_message_seen": false,
  "backend_health_ok": false,
  "frontend_http_ok": false,
  "sigterm_sent": false,
  "returncode": 1,
  "backend_pidfile_exists_after": false,
  "frontend_pidfile_exists_after": false
}
```

Observed failure tail:

```text
+ BACKEND_PORT=8795
+ FORCE_REBUILD=1
...
+ step '依旗標強制重建 local D1'
+ manage.sh local rebuild
Traceback (most recent call last):
  ...
lib.verify.LocalVerificationError: count mismatch, translation ownership mismatch, orphan references detected
...
lib.local.LocalRebuildError: count mismatch, translation ownership mismatch, orphan references detected
❌ dev.sh 失敗：第 173 行
```

Interpretation:

- 在 isolated `/private/tmp` checkout 中，`dev.sh --rebuild` 已不依賴 current repo active state，也未碰 `backend_v2`；
- corrected isolated real-dev 仍然無法成功 rebuild；
- 失敗點仍是 local rebuild verification，而不是 process cleanup、sandbox listen、或 current repo 汙染；
- 因 rebuild 未成功，所以 backend/frontend startup evidence 與 bounded SIGTERM cleanup evidence 在真機路徑上都無法成立。

### Second isolated launch / fingerprint-hit feasibility check

Read-only command:

```bash
cd /private/tmp/langmap-task5-isolated.9ezGnR
WRANGLER_LOG_PATH=/private/tmp/langmap-task5-isolated.9ezGnR/wrangler-logs ./scripts/db/manage.sh local status
```

Observed result:

```json
{"environment":"local","command":"status","repo_root":"/private/tmp/langmap-task5-isolated.9ezGnR","desired_fingerprint":"4b4aaf72d68f2a551c83eb0d5b0c5df663a7cc37678e7761442894a118cba5d8","stored_fingerprint":null,"state_exists":true,"rebuild_required":true}
```

Interpretation:

- isolated checkout 在 corrected rebuild failure 後，`stored_fingerprint` 仍為 `null`；
- 因此第二次 `./dev.sh --port=<p2>` 不可能誠實地走 fingerprint-hit / `local verify` 路徑；
- 若繼續跑第二次 `dev.sh`，只會再次進入 rebuild，而不是 reviewer 要求的 verify path；
- 本報告因此如實記錄：在 isolated real-dev 條件下，第二次 fingerprint-hit evidence 仍無法成立，原因是第一輪 rebuild verification 已失敗。

## Verification fix and final real-dev evidence

### Root cause and fix

Real rebuild exposed a data-model detail that the first verification implementation did not model:
the deterministic UI expression IDs intentionally allow multiple message keys to share one source
expression, and `expression_edges` de-duplicates identical expression pairs. Therefore an expression's
single `source_ref` cannot be used as the ownership key for a message. The verifier now:

- records the source expression ID in each expected and actual mapping;
- matches actual mappings by `ui_messages.source_expression_id`, not source `source_ref`;
- compares expected and actual logical mappings while treating a shared expression edge as managed when
  its normalized source/target pair belongs to any bundle mapping;
- continues to reject `ui_i18n` edges whose normalized pair is outside the bundle; and
- reports logical translation coverage, preserving the manifest's 1228 translation count.

Regression coverage was added for multiple message keys sharing one source expression. The full DB
test suite passes: `55 tests, OK`.

### Repository-local real rebuild and verify

```text
./scripts/db/manage.sh local rebuild
status: rebuilt
fingerprint: 4b4aaf72d68f2a551c83eb0d5b0c5df663a7cc37678e7761442894a118cba5d8

./scripts/db/manage.sh local verify
status: ok
languages: 62
languoids: 27177
language_subtags: 9296
language_locations: 45
ui_locales: 4
ui_messages: 312
ui_translation_mappings: 1228
orphans: languages=0, locales=0, messages=0, edges=0
```

### Real `dev.sh` flow

First run:

```bash
./dev.sh --rebuild --port=8796
```

Result: rebuild succeeded, backend became ready on `http://localhost:8796`, frontend became ready on
`http://localhost:5173`, and Ctrl-C cleanup stopped only the repository-owned backend/frontend PIDs.

Second run:

```bash
./dev.sh --port=8797
```

Result: output contained `fingerprint hit，驗證 local D1`; verification returned the same counts and
zero orphan references, then both local servers became ready. Ctrl-C cleanup completed successfully.
