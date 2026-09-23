# PostgreSQL COPY Dictionary Importer Implementation Plan

> Status: Implemented 2026-09-23. The plan is retained as the implementation record; verification used the complete dictionary test suite and an isolated PostgreSQL database. No representative production-scale performance benchmark was claimed.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dictionary importer's memory-heavy row-by-row PostgreSQL writes with streaming validation, `COPY` staging, set-based merges, one pre-release `pg_dump` per apply run by default, and independent source transactions with source-local rollback.

**Architecture:** Keep CSV and manifest validation database-free and parse each CSV as a bounded-memory stream. The check report retains streaming row/claim counters; global distinct expression/edge counts and duplicate `ENTRY_ID` enforcement are deferred to PostgreSQL staging, avoiding a slow SQLite accumulator. A release target is preflighted completely, then each source is staged and merged in its own PostgreSQL transaction; a `SAVEPOINT` marks the source merge, successful sources commit independently, and a failed source rolls back without undoing earlier commits. Connection-scoped temporary tables hold staged rows for the current source and orphan candidates until a final cleanup transaction.

**Tech Stack:** Python 3 standard library (`csv`, `subprocess`), psycopg 3 `COPY FROM STDIN`, PostgreSQL temporary tables and set-based SQL, pytest, isolated PostgreSQL integration tests.

**Spec:** `docs/superpowers/specs/2026-09-23-postgresql-copy-dictionary-import-design.md`

## Global Constraints

- Preserve `(language_id, text)` expression identity and source-scoped snapshot ownership.
- Do not truncate or globally replace shared dictionary data.
- `--check` remains database-free; `--apply` requires `DATABASE_URL`.
- `--apply` creates one pre-release custom-format `pg_dump` by default; `--no-pre-release-backup` is an explicit unsafe override.
- Every source has its own PostgreSQL transaction; an applied source commits independently and a failed source does not roll back earlier source commits.
- Do not use `CONCURRENTLY` for optional secondary-index rebuilds.
- Never run integration or performance tests against production; use only `LANGMAP_TEST_DATABASE_URL`.
- Use `apply_patch` for edits and finish with `git diff --check`.

---

### Task 1: Build bounded-memory manifest discovery and CSV streaming

**Files:**
- Modify: `scripts/dictionary/import_mapping_csv_pg.py`
- Test: `scripts/dictionary/tests/test_import_mapping_csv_pg.py`

**Interfaces:**
- Produces `ValidatedManifest`, `discover_manifests(target: Path)`, `validate_target(target: Path)`, and `iter_rows(validated: ValidatedManifest)` for the importer tasks that follow.
- Keeps `validate(manifest_path: Path) -> dict[str, Any]` compatible with existing tests and callers.

- [ ] **Step 1: Write failing tests for target discovery and streaming validation.**

Add tests that create nested `manifest.json` files and assert deterministic relative-path ordering, reject an empty `--input-dir`, reject duplicate `source_key` values, reject duplicate `(source_type, source_name)` values after applying the manifest defaults, and accept a zero-row CSV while returning `rows == 0`. Add a test that calls `iter_rows()` and verifies it yields rows one at a time with the same normalized cells/readings currently returned by `_read_csv`.

- [ ] **Step 2: Run the focused tests to verify the new interfaces fail.**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q
```

Expected: FAIL because directory discovery, `ValidatedManifest`, and the streaming iterator do not exist.

- [ ] **Step 3: Replace list-based CSV parsing with a reusable layout parser and row generator.**

Introduce immutable layout/manifest data structures that retain only manifest metadata, locale definitions, reading columns, CSV path, source identity, and validation summary. Split the current `_read_csv()` logic into:

```python
def _read_csv_layout(path: Path, metadata: dict[str, Any]) -> CsvLayout: ...
def iter_rows(validated: ValidatedManifest) -> Iterator[Row]: ...
```

The iterator must reopen the CSV, verify each row's column count, canonicalize expression text exactly as today, deduplicate cells/readings within the current row, and retain no previous rows. Keep entry, reading, expression-claim, and edge-claim counters streaming; set `expressions` and `edges` to `null` with an explicit deferred-count marker. Duplicate `ENTRY_ID` enforcement and global distinct-expression/edge counts happen in PostgreSQL staging during `--apply`.

- [ ] **Step 4: Implement recursive target discovery and complete preflight.**

Add `discover_manifests()` for either one `--manifest` path or an `--input-dir`; sort directory results by UTF-8 encoded relative path; reject an input directory with no manifests; validate every manifest and CSV before returning; and reject duplicate source keys and duplicate effective source identities. Make `validate_target()` return prepared manifests without retaining CSV rows.

- [ ] **Step 5: Run the focused tests and the existing dictionary unit suite.**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q
```

Expected: PASS, with existing summary assertions unchanged and new discovery/zero-row/streaming tests passing.

- [ ] **Step 6: Commit the bounded-memory validation slice.**

```bash
git add scripts/dictionary/import_mapping_csv_pg.py scripts/dictionary/tests/test_import_mapping_csv_pg.py
git commit -m "feat: stream dictionary manifest validation"
```

### Task 2: Add CLI target selection, backup policy, and result reporting

**Files:**
- Modify: `scripts/dictionary/import_mapping_csv_pg.py`
- Modify: `scripts/dictionary/README.md`
- Test: `scripts/dictionary/tests/test_import_mapping_csv_pg.py`

**Interfaces:**
- Adds mutually exclusive `--manifest PATH` / `--input-dir PATH` selection.
- Adds `--backup-dir PATH`, `--no-pre-release-backup`, and `--rebuild-secondary-indexes`.
- Produces `create_pre_release_backup(database_url: str, backup_dir: Path) -> Path` and a JSON-safe apply result containing `committed`, `failed`, `not_attempted`, and `cleanup` fields.

- [ ] **Step 1: Write failing CLI and backup-policy tests.**

Add tests for mutually exclusive target flags, database-free `--check`, default apply backup configuration resolution from `LANGMAP_PRE_RELEASE_BACKUP_DIR`, explicit `--backup-dir`, and the `--no-pre-release-backup` warning path. Mock `subprocess.run` for `pg_dump`, assert a custom-format output path is atomically finalized only after a zero exit status, and assert a failed `pg_dump` prevents any database connection attempt.

- [ ] **Step 2: Run the focused tests to verify the CLI additions fail.**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q
```

Expected: FAIL because the new CLI options and backup helper do not exist.

- [ ] **Step 3: Implement target parsing and one-time pre-release backup.**

Make `--manifest` and `--input-dir` the mutually exclusive required target group. Resolve the backup destination from `--backup-dir` or `LANGMAP_PRE_RELEASE_BACKUP_DIR`; when apply mode has neither and backup is not disabled, raise a clear `CsvContractError` before connecting to PostgreSQL. Run `pg_dump --format=custom --file=<temporary path> --dbname=<DATABASE_URL>` with `subprocess.run(..., check=False, capture_output=True, text=True)`, reject nonzero exit or an empty archive, and use `os.replace()` to publish the completed dump. Never create a backup for `--check`.

- [ ] **Step 4: Add deterministic source status reporting and partial-success exit behavior.**

Define an apply result that records each source key as committed, failed with an error string, or not attempted. A failed source must make the process return exit code `2` even when earlier sources committed. Print the result as JSON so an operator can resume failed/not-attempted sources with a single manifest or a corrected release directory.

- [ ] **Step 5: Update the dictionary README and run unit tests.**

Document `--input-dir`, the default backup behavior, `LANGMAP_PRE_RELEASE_BACKUP_DIR`, `--backup-dir`, `--no-pre-release-backup`, source-by-source commits, and the meaning of a partial-success nonzero exit. Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q
git diff --check
```

- [ ] **Step 6: Commit the CLI and backup slice.**

```bash
git add scripts/dictionary/import_mapping_csv_pg.py scripts/dictionary/README.md scripts/dictionary/tests/test_import_mapping_csv_pg.py
git commit -m "feat: add dictionary release targets and backup policy"
```

### Task 3: Create COPY staging and set-based source merge SQL

**Files:**
- Modify: `scripts/dictionary/import_mapping_csv_pg.py`
- Test: `scripts/dictionary/tests/test_import_mapping_csv_pg.py`

**Interfaces:**
- Produces `create_temp_tables(connection)`, `copy_source_rows(cursor, validated)`, and `merge_source(cursor, validated, source_id, locale_ids, source_key)`.
- Uses connection-scoped temporary tables for current-source cells, notes, readings, expression IDs, edge pairs, orphan expression candidates, orphan edge candidates, and affected language IDs.

- [ ] **Step 1: Write failing unit tests for COPY calls and set-based SQL boundaries.**

Add a small fake psycopg cursor/copy context in the unit test module and assert that copying a fixture emits rows through `write_row()` rather than executing one insert per cell/reading. Add assertions that the merge code issues `COPY`, `INSERT ... SELECT`, and `ON CONFLICT` statements and does not issue the old per-record expression/edge insert loop.

- [ ] **Step 2: Run the focused tests to verify the staging layer fails.**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q
```

Expected: FAIL because staging tables and merge functions do not exist.

- [ ] **Step 3: Implement reusable temporary staging tables.**

Create `ON COMMIT DELETE ROWS` tables for `_dictionary_cells`, `_dictionary_entry_ids`, `_dictionary_notes`, `_dictionary_readings`, `_dictionary_expression_ids`, and `_dictionary_edge_pairs`; `_dictionary_entry_ids` has a primary key and is populated from the row-numbered cell staging table so duplicate source markers fail in PostgreSQL. Create `ON COMMIT PRESERVE ROWS` tables for `_dictionary_orphan_expressions`, `_dictionary_orphan_edges`, and `_dictionary_affected_languages`. Populate current-source tables using psycopg 3 `cursor.copy("COPY ... FROM STDIN")` and `copy.write_row(...)`; use the validated iterator so only one row's working data is resident in Python.

- [ ] **Step 4: Implement set-based expression, locale-link, reading, claim, edge, and annotation merges.**

For each source transaction:

```sql
INSERT INTO expressions(language_id, text, homograph_index)
SELECT DISTINCT ll.language_id, c.expression_text, 1
FROM _dictionary_cells c
JOIN language_locales ll ON ll.code = c.locale_code
ON CONFLICT (language_id, text, homograph_index) DO NOTHING;
```

Then resolve IDs into `_dictionary_expression_ids`, insert locale links and `expression_sources`, resolve readings through the staged expression IDs, materialize pairwise expression IDs in `_dictionary_edge_pairs`, insert `expression_edges`, insert `expression_edge_sources`, and append note annotations with ordered `jsonb_agg` output after removing this source's prior annotations. Keep source markers and the current annotation JSON object shape unchanged.

- [ ] **Step 5: Implement source replacement and candidate tracking.**

Before deleting the current source snapshot, insert its expression and edge ownership IDs into the connection-scoped candidate tables, collect affected language IDs, remove only this source's annotations/claims/readings, and leave orphan deletion for final cleanup. Ensure a zero-row source still retires its old claims and readings. Keep registry creation bounded and reuse the existing locale conflict checks.

- [ ] **Step 6: Run unit tests and inspect the generated SQL diff.**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q
git diff --check
```

Expected: PASS for unit-level staging/SQL tests; no schema or migration change is needed because all staging tables are temporary.

- [ ] **Step 7: Commit the COPY/set-based merge slice.**

```bash
git add scripts/dictionary/import_mapping_csv_pg.py scripts/dictionary/tests/test_import_mapping_csv_pg.py
git commit -m "feat: stage dictionary sources with postgres copy"
```

### Task 4: Implement source-scoped transactions, savepoints, cleanup, and indexes

**Files:**
- Modify: `scripts/dictionary/import_mapping_csv_pg.py`
- Test: `scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py`

**Interfaces:**
- Produces `apply_target(target: Path, database_url: str, backup_dir: Path | None, backup_enabled: bool, rebuild_secondary_indexes: bool) -> dict[str, Any]`.
- Keeps `apply(manifest_path: Path, database_url: str) -> dict[str, Any]` as a compatibility wrapper with the explicit backup options available to the CLI.

- [ ] **Step 1: Write failing integration tests for source-local rollback and previous-source retention.**

Extend the isolated PostgreSQL test helpers to create two manifests under an input directory. Make the first source valid and make the second source fail during registry conflict validation after the first source has committed. Assert the process returns `2`, the JSON result lists the first source as committed and the second as failed, the first source's claims remain in PostgreSQL, and no later source is attempted. Add a test for a successful two-source input directory and a zero-row source retirement.

- [ ] **Step 2: Run the isolated integration tests to verify transaction orchestration fails.**

Run:

```bash
LANGMAP_TEST_DATABASE_URL="$LANGMAP_TEST_DATABASE_URL" python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py -q
```

Expected: the tests skip without the explicit isolated database URL; with one configured, the new source-local rollback tests fail against the current single-manifest implementation.

- [ ] **Step 3: Implement one transaction per source with a source merge savepoint.**

Open one connection, create temporary tables once, and loop over validated manifests in deterministic order. For each source use `with connection.transaction():`, create `SAVEPOINT before_source_merge`, run registry resolution, candidate capture, COPY staging, set-based merge, source invariants, optional index rebuild, and statistics refresh. On any exception execute `ROLLBACK TO SAVEPOINT before_source_merge`, re-raise so the source transaction rolls back, record the failure, and stop before the next source. A successful source exits the transaction context and commits independently.

- [ ] **Step 4: Implement final orphan cleanup and statistics refresh.**

After all selected sources commit, open a separate cleanup transaction. Delete only candidate edges with no remaining source marker, no annotations, no creator, no score, and no votes; then delete only candidate expressions with no source claim and none of the existing protected references (`expression_edges`, form edges, splits, handbook items, UI messages, or registry name references). Refresh statistics for the accumulated affected languages. If cleanup fails, retain all source commits, report cleanup as incomplete, and return a failure result without deleting anything outside the candidate sets.

- [ ] **Step 5: Implement transactional secondary-index capture/rebuild.**

Query PostgreSQL catalogs for valid, non-unique, non-constraint indexes on the five allowlisted high-write tables. Quote schema/index identifiers safely, execute `DROP INDEX` and the captured `pg_get_indexdef()` inside the current source transaction, recreate them before that source commits, and run `ANALYZE` on affected tables. Preserve primary keys, unique indexes, exclusion/constraint indexes, and unrelated-table indexes. A capture/drop/recreate error fails only the current source transaction.

- [ ] **Step 6: Run integration tests and focused unit tests.**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py -q
```

Expected: unit tests pass; integration tests pass when `LANGMAP_TEST_DATABASE_URL` points to an isolated database initialized from `backend/postgres/schema.sql`, otherwise integration tests skip.

- [ ] **Step 7: Commit the transaction and cleanup slice.**

```bash
git add scripts/dictionary/import_mapping_csv_pg.py scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py
git commit -m "feat: commit dictionary sources independently"
```

### Task 5: Complete documentation, compatibility tests, and verification

**Files:**
- Modify: `scripts/dictionary/README.md`
- Modify: `docs/superpowers/specs/2026-09-23-postgresql-copy-dictionary-import-design.md`
- Modify: `scripts/dictionary/tests/test_import_mapping_csv_pg.py`
- Modify: `scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py`

**Interfaces:**
- Documents the implemented flags, backup behavior, partial-success output, retry procedure, and source-level rollback semantics.

- [ ] **Step 1: Add compatibility tests for repeated imports and source-scoped idempotency.**

Run the same manifest twice with `--no-pre-release-backup`, assert identical source claim/edge/reading counts, then run a replacement manifest for the same source and assert old source markers/readings/annotations are retired while shared expressions and edges from another source remain.

- [ ] **Step 2: Add failure-path tests for backup, checksum drift, and index rebuild.**

Assert a failed backup prevents database mutation, a CSV checksum change after preflight aborts the current source, and an index-rebuild failure restores the source transaction's original indexes while leaving earlier committed sources unchanged. Keep all database tests behind `LANGMAP_TEST_DATABASE_URL`.

- [ ] **Step 3: Update the README and spec wording to match the implementation.**

Remove the old “single transaction/rollback the complete batch” wording from the README, document the source result JSON and resume behavior, and record any implementation limitations such as final cleanup retry after process interruption. Keep the existing Chinese documentation style and do not change CSV generation or schema contracts.

- [ ] **Step 4: Run the complete relevant verification set.**

Run:

```bash
python3 -m pytest scripts/dictionary/tests -q
git diff --check
```

If an isolated PostgreSQL URL is available, also run the integration tests explicitly and inspect the resulting source counts. Do not claim performance results unless a representative isolated fixture was measured.

- [ ] **Step 5: Review the final diff against the spec and report remaining operational prerequisites.**

Check that every spec goal has an implementation or test, that no schema migration was added for temporary staging, that backup and restore testing remain operator responsibilities, and that only the importer, its README, tests, plan, and already-approved spec are changed.
