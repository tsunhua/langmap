# Dictionary Import Staging Read Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove external staging SQLite random-read hot paths, retain deterministic canonical writes, expose phase progress/timing, cache repeated canonical lookups, and make no-argument CLI execution read-only.

**Architecture:** Load staging tables through one public sequential-snapshot boundary, keeping entry source identity in a separate lookup map. Preserve deterministic IDs by sorting lightweight Python keys only at canonical write boundaries. Carry optional structured progress callbacks through staging and D1 phases, and keep all canonical lookup caches scoped to one import call.

**Tech Stack:** Python 3.12, sqlite3, argparse, pytest.

## Global Constraints

- Keep staging under the configured `/Volumes/DATA` root; do not move it to the internal disk.
- Do not add staging indexes, schema migrations, dependencies, or cross-database global caches.
- Preserve canonical schema, transaction atomicity, source identity, homograph behavior, and deterministic write order.
- Preserve unrelated uncommitted changes in the shared worktree.
- Chinese CLI output uses Traditional Chinese.

---

### Task 1: Sequential staging snapshot

**Files:**
- Modify: `scripts/dictionary/langmap_dictionary/local_import.py`
- Test: `scripts/dictionary/tests/test_local_import.py`

**Interfaces:**
- Produces: `load_staging_snapshot(connection: sqlite3.Connection, run_id: str, *, progress: ProgressCallback | None = None) -> StagingSnapshot`.
- `StagingSnapshot` exposes `occurrences`, `clusters`, `members`, and `entry_sources`.

- [x] Add a failing public-seam test with multiple entry sources and verify occurrence-to-source resolution.
- [x] Run `python3 -m pytest scripts/dictionary/tests/test_local_import.py -q` and confirm failure.
- [x] Implement four `NOT INDEXED` scans without SQL `ORDER BY` or occurrence/entry JOIN.
- [x] Raise a clear integrity error when an occurrence references a missing entry source.
- [x] Update canonical import to use `entry_sources` and sort lightweight occurrence keys before deterministic writes.
- [x] Run the focused tests and confirm canonical counts, homographs, and edges remain stable.

### Task 2: Connection-scoped canonical lookup cache

**Files:**
- Modify: `scripts/dictionary/langmap_dictionary/local_import.py`
- Test: `scripts/dictionary/tests/test_local_import.py`

**Interfaces:**
- Produces: one import-scoped writer/cache object used only inside `import_release_to_local_d1()`.
- Cache keys cover table columns, language codes, locale codes, sources, and POS code sets.

- [x] Add a failing test that traces repeated canonical lookups during one public import call and asserts bounded repeats for identical values.
- [x] Run the focused test and confirm failure.
- [x] Route schema, language, locale, source, and POS lookups through the per-call cache.
- [x] Run focused tests and verify a second database/import cannot observe the first call's cache.

### Task 3: Structured progress and phase timing

**Files:**
- Modify: `scripts/dictionary/langmap_dictionary/local_import.py`
- Modify: `scripts/dictionary/langmap_dictionary/clusters.py`
- Modify: `scripts/dictionary/incremental_import.py`
- Modify: `scripts/dictionary/import_with_progress.py`
- Test: `scripts/dictionary/tests/test_local_import.py`
- Test: `scripts/dictionary/tests/test_import_with_progress.py`

**Interfaces:**
- `import_release_to_local_d1(..., progress: ProgressCallback | None = None)` emits staging-load and D1-write events.
- `_prepare_staging(..., progress: ProgressCallback | None = None)` forwards stage, normalize, and cluster events and returns phase timing.
- Per-file state records `phase_seconds` with `stage`, `normalize`, `cluster`, `staging_load`, `d1_write`, and `total`.

- [x] Add a failing import test for phase coverage and monotonic processed counts.
- [x] Add a failing CLI test for flushed, bounded plain-text phase output and saved timing fields.
- [x] Run both focused test files and confirm failures.
- [x] Add optional callbacks without changing behavior when omitted.
- [x] Emit immediate phase transitions, interval updates, and completion events without TTY escape codes.
- [x] Store phase timings in success records and last phase in failure records.
- [x] Run focused tests and confirm pass.

### Task 4: Safe explicit CLI actions

**Files:**
- Modify: `scripts/dictionary/import_with_progress.py`
- Test: `scripts/dictionary/tests/test_import_with_progress.py`

**Interfaces:**
- `main([])` and `main(["--list"])` list status and return zero without importing.
- Only `--next`, `--all`, `--only`, and `--force` select an import action.

- [x] Add failing tests proving no-argument and `--list` calls never invoke `prepare_and_import`.
- [x] Add failing tests for explicit action selection and conflicting action rejection.
- [x] Run the CLI test file and confirm failures.
- [x] Implement an argparse mutually exclusive action group and make no action list-only.
- [x] Ensure `--limit` alone cannot start an import.
- [x] Run CLI tests and confirm pass.

### Task 5: Verification and performance evidence

**Files:**
- Modify: `docs/superpowers/plans/2026-08-28-dictionary-import-staging-read-optimization.md`

**Interfaces:**
- Consumes all completed implementation interfaces.
- Produces recorded test and query-plan evidence in this plan.

- [x] Run `python3 -m pytest scripts/dictionary/tests/test_local_import.py scripts/dictionary/tests/test_import_with_progress.py -q`.
- [x] Run `python3 -m pytest scripts/dictionary/tests -q`.
- [x] Run `git diff --check`.
- [x] Run `EXPLAIN QUERY PLAN` on a generated staging fixture and confirm the three large tables are scanned without non-covering ordered lookups.
- [x] Run a fixed-fixture before/after-compatible timing harness and record staging-load rows and elapsed time without a hard millisecond gate.
- [x] Review the final diff for unrelated user changes and record remaining risks below.

## Verification Record

- `python3 -m pytest scripts/dictionary/tests -q`: 65 passed in 1.82s.
- `PYTHONPYCACHEPREFIX=/tmp/langmap-pycache python3 -m compileall ...`: passed. The explicit cache prefix avoids the managed sandbox denying writes to the macOS user cache.
- `git diff --check`: passed.
- Generated 10,000-row staging query plans: `SCAN input_entries`, `SCAN lexical_occurrences`, `SCAN lexical_clusters`, and `SCAN cluster_members`; no ordered non-covering lookup or temp B-tree.
- Fixed 10,000-row benchmark on internal storage: old path approximately 610,000 SQLite VM steps and 0.0531–0.0538s; new path approximately 410,000 VM steps and 0.0507–0.0522s. VM work fell about 33%; internal SSD elapsed time is cache-bound and is not used as a hard gate.
- Remaining risk: no-argument status listing still verifies SHA-256 for prior success records so stale detection remains exact. On the synchronous USB/NTFS volume this read-only verification can take noticeable time; the CLI now prints that verification phase immediately instead of appearing silent.
- Unrelated backend, migration, localization, and web changes were present before this work and were not edited as part of this plan.
