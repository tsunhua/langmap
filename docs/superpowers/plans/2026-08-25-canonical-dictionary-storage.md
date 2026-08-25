# Canonical Integer Dictionary Storage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以單一、整數鍵、低索引開銷的 canonical D1 取代現有文字 ID、packed mirror 與 release／claim 模型，並完成可逐部匯入的 AI 高信心詞典流程。

**Architecture:** Fresh D1 直接建立最終 canonical schema；runtime 只讀寫 `expressions`、locale links、readings、edges 及必要的社群功能表，不設 compatibility layer。API 對外仍以 decimal string 表示 ID；離線匯入器負責 normalization、sense reconciliation、穩定配號、checkpoint 與 benchmark。

**Tech Stack:** Cloudflare D1／SQLite、Hono、TypeScript、Vue 3、Python 3.12、Vitest、pytest。

**Design spec:** [`docs/superpowers/specs/2026-08-25-expression-locale-storage-optimization.md`](../specs/2026-08-25-expression-locale-storage-optimization.md)

## Global Constraints

- 採 greenfield 重建；不搬移大型舊資料，不保留舊 expression／edge ID alias。
- D1 內部使用 integer ID；API 使用 decimal string ID，前端不得轉成 JavaScript `number`。
- 完全移除 runtime release、claim、binding、evidence、attestation audit 與 packed mirror。
- 定義與標籤不進線上 D1；例句是獨立 expression，使用 relation mask `4` 連接。
- `expressions.created_by`、`expression_edges.created_by` 保留為 integer user ID。
- 所有大型列表使用 cursor；不得使用深層 `OFFSET` 或 SQL temporary sort。
- Mapping graph 上限為 3 hops、200 nodes、每節點 50 neighbors，並支援 `target_language`。
- 詞典一次只處理一部，小詞典優先；每部完成後必須可立即查詢。
- 完整 canonical D1 必須低於 5 GiB；推算超過 4.5 GiB 即停止下一部匯入。
- Schema 變更必須同步 `backend/schema.sql`、migration、migration lock、契約測試與 API types。
- 執行期間保留使用者現有未提交修改；每個 commit 只包含該 task 的檔案。

## Plan Shape

本 spec 橫跨多個 subsystem，但 schema、API ID 與 importer 必須在同一次 greenfield cutover 對齊，因此使用一份主計畫。每個 task 描述「交付內容、契約、驗收」，只在容易走錯的地方保留必要 HOW。

| 順序 | 可驗收成果 | 依賴 |
| --- | --- | --- |
| 1 | 最終 schema、索引與 ADR | 無 |
| 2 | language／expression／locale／reading backend | Task 1 |
| 3 | mapping、cursor 與 graph backend | Task 2 |
| 4 | votes、handbooks 與 profile backend | Task 1–3 |
| 5 | morphology、split、localization 與 preferences backend | Task 1–3 |
| 6 | 移除 release／packed／feed runtime | Task 2–5 |
| 7 | 前端契約與頁面切換 | Task 2–6 |
| 8 | canonical 詞典匯入與 AI 高信心合併 | Task 1–3 |
| 9 | fresh rebuild、全流程與空間驗收 | Task 1–8 |

---

### Task 1: 建立最終 canonical schema 與索引契約

**Files:**

- Create: `backend/migrations/0039_canonical_integer_storage.sql`
- Create: `docs/adr/0005-canonical-integer-dictionary-storage.md`
- Modify: `backend/schema.sql`
- Modify: `scripts/db/migration-lock.json`
- Modify: `scripts/db/lib/verify.py`
- Modify: `scripts/language-reference/generate.py`
- Modify: `scripts/language-reference/artifacts/language-reference.sql`
- Modify: `scripts/morphology/generate-form-feature-seed.py`
- Modify: `docs/adr/0004-language-codes-redesigned-around-iso639-3.md`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `backend/tests/mappingQueryIndexes.test.ts`
- Modify: `scripts/language-reference/test_generate.py`
- Test: `scripts/db/tests/test_local_rebuild.py`
- Test: `scripts/db/tests/test_verify.py`

**Produces:** 可由空資料庫直接建立的唯一 schema baseline，以及與 spec 第 17 節完全一致的索引集合。

- [ ] 先把 spec 中所有 target tables、columns、FK、CHECK、`WITHOUT ROWID`、trigger 與 indexes 寫成 schema contract tests。
- [ ] 重寫 `backend/schema.sql`，建立 integer registry、canonical expression graph、split votes、handbooks、morphology、UI localization 與 preferences。
- [ ] 刪除 dictionary mirror、release／claim／binding／evidence、舊 attestations、generic votes、FTS 及 compatibility views。
- [ ] 依 spec 的 83-index 處置表重建必要索引；`sqlite_master` 不得出現已決定移除的 explicit index。
- [ ] 更新 language-reference 與 morphology seed generator，使所有 expression／locale FK 使用 fresh build 所配發的整數 ID；生成物必須可重現。
- [ ] 新增 destructive migration，限制為 disposable／明確授權環境；更新 migration lock。
- [ ] 新增 ADR 0005，並把 ADR 0004 標記為被取代；ADR 只記錄跨模組決策與取捨，不複製整份 spec。
- [ ] 驗證 schema 可重複建立、`PRAGMA foreign_key_check` 為空、`PRAGMA integrity_check` 為 `ok`。

**Acceptance commands:**

```bash
cd backend && npx vitest run tests/schemaContract.test.ts tests/mappingQueryIndexes.test.ts
python3 -m pytest scripts/language-reference/test_generate.py scripts/db/tests/test_local_rebuild.py scripts/db/tests/test_verify.py -q
```

**Commit:** `feat(db): establish canonical integer schema`

---

### Task 2: 切換 language、expression、locale 與 reading backend 契約

**Files:**

- Modify: `backend/src/utils/ids.ts`
- Modify: `backend/src/services/expressionIdentity.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/services/readings.ts`
- Modify: `backend/src/services/sources.ts`
- Modify: `backend/src/services/provenance.ts`
- Modify: `backend/src/services/languageIdentity.ts`
- Modify: `backend/src/services/languageContent.ts`
- Modify: `backend/src/services/localizedName.ts`
- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/routes/languageLocales.ts`
- Modify: `backend/src/routes/languageRegistry.ts`
- Modify: `backend/src/routes/languages.ts`
- Modify: `backend/src/types/expression.ts`
- Modify: `backend/src/types/language.ts`
- Modify: `backend/src/utils/response.ts`
- Modify: `backend/tests/expressionIdentity.test.ts`
- Modify: `backend/tests/expressionDetail.test.ts`
- Modify: `backend/tests/expressions.test.ts`
- Modify: `backend/tests/expressionsIntegration.test.ts`
- Modify: `backend/tests/readings.test.ts`
- Modify: `backend/tests/readingsIntegration.test.ts`
- Modify: `backend/tests/provenance.test.ts`
- Modify: `backend/tests/languageContent.test.ts`
- Modify: `backend/tests/languageLocales.test.ts`
- Modify: `backend/tests/languageLocalesIntegration.test.ts`
- Modify: `backend/tests/languagesIntegration.test.ts`

**Produces:** 只使用 canonical integer tables 的核心詞句 API。

**Required API contract:**

| Capability | Contract |
| --- | --- |
| ID parser | 正整數 decimal string；超過 safe integer 明確拒絕 |
| Expression identity | `(language_id, canonical_text, homograph_index)` |
| Expression detail | `expression`、`locales`、`readings`；沒有 `attestations` |
| Locale membership | `PUT/DELETE /api/v2/expressions/:id/locales/:localeCode` |
| Reading identity | `(expression_id, locale_id, scheme, value)`；沒有 reading ID |
| Search | 必須指定 language；只支援 exact／prefix |
| Language lists | `alpha`／`new` cursor；不返回 `total`、`skip` 或 hot sort |

- [ ] 以 `parseIntegerId()`／decimal serializer 取代 hash ID、ULID 與字串比較；D1 rows 使用 number，API DTO 使用 string。
- [ ] Expression create、detail、exact search、prefix search 與 language list 直接 join integer language／locale registry。
- [ ] 移除 `text_hash`、description、tags、review status、`source_ref`、updated time 的 runtime 讀寫與 response 欄位。
- [ ] Locale PUT 必須 idempotent；DELETE 只刪除指定 pair；兩者都驗證 locale 與 expression language 一致。
- [ ] Reading create 依複合 PK idempotent，保留單一 `source_id`，API 以內容鍵識別 row。
- [ ] `/languages/:code` 使用 reverse locale index 計算 locale 列表、count 與 filter；大型 expression list 不做每頁 `COUNT(*)`。
- [ ] Exact／prefix query 需有 `EXPLAIN QUERY PLAN` 測試，確認使用 expression identity index 且沒有 temporary sort。

**Acceptance commands:**

```bash
cd backend && npx vitest run tests/expressionIdentity.test.ts tests/expressionDetail.test.ts tests/expressions.test.ts tests/readings.test.ts tests/languageContent.test.ts tests/languageLocales.test.ts
```

**Commit:** `feat(api): adopt canonical expression storage`

---

### Task 3: 重建 mapping adjacency、cursor 與 graph

**Files:**

- Modify: `backend/src/services/mappings.ts`
- Modify: `backend/src/services/mappingGraph.ts`
- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/routes/contributions.ts`
- Modify: `backend/src/types/mapping.ts`
- Modify: `backend/tests/mappings.test.ts`
- Modify: `backend/tests/mappingsIntegration.test.ts`
- Modify: `backend/tests/mappingGraphV2.test.ts`
- Modify: `backend/tests/mappingQueryIndexes.test.ts`
- Modify: `backend/tests/contributionsIntegration.test.ts`

**Produces:** 僅依 pair unique 與 b-side index 運作、無 temporary sort 的 mapping backend。

**Required API contract:**

| Capability | Contract |
| --- | --- |
| Edge identity | integer ID；canonical pair `(a,b)` 且 `a < b` |
| Relation | `relation_mask` 以 bitwise OR 合併，合法值 `1..7` |
| Direct list | phase cursor：a-side `(expression_b_id)`，再 b-side `(edge_id)` |
| Graph | `hops=1..3`、200 nodes、50 neighbors/node、cycle safe |
| Language lens | optional `target_language`；root 與目標語言交替展開 |

- [ ] Edge create／batch create 移除 source 與 created time，保留 integer `created_by`；既有 pair 只更新 relation mask。
- [ ] Direct mapping list 改為兩階段 cursor，取消 `OFFSET`、總數查詢、score／time 排序及前端排序依賴。
- [ ] Graph traversal 以 bounded D1 batches 掃描兩方向 adjacency；達上限即停止並返回 `omitted_count`。
- [ ] `target_language` 只保留 root language 與指定語言，排除第三種語言與同語言 edge。
- [ ] Query-plan tests 必須證明 a-side 使用 pair unique、b-side 使用 `idx_expression_edges_b_id`，核心查詢沒有 `USE TEMP B-TREE`。
- [ ] 測試 relation OR、cursor 跨 phase、重複／循環、超級節點截斷與指定語言 graph。

**Acceptance commands:**

```bash
cd backend && npx vitest run tests/mappings.test.ts tests/mappingGraphV2.test.ts tests/mappingQueryIndexes.test.ts tests/contributionsIntegration.test.ts
```

**Commit:** `feat(mapping): use bounded indexed adjacency`

---

### Task 4: 拆分 votes，保留 handbook new／hot，移除活動列表

**Files:**

- Create: `backend/src/routes/mappings.ts`
- Modify: `backend/src/services/votes.ts`
- Modify: `backend/src/routes/index.ts`
- Modify: `backend/src/routes/handbooks.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/src/routes/users.ts`
- Modify: `backend/tests/votes.test.ts`
- Modify: `backend/tests/handbooks.test.ts`
- Modify: `backend/tests/localizationIntegration.test.ts`
- Modify: `backend/tests/users.test.ts`

**Produces:** `edge_votes`、`handbook_votes` 與 cached scores；handbook new／hot 保持可用，profile 不再載入 activity。

- [ ] 固定投票端點為 `POST /api/v2/mappings/:id/vote` 與 `POST /api/v2/handbooks/:id/vote`；body 使用 `{ direction: "up" | "down" }`，再次送出同方向表示取消。
- [ ] Edge vote 與 handbook vote 都支援新增、取消、`1 ↔ -1` 切換；不建立 vote ID 或時間欄位。
- [ ] Vote row 與 cached score 在同一 D1 batch 更新；提供全表 reconciliation query 供測試與維護。
- [ ] Localization workbench 的 edge vote 改用 `edge_votes`，完成後只重算受影響的 expression mappings。
- [ ] Handbook ID 與 locale FK 改為 integer；列表只保留 `new` 與由 votes 驅動的 `hot`。
- [ ] Handbook new／hot 使用各自的 cursor 與既定索引順序，不使用 `OFFSET` 或 temporary sort。
- [ ] Handbook sections／items 使用 spec 定義的 integer FK、position keys 與 indexes。
- [ ] `/users/me` 只返回 user；刪除 activity union、activity response 與其索引依賴。
- [ ] 測試 cached score reconciliation、handbook visibility、new／hot order、vote toggle 與無 activity response。

**Acceptance commands:**

```bash
cd backend && npx vitest run tests/votes.test.ts tests/handbooks.test.ts tests/localizationIntegration.test.ts tests/users.test.ts
```

**Commit:** `feat(community): compact votes and handbook ranking`

---

### Task 5: 對齊 morphology、split undo、localization 與 preferences

**Files:**

- Modify: `backend/src/services/morphology.ts`
- Modify: `backend/src/services/splits.ts`
- Modify: `backend/src/services/localizationDomain.ts`
- Modify: `backend/src/services/localizedName.ts`
- Modify: `backend/src/services/workbench.ts`
- Modify: `backend/src/services/preferences.ts`
- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/routes/morphology.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/src/routes/preferences.ts`
- Modify: `backend/src/types/morphology.ts`
- Modify: `backend/src/types/mapping.ts`
- Modify: `backend/tests/morphology.test.ts`
- Modify: `backend/tests/morphologyIntegration.test.ts`
- Modify: `backend/tests/splits.test.ts`
- Modify: `backend/tests/localizationDomain.test.ts`
- Modify: `backend/tests/localizationIntegration.test.ts`
- Modify: `backend/tests/workbench.test.ts`
- Modify: `backend/tests/preferences.test.ts`
- Modify: `backend/tests/preferencesIntegration.test.ts`

**Produces:** 所有次要 runtime 功能只引用 integer canonical IDs，且不恢復已刪除索引。

- [ ] Form edges 改用 integer ID、`UNIQUE(form_id,lemma_id)`、lemma index 與反向 pair trigger；移除 pair_low／pair_high、source 與時間。
- [ ] Form features 只保留 `WITHOUT ROWID (edge_id,feature_code)`；不支援 feature-first query。
- [ ] POS registry 加入固定 `bit_index 0..62`；expression 查詢由 `pos_mask` 投影詞性。
- [ ] Split 只保存 source、target、creator 與 moved edge IDs；新增原子 undo，任一衝突即整次拒絕。
- [ ] 固定撤銷端點為 `POST /api/v2/expressions/:sourceId/splits/:splitId/undo`，僅限 admin；成功後刪除 compact undo log。
- [ ] UI locale、UI message expression FK 與 user locale preference 內部使用 integer ID；API 仍投影 locale code。
- [ ] 測試 reverse form pair、split success／undo／conflict、POS mask、多 locale fallback 與 preference round trip。

**Acceptance commands:**

```bash
cd backend && npx vitest run tests/morphology.test.ts tests/splits.test.ts tests/localizationDomain.test.ts tests/workbench.test.ts tests/preferences.test.ts
```

**Commit:** `feat(domain): migrate secondary relations to integer ids`

---

### Task 6: 刪除 release／claim／packed 與 feed runtime

**Files:**

- Delete: `backend/src/services/dictionaryReleaseEligibility.ts`
- Delete: `backend/src/services/dictionaryReleases.ts`
- Delete: `backend/src/types/dictionaryRelease.ts`
- Delete: `backend/tests/dictionaryReleaseEligibility.test.ts`
- Delete: `backend/src/utils/ulid.ts`
- Delete: `backend/src/utils/ulid.test.ts`
- Delete: `backend/src/routes/feed.ts`
- Delete: `backend/tests/feed.test.ts`
- Modify: `backend/src/routes/index.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/services/languageContent.ts`
- Modify: `backend/src/services/localizationDomain.ts`
- Modify: `backend/src/services/localizedName.ts`
- Modify: `backend/src/services/mappingGraph.ts`
- Modify: `backend/src/services/mappings.ts`
- Modify: `backend/src/services/morphology.ts`
- Modify: `backend/src/services/readings.ts`
- Modify: `backend/src/services/splits.ts`
- Modify: `backend/src/services/workbench.ts`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `backend/tests/cacheHeaders.test.ts`

**Produces:** Backend 不再知道 active release、managed object 或 packed compatibility views。

- [ ] 移除 eligibility、promotion、active release predicate 與 `all_expression_*`／`dictionary_*` query path。
- [ ] 取消 `/api/v2/feed` route；不提供 hot/new edge feed compatibility response。
- [ ] 全域搜尋不得再命中 runtime `release_id`、`claim_key`、binding、evidence、packed table 或 eligibility symbol。
- [ ] 已移除 endpoint 測試 404／未註冊；cache policy 不再列出 feed route。
- [ ] 執行 backend 全套非 integration tests，確認 canonical tables 是唯一讀寫路徑。

**Acceptance commands:**

```bash
rg -n "dictionaryRelease|releaseObject|edgeEligibility|activeRelease|all_expression_|dictionary_terms|dictionary_edges|claim_key|release_id" backend/src
cd backend && npm test
```

Expected: `rg` 無 runtime 命中；測試通過。

**Commit:** `refactor(api): remove managed dictionary runtime`

---

### Task 7: 更新 Web 契約並移除已取消介面

**Files:**

- Delete: `web/src/composables/useFeed.ts`
- Delete: `web/src/pages/HomeFeed.vue`
- Delete: `web/src/pages/HomeFeed.test.ts`
- Delete: `web/src/components/feed/MappingCard.vue`
- Delete: `web/src/components/feed/NewContribution.vue`
- Modify: `web/src/router.ts`
- Modify: `web/src/api/expressions.ts`
- Modify: `web/src/api/languageIdentity.ts`
- Modify: `web/src/api/localization.ts`
- Modify: `web/src/api/morphology.ts`
- Modify: `web/src/api/preferences.ts`
- Modify: `web/src/composables/useExpressions.ts`
- Modify: `web/src/composables/useLanguages.ts`
- Modify: `web/src/composables/useSearch.ts`
- Modify: `web/src/composables/useHandbooks.ts`
- Modify: `web/src/pages/LanguageDetail.vue`
- Modify: `web/src/pages/LanguageDetail.test.ts`
- Modify: `web/src/pages/Search.vue`
- Modify: `web/src/pages/Search.test.ts`
- Modify: `web/src/pages/MappingDetail.vue`
- Modify: `web/src/pages/MappingDetail.behavior.test.ts`
- Modify: `web/src/pages/MappingDetail.language.test.ts`
- Modify: `web/src/pages/Profile.vue`
- Modify: `web/src/pages/HandbookList.vue`
- Modify: `web/src/pages/HandbookList.test.ts`
- Modify: `web/src/pages/HandbookView.vue`
- Modify: `web/src/pages/HandbookView.test.ts`
- Modify: `web/src/components/mapping/ExpressionEvidenceList.vue`
- Modify: `web/src/components/mapping/ExpressionEvidenceList.test.ts`
- Modify: `web/src/components/mapping/ExpressionSplitDialog.vue`
- Modify: `web/src/components/mapping/ExpressionSplitDialog.test.ts`
- Modify: `web/src/components/mapping/MappingGraph.vue`
- Modify: `web/src/components/mapping/MappingGraph.test.ts`
- Modify: `web/src/components/mapping/GraphToolbar.vue`
- Modify: `web/src/components/mapping/GraphToolbar.test.ts`
- Modify: `web/src/components/mapping/GraphInspector.vue`
- Modify: `web/src/components/mapping/GraphInspector.test.ts`
- Modify: `web/src/components/mapping/GraphMobileInspector.vue`
- Modify: `web/src/components/mapping/GraphNode.vue`
- Modify: `web/src/components/mapping/mappingGraphModel.ts`
- Modify: `web/src/components/mapping/mappingGraphModel.test.ts`
- Modify: `web/src/components/mapping/mappingGraphLayout.ts`
- Modify: `web/src/components/mapping/mappingGraphLayout.test.ts`
- Modify: `web/src/components/mapping/mappingGraphTypes.ts`
- Modify: `web/src/components/handbook/HandbookExpressionInspector.vue`
- Modify: `web/src/components/handbook/HandbookRelationPreview.vue`
- Modify: `web/src/locales/en.ts`
- Modify: `web/src/router.test.ts`

**Produces:** Web 全面使用新 API；沒有 attestation、activity、feed、OFFSET 或舊 ID 假設。

- [ ] 所有 expression／edge／handbook ID 維持 string；不得 `Number(id)`、算術運算或依舊 ID 格式分割。
- [ ] Expression evidence UI 改讀 `locales` 與 content-key readings；移除 attestation metadata。
- [ ] Language 與 search pages 只提供 alpha／new、指定語言 prefix search 與 cursor load-more。
- [ ] Mapping detail 傳遞可選 `target_language`，graph/list 對 truncated 與 omitted count 提供可讀提示。
- [ ] Handbook list 保留 new／hot；handbook detail 支援 vote toggle。
- [ ] Profile 移除 activity 區塊；首頁 `/` 改為 `/languages`，並刪除 edge feed UI。
- [ ] 更新英文字串與相關 component tests；桌面及行動 viewport 都要檢查 mapping、language、handbook、profile。

**Acceptance commands:**

```bash
cd web && npm test
cd web && npm run build
```

**Commit:** `feat(web): adopt canonical dictionary api`

---

### Task 8: 改寫 canonical 詞典匯入與 AI 高信心合併

**Files:**

- Delete: `scripts/db/lib/dictionary_release.py`
- Delete: `scripts/db/tests/test_dictionary_release.py`
- Delete: `scripts/dictionary/import_mappings.py`
- Delete: `scripts/dictionary/test_import_mappings.py`
- Delete: `scripts/dictionary/import_structured_jsonl.py`
- Delete: `scripts/dictionary/test_import_structured_jsonl.py`
- Delete: `scripts/dictionary/langmap_dictionary/publisher.py`
- Delete: `scripts/dictionary/tests/test_publisher.py`
- Delete: `scripts/dictionary/tests/test_release_artifact.py`
- Create: `scripts/dictionary/tests/test_artifact.py`
- Modify: `scripts/db/manage.py`
- Modify: `scripts/db/lib/fingerprint.py`
- Modify: `scripts/db/lib/paths.py`
- Modify: `scripts/db/lib/production.py`
- Modify: `scripts/db/tests/test_fingerprint.py`
- Modify: `scripts/db/tests/test_production_inventory.py`
- Modify: `scripts/dictionary/manage.py`
- Modify: `scripts/dictionary/incremental_import.py`
- Modify: `scripts/dictionary/langmap_dictionary/local_import.py`
- Modify: `scripts/dictionary/langmap_dictionary/schema.py`
- Modify: `scripts/dictionary/langmap_dictionary/models.py`
- Modify: `scripts/dictionary/langmap_dictionary/compiler.py`
- Modify: `scripts/dictionary/langmap_dictionary/clusters.py`
- Modify: `scripts/dictionary/langmap_dictionary/reconciliation.py`
- Modify: `scripts/dictionary/langmap_dictionary/artifact.py`
- Modify: `scripts/dictionary/langmap_dictionary/report.py`
- Modify: `scripts/dictionary/config/reconciliation.json`
- Modify: `scripts/dictionary/README.md`
- Modify: `scripts/dictionary/gold/README.md`
- Modify: `scripts/dictionary/tests/test_cod_clusters.py`
- Modify: `scripts/dictionary/tests/test_compiler.py`
- Modify: `scripts/dictionary/tests/test_reconciliation.py`
- Modify: `scripts/dictionary/tests/test_local_import.py`
- Modify: `scripts/dictionary/tests/test_incremental_import.py`
- Modify: `scripts/dictionary/tests/test_manage_cli.py`
- Modify: `scripts/dictionary/tests/test_release_artifact.py`

**Produces:** Structured JSONL 到 canonical D1 的單部、可續跑、可量測流程；不寫任何 release／claim／packed runtime row。

**Required importer contract:**

| Stage | Output |
| --- | --- |
| Validate／normalize | 完整抽取欄位保留於離線 staging artifact |
| Reconcile | 同 language＋canonical text；confidence `>= 0.98`；cluster complete-pair |
| Sense identity | 穩定 fingerprint；未合併 sense 配下一個永不重用 homograph index |
| Aggregate | POS OR、locale/readings set union、edge relation OR、固定 source rank |
| Examples | 獨立 expression＋relation mask `4` edge |
| Write | sources → languages/locales → expressions → links → readings → edges |
| Resume | 離線 checkpoint；D1 內沒有 import state table |

- [ ] 把 staging 的執行範圍改為中性 `run_id`；移除 publish、active release、claim binding 與 packed append 分支。
- [ ] Source registry 在每次 fresh rebuild 前按 `(type,name)` 穩定配號；同 rank 依穩定 ID 選代表值。
- [ ] Sense registry 保存現存與已作廢 homograph index，確保 merge／delete 後不重用。
- [ ] AI merge 只接受 `>= 0.98`、無 hard contradiction 且 cluster 任意 pair 都通過；其他資料建立新 homograph。
- [ ] Canonical writer 直接 upsert 最終 tables，chunk 可調且每批 idempotent；中斷後從外部 checkpoint 續跑。
- [ ] Small-first orchestrator 一次只處理一部；每部記錄 records、canonical row counts、各階段耗時、rows/s、D1 bytes delta 與結果。
- [ ] 以固定 100,000-record 樣本 benchmark chunk 1,000／5,000／10,000，選出採用值；初始比較基準為 5,000。
- [ ] `cod` fixture 必須驗證三個 sense 的 homograph 與不同跨語言 mappings；另測高信心 merge、拒絕 merge、relation OR、example edge 與 resume。

**Acceptance commands:**

```bash
python3 -m pytest scripts/dictionary/tests -q
python3 -m pytest scripts/db/tests -q
```

**Commit:** `feat(import): write reconciled dictionaries to canonical d1`

---

### Task 9: Fresh rebuild、網站 smoke test 與容量／效能驗收

**Files:**

- Modify: `scripts/dictionary/README.md`
- Modify: `docs/superpowers/plans/2026-08-24-dictionary-import-performance.md`
- Runtime only: `/Volumes/DATA/langmap-import-state.json`
- Runtime only: `/Volumes/DATA/langmap-import-benchmarks.jsonl`
- Runtime only: `/Volumes/DATA/langmap-staging-parts/`

**Produces:** 可實際瀏覽、可逐部擴充、低於空間預算的本地 canonical D1，以及可重跑的驗收紀錄。

- [ ] 執行完整 static／unit tests；任何舊欄位、舊 ID、release／claim／packed 名稱的 runtime 殘留都先清完。
- [ ] `./dev.sh --rebuild` 建立 fresh local D1；確認 handbooks、language registry、UI locales 與必要 seed 正常。
- [ ] 先匯入最小詞典，驗證 `/`、`/languages`、language detail、search、`/mapping/:id`、handbooks 與 profile。
- [ ] 再匯入一部百萬級詞典，量測 language first page、cursor next page、prefix search、locale filter/count、expression detail、direct mappings、1/2/3-hop graph、target-language graph、handbook new/hot 的 warm p50／p95。
- [ ] 對所有核心 SQL 執行 `EXPLAIN QUERY PLAN`；任何 `USE TEMP B-TREE`、全表 edge scan 或深層 OFFSET 都視為失敗。
- [ ] 每部匯入後記錄 page count、file bytes、各 table/index bytes 與 bytes/canonical row；推算超過 4.5 GiB 時停止。
- [ ] 完整匯入完成後確認 D1 `< 5 GiB`、`foreign_key_check` 為空、`quick_check` 為 `ok`，並核對 `cod` 三義映射。
- [ ] 更新 README 的唯一正式匯入入口、checkpoint、benchmark 欄位、停止條件與本地驗證命令；舊 packed/import plan 標記為已取代。

**Acceptance commands:**

```bash
./build.sh
./dev.sh --rebuild
cd backend && npm test
cd web && npm test
python3 -m pytest scripts/dictionary/tests scripts/db/tests -q
```

**Manual acceptance:**

- `http://localhost:5173/languages`
- `http://localhost:5173/handbooks`
- 一個 fresh numeric URL：`http://localhost:5173/mapping/<decimal-id>`
- 指定語言的 prefix search 與 graph `target_language`

**Commit:** `docs: record canonical import verification`

---

## Spec Coverage Matrix

| Spec requirement | Task |
| --- | --- |
| Greenfield、integer IDs、registry | 1、2、9 |
| Expressions、POS、homographs | 1、2、8 |
| Locale links、readings、sources | 1、2、8 |
| Edges、mapping cursor、graph lens | 1、3、7 |
| Votes、handbook hot | 1、4、7 |
| Morphology、split undo | 1、5、7 |
| UI localization、preferences、users | 1、4、5、7 |
| 移除 release／claim／packed | 1、6、8 |
| Prefix search、cursor、無 temp sort | 2、3、7、9 |
| AI 高信心 reconciliation | 8、9 |
| 逐部匯入與 benchmark | 8、9 |
| 83-index 處置與 `< 5 GiB` | 1、9 |

## Final Definition of Done

- Schema、migration、backend、frontend、importer 與文件使用同一套 integer canonical contract。
- Runtime 沒有 release／claim／packed／attestation audit compatibility path。
- 核心查詢無 temporary sort，列表無深層 OFFSET。
- `cod` 多義詞與 AI 高信心合併均通過自動測試及本地 D1 smoke test。
- 最小詞典與百萬級詞典的吞吐、query-plan、p50／p95、table/index bytes 已記錄。
- 完整 canonical D1 推算及實測都低於 5 GiB。
