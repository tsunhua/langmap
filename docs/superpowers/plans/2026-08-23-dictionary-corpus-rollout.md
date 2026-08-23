# Dictionary Full-Corpus Adapters and Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cover every dictionary present when the export set is frozen, pass parser and AI quality gates, compile one deterministic full-corpus release, and activate it through the guarded LangMap release workflow.

**Architecture:** Discover dictionaries from completed Structured JSONL v2 headers and identify them by `CFBundleIdentifier`, never by a hard-coded count or mutable display name. The dictionary repository profiles each DOM family and exports loss-preserving records through shared engines plus explicit profiles. LangMap maps those records to closed-set language, reading and POS codes, stages all claims, runs the approved AI reconciliation config, and publishes only after corpus conservation and release invariants pass.

**Tech Stack:** Python 3.12, lxml 5–6, sqlite3, JSONL, pytest 8, Cloudflare D1/Wrangler 4, existing LangMap `scripts/db` release tooling.

## Global Constraints

- Requires Plans 1–3 and the design in `../specs/2026-08-23-dictionary-structured-jsonl-import-design.md`.
- The input directory may still be receiving files. A manifest can be frozen only after two scans have identical names, sizes, mtimes, checksums and header counts, and no output has a temporary suffix.
- The current v1 JSONL can inventory names/counts only. It cannot approve adapters because it omits raw DOM, immutable input checksum and reliable direction evidence; the release corpus must be regenerated as v2 before profiling.
- `CFBundleIdentifier` is the dictionary identity. File stems are presentation data only.
- Never hard-code a corpus count. The frozen manifest records the exact count and rejects later additions, removals or changed checksums until a new release is planned.
- A section-boundary direction fallback is valid only with exact input SHA-256, entry count, boundary ordinal and both neighboring anchor keys.
- Unknown direction, DOM signature, language profile, reading scheme, POS or atomization is quarantined; rollout never guesses it.
- One representative fixture per frozen dictionary and one fixture per observed layout signature are required.
- Definitions, labels and forms remain offline. Examples publish only as ordinary expression mappings. Raw POS remains offline; only mapped closed-set POS codes publish.
- The full run streams records and uses bounded batches. No step loads the corpus or all AI candidates into memory.
- Generated v2 JSONL, profile reports, staging databases, gold splits and release artifacts remain ignored operational state. Only code, declarative profiles, synthetic fixtures and documentation are committed.
- Each task uses TDD, preserves unrelated changes, runs `git diff --check`, and commits only its listed files.

---

## Adapter Families

The initially profiled dictionaries use these explicit families. The frozen manifest may contain more dictionaries added by the running export job; Task 1 must classify them by structural signature, and Task 3 adds a profile only after its fixture and coverage gate pass.

| Family | Dictionary profiles already identified |
|---|---|
| `semb-bilingual` | Arabic–English, Cantonese–English Colloquialisms, French–English, Korean–English, Simplified Chinese–English, Spanish–English, Thai–English, Vietnamese–English |
| `lingea-bilingual` | Croatian–English, Danish–English, Ukrainian–English after raw DOM verification |
| `generic-semb-bilingual` | Dutch–English, Gujarati–English, Indonesian–English, Kazakh–English, Malay–English, Norwegian–English, Turkish–English after raw DOM verification |
| `oup-indic-hybrid` | Bangla–English, Kannada–English, Malayalam–English, Punjabi–English, Tamil–English, Telugu–English; combines ODE-like and bilingual layouts |
| `cantonese-oxford` | Cantonese–English Oxford |
| `sanseido-wisdom` | WISDOM English–Japanese／Japanese–English |
| `sanseido-crown-zh-ja` | Simplified Chinese–Japanese |
| `traditional-chinese-english-idioms` | Traditional Chinese–English Idioms |
| `dr-eye-zh-hant-en` | Traditional Chinese–English, including the three `cod` homographs |
| `msdict-monolingual` | Oxford Dictionary of English, Spanish, Simplified Chinese Idioms, Standard Contemporary Chinese, Traditional Chinese Common Words |
| `sanseido-daijirin` | Sanseido Super Daijirin |
| `wunan-zh-hant` | Traditional Chinese |
| `oxford-thesaurus` | Oxford Thesaurus of English and Oxford American Writer's Thesaurus only after signature verification |
| `simplified-chinese-thesaurus` | Simplified Chinese Thesaurus |
| `oup-bilingual` | Additional OUP bilingual dictionaries discovered by Task 1; each language pair has its own direction and language-code profile |

`semb-bilingual` and `oup-bilingual` may reuse selector helpers, but they remain separate registered families until full profiling proves identical sense, example and direction semantics.

## File Structure

Dictionary repository (`/Users/lim/Documents/Code/tsunhua/dictionary`):

| File | Responsibility |
|---|---|
| `src/dictionary_export/corpus.py` | Stable corpus scan, manifest freeze and drift checks |
| `src/dictionary_export/macos_corpus.py` | Stream one installed dictionary through a temporary raw CSV into v2 output |
| `src/dictionary_export/dom_profile.py` | Per-entry structural signatures and coverage summaries |
| `src/dictionary_export/profile_cli.py` | `profile` and `freeze-manifest` entry points |
| `src/dictionary_export/jsonl_parsers/common.py` | DOM traversal, exclusions, homograph and example helpers |
| `src/dictionary_export/jsonl_parsers/semb_bilingual.py` | Shared `.gramb > .semb` engine |
| `src/dictionary_export/jsonl_parsers/oup_bilingual.py` | OUP bilingual engine with declarative direction profiles |
| `src/dictionary_export/jsonl_parsers/msdict_monolingual.py` | Shared `.sg > .se1` monolingual engine |
| `src/dictionary_export/jsonl_parsers/thesaurus.py` | Synonym/antonym relationship extraction |
| `src/dictionary_export/jsonl_parsers/specialized.py` | Registry composition for dedicated parser modules |
| `src/dictionary_export/dictionary_profiles.json` | Bundle-ID keyed adapter, direction and selector profiles |

LangMap repository (`/Users/lim/Documents/Code/tsunhua/langmap`):

| File | Responsibility |
|---|---|
| `scripts/dictionary/config/dictionaries.json` | Bundle-ID to LangMap language/profile/reading/POS projection |
| `scripts/dictionary/langmap_dictionary/corpus.py` | Frozen-manifest validation and all-dictionary orchestration |
| `scripts/dictionary/langmap_dictionary/quality.py` | Conservation, coverage, quarantine and drift gates |
| `scripts/dictionary/langmap_dictionary/report.py` | Deterministic machine-readable and Markdown summaries |
| `scripts/dictionary/tests/fixtures/corpus/` | Synthetic one-profile and failure fixtures |
| `scripts/dictionary/README.md` | Complete stage/reconcile/compile/publish runbook |

### Task 1: Freeze a complete, quiescent corpus manifest

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/corpus.py`
- Create: `src/dictionary_export/macos_corpus.py`
- Create: `src/dictionary_export/dom_profile.py`
- Create: `src/dictionary_export/profile_cli.py`
- Modify: `pyproject.toml`
- Create: `tests/test_corpus.py`
- Create: `tests/test_macos_corpus.py`
- Create: `tests/test_dom_profile.py`
- Create: `tests/test_profile_cli.py`

**Interfaces:**
- `scan_corpus(path: Path) -> CorpusSnapshot`.
- `freeze_manifest(first: CorpusSnapshot, second: CorpusSnapshot) -> CorpusManifest`.
- `profile_entry(record: EntryRecordV2) -> DomProfileRow`.
- CLI: `dictionary-profile scan INPUT_DIR --output REPORT_DIR` and `dictionary-profile freeze INPUT_DIR --output MANIFEST`.
- `export_macos_corpus(bundle_inventory, output_dir, raw_export_command) -> ExportSummary`.

- [ ] **Step 1: Write failing quiescence and identity tests**

```python
def test_freeze_rejects_a_directory_that_changed_between_scans(tmp_path):
    first = snapshot(files=(file_fact("a.jsonl", sha="1" * 64, entries=2),))
    second = snapshot(files=(file_fact("a.jsonl", sha="2" * 64, entries=2),))
    with pytest.raises(CorpusChangedError, match="a.jsonl"):
        freeze_manifest(first, second)

def test_manifest_identity_uses_bundle_identifier():
    item = manifest_item(header(bundle_identifier="com.example.lexicon", name="Renamed"))
    assert item.dictionary_key == "com.example.lexicon"
```

Also reject duplicate bundle identifiers, missing v2 headers, header/body count mismatches, `.tmp`／`.partial` siblings, non-regular files, and a filename set that changes between scans.

- [ ] **Step 2: Run tests and verify failure**

Run: `uv run pytest tests/test_corpus.py tests/test_macos_corpus.py tests/test_dom_profile.py tests/test_profile_cli.py -v`

Expected: FAIL because the modules and CLI do not exist.

- [ ] **Step 3: Add a failing one-bundle-at-a-time export test**

The test uses a fake bundle inventory and raw-export command. Assert only one temporary CSV exists at a time, the v2 header records its SHA-256 and entry count, a failed bundle leaves no final JSONL, successful outputs use atomic rename, and temporary CSV files are removed on success and failure.

- [ ] **Step 4: Implement macOS corpus export orchestration**

Reuse `bin/export-macos-dictionary.sh list` and `raw` through argument-array subprocess calls. Do not import or convert the already generated v1 JSONL: it lacks the raw DOM and immutable input facts required by the v2 gate. Accept explicit input/output paths, isolate temporary files with `TemporaryDirectory`, and resume only when an existing v2 output header and checksum match the current bundle input.

- [ ] **Step 5: Implement streaming scan and two-snapshot freeze**

Use immutable facts only:

```python
@dataclass(frozen=True, slots=True)
class CorpusFileFact:
    file_name: str
    dictionary_key: str
    input_sha256: str
    output_sha256: str
    entry_count: int
    schema_version: int

@dataclass(frozen=True, slots=True)
class CorpusManifest:
    manifest_version: Literal[1]
    files: tuple[CorpusFileFact, ...]
    corpus_hash: str
```

Sort by `dictionary_key`; compute `corpus_hash` from canonical JSON. The CLI performs the two scans around a full header/body validation pass rather than using a sleep interval.

- [ ] **Step 6: Implement structural profiling**

Emit one JSONL row per entry with dictionary key, ordinal, stable entry key, direction evidence, layout family, homograph marker kind, sense/definition/equivalent/example/POS counts and unknown signature codes. Emit a summary JSON with layout distribution, unclassified/conflicting direction counts, selector hit rates, empty-field counts and representative stable keys for every unknown signature.

- [ ] **Step 7: Add CLI and run tests**

Expose `dictionary-profile` in `pyproject.toml`. Run the Task 1 tests; expect PASS.

- [ ] **Step 8: Commit Task 1**

```bash
git add src/dictionary_export/corpus.py src/dictionary_export/macos_corpus.py src/dictionary_export/dom_profile.py src/dictionary_export/profile_cli.py pyproject.toml tests/test_corpus.py tests/test_macos_corpus.py tests/test_dom_profile.py tests/test_profile_cli.py
git commit -m "feat(export): profile and freeze dictionary corpus"
```

### Task 2: Add shared DOM helpers and the `semb-bilingual` family

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/jsonl_parsers/common.py`
- Create: `src/dictionary_export/jsonl_parsers/semb_bilingual.py`
- Modify: `src/dictionary_export/jsonl_registry.py`
- Create: `tests/test_jsonl_parser_common.py`
- Create: `tests/test_semb_bilingual.py`
- Create: `tests/fixtures/jsonl/semb_bilingual.py`

**Interfaces:**
- `homograph_marker(root) -> HomographMarker | None`.
- `nearest_grammar_group(node) -> HtmlElement`.
- `extract_example_pairs(node, profile) -> tuple[ExampleV2, ...]`.
- `SembBilingualParser(profile: SembProfile)`.

- [ ] **Step 1: Write failing common-helper tests**

Cover marker priority `.hw@homograph`, `.hw@hm`, adjacent `.hm`; removal of display marker from canonical headword; nearest `.gramb` POS binding; exclusion of translations under examples; and preservation of example text/translation pairing.

- [ ] **Step 2: Write failing family tests**

Use synthetic fixtures for Arabic, Cantonese Colloquialisms, French, Korean, Simplified Chinese–English, Spanish–English, Thai and Vietnamese. Assert direction evidence and profiles, `.trans.ty_pinyin` exclusion from equivalents, target reading retention, and exclusion of `.gr`, `.cnt`, `.fld`, `.reg` and `.lev` from equivalent text.

- [ ] **Step 3: Run tests and verify failure**

Run: `uv run pytest tests/test_jsonl_parser_common.py tests/test_semb_bilingual.py -v`

Expected: FAIL because the shared family does not exist.

- [ ] **Step 4: Implement the profile-driven engine**

```python
@dataclass(frozen=True, slots=True)
class DirectionRule:
    source_profile: str
    target_profile: str
    id_prefixes: tuple[str, ...] = ()
    section_fallback: SectionFallback | None = None

@dataclass(frozen=True, slots=True)
class SembProfile:
    dictionary_key: str
    directions: tuple[DirectionRule, ...]
    equivalent_xpath: str
    excluded_classes: tuple[str, ...]
```

Implement explicit prefix rules for signals verified by profiling. For section fallbacks, require input checksum, entry count, boundary and both anchor entry keys before accepting a direction.

- [ ] **Step 5: Register the family and run tests**

Registration is exact bundle ID to profile; do not auto-select from a display name. Run the Task 2 tests; expect PASS.

- [ ] **Step 6: Commit Task 2**

```bash
git add src/dictionary_export/jsonl_parsers/common.py src/dictionary_export/jsonl_parsers/semb_bilingual.py src/dictionary_export/jsonl_registry.py tests/test_jsonl_parser_common.py tests/test_semb_bilingual.py tests/fixtures/jsonl/semb_bilingual.py
git commit -m "feat(export): parse semb bilingual dictionaries"
```

### Task 3: Cover newly discovered bilingual and Indic hybrid dictionaries

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/jsonl_parsers/oup_bilingual.py`
- Create: `src/dictionary_export/jsonl_parsers/oup_indic_hybrid.py`
- Create: `src/dictionary_export/dictionary_profiles.json`
- Modify: `src/dictionary_export/jsonl_registry.py`
- Create: `tests/test_dictionary_profiles.py`
- Create: `tests/test_oup_bilingual.py`
- Create: `tests/test_oup_indic_hybrid.py`
- Create: `tests/fixtures/jsonl/oup_bilingual.py`
- Create: `tests/fixtures/jsonl/oup_indic_hybrid.py`

**Interfaces:**
- `load_dictionary_profiles() -> Mapping[str, DictionaryProfile]`.
- `validate_profile_coverage(manifest, profiles) -> CoverageResult`.
- `OupBilingualParser(profile: OupBilingualProfile)`.
- `OupIndicHybridParser(profile: OupIndicProfile)`.

- [ ] **Step 1: Generate the profile candidate list from the frozen manifest**

Run the Task 1 profiler against the completed v2 directory. For every bundle ID not covered by Task 2 or a later dedicated family, capture representative entries for each structural signature as synthetic, minimized fixtures. Do not copy corpus records into Git.

- [ ] **Step 2: Write failing declarative-profile tests**

```python
def test_every_frozen_bundle_has_exactly_one_profile(manifest, profiles):
    result = validate_profile_coverage(manifest, profiles)
    assert result.missing == ()
    assert result.ambiguous == ()
```

For every additional bilingual profile, assert exact BCP 47 source/target profiles, direction evidence, headword cleanup, one sense minimum when semantic nodes exist, example pairing and unknown-signature quarantine. Add hybrid fixtures for Bangla, Kannada, Malayalam, Punjabi, Tamil and Telugu that contain both ODE-like `.msDict/.df` and native bilingual `.semb/.trans` layouts. Kannada and Tamil require explicit selector branches; their current v1 output is not admissible as a coverage oracle.

- [ ] **Step 3: Run tests and verify failure**

Run: `uv run pytest tests/test_dictionary_profiles.py tests/test_oup_bilingual.py tests/test_oup_indic_hybrid.py -v`

Expected: FAIL with the exact uncovered bundle IDs.

- [ ] **Step 4: Implement the bilingual families, Indic hybrid engine, and declarative profiles**

The JSON entry for each bundle ID has this closed shape:

```json
{
  "adapter": "oup-bilingual",
  "profile_version": 1,
  "source_profiles": ["eng"],
  "target_profiles": ["deu"],
  "direction": {"detector": "entry-id-prefix", "rules": []},
  "allowed_layouts": ["gramb-semb"],
  "excluded_subtrees": ["eg", "hidden-subentry"]
}
```

Values must come from profiling, not from the example above. The loader rejects unknown keys, missing language profiles, unrecognized detector kinds and section fallbacks without immutable anchors. The Indic engine treats `.msDict/.df` as definitions, `.semb/.trans` as bilingual equivalents, and keeps both under distinct sense records; it never promotes an English definition to an equivalent.

- [ ] **Step 5: Run profile coverage tests**

Run Task 3 tests. Expected: PASS for every frozen additional bilingual/Indic dictionary; genuinely unsupported layouts remain assigned to a named dedicated family implemented in Task 4 or 5, not silently accepted here.

- [ ] **Step 6: Commit Task 3**

```bash
git add src/dictionary_export/jsonl_parsers/oup_bilingual.py src/dictionary_export/jsonl_parsers/oup_indic_hybrid.py src/dictionary_export/dictionary_profiles.json src/dictionary_export/jsonl_registry.py tests/test_dictionary_profiles.py tests/test_oup_bilingual.py tests/test_oup_indic_hybrid.py tests/fixtures/jsonl/oup_bilingual.py tests/fixtures/jsonl/oup_indic_hybrid.py
git commit -m "feat(export): cover newly profiled bilingual dictionaries"
```

### Task 4: Implement dedicated bilingual and Japanese adapters

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/jsonl_parsers/cantonese_oxford.py`
- Create: `src/dictionary_export/jsonl_parsers/sanseido_wisdom.py`
- Create: `src/dictionary_export/jsonl_parsers/sanseido_crown_zh_ja.py`
- Create: `src/dictionary_export/jsonl_parsers/traditional_chinese_english_idioms.py`
- Modify: `src/dictionary_export/jsonl_parsers/traditional_chinese_english.py`
- Create: `tests/test_cantonese_oxford_jsonl.py`
- Create: `tests/test_sanseido_wisdom_jsonl.py`
- Create: `tests/test_sanseido_crown_jsonl.py`
- Create: `tests/test_traditional_chinese_english_idioms_jsonl.py`
- Modify: `tests/test_traditional_chinese_english_jsonl.py`

- [ ] **Step 1: Add failing Cantonese Oxford tests**

Cover its English-side `.sg > .se1 > .msDict` layout and Cantonese-side `.gramb > .semb` layout. Assert `b-en-en-yue` and `b-yue-en` direction evidence, side-specific POS nodes, and exclusion of example translations from core equivalents.

- [ ] **Step 2: Add failing WISDOM and Crown tests**

Assert `WDEJ`／`WDJE` directions, `.hw@normalized`, adjacent homographs, Japanese reading versus written form, `zh-cmn-Hans`／`d:prn=1` Crown directions, Chinese pinyin and optional English blocks.

- [ ] **Step 3: Add failing Traditional Chinese bilingual tests**

For the idioms profile, keep `.trans.ty_idm` as the equivalent and other translation text offline. For Dr Eye, cover `.sg > .se1 > .se2 > .msDict`, section anchors, `.hw@homograph`, and `cod 1/2/3` producing canonical `cod` with markers `1`, `2`, `3`.

- [ ] **Step 4: Run dedicated tests and verify failure**

Run:

```bash
uv run pytest tests/test_cantonese_oxford_jsonl.py tests/test_sanseido_wisdom_jsonl.py tests/test_sanseido_crown_jsonl.py tests/test_traditional_chinese_english_idioms_jsonl.py tests/test_traditional_chinese_english_jsonl.py -v
```

- [ ] **Step 5: Implement and register the adapters**

Share only proven DOM helper functions. Each adapter owns its direction, selector ordering, reading roles and excluded subtrees. Update the bundle-ID profile registry and rerun the five test files; expect PASS.

- [ ] **Step 6: Commit Task 4**

```bash
git add src/dictionary_export/jsonl_parsers/cantonese_oxford.py src/dictionary_export/jsonl_parsers/sanseido_wisdom.py src/dictionary_export/jsonl_parsers/sanseido_crown_zh_ja.py src/dictionary_export/jsonl_parsers/traditional_chinese_english_idioms.py src/dictionary_export/jsonl_parsers/traditional_chinese_english.py tests/test_cantonese_oxford_jsonl.py tests/test_sanseido_wisdom_jsonl.py tests/test_sanseido_crown_jsonl.py tests/test_traditional_chinese_english_idioms_jsonl.py tests/test_traditional_chinese_english_jsonl.py src/dictionary_export/dictionary_profiles.json
git commit -m "feat(export): parse specialized bilingual dictionaries"
```

### Task 5: Implement monolingual, Daijirin, Wunan, and thesaurus families

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/jsonl_parsers/msdict_monolingual.py`
- Create: `src/dictionary_export/jsonl_parsers/sanseido_daijirin.py`
- Create: `src/dictionary_export/jsonl_parsers/wunan_zh_hant.py`
- Create: `src/dictionary_export/jsonl_parsers/thesaurus.py`
- Modify: `src/dictionary_export/jsonl_registry.py`
- Create: `tests/test_msdict_monolingual.py`
- Create: `tests/test_sanseido_daijirin_jsonl.py`
- Create: `tests/test_wunan_zh_hant_jsonl.py`
- Create: `tests/test_thesaurus_jsonl.py`

- [ ] **Step 1: Write failing `msdict-monolingual` tests**

Cover core `.se1 > .msDict`, nested `.se2 > .msDict`, multiple same-level senses, `.df`, `.pos`, `.eg .ex`, homograph attributes and exclusion of hidden subentries. Use a profile fixture for every frozen dictionary assigned to this family.

- [ ] **Step 2: Write failing Daijirin and Wunan tests**

Assert Daijirin reading headword, `.fg .f` written forms, accent reading, multiple same-level `.msDict` senses and limited POS. Assert Wunan ruby base text, Bopomofo/pinyin roles, `.se2` definitions, `.general-text.en_ex` examples and hidden compound exclusion.

- [ ] **Step 3: Write failing thesaurus tests**

Assert Oxford core and phrase senses, synonym/antonym relationship kinds, Simplified Chinese related-term readings, and examples. Synonyms and antonyms must not enter definitions or bilingual equivalents. A writer-thesaurus dictionary can reuse the Oxford profile only if its frozen layout signatures are a subset of the tested allowed signatures.

- [ ] **Step 4: Run tests and verify failure**

Run:

```bash
uv run pytest tests/test_msdict_monolingual.py tests/test_sanseido_daijirin_jsonl.py tests/test_wunan_zh_hant_jsonl.py tests/test_thesaurus_jsonl.py -v
```

- [ ] **Step 5: Implement, register, and rerun**

Preserve definition, label and form payloads in v2 records even though LangMap will not publish them. Emit explicit relation kinds: the LangMap projection publishes only the direct headword→synonym claim as an ordinary mapping, keeps antonyms offline, and never builds a clique among sibling synonyms. Run Task 5 tests; expect PASS.

- [ ] **Step 6: Commit Task 5**

```bash
git add src/dictionary_export/jsonl_parsers/msdict_monolingual.py src/dictionary_export/jsonl_parsers/sanseido_daijirin.py src/dictionary_export/jsonl_parsers/wunan_zh_hant.py src/dictionary_export/jsonl_parsers/thesaurus.py src/dictionary_export/jsonl_registry.py src/dictionary_export/dictionary_profiles.json tests/test_msdict_monolingual.py tests/test_sanseido_daijirin_jsonl.py tests/test_wunan_zh_hant_jsonl.py tests/test_thesaurus_jsonl.py
git commit -m "feat(export): parse monolingual and thesaurus dictionaries"
```

### Task 6: Complete LangMap projection profiles and corpus quality gates

**Repository:** `/Users/lim/Documents/Code/tsunhua/langmap`

**Files:**
- Create: `scripts/dictionary/config/dictionaries.json`
- Create: `scripts/dictionary/langmap_dictionary/corpus.py`
- Create: `scripts/dictionary/langmap_dictionary/quality.py`
- Create: `scripts/dictionary/langmap_dictionary/report.py`
- Modify: `scripts/dictionary/manage.py`
- Create: `scripts/dictionary/tests/test_corpus.py`
- Create: `scripts/dictionary/tests/test_quality.py`
- Create: `scripts/dictionary/tests/test_report.py`
- Modify: `scripts/dictionary/tests/test_manage_cli.py`

**Interfaces:**
- `validate_projection_profiles(manifest, profiles) -> ProjectionCoverage`.
- `run_corpus_stage(manifest_path, staging_path, batch_size=1000) -> StageSummary`.
- `evaluate_quality(connection, release_id, manifest) -> QualityGateResult`.
- CLI adds `corpus stage`, `corpus validate`, and `corpus report`.

- [ ] **Step 1: Write failing projection-profile tests**

Require exactly one LangMap profile per frozen bundle ID. Validate language profile codes against the D1 inventory, reading schemes against their allowed language profile, POS mappings against the seeded closed set, and example source/translation roles. Reject unused profile entries as well as missing ones.

- [ ] **Step 2: Write failing conservation and quality tests**

```python
assert gate.input_entries == gate.staged_entries + gate.export_quarantine_entries
assert gate.staged_claims == gate.publishable_claims + gate.staging_quarantine_claims
assert gate.publishable_occurrences == gate.bound_occurrences
assert gate.unknown_dictionary_profiles == 0
assert gate.unknown_dom_signatures == 0
assert gate.direction_conflicts == 0
```

Also test duplicate stable keys, output order drift, missing examples, all-empty semantic records, per-dictionary quarantine rates, POS mapping coverage and report sorting. Quarantine is an accepted terminal state only when it has a non-empty closed-set error code and preserved raw record.

- [ ] **Step 3: Run tests and verify failure**

Run: `python3 -m pytest scripts/dictionary/tests/test_corpus.py scripts/dictionary/tests/test_quality.py scripts/dictionary/tests/test_report.py scripts/dictionary/tests/test_manage_cli.py -v`

- [ ] **Step 4: Implement projection profiles and streaming orchestration**

Use bundle-ID keyed JSON entries with source/target `language_profile_code`, allowed reading mappings, POS map, punctuation/atomization policy and expected adapter ID. `run_corpus_stage` verifies v2 output checksums against the frozen manifest before loading each file and checkpoints only after the file transaction commits.

- [ ] **Step 5: Implement deterministic reports and CLI**

Write canonical JSON plus a Markdown summary under the requested ignored report directory. Summaries include per dictionary/language counts, terminal-state conservation, parser diagnostics, POS/readings/examples, AI decision counts and release object estimates; they contain no raw definition or example text.

- [ ] **Step 6: Run tests and commit Task 6**

```bash
python3 -m pytest scripts/dictionary/tests/test_corpus.py scripts/dictionary/tests/test_quality.py scripts/dictionary/tests/test_report.py scripts/dictionary/tests/test_manage_cli.py -v
git add scripts/dictionary/config/dictionaries.json scripts/dictionary/langmap_dictionary/corpus.py scripts/dictionary/langmap_dictionary/quality.py scripts/dictionary/langmap_dictionary/report.py scripts/dictionary/manage.py scripts/dictionary/tests/test_corpus.py scripts/dictionary/tests/test_quality.py scripts/dictionary/tests/test_report.py scripts/dictionary/tests/test_manage_cli.py
git commit -m "feat(dictionary): validate full corpus projection"
```

### Task 7: Build and approve the corpus reconciliation gold gate

**Repository:** `/Users/lim/Documents/Code/tsunhua/langmap`

**Files:**
- Modify: `scripts/dictionary/gold/README.md`
- Create: `scripts/dictionary/gold/manifest.json`
- Create: `scripts/dictionary/tests/test_gold_coverage.py`
- Modify: `scripts/dictionary/config/reconciliation.json`

- [ ] **Step 1: Generate deterministic annotation candidates**

Run `manage.py reconcile annotate` on the frozen staging database with the exact production candidate generator. Stratify by dictionary family, language, POS compatibility, explicit marker, published binding state and semantic-evidence completeness. Keep holdout claim keys isolated from calibration keys.

- [ ] **Step 2: Label and adjudicate the required set**

Two reviewers independently label at least 1,000 candidates that are eligible to enter the auto-merge path, with at least 50 per enabled adapter family; disagreements receive a recorded adjudicated label. Keep the labeled rows in ignored operational state and commit only the hash/count/split manifest.

- [ ] **Step 3: Write and run failing coverage tests**

```python
assert gold.auto_path_labels >= 1000
assert min(gold.labels_by_enabled_family.values()) >= 50
assert gold.calibration_keys.isdisjoint(gold.holdout_keys)
assert gold.payload_sha256 == recompute_payload_sha256(gold_path)
```

Run: `python3 -m pytest scripts/dictionary/tests/test_gold_coverage.py -v`

- [ ] **Step 4: Evaluate the exact config and freeze its hash**

Run both AI passes using the provider/model/prompt/feature/threshold configuration intended for the release. Accept the config only when holdout auto-merge precision is at least 99.5%, Wilson 95% lower bound is at least 99.0%, every deterministic blocker has zero violations, and all decisions have two valid passes. Write the accepted evaluation hash into `gold/manifest.json` and `reconciliation.json`.

- [ ] **Step 5: Rerun tests and commit Task 7**

```bash
python3 -m pytest scripts/dictionary/tests/test_gold_coverage.py scripts/dictionary/tests/test_evaluation.py -v
git add scripts/dictionary/gold/README.md scripts/dictionary/gold/manifest.json scripts/dictionary/tests/test_gold_coverage.py scripts/dictionary/config/reconciliation.json
git commit -m "test(dictionary): approve corpus reconciliation gate"
```

### Task 8: Run a full local release rehearsal

**Repositories:** both repositories; generated outputs remain untracked.

**Files:**
- Modify: `scripts/dictionary/README.md`
- Create: `scripts/dictionary/tests/test_full_release_contract.py`

- [ ] **Step 1: Re-export v2 and freeze the manifest**

Wait for the upstream export job to finish. Run v2 export to a new directory, then `dictionary-profile scan` and `dictionary-profile freeze`. Confirm the manifest covers every final input bundle and that a second scan is identical.

- [ ] **Step 2: Run exporter coverage**

Fail the rehearsal if any bundle lacks exactly one adapter/profile, any known semantic DOM signature is unparsed, any direction is conflicting, or any section fallback fails checksum/count/anchor validation. Record legitimate per-entry quarantine by closed error code.

- [ ] **Step 3: Stage, reconcile, compile and preflight**

Run the LangMap CLI in order:

```bash
python3 scripts/dictionary/manage.py corpus stage --manifest scripts/db/state/dictionary/full-corpus/manifest.json --database scripts/db/state/dictionary/full-corpus/staging.sqlite3
python3 scripts/dictionary/manage.py reconcile run --database scripts/db/state/dictionary/full-corpus/staging.sqlite3 --config scripts/dictionary/config/reconciliation.json
python3 scripts/dictionary/manage.py corpus validate --manifest scripts/db/state/dictionary/full-corpus/manifest.json --database scripts/db/state/dictionary/full-corpus/staging.sqlite3
python3 scripts/dictionary/manage.py plan --database scripts/db/state/dictionary/full-corpus/staging.sqlite3 --output scripts/db/state/artifacts/dictionary/full-corpus
python3 scripts/dictionary/manage.py verify --manifest scripts/db/state/artifacts/dictionary/full-corpus/manifest.json --environment local
```

The runbook explains that `full-corpus` is a local working alias. The generated immutable manifest still contains the content-derived release ID, and the approved artifact is moved under `scripts/db/state/artifacts/dictionary/<release-id>/` before production planning. No committed file stores a machine-specific absolute path.

- [ ] **Step 4: Add and run the full-release contract test**

The test consumes the report/manifest, not the multi-gigabyte corpus. Assert terminal-state conservation, frozen hashes, AI gate hash, stable ID allocation, no duplicate edge pairs, all foreign-key references resolved, D1 variable/statement limits, and `cod` three-node neighborhood isolation.

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_full_release_contract.py -v
cd backend && npm test
```

- [ ] **Step 5: Apply, activate, roll back, and reactivate locally**

Use the Plan 2 managed executor. Verify public counts and sample searches before activation, after activation, after rollback to the parent, and after reactivation. Reapplying the same artifact must be a no-op and preserve all IDs/counts.

- [ ] **Step 6: Commit the rehearsal contract and runbook**

```bash
git add scripts/dictionary/README.md scripts/dictionary/tests/test_full_release_contract.py
git commit -m "test(dictionary): verify full release rehearsal"
```

### Task 9: Plan, approve, apply, and verify the first production release

**Repository:** `/Users/lim/Documents/Code/tsunhua/langmap`

**Files:**
- Modify only after successful verification: `scripts/db/production-baseline.json`
- Modify: `scripts/dictionary/README.md`

- [ ] **Step 1: Generate a production plan without mutating production**

Use `scripts/db/manage.py production plan` with the immutable SQL and artifact manifest from Task 8. Review the stored Git commit, inventory fingerprint, checksums, expected deltas, estimated chunk count, active parent release and bookmark requirement.

- [ ] **Step 2: Obtain explicit production confirmation**

Stop here until the operator explicitly authorizes this exact plan/release ID. Planning and local rehearsal do not authorize a production write.

- [ ] **Step 3: Apply through the managed database workflow**

After authorization, create the required bookmark, apply chunks with resume journal, run invariants, and activate by the single dataset-state pointer update. Do not invoke Wrangler directly from the dictionary CLI.

- [ ] **Step 4: Verify and exercise rollback readiness**

Run release counts, foreign-key checks, identity/binding uniqueness, edge eligibility, POS/readings, sample queries across dictionary families, `cod` isolation and ordinary user-created mapping visibility. Keep the parent release and bookmark until the agreed observation window completes. If any invariant fails, switch the pointer back to the verified parent release.

- [ ] **Step 5: Refresh the production baseline only after success**

Generate a fresh inventory through `scripts/db/manage.py`, compare it to the approved plan, then update `scripts/db/production-baseline.json`. Never edit expected counts by hand.

- [ ] **Step 6: Run final verification and commit the operational record**

```bash
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py' -v
git diff --check
git add scripts/db/production-baseline.json scripts/dictionary/README.md
git commit -m "chore(db): record managed dictionary release baseline"
```

## Final Acceptance

- The frozen manifest covers every completed JSONL in the input directory and no program path assumes a fixed dictionary count.
- Every manifest bundle has exactly one exporter adapter/profile and one LangMap projection profile.
- Every input entry reaches an explicit exporter or staging terminal state; every publishable occurrence has a binding.
- Unknown DOM signatures and direction conflicts are zero at release level; permitted record quarantines are fully coded and conserved.
- `cod` has three distinct English Expression IDs with canonical text `cod`, stable homograph indices and isolated neighborhoods.
- AI auto merges use the exact approved dual-pass config and meet both precision thresholds on untouched holdout data.
- Artifact generation and same-release rerun are deterministic; apply, activation and rollback were rehearsed locally.
- Production is mutated only after explicit approval of the exact immutable plan, and the baseline is refreshed only after successful verification.
