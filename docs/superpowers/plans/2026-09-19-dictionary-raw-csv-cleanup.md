# Dictionary Raw-to-CSV Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 將 dictionary 統一為 `raw/<source-key>/` 原始輸入到 `csv/<source-key>/data.csv + manifest.json` 的流程，將詞句資料與 UI locale 從 JSON/JSONL 改為 CSV，刪除已被 PostgreSQL／canonical CSV 取代的 SQLite、D1 舊腳本，並以隔離 PostgreSQL 驗證 LangMap 可直接匯入寬表 CSV。

**Architecture:** dictionary 的 source adapter 只讀 raw workspace，所有正式輸出都經共用 canonical CSV writer；Wikivoyage 快照、Apple/PyGlossary、Yomichan、Kautian、Hakka、Shanghai、ChhoeTaigi、Jyutjyu 由一個跨平台 raw dispatcher 選擇 adapter。LangMap 保留 `import_mapping_csv_pg.py` 作為唯一詞典匯入入口，直接把 manifest 旁的 CSV 在單一 transaction 寫入 PostgreSQL；不建立 SQLite/D1 staging，也不以 JSONL 作為跨模組契約。

**Tech Stack:** Python 3.12、`uv`/`pytest`（dictionary）、`psycopg` 與 PostgreSQL（LangMap）、既有 canonical wide CSV contract、Git inventory。

**Spec:** `docs/superpowers/specs/2026-09-19-postgresql-csv-dictionary-design.md`、`docs/superpowers/specs/2026-09-19-wikivoyage-csv-source-design.md`

## Global Constraints

- 正式詞典 artifact 固定為 `csv/<source-key>/data.csv` 與同目錄 `manifest.json`；不產生詞句 JSON/JSONL、SQLite mirror 或 D1 staging。manifest、snapshot metadata、package/build 設定等非詞句 metadata JSON 可保留。
- raw 只作來源輸入 workspace；預設忽略 raw payload，只有經授權且值得版本控制的檔案才可明確加入 Git。
- canonical 表頭固定為 `ENTRY_ID,NOTE,LOCALE_<locale>...,READING_<locale>_<scheme>...`，locale 先於 reading 並按 UTF-8 bytewise 排序。
- LangMap importer 跨 OS，只依賴 Python、`psycopg` 與 `DATABASE_URL`，不呼叫 Homebrew、`psql`、Wrangler、SQLite 或 shell wrapper。
- 保留 UI locale 的 Web fallback code、PG schema／migration、language-reference、morphology 與 PG handbook builder；詞句 locale JSON 已由單一寬表 CSV 取代，manifest／catalog 等 metadata JSON 可保留。
- UI locale source 不再使用多份 `scripts/i18n/*.json`，改成單一寬表 `scripts/i18n/ui-locales.csv`（`ENTRY_ID,NOTE,LOCALE_*...`）；Web build 與 PG importer 都讀同一份 CSV。
- 不修改使用者已提交或後續新增的非本題資料；每次刪除先以 `git grep` 確認沒有現行程式或 CI 引用。

---

### Task 1: 建立 dictionary raw workspace 與統一 dispatcher

**Files:**
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/raw/README.md`
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/raw/.gitkeep`
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/raw/wikivoyage/.gitkeep`
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/raw_cli.py`
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/tests/test_raw_cli.py`
- Modify: `/Users/lim/Documents/Code/tsunhua/dictionary/pyproject.toml`
- Modify: `/Users/lim/Documents/Code/tsunhua/dictionary/.gitignore`
- Modify: `/Users/lim/Documents/Code/tsunhua/dictionary/README.md`

**Interfaces:**
- `dictionary-raw-export --source-key wikivoyage --raw-dir raw --output-dir csv --snapshot <dir>` calls `export_snapshot_directory` and writes `csv/wikivoyage/<pageid>-<target-locale>/...`.
- `dictionary-raw-export --source-key <adapter> --raw-dir raw --output-dir csv` discovers the source-specific raw file/directory and calls the existing direct CSV adapter; `--input` overrides discovery with a path relative to `raw`.
- The dispatcher rejects missing/ambiguous inputs and existing canonical archives before any output is written.

- [x] **Step 1: Write the failing dispatcher tests**

```python
def test_raw_wikivoyage_snapshot_exports_wide_archive(tmp_path):
    raw = make_snapshot(tmp_path / "raw" / "wikivoyage" / "jp-1")
    assert raw_cli.main(["--source-key", "wikivoyage", "--raw-dir", str(tmp_path / "raw"), "--output-dir", str(tmp_path / "csv")]) == 0
    assert (tmp_path / "csv" / "wikivoyage" / "16153-jpn-Jpan-JP" / "data.csv").is_file()

def test_raw_dispatcher_requires_one_input(tmp_path):
    (tmp_path / "raw" / "hakka").mkdir(parents=True)
    with pytest.raises(raw_cli.RawSourceError, match="raw input"):
        raw_cli.resolve_source_input(tmp_path / "raw", "hakka", None)
```

- [x] **Step 2: Run the focused tests and verify they fail**

Run: `uv run pytest tests/test_raw_cli.py -q`

Expected: FAIL because the raw dispatcher and raw workspace contract do not exist.

- [x] **Step 3: Implement the dispatcher and directory contract**

Implement `resolve_source_input(raw_dir, source_key, input_override)` with deterministic child discovery, an adapter table for `wikivoyage`, `pyglossary`, `yomichan`, `kautian`, `chhoetaigi`, `jyutjyu`, `hakka`, and `shanghai`, and `export_raw_source(...)` that routes only to existing CSV-producing functions. Default raw payload rules are:

```text
raw/<source-key>/                 # source input workspace
raw/wikivoyage/<snapshot>/        # snapshot manifest.json + page files
csv/<source-key>/                 # reviewed canonical output
```

Add the console entry point `dictionary-raw-export = "dictionary_export.raw_cli:main"`. Ignore raw payloads while retaining directories, README files, and `.gitkeep`; document that raw sources are not silently copied into `csv/` and canonical archives are never overwritten.

- [x] **Step 4: Run the focused tests and the existing Wikivoyage tests**

Run: `uv run pytest tests/test_raw_cli.py tests/test_wikivoyage_csv.py -q`

Expected: PASS; the output contains `data.csv`, metadata `manifest.json`, and no phrase JSONL artifact.

- [x] **Step 5: Commit the raw workflow**

```bash
git add raw src/dictionary_export/raw_cli.py tests/test_raw_cli.py pyproject.toml .gitignore README.md
git commit -m "feat: add raw source to canonical CSV dispatcher"
```

### Task 2: Remove dictionary JSONL output paths and obsolete source scripts

**Files:**
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/jsonl_cli.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/jsonl_pipeline.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/jsonl_registry.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/jsonl_profiles.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/jsonl_schema.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/jsonl_writer.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/jsonl_parsers/`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/*_cli.py` that only writes JSONL (`chhoetaigi_cli.py`, `hakka_cli.py`, `jyutjyu_cli.py`, `kautian_cli.py`, `shanghai_cli.py`, `yomichan_cli.py`)
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/kautian_mapping_csv.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/kautian_mapping_csv_cli.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/yomichan_mapping_csv.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/yomichan_mapping_csv_cli.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/bin/convert-all-to-langmap.py`
- Delete: `/Users/lim/Documents/Code/tsunhua/dictionary/tests/test_jsonl_*.py`, `tests/test_traditional_chinese_english_jsonl.py`, and tests that assert `export_*_jsonl`
- Modify: active source modules (`chhoetaigi.py`, `hakka.py`, `jyutjyu.py`, `kautian.py`, `shanghai.py`, `yomichan.py`, `csv_adapters.py`) to keep record construction but remove JSONL writer/header/schema calls
- Create/Modify: `src/dictionary_export/records.py` as the source-neutral record model module, if needed after import audit

**Interfaces:**
- Every supported source has a direct CSV adapter under `csv_adapters.py` or `wikivoyage/export.py`; no public function name ends in `_jsonl`, and no adapter writes phrase JSON/JSONL.
- Internal structured records remain Python objects only and are passed directly to `entry_records_to_rows`; they are not serialized as an intermediate artifact.

- [x] **Step 1: Capture the current direct CSV regression set**

Run: `uv run pytest tests/test_csv_adapters.py tests/test_csv_contract.py tests/test_manifest.py tests/test_wikivoyage_csv.py -q`

Expected: PASS before deleting legacy paths.

- [x] **Step 2: Remove JSONL-only entrypoints and tests**

Delete only files proven by `git grep` to be used by the removed JSONL commands; keep the source parsers and record fields required by direct CSV adapters. Update `pyproject.toml` so its only source export entrypoints are `dictionary-csv-export`, source-specific CSV entrypoints, `dictionary-wikivoyage-export`, and `dictionary-raw-export`.

- [x] **Step 3: Run the full dictionary suite and scan for forbidden output paths**

Run: `uv run pytest tests -q` and `git grep -n -E 'export_.*jsonl|jsonl_writer|jsonl_pipeline|\.jsonl|scripts/i18n/.*\.json' -- src bin tests pyproject.toml README.md`.

Expected: all retained tests pass; the grep returns no executable/export contract references (metadata JSON and raw upstream formats may remain explicitly documented).

- [x] **Step 4: Commit dictionary cleanup**

```bash
git add src tests bin pyproject.toml README.md
git commit -m "refactor: retire dictionary JSONL export paths"
```

### Task 3: Remove LangMap D1/SQLite staging scripts without touching PG tools

**Files:**
- Delete tracked files under `/Users/lim/Documents/Code/tsunhua/langmap/scripts/db/` (the ignored `scripts/db/state/` payload is not recursively deleted)
- Delete `/Users/lim/Documents/Code/tsunhua/langmap/backend/schema.sql` and tracked files under `backend/migrations/`, the retired SQLite/D1 baseline now replaced by PostgreSQL schema/migrations
- Modify: `/Users/lim/Documents/Code/tsunhua/langmap/.gitignore` to remove the obsolete tracked-state exception while retaining safe ignores for any user-owned local state
- Modify: `/Users/lim/Documents/Code/tsunhua/langmap/docs/runbooks/scripts-inventory.md` to mark `scripts/db/` removed and list the surviving PG/dictionary entries
- Modify: `/Users/lim/Documents/Code/tsunhua/langmap/docs/runbooks/reference-data-sync.md` and `docs/runbooks/production-data-release.md` with a clear historical banner and links to `database-migrations.md`, `scripts/dictionary/README.md`, and `docs/runbooks/wikivoyage-phrasebook-release.md`
- Modify: `/Users/lim/Documents/Code/tsunhua/langmap/scripts/i18n/README.md` to describe the single wide CSV source and remove executable SQL-import instructions
- Delete: tracked generated D1/SQLite SQL bundle files, SQL-only i18n generators, and the four phrase-bearing JSON locale source files after their CSV replacements pass the Web and PG checks
- Delete: `/Users/lim/Documents/Code/tsunhua/langmap/scripts/dictionary/gold/README.md`, the marker for the retired JSONL reconciliation gold workspace
- Create: `/Users/lim/Documents/Code/tsunhua/langmap/scripts/i18n/ui-locales.csv` as one wide UI locale table converted from the four locale source files plus `web/src/locales/en.ts`
- Create: `/Users/lim/Documents/Code/tsunhua/langmap/scripts/i18n/generate-ui-csv.py` to validate the wide table and refresh its metadata manifest
- Modify: `/Users/lim/Documents/Code/tsunhua/langmap/web/src/locales/project.ts` to load the one wide CSV through a typed Vite-compatible loader
- Delete: `scripts/i18n/generate-bundle.py`, `generate-i18n-sql.py`, `generate-ui-seed.py`, and generated SQL artifacts after the CSV importer is verified

**Interfaces:**
- Current commands are `python3 scripts/postgres/manage.py ...`, `python3 scripts/dictionary/import_mapping_csv_pg.py ...`, and `dictionary-raw-export`; no current runbook command points to `scripts/db`. UI locale source/import also reads CSV only.
- Historical specs and completed run logs remain immutable documentation; they are not executable entrypoints.

- [x] **Step 1: Generate and review the tracked keep/delete inventory**

Run: `git ls-files scripts/db scripts/i18n | sort` and `git grep -n -- ':!docs/superpowers/**' -- ':!docs/runbooks/2026-*' 'scripts/db|scripts/i18n/generate-.*sql|import-all.sh'`.

Expected: no active runtime or CI reference to `scripts/db`; UI phrase data is read from the single wide CSV, while only metadata JSON remains.

- [x] **Step 2: Convert UI locale source files to CSV before deleting JSON copies**

Use a deterministic conversion that writes one UTF-8 RFC 4180 wide CSV, verifies stable `ENTRY_ID` keys and locale columns, and makes `project.ts` select locale columns from that table. Run the frontend i18n checks and a production build before removing the phrase JSON copies.

- [x] **Step 3: Delete retired scripts and update current docs**

Use `git rm` on tracked D1/SQLite scripts and their tests/fixtures; do not use a recursive filesystem delete on `scripts/db/state` because it may contain ignored user snapshots. Remove SQL-only i18n artifacts only after the reference scan, preserving metadata JSON only.

- [x] **Step 4: Verify current references and documentation**

Run: `git grep -n -- ':!docs/superpowers/**' -- ':!docs/runbooks/2026-*' 'scripts/db|wrangler d1|SQLite mirror|D1 staging|import-all.sh|scripts/i18n/.*\.json'`.

Expected: no executable/current runbook reference and no phrase JSON input; remaining matches are explicit policy text, metadata manifests, or historical notes.

- [x] **Step 5: Commit LangMap cleanup**

```bash
git add .gitignore docs/runbooks scripts/i18n
git add -u scripts/db
git commit -m "chore: remove retired D1 and SQLite staging scripts"
```

### Task 4: Add opt-in PostgreSQL CSV integration coverage

**Files:**
- Create: `/Users/lim/Documents/Code/tsunhua/langmap/scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py`
- Modify: `/Users/lim/Documents/Code/tsunhua/langmap/scripts/dictionary/README.md`
- Modify: `/Users/lim/Documents/Code/tsunhua/langmap/docs/runbooks/database-migrations.md`

**Interfaces:**
- The integration test runs only when `LANGMAP_TEST_DATABASE_URL` is set; it never falls back to an arbitrary production `DATABASE_URL`.
- It writes a unique source snapshot containing `LOCALE_eng-Latn-US`, `LOCALE_jpn-Jpan-JP`, and `READING_jpn-Jpan-JP_kana`, runs `--check`, runs `--apply`, queries source-scoped expressions/edges/readings, then reapplies the same manifest to prove idempotency.

- [x] **Step 1: Write the opt-in integration test**

```python
database_url = os.getenv("LANGMAP_TEST_DATABASE_URL")
if not database_url:
    pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

manifest = write_fixture_manifest(tmp_path)
assert run_import(manifest, "--check", database_url).returncode == 0
first = run_import(manifest, "--apply", database_url)
second = run_import(manifest, "--apply", database_url)
assert first.returncode == second.returncode == 0
assert query_source_counts(database_url, manifest_source_name) == {"expressions": 2, "edges": 1, "readings": 1}
```

The fixture uses a unique `source_type/source_name`, so it cannot delete or reconcile another source; the README requires an isolated disposable database for the opt-in test.

- [x] **Step 2: Run the test against the local Homebrew PostgreSQL database**

Run: `LANGMAP_TEST_DATABASE_URL='postgresql://langmap_dev_user:langmap-local@127.0.0.1:5432/langmap_dev' /tmp/langmap-pg-venv/bin/python -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py -q`

Expected: PASS with `--check`, first `--apply`, and idempotent second `--apply` all successful.

- [x] **Step 3: Run importer unit tests and report unrelated legacy failures separately**

Run: `python3 -m pytest scripts/dictionary/tests scripts/postgres/tests -q` and `git diff --check`.

Expected: importer unit tests and PostgreSQL contract tests pass; the opt-in integration test is skipped unless `LANGMAP_TEST_DATABASE_URL` is set. Any remaining failures outside these suites are not attributed to this change.

- [x] **Step 4: Commit the PG verification**

```bash
git add scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py scripts/dictionary/README.md docs/runbooks/database-migrations.md
git commit -m "test: verify canonical CSV import into PostgreSQL"
```

### Task 5: Final acceptance and handoff

**Files:**
- Modify: `docs/runbooks/scripts-inventory.md` and the plan checklist itself

- [x] **Step 1: Run the supported source and PG checks**

Run in dictionary: `uv run pytest tests -q`.

Run in LangMap: `python3 -m pytest scripts/dictionary/tests scripts/postgres/tests -q`.

Run the existing local smoke: `curl -fsS http://127.0.0.1:8788/api/v2/languages` and `curl -fsSI http://127.0.0.1:5173/`.

- [x] **Step 2: Verify repository cleanliness and forbidden artifacts**

Run: `git status --short` in both repositories; `git grep -n -- '*.jsonl'` is not a valid path scan, so use `find src bin tests -type f \( -name '*.jsonl' -o -name '*jsonl*' \)` and inspect only tracked results. Confirm no newly generated `csv/` archive was overwritten and no secret/database URL was committed. Metadata/catalog JSON and raw upstream JSON inputs are allowed; phrase JSON/JSONL outputs are not.

- [x] **Step 3: Mark the checklist complete and summarize residual risk**

Record the two repository commit IDs, the raw layout/command, PG integration result, and the pre-existing unrelated test failures. State that ignored raw payloads and ignored local PostgreSQL state are intentionally not committed.

## Implementation and verification result

- The UI source is now the flat `scripts/i18n/ui-locales.csv` wide table plus `ui-locales.manifest.json`; Web parsing, CSV generation, importer `--check`, and `npm run build` passed.
- The dictionary repo now has `raw/<source-key>/` input workspaces, a `dictionary-raw-export` dispatcher, direct canonical CSV adapters, and one wide CSV archive per Wikivoyage English→target locale. JSON/JSONL phrase bridges, duplicate legacy pipelines, and mapping bridge CLIs were removed; package/catalog metadata JSON remains where it is not phrase data.
- Tracked D1/SQLite schema, migrations, staging managers, and SQL-only i18n generators were removed. The active path is PostgreSQL schema/migrations plus canonical CSV import.
- Verification completed: dictionary `uv run pytest tests -q` (88 passed); LangMap importer/PG contract tests (`7 passed, 1 skipped`), opt-in local PostgreSQL integration (`1 passed`), focused backend schema tests (`8 passed`), and local API/Web smoke checks succeeded. The full backend Vitest suite still has 48 pre-existing integration failures when no seeded `DATABASE_URL` is supplied.
- The final commits are recorded after the last status and diff checks; ignored raw payloads and local database state remain uncommitted by design.
