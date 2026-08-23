# Dictionary Exporter v2 and Staging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a versioned, atomic Structured JSONL v2 exporter plus a LangMap staging pipeline that proves the three `cod` homographs stay separate before any D1 writes.

**Architecture:** Extend the maintained `dictionary_export` Python package with a loss-preserving JSONL contract and a Traditional Chinese–English DOM adapter. In LangMap, load JSONL into a normalized SQLite staging database, apply an explicit adapter, form lexical occurrences/clusters, and emit a deterministic preview artifact without touching D1.

**Tech Stack:** Python 3.12, dataclasses, sqlite3, hashlib, json, lxml 5–6, pytest 8, uv, LangMap Python unittest/pytest-compatible tests.

## Global Constraints

- Design authority: `docs/superpowers/specs/2026-08-23-dictionary-structured-jsonl-import-design.md`.
- Dictionary checkout: `/Users/lim/Documents/Code/tsunhua/dictionary`; LangMap checkout: `/Users/lim/Documents/Code/tsunhua/langmap`.
- Preserve existing uncommitted files in both repositories; never add `export/` outputs to Git.
- Stream CSV and JSONL records; no `list(entries)` or whole-corpus in-memory collection.
- Canonical text is exactly `value.strip()` followed by Unicode NFC; do not lowercase or collapse internal whitespace.
- JSON serialization uses UTF-8, `ensure_ascii=False`, `sort_keys=True`, and compact separators for byte stability.
- The v2 exporter preserves raw and normalized fields but never assigns LangMap Expression IDs.
- `dictionary_key` is the exact non-empty `CFBundleIdentifier`; mutable filenames and display names never participate in identity.
- Unknown direction, locale, reading scheme, or atomization goes to staging quarantine; it is never guessed into a publishable row.
- Definitions, labels, forms, and raw POS remain offline.
- Plan 1 emits preview bindings only; it does not generate or execute production SQL.
- Each task uses TDD and ends with its own Conventional Commit in the repository it changes.

---

## File Structure

Dictionary repository:

| File | Responsibility |
|---|---|
| `src/dictionary_export/jsonl_models.py` | Immutable v2 record model and stable-key helpers |
| `src/dictionary_export/jsonl_schema.py` | Dict serialization and schema validation |
| `src/dictionary_export/jsonl_writer.py` | Atomic JSONL writer and manifest checksum |
| `src/dictionary_export/jsonl_parsers/base.py` | JSONL DOM adapter protocol and errors |
| `src/dictionary_export/jsonl_parsers/traditional_chinese_english.py` | Direction, homograph, sense, reading, POS and example extraction |
| `src/dictionary_export/jsonl_registry.py` | Explicit adapter registry |
| `src/dictionary_export/jsonl_pipeline.py` | Streaming export orchestration and diagnostics |
| `src/dictionary_export/jsonl_cli.py` | CLI entry point |
| `bin/export-dictionary-structured-jsonl.py` | Thin checkout-friendly wrapper |

LangMap repository:

| File | Responsibility |
|---|---|
| `scripts/dictionary/langmap_dictionary/models.py` | Typed staging and preview DTOs |
| `scripts/dictionary/langmap_dictionary/schema.py` | Staging SQLite DDL and schema version |
| `scripts/dictionary/langmap_dictionary/loader.py` | Streaming JSONL loader |
| `scripts/dictionary/langmap_dictionary/adapters/base.py` | Normalization adapter protocol |
| `scripts/dictionary/langmap_dictionary/adapters/traditional_chinese_english.py` | LangMap codes, atomization, reading and POS mappings |
| `scripts/dictionary/langmap_dictionary/clusters.py` | Explicit homograph lexical occurrence grouping |
| `scripts/dictionary/langmap_dictionary/preview.py` | Deterministic preview artifact generator |
| `scripts/dictionary/manage.py` | `stage`, `preview`, and `inspect` CLI |

### Task 1: Define Structured JSONL v2 records

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/jsonl_models.py`
- Create: `src/dictionary_export/jsonl_schema.py`
- Test: `tests/test_jsonl_models.py`

**Interfaces:**
- Produces `DictionaryHeaderV2`, `EntryRecordV2`, `SenseRecordV2`, `RelationV2`, `PronunciationV2`, `ExampleV2`.
- Produces `record_fingerprint(payload: Mapping[str, object]) -> str`.
- Produces `validate_v2_record(payload: object) -> DictionaryHeaderV2 | EntryRecordV2`.

- [ ] **Step 1: Write failing model tests**

```python
def test_entry_keeps_raw_headword_and_homograph_marker():
    entry = EntryRecordV2(
        dictionary_key="com.apple.dictionary.zh_TW-en.DrEye",
        entry_key="entry-native-1",
        record_fingerprint="a" * 64,
        csv_row_number=8,
        raw_headword="cod 1",
        canonical_headword="cod",
        homograph_marker="1",
        direction_hint="eng-to-cmn-Hant",
        native_locator="m_en_1",
        forms=(),
        pronunciations=(),
        senses=(),
        diagnostics=(),
    )
    assert entry.canonical_headword == "cod"
    assert entry.homograph_marker == "1"
```

Add tests that reject empty `dictionary_key`, `entry_key`, `raw_headword`, `canonical_headword`, non-64-hex fingerprints, duplicate sense keys, and non-positive CSV row numbers.

- [ ] **Step 2: Run the model test and verify failure**

Run: `uv run pytest tests/test_jsonl_models.py -v`

Expected: FAIL because `dictionary_export.jsonl_models` does not exist.

- [ ] **Step 3: Implement immutable v2 dataclasses**

Use frozen, slotted dataclasses. The exact top-level shapes are:

```python
@dataclass(frozen=True, slots=True)
class DictionaryHeaderV2:
    record_type: Literal["dictionary"]
    schema_version: Literal[2]
    dictionary_key: str
    input_file_name: str
    input_sha256: str
    entry_count: int
    exporter_version: str

@dataclass(frozen=True, slots=True)
class EntryRecordV2:
    record_type: Literal["entry"] = "entry"
    schema_version: Literal[2] = 2
    dictionary_key: str = ""
    entry_key: str = ""
    record_fingerprint: str = ""
    csv_row_number: int = 0
    raw_headword: str = ""
    canonical_headword: str = ""
    homograph_marker: str | None = None
    direction_hint: str | None = None
    native_locator: str | None = None
    forms: tuple[str, ...] = ()
    pronunciations: tuple[PronunciationV2, ...] = ()
    senses: tuple[SenseRecordV2, ...] = ()
    diagnostics: tuple[str, ...] = ()
```

`SenseRecordV2` contains `sense_key`, `ordinal`, `native_locator`, `definitions`, `pos`, `equivalents`, `relations`, `examples`, and `labels`. `RelationV2` has a closed `kind` (`synonym` or `antonym`), raw related text, optional reading and nullable language hint. All text-bearing children retain their raw string; language is a nullable direction hint, not a LangMap code.

- [ ] **Step 4: Implement stable canonical serialization**

`to_payload(record)` recursively converts tuples/dataclasses to JSON-compatible values. `record_fingerprint()` hashes canonical JSON after removing `record_fingerprint` itself:

```python
encoded = json.dumps(
    payload,
    ensure_ascii=False,
    sort_keys=True,
    separators=(",", ":"),
).encode("utf-8")
return hashlib.sha256(encoded).hexdigest()
```

- [ ] **Step 5: Implement strict record validation**

`validate_v2_record()` rejects unknown `record_type`, schema versions other than `2`, absent arrays, duplicate sense keys, invalid fingerprint grammar, and wrong scalar types. It must not silently drop unknown top-level keys; raise `JsonlSchemaError(path, reason)`.

- [ ] **Step 6: Run tests**

Run: `uv run pytest tests/test_jsonl_models.py -v`

Expected: PASS.

- [ ] **Step 7: Commit Task 1**

```bash
git add src/dictionary_export/jsonl_models.py src/dictionary_export/jsonl_schema.py tests/test_jsonl_models.py
git commit -m "feat(export): define structured JSONL v2 records"
```

### Task 2: Make raw CSV identity and JSONL output atomic

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Modify: `src/dictionary_export/models.py`
- Modify: `src/dictionary_export/source.py`
- Create: `src/dictionary_export/jsonl_writer.py`
- Test: `tests/test_source.py`
- Test: `tests/test_jsonl_writer.py`

**Interfaces:**
- `RawEntry` adds `raw_columns: tuple[str, ...]` with default `()`.
- `read_pyglossary_csv(path)` treats only explicit leading metadata keys as metadata.
- `write_jsonl_atomic(path, header, entries) -> JsonlWriteSummary`.

- [ ] **Step 1: Add failing metadata-boundary tests**

Construct a CSV with leading `#name` and `#CFBundleIdentifier`, followed by real entries `#` and `#9110`. Assert the first two are metadata and the latter two stream as `RawEntry` values. Assert a `#name` row after the first data row is also an entry.

- [ ] **Step 2: Run the source tests and verify failure**

Run: `uv run pytest tests/test_source.py -v`

Expected: FAIL because current code treats every leading `#...` key as metadata.

- [ ] **Step 3: Restrict metadata recognition**

Use this exact set while still inside the leading metadata block:

```python
METADATA_KEYS = frozenset({
    "name", "CFBundleIdentifier", "edition", "sourceLang", "targetLang",
})
```

A row is metadata only when `row[0][1:] in METADATA_KEYS`, it has at least two columns, and no data row has been emitted. Preserve extra columns in `RawEntry.raw_columns`.

- [ ] **Step 4: Add failing atomic writer tests**

Test canonical header-first output, UTF-8 round-trip, target refusal, parent validation, `fsync`＋`os.replace`, and sibling temporary-file removal when the entry iterator raises.

- [ ] **Step 5: Run writer tests and verify failure**

Run: `uv run pytest tests/test_jsonl_writer.py -v`

Expected: FAIL because `jsonl_writer` does not exist.

- [ ] **Step 6: Implement `write_jsonl_atomic`**

Write the header then each entry with:

```python
line = json.dumps(
    to_payload(record), ensure_ascii=False, sort_keys=True, separators=(",", ":")
)
handle.write(line + "\n")
```

Calculate SHA-256 while writing, verify the emitted entry count equals `header.entry_count`, flush, `os.fsync`, and `os.replace`. Return output path, byte count, SHA-256, and entry count.

- [ ] **Step 7: Run Task 2 tests**

Run: `uv run pytest tests/test_source.py tests/test_jsonl_writer.py -v`

Expected: PASS.

- [ ] **Step 8: Commit Task 2**

```bash
git add src/dictionary_export/models.py src/dictionary_export/source.py src/dictionary_export/jsonl_writer.py tests/test_source.py tests/test_jsonl_writer.py
git commit -m "fix(export): preserve hash-prefixed dictionary entries"
```

### Task 3: Parse Traditional Chinese–English homographs faithfully

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/jsonl_parsers/__init__.py`
- Create: `src/dictionary_export/jsonl_parsers/base.py`
- Create: `src/dictionary_export/jsonl_parsers/traditional_chinese_english.py`
- Create: `src/dictionary_export/jsonl_registry.py`
- Create: `tests/fixtures/traditional_chinese_english_jsonl.py`
- Test: `tests/test_traditional_chinese_english_jsonl.py`
- Test: `tests/test_jsonl_registry.py`

**Interfaces:**
- Protocol `JsonlDictionaryParser.id`, `.supports(metadata, samples)`, `.parse(raw, dictionary_key) -> EntryRecordV2`; `dictionary_key` comes from the validated `CFBundleIdentifier` metadata row rather than parser code.
- `select_jsonl_parser(metadata, samples, requested_id=None) -> JsonlDictionaryParser`.
- Errors `JsonlEntryParseError`, `UnsupportedJsonlDictionaryError`, `AmbiguousJsonlParserError`.

- [ ] **Step 1: Create a minimal synthetic `cod` fixture**

Create three `RawEntry` objects whose CSV headword is `cod` and whose HTML `.hw` text is `cod 1`, `cod 2`, `cod 3`. Use invented translations with the same structure as the real entry:

```python
COD_ROWS = (
    RawEntry(10, "cod", "<div><span id='cod-1' class='hw'>cod <span class='hm'>1</span></span>...</div>"),
    RawEntry(11, "cod", "<div><span id='cod-2' class='hw'>cod <span class='hm'>2</span></span>...</div>"),
    RawEntry(12, "cod", "<div><span id='cod-3' class='hw'>cod <span class='hm'>3</span></span>...</div>"),
)
```

Include `.se2` and `.semb` interleaved in DOM order, `.pos`, `.trans`, `.df`, `.eg > .ex`, `.eg .trg`, `.gr`, `.label`, `.frm`, and `.ph` nodes.

- [ ] **Step 2: Write failing parser tests**

Assert every record has `canonical_headword == "cod"`; markers are `1/2/3`; `sense_key` order follows DOM order; definitions are retained; example translations do not leak into equivalents; POS, labels, forms and pronunciations keep raw text; `direction_hint == "eng-to-cmn-Hant"`.

- [ ] **Step 3: Run parser tests and verify failure**

Run: `uv run pytest tests/test_traditional_chinese_english_jsonl.py tests/test_jsonl_registry.py -v`

Expected: FAIL because the JSONL parser package does not exist.

- [ ] **Step 4: Implement parser protocol and registry**

The registry is an explicit tuple. Requested IDs validate exactly; automatic selection requires exactly one match. Parser errors contain row number, parser ID, native locator when present, and a concise reason.

- [ ] **Step 5: Implement headword and direction extraction**

Prefer the CSV key as canonical headword when the `.hw` descendant is a numeric homograph marker. Detect marker only from a dedicated marker descendant or a terminal numeric text node; do not strip ordinary numbers from entries such as `Formula 1`.

Use per-entry direction attributes/IDs first. The adapter's validated fallback is Han detection only when one side is `cmn-Hant` and the other is `eng`; inability to decide raises `JsonlEntryParseError(..., "unknown_direction")`.

- [ ] **Step 6: Implement DOM-order sense extraction**

Traverse once with:

```python
sense_nodes = root.xpath(
    "//*[contains(concat(' ', normalize-space(@class), ' '), ' se2 ') or "
    "contains(concat(' ', normalize-space(@class), ' '), ' semb ')]"
)
```

Create stable keys from native element IDs when present; otherwise use `entry_key + ':sense:' + ordinal` and add diagnostic `fallback_sense_identity`. Definitions include `.df`; equivalents exclude descendants of `.eg`; examples pair `.ex` with `.trg`／`.trans` within the same `.eg`.

- [ ] **Step 7: Run parser and registry tests**

Run: `uv run pytest tests/test_traditional_chinese_english_jsonl.py tests/test_jsonl_registry.py -v`

Expected: PASS.

- [ ] **Step 8: Commit Task 3**

```bash
git add src/dictionary_export/jsonl_parsers src/dictionary_export/jsonl_registry.py tests/fixtures/traditional_chinese_english_jsonl.py tests/test_traditional_chinese_english_jsonl.py tests/test_jsonl_registry.py
git commit -m "feat(export): parse dictionary homographs and senses"
```

### Task 4: Add the v2 export pipeline and CLI

**Repository:** `/Users/lim/Documents/Code/tsunhua/dictionary`

**Files:**
- Create: `src/dictionary_export/jsonl_pipeline.py`
- Create: `src/dictionary_export/jsonl_cli.py`
- Modify: `pyproject.toml`
- Modify: `bin/export-dictionary-structured-jsonl.py`
- Test: `tests/test_jsonl_pipeline.py`
- Test: `tests/test_jsonl_cli.py`

**Interfaces:**
- `export_jsonl_v2(input_path, output_path, parser_id=None) -> JsonlExportSummary`.
- CLI: `dictionary-jsonl-export INPUT OUTPUT [--parser ID]`.
- Wrapper delegates to `dictionary_export.jsonl_cli:main` without parser logic.

- [ ] **Step 1: Write failing pipeline tests**

Assert streaming sample replay, input SHA-256, schema version `2`, byte-stable output, entry counts, diagnostic counts, existing-target refusal, and atomic cleanup when parsing fails.

- [ ] **Step 2: Write failing CLI tests**

Call `main([...])`; success prints one JSON summary to stdout and returns `0`; known validation/parsing/I/O failures print one concise line to stderr and return `1`; argparse errors return `2`.

- [ ] **Step 3: Run tests and verify failure**

Run: `uv run pytest tests/test_jsonl_pipeline.py tests/test_jsonl_cli.py -v`

Expected: FAIL because pipeline and CLI modules do not exist.

- [ ] **Step 4: Implement the streaming pipeline**

Read at most five samples for parser selection, replay them with `itertools.chain`, parse each entry once, and pass the iterator directly to `write_jsonl_atomic`. Build the header only after a lightweight first pass counts data rows and hashes the input; the second pass performs export. Do not store entries between passes.

- [ ] **Step 5: Implement CLI and package entry point**

Add:

```toml
dictionary-jsonl-export = "dictionary_export.jsonl_cli:main"
```

Replace the standalone wrapper body with import/bootstrap code that calls `main()`; delete duplicated extraction functions from the wrapper.

- [ ] **Step 6: Run the full dictionary test suite**

Run:

```bash
uv run pytest -v
uv run python -m compileall -q src tests
```

Expected: both commands exit `0`.

- [ ] **Step 7: Commit Task 4**

```bash
git add pyproject.toml src/dictionary_export/jsonl_pipeline.py src/dictionary_export/jsonl_cli.py bin/export-dictionary-structured-jsonl.py tests/test_jsonl_pipeline.py tests/test_jsonl_cli.py
git commit -m "feat(export): add atomic structured JSONL v2 CLI"
```

### Task 5: Create the LangMap staging database

**Repository:** `/Users/lim/Documents/Code/tsunhua/langmap`

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/__init__.py`
- Create: `scripts/dictionary/langmap_dictionary/models.py`
- Create: `scripts/dictionary/langmap_dictionary/schema.py`
- Create: `scripts/dictionary/langmap_dictionary/loader.py`
- Create: `scripts/dictionary/tests/__init__.py`
- Create: `scripts/dictionary/tests/test_staging_loader.py`
- Modify: `scripts/dictionary/test_import_structured_jsonl.py`

**Interfaces:**
- `create_staging_database(path: Path) -> sqlite3.Connection`.
- `load_jsonl_release(connection, paths: Sequence[Path]) -> StageSummary`.
- `StageSummary(input_records, staged_entries, staged_senses, quarantined, manifest_hash)`.

- [ ] **Step 1: Write a failing schema/loader test**

Use a two-entry v2 fixture and assert foreign keys are enabled; all arrays, including synonym/antonym relations, land in normalized tables; raw JSON and fingerprints are preserved; loading the same release twice is a no-op; malformed schema version creates a release-level failure instead of partial rows.

- [ ] **Step 2: Run the staging test and verify failure**

Run: `python3 -m pytest scripts/dictionary/tests/test_staging_loader.py -v`

Expected: FAIL because `langmap_dictionary` does not exist.

- [ ] **Step 3: Define staging schema version 1**

Create tables named in spec §7.2 with explicit primary/foreign keys. At minimum:

```sql
CREATE TABLE staging_releases (
  id TEXT PRIMARY KEY,
  manifest_hash TEXT NOT NULL UNIQUE,
  schema_version INTEGER NOT NULL CHECK (schema_version = 1),
  status TEXT NOT NULL CHECK (status IN ('loading','staged','failed'))
);
CREATE TABLE input_entries (
  release_id TEXT NOT NULL,
  entry_key TEXT NOT NULL,
  dictionary_key TEXT NOT NULL,
  canonical_headword TEXT NOT NULL,
  homograph_marker TEXT,
  direction_hint TEXT,
  record_fingerprint TEXT NOT NULL,
  raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, entry_key),
  FOREIGN KEY (release_id) REFERENCES staging_releases(id)
);
CREATE TABLE input_senses (
  release_id TEXT NOT NULL,
  sense_key TEXT NOT NULL,
  entry_key TEXT NOT NULL,
  ordinal INTEGER NOT NULL CHECK (ordinal >= 1),
  raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, sense_key),
  FOREIGN KEY (release_id, entry_key) REFERENCES input_entries(release_id, entry_key)
);
```

Add normalized child tables, lexical occurrences, clusters, decisions, and quarantine with indexes on release/dictionary/error code and `(lang_code, canonical_text)`.

- [ ] **Step 4: Implement transactional streaming load**

Validate header then each line with an in-repo v2 schema mirror. Insert entry and children within a savepoint; ordinary row errors become `quarantine_items`, while duplicate key with different fingerprint, schema mismatch, manifest mismatch, or count mismatch marks the release `failed` and rolls back all rows.

- [ ] **Step 5: Retire the flat importer tests**

Replace tests that expect one expression per `(lang,text)` with a compatibility assertion that `scripts/dictionary/import_structured_jsonl.py` exits with a migration message pointing to `scripts/dictionary/manage.py`. Do not keep two functional import paths.

- [ ] **Step 6: Run staging and legacy-entry tests**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_staging_loader.py scripts/dictionary/test_import_structured_jsonl.py -v
```

Expected: PASS.

- [ ] **Step 7: Commit Task 5**

```bash
git add scripts/dictionary/langmap_dictionary scripts/dictionary/tests scripts/dictionary/test_import_structured_jsonl.py scripts/dictionary/import_structured_jsonl.py
git commit -m "feat(dictionary): add normalized staging database"
```

### Task 6: Normalize the Traditional Chinese–English vertical slice

**Repository:** `/Users/lim/Documents/Code/tsunhua/langmap`

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/adapters/__init__.py`
- Create: `scripts/dictionary/langmap_dictionary/adapters/base.py`
- Create: `scripts/dictionary/langmap_dictionary/adapters/traditional_chinese_english.py`
- Create: `scripts/dictionary/langmap_dictionary/clusters.py`
- Create: `scripts/dictionary/tests/fixtures/traditional_chinese_english_v2.jsonl`
- Create: `scripts/dictionary/tests/test_traditional_chinese_english_adapter.py`
- Create: `scripts/dictionary/tests/test_cod_clusters.py`

**Interfaces:**
- `DictionaryAdapter.normalize_entry(entry: StagedEntry) -> NormalizedEntry`.
- `build_explicit_clusters(connection, release_id) -> ClusterSummary`.
- Error codes match spec §10 exactly.

- [ ] **Step 1: Write failing adapter tests**

Assert `eng → eng-Latn-US`, Traditional Chinese → `cmn-Hant-TW`, `UK_IPA solitary`/`US_IPA solitary` normalize to `ipa` with GB/US locales, raw POS maps to controlled codes, bullet prefixes are removed only from normalized equivalents, and ambiguous comma lists remain quarantined unless a fixture-specific rule proves atomization.

- [ ] **Step 2: Write the failing `cod` cluster test**

Load the three-entry fixture and assert exactly three English headword clusters, all with canonical text `cod`; explicit markers block cross-cluster merge; each sense under the same entry points to that entry's headword cluster; equivalent occurrences stay scoped to their sense.

- [ ] **Step 3: Run tests and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_traditional_chinese_english_adapter.py scripts/dictionary/tests/test_cod_clusters.py -v
```

Expected: FAIL because adapters and cluster builder do not exist.

- [ ] **Step 4: Implement adapter protocol and normalized DTOs**

Define frozen DTOs for `NormalizedEntry`, `NormalizedSense`, `NormalizedOccurrence`, `NormalizedReading`, and `NormalizedPos`. Every DTO carries `claim_key`, raw value, normalized value, language/locale codes, and zero or more error codes.

- [ ] **Step 5: Implement explicit homograph grouping**

Cluster headword occurrences by `(dictionary_key, entry_key, canonical_headword)`; all senses inside one entry reuse its headword cluster. Different explicit markers never merge. Equivalent and example occurrences receive distinct pre-AI cluster keys derived from their claim keys even when text matches elsewhere.

- [ ] **Step 6: Run Task 6 tests**

Run the two Task 6 test files; expect PASS.

- [ ] **Step 7: Commit Task 6**

```bash
git add scripts/dictionary/langmap_dictionary/adapters scripts/dictionary/langmap_dictionary/clusters.py scripts/dictionary/tests/fixtures scripts/dictionary/tests/test_traditional_chinese_english_adapter.py scripts/dictionary/tests/test_cod_clusters.py
git commit -m "feat(dictionary): preserve explicit homograph clusters"
```

### Task 7: Emit a deterministic preview artifact and CLI

**Repository:** `/Users/lim/Documents/Code/tsunhua/langmap`

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/preview.py`
- Create: `scripts/dictionary/manage.py`
- Create: `scripts/dictionary/tests/test_preview.py`
- Create: `scripts/dictionary/tests/test_manage_cli.py`
- Modify: `scripts/dictionary/README.md`

**Interfaces:**
- `build_preview(connection, release_id, output_dir) -> PreviewManifest`.
- CLI commands: `stage JSONL... --database PATH`, `preview --database PATH --release ID --output DIR`, `inspect --database PATH --release ID`.

- [ ] **Step 1: Write failing preview tests**

Assert `manifest.json`, `bindings.jsonl`, `quarantine.jsonl`, and `quality-report.json` are byte-stable; output directories are created atomically; stale files from a previous failed run are not mixed into a new artifact; preview contains no SQL.

- [ ] **Step 2: Write failing CLI tests**

Call `main([...])`; assert JSON-only stdout, concise stderr, return codes `0/1/2`, explicit database/output paths, and refusal to overwrite a different manifest at an existing output path.

- [ ] **Step 3: Run tests and verify failure**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_preview.py scripts/dictionary/tests/test_manage_cli.py -v
```

Expected: FAIL because preview and CLI modules do not exist.

- [ ] **Step 4: Implement deterministic preview emission**

Sort bindings by `(lang_code, canonical_text, cluster_key, claim_key)`, quarantine by `(error_code, dictionary_key, claim_key)`, and JSON object keys lexically. Write into a sibling temporary directory, fsync files, then rename only when all checksums match the manifest.

- [ ] **Step 5: Implement CLI and documentation**

Use `argparse` subcommands and never infer the external dictionary checkout. README must show explicit JSONL, staging DB, release ID, and artifact paths plus the `cod` fixture test command.

- [ ] **Step 6: Run Plan 1 verification**

Dictionary repository:

```bash
uv run pytest -v
uv run python -m compileall -q src tests
git diff --check
```

LangMap repository:

```bash
python3 -m pytest scripts/dictionary -v
git diff --check
```

Expected: all commands exit `0`; `git status --short` contains no generated JSONL, SQLite or artifact directory.

- [ ] **Step 7: Commit Task 7**

```bash
git add scripts/dictionary/manage.py scripts/dictionary/langmap_dictionary/preview.py scripts/dictionary/tests/test_preview.py scripts/dictionary/tests/test_manage_cli.py scripts/dictionary/README.md
git commit -m "feat(dictionary): add staged import preview workflow"
```

## Plan 1 Acceptance

- JSONL v2 contains raw/canonical headword, homograph marker, stable locators, definitions, examples, labels, POS, forms, readings and explicit synonym/antonym relations.
- Export is streaming, byte-stable and atomic.
- Hash-prefixed real entries are not consumed as metadata.
- Staging load is idempotent and preserves raw JSON.
- `cod` yields exactly three explicit English headword clusters with isolated equivalent neighborhoods.
- Preview artifact has deterministic bindings, quarantine and quality counts, and performs no D1 mutation.
- Both repositories pass their complete relevant test suites and `git diff --check`.
