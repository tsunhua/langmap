# 詞句翻譯（Expression Translation）實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `/translate` 提供登入後可用的「詞句翻譯」：`POST /api/v2/translate` 走「精確匹配快徑 → planner → 檢索 → generation」管線並以 NDJSON 串流，前端以獨立 fetch 客戶端呈現三階段進度與檢索證據，且舊 UI 翻譯工作台搬遷到 `/ui-translation`。

**Architecture:** 後端新增 `services/translation/`（types / validation / exactMatch / planner / retrieval / generation / orchestrator），route 只做邊界與 envelope；前端新增 `/translate` 頁面 + `useTranslationStream`（fetch + AbortController + NDJSON），把 `TranslateWorkbench` 更名為 `UiTranslationWorkbench` 並搬路由。

**Tech Stack:** Hono、Cloudflare Workers D1、Workers AI binding（`@cf/zai-org/glm-4.7-flash`）、Vue 3 `<script setup>`、Pinia、vue-i18n、Vitest。

---

## 決策（Decisions）

- **單一計畫、WHAT 為主**：本計畫描述每項任務的目標、檔案、契約與驗證重點（HOW 精簡），不再逐步驟貼完整程式碼。
- **Quota 本版不實作**：spec 9.6 的 server-side per-user counter（每 60 秒 3 次、每 UTC 日 30 次）本版依法略。不建 migration、不加 rate-limiting binding；route 不做計數與 429 回傳，但 API 型別與前端錯誤處理保留 429/`reset_at` 契約。**已知偏差**，列 Follow-up。
- **Workers AI binding 現在加入**：修改 `wrangler.jsonc` 新增 `ai` binding，並以 `wrangler types` 重生成 `worker-configuration.d.ts`。本機具權限可執行。
- **測試策略**：單元／route 測試一律用 fake D1（沿用 `backend/tests/votes.test.ts` 的 `fakeD1` pattern）+ mock AI 物件直接注入 `Env`，不觸發真實模型。整合測試（跑實機 `wrangler dev`）只測不會觸發 AI 的邊界路徑（auth / validation / locale 404 / 409）。
- **輸出路徑**：檢索、planner 碎片一律為暫態資料，不寫入 canonical 表；符合 ADR 0006。

## 里程碑總覽

| Phase | 內容 | 對應 spec |
| --- | --- | --- |
| 0 | 前置：AI binding、limits、翻譯型別 | §8, §9.6, §10 |
| 1 | 後端：validation / exactMatch / planner / retrieval / generation / orchestrator / route + 測試 | §8, §9, §13.1 |
| 2 | 前端：路由搬遷、串流 composable、頁面與元件、nav、contribute prefill + 測試 | §6, §7, §11, §13.2 |
| 3 | 驗證：build / test / 手動 viewport 檢查 | §13.2, §13.3 |

---

## Phase 0 — 前置

### Task 0.1：加入 Workers AI binding 並重生成型別

**Files:**
- Modify: `backend/wrangler.jsonc`
- Regenerate: `backend/worker-configuration.d.ts`（不手寫）

**WHAT:**
- 在 `wrangler.jsonc` 新增 `ai` binding：
  ```jsonc
  "ai": { "binding": "AI" }
  ```
- 執行 `cd backend && npm run types:check`（即 `wrangler types --include-runtime=false --check`）重新產生型別。確認 `__BaseEnv_Env` 含 `AI: Ai`。
- 測試不會用真實 token；整合測試只跑不觸 AI 路徑。不可把 secret/token 寫入 repo。

**驗證:** `cd backend && npm run types:check` 輸出含 `AI: Ai`；`grep -n "AI: Ai" backend/worker-configuration.d.ts` 命中。

**Commit:** `feat: add workers ai binding`

### Task 0.2：翻譯 limits 常數

**Files:**
- Modify: `backend/src/utils/limits.ts`
- Test: `backend/tests/limits.test.ts`（擴充）

**WHAT:**
- 新增常數並在各層使用：`MAX_TRANSLATION_GRAPHEMES=500`、`MAX_TRANSLATION_TEXT_BYTES=8192`、`MAX_TRANSLATION_BODY_BYTES=16384`、`MAX_PLANNER_SPANS=8`、`MAX_PREFIX_CANDIDATES_PER_ROOT=3`、`MAX_DIRECT_PATHS_PER_ROOT=3`、`MAX_EVIDENCE_TOTAL=24`、`MAX_ALTERNATIVES=2`、`MAX_EVIDENCE_SERIALIZED_BYTES=32768`、`MAX_TRANSLATION_OUTPUT_TOKENS=2048`、`PLANNER_TIMEOUT_MS=2500`、`RETRIEVAL_TIMEOUT_MS=2000`、`GENERATION_TIMEOUT_MS=9000`、`GENERATE_STAGE_DEADLINE_MS=6000`。
- 核准 pivot 清單（ISO 639-3）固定為常數：`eng cmn jpn spa fra deu por kor rus arb`。
- `tests/limits.test.ts` 新增一組 expect 檢查所有複數閾值；避免魔法數字散落。

**驗證:** `cd backend && npm test -- --run src/../tests/limits.test.ts`（等同 `npx vitest run tests/limits.test.ts`）通過。

**Commit:** `feat: define translation pipeline limits`

### Task 0.3：翻譯型別契約

**Files:**
- Create: `backend/src/services/translation/types.ts`

**WHAT:**
- 一次性 TypeScript 契約，對應 spec §8.2–§8.4：
  - `TranslationRequest`：`{ text, source_lang_code: string|null, source_locale_code: string|null, target_locale_code }`。
  - `SourceLanguageResult`：`{ code, confidence, candidates? }`。
  - `TranslationEvidence`：`{ source_text, target_text, target_locale_code, path_type: 'direct'|'two_hop', pivot_lang_code?, match_type: 'exact'|'prefix', source_markers: string[] }`（不帶內部整數 ID）；排序分數保留於服務內部，不進入此型別。
  - NDJSON 事件 union：`status`（`stage: 'analyzing'|'retrieving'|'generating'`、`mode: 'exact_lookup'|'assisted'`、`request_id`）、`source_language`、`source_confirmation_required`（`candidates`、`reason`）、`evidence`（`items`、`omitted_count`、`degraded`）、`translation_delta`（`text`）、`result`（`translation`、`alternatives`≤2、`source_lang_code`、`target_locale_code`、`evidence_present`、`model_only`、`resolution`、`generation_skipped`、`request_id`）、`error`（`code`、`retryable`、`retry_after_seconds?`、`reset_at?`）。
  - `TranslationResult`（exactMatch 與 generation 共用的主要結果形狀）與各服務的輸入輸出介面（`PlannerOutput`、`RetrievalOutput`、`GenerationOutput`）。
- 此檔案是所有後端任務的上游契約；後續任務不得各自另立型別名稱。

**驗證:** backend 目前無 `tsconfig.json`/`typescript` dep，`npx tsc --noEmit` 不可行；以檔案語法正確、vitest 相關測試可跑為準（後續 1.x 任務的型別正確性由各任務測試覆蓋）。

**Commit:** `feat: define translation pipeline types`

---

## Phase 1 — 後端

### Task 1.1：輸入驗證服務

**Files:**
- Create: `backend/src/services/translation/validation.ts`
- Test: `backend/tests/translationValidation.test.ts`

**WHAT:**
- 純函式驗證（不碰 DB 的）：
  - `countGraphemes(text)`：用 `Intl.Segmenter('en', { granularity: 'grapheme' })` 計數；≤500。
  - Text UTF-8 ≤8 KiB、body ≤16 KiB（route 的 bounded body reader 用）。
  - 拒絕空字串、NUL 與控制字元（允許 `\n`、`\r\n`、tab）；偵測 HTML tag 或 fenced Markdown → `PLAIN_TEXT_ONLY`，不清理。
  - 回傳結構化錯誤 code：`VALIDATION_FAILED` / `PLAIN_TEXT_ONLY`。
- 需要 DB 的檢查放 route 或獨立 registry helper：
  - `source_lang_code` 必須存在於 `languages.code`（`INVALID_LANG_CODE`）；`source_locale_code` 若給定必須存在且 `language_id` 對應，限制為 `source_lang_code` 的語言。
  - `target_locale_code` 必須精確存在於 `language_locales.code`（`TARGET_LOCALE_NOT_FOUND`），且其 language 不等於 source language 時視相容性（spec §8.2 最後）。
- 測試：grapheme 500/501、8 KiB 邊界、控制字元、HTML/Markdown、空值、NUL、source/target 查詢錯誤碼。

**驗證:** `cd backend && npx vitest run tests/translationValidation.test.ts`

**Commit:** `feat: validate translation request input`

### Task 1.2：精確匹配快徑

**Files:**
- Create: `backend/src/services/translation/exactMatch.ts`
- Test: `backend/tests/translationExactMatch.test.ts`

**WHAT:**
- `findExactTranslation(db, { canonicalText, sourceLangCode?, targetLocaleCode, limits })`：
  - 以 `canonicalizeExpressionText` 對完整輸入正規化（保留原始文字給 model path）。
  - 先查「source expression → target locale 的合格 direct edge」；沒有才查「source → 十個核准 pivot 之一 → target locale」的合格 two-hop。不查 prefix/片段/三跳/未核准 pivot（§9.2）。
  - Target expression 必須有 `expression_locale_links` 精確連到目標 locale；兩條 edge 都要過品質 predicate（score>0 或 ≥1 `expression_edge_sources` marker；集中於 service 常數）。
  - 排序：direct 優先、`match`（此處皆 exact）、edge score 降冪、provenance marker 數降冪、候選文字長度升冪、expression/edge id 升冪；前二不同 target text 作 alternatives。查詢總量 bounded，SQL 以 `LIMIT` 收斂。
  - source 未指定且跨 language 命中無法消歧 → 回 `source_confirmation_required`（不呼叫 AI）；單一 source language → `source_language` confidence=1。
- Route/orchestrator 呼叫此函式後若命中：送 `evidence` + `result`（`resolution=exact_lookup`、`generation_skipped=true`、`model_only=false`），不再進 planner/retrieval/generation。
- 測試（fake D1）：direct 命中（AI 呼叫計數為零）；two-hop 命中；片段 exact / prefix 命中不短路；無 target link / 品質不合格不短路；source ambiguity；排序與 alternatives 上限。

**驗證:** `cd backend && npx vitest run tests/translationExactMatch.test.ts`

**Commit:** `feat: exact translation fast path`

### Task 1.3：Planner

**Files:**
- Create: `backend/src/services/translation/planner.ts`
- Test: `backend/tests/translationPlanner.test.ts`

**WHAT:**
- `planTranslation(ai, { text, sourceLangCode?, sourceConfidenceThreshold=0.75, limits })`：以 `env.AI.run(model, prompt, { schema-driven JSON })` 的一次非串流呼叫取得 `{ source_lang_code, source_confidence, uncertain_spans[] }`。
- 回傳必須過手寫 type guard（不信任 JSON mode）：字串欄位型別、`uncertain_spans` 0–8 項、`start/end` 為 codepoint offset 且 `start<end`、`text` 等於輸入對應子字串、`reason ∈ {unknown_term, idiom, proper_noun, domain_term, context_ambiguity}`、`confidence ∈ 0..1`。重疊 span 合併、去重。
- 使用者指定 source 時 planner 只產 span，不覆蓋 code；source 未指定且 confidence<門檻 → 回 `source_confirmation_required`。
- invalid / timeout / parse error 不重試：source 已指定 → 回「僅完整輸入 root」fallback；source 也無法取得 → 標記 model-only（跳過檢索）。
- 測試：valid / invalid / timeout / 重疊錯位 span / source override / 低 confidence confirmation；invalid 不重試且仍可 model-only。

**驗證:** `cd backend && npx vitest run tests/translationPlanner.test.ts`

**Commit:** `feat: translation planner with schema guard`

### Task 1.4：檢索服務

**Files:**
- Create: `backend/src/services/translation/retrieval.ts`
- Test: `backend/tests/translationRetrieval.test.ts`

**WHAT:**
- `retrieveEvidence(db, { fullText, spans[], sourceLangCode, targetLocaleCode, limits })`：
  - 根集合：完整輸入永遠第一根；planner 有效 span 依出現順序加入，≤9 根。
  - 文字匹配：`canonicalizeExpressionText` exact；無 exact 才 prefix range fallback（每根最多 3 prefix root）；原始輸入給模型不改寫。
  - 語言限制：根 expression 語言=最終 source language；目標 expression 語言=target locale 的語言且有精確 `expression_locale_links`，無 exact locale link 不算證據。
  - direct 路徑先查（每根最多 3 條高排名 path）；不足才查 two-hop「source→pivot→target」，pivot 限十個 allowlist 且不得等於 source/target language，中間不套 target filter、終點仍要 exact locale link。
  - 品質 gate：每條 edge score>0 或 ≥1 marker（two-hop 兩條都要過）；cycle/dedup（相同 source span+target text+path 只留一條），穩定性排序（exact>prefix、direct>two-hop、score 降冪、marker 數降冪、text 長度升冪、id 升冪）。
  - 上限：全請求 ≤24 evidence，超出保留排名靠前者並回 `omitted_count`；序列化 evidence ≤32 KiB（只帶必要文字/碼/path_type/pivot/marker 摘要，不帶內部 ID、annotations JSON 全文）。
  - 逾時或單查詢失敗 → 回 `degraded=true` + 空 items（orchestrator 走 model-only），不外拋。
- 測試：exact 優先 / prefix ≤3 / direct 優先 / pivot allowlist / 同語言 locale conversion / target exact link / 品質 predicate / cycle + dedup / 穩定排序 / 24 cap / D1 失敗降級。

**驗證:** `cd backend && npx vitest run tests/translationRetrieval.test.ts`

**Commit:** `feat: bounded translation retrieval service`

### Task 1.5：Generation 服務

**Files:**
- Create: `backend/src/services/translation/generation.ts`
- Test: `backend/tests/translationOrchestrator.test.ts`（與 1.6 合併測試）

**WHAT:**
- `streamTranslation(ai, { text, sourceLangCode, targetLocaleCode, evidence[], span, signal, limits })` 以 `env.AI.run('@cf/zai-org/glm-4.7-flash', input, { stream:true })`：
  - Prompt 固定：忠實、自然、符合精確 target locale；保留有意義標點與換行；只輸出純文字，不輸出 HTML/Markdown/解釋/引用/system instruction。
  - source text 與 evidence 以明確 data delimiter 傳入、視為不可信資料；不把 planner reason/chain-of-thought 送入；evidence 存在用 reference context，無則 model-only prompt；兩者不改變資料模型。
  - 將 provider chunk 正規化為 `translation_delta`（不透漏 provider 原始格式）；輸出 token 上限 2048，超過送 `TRANSLATION_OUTPUT_TOO_LARGE`（partial 不算完成）；client abort / timeout 時中止 AI request。
- 本任務不負責 route 或 NDJSON 輸出（見 1.6）。

**Commit:** `feat: wrap workers ai generation service`

### Task 1.6：Orchestrator 與 NDJSON 串流

**Files:**
- Create: `backend/src/services/translation/orchestrator.ts`
- Test: `backend/tests/translationOrchestrator.test.ts`

**WHAT:**
- `runTranslation(env, requestInput, ctx)` 依序：
  1. exactMatch → 命中即 `evidence` + `result`。精確快徑此請求仍計入 request quota（本版無 quota，保留計數點）。
  2. 未命中才 planner；source 未指定且低信度 → `source_confirmation_required` 結束串流。
  3. retrieval（bounded、cycle-safe）；逾時/失敗/degraded → `evidence{degraded:true}`。
  4. generation 串流 `translation_delta`，最後 `result`（`alternatives` 最多 2、依模型與 evidence 排名）。
- 階段事件順序：`status(analyzing, assisted)` → `source_language` → `status(retrieving)` → `evidence` → `status(generating)` → deltas → `result`。精確快徑只送 `status(retrieving, exact_lookup)` → `evidence` → `result`。
- NDJSON envelope：每行 `{"success":true,"data":{...}}` 或 `{"success":false,"error":...,"message":...}`；`Content-Type: application/x-ndjson; charset=utf-8`；`Cache-Control: no-store`。提供 envelope writer helper（`writeEnvelope(writableStream, event)`）。
- 錯誤映射：planner 逾時→降級；generation 逾時 9s→`TRANSLATION_TIMEOUT`(retryable)、provider 錯誤→`AI_PROVIDER_FAILED`(retryable)、輸出過大→`TRANSLATION_OUTPUT_TOO_LARGE`、Workers AI 帳戶配額→`AI_DAILY_QUOTA_EXHAUSTED`(帶 `reset_at`)。串流建立後 HTTP 狀態不可改，以最後 error envelope 結束。
- 所有 timeout/abort promise 必須 await/處理；client disconnect 中止 generation。

**驗證:** `cd backend && npx vitest run tests/translationOrchestrator.test.ts`（mock AI：exact path 零 AI 呼叫、model-only generation、evidence-assisted generation、各錯誤碼、abort、timeout、NDJSON 順序與組裝）

**Commit:** `feat: translation orchestrator and ndjson stream`

### Task 1.7：Route 與註冊

**Files:**
- Create: `backend/src/routes/translation.ts`
- Modify: `backend/src/routes/index.ts`
- Test: `backend/tests/translationRoute.test.ts`、`backend/tests/translationIntegration.test.ts`

**WHAT:**
- `POST /api/v2/translate`：`requireAuth` → bounded body reader（16 KiB）→ validation（Task 1.1）→ 建立 `AbortController` request id → 依快徑或 assisted 送首個 `status` → 呼叫 orchestrator。route 不寫 SQL 圖遍歷或 provider prompt（§9.1）。
- 蓋 `Cache-Control: no-store`；未登入 401 `AUTH_REQUIRED` 不回任何翻譯內容。
- `routes/index.ts` 註冊 `/translate`。
- **Route 測試（mock Env，沿用 votes.test.ts pattern）：** auth 401、body >16 KiB、grapheme 501、plain-text、`INVALID_LANG_CODE`、`TARGET_LOCALE_NOT_FOUND`、`INVALID_LANGUAGE_LOCALE_CODE`、exact 命中回 envelope、generation 錯誤碼。
- **整合測試（實機 worker，僅不觸 AI 路徑）：** 未登入 401、空 body 400、500 grapheme 413/400、壞 locale 404、`PLAIN_TEXT_ONLY`。此測試不執行任何會呼叫 Workers AI 的請求。

**驗證:** `npx vitest run tests/translationRoute.test.ts`；`./dev.sh` 起 worker 後 `npx vitest run --no-file-parallelism --testTimeout=20000 tests/translationIntegration.test.ts`

**Commit:** `feat: expose /api/v2/translate route`

### Task 1.8：後端收尾

**WHAT:**
- 確認 `npm run types:check` 不含 hardcoded secret；`git diff --check` 通過。
- 全後端測試：`cd backend && npm test`（單元）與 `npm run test:integration`（實機 worker）。

**Commit:** 依需要以 `fix:`/`refactor:` 收合。

---

## Phase 2 — 前端

### Task 2.1：UI 翻譯工作台搬遷

**Files:**
- Move: `web/src/pages/TranslateWorkbench.vue` → `web/src/pages/UiTranslationWorkbench.vue`；`TranslateWorkbench.test.ts` → `UiTranslationWorkbench.test.ts`
- Modify: `web/src/router.ts`、`web/src/router.test.ts`

**WHAT:**
- Router：`/translate` 改掛新的 `ExpressionTranslation.vue`；`/ui-translation`、`/ui-translation/:code` 掛 `UiTranslationWorkbench.vue`；刪除舊 `/translate`、`/translate/:code` 兩條 route，不設 redirect（§11）。
- 頁面內部 import、i18n key（仍用既有 `translate` namespace）、localization API 契約不動；component 名稱與文字依語意調整（沿用原位、不重寫樣式）。
- `router.test.ts` 更新路徑斷言。
- **驗證:** `cd web && npm run build`；`cd web && npx vitest run src/router.test.ts src/pages/UiTranslationWorkbench.test.ts`

**Commit:** `refactor: move ui translation workbench to /ui-translation`

### Task 2.2：i18n namespace

**Files:**
- Modify: `web/src/locales/*`（zh-Hant 等既有檔）

**WHAT:**
- 新增獨立 `phraseTranslate` namespace（不與舊 `translate` key 混用）：表單 label、三階段進度、精確匹配、僅模型生成、檢索參考、參考譯法、取消/重試/複製/送入貢獻、各錯誤訊息、確認文字（AI 輔助）。
- 缺少譯文沿用現有 fallback 規則。
- **驗證:** 執行既有 i18n key 完整性測試（若無，至少 `npm run build` 通過且無缺 key 警告）。

**Commit:** `feat: add phraseTranslate i18n namespace`

### Task 2.3：串流 API 客戶端與 composable

**Files:**
- Create: `web/src/api/translation.ts`
- Create: `web/src/composables/useTranslationStream.ts`
- Test: `web/src/api/translation.test.ts`（型別/URL 組裝）

**WHAT:**
- `translation.ts`：型別與 `postTranslation(input, options)`，用 `fetch`（\(baseURL 沿用 `/api/v2`，Authorization header 帶 token）+ `AbortController`，不沿用 Axios 15s timeout。
- `useTranslationStream.ts`：解析 NDJSON；暴露 `request_id`、期別狀態、`translation` 累加、`evidence`、`alternatives`、`error`、`resetAt`；`submit()` / `cancel()`；以 request sequence 丟棄 stale stream（沿用 `useLatestRequest` 概念）。
- **驗證:** `cd web && npx vitest run src/api/translation.test.ts`

**Commit:** `feat: add translation stream client`

### Task 2.4：翻譯 UI 元件

**Files:**
- Create: `web/src/components/translation/TranslationForm.vue`
- Create: `web/src/components/translation/TranslationProgress.vue`
- Create: `web/src/components/translation/TranslationResult.vue`
- Create: `web/src/components/translation/EvidenceList.vue`

**WHAT:**
- `TranslationForm`：來源語言（自動偵測 + 可搜尋 language registry，選定以 code 覆蓋）/ target locale picker（可搜尋、分頁，限成功解析的 `language_locales`，不限 `ui_locales active`、沿用現有 picker 薄封裝）/ 單一 textarea（純文字、保留內部換行與標點、不小於 8 KiB、`0/500` grapheme 計數、超過即阻止提交）。送出/取消按鈕 ≥44px，驗證錯誤 inline + focusable 錯誤摘要。
- `TranslationProgress`：三階段可讀狀態文字（不依賴顏色）、`role="status"`/`aria-live="polite"`、失敗 `role="alert"`、尊重 `prefers-reduced-motion`。
- `TranslationResult`：delta 純文字顯示、複製/重試、`model_only` → 「僅模型生成」、精確匹配 → 「精確匹配」狀態（無 AI 輔助提示）、alternatives ≤2、顯示「送入貢獻」。
- `EvidenceList`：可展開，顯示 source/target 文字、`來源→目標` 或 `來源→pivot→目標` 路徑、match type 與來源標記摘要；不顯示內部整數 ID、不掛「LangMap 輔助」徽章。
- 全部沿用 atlas.css tokens；寬螢幕並排語言控制、小螢幕單欄；Grid/Flex 子項 `min-width:0`。

**驗證:** 元件級測試或頁面測試（見 2.5）覆蓋；構建通過。

**Commit:** `feat: add translation ui components`

### Task 2.5：ExpressionTranslation 頁面

**Files:**
- Create: `web/src/pages/ExpressionTranslation.vue`
- Create: `web/src/pages/ExpressionTranslation.test.ts`

**WHAT:**
- 組合表單、串流、結果、證據與貢獻 prefill；進度與結果不因 delta 改變主要佈局（預留證據區空間，避免 CLS）。
- Auth guard：未登入開啟 `/translate` → `/auth?return=%2Ftranslate`；登入後回跳且不把文字放 URL。鏡頭流程：匿名隱藏入口（見 2.6）。
- 送出前執行完整輸入精確快徑（合併進 stream：exact 命中只顯示檢索與結果，不進分析/生成）；stale stream 由 request sequence 丟棄。
- 結果流程：複製、重試、重新編輯；「送入貢獻」只帶主要 pair，透過記憶體 prefill（見 2.7）進 `/contribute`，不進 query string。
- 鍵盤可完成選擇/提交/取消/展開/送入貢獻；純文字輸出（不用 `v-html`）；375/768/1024/1440 手動檢查。
- 頁面測試：匿名隱藏、登入進入、grapheme counter、取消/stale、三階段進度、model-only vs evidence panel、copy/retry、alternatives ≤2、prefill 不進 URL、focus/ARIA。

**驗證:** `cd web && npx vitest run src/pages/ExpressionTranslation.test.ts`；`cd web && npm run build`

**Commit:** `feat: add expression translation page`

### Task 2.6：TopNav 詞句翻譯入口

**Files:**
- Modify: `web/src/components/nav/TopNav.vue`
- Modify: `web/src/components/nav/TopNav.test.ts`

**WHAT:**
- 桌面 `appnav` 與 mobile drawer 都新增「詞句翻譯」連結；只在 `auth.user` 存在時渲染（auth 尚未 hydration 時隱藏，避免匿名閃現）。舊工作台不新增公開 tab（§11）。
- 測試：匿名不渲染、登入後渲染、desktop/mobile 呈現、focus keydown 不受影響。

**驗證:** `cd web && npx vitest run src/components/nav/TopNav.test.ts`

**Commit:** `feat: add auth-gated phrase translate nav link`

### Task 2.7：Contribute 預填與確認文字

**Files:**
- Create: `web/src/stores/contributePrefill.ts`
- Modify: `web/src/pages/Contribute.vue`

**WHAT:**
- `contributePrefill.ts`（Pinia，session 內記憶體）：`{ source_locale_code?, lang_code, text, aiAssisted: boolean }`；`set()`/`consume()`（consume 後清空）。不放 localStorage/URL。
- `Contribute.vue` 讀取 prefill 填入一列（來源與目標兩行、可編輯），預設兩列即為該 pair；`aiAssisted=true` 時顯示「AI 輔助」確認文字；exact 匹配結果 `aiAssisted=false` 不顯示。送出邏輯（既有 `/contributions` clique）不變，alternatives 不送。
- 測試：prefill 填列、consume 清空、URL 不含原文/譯文、確認文字條件式顯示。

**驗證:** `cd web && npx vitest run src/pages/Contribute.test.ts`

**Commit:** `feat: prefill translate result into contribute flow`

### Task 2.8：前端收尾

**WHAT:**
- 全前端測試與 build：`cd web && npm run build`；相關 test 全綠。
- 手動 viewport（375/768/1024/1440）與鍵盤檢查；`git diff --check`。

**Commit:** 依需要 `fix:`/`refactor:` 收合。

---

## Phase 3 — 整合驗證

### Task 3.1：跨層驗證

**WHAT:**
- `./build.sh`（web → backend/public）完整通過。
- `cd backend && npm test` 與 `npm run test:integration`（實機 worker）通過。
- 手工 E2E：登入 → `/translate` 輸入有直接 mapping 的對照（exact 命中，不觸 AI）與無 mapping 的句子（assisted/model-only），確認三階段、證據、錯誤降級。
- stale stream / cancel、連續重送、離開頁面即丟棄暫態結果行為確認。

**Commit:** 若有修正，`fix:` 收合。

---

## 驗證與完成條件

- 對照 `docs/superpowers/specs/2026-09-14-expression-translation-design.md` §13 驗收清單過一遍；本計畫 Phase 0–3 任務務必建立對應測試。
- 已知非目標（spec §4）不得誤建表：無 translation 結果表、無 AI provenance、無 `/translate/:code` 舊工作台。
- **此計畫不含、且 beta flag 開啟前必須完成的項目列於 Follow-up**。

## Follow-up（非本次合併範圍，記錄於計畫與 spec checklist）

- [ ] **Quota counter**（spec §9.6）：D1 counter migration 或 rate-limiting binding；本版已法略，route 保留計數點。
- [ ] **p95 效能 benchmark harness 與固定 locale matrix fixture**（spec §13.3）：生產 beta flag 開啟前 gate；本版只建立單元/route 測試所需最小 fixture。
- [ ] 隱私政策與 release checklist（spec §4、§12）：確認部署未寫入 secret/完整內容/prompt。
- [ ] planner 門檻 0.75 與 generation output 2048 的 benchmark 校準。

實作後已知偏差 / 待補（記錄以供後續對齊）：

- [ ] **`source_confirmation_required.candidates` 目前為空陣列**：spec §8.3 期待事件帶可選語言候選，但 §9.3 planner schema 未輸出候選，plan Task 1.3 亦然。實作依 plan 送 `candidates: []`；前端確認流程需改以 language registry 讓使用者手選，或後續讓 planner 回傳候選（需 schema 與 benchmark 校準）。
- [ ] **`413 PAYLOAD_TOO_LARGE`**：body >16 KiB 的錯誤碼未列於 spec §8.4 表；實作採 413 `PAYLOAD_TOO_LARGE`。需回填 spec 或改碼。
- [ ] **首個 `status` 事件改由 orchestrator 發送**：spec §9.1.4 與 plan Task 1.7 原述「route 送首個 status」，實作改由 orchestrator 依 exact/assisted 決定並送（避免 route 需先探測快徑）。行為仍滿足「首事件為 status 且盡早送出」，但需同步 spec/plan 敘述。
- [ ] **整合測試（實機 worker）未於本環境執行**：AI binding 為 remote session，`wrangler dev` 在無 `CLOUDFLARE_API_TOKEN` 的非互動環境無法啟動，導致所有整合測試（含既有 auth/users smoke）無法跑；`translationIntegration.test.ts` 已撰寫但待在具 token 的環境執行。單元測試（含 route/orchestrator 等 143+）全數通過。
- [ ] **次要清理**：`utils/response.ts` 的 `notFoundCode` 參數語意易誤用（跨路由既有問題）；`RELATION_MASK` 等常數在 `exactMatch.ts`/`retrieval.ts` 重複；orchestrator `RunTranslationRequest.sourceLocaleCode` 目前未被消費。
- [ ] **精確匹配結果的貢獻按鈕**（前端，spec §6.3.5）：使用者裁示依 spec「預設不提供重複貢獻按鈕」實作，`resolution=exact_lookup` 時隱藏「送入貢獻」；spec 另一半「使用者改寫主要譯文後仍可進入貢獻流程」的可編輯譯文 UI 未實作，列為 follow-up（需在 `TranslationResult` 增加譯文編輯與 rewrite 狀態）。
- [ ] **Contribute prefill 形狀擴充**：plan Task 2.7 原列 `{ source_locale_code?, lang_code, text, aiAssisted }` 僅一側端點，無法建立兩列 mapping；實作擴充為同時帶 source/target 兩端點的 `{ sourceLangCode, sourceLocaleCode, sourceText, targetLangCode, targetLocaleCode, targetText, aiAssisted }`。需回填 plan。
- [ ] **前端施工順序調整**：Task 2.7（contribute prefill store）提前於 Task 2.5（頁面）執行，因頁面的「送入貢獻」需要該 store；Task 2.5 亦順帶修改 `Auth.vue` 支援登入後 `return` 回跳（plan Task 2.5 Files 未列但為 guard 所需）。
- [ ] **手動 viewport 與鍵盤檢查**（spec §7.2、§13.2）：375/768/1024/1440 與完整鍵盤流程未由 agent 實機檢查，待人工驗收。