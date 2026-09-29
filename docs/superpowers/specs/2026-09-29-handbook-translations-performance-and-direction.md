# Handbook translations 效能與來源方向規格

> 日期：2026-09-29
>
> 狀態：設計已核准，待實作。

## 問題與現況

`GET /api/v2/handbooks/:id/translations` 目前有兩項已由程式碼確認的問題：

1. `SOURCE_ITEMS` 以 `source_language.code='eng'` 限制來源，因此非英語來源的 handbook 不會產生來源項目；中文來源呼叫 translations endpoint 會得到空的 `items`。
2. `getHandbookTranslations` 先執行 `edgeSql`，再執行 `readingSql`。兩個獨立 SQL statement 都包含 `source_items`、`candidate_edges`、`unique_edges` 與 `ranked_edges`，讀音查詢因此重算整個候選邊圖。

本次無法重現先前回報的每條 SQL 約 5 秒；該數字視為歷史量測，不是目前基準。規格要求以相同隔離 PostgreSQL 資料集重新量測，分開記錄暖機與暖連線結果。

先前兩項查詢修正已存在於目前程式：handbook detail 與來源項目的 expression 解析使用語言及詞面精確條件；目標邊以 `locale_id` 篩選。這些既有修正不在本規格的實作範圍。

Cloudflare token 的 zone route／Hyperdrive 權限屬外部憑證狀態，repo 無法證實目前權限；本地 Wrangler Hyperdrive 連線變數亦未列在 README 的本機設定範例。本規格不包含憑證、部署權限或本機環境文件處理。

## 目標

- handbook 的每個來源 item 均以自己的 locale 與 expression 語言判斷來源，不限定英文來源。
- 保留目前排名、總數、隱藏數、讀音與回應契約。
- 每個 request 只計算一次 handbook 翻譯候選邊及其排名；讀音查詢只讀取該次結果選出的譯詞。
- 在代表性資料量上量測前後差異，不將 Hyperdrive 冷啟動時間誤認為 SQL 改善。

## 範圍與接入面

- 後端主要修改點：`backend/src/services/handbookTranslations.ts`。
- 前端翻譯清單依 `source_expression_id` 索引結果，沒有英語來源過濾；但 `web/src/pages/HandbookView.vue` 目前只在來源 expression 為英文時，才將所選目標語言傳給 mapping graph。來源方向擴充時，該圖譜篩選須對所有 managed handbook 來源語生效。
- 服務測試：`backend/tests/handbookTranslations.test.ts`；route 契約覆蓋依需要更新 `backend/tests/handbooks.test.ts`。
- 前端接入與測試：`web/src/pages/HandbookView.vue`、`web/src/pages/HandbookView.test.ts`。
- 不改 API 型別或翻譯清單視覺呈現。
- 不改資料庫 schema、migration、公開 API envelope、Apple 客戶端或一般即時翻譯 endpoint。

## 行為與資料契約

### 來源與目標方向

- 每個 `handbook_section_items` row 的 `language_locale_id` 決定其來源語言；依該 locale 與 item 文字解析 canonical expression，沿用既有 expression identity 與 locale link 規則。
- 移除來源必須為 `eng` 的限制。混合語言 handbook 逐 item 判定來源語言，不假設整本 handbook 只有一種語言。
- 目標候選仍須連到 request 指定的精確 `target_locale`，並支援 mapping edge 的正向及反向方向。
- `source_items` 必須帶出 canonical source expression 的 `source_language_id`；正向及反向候選都以 `target_language.id <> source_items.source_language_id` 排除同語言目標。
- 不同 script、region 或 place 的同語言 locale 不算本 endpoint 的翻譯目標；此規則延續目前英文來源不返回英文目標的語義。

### 回應與排序

- 保留 `{ success, data }` envelope 與 `HandbookTranslationsResponse` 欄位，不新增來源方向參數。
- 來源 item 依 section position、item position 與 expression ID 穩定排序；重複出現的同一來源 expression 仍合併。
- 同一來源的候選 edge 去重後，依既有 `edge_score DESC, LOWER(target_text), target_text, target_expression_id` 排序。
- 每個來源最多返回 3 個翻譯；`total_translation_count` 必須是去重後的完整候選數，`hidden_translation_count` 必須與此數一致。不得在完整計數前套用候選上限。
- 保留目前 5000 個來源 item 與 15000 筆翻譯／讀音查詢結果上限、讀音 locale 篩選、讀音去重與穩定排序。
- handbook 私有權限、無效 handbook、無效 target locale 與既有錯誤碼保持不變。
- managed handbook 中選取任何來源語的 expression 時，mapping graph 均依所選 target locale 的語言篩選；非 managed handbook 不新增此篩選。

## 查詢設計

1. `edgeSql` 負責解析來源 items、取得 locale 相符的正反向候選、去重、計數及排名，並維持既有翻譯數量上限。
2. 從 `edgeRows` 收集並去重實際返回的 `target_expression_id`。沒有譯詞時略過讀音查詢。
3. `readingSql` 直接從 `expression_readings` 依這組已選譯詞 ID 及 request 的 `locale_id` 取得讀音。使用目前 PostgreSQL adapter 支援的參數化集合查詢；不得把 ID 值字串插入 SQL。若 adapter 對單次集合大小有限制，可分批讀取，但不得重跑來源、候選、去重或排名 CTE。
4. 讀音結果繼續依 expression ID 組回翻譯；response 不因一個譯詞有多筆讀音而重複譯詞。

不合併成一條帶讀音展開的查詢，避免 edge × reading 行數膨脹及額外聚合解析。也不在排名／計數前提早截斷候選，因為這會破壞完整翻譯數與隱藏數契約。

## 驗收

### 行為驗收

- 英文來源到不同語言的既有結果、排序、總數、隱藏數及讀音與基準一致。
- 中文來源到英語或其他不同語言的 target locale，在 fixture 有相符 mapping 時會返回來源項目與譯詞；過去固定為空的案例不再為空。
- 混合來源語言 handbook 逐 item 排除同語言目標，並可返回各 item 不同語言的目標。
- 從非英語來源 item 開啟 expression inspector 時，mapping graph 使用目前選取的 target language，與翻譯清單方向一致。
- 不同 script／region 的同語言 locale 不會作為翻譯候選；target locale 不吻合的譯詞不會返回。
- 覆蓋正向與反向 edge、重複 edge、同來源重複位置、沒有讀音的譯詞、讀音重複、空候選、每來源三譯詞上限、完整 count 與全域數量上限。
- 私有 handbook 權限與既有 route 錯誤回歸不變。

### 效能驗收

- SQL 記錄證明 request 中完整候選／排名 CTE 只在邊查詢執行一次；讀音查詢只依已選譯詞 ID 與 locale 篩選。
- 在隔離 PostgreSQL、相同資料快照及 target locale 上，比較修改前後的查詢計畫及 endpoint 耗時。使用代表性大型 handbook（含接近 5000 個來源 item 的壓力情境），暖機與暖連線分開記錄；多次量測回報 p50、p95，並明確列出資料量與執行環境。
- 大型 handbook 的 endpoint 查詢總耗時中位數須低於修改前基準；若只減少 CTE 重算但未改善此指標，不視為完成，需檢查讀音查詢、資料分佈與 query plan。
- 不以單次冷啟動延遲或 production request 的偶發耗時作為唯一結論；不承諾固定秒數。

## 非目標與限制

- Cloudflare token scope、Workers Routes／Hyperdrive 權限及部署錯誤處理。
- README、`.dev.vars` 範例或本地 Hyperdrive connection string 設定。
- 同語言跨 script／region 的轉寫或變體改寫。
- 新增 index、materialized view、sense model、schema migration 或 API 分頁。
- 對 30 秒 statement timeout 的調整。完整候選總數仍需計算；若移除重複計算後仍慢，需另提保留 count 語義的查詢設計。
