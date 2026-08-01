# Task 8 Report — guarded production apply and operation journal

## Implemented

- `production apply` now requires a ready plan, matching configured database name and
  exact confirmation text, matching plan identity, and the same Git commit.
- Before any mutation it re-checks remote identity and obtains a Cloudflare Time Travel
  bookmark. Bookmark absence or identity/plan mismatch stops with no mutation.
- Mutation order is fixed: pending migrations, language registry bundle, system UI bundle,
  then a fresh read-only inventory and baseline verification. No deploy is invoked.
- Operation state is atomically appended to an ignored JSONL journal, including operation
  identity, bookmark, status, failure error, and post-apply verification result.
- The apply CLI requires explicit `--plan`, `--database-name`, and
  `--confirm-production` arguments; no default or shorthand can authorize a production
  mutation.
- Fake Wrangler tests verify that the Time Travel bookmark appears before any bundle file
  mutation and that a successful apply is journaled.

## Verification

```text
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'
Ran 61 tests in 18.287s — OK
```

All apply tests use a fake Wrangler. No production mutation, bookmark request, or remote
database operation was executed.

## Deferred minor

- The first apply implementation has no separate approved data-migration artifact because
  the current plan has no such artifact; the execution seam is intentionally limited to
  the pinned language/UI reference bundles until a migration metadata contract is added.
