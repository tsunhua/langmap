# Dictionary Incremental Import Implementation Plan
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將 `/Volumes/DATA/langmap-structured-jsonl` 的詞典按檔案大小由小到大逐部匯入本地 packed D1，每部完成即公開，並留下可續跑的效率與結果紀錄。

**Architecture:** 每個 JSONL 檔案使用獨立、可丟棄的 staging SQLite；完成 stage、normalize、explicit cluster 後，在同一個本地 D1 交易中追加整數 codebook、詞句、mapping、reading 與詞性 bitmask。D1 importer 將支援既有 packed catalog 的 append，並以輸入 manifest 避免重跑已成功檔案。definitions、labels、claims、AI 判定與其他抽取欄位只保留在來源 JSONL／暫存 staging，不寫入線上 D1。

**Tech Stack:** Python 3.12、SQLite、Cloudflare D1 local SQLite、既有 `manage.py` staging/normalization pipeline、packed integer catalog compatibility views。

## Global Constraints

- 一次只處理一部 JSONL；小檔案優先。
- 每部匯入獨立提交；失敗只影響當部，不回滾已成功檔案。
- packed D1 使用 integer language/locale codebooks；不得恢復文字重複索引或 audit 表。
- 保留所有抽取欄位在來源 JSONL／暫存 staging；definitions、labels 不進線上 D1；examples 只建立詞句 mapping。
- 不在此流程執行跨檔案 AI 合併；高信心合併另以完整 staging release 執行。
- 每部記錄 input SHA、entry count、耗時、輸入速率、D1 增量、summary 與錯誤；可從中斷處續跑。

---

### Task 1: Allow append-only packed D1 imports

**Files:**
- Modify: `scripts/dictionary/langmap_dictionary/local_import.py`
- Modify: `scripts/dictionary/manage.py`
- Test: `scripts/dictionary/tests/test_local_import.py`

**Interfaces:**
- `import_release_to_local_d1(..., packed=True, append=True)` permits an existing packed catalog and continues integer IDs from current maxima.
- `manage.py local-import --packed --append` exposes the mode without changing the fresh-catalog safety default.

- [ ] **Step 1: Add a failing two-release packed import test**

Create two isolated staging releases from the existing fixture, import the first with `packed=True`, import the second with `packed=True, append=True`, and assert that both releases remain in `dictionary_dataset_releases`, codebook IDs stay unique, term/edge/reading counts increase, and `PRAGMA foreign_key_check` is empty.

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `python3 -m pytest scripts/dictionary/tests/test_local_import.py -q`

Expected: the second import fails with the current `packed_catalog_requires_fresh_database` guard.

- [ ] **Step 3: Implement append codebook allocation and conflict-safe writes**

Add an `append` keyword defaulting to `False`. In append mode, insert only new language/locale codes using `MAX(id)+ROW_NUMBER()`; validate required locale codes after insertion. Keep fresh mode unchanged. Continue term, edge, and reading sequences from current maxima. Use `INSERT OR IGNORE` for pair/reading uniqueness conflicts while retaining monotonic IDs. Make dataset release IDs and active state update per file.

- [ ] **Step 4: Add the CLI flag and rerun focused tests**

Wire `--append` through `manage.py`, then run the focused importer tests and the existing dictionary test suite.

---

### Task 2: Build a resumable small-first orchestrator

**Files:**
- Create: `scripts/dictionary/incremental_import.py`
- Modify: `scripts/dictionary/manage.py` (only if shared command dispatch is reused)
- Test: `scripts/dictionary/tests/test_incremental_import.py`

**Interfaces:**
- `order_jsonl_files(input_dir: Path) -> list[Path]` sorts by `(size, name)`.
- `run_incremental_import(input_dir: Path, d1_database: Path, state_path: Path, staging_root: Path, batch_size: int = 2000, resume: bool = True) -> list[dict[str, object]]` returns one metric row per file.
- CLI: `python3 scripts/dictionary/incremental_import.py --input-dir ... --d1-database ... --state ... --staging-root ... --batch-size 2000`.

- [ ] **Step 1: Add failing ordering and resume tests**

Use three temporary JSONL paths with controlled sizes and a state JSON containing one successful matching SHA. Assert sorting is size ascending, successful matching files are skipped, changed files are not skipped, and a failure row does not prevent the next file from being attempted when the runner is configured to continue.

- [ ] **Step 2: Run the focused orchestrator test and verify it fails**

Run: `python3 -m pytest scripts/dictionary/tests/test_incremental_import.py -q`

Expected: import error because the orchestration module does not exist.

- [ ] **Step 3: Implement one-file lifecycle and metrics**

For each sorted JSONL: hash/measure file, create a unique staging database under `staging_root`, call the existing loader with one path and `fast=True`, normalize, build explicit clusters, call packed append (fresh for the first successful file, append thereafter), query D1 counts, atomically update state after success, and retain the staging DB only when `--keep-staging` is requested. Record `started_at`, `finished_at`, `seconds`, `entry_count`, `staged_entries`, `expressions`, `edges`, `readings`, `bytes`, `entries_per_second`, `bytes_per_second`, `d1_bytes`, `release_id`, `status`, and `error`.

- [ ] **Step 4: Add interrupted-run safety**

Write state through a temporary sibling file followed by `Path.replace`; never mark a file successful before the D1 transaction returns. On restart, verify the current file SHA and D1 release ID before skipping.

- [ ] **Step 5: Run focused and full dictionary tests**

Run: `python3 -m pytest scripts/dictionary/tests -q` and `python3 -m unittest scripts.db.tests.test_migrations -q`.

---

### Task 3: Document the incremental entry point and limits

**Files:**
- Modify: `scripts/dictionary/README.md`
- Modify: `docs/superpowers/plans/2026-08-24-dictionary-import-performance.md`

- [ ] **Step 1: Document the command and state files**

Include the exact `/Volumes/DATA/langmap-structured-jsonl` command, small-first ordering, resume behavior, staging retention, and the meaning of each metric.

- [ ] **Step 2: Document AI merge boundary**

State that one-file mode preserves explicit clusters and does not perform cross-file AI merging; a later complete staging pass is required for cross-file reconciliation.

- [ ] **Step 3: Run documentation checks**

Run: `git diff --check` and verify all command paths point to existing files.

---

### Task 4: Benchmark and run the local import

**Files:**
- Create at runtime only: `/Volumes/DATA/langmap-incremental-state.json`, per-file staging under `/Volumes/DATA/langmap-staging-parts/`.

- [ ] **Step 1: Measure the smallest file**

Run the orchestrator with `--limit-files 1` or the smallest-file selection, verify the D1 term/edge/reading deltas and elapsed metrics, and confirm `/api/v2/languages` reflects the new language immediately.

- [ ] **Step 2: Continue small-first with resume enabled**

Run without the limit; after each successful file verify the state row and D1 counts. Do not run `./dev.sh --rebuild` while this is active because rebuild swaps out the D1 state directory.

- [ ] **Step 3: Verify correctness and storage**

Check `PRAGMA foreign_key_check`, `PRAGMA quick_check`, `dictionary_dataset_state`, `dictionary_terms`, `dictionary_edges`, `dictionary_readings`, and API `/languages`. Record total D1 size and aggregate throughput in the state report.
