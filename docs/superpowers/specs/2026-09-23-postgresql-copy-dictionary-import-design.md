# PostgreSQL COPY Dictionary Importer

- Status: Draft for user review; implementation has not started.
- Date: 2026-09-23

## Context

`scripts/dictionary/import_mapping_csv_pg.py` currently validates and materializes an entire CSV in Python, then performs many individual PostgreSQL statements for expressions, locale links, source claims, readings, edges, and annotations. Large source exports therefore consume substantial importer memory and incur high database round-trip and per-row statement overhead.

Production PostgreSQL is hosted on a VM. A release directory containing canonical CSVs and their manifests can be copied to that VM before import. The operator can pause API reads and writes for the release window. The import must preserve source-scoped snapshot behavior; it must not truncate or globally replace shared dictionary data.

## Goals

- Provide a streaming PostgreSQL `COPY FROM STDIN` import path suitable for large CSV sources.
- Let the VM operator validate a release directory locally, then apply all of its manifests atomically in one PostgreSQL transaction.
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

Both modes support `--check` and `--apply`. `--check` remains database-free. Before opening a database transaction, the importer discovers manifests deterministically, verifies every manifest and CSV checksum, and validates each CSV's headers, locale/readings contract, row shape, normalized expressions, entry markers, and manifest counts. Validation and COPY processing stream records instead of retaining all source rows in Python memory.

An input directory with no manifests is an error. A valid zero-row manifest remains meaningful: applying it retires only that source's previous snapshot. In a batch, source identities (`source_type`, `source_name`) and source keys must not be duplicated.

Example VM workflow:

```bash
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --input-dir /srv/langmap/releases/dictionary-2026-09-23 \
  --check

# DATABASE_URL is supplied through the VM's protected environment/secret mechanism.
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --input-dir /srv/langmap/releases/dictionary-2026-09-23 \
  --apply --rebuild-secondary-indexes
```

Single-manifest invocations remain available for one-source checks and releases. The batch option is additive and does not reinterpret `--manifest`.

## Import architecture

1. Preflight every selected manifest and CSV before database mutation. Keep validation bounded-memory; retain only per-record working data and use disk-backed duplicate detection where required.
2. Open one PostgreSQL connection and one transaction for the complete target (one manifest or the full directory).
3. Resolve/create the bounded locale and source registry rows using the existing registry rules.
4. Create reusable temporary staging tables for the current source. Stream normalized entry, cell, and reading records to those tables with psycopg `COPY FROM STDIN`; the PostgreSQL server never needs filesystem access to the VM's CSV path.
5. Use set-based SQL to resolve expression IDs and synchronize locale links, expression source claims, readings, pairwise graph edges, source annotations, and edge-source claims. Continue to enforce stable `(language_id, text)` expression identity and the existing unique/primary-key constraints.
6. Record old claims/edge IDs from all replaced sources, remove only those sources' claims and annotations, and postpone orphan cleanup until all manifests have been merged. This prevents a shared expression from being deleted and recreated merely because its replacement source appeared later in the same release directory.
7. After all sources are merged, clean up only now-unclaimed source-owned orphans and refresh statistics for affected languages. Compare staged/expected per-source counts with resulting source claims, readings, annotations, and edge claims; verify recreated indexes are valid. Any mismatch aborts before commit. Recreate any dropped indexes, then run `ANALYZE` on affected large tables before commit.
8. Commit once. Any COPY, validation, merge, invariant check, index recreation, or other transaction error aborts the complete batch, including index DDL. No partially released source set becomes visible.

Temporary staging is reused source-by-source to bound temporary disk usage. No CSV is copied to a PostgreSQL server path, and no staging data survives the connection.

## Secondary-index policy

`--rebuild-secondary-indexes` is an explicit opt-in for batch `--input-dir --apply`; it is not the default and is rejected for `--check` or single-manifest mode. The importer captures and drops valid, non-unique, non-constraint secondary indexes on its allowlisted high-write tables (`expressions`, `expression_locale_links`, `expression_edges`, `expression_sources`, and `expression_edge_sources`), then recreates the captured definitions before commit.

Primary keys, unique constraints/indexes, exclusion constraints, and indexes on unrelated tables are retained. The importer must fail rather than silently continue if it cannot capture, drop, or recreate an eligible index. This operation is transactional and does not use `CONCURRENTLY`; index/table locks last until commit. Therefore the flag is for an announced maintenance window with API reads and writes paused. Small imports can omit it. Run `ANALYZE` after the bulk merge and index rebuild so query planning sees the refreshed data distribution.

## Compatibility and data safety

- Source ownership remains keyed by `(source_type, source_name)`; source markers remain source-specific.
- Replacing or retiring a source removes only its claims/readings/annotations. Shared expressions, edges, locale links, user-created edges, votes, and other sources remain protected by the current ownership/reference rules.
- Repeating the same release must be idempotent.
- A malformed later manifest, data constraint failure, connection interruption, or index creation failure must leave the pre-release committed state intact through transaction rollback.
- A transaction protects only work before `COMMIT`; it cannot undo a committed but semantically bad release. A verified pre-release backup is therefore a mandatory rollout gate.
- Existing `--manifest` callers and check/apply meanings remain supported.

## Verification plan

- Unit tests for streaming CSV/manifest validation, locale and reading columns, duplicate entry IDs, normalized text, zero-row source snapshots, directory discovery, duplicate source identities, and empty-directory rejection.
- Isolated PostgreSQL integration tests for single and batch imports, idempotency, shared cross-source expressions/edges, source-scoped retirement, readings/annotations/statistics, rollback when a later source fails, and index restoration on success and failure.
- Never run integration or performance tests against production. Use only an explicitly isolated `LANGMAP_TEST_DATABASE_URL`.
- Compare the existing row-oriented import path and COPY/set-based path on a representative large source or controlled large fixture using an isolated PostgreSQL database; record elapsed time, peak importer memory, and record/edge counts. If a safe local PostgreSQL instance or sufficient disk is unavailable, report that limitation rather than implying a performance result.
- Before a production run, after stopping all application/background writers, create a full-database custom-format `pg_dump` backup outside the VM's failure domain. Keep writes paused through the import so the backup is an exact pre-release recovery point. Inspect the archive and perform a restore test into an isolated database running a compatible PostgreSQL major version; an archive-list check alone is not a restore test. Record the backup location, timestamp, size, checksum, and restore-test result. Include this backup and restore test in the maintenance-window estimate.
- Run relevant Python tests and `git diff --check`.

## Rollout and rollback

1. Retain the current production release directory/manifests. Copy the new release directory to the VM and run `--check` before the maintenance window.
2. During the approved maintenance window, pause API reads/writes and all background or administrative writers. Create a full-database custom-format dump to storage outside the VM; verify the dump completed without warnings/errors and test restoring that exact archive into an isolated database. Keep writers paused until the release is accepted or rolled back. Do not begin the import if backup or restore verification fails.
3. Run batch `--apply`; add `--rebuild-secondary-indexes` only for a large release where its rebuild cost is justified.
4. The importer validates its per-source count invariants before commit. After commit, run source-scoped smoke checks against the release manifests and importer summary before resuming API traffic.
5. If apply fails before commit, PostgreSQL discards all transaction changes, including index DDL; correct the release and retry. If a committed release is semantically wrong, reapplying the previous known-good release directory is the fast source-scoped recovery and restores dictionary-source claims, but is not a byte-for-byte database restore. For exact pre-release recovery, restore the tested full-database backup to a separate database/instance, validate it, and cut traffic over to that restored target during the maintenance window. Never restore over the active production database without a reviewed, explicit recovery procedure, since that can overwrite legitimate writes made after the backup.

## Open implementation details

- Confirm whether the VM currently uses the required psycopg 3 version and document/install it as part of the runbook if needed.
- Select the concrete staging-column representation and set-based SQL layout after checking PostgreSQL's supported version and testing current annotation JSON behavior.
- Preserve existing report fields where practical; if large-source validation cannot compute distinct-expression/edge metrics without unbounded memory, document a compatible streaming summary rather than retaining the full CSV in memory.
- Define exact invariant queries/count semantics for pre-commit verification and post-commit smoke checks.
