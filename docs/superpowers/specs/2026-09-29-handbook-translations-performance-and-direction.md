# Handbook translations 效能與來源方向規格

> 日期：2026-09-29
>
> 狀態：程式已實作；真 PostgreSQL 與效能驗收待隔離資料庫。

## 問題與現況

`GET /api/v2/handbooks/:id/translations` 目前有兩項已由程式碼確認的問題：

1. `SOURCE_ITEMS` 以 `source_language.code='eng'` 限制來源，因此非英語來源的 handbook 不會產生來源項目；中文來源呼叫 translations endpoint 會得到空的 `items`。
2. `getHandbookTranslations` 先執行 `edgeSql`，再執行 `readingSql`。兩個獨立 SQL statement 都包含 `source_items`、`candidate_edges`、`unique_edges` 與 `ranked_edges`，讀音查詢因此重算整個候選邊圖。

設計審閱僅核對程式與 schema，未重新量測先前回報的每條 SQL 約 5 秒；該數字是歷史量測，不是目前基準。本次實作加入了隔離 PostgreSQL 測試，但目前沒有設定 `TRANSLATION_TEST_DATABASE_URL`，真資料庫案例及效能基準尚未執行。

審閱另確認三個接入缺口：瀏覽器 session cache 可能保留舊版非英語來源的空結果；expression inspector 同時供來源、譯詞及關聯節點使用，不能一律套用目標語篩選；來源去重分別取 `MIN(s.position)` 與 `MIN(i.position)`，可能拼出不屬於任何一次出現的位置。

先前兩項查詢修正已存在於目前程式：handbook detail 與來源項目的 expression 解析使用語言及詞面精確條件；目標邊以 `locale_id` 篩選。這些既有修正不在本規格的實作範圍。

Cloudflare token 的 zone route／Hyperdrive 權限屬外部憑證狀態，repo 無法證實目前權限；本地 Wrangler Hyperdrive 連線變數亦未列在 README 的本機設定範例。本規格不包含憑證、部署權限或本機環境文件處理。

## 目標

- handbook 的每個來源 item 均以自己的 locale 與 expression 語言判斷來源，不限定英文來源。
- 保留目前候選資格、排名、總數、隱藏數與回應欄位，修正重複來源位置及讀音上限被未返回譯詞占用的問題。
- 每個 request 只計算一次 handbook 翻譯候選邊及其排名；讀音查詢只讀取該次結果選出的譯詞。
- 前端可取得新方向的結果，並可從譯詞查看原文關係。
- 在代表性資料量上量測前後差異，不將 Hyperdrive 冷啟動時間誤認為 SQL 改善。

## 範圍與接入面

- 後端主要修改點：`backend/src/services/handbookTranslations.ts`。
- 服務測試：`backend/tests/handbookTranslations.test.ts`；真 PostgreSQL 覆蓋新增於 `backend/tests/handbookTranslationsPg.test.ts`，沿用 `backend/tests/translationRetrievalPg.test.ts` 的隔離 schema 方法。route 契約沿用 `backend/tests/handbooks.test.ts`。
- 前端接入與測試：`web/src/pages/HandbookView.vue`、`web/src/pages/HandbookView.test.ts`。
- 不改 API 型別或翻譯清單視覺呈現。
- 不改資料庫 schema、migration、公開 API envelope、Apple 客戶端或一般即時翻譯 endpoint。

## 行為與資料契約

### 來源與目標方向

- 每個 `handbook_section_items` row 的 `language_locale_id` 決定其來源語言；依該 locale 與 item 文字解析 canonical expression，沿用既有 expression identity 與 locale link 規則。
- 移除來源必須為 `eng` 的限制。混合語言 handbook 逐 item 判定來源語言；無法依文字、語言與精確 locale link 解析的 item 略過，不猜測來源或補造 expression。
- `source_items` 從既有解析步驟的 `ex.language_id` 帶出 `source_language_id`，避免再為判斷來源語加入 registry 查詢或重複 expression JOIN。
- 正向及反向候選均須有指定 `target_locale` 的精確 link，沿用直接 edge 與 `score >= 0` 資格；以 `target_language.id <> source_items.source_language_id` 排除同語言目標。
- 同語言跨 script、region 或 place 的排除僅是本 endpoint 已核准的顯示政策；不改 canonical mapping，也不表示同語言 mapping 無效。

### 回應與排序

- 保留 `{ success, data }` envelope 與 `HandbookTranslationsResponse` 欄位，不新增來源方向參數。
- 重複來源 expression 取實際最早出現的 `(section_position, item_position)`，例如以 `DISTINCT ON (expression_id)` 選取排序後的一整列；不能分別取兩個位置的最小值。來源依該位置對及 expression ID 穩定排序。
- 同一來源的候選 edge 去重後，依既有 `edge_score DESC, LOWER(target_text), target_text, target_expression_id` 排序。
- 每個來源最多返回 3 個翻譯；`total_translation_count` 是去重後的完整合格候選數，`hidden_translation_count = max(0, total_translation_count - translations.length)`。不得在完整計數前截斷候選。
- 依既有排序返回最多 5000 個有譯詞的來源、15000 筆翻譯；來源無候選時不產生 response item。5000 是輸出來源上限，不能先取 5000 個 handbook items 而漏掉後續有候選的來源。
- 讀音僅限指定 locale；全域最多返回 15000 筆唯一 `(expression_id, scheme, value)`，按這三欄排序後截斷。這是讀音列上限，不是譯詞上限，也不保證每個譯詞的全部讀音都已返回。
- handbook 私有權限、無效 handbook、無效 target locale 與既有錯誤碼保持不變。

## 查詢設計

1. 保留 handbook 權限與 target locale 的前置查詢。`edgeSql` 一次完成來源解析、候選、去重、完整計數及排名，再套用既有翻譯列上限。
2. 先依 `edgeRows` 組出最終返回的來源及譯詞，落實 5000／3 的上限；再從這份結果收集去重、數值排序的 target ID，最多 15000 個。被輸出上限捨棄的來源或譯詞不得占用讀音配額。
3. 有 target ID 時執行一次下列讀音查詢，將整個 ID 陣列作為一個參數綁定；沒有 ID 時略過。現有 `pgDatabase` 會把參數直接交給 `pg.Client.query`，已安裝的 `pg` 支援 JS 陣列；schema 的 expression ID 為 `BIGINT`，不需新增 adapter 能力或分批 fallback。

   ```sql
   SELECT expression_id, scheme, value
   FROM expression_readings
   WHERE expression_id = ANY(?::bigint[]) AND locale_id = ?
   ORDER BY expression_id, scheme, value
   LIMIT ?
   ```

   綁定順序為 `[targetIds, locale.id, 15000]`，不展開 ID 為大量 placeholder 或插入 ID 字串。既有主鍵 `(expression_id, locale_id, scheme, value)` 保證同 locale 的讀音列唯一，無須額外 JOIN、排名或聚合。
4. 讀音依 expression ID 附回譯詞；同一譯詞被多個來源引用時共用查詢結果，不重複讀取。查詢失敗沿用既有錯誤處理，不以成功的空讀音回應掩蓋失敗。

沿用兩段資料查詢與目前 response 組裝方式，只移除第二段的候選圖重算。兩次查詢維持既有的即時讀取語義：讀音若在其間刪除，該譯詞可返回空讀音；不新增 transaction 或一致快照承諾。

## 前端接入

- `HandbookView.vue` 沿用目前選取流程，將圖譜的 `lang_code === 'eng'` 條件一般化：managed handbook、有 target language、所選 expression 的語言已知且不同於 target language 時才傳入目標語篩選。
- 點選目標譯詞時，其語言與 target language 相同，圖譜不帶此篩選，避免排除原文關係；返回節點仍受既有圖譜上限約束。沒有 target 或所選語言未知時也不帶篩選；不得以先前選中 expression 的語言判斷新 ID。
- 圖譜 API 只有語言篩選，可能包含該語言其他 locale 的節點；精確 locale 限制只由 translations 清單保證。沿用切換目標時重載 inspector 與忽略晚到結果的機制，不新增選取狀態模型。
- 翻譯 session cache key 加入明確版本：`handbook:${handbookId}:translations:v2:${locale}:${sourceFingerprint}`。讀寫共用此 key，舊版空結果不再阻止 request；已選 target locale 的偏好 key 保持原樣。新版本中正常的空結果仍可暫存。
- 沿用 storage 失敗／損毀時重新取 API 的處理；cache 的 `target_locale` 必須與此次 request 一致。保留取消與 request 序號檢查，快取和晚到結果均不可覆蓋新的 handbook／locale。

## 驗收

### 行為驗收

- 在未觸及全域上限、沒有重複來源位置的英文 fixture，譯詞、排序、計數與讀音與基準一致；重複位置及未返回譯詞占用讀音配額的差異按上述修正驗收。
- 中文來源到英語或其他不同語言的 target locale，在 fixture 有相符 mapping 時會返回來源項目與譯詞；過去固定為空的案例不再為空。
- 混合來源語言 handbook 逐 item 排除同語言目標，並可返回各 item 不同語言的目標。
- 來源在 `(section=1,item=8)` 與 `(section=2,item=0)` 重複出現時，取 `(1,8)`；另一個位於 `(1,4)` 的來源必須排在它之前。
- 非英語來源的 inspector 套用 target language；點選該目標語譯詞後，圖譜仍能顯示原文。清除／切換 target、未知選取語言及晚到結果均按前端接入規則處理。
- 舊版本 session cache 含空 `items` 時仍會請求 API 並顯示新譯詞；新版本快取可重用，偏好、cache 損毀與 storage 不可用不影響載入。
- 不同 script／region 的同語言 locale 不會作為翻譯候選；target locale 不吻合的譯詞不會返回。
- 以真 PostgreSQL 驗證正反向 edge、精確 locale、`score >= 0`、同語言排除、排序與計數，以及 `bigint[]` 綁定。SQL 字串或 mocked rows 不能代替這些驗收。
- 覆蓋無候選時略過讀音 SQL、共享 target ID 只綁一次、多 scheme／無讀音、3 個譯詞與完整 count、5001 個有候選來源，以及超過 15000 筆讀音時的全域排序截斷。讀音綁定 ID 必須恰好等於最終 response 中的 target ID 集合。
- 私有 handbook 權限與既有 route 錯誤回歸不變。

### 效能驗收

- SQL 記錄證明 request 中完整候選／排名 CTE 只在邊查詢執行一次；讀音查詢只依已選譯詞 ID 與 locale 篩選。
- `getHandbookTranslations` 正常有譯詞時最多執行 4 個 statements（2 個前置查詢、1 個候選查詢、1 個讀音查詢）；無譯詞時不執行讀音查詢。此數量不包含 route 的其他服務。
- 在隔離 PostgreSQL、相同快照及 target locale 上，以原本已支援的英文來源 fixture 比較前後，確保候選數與返回量相同；不得拿新版有結果的中文來源與舊版空結果比較效能。非英語案例另驗功能並記錄耗時。
- 小型與接近 5000 個有候選來源的 fixture 各記錄資料量及 `EXPLAIN (ANALYZE, BUFFERS)`。同一環境每版本先暖機 5 次，再至少量測 20 次，交錯比較並回報主要資料 SQL 的 p50／p95。API 整體耗時與連線耗時另記，瀏覽器 session cache 或 Hyperdrive query cache 命中不作為 SQL 加速證據。
- 大型 fixture 的主要資料 SQL 總耗時中位數須低於基準，且差異超過重複量測的波動；小型 fixture 不得有可重現的退步。若未改善，先以查詢計畫定位，不宣稱已解決效能問題。
- 不以單次冷啟動延遲或 production request 的偶發耗時作為唯一結論；不承諾固定秒數。

## 非目標與限制

- Cloudflare token scope、Workers Routes／Hyperdrive 權限及部署錯誤處理。
- README、`.dev.vars` 範例或本地 Hyperdrive connection string 設定。
- 同語言跨 script／region 的轉寫或變體改寫。
- 新增 index、materialized view、sense model、schema migration 或 API 分頁。
- 通用快取框架、選取狀態重構、讀音分頁或新增效能監控系統。
- 對 30 秒 statement timeout 的調整。完整候選總數仍需計算；若移除重複計算後仍慢，需另提保留 count 語義的查詢設計。
