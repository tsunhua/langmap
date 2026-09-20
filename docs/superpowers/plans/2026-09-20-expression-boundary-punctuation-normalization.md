# Expression 邊界標點正規化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓所有未來 expression 寫入與語義查找共用一致的邊界標點、配對符號與全大寫句號正規化，並讓 dictionary CSV 匯入器與 registry seed 遵守相同契約。

**Architecture:** 在既有 TypeScript `expressionIdentity.ts` 與 Python `text_identity.py` identity seam 內實作同一套純正規化行為，以一份 JSON golden cases 驗證兩個 runtime。Backend 建立、搜尋與翻譯明確處理 identity error；stable text-key URL 保持 literal lookup。CSV 匯入器只對 expression cells 正規化，dictionary 的多值拆分仍留在 dictionary 專案。

**Tech Stack:** TypeScript、Vitest、Python 3、pytest、Hono、PostgreSQL CSV importer。

**Spec:** `docs/superpowers/specs/2026-09-20-expression-boundary-punctuation-normalization-design.md`

## Global Constraints

- 不清理、合併或遷移 PostgreSQL 既有 expressions。
- 不新增資料模型、migration、database function 或 trigger。
- 不在 LangMap 拆分 `/`、`／`、`|` 或其他多值格式。
- 不修改 reading、NOTE、source marker、mapping annotation、Web 或 Apple 客戶端。
- TypeScript 與 Python 對共用 golden cases 必須產生完全相同的結果或相同類型的驗證失敗。
- Stable text-key URL 保持 literal lookup，以相容未遷移的舊 expression。
- API 正規化失敗沿用 `VALIDATION_FAILED`，CSV 正規化失敗包含 row number 與 locale。
- 省略號 `…`、`……` 與三個以上連續 ASCII period 保留；全大寫文字保留邊界句號。

## File Map

- Create: `scripts/dictionary/tests/fixtures/expression_identity_cases.json` — 跨 runtime 行為契約。
- Modify: `scripts/dictionary/text_identity.py` — Python canonicalizer、錯誤型別與配對演算法。
- Create: `scripts/dictionary/tests/test_text_identity.py` — Python golden cases 與 delimiter tests。
- Modify: `backend/src/services/expressionIdentity.ts` — TypeScript canonicalizer 與錯誤型別。
- Modify: `backend/tests/expressionIdentity.test.ts` — TypeScript golden cases 與例外測試。
- Modify: `backend/src/services/expressions.ts`、`backend/src/routes/expressions.ts`、`backend/src/routes/translation.ts` — Backend error mapping and canonical lookup。
- Modify: `backend/tests/expressions.test.ts`、`backend/tests/expressionKeyRoutes.test.ts` — API identity and legacy-key tests。
- Modify: `scripts/dictionary/import_mapping_csv_pg.py` — expression cell canonicalization and source-position errors。
- Modify: `scripts/dictionary/tests/test_import_mapping_csv_pg.py` — CSV normalization, dedupe and failure tests。
- Modify only when generator output changes: `scripts/language-reference/artifacts/` and maintained morphology seed artifacts。

---

### Task 1: 建立跨 runtime golden cases 與 Python identity 行為

**Files:**
- Create: `scripts/dictionary/tests/fixtures/expression_identity_cases.json`
- Create: `scripts/dictionary/tests/test_text_identity.py`
- Modify: `scripts/dictionary/text_identity.py`

**Interfaces:**
- Consumes: Existing `canonicalize_expression_text(value: str) -> str` call sites in language reference and morphology generators.
- Produces: `ExpressionTextIdentityError` with code `UNBALANCED_DELIMITER`; the existing function returns a canonical string, returns `''` for empty output, and raises for an unbalanced non-lexical delimiter.

- [ ] **Step 1: Write the shared fixture and failing Python cases**

Create records with `name`, `input`, and exactly one of `output` or `error`. Include these core cases plus full／half-width variants, repeated marks, `……`, `3.14`, and a trailing unmatched bracket:

```json
[
  {"name":"trim_nfc","input":"  café  ","output":"Café"},
  {"name":"paired_cjk_quote","input":"「你好！」","output":"你好"},
  {"name":"orphan_leading_quote","input":"「你好！","output":"你好"},
  {"name":"orphan_trailing_quote","input":"你好！」","output":"你好"},
  {"name":"nested_wrappers","input":"。（「你好！」）。","output":"你好"},
  {"name":"internal_unbalanced_quote","input":"他說「你好","error":"UNBALANCED_DELIMITER"},
  {"name":"internal_unbalanced_parenthesis","input":"函數(x","error":"UNBALANCED_DELIMITER"},
  {"name":"balanced_internal_quote","input":"他說「你好」","output":"他說「你好」"},
  {"name":"lexical_apostrophe","input":"don't","output":"Don't"},
  {"name":"uppercase_periods","input":"U.S.A.","output":"U.S.A."},
  {"name":"uppercase_dotnet","input":".NET","output":".NET"},
  {"name":"uppercase_terminal_exclamation","input":"HELLO!","output":"HELLO"},
  {"name":"ellipsis_ascii","input":"等等...","output":"等等..."},
  {"name":"internal_slash","input":"台北／高雄","output":"台北／高雄"},
  {"name":"punctuation_only","input":"！！！","output":""}
]
```

Add `test_text_identity.py` to load the JSON, assert output records, assert `exc.value.code == 'UNBALANCED_DELIMITER'` for error records, and directly prove that `don't` does not count its apostrophe as a quote.

- [ ] **Step 2: Run the Python tests to verify failure**

Run `python3 -m pytest scripts/dictionary/tests/test_text_identity.py -q`.

Expected: FAIL because the new exception and punctuation behavior are not implemented.

- [ ] **Step 3: Implement the Python canonicalizer**

Add:

```python
class ExpressionTextIdentityError(ValueError):
    code = "UNBALANCED_DELIMITER"
```

Implement explicit delimiter tables and a loop that NFC-normalizes and trims; treats apostrophes between alphanumeric characters as lexical; removes complete outer pairs; removes only unmatched delimiter characters at the first or last position when the delimiter-family count is odd; removes allowlisted boundary marks while protecting `…`, `……`, and ASCII runs of three or more periods; validates remaining non-lexical delimiters; returns `''` for punctuation-only output; then applies the existing sentence-case logic. Do not use a broad Unicode `P*` regex.

- [ ] **Step 4: Run the Python tests to verify pass**

Run `python3 -m pytest scripts/dictionary/tests/test_text_identity.py -q`; expected: all new identity cases PASS.

- [ ] **Step 5: Run existing Python consumers and commit**

Run `python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py scripts/language-reference/test_generate.py -q`; expected: PASS. Then commit:

```bash
git add scripts/dictionary/text_identity.py scripts/dictionary/tests/test_text_identity.py scripts/dictionary/tests/fixtures/expression_identity_cases.json
git commit -m "feat: normalize expression boundary punctuation in Python"
```

### Task 2: 對齊 TypeScript identity 與 shared cases

**Files:**
- Modify: `backend/src/services/expressionIdentity.ts`
- Modify: `backend/tests/expressionIdentity.test.ts`
- Read: `scripts/dictionary/tests/fixtures/expression_identity_cases.json`

**Interfaces:**
- Consumes: Python fixture schema from Task 1 and existing `canonicalizeExpressionText` callers.
- Produces: `ExpressionIdentityError` with code `UNBALANCED_DELIMITER`; `canonicalizeExpressionText(input: string): string` returns `''` only when normalized content is empty.

- [ ] **Step 1: Add failing Vitest cases**

Load the shared JSON relative to the test module, run output cases through `canonicalizeExpressionText`, and assert error cases throw `ExpressionIdentityError` with `code === 'UNBALANCED_DELIMITER'`. Keep all existing prefix-bound tests and add explicit assertions for `「你好！」`, `他說「你好`, `U.S.A.`, `等等...`, `台北／高雄`, and `don't`.

- [ ] **Step 2: Run the focused TypeScript tests to verify failure**

Run `cd backend && npx vitest run tests/expressionIdentity.test.ts`; expected: new cases FAIL.

- [ ] **Step 3: Implement the TypeScript canonicalizer**

Export:

```ts
export class ExpressionIdentityError extends Error {
  readonly code = 'UNBALANCED_DELIMITER' as const;
  constructor() {
    super('UNBALANCED_DELIMITER');
    this.name = 'ExpressionIdentityError';
  }
}
```

Mirror the Python delimiter tables and loop in `expressionIdentity.ts`. Use `Array.from` for code-point-safe iteration, keep the existing sentence-case behavior after punctuation processing, and leave `expressionPrefixUpperBound` unchanged.

- [ ] **Step 4: Run the focused tests to verify pass and commit**

Run `cd backend && npx vitest run tests/expressionIdentity.test.ts`; expected: PASS. Then commit:

```bash
git add backend/src/services/expressionIdentity.ts backend/tests/expressionIdentity.test.ts
git commit -m "feat: normalize expression boundary punctuation in TypeScript"
```

### Task 3: 接通 Backend 建立、搜尋、翻譯與 legacy key

**Files:**
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/routes/translation.ts`
- Modify: `backend/tests/expressions.test.ts`
- Modify: `backend/tests/expressionKeyRoutes.test.ts`

**Interfaces:**
- Consumes: `canonicalizeExpressionText` and `ExpressionIdentityError` from Task 2.
- Produces: API `VALIDATION_FAILED` for empty or unbalanced create/search/translation input; literal stable-key resolution for legacy text.

- [ ] **Step 1: Write failing service and route tests**

Add assertions that `createExpression` inserts/query-binds `你好` for `「你好！」`, rejects `他說「你好` with `VALIDATION_FAILED`, and searches `q: '「你好！」'` through the canonical prefix. Add a route test that an invalid non-empty search query returns 400 `VALIDATION_FAILED` instead of the unfiltered list, a translation route test for the same error, and a key-route test that a legacy row with literal text `你好！` remains addressable.

- [ ] **Step 2: Run focused Backend tests to verify failure**

Run `cd backend && npx vitest run tests/expressions.test.ts tests/expressionKeyRoutes.test.ts`; expected: new assertions FAIL.

- [ ] **Step 3: Map identity errors at service and routes**

In `createExpression`, catch `ExpressionIdentityError` and throw `ExpressionError('VALIDATION_FAILED')` before language lookup or insert. In `searchExpressions`, distinguish an intentionally empty query from a non-empty query that canonicalizes to `''`; let identity errors reach the route, which returns `badRequest(c, 'VALIDATION_FAILED')`. In the translation route, wrap canonicalization and map identity errors or empty canonical text to the existing validation response before creating the stream. Do not call identity normalization from `parseExpressionKey` or `resolveExpressionKey`.

- [ ] **Step 4: Run focused and adjacent tests**

Run:

```bash
cd backend && npx vitest run tests/expressions.test.ts tests/expressionKeyRoutes.test.ts
cd backend && npx vitest run tests/translation*.test.ts tests/expressionIdentity.test.ts
```

Expected: all existing and new tests PASS.

- [ ] **Step 5: Commit Backend wiring**

```bash
git add backend/src/services/expressions.ts backend/src/routes/expressions.ts backend/src/routes/translation.ts backend/tests/expressions.test.ts backend/tests/expressionKeyRoutes.test.ts
git commit -m "feat: enforce expression identity validation at API boundaries"
```

### Task 4: 將 CSV expression cells 接到 Python identity

**Files:**
- Modify: `scripts/dictionary/import_mapping_csv_pg.py`
- Modify: `scripts/dictionary/tests/test_import_mapping_csv_pg.py`
- Inspect and modify only if an existing canonical-text assertion changes: `scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py`

**Interfaces:**
- Consumes: `canonicalize_expression_text` and `ExpressionTextIdentityError` from Task 1.
- Produces: canonical `Cell.text`, stable cell dedupe, and `CsvContractError` messages containing row number and locale for empty or unbalanced expression cells.

- [ ] **Step 1: Write failing CSV validation tests**

Add:

```python
def test_validate_normalizes_expression_cells_and_deduplicates(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "「Hello！」|Hello", "「你好！」"]])
    summary = validate(manifest)
    assert summary["expressions"] == 2
    assert summary["edges"] == 1

def test_validate_rejects_unbalanced_expression_cell_with_location(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "他說「你好", "hello"]])
    with pytest.raises(CsvContractError, match=r"row 2.*eng-Latn-US"):
        validate(manifest)

def test_validate_rejects_punctuation_only_expression_cell(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "！！！", "hello"]])
    with pytest.raises(CsvContractError, match=r"row 2.*eng-Latn-US"):
        validate(manifest)
```

Import `pytest`; keep whitespace-only cells absent, matching the existing CSV contract.

- [ ] **Step 2: Run the focused CSV tests to verify failure**

Run `python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q`; expected: new normalization and location assertions FAIL.

- [ ] **Step 3: Normalize only locale expression cells**

In `_read_csv`, keep `_canonical` for `ENTRY_ID`, `NOTE`, and readings. For each non-whitespace `LOCALE_*` raw value, call `canonicalize_expression_text`; convert `ExpressionTextIdentityError` into `CsvContractError(f"row {line_number} locale {locale.code}: {error.code}")`; reject a non-empty raw value whose canonical result is empty with the same row/locale context. Store canonical text in `Cell`, then apply existing per-locale stable dedupe. Because both `validate()` and `apply()` call `_read_csv`, check counts and PostgreSQL writes will use identical canonical cells.

- [ ] **Step 4: Run focused and integration tests**

Run:

```bash
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg.py -q
python3 -m pytest scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py -q
```

Expected: CSV contract, source snapshot synchronization, expression reuse, edge creation, readings, and source markers PASS.

- [ ] **Step 5: Commit CSV integration**

```bash
git add scripts/dictionary/import_mapping_csv_pg.py scripts/dictionary/tests/test_import_mapping_csv_pg.py scripts/dictionary/tests/test_import_mapping_csv_pg_integration.py
git commit -m "feat: normalize dictionary expression cells"
```

### Task 5: 驗證 generators、完整測試與交付

**Files:**
- Read and run: `scripts/language-reference/generate.py`, `scripts/language-reference/test_generate.py`, `scripts/morphology/generate-form-feature-seed.py`。
- Modify generated artifacts only when a maintained generator produces a deterministic expected diff。

**Interfaces:**
- Consumes: TypeScript and Python identity modules plus CSV behavior from Tasks 1–4。
- Produces: deterministic generated seed output and a verified implementation ready for review。

- [ ] **Step 1: Run registry and morphology checks**

Run:

```bash
python3 -m pytest scripts/language-reference/test_generate.py -q
python3 scripts/morphology/generate-form-feature-seed.py --help
```

Expected: registry artifacts remain byte-stable unless canonical input changes; morphology help exits successfully without writing the default artifact.

- [ ] **Step 2: Regenerate maintained artifacts only through generators**

Run the maintained commands exactly:

```bash
python3 scripts/language-reference/generate.py
python3 scripts/morphology/generate-form-feature-seed.py -o /tmp/langmap-morphology-seed.sql
git diff -- scripts/language-reference/artifacts scripts/morphology
```

Update tracked language-reference artifacts only when the diff contains the specified canonical text changes. The morphology command writes to `/tmp/langmap-morphology-seed.sql` because this repository does not track a default morphology SQL artifact; compare it with the SQL consumed by the deployment process before deciding whether any tracked seed needs updating. Never edit generated SQL by hand; re-run generator tests after an accepted artifact diff.

- [ ] **Step 3: Run complete targeted verification**

Run:

```bash
python3 -m pytest scripts/dictionary/tests scripts/language-reference -q
cd backend && npm test && cd ..
./build.sh
git diff --check
```

Expected: all relevant tests and build PASS. Any unrelated legacy failure is recorded with its exact command and failure, not reported as a pass.

- [ ] **Step 4: Inspect the final diff against the spec**

Confirm that the diff contains no PostgreSQL migration, schema change, existing-data cleanup, slash splitting, reading/NOTE mutation, Web change, or Apple change. Confirm stable text-key lookup remains literal and invalid search/translation input cannot fall through to an unfiltered or streamed operation.

- [ ] **Step 5: Record the final verification boundary**

If Step 2 produced an accepted deterministic language-reference artifact diff, commit only those exact generated files:

```bash
git add scripts/language-reference/artifacts/language-reference.sql scripts/language-reference/artifacts/manifest.json
git commit -m "chore: refresh generated expression seed"
```

If Step 2 produced no accepted generated diff, leave the four implementation commits intact and do not create an empty verification commit.
