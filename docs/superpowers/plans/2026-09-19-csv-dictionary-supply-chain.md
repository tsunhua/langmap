# CSV Dictionary Supply Chain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 `dictionary` repo 直接產生並保存 canonical CSV + manifest，並讓 LangMap 以跨平台 script 安全同步到 PostgreSQL。

**Architecture:** dictionary 的 shared exporter contract 與 source adapters 分離，所有 adapters 寫入同一 canonical CSV writer。LangMap importer 只驗證/同步 snapshot 到 PG，不了解個別字典 parser 或 JSONL。

**Tech Stack:** Python 3.12、uv、pytest、CSV、JSON manifest、psycopg、PostgreSQL。

**Spec:** `docs/superpowers/specs/2026-09-19-postgresql-csv-dictionary-design.md`

## Global Constraints

- `dictionary` repo 的 canonical artifact 是已提交 `csv/<source-key>/data.csv` 與 `manifest.json`；不再輸出 JSONL。
- Header 固定為 `ENTRY_ID,NOTE,LOCALE_<locale-code>...`，locale columns bytewise sorted。
- source-specific rules 不進 shared layer；跨至少兩 source 的規則才可提升。
- importer 不依賴 Homebrew、shell、`psql`、D1 或 SQLite。

---

### Task 1: 在 dictionary 建立 shared CSV contract

**Files:**
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/csv_contract.py`, `csv_writer.py`, `manifest.py`, `csv_cli.py`
- Modify: `/Users/lim/Documents/Code/tsunhua/dictionary/pyproject.toml`, `README.md`
- Test: `/Users/lim/Documents/Code/tsunhua/dictionary/tests/test_csv_contract.py`, `test_manifest.py`

**Produces:** `CanonicalEntry`/`LocaleMetadata` model、header lint、deterministic writer、checksum manifest 與 `dictionary-csv-export` CLI。

- [ ] **Step 1: 以 failing tests 固定 header、entry ID、cell canonicalization 與 stable output**
- [ ] **Step 2: 實作 shared model/writer/manifest；拒絕未知欄位、重複 ID 與未排序 locale columns**
- [ ] **Step 3: CLI 以 source profile 輸出 `csv/<source-key>/data.csv`、`manifest.json`；禁止 JSONL output flag**
- [ ] **Step 4: Run `cd /Users/lim/Documents/Code/tsunhua/dictionary && uv run pytest tests/test_csv_contract.py tests/test_manifest.py -q`**
- [ ] **Step 5: Commit: `feat(export): add canonical CSV contract`**

### Task 2: 分離 shared 與 source-specific exporter，逐源直出 CSV

**Files:**
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/src/dictionary_export/adapters/`
- Modify/Delete: `jsonl_pipeline.py`, `jsonl_models.py`, `jsonl_schema.py`, `jsonl_writer.py`, `jsonl_parsers/`, `*_jsonl.py`, `*_jsonl_cli.py`, mapping-csv-from-jsonl modules and tests
- Test: source fixtures plus per-source golden CSV tests

**Produces:** 每部受支援詞典由 adapter 產生 canonical entries；shared layer 不含 bundle/parser special cases。

- [ ] **Step 1: 為每個現有 source 建立 adapter inventory**

列出 raw input、locale metadata、授權、readings、現有 JSONL parser、預期 CSV archive；先處理仍要發布的 source，未支持者明確 retire。

- [ ] **Step 2: 為每個保留 source 寫 adapter → CanonicalEntry 與 golden CSV tests**

保持現有已驗證的 pronunciation/filtering rules；把任何 Apple HTML selector、Yomichan/Kautian/Jyutjyu/Hakka/Shanghai 特例限制在 adapter。

- [ ] **Step 3: 每 source 驗證後刪除相對應 JSONL module/CLI/test/doc**

不要保留 CSV-from-JSONL bridge；CSV 必須直接由 raw source export。

- [ ] **Step 4: Run `uv run pytest tests -q` and commit per coherent source family**

Commit format: `refactor(export): emit <source> CSV directly`

### Task 3: 提交 CSV archives 並完成 dictionary 文件

**Files:**
- Create: `/Users/lim/Documents/Code/tsunhua/dictionary/csv/<source-key>/data.csv`, `manifest.json`
- Modify: `/Users/lim/Documents/Code/tsunhua/dictionary/.gitignore`, `README.md`, `AGENTS.md`

**Produces:** 可 review、checksum-locked 的完整 CSV archives；新 contributor 能理解 adapter/shared boundary 和重匯出流程。

- [ ] **Step 1: 將每個 source CSV 寫到版本控制目錄，不再忽略 canonical artifacts**
- [ ] **Step 2: 逐 source 比較 entry count、locale columns、readings 與抽樣詞面；記錄驗收 summary**
- [ ] **Step 3: 將 README/AGENTS 改為 CSV workflow，刪除 `/Volumes/DATA/langmap-structured-jsonl`、D1 mirror 與 JSONL 指令**
- [ ] **Step 4: Commit: `data: add canonical dictionary CSV archives`**

### Task 4: 實作 LangMap 跨平台 CSV→PG importer

**Files:**
- Create: `scripts/dictionary/import_mapping_csv_pg.py`, `scripts/dictionary/csv_format.py`, `scripts/dictionary/requirements-pg.txt`
- Modify: `scripts/dictionary/README.md`
- Test: `scripts/dictionary/tests/test_import_mapping_csv_pg.py`
- Delete: `scripts/dictionary/import_mappings.py`, `export_mapping_csv_jsonl.py`, `export_mapping_csv_sql.py` and their tests (after replacement passes)

**Interfaces:**

```text
--manifest PATH --check | --apply
DATABASE_URL=postgresql://…
```

- [ ] **Step 1: Write PG integration tests for validate-only and transactional apply**

Cover checksum/header failure zero writes, registry creation, metadata conflict rollback, same-language/other-language pairs, no self edge, note ownership, idempotence, source-row deletion and cross-source preservation.

- [ ] **Step 2: Implement format validator and `psycopg` importer**

Use one transaction for `--apply`; resolve IDs only inside PG; ensure registry from manifest; produce sorted machine-readable summary. `--check` performs no writes.

- [ ] **Step 3: Implement source snapshot synchronization and orphan cleanup**

Every DELETE is scoped by `source_key`; preserve other source markers/annotations before deleting orphan rows. Add explicit failure when a source record conflicts with manifest identity.

- [ ] **Step 4: Replace LangMap dictionary documentation and delete bridges**

Document dependency installation cross-platform and the two commands only; remove SQL/JSONL/D1 instructions and retired tests.

- [ ] **Step 5: Verify and commit**

Run: `python -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q`

Commit: `feat(dictionary): import canonical CSV into PostgreSQL`

### Task 5: End-to-end source verification and final cleanup

**Files:**
- Modify: `docs/runbooks/scripts-inventory.md`, `scripts/dictionary/README.md`, `README.md`

- [ ] **Step 1: For each committed CSV archive, run `--check`, then import into a clean PG test database**
- [ ] **Step 2: Reapply each archive and verify unchanged summary; remove one fixture row and verify source-scoped synchronization**
- [ ] **Step 3: Run dictionary `uv run pytest tests -q`, LangMap importer tests, backend suite, and `git diff --check`**
- [ ] **Step 4: Update inventory to show removed JSONL/SQLite/D1 paths and retained CSV tools**
- [ ] **Step 5: Commit: `chore: retire JSONL dictionary pipeline`**
