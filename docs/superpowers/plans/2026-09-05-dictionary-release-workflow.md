# Dictionary Release Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 讓詞典修復流程自動保留可靠差分基線、以常數級記憶體產生 delta，並使 data-only production apply 可跳過無關 reference artifacts、從已完成 stage 安全續跑。

**Architecture:** incremental importer 在通過 staging quality gate 後、修改 mirror 前，以 SQLite backup API 建立不可變 snapshot 並寫入 state。delta exporter 使用 `ATTACH DATABASE` 與 primary-key anti-join 串流輸出。production plan 明確記錄是否需要 reference artifacts；apply journal 以 stage checkpoint 作為同一 plan 的 resume 依據。

**Tech Stack:** Python 3、SQLite、Cloudflare Wrangler、unittest／pytest、JSONL operation journal。

## Global Constraints

- 保留 production D1 與 mirror 的整數 ID 空間。
- production mutation 必須經 plan/apply、database confirmation 與 Time Travel bookmark。
- delta 維持 deterministic、checksum-locked、`INSERT OR IGNORE` 與 FK-safe table order。
- 不降低 reading quality gate，不修改 dictionary canonical identity。
- 保留舊 plan 相容性：缺少新欄位時沿用目前 full-reference 行為。

---

### Task 1: Stream Dictionary Delta from SQLite

**Files:**
- Modify: `scripts/db/export_dictionary_delta.py`
- Test: `scripts/db/tests/test_export_dictionary_delta.py`

**Interfaces:**
- Consumes: `export_delta(before: Path, after: Path, output: Path, *, limit: int | None = None, rows_per_insert: int = 100) -> dict[str, int]`
- Produces: `_iter_added_rows(connection, table, pk, columns, limit) -> Iterator[sqlite3.Row]`，只保留單一 insert batch 在記憶體。

- [x] **Step 1: Write the failing streaming test**

```python
def test_delta_streams_rows_without_materializing_full_tables(self):
    with mock.patch(
        "scripts.db.export_dictionary_delta._rows_by_pk",
        side_effect=AssertionError("full-table materialization is forbidden"),
    ):
        counts = export_delta(before, after, output, rows_per_insert=2)
    self.assertEqual(counts["expressions"], 3)
```

- [x] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest scripts/db/tests/test_export_dictionary_delta.py -q`

Expected: FAIL because `export_delta` still calls `_rows_by_pk`.

- [x] **Step 3: Implement ATTACH anti-join streaming**

```python
after_conn.execute("ATTACH DATABASE ? AS before_db", (str(before),))
where = " AND ".join(
    f'previous."{column}" IS current."{column}"' for column in pk
)
cursor = after_conn.execute(
    f'SELECT {selected} FROM main."{table}" AS current '
    f'WHERE NOT EXISTS (SELECT 1 FROM before_db."{table}" AS previous WHERE {where}) '
    f'ORDER BY {ordered_pk}'
)
```

Use `fetchmany(rows_per_insert)` and write each batch immediately. Validate that before／after columns and PK columns match before querying.

- [x] **Step 4: Verify deterministic replay and batching**

Run: `python3 -m pytest scripts/db/tests/test_export_dictionary_delta.py -q`

Expected: all tests PASS; existing SQL format and row counts remain unchanged.

- [x] **Step 5: Commit**

```bash
git add scripts/db/export_dictionary_delta.py scripts/db/tests/test_export_dictionary_delta.py
git commit -m "perf: stream dictionary delta generation"
```

### Task 2: Capture an Immutable Pre-import Mirror Snapshot

**Files:**
- Modify: `scripts/dictionary/incremental_import.py`
- Test: `scripts/dictionary/tests/test_incremental_import.py`

**Interfaces:**
- Consumes: `run_incremental_import(..., snapshot_root: Path | None = None) -> list[dict[str, Any]]`
- Produces: `create_sqlite_snapshot(source: Path, destination: Path) -> str` returning SHA-256; each successful state row contains `before_snapshot_path` and `before_snapshot_sha256`.

- [x] **Step 1: Write failing snapshot tests**

```python
first = run_incremental_import(
    input_dir, d1_path, state_path, staging_root,
    snapshot_root=tmp_path / "snapshots",
)
snapshot = Path(first[0]["before_snapshot_path"])
assert snapshot.is_file()
assert first[0]["before_snapshot_sha256"] == file_sha256(snapshot)
assert sqlite3.connect(snapshot).execute(
    "SELECT COUNT(*) FROM expressions"
).fetchone()[0] == first[0]["d1_before"]["terms"]
```

Also assert that a quality-gate failure creates no snapshot and that the resume skip preserves the original snapshot metadata.

- [x] **Step 2: Run tests to verify failure**

Run: `python3 -m pytest scripts/dictionary/tests/test_incremental_import.py -q`

Expected: FAIL because `snapshot_root` and snapshot state fields do not exist.

- [x] **Step 3: Implement atomic SQLite backup**

```python
def create_sqlite_snapshot(source: Path, destination: Path) -> str:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(f".{destination.name}.{time.time_ns()}.tmp")
    with sqlite3.connect(source, timeout=60) as source_db:
        with sqlite3.connect(temporary) as snapshot_db:
            source_db.backup(snapshot_db)
    temporary.replace(destination)
    return file_sha256(destination)
```

Create the snapshot only after staging／normalization／quality／clustering succeeds and immediately before `import_release_to_local_d1`. Default `snapshot_root` to `state_path.parent / "snapshots"`; name snapshots with source stem, input digest prefix, and release ID so existing files are never silently overwritten.

- [x] **Step 4: Persist and resume snapshot metadata**

Write a `snapshot_created` state row atomically before mirror mutation. When the same input resumes, reuse only a snapshot whose stored checksum still matches; successful skip output includes the two snapshot fields.

- [x] **Step 5: Run importer tests**

Run: `python3 -m pytest scripts/dictionary/tests/test_incremental_import.py scripts/dictionary/tests/test_import_with_progress.py -q`

Expected: all tests PASS.

- [x] **Step 6: Commit**

```bash
git add scripts/dictionary/incremental_import.py scripts/dictionary/tests/test_incremental_import.py
git commit -m "feat: snapshot mirror before dictionary import"
```

### Task 3: Make Data-only Production Plans Skip Unchanged References

**Files:**
- Modify: `scripts/db/lib/production.py`
- Test: `scripts/db/tests/test_production_inventory.py`

**Interfaces:**
- Consumes: existing `plan_production` reference diff and approved data metadata.
- Produces: plan field `reference_artifacts: {"action": "apply" | "skip", "reason": str}`.

- [x] **Step 1: Write failing plan/apply tests**

```python
self.assertEqual(
    plan["reference_artifacts"],
    {"action": "skip", "reason": "unchanged-data-only-release"},
)
```

Apply the plan with fake Wrangler and assert the approved delta filename appears once while `language-reference.sql`, `system-ui.sql`, and `system-ui-edges-001.sql` do not appear.

- [x] **Step 2: Run test to verify failure**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py -q`

Expected: FAIL because plans do not record this action and apply always replays references.

- [x] **Step 3: Compute reference action during plan**

Set `skip` only when an approved data migration is present, no schema migration is pending, no dictionary artifact activation is requested, and every reference diff action is `unchanged`. Otherwise record `apply` with a reason. Do not recompute this decision during apply.

- [x] **Step 4: Honor the checksum-locked plan decision**

Wrap the registry／UI mutation block in `if reference_artifacts.get("action", "apply") == "apply"`. Missing field defaults to `apply` for old plans.

- [x] **Step 5: Run production tests**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py -q`

Expected: all tests PASS.

- [x] **Step 6: Commit**

```bash
git add scripts/db/lib/production.py scripts/db/tests/test_production_inventory.py
git commit -m "perf: skip unchanged references for data releases"
```

### Task 4: Resume Production Apply from Journaled Stages

**Files:**
- Modify: `scripts/db/lib/journal.py`
- Modify: `scripts/db/lib/production.py`
- Test: `scripts/db/tests/test_production_inventory.py`

**Interfaces:**
- Produces: `read_operation_events(path: Path, operation_id: str) -> list[dict[str, Any]]`.
- Produces journal statuses: `migrations-applied`, `data-applied`, `references-applied`, `succeeded`.

- [x] **Step 1: Write a failing resume test**

Simulate a first apply that writes `data-applied` and then raises during verification. Re-run the same plan and assert the approved delta occurs once across both fake Wrangler logs, the original bookmark is returned, and the second run reaches `succeeded`.

- [x] **Step 2: Run test to verify failure**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py -q`

Expected: FAIL because apply replays every mutation stage.

- [x] **Step 3: Add operation event reader and stage set**

```python
events = journal.read_operation_events(path, operation_id)
completed = {event["status"] for event in events}
bookmark = next(
    (event.get("bookmark") for event in events if event.get("bookmark")),
    None,
)
```

Reject a journal event whose operation ID matches but plan path or database identity differs.

- [x] **Step 4: Checkpoint immediately after each stage**

Append the stage event only after its command returns successfully. On resume, skip completed mutation stages; reuse the first recorded bookmark once any mutation stage completed. If `succeeded` already exists, return the recorded result without mutation.

- [x] **Step 5: Run production recovery tests**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py -q`

Expected: all tests PASS, including existing confirmation and bookmark ordering tests.

- [x] **Step 6: Commit**

```bash
git add scripts/db/lib/journal.py scripts/db/lib/production.py scripts/db/tests/test_production_inventory.py
git commit -m "feat: resume production apply by stage"
```

### Task 5: Document and Validate Phase One

**Files:**
- Modify: `docs/runbooks/production-data-release.md`
- Modify: `docs/runbooks/database-migrations.md`
- Modify: `TODO.md`

**Interfaces:**
- Documents the snapshot path contract, data-only reference skip, and same-plan resume behavior.

- [x] **Step 1: Update runbooks with exact commands**

Document `--snapshot-root`, the state fields, how to pass the recorded snapshot to `export_dictionary_delta.py`, and that retries must use the same plan file and pinned `LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler`.

- [x] **Step 2: Record issue progress**

Add issue `#120`, completed phase-one commits, test counts, and remaining statistics／single-command work to `TODO.md`.

- [x] **Step 3: Run complete verification**

Run: `python3 -m pytest scripts/db/tests scripts/dictionary/tests -q`

Expected: all tests PASS.

Run: `git diff --check`

Expected: no output.

- [x] **Step 4: Commit documentation**

```bash
git add docs/runbooks/production-data-release.md docs/runbooks/database-migrations.md TODO.md docs/superpowers/plans/2026-09-05-dictionary-release-workflow.md
git commit -m "docs: describe resumable dictionary releases"
```

- [x] **Step 5: Post progress to issue #120**

Use `gh issue comment 120 --body-file <summary-file>` with commit hashes, test result, completed acceptance criteria, and the next implementation slice.

### Task 6: Batch and Resume Split Approved SQL

**Files:**
- Modify: `scripts/db/lib/production.py`
- Test: `scripts/db/tests/test_production_inventory.py`

**Interfaces:**
- Produces: `_approved_sql_batches(path: Path, max_bytes: int = 256 * 1024) -> Iterator[tuple[int, str]]`.
- Produces journal status `data-batch-applied` with `batch_index`, `data_sha256`, and `batch_bytes`.

- [x] **Step 1: Write failing batching and resume tests**

Use a split SQL fixture larger than a small test batch. Assert one remote `--command` contains several statements, and when the second batch fails, a second apply of the same plan executes the first batch only once and reuses the first bookmark.

- [x] **Step 2: Run tests to verify failure**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py -q`

Expected: FAIL because split mode currently invokes one remote command per statement and has no batch checkpoints.

- [x] **Step 3: Implement bounded SQL batching**

Group `_split_approved_sql(path)` statements until adding the next statement would exceed 256 KiB; permit a single larger statement as one batch. Preserve statement order and the existing checksum validation.

- [x] **Step 4: Journal and resume each batch**

After each successful batch append `data-batch-applied`; on retry skip only recorded batches whose `data_sha256` matches the approved file. If a mutation-stage failure has no final `data-applied` event, reuse the original bookmark so a partially applied batch remains rollback-safe.

- [x] **Step 5: Run split recovery tests and commit**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py -q`

Expected: all production tests PASS.

```bash
git add scripts/db/lib/production.py scripts/db/tests/test_production_inventory.py docs/superpowers/plans/2026-09-05-dictionary-release-workflow.md
git commit -m "perf: batch resumable split data releases"
```

### Task 7: Include Statistics Refresh in the Same Release Operation

**Files:**
- Modify: `scripts/db/manage.py`
- Modify: `scripts/db/lib/production.py`
- Test: `scripts/db/tests/test_production_inventory.py`
- Test: `scripts/db/tests/test_manage.py`

**Interfaces:**
- Produces CLI flag `production plan --refresh-language-statistics`.
- Produces plan field `statistics_refresh` containing a repository-relative path, SHA-256, and mode.
- Produces journal status `statistics-refreshed`.

- [x] **Step 1: Write failing plan/apply tests**

Create the managed refresh SQL fixture and assert that a plan with `--approved-data-migration` plus `--refresh-language-statistics` records its checksum; apply must execute the data file and refresh file in that order.

- [x] **Step 2: Run tests to verify failure**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py -q`

Expected: FAIL because the CLI and plan do not accept or apply a statistics refresh stage.

- [x] **Step 3: Add checksum-locked statistics metadata**

Add `--refresh-language-statistics` to the production plan parser and include the managed `006-refresh-language-statistics.sql` artifact metadata in the plan. Reject the plan if the artifact is missing or changes after planning.

- [x] **Step 4: Apply and checkpoint the refresh stage**

Execute the refresh after data and before references, append `statistics-refreshed` only after success, and skip it when that checkpoint already exists during same-plan resume. Treat failures as a mutation-stage failure that retains the original bookmark.

- [x] **Step 5: Run tests and commit**

Run: `python3 -m pytest scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py -q`

Expected: all production tests PASS.

```bash
git add scripts/db/manage.py scripts/db/lib/production.py scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py docs/superpowers/plans/2026-09-05-dictionary-release-workflow.md
git commit -m "feat: refresh language statistics in data release"
```

### Task 8: Add Checksum-locked Dictionary Postflight Manifest

**Files:**
- Modify: `scripts/db/export_dictionary_delta.py`
- Modify: `scripts/db/lib/production.py`
- Modify: `scripts/db/manage.py`
- Test: `scripts/db/tests/test_export_dictionary_delta.py`
- Test: `scripts/db/tests/test_production_inventory.py`
- Test: `scripts/db/tests/test_manage.py`

**Interfaces:**
- Produces `export_delta(..., manifest: Path | None = None) -> dict[str, int]` and a JSON manifest with before/after database SHA-256 plus canonical table counts.
- Produces CLI flag `production plan --dictionary-postflight-manifest <path>`.
- Produces plan field `dictionary_postflight` and raises a production verification error when actual counts differ from the manifest.

- [x] **Step 1: Write failing manifest and plan/apply tests**

Assert that delta export writes deterministic manifest counts, plan rejects a production baseline whose counts differ from manifest before counts, and apply rejects a postflight inventory whose counts differ from manifest after counts.

- [x] **Step 2: Run tests to verify failure**

Run: `python3 -m pytest scripts/db/tests/test_export_dictionary_delta.py scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py -q`

Expected: FAIL because delta export and production plan/apply have no postflight manifest interface.

- [x] **Step 3: Generate and checksum manifest**

Add `--manifest` to `export_dictionary_delta.py`; record before／after SHA-256, per-table before／after counts, and added row counts. Keep JSON sorted and atomically written.

- [x] **Step 4: Enforce preflight and postflight counts**

Add `--dictionary-postflight-manifest` to plan. Validate its path and SHA-256, compare production inventory counts to manifest before counts during planning, and compare post-apply inventory counts to after counts. Keep old plans without the field compatible.

- [ ] **Step 5: Run tests and commit**

Run: `python3 -m pytest scripts/db/tests/test_export_dictionary_delta.py scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py -q`

Expected: all tests PASS.

```bash
git add scripts/db/export_dictionary_delta.py scripts/db/lib/production.py scripts/db/manage.py scripts/db/tests/test_export_dictionary_delta.py scripts/db/tests/test_production_inventory.py scripts/db/tests/test_manage.py docs/superpowers/plans/2026-09-05-dictionary-release-workflow.md
git commit -m "feat: verify dictionary release counts"
```
