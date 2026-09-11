# Wikivoyage Multilingual Phrasebook Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Execute this plan task-by-task with the stated tests and checkpoints.

**Goal:** 從英文 Wikivoyage `Category:Phrasebooks` 建立一套可重跑的英文會話手冊匯入流程，並在 handbook 中按使用者選定的 locale 批量顯示直接翻譯與 reading。

**Architecture:** 以固定 revision 的 MediaWiki wikitext 快照為唯一輸入，經 page/section catalog、結構化解析器與既有 Structured JSONL v2 staging pipeline 寫入 canonical expressions、readings、edges。建立一個 `managed_key=enwikivoyage-phrasebooks` 的唯讀 handbook；詳情頁保留英文項目，翻譯由單次 batch API 查詢直接 edge 並按精確 target locale 過濾，前端只在選定 locale 後請求。

**Tech Stack:** Python 3 標準庫、SQLite/D1、Hono + TypeScript、Vue 3 + Pinia、Vitest、既有 JSONL v2 importer。

## Global Constraints

- 來源只用 `https://en.wikivoyage.org/wiki/Category:Phrasebooks` 的 namespace-0 article pages；category pages 不作詞句資料。
- 只發布英文詞句、其他語言對應詞句及 reading；不導入敘事、文法說明或 target-to-target edge。
- `(language_id,text)` 合併為 `homograph_index=1`；所有來源證據以 URL、revision、section/row marker 保留。
- handbook 使用 `managed_key='enwikivoyage-phrasebooks'`、`eng-Latn-US`，由 system user 管理且不可由一般 UI 編輯。
- `/locales` coverage 聚合不建立；選項沿用 `/language-locales`，翻譯查詢必須是 exact locale、direct edge、`score >= 0`。
- 更新採增量追加；刪除或 identity-changed 只產生 review artifact，不自動刪除共用 expression/reading。
- 每個查詢、圖遍歷、列表均使用穩定排序與上限；保留 `web/` 與 backend 既有 tokens、鍵盤操作及行動版規則。

---

## File map

- `scripts/wikivoyage/download.py`：MediaWiki discovery、continuation/retry、原始 revision snapshot 與 manifest。
- `scripts/wikivoyage/page-catalog.json`、`section-catalog.json`：明確的頁面 locale profile、章節 alias、include/exclude 規則。
- `scripts/wikivoyage/parser.py`、`export_phrasebooks.py`：wikitext AST/definition-list 解析、JSONL v2 輸出、quarantine/review artifact。
- `scripts/dictionary/langmap_dictionary/adapters/wikivoyage_phrasebook.py` 及 adapter registry：把 Wikivoyage entry 正規化為英文 headword + target equivalents/readings。
- `backend/schema.sql`、`backend/migrations/0044_wikivoyage_handbook.sql`、`scripts/wikivoyage/build_handbook.py`：managed handbook identity、section/item 建置與 seed。
- `backend/src/services/handbookTranslations.ts`、`backend/src/routes/handbooks.ts`、`backend/tests/handbookTranslations.test.ts`：batch translation contract 與 query-plan guard。
- `web/src/api/handbooks.ts`、`web/src/composables/useHandbooks.ts`、`web/src/pages/HandbookView.vue`、`web/src/components/handbook/HandbookTranslationPicker.vue`：locale 開關、URL state、翻譯 cache/abort、顯示 reading。
- `scripts/wikivoyage/tests/`、`scripts/dictionary/tests/`、`web/src/pages/HandbookView.test.ts`：fixture、parser、匯入、API、UI 回歸測試。

## Task 1: 建立可重跑的 Wikivoyage 快照下載器（已完成）

**Files:**
- Create: `scripts/wikivoyage/__init__.py`, `scripts/wikivoyage/download.py`
- Create: `scripts/wikivoyage/tests/test_download.py`
- Modify: `.gitignore`（忽略本機快照目錄）

**Interfaces:**
- `discover_pages(fetch_json, category: str) -> tuple[PageDescriptor, ...]` 只回傳 namespace 0，處理 `continue`。
- `download_snapshot(client, output_dir: Path, category: str, user_agent: str) -> SnapshotManifest`；manifest 固定保存 pageid、title、revid、timestamp、sha256、raw path、license、retrieved_at。

- [x] Step 1–5：已完成 continuation、namespace filter、retry、atomic snapshot、manifest 與回歸測試。

## Task 2: 固定 page/section catalog 並輸出 registry 阻擋報告（已完成首批）

**Files:**
- Create: `scripts/wikivoyage/page-catalog.json`, `scripts/wikivoyage/section-catalog.json`, `scripts/wikivoyage/catalog.py`
- Create: `scripts/wikivoyage/tests/test_catalog.py`

**Interfaces:**
- `load_page_catalog(path) -> dict[int, PageProfile]`：每個 pageid 明確給 `lang_code`、零至多個 exact `locale_code`、reading schemes、include/exclude。
- `resolve_section(title, catalog) -> str | None`：先 canonical title，再 alias；未列入的章節不解析。
- `validate_registry(connection, page_catalog) -> RegistryReport`：缺語言或 locale 時標為 blocked，不猜測 title。

- [x] Step 1–4：已完成 11 個 reviewed profiles、section aliases、registry report 與 deterministic ordering。
- [ ] 後續：為 snapshot 中其餘 306 個 `blocked` 頁面補 registry identity，逐頁審閱後再解鎖。

## Task 3: 解析 wikitext 並產生 Structured JSONL v2（已完成首批）

**Files:**
- Create: `scripts/wikivoyage/parser.py`, `scripts/wikivoyage/export_phrasebooks.py`
- Create: `scripts/wikivoyage/tests/fixtures/japanese_phrasebook.wikitext`, `scripts/wikivoyage/tests/fixtures/japanese_page.json`
- Create: `scripts/wikivoyage/tests/test_parser.py`, `scripts/wikivoyage/tests/test_export.py`

**Interfaces:**
- `parse_phrase_rows(wikitext: str, page: PageProfile, sections: SectionCatalog) -> PageParseResult`。
- `export_page(snapshot: PageSnapshot, profile: PageProfile, sections: SectionCatalog) -> list[dict[str, object]]`。
- `write_jsonl_v2(results, destination, snapshot_manifest) -> ExportReport`，entry key 使用 `pageid:section_key:sha256(english_text):occurrence`。

- [x] Step 1–5：已完成受限 parser、JSONL v2、provenance、quarantine/removal artifacts 與 deterministic export。

## Task 4: 接入既有 staging/adapter/canonical import（已完成）

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/adapters/wikivoyage_phrasebook.py`
- Modify: `scripts/dictionary/langmap_dictionary/adapters/__init__.py`, `scripts/dictionary/incremental_import.py`, `scripts/dictionary/manage.py`
- Create: `scripts/dictionary/tests/test_wikivoyage_phrasebook_adapter.py`

**Interfaces:**
- `WikivoyagePhrasebookAdapter.normalize_entry(entry: StagedEntry) -> NormalizedEntry`：headword 必為 `eng`，equivalent 依 catalog exact `lang_code/locale_code`，reading 用 `target_claim_key` 掛到 target expression。
- `adapter_for_dictionary_key(dictionary_key: str) -> DictionaryAdapter`：`enwikivoyage:` 選新 adapter，其他 key 維持既有 adapter。

- [x] Step 1–5：已完成 adapter dispatch、canonical import、source markers/readings 與 local-import tests。

## Task 5: managed handbook schema 與 builder（已完成）

**Files:**
- Create: `backend/migrations/0044_wikivoyage_handbook.sql`
- Modify: `backend/schema.sql`, `backend/src/routes/handbooks.ts`
- Create: `scripts/wikivoyage/build_handbook.py`, `scripts/wikivoyage/tests/test_build_handbook.py`
- Modify: `backend/tests/schemaContract.test.ts`, handbook route tests

**Interfaces:**
- migration 新增 `handbooks.managed_key TEXT NULL`、唯一 partial index `WHERE managed_key IS NOT NULL`。
- `build_managed_handbook(connection, managed_key='enwikivoyage-phrasebooks', section_catalog) -> BuildReport`：system user `langmap`、`eng-Latn-US`、唯讀 handbook；同 section 英文 text 精確去重，跨 section 可重複。
- `GET /handbooks/:id` 回傳 `managed: boolean`、`can_edit: boolean`；managed handbook 的 PUT/DELETE 回傳 403。

- [x] Step 1–4：已完成 nullable managed key、唯一索引、idempotent builder、route capability 與測試。

## Task 6: batch translations API 與 query-plan guard（已完成）

**Files:**
- Create: `backend/src/services/handbookTranslations.ts`
- Modify: `backend/src/routes/handbooks.ts`, `backend/src/types.ts`
- Create: `backend/tests/handbookTranslations.test.ts`

**Interfaces:**
- `getHandbookTranslations(db, handbookId: number, targetLocale: string, hints) -> Promise<TranslationResponse>`。
- `GET /api/v2/handbooks/:id/translations?target_locale=jpn-Jpan-JP&ui_locale=...&secondary_ui_locale=...` 回傳 `{target_locale,items:[{source_expression_id,total_translation_count,hidden_translation_count,translations:[{id,text,lang_code,language_locale_code,language_name,readings:[{scheme,value}]}]}]}`；每個 source expression 預設最多 3 個候選。

- [x] Step 1–5：已完成 exact locale、direct edge、score、private visibility、雙向 UNION、reading batch 與上限測試。

## Task 7: handbook locale selector 與雙語顯示（已完成）

**Files:**
- Create: `web/src/api/handbooks.ts`, `web/src/components/handbook/HandbookTranslationPicker.vue`
- Modify: `web/src/composables/useHandbooks.ts`, `web/src/pages/HandbookView.vue`, `web/src/components/handbook/HandbookExpressionInspector.vue`, `web/src/i18n/locales/*.json`（沿用既有 locale 文案檔）
- Modify: `web/src/pages/HandbookView.test.ts`, `web/src/api/handbooks.test.ts`

**Interfaces:**
- `getTranslations(handbookId: string, targetLocale: string, hints: LocaleHints, signal?: AbortSignal): Promise<HandbookTranslations>`。
- `HandbookTranslationPicker` 使用既有 `LanguageLocalePicker`，emit `update:modelValue`，不顯示 coverage aggregate。

- [x] Step 1–5：已完成 URL/session locale state、單次 batch request、abort/cache、雙語 reading、managed read-only UI、a11y/mobile states 與 build/tests。

## Task 8: fixture-to-corpus 驗收與發布包（本地流程已完成）

**Files:**
- Create: `scripts/wikivoyage/README.md`, `scripts/wikivoyage/quality.py`, `scripts/wikivoyage/tests/test_quality.py`
- Modify: `docs/runbooks/production-data-release.md` 或新增 `docs/runbooks/wikivoyage-phrasebook-release.md`

- [x] Step 1–5：已完成 quality gate、pipeline CLI、乾淨 SQLite 端到端驗收、release runbook 與 production apply guard。
- [ ] 後續：完成 306 頁 registry／內容抽查，並依 runbook 另行核准 production plan/apply。

## Checkpoint / 驗收順序

1. Task 1–3 完成後，先用一個真實英文頁面 revision（不寫 D1）驗證下載與 JSONL row。
2. Task 4–5 完成後，使用本地 D1 fixture 驗證 expression/edge/reading/handbook idempotency。
3. Task 6 完成後保存 `EXPLAIN QUERY PLAN` 輸出與 route integration test 結果。
4. Task 7–8 完成後跑前後端完整驗證；生產 plan/apply、statistics refresh 與 full corpus publish 另依 runbook 執行並需明確批准。
