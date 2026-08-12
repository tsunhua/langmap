# ISO 639-3 語言代碼重建整改 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修復 ISO 639-3 語言身份重建的資料一致性、API 相容、前端缺失與驗收門禁，使 `2026-08-11-language-code-redesign-design.md` 能按全棧規格正式驗收。

**Architecture:** 施工分為三個可獨立審核的階段：先以 D1 transaction batch 修正後端寫入不變量與安全邊界，再以明確 TypeScript API contract 將 Web 垂直切換到 Language／Language Locale／TEXT Expression ID，最後恢復未授權刪除的既有產品域並建立可重跑的全棧驗收門禁。每個階段保持 `/api/v2` envelope，先寫失敗測試再做最小修改，不加入舊 Glottolog／BCP 47 runtime alias。

**Tech Stack:** TypeScript、Hono、Cloudflare Workers、Cloudflare D1、Vitest、Vue 3 `<script setup>`、Pinia、vue-i18n、Tailwind／既有 scoped CSS、Python `unittest`。

## Global Constraints

- 施工權威是 `docs/superpowers/specs/2026-08-11-language-code-redesign-design.md`；舊語言模型文件只作歷史背景。
- Greenfield：不保存、不遷移既有 D1 資料，不新增 runtime alias 或 `language_profile_code` 相容層。
- API prefix 固定為 `/api/v2`，回應維持 `{ success, data?, error?, message? }`。
- `lang_code`、`script_code`、`region_code` 必須分別存在於 pinned ISO 639-3 individual、ISO 15924、ISO 3166-1 alpha-2 registry。
- Language Locale code 只能由後端 canonical builder 生成；前端 preview 只作展示。
- Expression identity 建立後不可修改；ID 與所有前端型別一律使用 `string`。
- Mapping pair 字典序 canonicalize、同 pair 唯一；Split 保留 edge ID、score 與 votes。
- 所有關聯寫入使用 prepared statements；需原子的多 statement 寫入使用 `D1Database.batch()`，不得用 `exec()` 拼接使用者輸入。Cloudflare D1 文件確認 batch 是 transaction，任一 statement 失敗會 rollback 整批。
- 所有查詢、圖遍歷、列表與 split 配置必須有穩定 tie-breaker、循環防護、去重與數量上限。
- 500 response 不回傳 exception、SQL、constraint 或 D1 原始訊息；詳細錯誤只寫 server log。
- 前端沿用 `web/src/assets/atlas.css` tokens、lucide 圖示、低圓角與既有視覺；不重新設計風格。
- 互動元件需支援鍵盤、可見 focus、accessible name；觸控目標至少 44px；圖譜與地圖保留完整文字列表。
- 不修改 `apple/`；不手動修改 `web/dist/`、`backend/public/`、`.wrangler/`。
- 不恢復 Glottolog、IANA subtag、Language Variety／Profile runtime 或 `scripts/v2/` 產物。

## Non-goals

- 不新增 sense entity、讀音 scheme registry、音檔、全球 place registry 或 locale 自動繼承。
- 不藉整改重構整套 UI、替換 CSS 系統或引入新狀態管理框架。
- 不恢復已刪除的舊語言建立 API；Language registry 維持唯讀，使用者只能建立 Language Locale。

## Target File Structure

### Backend domain boundaries

- `backend/src/services/provenance.ts`：唯一負責 source 解析與 NULL-safe provenance pair。
- `backend/src/services/expressions.ts`：Expression 建立／重用、locale attestation、detail 聚合。
- `backend/src/services/readings.ts`：reading 驗證、去重與 reading+attestation 原子 batch。
- `backend/src/services/votes.ts`：vote upsert 與 edge materialized score 原子同步。
- `backend/src/services/splits.ts`：split 驗證、audit、edge move、locale revision 同一 batch。
- `backend/src/services/localizationDomain.ts`：coverage、activation、bundle resolution、受影響 locale 收集。
- `backend/src/services/mappingGraph.ts`：以 TEXT Expression ID 作有限、穩定 BFS。
- `backend/src/routes/expressions.ts`：Expression REST adapter；不拼 domain SQL。
- `backend/src/routes/handbooks.ts`、`feed.ts`：保留既有產品域，改用新 Expression schema。
- `backend/src/utils/response.ts`：穩定錯誤碼與安全 500 helper。

### Frontend contract boundaries

- `web/src/api/languageIdentity.ts`：registry、Language Locale、Language content API 與型別。
- `web/src/api/expressions.ts`：Expression detail、graph、contribution、reading、attestation、split API。
- `web/src/api/localization.ts`：UI Locale、workbench、mapping、activation、bundle API。
- `web/src/api/preferences.ts`：`language.locales` 登入偏好 API。
- `web/src/utils/languageLocale.ts`：前端純展示 code preview 與 grammar；不作 server authority。
- `web/src/components/language/LanguagePicker.vue`：唯讀 ISO language combobox。
- `web/src/components/language/LanguageLocalePicker.vue`：既有 locale combobox，可開 create dialog。
- `web/src/components/language/LanguageLocaleCreateDialog.vue`：Language Locale structured form。
- `web/src/components/language/LanguageLocaleCodePreview.vue`：canonical preview。
- `web/src/stores/localization.ts`：primary／secondary preference、bundle 與 vue-i18n 套用。

## Phase Gates

1. **Backend integrity gate:** Tasks 1–4 完成後，backend unit tests 全過且所有新增 mutation 都有實際 D1 integration coverage。
2. **Contract preservation gate:** Task 5 完成後，handbook、feed、search 既有頁面不再因 route 移除而 404。
3. **Frontend cutover gate:** Tasks 6–9 完成後，`web/src` 不再出現 `language_profile_code`、Glottolog、Language Variety／Profile 或舊 localization endpoint。
4. **Release gate:** Task 10 的自動與人工驗收全部通過後，才更新規格狀態為已實作。

---

## Phase A — Backend integrity and safe contracts

### Task 1: NULL-safe provenance 與 Expression／Reading 原子寫入

**Files:**
- Create: `backend/src/services/provenance.ts`
- Create: `backend/tests/provenance.test.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/services/readings.ts`
- Modify: `backend/tests/expressions.test.ts`
- Modify: `backend/tests/expressionsIntegration.test.ts`
- Modify: `backend/tests/readings.test.ts`
- Modify: `backend/tests/readingsIntegration.test.ts`

**Interfaces:**
- Consumes: `findOrCreateSource(db, { type, name }): Promise<string>` from `backend/src/services/sources.ts`.
- Produces:

```ts
export interface SourceInput {
  type: string
  name: string
  ref?: string
}

export interface ResolvedProvenance {
  source_id: string | null
  source_ref: string | null
}

export const NULL_SAFE_PROVENANCE_PREDICATE =
  'source_id IS ? AND source_ref IS ?'

export async function resolveProvenance(
  db: D1Database,
  source?: SourceInput,
): Promise<ResolvedProvenance>
```

- `createExpression()` 保持既有 signature，但即使 `created === false`，提供 `language_locale_code` 時仍保證 attestation 存在。
- `createReading()` 保持既有 signature；新增 reading 與缺少的 attestation 必須在一個 `db.batch()` 內提交。

- [ ] **Step 1: 為 source 有值但 ref 為 NULL 的去重寫失敗測試**

在 `backend/tests/provenance.test.ts` 驗證解析結果，並在 `expressions.test.ts`、`readings.test.ts` 驗證查詢只使用一個 NULL-safe predicate：

```ts
it('represents a named source without a ref as a NULL-safe pair', async () => {
  const db = fakeD1({
    'SELECT id FROM sources WHERE type = ? AND name = ?': () => ({ id: 'src-dict' }),
  })

  await expect(resolveProvenance(db, {
    type: 'publication',
    name: 'Dictionary',
  })).resolves.toEqual({ source_id: 'src-dict', source_ref: null })
})

it('reuses sourced attestation when source_ref is null', async () => {
  const result = await createLocaleAttestation(db, {
    expression_id: 'nan:hash',
    language_locale_code: 'nan-Hant-TW',
    source: { type: 'publication', name: 'Dictionary' },
    created_by: 7,
  })
  expect(result).toMatchObject({ created: false, attestation: { id: 'att-existing' } })
})
```

- [ ] **Step 2: 執行精準測試並確認舊實作失敗**

Run:

```bash
cd backend
npm test -- provenance.test.ts expressions.test.ts readings.test.ts
```

Expected: FAIL；舊 SQL 使用 `source_ref = ?` 綁定 NULL，且 `provenance.ts` 尚不存在。

- [ ] **Step 3: 實作唯一 provenance resolver**

在 `backend/src/services/provenance.ts` 寫入：

```ts
import type { D1Database } from '@cloudflare/workers-types'
import { findOrCreateSource } from './sources'

export interface SourceInput {
  type: string
  name: string
  ref?: string
}

export interface ResolvedProvenance {
  source_id: string | null
  source_ref: string | null
}

export const NULL_SAFE_PROVENANCE_PREDICATE =
  'source_id IS ? AND source_ref IS ?'

export async function resolveProvenance(
  db: D1Database,
  source?: SourceInput,
): Promise<ResolvedProvenance> {
  if (!source) return { source_id: null, source_ref: null }
  const sourceId = await findOrCreateSource(db, source)
  const sourceRef = source.ref?.trim() || null
  return { source_id: sourceId, source_ref: sourceRef }
}
```

- [ ] **Step 4: 先驗證 optional locale，再以 NULL-safe 查詢建立或重用 Expression**

將 `createExpression()` 的順序固定為：canonicalize → registry 驗證 → optional locale existence 驗證 → hash lookup。既有 Expression 分支必須執行：

```ts
if (existing) {
  if (existing.text !== text) {
    throw new ExpressionError('EXPRESSION_HASH_COLLISION')
  }
  if (input.language_locale_code) {
    await createLocaleAttestation(db, {
      expression_id: existing.id,
      language_locale_code: input.language_locale_code,
      created_by: input.created_by,
    })
  }
  const expression = await loadExpressionById(db, existing.id)
  return { expression, created: false }
}
```

新 Expression 有 locale 時，先查重 attestation ID，然後將 Expression INSERT 與 attestation INSERT 放入同一 batch：

```ts
await db.batch([
  db.prepare(INSERT_EXPRESSION_SQL).bind(/* typed values */),
  db.prepare(INSERT_ATTESTATION_SQL).bind(
    attestationId,
    id,
    input.language_locale_code,
    input.created_by,
  ),
])
```

- [ ] **Step 5: 將 attestation 與 reading 查重統一為 `IS ?`**

兩個 service 均移除依 `sourceId` 分叉的 `= ?`／`IS NULL` SQL，改成：

```ts
const existing = await db.prepare(
  `SELECT ${COLUMNS}
   FROM expression_locale_attestations
   WHERE expression_id = ?
     AND language_locale_code = ?
     AND ${NULL_SAFE_PROVENANCE_PREDICATE}`,
).bind(
  input.expression_id,
  input.language_locale_code,
  provenance.source_id,
  provenance.source_ref,
).first<LocaleAttestationRow>()
```

Reading 使用相同 predicate，前置條件另含 `scheme` 與 trimmed `value`。

- [ ] **Step 6: 讓 reading 與缺少的 attestation 同 batch**

在任何寫入前完成 expression、locale、scheme、value、source 及 reading dedup 驗證。組成 statements：

```ts
const statements: D1PreparedStatement[] = []
if (!existingAttestation) {
  statements.push(db.prepare(INSERT_ATTESTATION_SQL).bind(
    attestationId,
    input.expression_id,
    input.language_locale_code,
    provenance.source_id,
    provenance.source_ref,
    input.created_by,
  ))
}
statements.push(db.prepare(INSERT_READING_SQL).bind(
  readingId,
  input.expression_id,
  input.language_locale_code,
  input.scheme,
  trimmedValue,
  provenance.source_id,
  provenance.source_ref,
  input.created_by,
))
await db.batch(statements)
```

- [ ] **Step 7: 增加真實 D1 regression cases**

在 integration tests 增加以下具名案例：

```ts
it('adds the requested locale when reusing a base expression', async () => {
  // POST base expression without locale, repeat with nan-Hant-TW,
  // then GET detail and assert exactly one matching attestation.
})

it('deduplicates a named source whose ref is omitted', async () => {
  // Repeat the same attestation and reading POST twice.
  // Both second responses return created=false and row counts stay at one.
})

it('rolls back the attestation when reading insertion fails', async () => {
  // Before the request, install a local-D1 trigger:
  // CREATE TRIGGER test_abort_reading BEFORE INSERT ON expression_readings
  // WHEN NEW.value = '__force_rollback__'
  // BEGIN SELECT RAISE(ABORT, 'forced reading failure'); END;
  // POST value='__force_rollback__', assert 500, then query that neither
  // the reading nor its matching attestation exists; drop the trigger in finally.
})
```

- [ ] **Step 8: 執行 Task 1 測試**

Run:

```bash
cd backend
npm test -- provenance.test.ts expressions.test.ts readings.test.ts
npm run test:integration -- expressionsIntegration.test.ts readingsIntegration.test.ts
```

Expected: unit 與 integration 全 PASS；重複提交不增加 row count。

- [ ] **Step 9: Commit**

```bash
git add backend/src/services/provenance.ts backend/src/services/expressions.ts backend/src/services/readings.ts backend/tests/provenance.test.ts backend/tests/expressions.test.ts backend/tests/expressionsIntegration.test.ts backend/tests/readings.test.ts backend/tests/readingsIntegration.test.ts
git commit -m "fix(api): make expression provenance writes atomic"
```

### Task 2: Vote score 同步與 Split 原子 revision 通知

**Files:**
- Modify: `backend/src/services/votes.ts`
- Modify: `backend/src/services/splits.ts`
- Modify: `backend/src/services/localizationDomain.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/tests/votes.test.ts`
- Modify: `backend/tests/localizationIntegration.test.ts`
- Modify: `backend/tests/splits.test.ts`
- Modify: `backend/tests/mappingsIntegration.test.ts`

**Interfaces:**
- Produces:

```ts
export async function listAffectedUiLocaleCodes(
  db: D1Database,
  projectId: string,
  expressionIds: readonly string[],
): Promise<string[]>

export function prepareRevisionBumps(
  db: D1Database,
  projectId: string,
  localeCodes: readonly string[],
): D1PreparedStatement[]
```

- `castVote()` 仍回 `{ score, user_vote }`，但 vote row 與 `expression_edges.score` 必須同 transaction。
- `splitExpression()` 收集 source、target 及所有 moved-edge opposite endpoint 的語言，並將 revision bump statements 加入同一 split batch。

- [ ] **Step 1: 寫 vote materialized score 失敗測試**

```ts
it('updates the edge score in the same batch as the vote', async () => {
  const db = recordingD1({ computedScore: 3 })
  const result = await castVote(db, {
    target_type: 'edge', target_id: 'e1', vote: 1, user_id: 7,
  })
  expect(db.batchSql).toEqual([
    expect.stringContaining('INSERT INTO votes'),
    expect.stringContaining('UPDATE expression_edges SET score'),
    expect.stringContaining('SELECT score FROM expression_edges'),
  ])
  expect(result.score).toBe(3)
})
```

- [ ] **Step 2: 寫 split affected-locale 與 rollback 失敗測試**

```ts
it('bumps revisions for source and every moved opposite endpoint language', async () => {
  // Move nan<->eng and nan<->jpn edges.
  // Assert the single split batch contains revision updates for
  // eng-Latn-US, jpn-Jpan-JP and nan-Hant-TW in code order.
})

it('does not commit split audit when a revision statement fails', async () => {
  // Force the last batch statement to reject and assert the service rejects;
  // integration verification asserts source edges and audit tables are unchanged.
})
```

- [ ] **Step 3: Run red tests**

```bash
cd backend
npm test -- votes.test.ts splits.test.ts localizationDomain.test.ts
```

Expected: FAIL；現有 vote 只更新 votes，split 在 batch 後才呼叫 `recalculateForExpressions()`。

- [ ] **Step 4: 將 vote 與 edge score 放入同一 D1 batch**

```ts
const updateScore = db.prepare(
  `UPDATE expression_edges
   SET score = (
     SELECT COALESCE(SUM(vote), 0)
     FROM votes
     WHERE target_type = 'edge' AND target_id = ?
   )
   WHERE id = ?`,
).bind(input.target_id, input.target_id)
const readScore = db.prepare(
  'SELECT score FROM expression_edges WHERE id = ?',
).bind(input.target_id)

const [, , scoreResult] = await db.batch([upsertVote, updateScore, readScore])
const score = Number(
  (scoreResult.results[0] as { score: number } | undefined)?.score ?? 0,
)
```

- [ ] **Step 5: 抽出穩定 affected-locale collector 與 revision statements**

`listAffectedUiLocaleCodes()` 先查 Expression `lang_code`，再查 project UI locale；結果去重並依 code 排序，保留 200 per-language 上限。`prepareRevisionBumps()` 只產生：

```sql
UPDATE ui_locales
SET mapping_revision = mapping_revision + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE project_id = ? AND language_locale_code = ?
```

Coverage 本身不落表，讀取時由 `computeCoverage()` 動態計算；Split 只會令 candidate 消失，不會令 draft 自動達 60%，因此 transaction 內不另做 activation。

- [ ] **Step 6: 將 split 所有寫入與 revision bump 合併為一個 batch**

```ts
const affectedExpressionIds = [
  input.source_expression_id,
  targetId,
  ...edges.map(edge =>
    edge.expression_a_id === input.source_expression_id
      ? edge.expression_b_id
      : edge.expression_a_id),
]
const localeCodes = await listAffectedUiLocaleCodes(
  db,
  input.project_id ?? 'langmap-web',
  affectedExpressionIds,
)
statements.push(...prepareRevisionBumps(
  db,
  input.project_id ?? 'langmap-web',
  localeCodes,
))
await db.batch(statements)
```

刪除 batch 之後的 `recalculateForExpressions()`；保留 UNIQUE conflict → `EXPRESSION_SPLIT_CONFLICT` 映射。

- [ ] **Step 7: 讓 vote 後的 activation 重算讀取已同步 score**

Route 保持先 `await castVote()`，再查 edge endpoints 並 `await recalculateForExpressions()`。新增 integration assertion：vote 將 score 從 `-1` 變 `0` 時，candidate 重新計入 coverage 且 draft 可於 60% 轉 active。

- [ ] **Step 8: Run Task 2 tests**

```bash
cd backend
npm test -- votes.test.ts splits.test.ts localizationDomain.test.ts
npm run test:integration -- localizationIntegration.test.ts mappingsIntegration.test.ts
```

Expected: 全 PASS；split failure 無 audit、target Expression 或 moved edge 殘留。

- [ ] **Step 9: Commit**

```bash
git add backend/src/services/votes.ts backend/src/services/splits.ts backend/src/services/localizationDomain.ts backend/src/routes/localization.ts backend/tests/votes.test.ts backend/tests/splits.test.ts backend/tests/localizationIntegration.test.ts backend/tests/mappingsIntegration.test.ts
git commit -m "fix(api): keep votes splits and locale revisions consistent"
```

### Task 3: 安全錯誤回應、router 命名與穩定排序

**Files:**
- Modify: `backend/src/utils/response.ts`
- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/routes/languageLocales.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/src/routes/contributions.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/tests/expressions.test.ts`
- Create: `backend/tests/errorResponses.test.ts`

**Interfaces:**
- Produces:

```ts
export function notFoundCode(
  c: Context,
  error: string,
  message: string,
): Response

export function internalError(c: Context): Response
```

- [ ] **Step 1: 寫不洩露 SQL 的 response 測試**

```ts
it('never serializes an internal exception message', async () => {
  const response = internalError(context)
  const body = await response.json()
  expect(body).toEqual({
    success: false,
    error: 'INTERNAL_SERVER_ERROR',
    message: 'Internal server error',
  })
  expect(JSON.stringify(body)).not.toContain('UNIQUE constraint failed')
})
```

- [ ] **Step 2: 寫同文 homograph 與同秒 attestation 的排序測試**

```ts
it('uses deterministic tie breakers for expression and attestation lists', () => {
  expect(EXPRESSION_PAGE_SQL).toContain(
    'ORDER BY text ASC, homograph_index ASC, id ASC',
  )
  expect(ATTESTATION_LIST_SQL).toContain(
    'ORDER BY language_locale_code ASC, created_at ASC, id ASC',
  )
})
```

- [ ] **Step 3: Run red tests**

```bash
cd backend
npm test -- errorResponses.test.ts expressions.test.ts
```

Expected: FAIL；500 helper 仍接受並回傳 exception message，排序缺 tie-breaker。

- [ ] **Step 4: 收緊 response helper**

```ts
export const notFoundCode = (
  c: Context,
  error: string,
  message: string,
) => c.json<ErrorResponse>({ success: false, error, message }, 404)

export const internalError = (c: Context) =>
  c.json<ErrorResponse>({
    success: false,
    error: 'INTERNAL_SERVER_ERROR',
    message: 'Internal server error',
  }, 500)
```

所有 catch 保留 `console.error()`，但只 `return internalError(c)`。穩定 domain 404 使用 `notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found')`。

- [ ] **Step 5: 修正 expressions router 名稱與 helper 使用**

```ts
const expressions = new Hono<{
  Bindings: Bindings
  Variables: Variables
}>()

expressions.get('/:id', async (c) => {
  const result = await getExpression(c.env.DB, c.req.param('id'))
  if (!result) {
    return notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found')
  }
  return success(c, result)
})

export default expressions
```

- [ ] **Step 6: 加入所有非唯一排序欄位的 tie-breaker**

至少修改：

```sql
ORDER BY text ASC, homograph_index ASC, id ASC
ORDER BY language_locale_code ASC, created_at ASC, id ASC
ORDER BY language_locale_code ASC, scheme ASC, created_at ASC, id ASC
```

- [ ] **Step 7: Run Task 3 tests**

```bash
cd backend
npm test -- errorResponses.test.ts expressions.test.ts
npm test
```

Expected: unit tests PASS；integration tests 若 Worker 未啟動可單獨留到 Task 10，不得把連線失敗記作功能通過。

- [ ] **Step 8: Commit**

```bash
git add backend/src/utils/response.ts backend/src/routes/expressions.ts backend/src/routes/languageLocales.ts backend/src/routes/localization.ts backend/src/routes/contributions.ts backend/src/services/expressions.ts backend/tests/errorResponses.test.ts backend/tests/expressions.test.ts
git commit -m "fix(api): harden errors and deterministic ordering"
```

### Task 4: TEXT Expression ID mapping graph 與 detail source/readings contract

**Files:**
- Create: `backend/src/services/mappingGraph.ts`
- Create: `backend/tests/mappingGraphV2.test.ts`
- Modify: `backend/src/services/mappings.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/types/expression.ts`
- Modify: `backend/src/types/mapping.ts`
- Modify: `backend/tests/expressionsIntegration.test.ts`
- Modify: `backend/tests/mappingsIntegration.test.ts`

**Interfaces:**
- Produces:

```ts
export interface MappingGraphNode {
  expression_id: string
  text: string
  lang_code: string
  language_name: string
  depth: number
}

export interface MappingGraphEdge {
  edge_id: string
  source_id: string
  target_id: string
  score: number
  depth: number
}

export interface MappingGraphResponse {
  root_id: string
  requested_hops: 1 | 2 | 3
  resolved_hops: 0 | 1 | 2 | 3
  nodes: MappingGraphNode[]
  edges: MappingGraphEdge[]
  layer_counts: Record<number, number>
  truncated: boolean
  omitted_count: number
}

export async function getMappingGraph(
  db: D1Database,
  rootId: string,
  hops: 1 | 2 | 3,
  nodeLimit?: number,
): Promise<MappingGraphResponse | null>
```

- Expression detail produces `{ expression, attestations, readings }`；attestation／reading row 同時回傳 `source: { id, type, name } | null` 與 `source_ref`。

- [ ] **Step 1: 寫 graph cycle、duplicate、limit、stable order 失敗測試**

```ts
it('traverses a cycle once and returns stable TEXT ids', async () => {
  const graph = await getMappingGraph(db, 'nan:root', 3, 200)
  expect(graph?.nodes.map(node => node.expression_id)).toEqual([
    'nan:root', 'eng:a', 'jpn:b',
  ])
  expect(new Set(graph?.edges.map(edge => edge.edge_id)).size)
    .toBe(graph?.edges.length)
})

it('sets truncated and omitted_count at the node limit', async () => {
  const graph = await getMappingGraph(db, 'nan:root', 3, 2)
  expect(graph).toMatchObject({ truncated: true, omitted_count: 1 })
})
```

- [ ] **Step 2: 寫 detail readings/source contract 失敗測試**

```ts
it('returns attestations and readings with stable source details', async () => {
  const response = await get('/api/v2/expressions/nan:hash')
  const body = await response.json()
  expect(body.data.readings[0]).toMatchObject({
    language_locale_code: 'nan-Hant-TW',
    scheme: 'ipa',
    source: { type: 'publication', name: 'Dictionary' },
  })
})
```

- [ ] **Step 3: Run red tests**

```bash
cd backend
npm test -- mappingGraphV2.test.ts expressions.test.ts
```

Expected: FAIL；`mappingGraph.ts` 尚不存在，detail 未讀 readings/source。

- [ ] **Step 4: 實作 bounded BFS**

每層只查目前 frontier，相鄰 edge 排序固定為 `score DESC, created_at ASC, id ASC`；frontier、nodes、edges 皆用 `Set<string>` 去重。Pseudo-code 必須落成同等控制流：

```ts
const visited = new Set<string>([rootId])
let frontier = [rootId]
for (let depth = 1; depth <= hops && frontier.length > 0; depth++) {
  const rows = await loadEdgesForFrontier(db, frontier)
  const next = new Set<string>()
  for (const row of rows) {
    addEdgeOnce(row, depth)
    const neighbor = oppositeEndpoint(row, frontier)
    if (!visited.has(neighbor) && visited.size < nodeLimit) {
      visited.add(neighbor)
      next.add(neighbor)
    } else if (!visited.has(neighbor)) {
      omitted.add(neighbor)
    }
  }
  frontier = [...next].sort()
}
```

- [ ] **Step 5: 將 mappings endpoint 切成 graph contract**

`GET /expressions/:id/mappings?hops=1|2|3` 呼叫 `getMappingGraph()`；未知 root 回 `EXPRESSION_NOT_FOUND` 404。直接 edge 列表保留為 `GET /expressions/:id/edges?limit=&offset=`，供 split picker 使用，避免一個 endpoint 同時有兩種 shape。

- [ ] **Step 6: 聚合 detail readings 與 source**

Query 明確使用：

```sql
LEFT JOIN sources s ON s.id = r.source_id
ORDER BY r.language_locale_code ASC,
         r.scheme ASC,
         r.created_at ASC,
         r.id ASC
```

Attestation 使用 `language_locale_code, created_at, id`。不把多份來源壓成 count；API 原樣保留每筆 provenance。

- [ ] **Step 7: Run Task 4 tests**

```bash
cd backend
npm test -- mappingGraphV2.test.ts mappings.test.ts expressions.test.ts
npm run test:integration -- mappingsIntegration.test.ts expressionsIntegration.test.ts
```

Expected: cycle、limit、stable ordering、detail readings/source 全 PASS。

- [ ] **Step 8: Commit**

```bash
git add backend/src/services/mappingGraph.ts backend/src/services/mappings.ts backend/src/services/expressions.ts backend/src/routes/expressions.ts backend/src/types/expression.ts backend/src/types/mapping.ts backend/tests/mappingGraphV2.test.ts backend/tests/expressionsIntegration.test.ts backend/tests/mappingsIntegration.test.ts
git commit -m "feat(api): expose stable text-id mapping graph"
```

## Phase B — Preserve product domains and cut over Web

### Task 5: 恢復 Handbook／Feed，將 Search 接到新 Expression API

**Files:**
- Create: `backend/migrations/0008_restore_handbooks.sql`
- Modify: `backend/schema.sql`
- Create: `backend/src/routes/handbooks.ts`
- Create: `backend/src/routes/feed.ts`
- Modify: `backend/src/routes/index.ts`
- Create: `backend/tests/handbooksIntegration.test.ts`
- Create: `backend/tests/feedIntegration.test.ts`
- Modify: `web/src/composables/useHandbooks.ts`
- Modify: `web/src/composables/useFeed.ts`
- Modify: `web/src/composables/useSearch.ts`
- Modify: `web/src/pages/HomeFeed.vue`
- Create: `web/src/pages/HomeFeed.test.ts`
- Modify: `web/src/pages/Search.vue`
- Create: `web/src/pages/Search.contract.test.ts`
- Modify: `web/src/pages/HandbookEdit.vue`
- Modify: `web/src/pages/HandbookView.vue`
- Modify: `web/src/components/expression/ExpressionRow.vue`
- Modify: `web/src/components/expression/ExpressionPicker.vue`
- Modify: `web/src/components/handbook/SectionEditor.vue`
- Modify: `web/src/components/handbook/HandbookExpressionInspector.vue`
- Modify: `web/src/components/handbook/HandbookRelationPreview.vue`

**Interfaces:**
- Handbook 與 section ID 改用 `TEXT` ULID，使 handbook、sections、items 可在執行前取得所有 ID 並放入同一 D1 batch；`handbook_section_items.expression_id` 是 `TEXT` FK。
- Handbook embedded expression shape：

```ts
interface HandbookExpression {
  id: string
  text: string
  lang_code: string
  language_name: string
  position: number
}
```

- Frontend search 改呼叫 `GET /expressions/search?q=&lang_code=&limit=&offset=`，不恢復 `/search/expressions` alias。

- [ ] **Step 1: 寫未受本規格刪除之產品域 regression tests**

```ts
it('creates and reads a handbook containing TEXT expression ids', async () => {
  const created = await post('/api/v2/handbooks', {
    title: 'Starter',
    sections: [{ title: 'One', expressionIds: ['nan:hash'] }],
  })
  const detail = await get(`/api/v2/handbooks/${created.data.id}`)
  expect(detail.data.sections[0].items[0]).toMatchObject({
    id: 'nan:hash', lang_code: 'nan',
  })
})

it('returns stable hot and new feed rows from expression_edges', async () => {
  const response = await get('/api/v2/feed/hot?limit=20')
  expect(response.data.items.map((item: { edge_id: string }) => item.edge_id))
    .toEqual([...response.data.items].sort(feedComparator).map(item => item.edge_id))
})

it('renders feed and search rows with TEXT ids and lang_code', async () => {
  mockFeed([{ edge_id: '01EDGE', expression_id: 'nan:hash', lang_code: 'nan' }])
  mockSearch({ items: [{ id: 'nan:hash', text: '食', lang_code: 'nan' }] })
  expect(homeFeed.text()).toContain('nan')
  expect(searchPage.text()).toContain('食')
  expect(searchPage.text()).not.toContain('undefined')
})
```

- [ ] **Step 2: Run red backend tests**

```bash
cd backend
npm run test:integration -- handbooksIntegration.test.ts feedIntegration.test.ts
```

Expected: FAIL 404；routes 與 handbook tables 不存在。

- [ ] **Step 3: 加回新 schema handbook tables**

Migration 與 `schema.sql` 使用相同 DDL：

```sql
CREATE TABLE handbooks (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  visibility TEXT NOT NULL DEFAULT 'public'
    CHECK (visibility IN ('public', 'private')),
  status TEXT NOT NULL DEFAULT 'published'
    CHECK (status IN ('draft', 'published')),
  score INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE handbook_sections (
  id TEXT PRIMARY KEY,
  handbook_id INTEGER NOT NULL,
  title TEXT,
  position INTEGER NOT NULL,
  FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE,
  UNIQUE (handbook_id, position)
);

CREATE TABLE handbook_section_items (
  section_id INTEGER NOT NULL,
  expression_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY (section_id, expression_id),
  UNIQUE (section_id, position),
  FOREIGN KEY (section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE,
  FOREIGN KEY (expression_id) REFERENCES expressions(id)
);
```

- [ ] **Step 4: 恢復 routes 並切到新欄位**

Handbook route 在組 statements 前用 `ulid()` 配置 handbook 與所有 section IDs；detail join 使用 `e.lang_code` 與 `languages.name_en`。Create 將 handbook、sections、items 放入單一 `db.batch()`；update 將 DELETE sections 與 replacement INSERTs 放入單一 batch，避免半本 handbook。Feed 只讀 `expression_edges` 和兩端 expressions，hot order 為 `score DESC, created_at DESC, id ASC`，new order 為 `created_at DESC, id ASC`，limit 1–100。

- [ ] **Step 5: 掛回 routes 並更新前端 TEXT ID**

```ts
api.route('/handbooks', handbooks)
api.route('/feed', feed)
```

所有 handbook component 的 handbook `id`、section `id`、`expression_id`、`expressionIds` 從 `number` 改 `string`；`ExpressionRow`、`ExpressionPicker`、Search 與 HomeFeed 同步消費 `id: string`、`lang_code` 與新 feed edge shape，完全刪除 `language_profile_code`。

- [ ] **Step 6: 將 search composable 直連新 endpoint**

```ts
const { data } = await api.get('/expressions/search', {
  params: {
    q,
    lang_code: params.lang,
    limit: params.limit,
    offset: params.offset,
  },
})
return data.data
```

- [ ] **Step 7: Run Task 5 tests**

```bash
cd backend
npm run test:integration -- handbooksIntegration.test.ts feedIntegration.test.ts
cd ../web
npm test -- HandbookView HandbookEdit HomeFeed.test.ts Search.contract.test.ts
npm run build
```

Expected: handbook/feed 不再 404；Web 無 handbook numeric-expression type error。

- [ ] **Step 8: Commit**

```bash
git add backend/migrations/0008_restore_handbooks.sql backend/schema.sql backend/src/routes/handbooks.ts backend/src/routes/feed.ts backend/src/routes/index.ts backend/tests/handbooksIntegration.test.ts backend/tests/feedIntegration.test.ts web/src/composables/useHandbooks.ts web/src/composables/useFeed.ts web/src/composables/useSearch.ts web/src/pages/HomeFeed.vue web/src/pages/HomeFeed.test.ts web/src/pages/Search.vue web/src/pages/Search.contract.test.ts web/src/pages/HandbookEdit.vue web/src/pages/HandbookView.vue web/src/components/expression/ExpressionRow.vue web/src/components/expression/ExpressionPicker.vue web/src/components/handbook/SectionEditor.vue web/src/components/handbook/HandbookExpressionInspector.vue web/src/components/handbook/HandbookRelationPreview.vue
git commit -m "fix(api): preserve handbook feed and search flows"
```

### Task 6: 建立 Web Language Identity API 與 Locale picker 元件

**Files:**
- Create: `web/src/api/languageIdentity.ts`
- Create: `web/src/api/languageIdentity.test.ts`
- Create: `web/src/utils/languageLocale.ts`
- Create: `web/src/utils/languageLocale.test.ts`
- Modify: `web/src/components/language/LanguagePicker.vue`
- Modify: `web/src/components/language/LanguagePicker.test.ts`
- Create: `web/src/components/language/LanguageLocalePicker.vue`
- Create: `web/src/components/language/LanguageLocalePicker.test.ts`
- Create: `web/src/components/language/LanguageLocaleCreateDialog.vue`
- Create: `web/src/components/language/LanguageLocaleCreateDialog.test.ts`
- Create: `web/src/components/language/LanguageLocaleCodePreview.vue`

**Interfaces:**
- Produces:

```ts
export interface Language { code: string; name_en: string }
export interface Script { code: string; name_en: string; direction: 'ltr' | 'rtl' }
export interface Region {
  code: string; name_en: string
  latitude: number | null; longitude: number | null
}
export interface LanguageLocale {
  code: string; lang_code: string; script_code: string; region_code: string
  place_path: string; name: string; name_en: string
  latitude: number | null; longitude: number | null
  coordinate_source?: 'locale' | 'region' | null
}
export interface Page<T> {
  items: T[]; total: number; skip: number; limit: number; hasMore: boolean
}
```

- `LanguagePicker v-model` 是 `lang_code`；不提供 create language。
- `LanguageLocalePicker v-model` 是完整 locale code；`langCode?: string` 可縮小查詢，`allowCreate` 控制 dialog。

- [ ] **Step 1: 寫 API endpoint shape 失敗測試**

```ts
it('queries ISO registries and language locales through v2 contracts', async () => {
  await listLanguages('nan')
  expect(api.get).toHaveBeenCalledWith('/language-registry/languages', {
    params: { q: 'nan', limit: 20, offset: 0 },
    signal: undefined,
  })
  await listLanguageLocales({ lang_code: 'nan', q: '', limit: 20, offset: 0 })
  expect(api.get).toHaveBeenLastCalledWith('/language-locales', expect.any(Object))
})
```

- [ ] **Step 2: 寫 canonical preview grammar 測試**

```ts
expect(previewLanguageLocaleCode({
  lang_code: 'nan', script_code: 'Hant', region_code: 'CN',
  place_segments: ['Quanzhou', 'Nanan'],
})).toBe('nan-Hant-CN_Quanzhou_Nanan')
expect(() => previewLanguageLocaleCode({
  lang_code: 'nan', script_code: 'Hant', region_code: 'CN',
  place_segments: ['New York'],
})).toThrow('INVALID_PLACE_SEGMENT')
```

- [ ] **Step 3: Run red tests**

```bash
cd web
npm test -- languageIdentity.test.ts languageLocale.test.ts LanguagePicker.test.ts LanguageLocalePicker.test.ts LanguageLocaleCreateDialog.test.ts
```

Expected: FAIL；新 API、helper、components 不存在。

- [ ] **Step 4: 實作 typed API**

`languageIdentity.ts` 只包含下列 calls：

```ts
listLanguages(q, limit, offset, signal)
listScripts(q, limit, offset, signal)
listRegions(q, limit, offset, signal)
listLanguageLocales(filters, signal)
getLanguageLocale(code, signal)
createLanguageLocale(payload)
listContentLanguages(filters, signal)
getLanguageDetail(code, signal)
listLanguageExpressions(code, filters, signal)
```

`createLanguageLocale()` payload 不接受 `code`：

```ts
export interface CreateLanguageLocaleInput {
  lang_code: string
  script_code: string
  region_code: string
  place_segments: string[]
  name: string
  name_en: string
  latitude?: number
  longitude?: number
  source?: { type: 'publication' | 'url'; name: string; ref?: string }
}
```

- [ ] **Step 5: 實作四個元件並保持可存取性**

Picker 使用 combobox/listbox、`aria-activedescendant`、ArrowUp/Down、Enter、Escape；create dialog 依 language → script → region → places → names/coordinates 排列。Preview component 只呼叫 `previewLanguageLocaleCode()`，submit 只採用 server 回傳 `data.code`。

- [ ] **Step 6: 將新 picker 自身與共用文案切離舊 runtime**

`LanguagePicker` 不再 import `LanguageCreateDialog` 或 `web/src/api/languages.ts`；新元件只 import `languageIdentity.ts`。加入 Language Locale 新文案，但暫時保留仍由 `LanguageList.vue` 使用的舊 dialog files，待 Task 7 消費方切換後刪除，確保本 Task 可獨立 build。執行：

```bash
rg -n "LanguageCreateDialog|@/api/languages" web/src/components/language/LanguagePicker.vue web/src/components/language/LanguageLocalePicker.vue web/src/components/language/LanguageLocaleCreateDialog.vue
```

Expected: 無命中；舊 files 仍存在但新元件不再依賴它們。

- [ ] **Step 7: Run Task 6 tests and build**

```bash
cd web
npm test -- languageIdentity.test.ts languageLocale.test.ts LanguagePicker.test.ts LanguageLocalePicker.test.ts LanguageLocaleCreateDialog.test.ts
npm run build
```

Expected: tests 與 TypeScript build PASS；dialog mobile control height ≥ 44px。

- [ ] **Step 8: Commit**

```bash
git add web/src/api/languageIdentity.ts web/src/api/languageIdentity.test.ts web/src/utils/languageLocale.ts web/src/utils/languageLocale.test.ts web/src/components/language/LanguagePicker.vue web/src/components/language/LanguagePicker.test.ts web/src/components/language/LanguageLocalePicker.vue web/src/components/language/LanguageLocalePicker.test.ts web/src/components/language/LanguageLocaleCreateDialog.vue web/src/components/language/LanguageLocaleCreateDialog.test.ts web/src/components/language/LanguageLocaleCodePreview.vue web/src/locales
git commit -m "feat(web): replace glottolog flow with language locales"
```

### Task 7: Contribution、Language pages 與 Map Lens 垂直切換

**Files:**
- Modify: `web/src/pages/Contribute.vue`
- Modify: `web/src/pages/Contribute.test.ts`
- Modify: `web/src/pages/LanguageList.vue`
- Modify: `web/src/pages/LanguageList.test.ts`
- Modify: `web/src/pages/LanguageDetail.vue`
- Create: `web/src/pages/LanguageDetail.test.ts`
- Modify: `web/src/pages/MapLens.vue`
- Create: `web/src/pages/MapLens.languageLocale.test.ts`
- Modify: `web/src/stores/languages.ts`
- Modify: `web/src/composables/useLanguages.ts`
- Modify: `web/src/components/language/LanguageCard.vue`
- Modify: `web/src/components/mapping/CliquePreview.vue`
- Delete: `web/src/components/language/LanguageTagBuilder.vue`
- Delete: `web/src/components/language/LanguageTagBuilder.test.ts`
- Delete: `web/src/components/language/LanguageSubtagSelect.vue`
- Delete: `web/src/components/language/LanguageSubtagSelect.test.ts`
- Delete: `web/src/components/language/GlottologMatchList.vue`
- Delete: `web/src/components/language/GlottologMatchList.test.ts`
- Delete: `web/src/components/language/LanguageMetadataForm.vue`
- Delete: `web/src/components/language/LanguageCreateDialog.vue`
- Delete: `web/src/components/language/LanguageCreateDialog.test.ts`
- Delete: `web/src/composables/useLanguageCreation.ts`
- Delete: `web/src/composables/useLanguageCreation.test.ts`

**Interfaces:**
- Contribution row：

```ts
interface ContributionRow {
  key: number
  lang_code: string
  language_locale_code?: string
  text: string
}
```

- POST body：

```ts
{ expressions: Array<{
  lang_code: string
  text: string
  language_locale_code?: string
}> }
```

- [ ] **Step 1: 寫 Contribution contract 與 input preservation 測試**

```ts
it('submits lang_code text and optional locale without tags', async () => {
  await fillRow(0, { lang: 'nan', locale: 'nan-Hant-TW', text: '食' })
  await fillRow(1, { lang: 'eng', text: 'eat' })
  await wrapper.get('[data-action="submit-contribution"]').trigger('click')
  expect(api.post).toHaveBeenCalledWith('/contributions/batch', {
    expressions: [
      { lang_code: 'nan', language_locale_code: 'nan-Hant-TW', text: '食' },
      { lang_code: 'eng', text: 'eat' },
    ],
  })
})

it('keeps every row after a failed batch', async () => {
  api.post.mockRejectedValueOnce(new Error('failed'))
  await submit()
  expect(readRows()).toEqual(rowsBeforeSubmit)
})
```

- [ ] **Step 2: 寫 Language detail／Map coordinate 測試**

```ts
it('renders locale region fallback and coordinate-less locales in the list', async () => {
  mockDetail({ locales: [
    { code: 'nan-Hant-TW', coordinate_source: 'region', latitude: 23.7, longitude: 121 },
    { code: 'nan-Hant-CN_Quanzhou', coordinate_source: null, latitude: null, longitude: null },
  ] })
  expect(wrapper.text()).toContain('nan-Hant-CN_Quanzhou')
  expect(wrapper.text()).toContain('Region representative point')
})
```

- [ ] **Step 3: Run red tests**

```bash
cd web
npm test -- Contribute.test.ts LanguageList.test.ts LanguageDetail.test.ts MapLens.languageLocale.test.ts
```

Expected: FAIL；舊 contribution 送 `lang/tags`，pages 仍依 Variety/Profile shape。

- [ ] **Step 4: 切換 Contribution**

每 row 放 `LanguagePicker` 與 optional `LanguageLocalePicker :lang-code="row.lang_code"`；locale picker 的 create result 回填該 row。`catch` 只設 error，不 reset `rows`。CliquePreview node label 使用 `lang_code`。

- [ ] **Step 5: 切換 Language List／Detail**

List 只呼叫 `/languages` content endpoint，不顯示完整 ISO registry；移除「建立語言」按鈕，改成可選的「建立 Language Locale」dialog 入口。Detail 顯示 `name_en`、`name`、expression/reading counts 與全部 locales；coordinate source 明示 `locale` 或 `region`。

- [ ] **Step 6: 切換 Map Lens 並保留文字替代**

Graph node 只讀 `lang_code`。對每個 graph language 從 language detail cache 取得 locales；marker 優先 locale coordinate，否則用 API 已標示的 region fallback。所有 locale（包括無座標）都進 `.map-lens-list`，marker popup 不使用未 escape 的 HTML 字串，改用 DOM textContent 或 Leaflet tooltip element。

- [ ] **Step 7: 刪除最後的舊建立流程與 API**

LanguageList、Contribution、LanguagePicker 等消費方都已切換後，刪除 Files 清單中的 Glottolog／subtag／variety files。更新所有 imports 後執行：

```bash
rg -n "Glottolog|LanguageTagBuilder|LanguageSubtagSelect|useLanguageCreation" web/src --glob '!pages/TranslateWorkbench.vue' --glob '!api/languages.ts' --glob '!api/languages.test.ts'
```

Expected: 無命中。`api/languages.ts` 暫留給尚未施工的 Workbench，於 Task 9 與最後一個 consumer 一起刪除。

- [ ] **Step 8: Run Task 7 tests and build**

```bash
cd web
npm test -- Contribute.test.ts LanguageList.test.ts LanguageDetail.test.ts MapLens.languageLocale.test.ts
npm run build
```

Expected: tests/build PASS；760px 以下 contribution 單欄，所有 controls ≥ 44px。

- [ ] **Step 9: Commit**

```bash
git add -A web/src/pages/Contribute.vue web/src/pages/Contribute.test.ts web/src/pages/LanguageList.vue web/src/pages/LanguageList.test.ts web/src/pages/LanguageDetail.vue web/src/pages/LanguageDetail.test.ts web/src/pages/MapLens.vue web/src/pages/MapLens.languageLocale.test.ts web/src/stores/languages.ts web/src/composables/useLanguages.ts web/src/components/language web/src/components/mapping/CliquePreview.vue web/src/composables/useLanguageCreation.ts web/src/composables/useLanguageCreation.test.ts web/src/locales
git commit -m "feat(web): migrate language content and contribution flows"
```

### Task 8: Mapping Detail TEXT ID、inspector 與 admin split flow

**Files:**
- Create: `web/src/api/expressions.ts`
- Create: `web/src/api/expressions.test.ts`
- Modify: `web/src/composables/useExpressions.ts`
- Modify: `web/src/pages/MappingDetail.vue`
- Modify: `web/src/pages/MappingDetail.language.test.ts`
- Modify: `web/src/components/mapping/mappingGraphTypes.ts`
- Modify: `web/src/components/mapping/mappingGraphModel.ts`
- Modify: `web/src/components/mapping/mappingGraphModel.test.ts`
- Modify: `web/src/components/mapping/mappingGraphLayout.ts`
- Modify: `web/src/components/mapping/mappingGraphLayout.test.ts`
- Modify: `web/src/components/mapping/MappingGraph.vue`
- Modify: `web/src/components/mapping/MappingHierarchyList.vue`
- Modify: `web/src/components/mapping/GraphInspector.vue`
- Modify: `web/src/components/mapping/GraphMobileInspector.vue`
- Create: `web/src/components/mapping/ExpressionEvidenceList.vue`
- Create: `web/src/components/mapping/ExpressionEvidenceList.test.ts`
- Create: `web/src/components/mapping/ExpressionSplitDialog.vue`
- Create: `web/src/components/mapping/ExpressionSplitDialog.test.ts`

**Interfaces:**
- 所有 graph/node route/type 的 ID 為 `string`；`route.params.id` 只 decode，不 `parseInt()`。
- `ExpressionEvidenceList` consumes `attestations`、`readings` from Task 4。
- `ExpressionSplitDialog` consumes direct edges from `/expressions/:id/edges`，produces `splitExpression(id, edgeIds)`。

- [ ] **Step 1: 寫 TEXT ID graph model 失敗測試**

```ts
const graph: MappingGraphResponse = {
  root_id: 'nan:root', requested_hops: 2, resolved_hops: 2,
  nodes: [
    { expression_id: 'nan:root', text: '食', lang_code: 'nan', language_name: 'Min Nan', depth: 0 },
    { expression_id: 'eng:eat', text: 'eat', lang_code: 'eng', language_name: 'English', depth: 1 },
  ],
  edges: [{ edge_id: '01EDGE', source_id: 'eng:eat', target_id: 'nan:root', score: 1, depth: 1 }],
  layer_counts: { 0: 1, 1: 1 }, truncated: false, omitted_count: 0,
}
expect(buildDisplayTree(graph).nodes.map(node => node.id))
  .toEqual(['nan:root', 'eng:eat'])
```

- [ ] **Step 2: 寫 evidence stable grouping 與 split warning 測試**

```ts
it('groups readings after locale attestations in stable order', () => {
  expect(renderedEvidenceCodes()).toEqual([
    'nan-Hant-CN', 'nan-Hant-TW', 'nan-Hant-TW / ipa',
  ])
})

it('requires an edge selection and displays the non-copy warning', async () => {
  expect(wrapper.text()).toContain(
    'Readings, locale attestations and handbook items will not be copied',
  )
  expect(wrapper.get('[data-action="confirm-split"]').attributes('disabled'))
    .toBeDefined()
})
```

- [ ] **Step 3: Run red tests**

```bash
cd web
npm test -- expressions.test.ts mappingGraphModel.test.ts mappingGraphLayout.test.ts MappingDetail.language.test.ts ExpressionEvidenceList.test.ts ExpressionSplitDialog.test.ts
```

Expected: FAIL；graph types 使用 number，evidence/split 元件不存在。

- [ ] **Step 4: 建立 expressions API adapter**

```ts
getExpression(id: string)
getMappingGraph(id: string, hops: 1 | 2 | 3)
getExpressionEdges(id: string, limit: number, offset: number)
createExpression(input)
createLocaleAttestation(id, input)
createReading(id, input)
splitExpression(id: string, edgeIds: string[])
submitContribution(expressions)
```

所有 path segment `encodeURIComponent()`；response 只在 adapter 解 envelope。

- [ ] **Step 5: 將 graph model/layout 全部改為 string ID**

數值減法 comparator 改為 `localeCompare()`：

```ts
if (a.source_id !== b.source_id) return a.source_id.localeCompare(b.source_id)
if (a.target_id !== b.target_id) return a.target_id.localeCompare(b.target_id)
return a.edge_id.localeCompare(b.edge_id)
```

Set、Map、selected/collapsed IDs 與 route query 都改 `string`。

- [ ] **Step 6: 接上 inspector evidence 與 split dialog**

Desktop、mobile inspector 共用 `ExpressionEvidenceList`，不複製 grouping logic。只有 `auth.user.role === 'admin'` 顯示 split action。成功後 navigation 到 `target_expression_id` 並重新載入 graph；失敗保留 edge selection。

- [ ] **Step 7: 驗證 list alternative**

`MappingHierarchyList` 必須包含每個 visible graph node、language、edge score；鍵盤可選 node 並同步 inspector。Mobile 預設 list，不將 graph 當唯一入口。

- [ ] **Step 8: Run Task 8 tests and build**

```bash
cd web
npm test -- expressions.test.ts mappingGraphModel.test.ts mappingGraphLayout.test.ts MappingDetail.language.test.ts ExpressionEvidenceList.test.ts ExpressionSplitDialog.test.ts MappingHierarchyList.test.ts
npm run build
```

Expected: 全 PASS；`rg -n "expression_id: number|source_id: number|target_id: number|language_profile_code" web/src/components/mapping web/src/pages/MappingDetail.vue` 無命中。

- [ ] **Step 9: Commit**

```bash
git add web/src/api/expressions.ts web/src/api/expressions.test.ts web/src/composables/useExpressions.ts web/src/pages/MappingDetail.vue web/src/pages/MappingDetail.language.test.ts web/src/components/mapping
git commit -m "feat(web): migrate mapping detail to expression text ids"
```

### Task 9: UI localization workbench 與 primary/secondary preference

**Files:**
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/tests/localizationIntegration.test.ts`
- Modify: `web/src/locales/index.ts`
- Modify: `web/src/api/localization.ts`
- Create: `web/src/api/localization.test.ts`
- Create: `web/src/api/preferences.ts`
- Create: `web/src/api/preferences.test.ts`
- Modify: `web/src/stores/localization.ts`
- Modify: `web/src/stores/localization.test.ts`
- Modify: `web/src/components/nav/LangSwitcher.vue`
- Create: `web/src/components/nav/LangSwitcher.test.ts`
- Modify: `web/src/pages/TranslateWorkbench.vue`
- Modify: `web/src/pages/TranslateWorkbench.language.test.ts`
- Delete: `web/src/api/languages.ts`
- Delete: `web/src/api/languages.test.ts`

**Interfaces:**
- Source locale 固定 `eng-Latn-US`。
- Preference：

```ts
export interface LanguageLocalePreference {
  primary: string
  secondary?: string
}
```

- Store produces：

```ts
primary: Ref<string>
secondary: Ref<string | undefined>
setPreferences(value: LanguageLocalePreference): Promise<void>
loadPreferences(): Promise<void>
loadBundle(): Promise<void>
```

- Workbench 只採信 backend 的 `coverage`, `translated`, `total`, `status`, `activation_source`；不得用 bundled English catalog 在 client 重算。

- [ ] **Step 1: 寫 localization API contract 失敗測試**

```ts
it('loads the resolved primary secondary bundle', async () => {
  await getUiMessages({ primary: 'nan-Hant-TW', secondary: 'cmn-Hant-TW' })
  expect(api.get).toHaveBeenCalledWith(
    '/localization/projects/langmap-web/messages',
    { params: { primary: 'nan-Hant-TW', secondary: 'cmn-Hant-TW' } },
  )
})

it('creates a draft locale using language_locale_code', async () => {
  await addUiLocale('nan-Hant-TW')
  expect(api.post).toHaveBeenCalledWith(
    '/localization/projects/langmap-web/locales',
    { language_locale_code: 'nan-Hant-TW' },
  )
})
```

- [ ] **Step 2: 寫 preference persistence 與 fallback 測試**

```ts
it('saves authenticated preferences to D1', async () => {
  auth.user = { id: 1, role: 'user', username: 'u' }
  await store.setPreferences({ primary: 'nan-Hant-TW', secondary: 'cmn-Hant-TW' })
  expect(putLanguageLocalePreference).toHaveBeenCalledWith({
    primary: 'nan-Hant-TW', secondary: 'cmn-Hant-TW',
  })
})

it('saves anonymous preferences to localStorage and rejects equal values', async () => {
  await expect(store.setPreferences({
    primary: 'nan-Hant-TW', secondary: 'nan-Hant-TW',
  })).rejects.toThrow('INVALID_LANGUAGE_PREFERENCE')
})
```

- [ ] **Step 3: 寫 workbench server-authority 測試**

```ts
it('renders backend coverage without recomputing from the bundled catalog', async () => {
  mockWorkbench({
    locale: { status: 'draft', activation_source: null },
    coverage: { coverage: 0.59, translated: 59, total: 100 },
    messages: [], total: 100, skip: 0, limit: 100,
  })
  expect(wrapper.text()).toContain('59%')
  expect(wrapper.text()).toContain('59 / 100')
})
```

- [ ] **Step 4: Run red tests**

```bash
cd web
npm test -- localization.test.ts preferences.test.ts stores/localization.test.ts LangSwitcher.test.ts TranslateWorkbench.language.test.ts
```

Expected: FAIL；舊 API path/body、單 locale store 與 client coverage 算法不符。

- [ ] **Step 5: 切換 locale constants 與 API adapters**

```ts
export const SOURCE_LOCALE = 'eng-Latn-US'
export const DEFAULT_LOCALE = SOURCE_LOCALE
```

刪除 BCP 47 parent fallback chain 與 Mandarin runtime alias；backend 已逐 key處理 primary → secondary → English。Backend locale list join `language_locales` 與 `scripts`，回傳 `language_locale_code`、`name`、`name_en`、`direction`、`status`、`mapping_revision`、`activation_source`；candidate Expression ID 為 string：

```sql
SELECT u.language_locale_code, l.name, l.name_en, s.direction,
       u.status, u.mapping_revision, u.activation_source
FROM ui_locales u
JOIN language_locales l ON l.code = u.language_locale_code
JOIN scripts s ON s.code = l.script_code
WHERE u.project_id = ?
ORDER BY u.language_locale_code ASC
LIMIT 200
```

- [ ] **Step 6: 實作 store 的登入／匿名偏好**

登入者 GET `/preferences`、PUT `/preferences/language.locales`；匿名者用 `langmap.language-locales` localStorage。每次 preference 變更重新 GET resolved bundle，把 `{ key, text }[]` 展開成 nested vue-i18n messages。`document.documentElement.dir` 使用 primary locale 的 script direction；`document.documentElement.lang` 使用 `primary.split('_')[0]`，避免把自訂 place path 當 HTML BCP 47 tag。

- [ ] **Step 7: 將 LangSwitcher 改成 primary + optional secondary**

兩個 `LanguageLocalePicker` 使用明確 label；secondary 提供 clear，保存前阻擋相同值。Trigger 與選項 desktop/mobile 均 ≥ 44px；Escape 恢復 trigger focus；不再依 `groupLocalesByVariety()` 或 BCP 47 base grouping。

- [ ] **Step 8: 切換 Workbench**

Locale picker 列出既有 Language Locales；選中後可 POST 建立 draft UI Locale。Translation submit 對每個 dirty key 依序：

```ts
const expression = await createExpression({
  lang_code: selectedLocale.lang_code,
  text: draft[key],
  language_locale_code: selectedLocale.code,
})
await submitTranslationMapping({
  message_key: key,
  target_expression_id: expression.expression.id,
})
```

Batch UI 可在 adapter 串行或後端 batch contract 完整驗證後使用；任何失敗保留 dirty draft。Admin 顯示 activate/archive；成功後重新 fetch workbench，讓 60% auto activation 狀態由 server 回傳。

Workbench 改用 Task 6 的 `languageIdentity.ts` 後，刪除最後的 `web/src/api/languages.ts` 與測試；確認 `rg -n "@/api/languages|language-registry/subtags|/languoids" web/src` 無命中。

- [ ] **Step 9: Run Task 9 tests and build**

```bash
cd web
npm test -- localization.test.ts preferences.test.ts stores/localization.test.ts LangSwitcher.test.ts TranslateWorkbench.language.test.ts
npm run build
```

Expected: 全 PASS；primary 缺 key 使用 secondary，secondary 缺 key使用 English source；fallback 不改 workbench coverage。

- [ ] **Step 10: Commit**

```bash
git add -A backend/src/routes/localization.ts backend/tests/localizationIntegration.test.ts web/src/locales/index.ts web/src/api/localization.ts web/src/api/localization.test.ts web/src/api/preferences.ts web/src/api/preferences.test.ts web/src/api/languages.ts web/src/api/languages.test.ts web/src/stores/localization.ts web/src/stores/localization.test.ts web/src/components/nav/LangSwitcher.vue web/src/components/nav/LangSwitcher.test.ts web/src/pages/TranslateWorkbench.vue web/src/pages/TranslateWorkbench.language.test.ts
git commit -m "feat(web): add language locale preferences and workbench"
```

## Phase C — Acceptance gates and release proof

### Task 10: 可重跑驗收、raw data whitespace policy 與規格狀態

**Files:**
- Create: `scripts/test_all.py`
- Create: `scripts/test_all_loader_test.py`
- Create: `.gitattributes`
- Create: `docs/superpowers/plans/2026-08-12-language-code-redesign-acceptance.md`
- Modify: `docs/superpowers/specs/2026-08-11-language-code-redesign-design.md`
- Modify: `AGENTS.md`

**Interfaces:**
- `python3 -m unittest discover scripts` 必須實際載入 `scripts/**/test*.py`，測試數不得為 0。
- `.gitattributes` 只豁免 pinned upstream `iso639-3.tab` 的 trailing-tab whitespace；其他 source/docs 仍由 `git diff --check` 阻擋。
- Acceptance record 固定記錄 commit SHA、命令、PASS count、人工 viewport 與九項人工情境。

- [ ] **Step 1: 寫 unittest loader meta-test**

`scripts/test_all_loader_test.py` 直接測 loader，不在 subprocess 中再次 discovery，避免自我遞迴：

```py
import unittest
from test_all import load_tests


class TestAllScripts(unittest.TestCase):
    def test_root_discovery_runs_real_tests(self) -> None:
        suite = load_tests(unittest.TestLoader(), unittest.TestSuite(), None)
        self.assertGreaterEqual(suite.countTestCases(), 76)


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 實作 recursive `load_tests`**

`scripts/test_all.py` 用 `importlib.util` 載入所有 descendant test files，避開 `language-reference` 不是合法 Python package name 的限制：

```py
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parent


def load_tests(
    loader: unittest.TestLoader,
    standard_tests: unittest.TestSuite,
    pattern: str | None,
) -> unittest.TestSuite:
    suite = unittest.TestSuite()
    for path in sorted(ROOT.rglob('test*.py')):
        if path in {Path(__file__), ROOT / 'test_all_loader_test.py'}:
            continue
        relative = str(path.relative_to(ROOT))
        name = 'langmap_script_test_' + re.sub(r'\W+', '_', relative)
        spec = spec_from_file_location(name, path)
        if spec is None or spec.loader is None:
            raise RuntimeError(f'Cannot import {path}')
        module = module_from_spec(spec)
        spec.loader.exec_module(module)
        suite.addTests(loader.loadTestsFromModule(module))
    return suite
```

- [ ] **Step 3: 為 pinned upstream whitespace 建立窄豁免**

`.gitattributes` 加入：

```gitattributes
scripts/language-reference/raw/iso639-3.tab whitespace=-trailing-space
```

驗證：

```bash
git check-attr whitespace -- scripts/language-reference/raw/iso639-3.tab
git diff --check d517707...HEAD
```

Expected: 第一個命令顯示 `whitespace: -trailing-space`；第二個命令無輸出。不得全域關閉 trailing whitespace 檢查。

- [ ] **Step 4: 啟動 fresh local D1 與 Worker**

Terminal A：

```bash
./dev.sh --rebuild
```

Expected: local bootstrap fingerprint、registry、system UI seed 完成；Web `:5173`、API `:8788` 可連線。

- [ ] **Step 5: 執行完整自動驗收**

Terminal B：

```bash
cd backend && npm test
cd ../web && npm test
cd ../web && npm run build
cd .. && python3 -m unittest discover scripts
./build.sh
git diff --check
```

Expected:

- Backend 24 個既有 test files 加 Tasks 1–5 新增 tests 全 PASS；不得以 `127.0.0.1:8788` 連線失敗代替結果。
- Web tests 全 PASS，`vue-tsc --noEmit` 與 Vite build PASS。
- Python output 的 test count 大於或等於目前分目錄總數 76。
- `./build.sh` PASS；`git diff --check` 無輸出。

- [ ] **Step 6: 執行 legacy runtime 靜態掃描**

```bash
rg -n "language_profile_code|language_profiles|language_varieties|languoids|Glottolog|language-registry/subtags|/languoids" backend/src web/src scripts --glob '!scripts/language-reference/raw/**'
```

Expected: 無 runtime 命中。歷史 docs 可保留，generated/raw 不納入 runtime scan。

- [ ] **Step 7: 執行九項人工驗收並記錄 evidence**

在 acceptance record 逐項寫 `PASS`、測試帳號、建立 ID 與觀察結果：

1. 建立 `nan-Hant-CN_Quanzhou_Nanan`。
2. 同一 Expression 加兩個 locales 與兩種 readings。
3. 三個 expressions batch contribution 建立 3 條 clique edges。
4. Admin split 選定 edges，edge IDs 與 votes 不變，evidence 未複製。
5. UI Locale coverage 由 59% 到 60% 自動 active。
6. Admin 手動 activate 未達門檻 locale，system source locale 無法 archive。
7. Primary 缺 key → secondary；再缺 → English；`resolved_from` 正確。
8. Map Lens 文字列表同時包含 locale coordinate、region fallback、無座標 locale。
9. 1440×900、768×1024、390×844 viewport 無橫向溢出；所有圖形操作有鍵盤列表入口。

- [ ] **Step 8: 更新文件狀態與操作入口**

只有 Steps 4–7 全 PASS 後，把規格 header 從「待實作」改為：

```md
> **狀態：已實作。** 驗收證據見 [2026-08-12-language-code-redesign-acceptance.md](../plans/2026-08-12-language-code-redesign-acceptance.md)。
```

同時將 `AGENTS.md` Domain 更新為 ISO 639-3 `expression.lang_code`、Language Locale、TEXT edge endpoints；把 Python 驗收命令保留為已修復的 `python3 -m unittest discover scripts`。

- [ ] **Step 9: Final diff review**

```bash
git status --short
git diff --stat
git diff --check
git diff -- docs/superpowers/specs/2026-08-11-language-code-redesign-design.md AGENTS.md
```

Expected: 只有本計劃內檔案；沒有 generated `web/dist/`、`backend/public/`、`.wrangler/` 或 secret。

- [ ] **Step 10: Commit**

```bash
git add .gitattributes AGENTS.md scripts/test_all.py scripts/test_all_loader_test.py docs/superpowers/specs/2026-08-11-language-code-redesign-design.md docs/superpowers/plans/2026-08-12-language-code-redesign-acceptance.md
git commit -m "test: enforce language redesign acceptance gates"
```

## Final Review Checklist

- [ ] Task 1：重用 Expression 仍建立 optional locale；named source/no-ref 可去重；reading+attestation 原子。
- [ ] Task 2：votes materialize 到 edge score；split、audit、moves、revision 同 batch；所有 opposite endpoints 通知到。
- [ ] Task 3：500 不洩露內部訊息；route 使用 response helpers；所有列表有唯一 tie-breaker。
- [ ] Task 4：mapping graph 使用 TEXT IDs，cycle/duplicate/limit/stable order 全覆蓋；detail 有 readings/source。
- [ ] Task 5：Handbook／Feed 可用；Search 使用正式 endpoint；沒有舊 language profile schema。
- [ ] Task 6：舊 Glottolog／BCP 47 create flow 已刪除；Language／Locale picker 與 preview 完成。
- [ ] Task 7：Contribution、Language pages、Map Lens 完成新 contract 與文字替代。
- [ ] Task 8：Mapping Detail、evidence、admin split、graph list alternative 完成。
- [ ] Task 9：Workbench 與 primary/secondary preference 由 server contract 驅動，fallback 不計 coverage。
- [ ] Task 10：完整自動與人工驗收有持久 evidence，規格只在全 PASS 後標記已實作。
