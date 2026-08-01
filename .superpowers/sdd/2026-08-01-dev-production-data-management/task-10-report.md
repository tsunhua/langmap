# Task 10 Report — runbooks, entry-point convergence, and final verification

## Implemented

- Added runbooks for dev D1, schema migrations, reference sync, production data release,
  and D1 Time Travel restore.
- Updated the design spec status to implemented and documented the production operator gate.
- Renamed the direct remote migration npm alias to `db:migrate:remote:internal`; operator
  documentation now recommends `scripts/db/manage.sh` inventory/plan/apply/restore flows.
- Added safety warnings to the historical v1 → v2 migration documentation and connected
  i18n production guidance to the data manager runbook.

## Final verification

Passed:

- DB manager suite: 62 tests.
- i18n generator suite: 8 tests.
- i18n import wrapper: pass.
- v2 TypeScript suite: 7 tests.
- web typecheck/build: pass.
- `./build.sh`: pass.
- backend integration suite with local Worker on `127.0.0.1:8788`: 64 tests.
- `git diff --check`: pass.

No production inventory, plan, apply, or restore command was run against Cloudflare. Production
behavior was validated only with the fake Wrangler fixture.

## Deferred limitations recorded in earlier reports

- First-party UI locale JSON currently has partial coverage for a small set of newly added keys.
- Production apply currently has no separate approved data-migration artifact because none is
  present in the current plan; the stage boundary is ready for a future metadata contract.
- Provider-specific error payload enrichment and stronger normalized remote SQL fingerprints can
  be added without bypassing the existing safety gates.
