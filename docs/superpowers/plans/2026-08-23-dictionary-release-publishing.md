# Dictionary Release Schema and Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the minimal D1 release/binding/evidence/POS model and a guarded publisher so a dictionary fixture release can be applied, activated, verified, and rolled back without changing ordinary LangMap data.

**Architecture:** Store immutable release rows and use one `dictionary_dataset_state.active_release_id` pointer as the atomic visibility switch. Reuse existing Expression and edge identities, attach release-specific bindings/evidence/membership, centralize active-release SQL predicates, and extend the existing `scripts/db` plan/apply/bookmark workflow for approved dictionary artifacts.

**Tech Stack:** Cloudflare D1/SQLite, Hono, TypeScript, Vitest, Python 3.12 standard library, Wrangler 4, existing `scripts/db` framework.

## Global Constraints

- Requires the Plan 1 preview/staging contract from `2026-08-23-dictionary-export-staging.md`.
- Use the next available migration sequence; at plan creation it is `0034`.
- Every schema change updates migration, `backend/schema.sql`, schema contract tests, and `scripts/db/migration-lock.json`.
- Do not add definitions, labels, forms, raw POS, or a public sense table to D1.
- One managed edge remains one row in `expression_edges`; multiple claims use evidence rows.
- The single-row dataset-state update is the visibility commit point; chunk loading must not become publicly visible before it.
- Unmanaged objects are always visible. A reused user/system object must not become hidden after release rollback.
- When an ordinary API write reuses an object originally created only by a dictionary release, mark its historical ownership rows promoted; do not delete the audit rows or create a duplicate object.
- Expressions remain addressable after rollback; cleanup only removes safely unreferenced objects created by a release.
- All query builders validate aliases/kinds from closed sets; never interpolate request data into SQL.
- Backend changes use no `any`; API responses retain `{ success, data?, error?, message? }`.
- Backend tests use Vitest; Python publisher tests use `python3 -m unittest` or existing unittest-compatible discovery.
- Preserve existing worktree changes and generated directories.

---

## File Structure

| File | Responsibility |
|---|---|
| `backend/migrations/0034_dictionary_dataset_releases.sql` | Release, state, binding, evidence, membership and POS DDL |
| `backend/src/services/dictionaryReleaseEligibility.ts` | Closed-set SQL eligibility builders |
| `backend/src/services/dictionaryReleases.ts` | Active release and POS read models |
| `backend/src/types/dictionaryRelease.ts` | Release/POS row types |
| `scripts/dictionary/langmap_dictionary/compiler.py` | D1 inventory-aware ID allocation and SQL operations |
| `scripts/dictionary/langmap_dictionary/artifact.py` | Manifest/chunk/checksum contract |
| `scripts/dictionary/langmap_dictionary/publisher.py` | Dictionary CLI orchestration over the managed database executor |
| `scripts/db/lib/dictionary_release.py` | Shared local/production release executor, journal and invariant checks |
| `scripts/db/lib/production.py` | Approved artifact plan/apply integration |

### Task 1: Add release and POS schema

**Files:**
- Create: `backend/migrations/0034_dictionary_dataset_releases.sql`
- Modify: `backend/schema.sql`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `backend/tests/mappingQueryIndexes.test.ts`
- Modify: `scripts/db/migration-lock.json`

**Interfaces:**
- Produces tables `dictionary_dataset_releases`, `dictionary_dataset_state`, `dictionary_expression_bindings`, `expression_edge_evidence`, `dictionary_release_objects`, `parts_of_speech`, `expression_pos_attestations`.
- Dataset key for this program is `managed-dictionaries`.

- [ ] **Step 1: Add failing schema contract assertions**

```ts
it('defines dictionary release identity and one active pointer', () => {
  expect(schema).toMatch(/CREATE TABLE dictionary_dataset_releases[\s\S]*?artifact_hash TEXT NOT NULL/s);
  expect(schema).toMatch(/CREATE TABLE dictionary_dataset_state[\s\S]*?active_release_id TEXT/s);
  expect(schema).toMatch(/UNIQUE \(dataset_key, input_manifest_hash, adapter_bundle_hash, reconciliation_config_hash\)/s);
});

it('defines release bindings, edge evidence, object membership, and POS', () => {
  for (const table of [
    'dictionary_expression_bindings', 'expression_edge_evidence',
    'dictionary_release_objects', 'parts_of_speech', 'expression_pos_attestations',
  ]) expect(schema).toMatch(new RegExp(`CREATE TABLE ${table}`));
});
```

Also assert all foreign keys, checks, composite keys, and required indexes.

- [ ] **Step 2: Run the contract test and verify failure**

Run: `cd backend && npx vitest run tests/schemaContract.test.ts`

Expected: FAIL because the new tables are absent.

- [ ] **Step 3: Write migration DDL**

Use this column/key contract in migration and equivalent full-schema DDL:

```sql
CREATE TABLE dictionary_dataset_releases (
  id TEXT PRIMARY KEY,
  dataset_key TEXT NOT NULL,
  parent_release_id TEXT,
  input_manifest_hash TEXT NOT NULL,
  exporter_schema_version INTEGER NOT NULL,
  adapter_bundle_hash TEXT NOT NULL,
  reconciliation_config_hash TEXT NOT NULL,
  artifact_hash TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('planned','applying','validated','failed')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activated_at TEXT,
  UNIQUE (dataset_key, input_manifest_hash, adapter_bundle_hash, reconciliation_config_hash),
  FOREIGN KEY (parent_release_id) REFERENCES dictionary_dataset_releases(id)
);

CREATE TABLE dictionary_dataset_state (
  dataset_key TEXT PRIMARY KEY,
  active_release_id TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (active_release_id) REFERENCES dictionary_dataset_releases(id)
);

CREATE TABLE dictionary_expression_bindings (
  release_id TEXT NOT NULL,
  claim_key TEXT NOT NULL,
  cluster_key TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('headword','equivalent','synonym','example_text','example_translation')),
  expression_id TEXT NOT NULL,
  binding_kind TEXT NOT NULL CHECK (binding_kind IN ('allocated','reused','ai_merged','explicit_group')),
  PRIMARY KEY (release_id, claim_key, role),
  FOREIGN KEY (release_id) REFERENCES dictionary_dataset_releases(id),
  FOREIGN KEY (expression_id) REFERENCES expressions(id)
);

CREATE TABLE expression_edge_evidence (
  release_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  claim_key TEXT NOT NULL,
  evidence_kind TEXT NOT NULL CHECK (evidence_kind IN ('equivalent','synonym','example')),
  PRIMARY KEY (release_id, edge_id, claim_key, evidence_kind),
  FOREIGN KEY (release_id) REFERENCES dictionary_dataset_releases(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);

CREATE TABLE dictionary_release_objects (
  release_id TEXT NOT NULL,
  object_kind TEXT NOT NULL CHECK (object_kind IN ('expression','edge','reading','locale_attestation','pos_attestation')),
  object_id TEXT NOT NULL,
  claim_key TEXT NOT NULL,
  object_action TEXT NOT NULL CHECK (object_action IN ('created','reused')),
  promoted_at TEXT,
  promotion_actor_kind TEXT CHECK (promotion_actor_kind IN ('user','system')),
  promoted_by INTEGER,
  PRIMARY KEY (release_id, object_kind, object_id, claim_key),
  FOREIGN KEY (release_id) REFERENCES dictionary_dataset_releases(id),
  FOREIGN KEY (promoted_by) REFERENCES users(id),
  CHECK (promoted_at IS NULL OR object_action = 'created'),
  CHECK (
    (promoted_at IS NULL AND promotion_actor_kind IS NULL AND promoted_by IS NULL)
    OR (promoted_at IS NOT NULL AND promotion_actor_kind = 'user' AND promoted_by IS NOT NULL)
    OR (promoted_at IS NOT NULL AND promotion_actor_kind = 'system' AND promoted_by IS NULL)
  )
);
```

`status` records load validity only. It never represents public visibility; `dictionary_dataset_state.active_release_id` is the sole active truth. Activation/rollback does not rewrite release status. `activated_at` records the first successful activation for audit and is set with `COALESCE(activated_at, CURRENT_TIMESTAMP)` in the same transaction as the pointer switch.

Add POS tables and seed the closed codes `noun`, `proper-noun`, `verb`, `auxiliary`, `adjective`, `adverb`, `pronoun`, `determiner`, `numeral`, `adposition`, `conjunction`, `particle`, `interjection`, `abbreviation`, and `phrase`, with unique `sort_order` in that order.

- [ ] **Step 4: Add indexes**

Create indexes for active pointer joins, binding lookup by expression, evidence lookup by edge/release, object lookup by kind/id/action/release, and POS lookup by expression/release. Extend `mappingQueryIndexes.test.ts` to assert the correlated eligibility predicates have covering index prefixes. Do not add a partial unique active-status index; `dictionary_dataset_state` is the sole active pointer.

- [ ] **Step 5: Sync migration lock**

Run the existing migration-lock sync command used by `scripts/db` (inspect `scripts/db/manage.sh` help if needed), then verify sequence, size, and SHA-256 match the new migration. Do not hand-edit checksum values.

- [ ] **Step 6: Run schema tests**

Run:

```bash
cd backend
npx vitest run tests/schemaContract.test.ts tests/mappingQueryIndexes.test.ts
cd ..
python3 -m unittest scripts.db.tests.test_migrations -v
```

Expected: PASS.

- [ ] **Step 7: Commit Task 1**

```bash
git add backend/migrations/0034_dictionary_dataset_releases.sql backend/schema.sql backend/tests/schemaContract.test.ts backend/tests/mappingQueryIndexes.test.ts scripts/db/migration-lock.json
git commit -m "feat(db): add managed dictionary release schema"
```

### Task 2: Centralize active-release eligibility SQL

**Files:**
- Create: `backend/src/services/dictionaryReleaseEligibility.ts`
- Create: `backend/tests/dictionaryReleaseEligibility.test.ts`

**Interfaces:**
- `edgeEligibilityPredicate(edgeAlias: EdgeAlias) -> string`.
- `releaseObjectEligibilityPredicate(kind: ManagedObjectKind, objectIdSql: ManagedObjectIdSql) -> string`.
- `dictionaryManagedObjectPredicate(kind: ManagedObjectKindWithEdge, objectIdSql: ManagedObjectIdSqlWithEdge) -> string`.
- `activeReleasePredicate(releaseIdSql: ReleaseIdSql) -> string`.
- `promoteManagedObject(db, kind, objectId, actor) -> Promise<void>` where actor is `{ kind: 'user'; userId: number } | { kind: 'system' }`.
- Aliases/ID expressions use closed union types, not arbitrary strings.

- [ ] **Step 1: Write failing pure-function tests**

```ts
expect(edgeEligibilityPredicate('ed')).toContain('expression_edge_evidence');
expect(edgeEligibilityPredicate('ed')).toContain('dictionary_release_objects');
expect(releaseObjectEligibilityPredicate('reading', 'r.id')).toContain("'reading'");
```

Assert generated SQL implements `unmanaged OR active membership`, references `dictionary_dataset_state.active_release_id`, and never checks only `expression_edges.source`.

- [ ] **Step 2: Run and verify failure**

Run: `cd backend && npx vitest run tests/dictionaryReleaseEligibility.test.ts`

Expected: FAIL because the module does not exist.

- [ ] **Step 3: Implement closed-set builders**

Use exact types:

```ts
export type EdgeAlias = 'e' | 'ed' | 'g' | 'direct_edge';
export type ManagedObjectKind = 'reading' | 'locale_attestation' | 'pos_attestation';
export type ManagedObjectKindWithEdge = ManagedObjectKind | 'edge';
export type ManagedObjectIdSql = 'r.id' | 'a.id' | 'pa.id';
export type ManagedObjectIdSqlWithEdge = ManagedObjectIdSql | 'e.id' | 'ed.id' | 'g.id' | 'direct_edge.id';
export type ReleaseIdSql = 'b.release_id' | 'ev.release_id' | 'pa.release_id' | 'ro.release_id';
```

For edges, return true when no unpromoted `dictionary_release_objects` row with `object_kind='edge'`, matching ID, and `object_action='created'` exists, or when active `expression_edge_evidence` exists. For other objects, use the same unpromoted-created test plus active `dictionary_release_objects` membership. `dictionaryManagedObjectPredicate` answers historical ownership regardless of active release or promotion and is the split guard. Promotion updates only previously unpromoted historical `created` rows for that object in one D1 batch; reruns never overwrite the first actor/time.

- [ ] **Step 4: Run tests**

Run the Task 2 test; expect PASS.

- [ ] **Step 5: Commit Task 2**

```bash
git add backend/src/services/dictionaryReleaseEligibility.ts backend/tests/dictionaryReleaseEligibility.test.ts
git commit -m "feat(api): centralize dictionary release visibility"
```

### Task 3: Apply edge eligibility to every consumer

**Files:**
- Modify: `backend/src/services/mappings.ts`
- Modify: `backend/src/services/mappingGraph.ts`
- Modify: `backend/src/services/languageContent.ts`
- Modify: `backend/src/services/localizedName.ts`
- Modify: `backend/src/services/localizationDomain.ts`
- Modify: `backend/src/services/workbench.ts`
- Modify: `backend/src/services/votes.ts`
- Modify: `backend/src/services/splits.ts`
- Modify: `backend/src/services/readings.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/routes/feed.ts`
- Modify: `backend/src/routes/users.ts`
- Modify: `backend/src/routes/handbooks.ts`
- Modify: `backend/src/routes/localization.ts`
- Test: `backend/tests/mappings.test.ts`
- Test: `backend/tests/mappingsIntegration.test.ts`
- Test: `backend/tests/mappingGraphV2.test.ts`
- Test: `backend/tests/languageContent.test.ts`
- Test: `backend/tests/languagesIntegration.test.ts`
- Test: `backend/tests/feed.test.ts`
- Test: `backend/tests/users.test.ts`
- Test: `backend/tests/votes.test.ts`
- Test: `backend/tests/splits.test.ts`
- Test: `backend/tests/readings.test.ts`
- Test: `backend/tests/readingsIntegration.test.ts`
- Test: `backend/tests/expressions.test.ts`
- Test: `backend/tests/expressionsIntegration.test.ts`
- Test: `backend/tests/localizedName.test.ts`
- Test: `backend/tests/registryLocalizedName.test.ts`
- Test: `backend/tests/localizationDomain.test.ts`
- Test: `backend/tests/localizationIntegration.test.ts`
- Test: `backend/tests/workbench.test.ts`
- Test: `backend/tests/handbooks.test.ts`
- Test: `backend/tests/morphologyIntegration.test.ts`

**Interfaces:**
- Consumes `edgeEligibilityPredicate`.
- Produces one consistent public definition of an eligible edge.

- [ ] **Step 1: Add failing mapping and graph tests**

Extend fake-D1 SQL assertions and integration fixtures with three edges: unmanaged, created by inactive release, and created/reused by active release. Assert counts, page items, and graph traversal include unmanaged＋active only.

- [ ] **Step 2: Run focused tests and verify failure**

Run:

```bash
cd backend
npx vitest run tests/mappings.test.ts tests/mappingGraphV2.test.ts tests/languageContent.test.ts
```

Expected: FAIL because current queries see inactive edges.

- [ ] **Step 3: Update service queries**

Import the helper and inject its static predicate into every edge subquery, count, join, graph expansion, mapping-count sort, localized-name candidate query, workbench query, and localization revision query. Parenthesize existing `OR` endpoint conditions before adding `AND eligibility`.

Apply non-edge membership predicates explicitly to:

- `languageContent.ts`: locale-filtered `expression_count`, global `reading_count`, `mapped_expression_count`, list locale `EXISTS`, and each row's `reading_count`;
- `mappingGraph.ts`: root and endpoint locale-attestation subqueries;
- `localizedName.ts`, `localizationDomain.ts`, and `workbench.ts`: target-locale candidate `EXISTS` clauses;
- `handbooks.ts`: language-profile locale projection.

- [ ] **Step 4: Add failing route/vote/split/promotion tests**

Assert inactive edges never appear in feed, user activity or localization reads, cannot receive a new vote, and cannot be selected for admin split. In `users.ts`, cover both the mapping-activity branch and vote-activity branch joined back to an eligible edge. For handbooks, assert an inactive managed-only locale attestation cannot supply `language_profile_code/name`, while unmanaged or promoted attestations remain valid. Reused unmanaged edges remain visible and mutable after rollback. When `createEdge`, `createEdgesForPairs`, `createReading`, or `createLocaleAttestation` reuses an inactive managed-created object through an ordinary user or system write, assert all previously unpromoted historical created-membership rows receive the immutable first promotion actor/time and the object remains visible after rollback.

- [ ] **Step 5: Update direct route SQL and write guards**

Apply the helper to direct SQL routes. In `votes.ts`, edge existence means eligible edge. Make `castVote` return the already validated endpoints so `routes/localization.ts` does not perform an unfiltered second edge lookup. In `splits.ts`, use `dictionaryManagedObjectPredicate` and reject edges ever created by a managed release with `DICTIONARY_MANAGED_EDGE_IMMUTABLE`; promotion does not make artifact endpoints mutable. Call `promoteManagedObject` only on ordinary write-path reuse; publisher SQL never calls promotion.

- [ ] **Step 6: Run all affected tests**

Run:

```bash
cd backend
npx vitest run tests/mappings.test.ts tests/mappingsIntegration.test.ts tests/mappingGraphV2.test.ts tests/languageContent.test.ts tests/languagesIntegration.test.ts tests/feed.test.ts tests/users.test.ts tests/votes.test.ts tests/splits.test.ts tests/readings.test.ts tests/readingsIntegration.test.ts tests/expressions.test.ts tests/expressionsIntegration.test.ts tests/localizedName.test.ts tests/registryLocalizedName.test.ts tests/localizationDomain.test.ts tests/localizationIntegration.test.ts tests/workbench.test.ts tests/handbooks.test.ts tests/morphologyIntegration.test.ts
```

Expected: PASS.

- [ ] **Step 7: Commit Task 3**

```bash
git add backend/src/services/mappings.ts backend/src/services/mappingGraph.ts backend/src/services/languageContent.ts backend/src/services/localizedName.ts backend/src/services/localizationDomain.ts backend/src/services/workbench.ts backend/src/services/votes.ts backend/src/services/splits.ts backend/src/services/readings.ts backend/src/services/expressions.ts backend/src/services/dictionaryReleaseEligibility.ts backend/src/routes/feed.ts backend/src/routes/users.ts backend/src/routes/handbooks.ts backend/src/routes/localization.ts backend/tests/mappings.test.ts backend/tests/mappingsIntegration.test.ts backend/tests/mappingGraphV2.test.ts backend/tests/languageContent.test.ts backend/tests/languagesIntegration.test.ts backend/tests/feed.test.ts backend/tests/users.test.ts backend/tests/votes.test.ts backend/tests/splits.test.ts backend/tests/readings.test.ts backend/tests/readingsIntegration.test.ts backend/tests/expressions.test.ts backend/tests/expressionsIntegration.test.ts backend/tests/localizedName.test.ts backend/tests/registryLocalizedName.test.ts backend/tests/localizationDomain.test.ts backend/tests/localizationIntegration.test.ts backend/tests/workbench.test.ts backend/tests/handbooks.test.ts backend/tests/morphologyIntegration.test.ts
git commit -m "feat(api): hide inactive dictionary mappings"
```

### Task 4: Expose POS and filter managed expression details

**Files:**
- Create: `backend/src/types/dictionaryRelease.ts`
- Create: `backend/src/services/dictionaryReleases.ts`
- Modify: `backend/src/types/expression.ts`
- Modify: `backend/src/services/expressions.ts`
- Test: `backend/tests/expressions.test.ts`
- Test: `backend/tests/expressionDetail.test.ts`
- Test: `backend/tests/expressionsIntegration.test.ts`

**Interfaces:**
- `listExpressionPartsOfSpeech(db, expressionId) -> Promise<PartOfSpeechDto[]>`.
- `PartOfSpeechDto = { code: string; name_en: string }`.
- `getExpression()` adds `parts_of_speech` while retaining existing fields.

- [ ] **Step 1: Add failing POS/detail tests**

Assert active release POS is returned once per code in registry order; duplicate claim attestations aggregate; inactive managed reading/attestation/POS is hidden; unmanaged reading/attestation remains visible. The integration test calls `GET /api/v2/expressions/:id` and verifies the public `parts_of_speech` contract plus rollback filtering.

- [ ] **Step 2: Run and verify failure**

Run: `cd backend && npx vitest run tests/expressions.test.ts tests/expressionDetail.test.ts tests/expressionsIntegration.test.ts`

Expected: FAIL because POS is absent and details are unfiltered.

- [ ] **Step 3: Implement POS reader**

Query `expression_pos_attestations` joined to `parts_of_speech`, filter by active release, group by code/name/sort order, and order `sort_order ASC, code ASC`.

- [ ] **Step 4: Filter readings and locale attestations**

Use `releaseObjectEligibilityPredicate('reading','r.id')` and `releaseObjectEligibilityPredicate('locale_attestation','a.id')` in detail queries. Fetch POS in the same `Promise.all` as readings/attestations.

- [ ] **Step 5: Run tests**

Run the two Task 4 test files; expect PASS.

- [ ] **Step 6: Commit Task 4**

```bash
git add backend/src/types/dictionaryRelease.ts backend/src/types/expression.ts backend/src/services/dictionaryReleases.ts backend/src/services/expressions.ts backend/tests/expressions.test.ts backend/tests/expressionDetail.test.ts backend/tests/expressionsIntegration.test.ts
git commit -m "feat(api): expose managed expression parts of speech"
```

### Task 5: Compile preview bindings into a release artifact

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/artifact.py`
- Create: `scripts/dictionary/langmap_dictionary/compiler.py`
- Create: `scripts/dictionary/langmap_dictionary/sql.py`
- Create: `scripts/dictionary/tests/test_release_artifact.py`
- Create: `scripts/dictionary/tests/test_compiler.py`

**Interfaces:**
- `D1Inventory(expressions_by_identity, bindings_by_claim, edges_by_pair, max_homograph_by_text, fingerprint)`.
- `compile_release(staging_db, release_id, inventory, output_dir) -> ReleaseArtifact`.
- Artifact paths: `manifest.json`, `quality-report.json`, `bindings.jsonl`, `sql/*.sql`, `rollback/manifest.json`.

- [ ] **Step 1: Write failing allocator tests**

Cover no existing text → index `1`; existing indexes `1,3` → new index `4`; parent binding reuse; two parent Expression IDs in one cluster → `published_identity_conflict`; inventory fingerprint change → `artifact_mismatch`; input reorder → identical output.

- [ ] **Step 2: Write failing SQL artifact tests**

Execute emitted SQL twice in an in-memory SQLite database using an equivalent schema. Assert expressions, release rows, bindings, edges, evidence, readings, locale attestations, POS, and release objects have unchanged counts on rerun.

- [ ] **Step 3: Run tests and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_compiler.py scripts/dictionary/tests/test_release_artifact.py -v
```

Expected: FAIL because compiler/artifact modules do not exist.

- [ ] **Step 4: Implement inventory-aware allocation**

Sort unbound clusters by `(lang_code, canonical_text, cluster_key)`. Reuse exactly one parent binding when available; otherwise allocate `max_existing + ordinal`. Generate IDs with the same base32 SHA-256 algorithm as `backend/src/services/expressionIdentity.ts` and assert Python test vectors match `hello → ftze3os7wcrq4jxihmvmlopcty`.

- [ ] **Step 5: Implement star-edge and membership SQL**

For each normalized sense, emit headword→equivalent and explicitly asserted headword→synonym pairs only; examples emit text→translation pairs. Antonym relations remain in the offline artifact and emit no edge. Sort endpoint IDs, reject self-pairs, reuse inventory edges, and emit one evidence row per claim. Emit release membership for every allocated/reused Expression, reading, locale attestation, edge and POS attestation so ownership audit and cleanup-candidate calculation are complete.

- [ ] **Step 6: Implement chunked artifact writer**

Each SQL chunk starts with foreign keys enabled, has a deterministic sequence and SHA-256, and stays below the configured statement count. The final chunk validates expected counts and sets release status `validated`; activation is not part of ordinary data chunks. Artifact verification excludes mutable promotion columns from its content identity, but asserts promotion is allowed only on `created` membership, and that an existing first actor/time is never overwritten by apply or rerun.

- [ ] **Step 7: Run Task 5 tests**

Run the two Task 5 test files; expect PASS.

- [ ] **Step 8: Commit Task 5**

```bash
git add scripts/dictionary/langmap_dictionary/artifact.py scripts/dictionary/langmap_dictionary/compiler.py scripts/dictionary/langmap_dictionary/sql.py scripts/dictionary/tests/test_compiler.py scripts/dictionary/tests/test_release_artifact.py
git commit -m "feat(dictionary): compile managed D1 release artifacts"
```

### Task 6: Apply, activate, verify, and roll back locally

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/publisher.py`
- Create: `scripts/db/lib/dictionary_release.py`
- Modify: `scripts/db/lib/fingerprint.py`
- Modify: `scripts/dictionary/manage.py`
- Create: `scripts/dictionary/tests/test_publisher.py`
- Create: `scripts/db/tests/test_dictionary_release.py`
- Modify: `scripts/db/tests/test_local_rebuild.py`
- Modify: `scripts/dictionary/tests/test_manage_cli.py`

**Interfaces:**
- `apply_release(paths, manifest_path, environment='local') -> ApplyResult`.
- `verify_release(...) -> VerifyResult`.
- `activate_release(...) -> ActivationResult`.
- `rollback_release(...) -> RollbackResult`.
- CLI adds `plan`, `apply`, `verify`, `activate`, `rollback`.

- [ ] **Step 1: Write failing executor and publisher tests with fake Wrangler**

Record commands and return JSON fixtures. Assert chunk order/checksum verification, atomic checkpoint resume, no activation after a failed chunk, one-transaction active pointer update, parent-only rollback, and cleanup candidate reporting without destructive cleanup. Assert `publisher.py` delegates all database mutations to `scripts/db/lib/dictionary_release.py` and never constructs a Wrangler command. Assert local status reports the active dictionary release separately while local rebuild remains lightweight and does not auto-apply corpus data.

- [ ] **Step 2: Run and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_publisher.py scripts/dictionary/tests/test_manage_cli.py -v
python3 -m unittest scripts.db.tests.test_dictionary_release scripts.db.tests.test_local_rebuild -v
```

Expected: FAIL because publisher commands do not exist.

- [ ] **Step 3: Implement the managed release executor and thin local publisher**

Put command construction, chunk execution, checkpoint and invariant queries in `scripts/db/lib/dictionary_release.py`. Use `subprocess.run` with argument arrays through the existing `scripts/db/lib/runner.py`; never `shell=True`. `publisher.py` validates CLI inputs and calls this shared executor. Store one atomically replaced checkpoint JSON under `scripts/db/state/dictionary/<release-id>/`. Recompute artifact hashes before every chunk. Compare the pre-apply inventory fingerprint only before the first mutation; on resume, verify the checkpoint, completed chunk hashes and expected intermediate counts instead of comparing the now-stale pre-apply fingerprint.

- [ ] **Step 4: Implement activation and rollback pointer updates**

Activation executes one D1 transaction after `verify_release` passes: update `dictionary_dataset_state.active_release_id` and set the release's first `activated_at` with `COALESCE`. Rollback verifies `parent_release_id`, then updates only the same pointer in one transaction and produces cleanup candidates. Release status stays `validated`; public visibility depends only on the pointer.

- [ ] **Step 5: Report local active release without bloating rebuild**

Extend local fingerprint/status output with an optional `active_dictionary_release_id` sidecar field. Keep it outside the bootstrap schema/data fingerprint so `local rebuild` does not expect or auto-load the corpus. Add the regression to `test_local_rebuild.py`.

- [ ] **Step 6: Run publisher tests**

Run Task 6 tests; expect PASS.

- [ ] **Step 7: Commit Task 6**

```bash
git add scripts/dictionary/langmap_dictionary/publisher.py scripts/dictionary/manage.py scripts/dictionary/tests/test_publisher.py scripts/dictionary/tests/test_manage_cli.py scripts/db/lib/dictionary_release.py scripts/db/lib/fingerprint.py scripts/db/tests/test_dictionary_release.py scripts/db/tests/test_local_rebuild.py
git commit -m "feat(dictionary): publish and roll back local releases"
```

### Task 7: Integrate approved artifacts into production planning

**Files:**
- Modify: `scripts/db/manage.py`
- Modify: `scripts/db/lib/production.py`
- Modify: `scripts/db/lib/paths.py`
- Modify: `scripts/db/tests/test_manage.py`
- Modify: `scripts/db/tests/test_production_inventory.py`

**Interfaces:**
- `production plan --dictionary-artifact-manifest RELATIVE_JSON`.
- `production apply --plan PLAN_JSON --confirm-production --confirm-release-id RELEASE_ID` stages chunks, verifies, then activates.
- `plan_production(..., dictionary_artifact_manifest=None)`.
- Artifacts live under ignored `scripts/db/state/artifacts/dictionary/<release-id>/`.

- [ ] **Step 1: Write failing CLI/plan tests**

Assert plan stores the repo-relative manifest path, manifest SHA-256, ordered chunk paths/checksums, release ID, expected counts, active parent and current Git commit. Reject absolute paths, `..` escape, missing chunks, manifest/chunk mismatch, and artifacts outside `scripts/db/state/artifacts/dictionary/`.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
python3 -m unittest scripts.db.tests.test_manage scripts.db.tests.test_production_inventory -v
```

Expected: FAIL because plan CLI cannot approve an artifact.

- [ ] **Step 3: Extend paths and production plan**

Add `dictionary_artifacts_dir`. Resolve the manifest and every declared chunk under repo root and the dictionary artifact directory, hash them, and copy immutable facts into the production plan. Keep plan read-only and `mutation_allowed=False`. Inventory is schema-aware: before migration `0034` exists, report `release_schema_present=false` and omit release-table queries; after migration, require the complete release inventory.

- [ ] **Step 4: Harden apply verification**

Before bookmark/mutation, re-hash manifest and every chunk, verify Git commit and pre-apply inventory fingerprint, then apply pending schema migrations. Delegate all dictionary chunks and checkpoint resume to `scripts/db/lib/dictionary_release.py`; do not execute a separate approved SQL file. After the executor reaches `validated`, run release count/invariant queries, then perform the one-transaction pointer activation and verify public eligibility. A mismatch aborts before activation and leaves the bookmark available for the existing restore flow.

- [ ] **Step 5: Extend inventory reporting without changing the production baseline**

Add counts for releases, active dataset pointer, bindings, edge evidence, release objects and POS attestations. Keep `scripts/db/production-baseline.json` unchanged in this plan: it may only be refreshed after Plan 4 has applied and verified an explicitly approved production release.

- [ ] **Step 6: Run database-management tests**

Run:

```bash
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py' -v
```

Expected: PASS.

- [ ] **Step 7: Commit Task 7**

```bash
git add scripts/db/manage.py scripts/db/lib/production.py scripts/db/lib/paths.py scripts/db/tests/test_manage.py scripts/db/tests/test_production_inventory.py
git commit -m "feat(db): approve managed dictionary artifacts"
```

### Task 8: End-to-end fixture release verification

**Files:**
- Create: `backend/tests/dictionaryReleaseIntegration.test.ts`
- Modify: `scripts/dictionary/README.md`

- [ ] **Step 1: Add the failing integration test**

Apply the Plan 1 `cod` fixture release to rebuilt local D1. Assert three `cod` Expression IDs, isolated neighbor sets, active POS/readings, inactive release invisibility, ordinary mapping visibility, repeat apply count stability, and parent rollback behavior.

- [ ] **Step 2: Start the local Worker and run the test**

Run `./dev.sh`, then:

```bash
cd backend
npx vitest run tests/dictionaryReleaseIntegration.test.ts --no-file-parallelism --testTimeout=20000
```

Expected before final fixes: FAIL at the first uncovered integration gap.

- [ ] **Step 3: Fix only integration gaps in files owned by Tasks 2–7**

Do not add new schema or broaden product behavior. Typical allowed fixes are missing eligibility predicates, manifest count queries, or response typing that contradicts already defined interfaces.

- [ ] **Step 4: Run full verification**

```bash
cd backend
npm test
cd ..
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py' -v
python3 -m pytest scripts/dictionary -v
./build.sh
git diff --check
```

Expected: all commands exit `0`.

- [ ] **Step 5: Update README**

Document fixture release `stage → preview → plan → apply → verify → activate → rollback`, artifact paths, JSON outputs, journal recovery, and the rule that full corpus is never part of default local rebuild.

- [ ] **Step 6: Commit Task 8**

```bash
git add backend/tests/dictionaryReleaseIntegration.test.ts scripts/dictionary/README.md
git commit -m "test(dictionary): verify managed release lifecycle"
```

## Plan 2 Acceptance

- Schema and migration lock are synchronized.
- One active pointer controls managed-object visibility.
- Every edge consumer uses the shared predicate; inactive managed edges cannot be voted or split.
- Expression detail returns stable aggregated POS and hides inactive managed details.
- Compiler reuses parent bindings and appends homograph indexes deterministically.
- SQL artifacts are idempotent and checksummed.
- Local and production workflows plan before mutate, bookmark before production apply, verify after apply, and can roll back.
- The `cod` fixture release passes API and lifecycle integration tests.
