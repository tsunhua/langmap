# Handbook translations 實作計畫

> **For agentic workers:** 按核准規格逐步實作；每個步驟完成後執行該步驟列出的驗收。

**Goal:** 讓 handbook 翻譯查詢支援每筆來源自己的語言，並在單次候選查詢後只載入實際返回譯詞的讀音。

**Architecture:** 後端以 item locale 解析來源 expression 與語言，使用單次 CTE 查詢完成候選排序，再以返回的譯詞 ID 查讀音。前端沿用現有選取與 session cache，修正圖譜篩選條件及快取版本。

**Tech Stack:** PostgreSQL、Hono service、Vitest、Vue 3、Vue Test Utils。

**Spec:** `docs/superpowers/specs/2026-09-29-handbook-translations-performance-and-direction.md`

## 全域限制

- 不改 schema、migration、公開 API 欄位、Apple 客戶端或即時翻譯 endpoint。
- 來源候選只取精確 locale link；保留 edge `score >= 0`、既有排名與完整候選計數。
- 譯詞上限為每來源 3 筆、最多 5000 個有候選來源及 15000 筆讀音。
- 讀音 ID 使用一個綁定的 `bigint[]` 參數；沒有譯詞時跳過讀音查詢。
- 前端沿用現有 request 序號、取消機制與選取流程；舊版 session cache 透過 `v2` key 失效。

---

### Task 1：後端來源方向與單次候選查詢

**Files:**
- 修改：`backend/src/services/handbookTranslations.ts`
- 修改：`backend/tests/handbookTranslations.test.ts`
- 新增：`backend/tests/handbookTranslationsPg.test.ts`

**介面：**
- 輸入仍為 `getHandbookTranslations(db, handbookId, targetLocale, options)`。
- 回應仍為 `HandbookTranslationsResponse`。
- 邊查詢回傳最終有序譯詞；讀音查詢綁定 `[targetIds, localeId, 15000]`。

- [x] 先擴充 mock 測試：驗證來源方向 SQL、最早實際位置、回傳 target IDs 綁定、無譯詞不執行讀音 SQL、來源上限及 SQL statement 數量。
- [x] 執行 `cd backend && npm test -- tests/handbookTranslations.test.ts`，確認新增案例先失敗。
- [x] 改寫 `SOURCE_ITEMS` 以 locale 對應語言解析，使用 `DISTINCT ON` 保留最早的一整組位置；正反向候選按 source language ID 排除同語言 target。
- [x] 移除讀音查詢中的候選 CTE，先從最終輸出收集排序後唯一 ID，再用一個 `ANY(?::bigint[])` 參數載入讀音；依實際返回數量計算 hidden count。
- [x] 新增隔離 PostgreSQL 測試，沿用 `TRANSLATION_TEST_DATABASE_URL` 與既有隔離 schema 模式，驗證不同來源方向、精確 locale、edge 資格、位置排序、array 綁定、5000 來源與 15000 讀音上限。
- [x] 執行 `cd backend && npm test -- tests/handbookTranslations.test.ts tests/handbookTranslationsPg.test.ts`；mock 測試通過，PostgreSQL 案例因未設定連線變數而跳過。

### Task 2：前端圖譜篩選與翻譯快取版本

**Files:**
- 修改：`web/src/pages/HandbookView.vue`
- 修改：`web/src/pages/HandbookView.test.ts`

**介面：**
- 翻譯 API、型別及 picker 維持原樣。
- 圖譜僅在 managed handbook、target language 與目前所選語言均已知且不同時帶入 target language。

- [x] 新增測試：中文來源選取帶 target language 篩選；點選 target-language 譯詞不帶篩選；未知新選取不沿用前一節點語言。
- [x] 新增測試：`v2` cache 不讀舊版空結果、locale 不符的快取失效、有效新版快取可重用。
- [x] 執行 `cd web && npm test -- src/pages/HandbookView.test.ts`，確認新案例先失敗。
- [x] 將 cache key 換成 `handbook:${id}:translations:v2:${locale}:${fingerprint}`，讀取時驗證 `target_locale`；圖譜條件只根據當前所選節點語言計算。
- [x] 重跑上述頁面測試並執行 `cd web && npm run build`。

### Task 3：跨接入驗收

**Files:**
- 檢查：本計畫涉及的 service、頁面、單元與 PostgreSQL 測試。

- [x] 執行後端相關測試及 Web build，修正整合造成的型別或契約問題。
- [x] 檢查 SQL 綁定順序、response 上限、來源順序、cache key 與選取 request guard 對照規格。
- [x] 執行 `git diff --check`，確認沒有生成檔或無關檔案變更。
