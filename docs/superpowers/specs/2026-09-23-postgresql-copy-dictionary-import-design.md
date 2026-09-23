# PostgreSQL COPY Dictionary Importer

- Status: Draft for user review; implementation has not started.
- Date: 2026-09-23

## Context

`scripts/dictionary/import_mapping_csv_pg.py` currently validates and materializes an entire CSV in Python, then performs many individual PostgreSQL statements for expressions, locale links, source claims, readings, edges, and annotations. Large source exports therefore consume substantial importer memory and incur high database round-trip and per-row statement overhead.

Production PostgreSQL is hosted on a VM. A release directory containing canonical CSVs and their manifests can be copied to that VM before import. The operator can pause API reads and writes for the release window. The import must preserve source-scoped snapshot behavior; it must not truncate or globally replace shared dictionary data. Sources are committed independently: a failed source is rolled back without undoing sources that were already committed.

## Goals

- Provide a streaming PostgreSQL `COPY FROM STDIN` import path suitable for large CSV sources.
- Let the VM operator validate a release directory locally, then apply its manifests deterministically with one PostgreSQL transaction per source.
- Create one optional pre-release `pg_dump` recovery point per apply run, enabled by default and explicitly disableable.
- Replace per-record database round trips with temporary staging tables and set-based SQL merges.
- Preserve existing expression identity, locale, reading, source-marker, annotation, graph-edge, orphan-cleanup, and language-statistics semantics.
- Optionally improve large imports by rebuilding eligible secondary indexes, without dropping primary-key or uniqueness enforcement.
- Keep the existing single-manifest CLI workflow usable.

## Non-goals

- No production-wide `TRUNCATE`, source-independent dictionary wipe, or direct `COPY` into live application tables.
- No permanent staging tables or schema migrations.
- No changes to dictionary CSV generation or manifest format.
- No automatic import of a repository's entire dictionary collection unless the operator deliberately passes a release directory containing those manifests.

## CLI and release-directory behavior

The CLI accepts exactly one import target:

- `--manifest PATH`: existing single-source mode.
- `--input-dir PATH`: recursively discover `manifest.json` files and import the complete release directory.

Both modes support `--check` and `--apply`. `--check` remains database-free. Before opening a database transaction, the importer discovers manifests deterministically, verifies every manifest and CSV checksum, and validates each CSV's headers, locale/readings contract, row shape, normalized expressions, and manifest counts. Validation and COPY processing stream records instead of retaining all source rows in Python memory. The check summary keeps streaming row/claim counters, but defers global distinct-expression/edge counts and duplicate `ENTRY_ID` enforcement to PostgreSQL staging; it reports the deferred distinct fields explicitly rather than using a disk-backed SQLite accumulator.

An input directory with no manifests is an error. A valid zero-row manifest remains meaningful: applying it retires only that source's previous snapshot. In a batch, source identities (`source_type`, `source_name`) and source keys must not be duplicated. Preflight covers the complete selected target before any source is committed; a database or data error discovered during apply can still leave earlier sources committed.

For `--apply`, the importer creates one custom-format `pg_dump` before the first source transaction by default. The destination must be supplied by a controlled backup configuration or `--backup-dir`; the importer fails before mutation if the backup cannot be written or completed. `--no-pre-release-backup` explicitly disables this protection and must produce a prominent warning. `--check` never creates a backup. The backup is created once per apply run, not once per source.

Example VM workflow:

```bash
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --input-dir /srv/langmap/releases/dictionary-2026-09-23 \
  --check

# DATABASE_URL is supplied through the VM's protected environment/secret mechanism.
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --input-dir /srv/langmap/releases/dictionary-2026-09-23 \
  --apply --backup-dir /srv/langmap/backups \
  --rebuild-secondary-indexes
```

Use `--no-pre-release-backup` only when an equivalent, verified recovery point is already managed outside the importer. Single-manifest invocations remain available for one-source checks and releases. The batch option is additive and does not reinterpret `--manifest`.

## Import architecture

1. Preflight every selected manifest and CSV before database mutation. Keep validation bounded-memory; retain only per-record working data and report global distinct counts as deferred when they require database state. PostgreSQL staging enforces duplicate `ENTRY_ID` with a temporary primary key during apply.
2. For `--apply`, create the single pre-release `pg_dump` recovery point unless explicitly disabled. Keep API, background, and administrative writes paused for the backup and all source transactions.
3. Open one PostgreSQL connection and process manifests in deterministic order. Each source gets its own transaction and commit boundary; a source failure rolls back only that source and stops subsequent sources from being attempted.
4. Within the source transaction, create or reuse temporary staging tables and establish `SAVEPOINT before_source_merge`. Stream normalized entry, cell, and reading records to those tables with psycopg `COPY FROM STDIN`; a connection-scoped staging primary key rejects duplicate `ENTRY_ID` values, and the PostgreSQL server never needs filesystem access to the VM's CSV path.
5. Use set-based SQL to resolve expression IDs and synchronize locale links, expression source claims, readings, pairwise graph edges, source annotations, and edge-source claims. Continue to enforce stable `(language_id, text)` expression identity and the existing unique/primary-key constraints. Resolve/create the bounded locale and source registry rows using the existing registry rules. A reading column first targets an expression with the exact reading locale in the row; when that profile is not a `LOCALE_*` column, it targets the row's expression(s) in the same language while retaining the reading profile as `locale_id`.
6. Record old claims/edge IDs affected by the source, remove only that source's claims and annotations, and retain orphan candidates in connection-scoped temporary tables. Do not delete candidates immediately if a later source in the same release may reuse the expression or edge; final orphan cleanup runs only after all selected sources have committed.
7. Compare PostgreSQL-staged per-source counts with resulting source claims, readings, annotations, and edge claims before that source commits. On mismatch or any source error, `ROLLBACK TO SAVEPOINT before_source_merge`, roll back the source transaction, report the source as failed, and leave earlier committed sources intact. On success, recreate any indexes handled for that source, run source-level checks, and commit that source.
8. After all sources succeed, run a final cleanup transaction for only now-unclaimed candidates and refresh statistics for affected languages. If final cleanup fails, keep all source commits, report the cleanup as incomplete, and allow a safe retry; never delete shared or user-owned data merely to make cleanup succeed.

Temporary staging is reused source-by-source to bound temporary disk usage. Candidate tracking may remain in connection-scoped temporary tables until final cleanup; no CSV is copied to a PostgreSQL server path, and no staging data survives the connection.

## Secondary-index policy

`--rebuild-secondary-indexes` is an explicit opt-in for `--apply`; it is not the default and is rejected for `--check`. Under source-scoped transactions, the importer captures and drops valid, non-unique, non-constraint secondary indexes on its allowlisted high-write tables (`expressions`, `expression_locale_links`, `expression_edges`, `expression_sources`, and `expression_edge_sources`) for the current source transaction, then recreates the captured definitions before that source commits. Multi-source releases may therefore rebuild the same indexes more than once; small or partial releases should omit the flag.

Primary keys, unique constraints/indexes, exclusion constraints, and indexes on unrelated tables are retained. The importer must fail the current source rather than silently continue if it cannot capture, drop, or recreate an eligible index. This operation is transactional and does not use `CONCURRENTLY`; index/table locks last until that source commits. Therefore the flag is for an announced maintenance window with API reads and writes paused. Run `ANALYZE` after the source merges and index rebuilds so query planning sees the refreshed data distribution.

## Compatibility and data safety

- Source ownership remains keyed by `(source_type, source_name)`; source markers remain source-specific.
- Replacing or retiring a source removes only its claims/readings/annotations. Shared expressions, edges, locale links, user-created edges, votes, and other sources remain protected by the current ownership/reference rules.
- Repeating the same release must be idempotent.
- A malformed manifest is rejected during complete preflight before any source commit. A data constraint failure, connection interruption, or index creation failure rolls back only the current source; earlier source commits remain visible and later sources are not attempted.
- A source transaction protects only work before its `COMMIT`; savepoints cannot undo an already committed source. A verified pre-release backup is therefore the default recovery point for a semantically bad release or a broader operational failure.
- Existing `--manifest` callers and check/apply meanings remain supported.

## Verification plan

- Unit tests for streaming CSV/manifest validation, locale and reading columns, deferred distinct-count reporting, normalized text, zero-row source snapshots, directory discovery, duplicate source identities, and empty-directory rejection; PostgreSQL integration tests cover duplicate `ENTRY_ID` rejection in staging.
- Isolated PostgreSQL integration tests for single and batch imports, idempotency, shared cross-source expressions/edges, source-scoped retirement, readings/annotations/statistics, source-scoped rollback with earlier-source commit retention, stopping after a failed source, final orphan cleanup, and index restoration on success and failure.
- Never run integration or performance tests against production. Use only an explicitly isolated `LANGMAP_TEST_DATABASE_URL`.
- Compare the existing row-oriented import path and COPY/set-based path on a representative large source or controlled large fixture using an isolated PostgreSQL database; record elapsed time, peak importer memory, and record/edge counts. If a safe local PostgreSQL instance or sufficient disk is unavailable, report that limitation rather than implying a performance result.
- Before a production run, after stopping all application/background writers, create one full-database custom-format `pg_dump` backup outside the VM's failure domain unless the operator explicitly disables the default backup. Keep writes paused through all source commits so the backup is an exact pre-release recovery point. Inspect the archive and perform a restore test into an isolated database running a compatible PostgreSQL major version; an archive-list check alone is not a restore test. Record the backup location, timestamp, size, checksum, and restore-test result. Include this backup and restore test in the maintenance-window estimate.
- Run relevant Python tests and `git diff --check`.

## Rollout and rollback

1. Retain the current production release directory/manifests. Copy the new release directory to the VM and run `--check` before the maintenance window.
2. During the approved maintenance window, pause API reads/writes and all background or administrative writers. Create the default one-time full-database custom-format dump to storage outside the VM; verify the dump completed without warnings/errors and test restoring that exact archive into an isolated database. Keep writers paused through all source transactions and final cleanup. Do not begin the import if backup or restore verification fails, unless the operator explicitly accepted `--no-pre-release-backup` and the equivalent recovery point is documented.
3. Run `--apply`; add `--rebuild-secondary-indexes` only for a large source where rebuilding its indexes is worth the repeated source-level cost.
4. The importer validates each source's count invariants before committing that source and reports committed, failed, and not-attempted sources. After the run, execute source-scoped smoke checks for every committed source before resuming API traffic.
5. If a source fails before its commit, PostgreSQL discards that source's changes, including its index DDL; correct the source and retry it without undoing earlier committed sources. If a committed source is semantically wrong, reapplying its previous known-good manifest is the fast source-scoped recovery, but is not a byte-for-byte database restore. For exact pre-release recovery, restore the tested full-database backup to a separate database/instance, validate it, and cut traffic over to that restored target during the maintenance window. Never restore over the active production database without a reviewed, explicit recovery procedure, since that can overwrite legitimate writes made after the backup.

## Open implementation details

- Confirm whether the VM currently uses the required psycopg 3 version and document/install it as part of the runbook if needed.
- Select the concrete staging-column representation and set-based SQL layout after checking PostgreSQL's supported version and testing current annotation JSON behavior.
- Keep the check report shape stable where practical: `expressions` and `edges` are `null` with `distinct_counts=deferred_to_postgresql`, while row/claim counters remain available. The importer now uses PostgreSQL staging for the exact pre-commit invariant counts.
- Define the source result format and non-zero exit behavior for partial success, including how an operator resumes failed or not-attempted sources.
- Define a resumable final orphan-cleanup strategy after a process interruption, since connection-scoped candidate tables disappear when the importer exits before finalization.
