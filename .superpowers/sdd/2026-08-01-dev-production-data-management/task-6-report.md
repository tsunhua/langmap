# Task 6 Report — production read-only inventory and baseline

## Implemented

- Added `scripts/db/lib/production.py` with fail-closed production identity validation,
  read-only Wrangler `d1 info` and `d1 execute --command SELECT` calls, schema/column/
  migration inventory, reference/orphan counts, and managed system UI ownership counts.
- Added `scripts/db/lib/journal.py` for atomic JSON report writes.
- Added versioned `scripts/db/production-baseline.json` containing only database identity,
  schema object names, and migration checksums; it contains no remote row counts,
  bookmarks, credentials, or application data.
- Added `production inventory` CLI wiring. Console output is a summary; the detailed
  report is written under ignored `scripts/db/state/production/inventory.json`.
- Added fake Wrangler coverage proving identity mismatch stops before SELECT and that no
  mutation SQL is accepted by the production fixture.
- Added pure `check_baseline`; it only reads inventory/baseline and never writes
  `d1_migrations` or any remote table.

## Verification

```text
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'
Ran 58 tests in 17.167s — OK
```

Focused production inventory and CLI tests also pass. No remote production command was
run during this task.

## Deferred minor

- The inventory report currently records schema object SQL returned by Wrangler for audit
  context, while the approved baseline compares stable object type/name pairs and locked
  migration checksums. A later plan task can add normalized SQL fingerprints if a stronger
  remote schema diff is required.
