# Task 7 Report — production plan and reference diff

## Implemented

- Added `scripts/db/lib/reference.py` with an ownership-aware pure diff. Artifact-missing
  remote rows are never classified as deletes; they remain manual review items.
- Added read-only `production plan` generation on top of the identity-checked inventory.
- Plans include operation ID, schema baseline preflight, pending migrations, migration
  risk classification, managed reference expected/actual counts, action counts, and an
  explicit `mutation_allowed: false` guard.
- Plan reports are atomically written under ignored
  `scripts/db/state/production/plans/<operation-id>.json`.
- The CLI returns non-zero with a blocked plan when the approved baseline is unavailable
  or mismatched; it never falls back to a mutation.
- Fake tests cover plan read-only behavior, baseline blocking, no-delete reference diff,
  and CLI wiring.

## Verification

```text
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'
Ran 60 tests in 17.277s — OK
```

No production command was run. The fake Wrangler received only `info` and SELECT queries.

## Deferred minor

- Reference planning currently reconciles the pinned language/UI manifest counts and the
  pure key-level diff helper is ready for Task 8's approved data migration execution;
  full per-row remote reference planning remains intentionally read-only until ownership
  queries are expanded with the production schema contract.
