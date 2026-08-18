# Morphological Form Edges Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 獨立星型形態邊連接變化形與辭書形，邊上掛可疊加登錄特徵；搜尋與詳情能從變化形看到原形對照，且不污染語義圖譜。

**Architecture:** 四張新表與 `expression_edges` 隔離。名稱走既有 expression mapping；抽出「依 `name_expression_id` 批次解析」供登錄表與語言名共用。寫入是 pairwise find-or-create + 特徵聯集。前端 Mapping Detail 另開形態區與原形對照條，圖譜只讀語義邊。

**Tech Stack:** Hono + TypeScript + D1；Vitest（fake D1 單測 + 需 worker 的整合測）；Vue 3 + Pinia + vue-i18n；Python seed 產 SQL（身份演算法對齊 `expressionIdentity.ts`）。

**Spec:** `docs/superpowers/specs/2026-08-18-morphological-form-edges-design.md`

## Global Constraints

- 不改 `expression_edges` 語意、完全圖批次、圖譜遍歷。
- 不改 `POST /contributions/batch`，不改 `apple/`。
- Split 不搬形態邊。形態邊不讚踩、不刪、不整組覆寫特徵。
- 不做 POS、派生、自動範式、Wiktionary 匯入。
- 特徵名稱不進 `web/src/locales`；區塊標題才走 vue-i18n。
- API `/api/v2`，`{ success, data?, error?, message? }`。形態端點不走 `paginated`。
- `GET /expressions/:id/form-edges` 的 `limit` clamp `[1, 50]`，預設 20，**每個方向各自計算**。
- schema 變更必須同時改 migration、`schema.sql`、migration-lock。
- 查詢穩定排序、有上限。不新增 `any`。前端經 `web/src/api/client.ts`。
- 單檔後端測試：`cd backend && npx vitest run tests/<file>.test.ts`。前端：`cd web && npm run build`。

---

## File Structure

| 檔案 | 動作 | 責任 |
|---|---|---|
| `backend/migrations/0020_morphological_form_edges.sql` | Create | DDL + 由 seed 腳本產生的登錄／名稱 SQL |
| `backend/schema.sql` | Modify | 等價 DROP + CREATE + seed；DROP 須先子表後父表 |
| `scripts/db/migration-lock.json` | Modify | 以 `sync` 更新，不手編 |
| `scripts/morphology/generate-form-feature-seed.py` | Create | 依 spec §6／§7.3 產出可重跑 SQL（id 對齊 runtime hash） |
| `scripts/morphology/names.json` | Create | 維度／特徵的五 locale 顯示名（內容逐字抄 spec §7.3） |
| `backend/src/types/morphology.ts` | Create | 列型別與 API DTO |
| `backend/src/services/localizedName.ts` | Modify | 抽出 `resolveNamesByExpressionIds` |
| `backend/src/services/morphology.ts` | Create | 登錄表讀取、形態邊寫入／讀取 |
| `backend/src/routes/morphology.ts` | Create | `GET /morphological-features` |
| `backend/src/routes/index.ts` | Modify | 註冊 `/morphological-features` |
| `backend/src/routes/expressions.ts` | Modify | `POST`／`GET /:id/form-edges` |
| `backend/src/services/expressions.ts` | Modify | search hit 批次附 `form_of` |
| `backend/tests/schemaContract.test.ts` | Modify | 四表契約 |
| `backend/tests/localizedName.test.ts` | Modify | 新解析入口 |
| `backend/tests/morphology.test.ts` | Create | service 單測 |
| `backend/tests/morphologyIntegration.test.ts` | Create | API、search、graph 隔離、split 不搬邊 |
| `web/src/api/morphology.ts` | Create | 登錄表與 form-edges 客戶端 |
| `web/src/api/expressions.ts` | Modify | search 型別含 `form_of` |
| `web/src/components/expression/ExpressionRow.vue` | Modify | 形態摘要行 |
| `web/src/components/mapping/MorphologyPanel.vue` | Create | 詞形區 + 原形對照 + 提交表單 |
| `web/src/pages/MappingDetail.vue` | Modify | 掛上面板，圖譜不變 |
| `web/src/pages/Search.vue` | Modify | 把 `form_of` 傳入 row |
| `web/src/locales/en.ts` | Modify | 區塊／表單鉻文案 |

不改：`web/src/pages/Contribute.vue`、`backend/src/routes/contributions.ts`、`backend/src/services/mappingGraph.ts`、`backend/src/services/splits.ts`。

---

### Task 1: Schema 0020 + 契約

**Files:** `backend/migrations/0020_morphological_form_edges.sql`（Create）、`backend/schema.sql`、`backend/tests/schemaContract.test.ts`、`scripts/db/migration-lock.json`

**Produces:** 四張表與三個索引，欄位／CHECK／UNIQUE／FK 逐字對齊 spec §5.1–§5.2。本 task 只建空表；登錄列在 Task 2 插入。

- [x] **Step 1:** 寫契約測試：四表存在；`morphological_dimensions`／`features` 的 `name_expression_id`、`sort_order` UNIQUE；`expression_form_edges` 的 `CHECK (form_id <> lemma_id)`、`CHECK (pair_low < pair_high)`、`UNIQUE (form_id, lemma_id)`、`UNIQUE (pair_low, pair_high)`；`expression_form_edge_features` 複合 PK；三個索引名存在。

- [x] **Step 2:** 跑測試，確認失敗。

- [x] **Step 3:** 寫 migration（`IF NOT EXISTS`、無 DROP）與 `schema.sql`（檔頭 DROP 順序：`expression_form_edge_features` → `expression_form_edges` → `morphological_features` → `morphological_dimensions`，且須在 `DROP expressions` 之前）。

- [x] **Step 4:** `cd scripts/db && ./manage.sh local rebuild && ./manage.sh local verify`；`cd backend && npx vitest run tests/schemaContract.test.ts`。過後 `sync` migration-lock。

---

### Task 2: 名稱與登錄表 seed

**Files:** `scripts/morphology/names.json`、`scripts/morphology/generate-form-feature-seed.py`、`0020` 與 `schema.sql`（插入產生的 SQL）

**Consumes:** spec §6 維度／特徵碼與 sort_order；§7.3 五欄顯示名。

**Produces:** 每個 code 的英文 expression（`name_expression_id`）、四個譯名 expression、locale 佐證、直接語義邊 `source='seed'`、登錄表列。可重跑，id 與 runtime `canonicalize + SHA-256[:16] + base32` 一致（對齊 `scripts/i18n/generate-i18n-sql.py`）。

- [x] **Step 1:** `names.json` 逐字抄 §7.3，鍵為 code，值為 `{ "eng-Latn-US", "cmn-Hans-CN", "cmn-Hant-TW", "jpn-Jpan-JP", "spa-Latn-ES" }`。

- [x] **Step 2:** 產生器輸出 `INSERT OR IGNORE`：expressions → attestations → edges（pair 字典序）→ dimensions → features。`created_by` NULL。英文 `text` 必須等於 §7.3 的 eng 欄。

- [x] **Step 3:** 將產出納入 0020 與 `schema.sql`。rebuild 後斷言：13 維度、§6 全部特徵、`plural` 的四語名稱 expression 與 `eng-Latn-US`／`cmn-Hans-CN`／`cmn-Hant-TW`／`jpn-Jpan-JP`／`spa-Latn-ES` 佐證都在。

---

### Task 3: 依 expression id 解析名稱 + 登錄表 API

**Files:** `backend/src/services/localizedName.ts`、`backend/tests/localizedName.test.ts`、`backend/src/types/morphology.ts`、`backend/src/services/morphology.ts`、`backend/src/routes/morphology.ts`、`backend/src/routes/index.ts`、`backend/tests/morphology.test.ts`、`backend/tests/morphologyIntegration.test.ts`

**Produces:**

```ts
resolveNamesByExpressionIds(db, ids: readonly string[], hints: LocaleHints)
  : Promise<Map<string, { name: string; name_en: string }>>
```

候選規則與回退與語言名相同（直接邊、locale attestation、`score >= 0`；primary → secondary → 英文 `text` → 呼叫端再退 `code`）。`IdentityKind` 不加 `'feature'`。

`listMorphologicalFeatures(db, hints)` 回 spec §8.1 形狀。`GET /api/v2/morphological-features` 公開，吃 `ui_locale`／`secondary_ui_locale`，無效 locale 忽略不 400。

- [x] **Step 1:** 單測：抽出的解析器對已知 `name_expression_id` 選對譯名；語言名舊測試仍過。

- [x] **Step 2:** 單測：`listMorphologicalFeatures` 維度／特徵順序、名稱解析、缺譯回退英文。

- [x] **Step 3:** 實作解析器重構與登錄表讀取；掛路由。

- [x] **Step 4:** 整合測：`plural` 在 `cmn-Hans-CN`→`复数`、`cmn-Hant-TW`→`複數`、`jpn-Jpan-JP`→`複数`、`spa-Latn-ES`→`plural`。

---

### Task 4: 形態邊寫入／讀取 API

**Files:** `backend/src/types/morphology.ts`、`backend/src/services/morphology.ts`、`backend/src/routes/expressions.ts`、`backend/tests/morphology.test.ts`、`backend/tests/morphologyIntegration.test.ts`

**Produces:**

```ts
createFormEdge(db, { formId, lemmaId, features?: string[], source, createdBy, hints })
getExpressionFormEdges(db, expressionId, { limit, hints })
```

契約（spec §8.2–§8.5）：

- `POST /expressions/:id/form-edges` 需登入；`:id` 是 form。
- 兩端必須已存在、同語言、非自己、無反向邊。
- `(form_id, lemma_id)` find-or-create；`pair_low`／`pair_high` 由 service 算。
- 省略 `features`：舊特徵不動，新建為空。有給則聯集；請求內去重；任一未知碼整筆拒絕。
- 新建 `201` + `created=true`，重用 `200` + `created=false`。
- POST 與 GET 都依 query locale 解析名稱。
- `GET` 回 `as_form`／`as_lemma`；`as_form` 依 `lemma.id ASC`；`as_lemma` 依最小 `(dimension.sort_order, feature.sort_order)`，無特徵置後，再 `form.id ASC`。
- `limit` 每向各自截斷，帶該向 `truncated`／`omitted_count`。
- 錯誤碼：`EXPRESSION_NOT_FOUND`、`FORM_EDGE_CROSS_LANGUAGE`、`FORM_EDGE_SELF`、`FORM_EDGE_MUTUAL`、`FORM_FEATURE_UNKNOWN`、`VALIDATION_FAILED`。Constraint 不外洩。
- 不提供從 lemma 一次張貼整張範式的端點。

- [x] **Step 1:** 單測覆蓋：成功、跨語言、自連、互指、find-or-create、聯集、未知特徵、空特徵、一 form 多 lemma、同一節點兼 form／lemma、雙向排序與分向 limit。

- [x] **Step 2:** 實作 service + route。

- [x] **Step 3:** 整合測走同一組案例（需 worker + rebuilt D1）。

---

### Task 5: 搜尋 `form_of` + 語義／split 隔離

**Files:** `backend/src/services/expressions.ts`、`backend/src/routes/expressions.ts`、既有 search／mappings／splits 測試、`backend/tests/morphologyIntegration.test.ts`

**Produces:** `GET /expressions/search` 每個 hit 帶 `form_of`（最多 3 個 lemma，`lemma_id ASC`）；無邊則 `[]`。當頁一次批次查，不逐列。字面 `LIKE` 不變。

隔離：建形態邊後，同一 root 的 mapping graph 節點／邊集合不變。Split 後形態邊仍指舊 expression id。不改 `mappingGraph.ts`、`splits.ts`。

- [x] **Step 1:** 搜尋單測／整合測：`gatas` 命中自己且 `form_of` 指向 `gato`；無邊為 `[]`。

- [x] **Step 2:** graph 隔離與 split 不搬邊的測試。

- [x] **Step 3:** 實作 search 附加欄位。

---

### Task 6: 前端搜尋摘要與 Mapping Detail 形態區

**Files:** `web/src/api/morphology.ts`、`web/src/api/expressions.ts`、`web/src/components/expression/ExpressionRow.vue`、`web/src/pages/Search.vue`、`web/src/components/mapping/MorphologyPanel.vue`、`web/src/pages/MappingDetail.vue`、`web/src/locales/en.ts`、相關 `*.test.ts`

**Produces:**

- API 客戶端：`listMorphologicalFeatures`、`getExpressionFormEdges(id, { limit: 50, ...hints })`、`createFormEdge`。
- 搜尋列在字面命中下顯示「{特徵名} ← {lemma}」；多 lemma 並列；無 `form_of` 不渲染；有 accessible name。
- Mapping Detail 圖譜／hop 控制不變。圖譜外加 `MorphologyPanel`：`as_form` 列表、`as_lemma` 按維度分組（空格不畫假格）、兩種角色都有則兩塊都顯示。
- 「原形的對照」：最多 3 個 lemma，各打既有 `getMappingGraph(lemmaId, 1)`；分組掛在各原形下；不得併入當前圖譜節點。超過 3 個連到該原形 mapping 頁。
- 登入後「標為變化形」：搜同語言既有 expression 當 lemma，核取 `GET /morphological-features`（依維度分組），一次一個 lemma。選擇器不硬編碼特徵碼。
- 形態讀取失敗只壞面板，頁面其餘可用。lemma 對照請求用 `AbortSignal`／request token。
- 鉻文案（`morphology.forms`、`morphology.lemmaMappings`、`morphology.markAsForm` 等）進 `en.ts`。觸控 ≥ 44px，可見 focus，範式另有列表替代。

- [x] **Step 1:** 型別與 API wrapper。

- [x] **Step 2:** ExpressionRow 摘要 + Search 傳值。

- [x] **Step 3:** MorphologyPanel + 掛進 MappingDetail；不改 graph model／layout。

- [x] **Step 4:** `cd web && npm run build`；補／改相關前端測試。

---

### Task 7: 全流程驗收

- [x] **Step 1:** `gato` + `gatas` → `{feminine, plural}` → 搜 `gatas` 見摘要 → mapping 頁形態區與原形對照有 `cat`（若已有語義邊）→ `gatas` 圖譜不含 `gato`／`cat`。

- [x] **Step 2:** 相關後端測試 + `cd web && npm run build`。跨前後端再 `./build.sh`。

- [x] **Step 3:** `git diff --check`；確認未改 `apple/`、`contributions.ts`、`mappingGraph.ts`、`splits.ts`。

---

## Spec coverage

| Spec | Task |
|---|---|
| §5 四表、索引、互指 UNIQUE | 1 |
| §6／§7 seed 與四語五 locale 名 | 2、3 |
| §7.1 共用解析器 | 3 |
| §8.1 登錄表 API | 3 |
| §8.2–§8.5 寫入／讀取／錯誤碼 | 4 |
| §8.4 search `form_of` | 5 |
| §8.6 split 不搬 | 5 |
| §9–§10 前端兩層、摘要、表單、上限 | 6 |
| §11–§12 驗收與非目標 | 7 |

## 刻意不在本計劃

匯入管線、刪邊、特徵覆寫、形態讚踩、Contribute 批次、圖譜第二種邊、POS、派生。
