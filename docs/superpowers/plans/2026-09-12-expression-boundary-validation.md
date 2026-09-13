# Expression 邊界與詞句品質閘門 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Execute this plan task-by-task with the stated tests and checkpoints.

**Goal:** 把詞句、讀音與 mapping 註釋的邊界落成可重跑的 staging 校驗，阻止混入讀音、說明、錯誤尾標點或未拆分替代形式的污染資料；同時保留原始欄位以便追溯。

**Architecture:** 新增一個與來源無關的 expression-surface 純函式層，先識別頂層替代形式、reading slash 與括號說明，再由各 dictionary adapter 將可發布詞句、reading 與待審 annotation 分流。staging 以明確的 lexical annotation 表保留被移出的說明；canonical mapping annotation 以 `expression_edges.annotations_json` 的 bounded JSON array 保存可展示欄位，不新增獨立 annotation table。本階段不直接改 production D1。

**Tech Stack:** Python 3、SQLite staging、既有 Structured JSONL v2 loader/adapter/compiler、pytest。

## Global Constraints

- expression 只保存單一語言中可說出或寫出的詞、短語或句子；不保存 reading、定義、欄位標籤、來源導航或解釋說明。
- 頂層 `/` 替代形式拆成獨立詞句，例如 `Hello!/i say!/hey!`；IPA 或其他 reading 斜線不得被當作詞句分隔。
- 多個 reading 必須是多筆 `lexical_readings`，不得拼進 expression text。
- 括號內的使用限制或解釋（例如 `only on the telephone`）保留為 annotation/provenance，不建立 expression。
- 全大寫縮寫（例如 `UFO`）保留；其他可安全處理的拉丁字串沿用既有 sentence-case identity 規則。
- malformed 或無法可靠判斷的值 fail closed，進 quarantine，不猜測語言、不發布。
- 不下載或匯出 production 全庫；只對本地 fixture/staging 做驗證與抽樣報告。
- 不修改 `apple/`、`web/dist/`、`backend/public/` 或現有 production 資料。

## File Map

- Create: `scripts/dictionary/langmap_dictionary/expression_surface.py`
- Create: `scripts/dictionary/tests/test_expression_surface.py`
- Modify: `scripts/dictionary/langmap_dictionary/models.py`
- Modify: `scripts/dictionary/langmap_dictionary/schema.py`
- Modify: `scripts/dictionary/langmap_dictionary/adapters/traditional_chinese_english.py`
- Modify: `scripts/dictionary/langmap_dictionary/adapters/wikivoyage_phrasebook.py`
- Modify: `scripts/dictionary/langmap_dictionary/compiler.py`
- Modify: `scripts/dictionary/tests/test_traditional_chinese_english_adapter.py`
- Modify: `scripts/dictionary/tests/test_wikivoyage_phrasebook_adapter.py`
- Modify: `backend/migrations/0045_mapping_annotations.sql`, `backend/migrations/0045_mapping_annotations.meta.json`
- Modify: `backend/schema.sql`, backend mapping service/type/API tests after staging contract is stable
- Create: `docs/superpowers/specs/2026-09-12-expression-boundary-validation.md`

## Task 1: 建立純函式 surface parser（先紅後綠）

**Interfaces:**

- `split_expression_alternatives(value: str) -> tuple[str, ...]`
- `normalize_expression_surface(value: str) -> str`
- `extract_reading_parentheses(value: str) -> tuple[str, tuple[str, ...]]`
- `extract_mapping_annotation(value: str) -> tuple[str, str | None]`

- [ ] 先新增公開 seam 測試：`Hello!/i say!/hey!`、`ผม/ดิฉัน`、`/ˈbo.ɐ ˈtaɾ.dɨ/` 不拆成詞句、`Hello ,` 清理、`Boa tarde (, /.../)` 分離 reading、`Hello (only on the telephone)` 分離 annotation、未閉合括號回傳錯誤候選。
- [ ] 執行 focused pytest，確認因函式不存在而失敗。
- [ ] 實作保守 tokenizer：只在括號／方括號／IPA slash block 外拆 slash；不移除 `?`、`!` 等語義標點；移除孤立尾逗號與句號。
- [ ] 重新執行 focused pytest 與 `git diff --check`。

## Task 2: adapter 與 staging 分流

- [ ] 新增 `NormalizedAnnotation` DTO，保存 claim、原文、normalized text、target claim、metadata/errors。
- [ ] staging 新增 `lexical_annotations`（release、claim、entry/sense、side、raw、text、target claim、metadata、errors）與索引；同步清理、resume、flush、foreign-key check。
- [ ] Traditional Chinese/English adapter 對 forms、mappings、equivalents、synonyms、examples 使用 surface parser；替代形式產生穩定 claim suffix，reading 斜線分成多筆 reading，括號說明進 annotation。
- [ ] Wikivoyage adapter 保持英文 equivalent 限制，但同樣拆 slash alternatives、移除 reading/說明污染並 quarantine mixed values。
- [ ] 為 `Hello!/i say!/hey!`、`Boa tarde (, /.../)`、`Hello (only on the telephone)`、`你（們）好` 增加 adapter/staging 回歸測試。

## Task 3: compiler quality gate

- [ ] compiler 只消費無 surface errors 的 occurrences/readings；annotation 先輸出到離線 artifact/provenance，不生成 expression。
- [ ] 新增 quality gate 統計與 quarantine code：`unsplit_alternative`、`reading_in_expression`、`mixed_expression_annotation`、`malformed_surface`、`orphan_terminal_punctuation`。
- [ ] 以本地 fixture 驗證 expression、reading、annotation 的數量與 claim 對應，確保重跑不重複。

## Task 4: mapping annotation canonical schema/API（edge JSON migration）

- [ ] 在 `expression_edges` 新增 `annotations_json TEXT NOT NULL DEFAULT '[]'`；每個元素只保存 `text`、`side`、optional `source_id`／`source_marker`，不保存 `raw_text` 或 staging metadata。
- [ ] 更新 local importer、mapping service、graph response、TypeScript contract 與 mapping detail 測試；寫入時去重並穩定排序，讀取時設每 edge 20 筆上限。
- [ ] 只在本地 API/整合測試通過後產生受管 migration plan；本次不 apply production。

## Task 5: 驗收與交付

- [ ] 執行 `python3 -m pytest scripts/dictionary/tests -q` 及受影響 backend tests。
- [ ] 執行 `git diff --check`，檢查 schema/migration 一致與文件連結。
- [ ] 產出抽樣報告，列出 quarantine 原因與未處理來源，不拉取 production 大量資料。
- [ ] 以 Conventional Commit 分開提交 parser/staging 與 schema/API 兩組變更；若第二組未完成，明確保留未發布狀態。
