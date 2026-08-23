# Backend API 與 SQL 效能最佳化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改變 `/api/v2` 回應契約與資料語義的前提下，降低高流量讀取 API 的 SQL 掃描與排序成本、消除可避免的 N+1/串行查詢，並為所有批次寫入建立可預測的工作量上限。

**Architecture:** 先以一個 migration 補齊 feed、使用者活動與批次查詢所需的索引，再分別重寫 expression hot search、localization candidate 與 workbench 查詢，讓聚合與候選列在 SQL 端受控。寫入路徑以共用上限與 chunked D1 batch 保護資料庫；讀取路徑只並行真正獨立的查詢，保留目前穩定排序、循環處理、權限與錯誤語義。最後以現有 Vitest 測試、SQLite `EXPLAIN QUERY PLAN` 及固定樣本 HTTP benchmark 驗收。

**Tech Stack:** Hono 4 + TypeScript + Cloudflare Workers + D1/SQLite; Vitest; Wrangler v4 local D1; SQL migration/schema contract tests。

## Global Constraints

- 只修改 `backend/`、`backend/migrations/`、`backend/schema.sql`、必要測試與本計劃文件；不順手修改 `web/`、`apple/`。
- 保留目前工作樹中已有的 `backend/migrations/0032_feed_created_at_indexes.sql`、`backend/src/routes/feed.ts`、`backend/tests/feed.test.ts` 及其他未提交變更；本計劃的索引 migration 從 `0033` 接續。
- API prefix、回應格式、權限、ID 規則與既有資料語義不變；最佳化不得以刪除欄位、降低結果完整性或改變穩定排序換取效能。
- 所有列表與圖遍歷查詢必須有穩定排序、明確上限與參數化 binding；不得把使用者輸入直接拼入 SQL。
- 所有陣列型寫入輸入都必須先去重、驗證及限制數量；D1 batch 必須按固定 chunk 大小拆分，避免單次 statement 數量與請求工作量無界增長。
- schema 變更必須同時新增 migration、更新 `backend/schema.sql`，並在實作時更新 migration lock；不得只修改其中一份。
- 不新增統計表或 FTS5 作為第一步。只有在改寫查詢後仍由 benchmark 證明為主要瓶頸，才另開資料模型/搜尋方案計劃。
- 不執行會改動共享資料庫的 mutation benchmark；整合測試使用隔離的 local D1 fixture 或測試專用資料庫。
- 所有效能結論需區分本地 D1 的相對比較與 production SLO；本地測試毫秒數不可直接宣稱為 production latency。

---

## 審計基線與優先級

本計劃根據全量 backend route、service SQL、schema/migration、local D1 `EXPLAIN QUERY PLAN` 與 Chrome DevTools baseline 建立。已盤點約 50 個 Hono route declarations；GET 路徑已以本地 Worker 實測，POST/PUT/DELETE 以靜態 SQL 與整合測試檢查，避免審計造成資料變更。

| 優先級 | 現象 | 證據與目標 |
|---|---|---|
| P0 | 批次 contribution、localization mapping、handbook、split 的輸入與 statement 數量沒有一致硬上限 | 目前會逐筆查詢/寫入，`createEdgesBatch` 為巢狀 pair loop；目標是輸入可預測、chunked、超限明確回 `400` |
| P1 | `feed/hot` 掃描 `expression_edges` 並使用 temp B-tree 排序 | `backend/src/routes/feed.ts` 的 plan 顯示 `SCAN ed`、`USE TEMP B-TREE FOR ORDER BY`；目標是用 `(score DESC, created_at DESC, id ASC)` top-K index |
| P1 | expression hot search 有全表掃描、correlated edge count 與 temp sort | `backend/src/services/expressions.ts` 的 `LIKE '%q%'` 無法由普通 B-tree 解決；先把過濾 expression 集合與 mapping count 分離，避免每列 scalar subquery |
| P1 | localization candidate SQL 把所有候選列拉回 TypeScript 才挑第一筆/前五筆 | `localizedName.ts`、`localizationDomain.ts`、`workbench.ts` 均存在無界 candidate materialization；目標是 SQL 端按 source/message 分區取有限列，並避免 coverage/workbench 重複計算 |
| P1 | `users/me` activity 依 `created_by`/`user_id` 過濾但缺少對應 composite index | expressions、edges、handbooks 的 plan 會掃描或額外排序；目標是新增 user + created_at + tie-breaker indexes |
| P2 | language、mapping、expression detail 等服務有可並行的獨立查詢 | `languageContent.ts`、`mappings.ts`、`expressions.ts` 目前 count/detail 查詢串行；目標是縮短 wall-clock round trips，不改變錯誤處理 |
| P2 | localized fallback 每個 item 都可能再查一次 | `languageContent.ts` 的 fallback path 有 per-item query；目標是一次按 language code 批量載入 fallback 名稱 |
| P2 | graph frontier 會一次取得該 frontier 的全部相鄰 edges | 現有 node limit、cycle/dedupe 正確；本計劃先加入 row-count benchmark 與監控性回歸，不直接改變圖譜完整性 |

目前本地資料量約為 expressions 26,482、expression_edges 17,519；local Worker 的主要 GET 約 5–88ms，feed/new 已受 `0032` 的 created_at indexes/CTE 改善。這些數字只作回歸基線；實作時須比較 warm/cold、不同 query shape 與 `EXPLAIN QUERY PLAN`，不可只看單次 wall-clock。

## File Structure

| 檔案 | 責任 | 動作 |
|---|---|---|
| `backend/migrations/0033_api_performance_indexes.sql` | feed/hot、users/me activity、候選查詢所需的新增索引 | Create |
| `backend/schema.sql` | 與 0033 等價的完整 schema index 定義 | Modify |
| `backend/src/utils/limits.ts` | 批次輸入、D1 chunk、graph frontier 的共用上限常數與 clamp helper | Create |
| `backend/src/routes/contributions.ts` | contribution 輸入上限、去重與批次建立流程 | Modify |
| `backend/src/routes/localization.ts` | localization mapping batch 上限、批量 affected locale 重算觸發 | Modify |
| `backend/src/routes/handbooks.ts` | sections/items 上限與 chunked handbook write | Modify |
| `backend/src/services/mappings.ts` | bulk expression/edge resolve、chunked edge insert、穩定順序 | Modify |
| `backend/src/services/splits.ts` | split edge_ids 上限與 bounded dynamic set 查詢 | Modify |
| `backend/src/services/expressions.ts` | expression hot search 聚合查詢重寫 | Modify |
| `backend/src/services/localizedName.ts` | bounded localized-name candidate query | Modify |
| `backend/src/services/localizationDomain.ts` | bounded candidate、coverage 與 recalculate 去重 | Modify |
| `backend/src/services/workbench.ts` | workbench 分頁候選的 SQL-side top-5 與總數查詢 | Modify |
| `backend/src/services/languageContent.ts` | 獨立查詢並行與 fallback 批量載入 | Modify |
| `backend/src/services/mappingGraph.ts` | frontier row-count 統計/上限 helper，保留目前圖譜語義 | Modify |
| `backend/tests/schemaContract.test.ts` | migration/schema index parity | Modify |
| `backend/tests/mappingQueryIndexes.test.ts` | feed/activity/candidate index contract 與 query plan regression | Modify |
| `backend/tests/feed.test.ts` | feed hot/new 輸出與排序回歸 | Modify |
| `backend/tests/expressions.test.ts`、`backend/tests/expressionsIntegration.test.ts` | hot search 結果、count、filter 與排序回歸 | Modify |
| `backend/tests/contributionsIntegration.test.ts`、`backend/tests/handbooks.test.ts`、`backend/tests/splits.test.ts` | 批次上限、chunking 與既有資料語義 | Modify |
| `backend/tests/localizedName.test.ts`、`backend/tests/localizationDomain.test.ts`、`backend/tests/workbench.test.ts` | candidate cap、coverage、fallback 與前五筆排序 | Modify |
| `backend/tests/languageContent.test.ts`、`backend/tests/mappings.test.ts`、`backend/tests/expressionDetail.test.ts` | parallel read 與 query result 回歸 | Modify |
| `backend/tests/mappingGraphV2.test.ts` | frontier row cap/統計、cycle/dedupe 與 node limit 回歸 | Modify |

## Task 1: 建立效能索引 migration 與 schema contract

先把可由 schema 解決的瓶頸固定下來，再進行 query rewrite。索引欄位需包含穩定排序的 tie-breaker，避免只靠 score/created_at 造成同分頁結果漂移。

**Files:**

- Create: `backend/migrations/0033_api_performance_indexes.sql`
- Modify: `backend/schema.sql`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `backend/tests/mappingQueryIndexes.test.ts`
- Modify: `scripts/db/migration-lock.json`（實作時使用既有 sync 工具更新，不手編）

**Interfaces:**

- Consumes: 現有 `0031_mapping_query_indexes.sql`、`0032_feed_created_at_indexes.sql`、`expression_edges`/`expressions`/`handbooks`/`votes` schema。
- Produces: feed/hot 與 users/me 可直接使用的索引；Task 2–4 的 query rewrite 只依賴既有欄位與這些 indexes，不新增資料表。

- [ ] **Step 1: 先寫 index contract 測試**

在 `schemaContract.test.ts` 解析完整 schema，在 `mappingQueryIndexes.test.ts` 對 local D1 建立 minimal fixture，斷言下列 index 名稱、欄位順序與 migration/schema parity：

```sql
idx_expression_edges_score_feed
  ON expression_edges(score DESC, created_at DESC, id ASC)

idx_expressions_created_by_at
  ON expressions(created_by, created_at DESC, id ASC)

idx_expression_edges_created_by_at
  ON expression_edges(created_by, created_at DESC, id ASC)

idx_handbooks_user_created_at
  ON handbooks(user_id, created_at DESC, id ASC)

idx_votes_user_created_at
  ON votes(user_id, created_at DESC, target_id)
```

測試不得只斷言 index 名稱；必須讀取 `PRAGMA index_info` 或 schema metadata 確認欄位順序。

- [ ] **Step 2: 新增 `0033` migration**

建立 `backend/migrations/0033_api_performance_indexes.sql`，使用 `CREATE INDEX IF NOT EXISTS`，只新增 Step 1 列出的五個 index。不要重建或刪除現有 `0031`/`0032` index，也不要把 `LIKE '%q%'` 誤配普通 B-tree index。

- [ ] **Step 3: 同步 `backend/schema.sql`**

在完整 schema 的 index 區加入與 migration 完全相同的五個 index；確認 DROP/CREATE 順序可從零重建，並以 schema contract 測試檢查兩份 DDL 的 index 集合一致。

- [ ] **Step 4: 更新 migration lock 並檢查 dirty worktree**

使用 repo 既有 migration lock sync 工具重新計算 0033 的 sequence、size、sha256；檢查只包含本 task 的預期檔案，不能覆蓋使用者現有變更。

- [ ] **Step 5: 套用 local migration 並驗證 index 使用**

在隔離 local D1 套用 migration，執行 feed/hot 與 users/me 的 `EXPLAIN QUERY PLAN`。預期 feed/hot 能從 score index 以有序掃描開始，users/me 的四類 activity query 能使用對應 user-leading index；若 SQLite 仍選擇其他 index，記錄實際 plan 並在 Task 2/3 調整 SQL，而不是盲目增加 index。

- [ ] **Step 6: Commit**

```bash
git add backend/migrations/0033_api_performance_indexes.sql backend/schema.sql backend/tests/schemaContract.test.ts backend/tests/mappingQueryIndexes.test.ts scripts/db/migration-lock.json
git commit -m "perf(db): add API query indexes"
```

## Task 2: 優化 feed/hot、expression hot search 與 users/me activity

把高頻列表的排序與聚合改成可被 SQLite 直接限制的形狀，同時保留 feed/new 目前 `0032` 的 CTE/created_at 行為。

**Files:**

- Modify: `backend/src/routes/feed.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/routes/users.ts`
- Modify: `backend/tests/feed.test.ts`
- Modify: `backend/tests/expressions.test.ts`
- Modify: `backend/tests/expressionsIntegration.test.ts`
- Modify: `backend/tests/users.test.ts`
- Modify: `backend/tests/mappingQueryIndexes.test.ts`

**Interfaces:**

- Consumes: Task 1 的 `idx_expression_edges_score_feed` 與 user activity indexes。
- Produces: 相同 response fields、pagination contract、filter semantics 與穩定排序；只改 SQL 執行策略。

- [ ] **Step 1: 為 feed/hot 建立排序與 limit 回歸測試**

使用多筆同 score、同 created_at、不同 id 的 fixture，斷言 `/feed/hot` 仍依現有契約排序且 limit/skip 不漂移；對 `/feed/new` 斷言目前 0032 CTE 行為與新索引共存。加入至少一個包含缺少 mapping 的 expression fixture，確保 hot count 為零時仍可正確排序。

- [ ] **Step 2: 驗證 feed/hot 的 index-first query shape**

將 hot query 的 primary scan 改為先從 `expression_edges` 的 score index 取 top-K 候選，再 join expression/attestation 所需資料；若 response 需要 expression-side filters，先以有限候選補足頁面而非退回整表排序。SQL 必須在 `ORDER BY score DESC, created_at DESC, id ASC` 下使用 binding limit，並保持結果去重。

用 `EXPLAIN QUERY PLAN` 驗收不得出現原本的全量 `SCAN ed` + final `USE TEMP B-TREE FOR ORDER BY` 組合；若 filter 使 SQLite 必須回到 fallback query，將 fallback 寫成明確、有上限且有測試的分支。

- [ ] **Step 3: 重寫 expression hot search 的 mapping count**

在 `backend/src/services/expressions.ts` 將目前每個 expression 的 correlated `COUNT` 改成兩段 CTE：

1. `filtered_expressions` 先套用 `lang_code`、`q`、`alpha` 與其他既有 filters。
2. `mapping_counts` 將 `expression_edges.expression_a_id` 與 `expression_b_id` 以 `UNION ALL` 展開，join `filtered_expressions` 後按 expression id 聚合。
3. 主查詢 `LEFT JOIN mapping_counts`，以 `COALESCE(mapping_count, 0)` 加上現有文字/id tie-breaker 排序。

保留 `q` 的 contains semantics（`LIKE '%q%'`），不新增無效的普通 text index；把 `q` 長度與既有 route 上限維持不變。對有 q、無 q、lang filter、alpha filter、零 mapping 五組資料測試結果與 total。

- [ ] **Step 4: 驗證 users/me activity 使用新 indexes**

檢查 `backend/src/routes/users.ts` 的 expressions、edges、handbooks、votes 四個 activity query，將排序統一為與 index 相容的 `created_at DESC, id ASC` 或保留現有契約的等價 tie-breaker。不得為了使用 index 移除 response 的 stable ordering。以 `EXPLAIN QUERY PLAN` 確認 user-leading index 被使用，並測試空結果、分頁及跨表 total。

- [ ] **Step 5: 執行 query-plan 與 API 回歸**

使用固定 local fixture，各 query warm-up 後重複至少 10 次，記錄 median/p95、結果筆數與 plan；不得只以單次最快值判斷。比較重寫前後的 scan rows、temp sort 與 SQL round trips，並把結果留在實作 PR/變更說明中。

- [ ] **Step 6: Commit**

```bash
git add backend/src/routes/feed.ts backend/src/services/expressions.ts backend/src/routes/users.ts backend/tests/feed.test.ts backend/tests/expressions.test.ts backend/tests/expressionsIntegration.test.ts backend/tests/users.test.ts backend/tests/mappingQueryIndexes.test.ts
git commit -m "perf(api): optimize feed search and user activity queries"
```

## Task 3: 限制並批量化 mutation paths

讓所有大陣列輸入在 route 層快速拒絕，並讓 service 層以 bulk resolve + chunked batch 執行，避免目前的逐筆 round trip 與 nested pair loop。

**Files:**

- Create: `backend/src/utils/limits.ts`
- Modify: `backend/src/routes/contributions.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/src/routes/handbooks.ts`
- Modify: `backend/src/services/mappings.ts`
- Modify: `backend/src/services/splits.ts`
- Modify: `backend/tests/contributionsIntegration.test.ts`
- Modify: `backend/tests/localizationIntegration.test.ts`
- Modify: `backend/tests/handbooks.test.ts`
- Modify: `backend/tests/splits.test.ts`
- Modify: `backend/tests/errorResponses.test.ts`

**Interfaces:**

- `backend/src/utils/limits.ts` exports immutable limits and a numeric array clamp/validation helper，不暴露 D1-specific details。
- 初始上限固定為：contribution expressions `50`、localization mappings `100`、handbook sections `50`、handbook items `500`、split edge ids `100`；D1 write chunk 固定為 `50` statements。超限 error code 分別為 `CONTRIBUTION_BATCH_TOO_LARGE`、`LOCALIZATION_BATCH_TOO_LARGE`、`HANDBOOK_BATCH_TOO_LARGE`、`EXPRESSION_SPLIT_TOO_LARGE`。
- 不改變成功 response 的 `expressions`、`edges`、handbook 與 split 欄位；超限一律在任何寫入前回 `400`。

- [ ] **Step 1: 先建立 limits helper 與超限測試**

在 `limits.ts` 定義上述常數與 `assertArrayLimit`/等價 typed helper。為四個 route 加上 body array 為空、剛好等於上限、超過上限、含無效項目的測試；確認超限請求不會建立任何 expression、edge、section 或 split move。

- [ ] **Step 2: 改造 contribution batch**

在 `contributions.ts` 解析後立即檢查上限，先按 `(lang_code, normalized text, locale)` 去重，再一次性解析已存在 expression identity；新增的 expressions 以 chunked D1 writes 建立，最後將 distinct ids 傳給 `createEdgesBatch`。保留「至少兩個 distinct expressions」與現有 `ExpressionError`/`MappingError` response。

在 `mappings.ts` 將 nested pair loop 改為：canonicalize/dedupe pairs → 一次 bulk resolve existing edges → 對缺少 pairs 產生 ULID 並按 50 statements 分 batch insert → 一次讀回結果並按 `score DESC, created_at ASC, id ASC` 或既有 edge order 回傳。每次寫入仍由 UNIQUE constraint 作最後防線。

- [ ] **Step 3: 改造 localization mapping batch**

對 `localization.ts` 的 mappings array 先驗證/去重，批量查出 message source expression 與 target expression；不得每個 mapping 逐一 `SELECT`。以 chunked edge insert 寫入，收集 affected language locale set 後每個 locale 每次 request 只呼叫一次 `recalculateLocale`。單一 mapping route 的既有行為保持不變。

- [ ] **Step 4: 改造 handbook write**

在 `handbooks.ts` 同時限制 sections/items，先完整驗證 hierarchy、expression references 與 duplicate positions，再執行 delete/reinsert。將 statements 按 50 拆成 D1 batch；任何一批失敗都必須保持原子性（使用既有 transaction/batch 邊界或明確 rollback strategy），並保留空 section、排序與公開狀態語義。

- [ ] **Step 5: 改造 split edge selection**

在 `splits.ts` 限制 `edge_ids` 為 100，改用 `json_each(?)` 或等價參數化 row set 取代無界 dynamic `IN`；維持 adjacency validation、edge move audit、dedupe 與原子操作。測試超限、重複 id、非相鄰 edge 與部分失敗時資料不變。

- [ ] **Step 6: 執行 mutation isolation test**

以每個 test case 前後 row count、audit rows 與 revision 值驗證：超限在寫入前拒絕；去重不重複建立 edge；分 batch 不改變回應數量；localization 同一 locale 只重算一次。整合測試必須使用隔離 local D1，不連到含使用者資料的共享 Worker。

- [ ] **Step 7: Commit**

```bash
git add backend/src/utils/limits.ts backend/src/routes/contributions.ts backend/src/routes/localization.ts backend/src/routes/handbooks.ts backend/src/services/mappings.ts backend/src/services/splits.ts backend/tests/contributionsIntegration.test.ts backend/tests/localizationIntegration.test.ts backend/tests/handbooks.test.ts backend/tests/splits.test.ts backend/tests/errorResponses.test.ts
git commit -m "perf(api): bound and batch mutation workloads"
```

## Task 4: 限制 localization candidates，消除 coverage/workbench 重複工作

把候選列的「按 source/message 取第一筆或前五筆」移到 SQL，並讓 coverage 與 workbench page 不再各自把同一批候選全部載入記憶體。

**Files:**

- Modify: `backend/src/services/localizedName.ts`
- Modify: `backend/src/services/localizationDomain.ts`
- Modify: `backend/src/services/workbench.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/tests/localizedName.test.ts`
- Modify: `backend/tests/localizationDomain.test.ts`
- Modify: `backend/tests/workbench.test.ts`
- Modify: `backend/tests/localizationIntegration.test.ts`

**Interfaces:**

- Candidate ranking固定為現有優先順序：`score DESC, created_at ASC, edge_id ASC`；同一 source/message 只取最優 candidate，workbench 每 message 最多取 5 筆。
- coverage 只回傳目前 response 所需的 coverage count，不再依賴載入全部 candidate rows；workbench 仍回傳同一 page/total 欄位。
- candidate SQL 必須使用 `ROW_NUMBER() OVER (PARTITION BY ...)` 或等價 correlated `LIMIT`，並以 `UNION ALL` 分開 expression edge 的 a/b endpoint branch；不得以 OR join 讓 planner 退回全量候選後再由 JS 截斷。

- [ ] **Step 1: 建立候選排序與上限測試 fixture**

在三組 service tests 建立同一 message/source 對應多個 target expression、兩個 endpoint 方向、同分數與多 locale 的 fixture；斷言 localized name 取第一筆、workbench 每 message 最多五筆、tie-breaker 穩定，且不因 global row limit 讓後面的 message 永遠沒有候選。

- [ ] **Step 2: 重寫 `localizedName.ts` candidate query**

將 `CANDIDATE_SQL` 拆成 source expression 與 target expression 兩個 index-friendly branch，`UNION ALL` 後按 source expression 分區排名，SQL 端只保留 `row_number = 1`。`loadCandidateMap` 只做 mapping，不再從大結果集挑第一列；保留 language fallback 與 locale priority。

- [ ] **Step 3: 重寫 `localizationDomain.ts` candidate/coverage**

以同樣的 endpoint branch 與 partition ranking 供 `loadCandidatesForLanguage` 使用；`computeCoverage` 改為直接在 bounded candidate relation 上計算 active message key 的 distinct translated count。`recalculateForExpressions` 先 dedupe affected expression ids 與 locale codes，再逐 locale 執行一次，不重複掃相同候選。

- [ ] **Step 4: 重寫 `workbench.ts` 分頁候選**

移除目前 global `LIMIT 500` 再由 TypeScript 每 message 留 5 筆的做法。以 message key/source expression 分區取 top 5，再在外層按既有 message order 套 page limit/offset；total query 只計 active message rows，不把 candidate row 數誤當 message total。`q` filter 的 semantics 與上限維持現有 route contract。

- [ ] **Step 5: 合併 workbench route 的重複查詢**

在 `localization.ts` 的 workbench handler 使 coverage 與 page query 共用同一個 bounded candidate scope/SQL helper；至少避免 coverage 先載入全量 candidates、page 再重做一次。若要保留獨立 total query，確保它只做 `COUNT`，不 materialize candidate payload。

- [ ] **Step 6: 驗證 candidate query plan 與 memory upper bound**

用 10,000+ candidate fixture 執行 `EXPLAIN QUERY PLAN`，確認 a/b branches 使用 `idx_expression_edges_a_id`/`idx_expression_edges_b_id`，SQL 端 row count 不超過 message count × 5（workbench）或 message count（localized name）。比較 coverage/workbench 的 D1 round trips、回傳 bytes 與 median/p95。

- [ ] **Step 7: Commit**

```bash
git add backend/src/services/localizedName.ts backend/src/services/localizationDomain.ts backend/src/services/workbench.ts backend/src/routes/localization.ts backend/tests/localizedName.test.ts backend/tests/localizationDomain.test.ts backend/tests/workbench.test.ts backend/tests/localizationIntegration.test.ts
git commit -m "perf(localization): bound translation candidate queries"
```

## Task 5: 並行化獨立讀取與消除 fallback N+1

這一 task 只處理已確認互不依賴的 read queries；不把有順序依賴或需維持錯誤 precedence 的查詢硬改成並行。

**Files:**

- Modify: `backend/src/services/languageContent.ts`
- Modify: `backend/src/services/mappings.ts`
- Modify: `backend/src/services/expressions.ts`
- Modify: `backend/src/services/languageIdentity.ts`
- Modify: `backend/tests/languageContent.test.ts`
- Modify: `backend/tests/mappings.test.ts`
- Modify: `backend/tests/expressionDetail.test.ts`
- Modify: `backend/tests/languageIdentity.test.ts`

**Interfaces:**

- 外部回應 JSON、欄位順序與錯誤 code 不變。
- `Promise.all` 只用於同一輸入下無資料依賴的 SELECT；任何需要前一 query id/存在性結果的操作仍維持順序。
- fallback name 改為一次按 language code 的批量查詢，再在記憶體以 Map lookup；禁止重新引入 per-item SELECT。

- [ ] **Step 1: 為 query round trips 建立行為測試**

在現有 service tests 固定 response 結果，並以 mock D1 statement counter 或 integration query log 驗證：language detail 的 locale/counts、language expressions 的 total/page、mapping count/page、expression attestations/readings 各自不再因串行而增加查詢數，且仍產生相同資料。

- [ ] **Step 2: 並行 language 與 expression detail reads**

在 `languageContent.ts` 對 locale query、三個 count query，以及 list total/page query 使用 `Promise.all`；在 `expressions.ts` 對 attestations/readings 使用 `Promise.all`。先完成需要的 primary row lookup，再並行 dependent reads。

- [ ] **Step 3: 並行 mapping count/page 與 reference existence checks**

在 `mappings.ts` 對 count/page 使用 `Promise.all`。在 `languageIdentity.ts` 對 language/script/region reference checks 並行執行，最後以固定欄位順序檢查結果，保留原本第一個 validation error code。

- [ ] **Step 4: 批量化 localized fallback**

收集所有缺少 resolved name 的 language codes，使用一個 `IN (SELECT value FROM json_each(?))` 或等價參數化查詢載入 fallback names；以 Map 回填，保留每個 item 原有 fallback priority 與 null 行為。空集合不得發出 SQL。

- [ ] **Step 5: 驗證錯誤與資料一致性**

測試缺 locale、缺 language、空列表、DB read reject 及 partial result 情況，確認並行化不會把錯誤轉成 500、吞掉原有 error code 或改變 HTTP status。完成後比較各 endpoint SQL round trips 與 wall-clock median/p95。

- [ ] **Step 6: Commit**

```bash
git add backend/src/services/languageContent.ts backend/src/services/mappings.ts backend/src/services/expressions.ts backend/src/services/languageIdentity.ts backend/tests/languageContent.test.ts backend/tests/mappings.test.ts backend/tests/expressionDetail.test.ts backend/tests/languageIdentity.test.ts
git commit -m "perf(api): parallelize independent reads"
```

## Task 6: Graph frontier guardrail、完整驗證與交付報告

圖譜目前已有 node limit、cycle handling、dedupe 與穩定排序；先以可觀測 row count 找出高 degree frontier，不直接用隱性截斷改變 graph semantics。只有測試明確定義 truncation metadata 後，才可在後續計劃引入 per-frontier edge cap。

**Files:**

- Modify: `backend/src/services/mappingGraph.ts`
- Modify: `backend/tests/mappingGraphV2.test.ts`
- Modify: `backend/tests/mappingQueryIndexes.test.ts`
- Modify: `docs/superpowers/plans/2026-08-22-backend-api-sql-performance-optimization.md`（實作完成後補上實測結果區；不改寫審計結論）

**Interfaces:**

- graph response shape、`nodes`/`edges`/`truncated` semantics 不變。
- 新增的 row-count guard 只用於測試/內部診斷，不能把診斷欄位暴露成未定義的 public API。

- [ ] **Step 1: 增加 frontier row-count regression fixture**

建立高 degree root、重複 edge、cycle 與多 hop fixture，斷言 node limit、edge dedupe、stable order 與目前 response 不變；記錄每輪 frontier 的 SQL rows，確保 benchmark 能辨識「結果 node 少」與「SQL 中間列爆量」的差異。

- [ ] **Step 2: 決定是否需要 per-frontier cap**

以固定資料量與 production-like degree distribution benchmark。只有當單一 frontier SQL rows 造成 p95 明顯上升，且可接受「每 frontier top-N + `truncated` 明確表示」的產品語義時，才在 mappingGraph service 另加參數化 window query；否則保留目前完整 edge semantics，將 graph cap 列為後續非本計劃範圍。

- [ ] **Step 3: 執行完整 backend 驗證**

```bash
cd backend && npm test
cd backend && npm run build
git diff --check
```

整合測試需先啟動 local Worker（`127.0.0.1:8788`）並使用隔離 local D1；針對受影響檔案先執行：

```bash
cd backend && npx vitest run tests/feed.test.ts tests/expressions.test.ts tests/users.test.ts tests/workbench.test.ts tests/localizationDomain.test.ts tests/mappingGraphV2.test.ts
```

再執行完整測試與 integration suite。若 repo script 對 integration 有既定命令，沿用 `package.json`，不要自行連線到 production。

- [ ] **Step 4: 以 EXPLAIN 與 HTTP benchmark 交付數據**

對下列代表性 endpoints 各 warm-up 後重複至少 10 次，記錄 median/p95、status、payload bytes、D1 query count 與主要 query plan：

`/api/v2/feed/hot`、`/api/v2/feed/new`、`/api/v2/expressions/search`（有 q/無 q）、`/api/v2/users/me`、language detail、mapping list、expression detail、localization workbench、mapping graph。

交付報告至少包含：

- 哪些 query 從 full scan/temp sort 改為 index/limited scan。
- 每個 mutation path 的 hard limit、chunk size 與超限 error code。
- coverage/workbench 是否消除重複 candidate materialization。
- 讀取 round trips、median/p95 與回應 bytes 的前後比較。
- 未改善或無法在本計劃安全修改的項目（`LIKE '%q%'`、graph high-degree cap、production field data 缺失）。

- [ ] **Step 5: 最終檢查與 Commit**

確認 migration lock、schema parity、測試結果、`git diff --check` 與工作樹中使用者既有變更均無被覆蓋；再按每個 task 的小 commit 或合併成一個 Conventional Commit 交付。

---

## 非本計劃範圍

- 不在沒有 benchmark 證據下新增 `expression_stats`/denormalized counter table。
- 不因 `LIKE '%q%'` 看到全表掃描就新增無效 B-tree；若搜尋成為主要瓶頸，另立 FTS5/搜尋索引設計與 migration 計劃。
- 不直接移除 Google Fonts、CSS、cache header 或前端資產；Chrome baseline 的 LCP 約 550ms、CLS 0，render-blocking resource 預估節省為 0ms，當前沒有證據顯示 backend query 是首要頁面 LCP 瓶頸。
- 不在本計劃中改寫整個 mapping graph 演算法或改變 graph completeness contract。

## 實作完成驗收門檻

- `backend/schema.sql` 與 migrations 的新增 index 完全一致，migration lock 更新且 local D1 可由零重建。
- 所有 batch mutation 超限在第一次寫入前回 `400`，正常輸入的 response 與資料結果與 baseline 一致。
- feed/hot、users/me、localization candidate query 的 `EXPLAIN QUERY PLAN` 與 benchmark 顯示 scan/temp sort 或 materialized rows 有可量化改善；expression hot search 若 benchmark 未改善，保留原有按 expression 索引查詢並記錄為後續 FTS/統計設計候選。
- 既有 `0032` feed/new 行為、stable ordering、graph cycle/dedupe、權限與錯誤契約通過回歸測試。
- `cd backend && npm test`、必要 integration tests、`npm run build`、`git diff --check` 全部通過；任何未能驗證的 production 指標明確標註為限制。

## 本 session 執行記錄（2026-08-23）

### 已完成

- [x] 新增 `0033_api_performance_indexes.sql`，並同步 `backend/schema.sql` 與 migration lock；local D1 已套用並驗證。
- [x] 對 feed、users、handbooks、votes 的高頻條件補上複合索引；保留使用者既有的 `0032` feed/new 變更。
- [x] 移除 localization name fallback 的逐筆 N+1 查詢，將 localization domain、localized name、workbench 的候選查詢改為 endpoint-specific `UNION ALL`、SQL-side ranking 與 top-N 限界。
- [x] 對 contribution、localization、handbook、split mutation 增加 hard limit；localization mapping 改為去重、批量載入與分批寫入。
- [x] 對 language detail、language expressions、mapping list、expression detail、reference existence checks 的獨立讀取使用 `Promise.all`。
- [x] 補上 SQL shape、batch limit、schema/index、integration regression tests。

### 有意保留／延後

- [x] expression hot search 的 CTE 聚合改寫已用 `EXPLAIN QUERY PLAN` 與 cache-busting HTTP benchmark 驗證；它會完整掃描兩次 `expression_edges`，目前約為無 q 63ms、含 q 41ms，劣於審計基準約 39–41ms、18–19ms，因此已回退，保留原有按 expression 的索引查詢。
- [ ] 不在本 session 引入 expression stats/denormalized counter 或 FTS5；需另以 production-like benchmark 與資料模型計劃處理。
- [ ] 不改變 mapping graph 的 completeness contract；高 degree frontier 只保留為後續觀測與 benchmark 項目。

### 驗證結果

- `cd backend && npm run types:check`：通過。
- `cd backend && npx vitest run`：40 個 test files、294 個 tests 全部通過。
- `git diff --check`：通過。
- local cache-busting HTTP benchmark：`feed/hot` median 5.68ms/p95 8.94ms；`feed/new` 4.91ms/6.31ms；expression search hot 無 q 63.12ms/67.20ms、有 q 40.94ms/48.10ms；`languages` 12.38ms/20.44ms。這些是 local D1/Worker 指標，不代表 production SLO，也未包含 production field data。
