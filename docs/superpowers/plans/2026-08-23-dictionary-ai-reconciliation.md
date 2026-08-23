# Dictionary AI Reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible AI reconciliation stage that automatically merges only high-confidence same-language/same-text lexical occurrences and leaves every unsafe or insufficiently evaluated candidate separate.

**Architecture:** Generate deterministic candidate pairs from staged occurrences, calculate closed-set blockers/features locally, and send eligible pairs through a JSONL subprocess provider twice with different stable input ordering. Accept only dual-pass merge decisions, construct complete-link clusters, evaluate the exact config against a held-out gold set, and make compiler use accepted decisions only when the precision gate passes.

**Tech Stack:** Python 3.12 standard library, sqlite3, JSONL subprocess protocol, dataclasses, hashlib, statistics/math, pytest.

## Global Constraints

- Requires Plan 1 staging schema and Plan 2 release binding/compiler contract.
- AI only compares occurrences with identical `lang_code` and canonical text.
- Different explicit homograph markers in the same dictionary are a hard blocker.
- A candidate touching two different published Expression IDs is a hard blocker.
- Free-form AI text never controls behavior; only validated enum/code fields do.
- Every auto merge requires two independent `merge` decisions with reordered evidence.
- Accepted connected components use complete-link consistency; transitive pair acceptance alone is insufficient.
- AI/provider failure means `abstain`; it never falls back to text-only merge.
- Auto merge is disabled unless the exact provider/model/prompt/feature/threshold hash passes the gold-set gate.
- Holdout auto-merge precision must be at least 99.5% and Wilson 95% lower bound at least 99.0%.
- Definitions, labels, examples and raw POS stay in offline requests/artifacts and never enter D1.
- Provider secrets come from its process environment, never CLI arguments, manifests, logs or JSONL payload metadata.
- Each task uses TDD and a focused Conventional Commit.

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/dictionary/langmap_dictionary/candidates.py` | Candidate generation, caps and deterministic blockers |
| `scripts/dictionary/langmap_dictionary/features.py` | Stable structured feature extraction |
| `scripts/dictionary/langmap_dictionary/decision_schema.py` | Request/response DTO validation |
| `scripts/dictionary/langmap_dictionary/provider.py` | JSONL subprocess execution |
| `scripts/dictionary/langmap_dictionary/reconciliation.py` | Dual-pass decisions and complete-link clusters |
| `scripts/dictionary/langmap_dictionary/evaluation.py` | Gold-set metrics and Wilson gate |
| `scripts/dictionary/config/reconciliation.json` | Non-secret feature/prompt/threshold configuration |
| `scripts/dictionary/gold/README.md` | Annotation contract and split rules |

### Task 1: Generate bounded deterministic candidate pairs

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/features.py`
- Create: `scripts/dictionary/langmap_dictionary/candidates.py`
- Create: `scripts/dictionary/tests/test_candidates.py`
- Create: `scripts/dictionary/tests/test_features.py`

**Interfaces:**
- `CandidateKey(left_claim_key, right_claim_key)` with lexically ordered keys.
- `CandidateFeatures` contains language/text, POS sets, definitions, labels, examples, equivalent-neighbor texts, marker facts, binding facts, and completeness codes.
- `generate_candidates(connection, release_id, max_group_size=50) -> CandidateSummary`.
- `deterministic_blockers(features) -> tuple[str, ...]`.

- [ ] **Step 1: Write failing feature tests**

```python
features = build_features(connection, release_id="r1", left="a", right="b")
assert features.language_code == "eng"
assert features.canonical_text == "cod"
assert features.left_pos == ("noun",)
assert features.right_definitions == ("an invented definition",)
```

Assert arrays are stable-sorted, raw evidence order is preserved in a separate field, duplicate strings are removed deterministically, and features contain no staging database paths.

- [ ] **Step 2: Write failing candidate/blocker tests**

Cover identical text/language pair generation; different text/language exclusion; same-dictionary marker `1` vs `2`; incompatible explicit POS; fallback identity ambiguity; two published bindings; missing semantic evidence; group size `51`; and candidate-key order stability.

- [ ] **Step 3: Run and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_features.py scripts/dictionary/tests/test_candidates.py -v
```

Expected: FAIL because feature/candidate modules do not exist.

- [ ] **Step 4: Implement structured features**

Read only normalized staging tables. Definitions, labels and examples remain strings; neighbor evidence is represented as `(language_code, canonical_text)` tuples. Compute `features_fingerprint` from canonical JSON excluding display summaries.

- [ ] **Step 5: Implement candidate generation and blockers**

Group on `(release_id, lang_code, canonical_text)`, sort claim keys, and emit every unordered pair only when group size is at most `max_group_size`. Groups over the cap receive `candidate_group_too_large` quarantine items. Return blocker codes from a frozen enum:

```python
BLOCKER_CODES = frozenset({
    "different_language", "different_text", "explicit_homograph_conflict",
    "pos_conflict", "fallback_identity_ambiguous", "published_identity_conflict",
    "insufficient_semantic_evidence", "candidate_group_too_large",
})
```

- [ ] **Step 6: Run Task 1 tests**

Run the two Task 1 test files; expect PASS.

- [ ] **Step 7: Commit Task 1**

```bash
git add scripts/dictionary/langmap_dictionary/features.py scripts/dictionary/langmap_dictionary/candidates.py scripts/dictionary/tests/test_features.py scripts/dictionary/tests/test_candidates.py
git commit -m "feat(dictionary): generate bounded merge candidates"
```

### Task 2: Define the AI JSONL provider contract

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/decision_schema.py`
- Create: `scripts/dictionary/langmap_dictionary/provider.py`
- Create: `scripts/dictionary/tests/fixtures/fake_ai_provider.py`
- Create: `scripts/dictionary/tests/test_decision_schema.py`
- Create: `scripts/dictionary/tests/test_provider.py`

**Interfaces:**
- `ReconciliationRequest(candidate_key, pass_id, evidence_order, features)`.
- `ReconciliationResponse(candidate_key, pass_id, decision, confidence, evidence_codes, conflict_codes, summary, provider_id, model_id)`.
- `run_provider(command, requests, output_dir, timeout_seconds) -> ProviderRun`.
- Provider command contract: `COMMAND --input REQUESTS.jsonl --output RESPONSES.jsonl --pass-id N`.

- [ ] **Step 1: Write failing schema tests**

Accept only decisions `merge`, `keep_separate`, `abstain`; confidence finite and within `[0,1]`; known evidence/conflict codes; exact candidate/pass match; no duplicate response; no unknown keys. Reject malformed JSON with line context.

- [ ] **Step 2: Write a deterministic fake provider**

The test executable reads requests and writes responses. It returns `merge` only when fixture feature `test_expected_decision == "merge"`, supports flags for malformed output, duplicate keys, timeout, missing response, and mismatched pass ID.

- [ ] **Step 3: Write failing provider tests**

Assert argument-array execution with `shell=False`, isolated input/output paths, timeout termination, non-zero exit handling, stdout/stderr truncation in errors, complete response coverage, environment pass-through without logging secret values, and byte-stable captured requests.

- [ ] **Step 4: Run and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_decision_schema.py scripts/dictionary/tests/test_provider.py -v
```

Expected: FAIL because schema/provider modules do not exist.

- [ ] **Step 5: Implement strict DTO validation**

Use dataclasses plus explicit `isinstance` checks; booleans are not accepted as numeric confidence. Sort code arrays before storage. Preserve `summary` but never expose a parser that turns summary text into codes.

- [ ] **Step 6: Implement subprocess provider**

Write canonical request JSONL, call `subprocess.run([...], shell=False, timeout=...)`, require output file creation, parse responses, and hash request/response files. Store provider/model IDs returned by every response and reject mixed IDs within one run.

- [ ] **Step 7: Run Task 2 tests**

Run the two Task 2 test files; expect PASS.

- [ ] **Step 8: Commit Task 2**

```bash
git add scripts/dictionary/langmap_dictionary/decision_schema.py scripts/dictionary/langmap_dictionary/provider.py scripts/dictionary/tests/fixtures/fake_ai_provider.py scripts/dictionary/tests/test_decision_schema.py scripts/dictionary/tests/test_provider.py
git commit -m "feat(dictionary): add AI reconciliation provider protocol"
```

### Task 3: Reconcile with dual passes and complete-link clustering

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/reconciliation.py`
- Create: `scripts/dictionary/tests/test_reconciliation.py`

**Interfaces:**
- `reconcile_release(connection, release_id, provider_command, config) -> ReconciliationSummary`.
- `AcceptedPair(candidate_key, confidence_min, decision_fingerprint)`.
- `build_complete_link_clusters(occurrence_keys, accepted_pairs) -> tuple[LexicalCluster, ...]`.

- [ ] **Step 1: Write failing dual-pass tests**

Cover merge/merge above threshold; merge/keep; merge/abstain; confidence below threshold; blocker present; missing provider response; provider failure; and different provider/model IDs. Only the first case may produce an accepted pair.

- [ ] **Step 2: Write failing complete-link tests**

For occurrences A/B/C: accepted A-B and B-C but rejected/missing A-C must not create `{A,B,C}`. Deterministic result is `{A,B}`＋`{C}` based on lexical key order. All three accepted yields one cluster. Explicit pre-clusters from one homograph entry remain indivisible.

- [ ] **Step 3: Run and verify failure**

Run: `python3 -m pytest scripts/dictionary/tests/test_reconciliation.py -v`

Expected: FAIL because reconciliation module does not exist.

- [ ] **Step 4: Implement pass ordering**

Pass 1 presents left then right evidence; pass 2 swaps them and reverses each stable evidence array. `pass_id` and `evidence_order` are explicit request fields. Both provider runs finish before any decision row is committed.

- [ ] **Step 5: Implement final decision rules**

Accept only two `merge` decisions, no conflicts, at least two distinct evidence codes across each response, and both confidence values `>= auto_merge_threshold`. Store both raw responses, config hash, features hash, final decision, and reason code in `reconciliation_decisions`.

- [ ] **Step 6: Implement complete-link clustering**

Sort occurrences and greedily add an occurrence to the earliest cluster only when every cross-pair is accepted; otherwise start a new cluster. Recompute cluster key from sorted occurrence keys and config hash. Assert no occurrence appears twice.

- [ ] **Step 7: Run reconciliation tests**

Run the Task 3 test; expect PASS.

- [ ] **Step 8: Commit Task 3**

```bash
git add scripts/dictionary/langmap_dictionary/reconciliation.py scripts/dictionary/tests/test_reconciliation.py
git commit -m "feat(dictionary): reconcile senses with dual AI passes"
```

### Task 4: Implement gold-set evaluation and auto-merge gate

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/evaluation.py`
- Create: `scripts/dictionary/tests/test_evaluation.py`
- Create: `scripts/dictionary/config/reconciliation.json`
- Create: `scripts/dictionary/gold/README.md`
- Create: `scripts/dictionary/gold/holdout-fixture.jsonl`

**Interfaces:**
- `evaluate_decisions(gold, decisions) -> EvaluationReport`.
- `wilson_interval(successes, total, z=1.959963984540054) -> (lower, upper)`.
- `auto_merge_enabled(report, config_hash, adapters) -> GateResult`.

- [ ] **Step 1: Write failing Wilson tests**

Use known boundary cases: `(0,0)` returns `(0,0)` with `insufficient_sample`; `(1000,1000)` lower bound is greater than `0.996`; `(995,1000)` point precision is `0.995` and lower bound is below `0.99`, so the gate fails.

- [ ] **Step 2: Write failing gate tests**

Assert at least 1,000 auto-path labels, point precision `>=0.995`, Wilson lower `>=0.99`, zero blocker violations, exact config hash, and at least 50 labeled auto-path candidates per enabled adapter. Adapters below 50 are disabled individually, not counted as globally enabled.

- [ ] **Step 3: Run and verify failure**

Run: `python3 -m pytest scripts/dictionary/tests/test_evaluation.py -v`

Expected: FAIL because evaluation module does not exist.

- [ ] **Step 4: Implement metrics**

Report TP/FP/TN/FN, precision, recall, Wilson interval, blocker violations, missing decisions, config mismatch, per-adapter metrics, and enabled adapter IDs. `auto_merge_enabled` returns false on any non-finite value or denominator mismatch.

- [ ] **Step 5: Add tracked configuration**

Use this non-secret structure:

```json
{
  "schema_version": 1,
  "auto_merge_threshold": 0.995,
  "max_candidate_group_size": 50,
  "provider_timeout_seconds": 1800,
  "minimum_holdout_auto_candidates": 1000,
  "minimum_adapter_auto_candidates": 50,
  "minimum_precision": 0.995,
  "minimum_wilson_lower": 0.99,
  "required_passes": 2
}
```

Provider/model/prompt identifiers are CLI/runtime inputs included in the computed config hash; no secret belongs in this file.

- [ ] **Step 6: Document gold JSONL contract**

Each row contains `candidate_key`, `label` (`merge` or `keep_separate`), `adapter_id`, `split` (`tuning` or `holdout`), `annotator_id`, and `annotation_version`. The same candidate cannot appear in both splits; loader rejects duplicates and unknown claims.

- [ ] **Step 7: Run evaluation tests**

Run the Task 4 test; expect PASS.

- [ ] **Step 8: Commit Task 4**

```bash
git add scripts/dictionary/langmap_dictionary/evaluation.py scripts/dictionary/tests/test_evaluation.py scripts/dictionary/config/reconciliation.json scripts/dictionary/gold/README.md scripts/dictionary/gold/holdout-fixture.jsonl
git commit -m "feat(dictionary): gate automatic merges on holdout precision"
```

### Task 5: Add annotation/export/evaluate CLI workflow

**Files:**
- Modify: `scripts/dictionary/manage.py`
- Create: `scripts/dictionary/langmap_dictionary/annotation.py`
- Create: `scripts/dictionary/tests/test_annotation.py`
- Modify: `scripts/dictionary/tests/test_manage_cli.py`
- Modify: `scripts/dictionary/README.md`

**Interfaces:**
- `candidates export --release ID --output FILE --limit N --seed HASH`.
- `gold import --input FILE --database PATH`.
- `reconcile --provider-command ... --provider-id ID --model-id ID`.
- `evaluate --gold FILE --release ID --output REPORT`.

- [ ] **Step 1: Write failing annotation sampling tests**

Assert stratification by adapter, merge likelihood, blocker family, language, POS conflict and completeness; stable seed produces byte-identical output; no tuning/holdout overlap; candidate text/evidence is sufficient for a reviewer without database queries.

- [ ] **Step 2: Write failing CLI tests**

Assert exact required options, JSON stdout, non-zero return on invalid label/duplicate/split leak, provider command accepted only after `--`, and no provider environment values printed.

- [ ] **Step 3: Run and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_annotation.py scripts/dictionary/tests/test_manage_cli.py -v
```

Expected: FAIL because annotation/reconciliation CLI commands are absent.

- [ ] **Step 4: Implement stable candidate export/import**

Use SHA-256 of `(seed, candidate_key)` as sampling order inside each stratum. Export canonical JSONL. Import validates every candidate key against the staging release and persists labels in dedicated gold tables, never in reconciliation decisions.

- [ ] **Step 5: Implement reconcile/evaluate CLI**

Split provider command after `--`, execute two passes, store decisions, evaluate the requested immutable gold file, and write a canonical report containing config hash and enabled adapters.

- [ ] **Step 6: Update README with exact workflow**

Document:

```bash
python3 scripts/dictionary/manage.py candidates export --database STAGING --release RELEASE --output candidates.jsonl --limit 1200 --seed langmap-holdout-v1
python3 scripts/dictionary/manage.py gold import --database STAGING --input reviewed-gold.jsonl
python3 scripts/dictionary/manage.py reconcile --database STAGING --release RELEASE --provider-id PROVIDER --model-id MODEL -- PROVIDER_COMMAND
python3 scripts/dictionary/manage.py evaluate --database STAGING --release RELEASE --gold reviewed-gold.jsonl --output evaluation.json
```

- [ ] **Step 7: Run Task 5 tests**

Run the two Task 5 test files; expect PASS.

- [ ] **Step 8: Commit Task 5**

```bash
git add scripts/dictionary/manage.py scripts/dictionary/langmap_dictionary/annotation.py scripts/dictionary/tests/test_annotation.py scripts/dictionary/tests/test_manage_cli.py scripts/dictionary/README.md
git commit -m "feat(dictionary): add reconciliation evaluation workflow"
```

### Task 6: Make compiler consume only gated decisions

**Files:**
- Modify: `scripts/dictionary/langmap_dictionary/compiler.py`
- Modify: `scripts/dictionary/langmap_dictionary/artifact.py`
- Modify: `scripts/dictionary/tests/test_compiler.py`
- Create: `scripts/dictionary/tests/test_reconciled_artifact.py`

**Interfaces:**
- `compile_release(..., evaluation_report_path: Path)` requires an exact passing config for AI bindings.
- `binding_kind='ai_merged'` only for accepted pairs/components under enabled adapters.

- [ ] **Step 1: Write failing compiler-gate tests**

Cover missing report, failing metrics, wrong config hash, adapter disabled, decision changed after evaluation, and passing report. First five keep occurrences separate or fail closed according to manifest mode; only passing report emits `ai_merged` bindings.

- [ ] **Step 2: Write failing `cod` cross-dictionary test**

Add synthetic claims from a second dictionary. A high-confidence fish claim may bind to `cod 1`; a joke claim to `cod 3`; a blocked bag-vs-fish pair stays separate. Existing `cod 1/2/3` bindings never change IDs.

- [ ] **Step 3: Run and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_compiler.py scripts/dictionary/tests/test_reconciled_artifact.py -v
```

Expected: FAIL because compiler ignores evaluation gate.

- [ ] **Step 4: Enforce decision/config fingerprints**

Compiler recomputes feature, decision and config hashes, checks the evaluation report's artifact hash, and verifies every AI-merged claim belongs to an enabled adapter. A mismatch is release-level `artifact_mismatch`.

- [ ] **Step 5: Emit reconciliation artifacts**

Include canonical `reconciliation-decisions.jsonl`, evaluation summary, provider/model identifiers, request/response checksums, enabled adapters, and AI merge counts in manifest. Do not copy raw evidence into D1 SQL.

- [ ] **Step 6: Run Plan 3 verification**

```bash
python3 -m pytest scripts/dictionary -v
python3 -m compileall -q scripts/dictionary
git diff --check
```

Expected: all commands exit `0`.

- [ ] **Step 7: Commit Task 6**

```bash
git add scripts/dictionary/langmap_dictionary/compiler.py scripts/dictionary/langmap_dictionary/artifact.py scripts/dictionary/tests/test_compiler.py scripts/dictionary/tests/test_reconciled_artifact.py
git commit -m "feat(dictionary): compile only evaluated AI merges"
```

## Plan 3 Acceptance

- Candidate pairs are same-language/same-text, bounded and deterministic.
- All deterministic blockers from the spec are enforced before provider calls.
- Provider I/O is strict JSONL, subprocess-safe, complete and checksummed.
- Auto merge requires two agreeing passes and at least two evidence classes.
- Cluster construction is complete-link and cannot merge via an unverified transitive chain.
- The exact reconciliation config passes the holdout thresholds before any adapter is auto-enabled.
- Compiler rejects stale/mismatched evaluation and records `ai_merged` only for enabled adapters.
- Cross-dictionary `cod` claims can join the correct existing homograph without changing published IDs.
