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

## Task 1: 建立可重跑的 Wikivoyage 快照下載器

**Files:**
- Create: `scripts/wikivoyage/__init__.py`, `scripts/wikivoyage/download.py`
- Create: `scripts/wikivoyage/tests/test_download.py`
- Modify: `.gitignore`（忽略本機快照目錄）

**Interfaces:**
- `discover_pages(fetch_json, category: str) -> tuple[PageDescriptor, ...]` 只回傳 namespace 0，處理 `continue`。
- `download_snapshot(client, output_dir: Path, category: str, user_agent: str) -> SnapshotManifest`；manifest 固定保存 pageid、title、revid、timestamp、sha256、raw path、license、retrieved_at。

- [ ] Step 1: 先寫 mock continuation、namespace filter、429/5xx retry、atomic file test。
- [ ] Step 2: 執行 `python3 -m pytest scripts/wikivoyage/tests/test_download.py -q`，確認新測試先失敗。
- [ ] Step 3: 用 `urllib.request` 實作 API client；每次 request 帶明確 User-Agent，指數 backoff 上限 30 秒，`.tmp` 寫完後 rename；輸出 `manifest.json` 與 `pages/<pageid>-<revid>.wikitext`。
- [ ] Step 4: 重跑測試，並用 fixture 驗證只下載 namespace-0、同 pageid/revid 不重寫。
- [ ] Step 5: `git diff --check`，提交 `feat: add Wikivoyage revision snapshot downloader`。

## Task 2: 固定 page/section catalog 並輸出 registry 阻擋報告

**Files:**
- Create: `scripts/wikivoyage/page-catalog.json`, `scripts/wikivoyage/section-catalog.json`, `scripts/wikivoyage/catalog.py`
- Create: `scripts/wikivoyage/tests/test_catalog.py`

**Interfaces:**
- `load_page_catalog(path) -> dict[int, PageProfile]`：每個 pageid 明確給 `lang_code`、零至多個 exact `locale_code`、reading schemes、include/exclude。
- `resolve_section(title, catalog) -> str | None`：先 canonical title，再 alias；未列入的章節不解析。
- `validate_registry(connection, page_catalog) -> RegistryReport`：缺語言或 locale 時標為 blocked，不猜測 title。

- [ ] Step 1: 寫 Japanese、Mandarin、無 registry、alias、非會話章節 fixture 測試。
- [ ] Step 2: 執行 catalog tests，確認缺少 profile 與未知 alias 都被明確報告。
- [ ] Step 3: 填入目前英文 Category snapshot 的 catalog 初版；建立 `registry-report.json`，每頁必為 `included|empty|excluded|blocked` 之一。
- [ ] Step 4: 加入 canonical section order 與 deterministic extra-section sort 測試，提交 `feat: pin phrasebook page and section catalogs`。

## Task 3: 解析 wikitext 並產生 Structured JSONL v2

**Files:**
- Create: `scripts/wikivoyage/parser.py`, `scripts/wikivoyage/export_phrasebooks.py`
- Create: `scripts/wikivoyage/tests/fixtures/japanese_phrasebook.wikitext`, `scripts/wikivoyage/tests/fixtures/japanese_page.json`
- Create: `scripts/wikivoyage/tests/test_parser.py`, `scripts/wikivoyage/tests/test_export.py`

**Interfaces:**
- `parse_phrase_rows(wikitext: str, page: PageProfile, sections: SectionCatalog) -> PageParseResult`。
- `export_page(snapshot: PageSnapshot, profile: PageProfile, sections: SectionCatalog) -> list[dict[str, object]]`。
- `write_jsonl_v2(results, destination, snapshot_manifest) -> ExportReport`，entry key 使用 `pageid:section_key:sha256(english_text):occurrence`。

- [ ] Step 1: 以 fixture 覆蓋 heading/alias、definition list、允許 table、link/template/italic 清理、空列、重複列、target reading、未知 scheme、CJK 混入 romanization/IPA quarantine。
- [ ] Step 2: 執行 parser/export tests，確認 JSONL header `schema_version=2`、`dictionary_key=enwikivoyage:<pageid>`、`entry_count` 與 fingerprint 穩定。
- [ ] Step 3: 實作受限 AST tokenizer（巢狀 template/link 不用全文 regex），只讀 catalog 允許的 row；輸出每筆英文 headword、target equivalent、reading、source marker 與 raw wikitext。
- [ ] Step 4: 產生 `review/removals.jsonl` 與 `review/quarantine.jsonl`；只在同一 page/entry identity 變更時標記 review，不刪既有資料。
- [ ] Step 5: 執行 `git diff --check`，提交 `feat: export Wikivoyage phrasebook JSONL`。

## Task 4: 接入既有 staging/adapter/canonical import

**Files:**
- Create: `scripts/dictionary/langmap_dictionary/adapters/wikivoyage_phrasebook.py`
- Modify: `scripts/dictionary/langmap_dictionary/adapters/__init__.py`, `scripts/dictionary/incremental_import.py`, `scripts/dictionary/manage.py`
- Create: `scripts/dictionary/tests/test_wikivoyage_phrasebook_adapter.py`

**Interfaces:**
- `WikivoyagePhrasebookAdapter.normalize_entry(entry: StagedEntry) -> NormalizedEntry`：headword 必為 `eng`，equivalent 依 catalog exact `lang_code/locale_code`，reading 用 `target_claim_key` 掛到 target expression。
- `adapter_for_dictionary_key(dictionary_key: str) -> DictionaryAdapter`：`enwikivoyage:` 選新 adapter，其他 key 維持既有 adapter。

- [ ] Step 1: 寫一筆英文→日文（含 kana/romaji）、一筆英文→中文（含 pinyin）、未知 scheme reading-only quarantine、target-target 不建 edge 的測試。
- [ ] Step 2: 執行 adapter tests，確認 canonical importer 能重用 `(eng,text)` 與 `(target,text)`，且 source marker 為 `oldid:<revid>#<section>/<row>`。
- [ ] Step 3: 實作 adapter 與 dispatch；保留 reading schemes `ipa|hepburn|pinyin|jyutping|tailo|wikivoyage-romanization|wikivoyage-respelling`，不以 script 猜 locale。
- [ ] Step 4: 讓 `run_incremental_import`、`manage.py preview/prepare` 依 dictionary key 選 adapter；執行既有 dictionary tests 加新 tests。
- [ ] Step 5: 提交 `feat: import Wikivoyage entries through canonical pipeline`。

## Task 5: managed handbook schema 與 builder

**Files:**
- Create: `backend/migrations/0044_wikivoyage_handbook.sql`
- Modify: `backend/schema.sql`, `backend/src/routes/handbooks.ts`
- Create: `scripts/wikivoyage/build_handbook.py`, `scripts/wikivoyage/tests/test_build_handbook.py`
- Modify: `backend/tests/schemaContract.test.ts`, handbook route tests

**Interfaces:**
- migration 新增 `handbooks.managed_key TEXT NULL`、唯一 partial index `WHERE managed_key IS NOT NULL`。
- `build_managed_handbook(connection, managed_key='enwikivoyage-phrasebooks', section_catalog) -> BuildReport`：system user `langmap`、`eng-Latn-US`、唯讀 handbook；同 section 英文 text 精確去重，跨 section 可重複。
- `GET /handbooks/:id` 回傳 `managed: boolean`、`can_edit: boolean`；managed handbook 的 PUT/DELETE 回傳 403。

- [ ] Step 1: 寫 migration/schema contract 與 builder fixture 測試（idempotent、section order、extra sort、same text 跨 section）。
- [ ] Step 2: 執行 backend schema/builder tests，確認新欄位存在且舊 handbook 不受影響。
- [ ] Step 3: 實作 migration、builder 及 route capability；builder 只從指定 managed source 的英文 expressions/edges 建 items。
- [ ] Step 4: 跑 `cd backend && npm test -- --runInBand`（若 runner 不支援則使用專案既有 Vitest 指令），提交 `feat: create managed English phrasebook handbook`。

## Task 6: batch translations API 與 query-plan guard

**Files:**
- Create: `backend/src/services/handbookTranslations.ts`
- Modify: `backend/src/routes/handbooks.ts`, `backend/src/types.ts`
- Create: `backend/tests/handbookTranslations.test.ts`

**Interfaces:**
- `getHandbookTranslations(db, handbookId: number, targetLocale: string, hints) -> Promise<TranslationResponse>`。
- `GET /api/v2/handbooks/:id/translations?target_locale=jpn-Jpan-JP&ui_locale=...&secondary_ui_locale=...` 回傳 `{target_locale,items:[{source_expression_id,translations:[{id,text,lang_code,language_locale_code,language_name,readings:[{scheme,value}]}]}]}`。

- [ ] Step 1: 寫 exact locale、score 过滤、direct edge、兩端方向、reading、無 translation、private handbook、invalid locale 測試。
- [ ] Step 2: 執行新 route tests，確認先失敗。
- [ ] Step 3: 用兩個有向 `UNION ALL` 分支批量查詢 handbook source expressions；join exact `expression_locale_links`，readings 以第二個固定查詢聚合，禁止每 item N+1。
- [ ] Step 4: 對 translation query 與 readings query 執行 `EXPLAIN QUERY PLAN` fixture，斷言使用 expression edge/locale indexes，並設定 item/translation 上限。
- [ ] Step 5: 跑 backend 全測試，提交 `feat: add locale-scoped handbook translations API`。

## Task 7: handbook locale selector 與雙語顯示

**Files:**
- Create: `web/src/api/handbooks.ts`, `web/src/components/handbook/HandbookTranslationPicker.vue`
- Modify: `web/src/composables/useHandbooks.ts`, `web/src/pages/HandbookView.vue`, `web/src/components/handbook/HandbookExpressionInspector.vue`, `web/src/i18n/locales/*.json`（沿用既有 locale 文案檔）
- Modify: `web/src/pages/HandbookView.test.ts`, `web/src/api/handbooks.test.ts`

**Interfaces:**
- `getTranslations(handbookId: string, targetLocale: string, hints: LocaleHints, signal?: AbortSignal): Promise<HandbookTranslations>`。
- `HandbookTranslationPicker` 使用既有 `LanguageLocalePicker`，emit `update:modelValue`，不顯示 coverage aggregate。

- [ ] Step 1: 寫 UI/API tests：URL `target_locale` round-trip、未選 locale 只顯示英文、選 locale 顯示 loading/translation/reading、切換 abort 舊 request、managed 不顯示 edit。
- [ ] Step 2: 執行 `cd web && npm test -- --run web/src/pages/HandbookView.test.ts`（按專案 runner 調整），確認新測試先失敗。
- [ ] Step 3: 在 HandbookView 加 `target_locale` query state、session cache 與固定 batch request；每列顯示英文→target→readings，target 點擊沿用 inspector。
- [ ] Step 4: 加 skeleton/error/empty state、鍵盤 focus、手機版不撐破長詞句；只在 managed handbook 顯示來源 attribution。
- [ ] Step 5: 執行 `cd web && npm run build` 與 HandbookView tests，提交 `feat: add handbook translation locale switch`。

## Task 8: fixture-to-corpus 驗收與發布包

**Files:**
- Create: `scripts/wikivoyage/README.md`, `scripts/wikivoyage/quality.py`, `scripts/wikivoyage/tests/test_quality.py`
- Modify: `docs/runbooks/production-data-release.md` 或新增 `docs/runbooks/wikivoyage-phrasebook-release.md`

- [ ] Step 1: 寫 quality gate：每個 discovered page 必有 state、JSONL page count 等於 included page、first/middle/last valid row sample、quarantine/removal counts。
- [ ] Step 2: 實作 CLI pipeline：`download → catalog report → export → stage → preview/quality → local-import → build handbook`，每批約 20–30 pages，輸出 manifest/checksum。
- [ ] Step 3: 用小型 fixture 跑完整流程，驗證 `/handbooks/:id/translations` 與 UI 只使用直接 mapping；確認 language statistics refresh SQL 有列在 release checklist。
- [ ] Step 4: 執行 `git diff --check`、`cd backend && npm test`、`cd web && npm run build`、Python tests；不得在此任務自動 apply production migration。
- [ ] Step 5: 提交 `docs: document Wikivoyage phrasebook release runbook`，並留下待人工抽查的 full-corpus manifest。

## Checkpoint / 驗收順序

1. Task 1–3 完成後，先用一個真實英文頁面 revision（不寫 D1）驗證下載與 JSONL row。
2. Task 4–5 完成後，使用本地 D1 fixture 驗證 expression/edge/reading/handbook idempotency。
3. Task 6 完成後保存 `EXPLAIN QUERY PLAN` 輸出與 route integration test 結果。
4. Task 7–8 完成後跑前後端完整驗證；生產 plan/apply、statistics refresh 與 full corpus publish 另依 runbook 執行並需明確批准。
