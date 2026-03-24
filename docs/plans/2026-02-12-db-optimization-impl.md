# 實施計劃：數據庫性能優化 (Database Optimization Implementation)

**日期**：2026-02-12
**狀態**：待評審
**目標**：實施多級緩存與索引優化，顯著降低 Cloudflare D1 的查詢負載。

## 1. 緩存層優化 (Multi-layer Cache)

### 1.1 L1: 內存級緩存 (Isolate Level)
**目標**：消除基礎數據的重複查詢（如語言列表）。
- **對象**：`getLanguages`, `getLanguageByCode`。
- **實施**：在 `d1.ts` 中引入 `languagesCache` 變量，設置 30 分鐘 TTL。
- **失效**：在 `createLanguage` 或 `updateLanguage` 時手動清空。

### 1.2 L2: Cloudflare Workers Cache API (Edge Level)
**目標**：針對高頻請求（如搜索、列表分頁）緩存 JSON 響應。
- **對象**：`GET /api/v1/expressions`, `GET /api/v1/expressions/search`。
- **優點**：
    - **極低延遲**：直接在邊緣節點返回，無需經過數據庫。
    - **成本優化**：完全免費（包含在 Worker 計劃內），且減少 D1 的行讀取額度。
- **實施**：在 API 層（v1.ts）集成 `caches.default`。
- **失效**：通過 `Cache-Control: max-age=3600` 設置自動過期，或通過版本號（?v=...）進行全局強制失效。

## 2. 針對高負載查詢的專項優化 (Targeted SQL Fixes)

根據最新的統計，我們將針對 Rows Read 排名前五的語句實施專項優化：

### 2.1 搜索優化 (針對 SQL #1)
- **現狀**：`text LIKE ?` 在百萬級數據下會導致全表掃描。
- **優化**：
    - **L2 緩存**：使用 Workers Cache API 緩存高頻搜索關鍵詞的結果，避免重複穿透。
    - **FTS5 (長期)**：評估引入 SQLite 的 FTS5 虛擬表，實現高性能的前綴匹配與全文搜索。

### 2.2 計數與統計優化 (針對 SQL #2, #3, #5)
- **現狀**：`COUNT(*)` 和 `GROUP BY language_code` 每次都會掃描整張 Expressions 表。
- **優化**：
    - **反範式化 (De-normalization)**：在 `collections` 表中增加 `items_count` 字段。每次添加/刪除成員時同步更新，以此消除 SQL #5 中的相關子查詢。
    - **物化統計表**：建立 `language_stats` 表記錄各語言的詞句總數。`getHeatmapData` (SQL #3) 直接讀取此表，不再進行全表聚合。
    - **強力緩存**：對 SQL #2 的總數查詢實施更持久的 L1 緩存或存儲在 KV 中。

### 2.3 索引精細化 (針對 SQL #4, #5)
- **優化**：
    - **複合索引**：創建 `idx_collection_items_query: (collection_id, created_at DESC)`。這將同時滿足 SQL #4 的過濾與排序需求。
    - **關聯優化**：爲 `collections` 增加 `(is_public, created_at DESC)` 複合索引，優化公共列表分頁。

### 2.4 UI 翻譯性能優化 (針對 /ui-translations/:language)
- **現狀**：該接口涉及 `expressions`, `collection_items`, `collections` 三表聯查，且缺少 `collections(name)` 索引。
- **優化**：
    - **補充索引**：爲 `collections(name)` 創建索引，確保聯表查詢能快速鎖定 `langmap` 集合。
    - **L2 緩存集成**：該接口返回的數據相對靜態，非常適合使用 **Workers Cache API**。設置 `max-age=3600` (1小時)，大幅減少數據庫負載。

## 3. 實施路線圖 (更新版)

| 優先級 | 任務內容 | 解決的 Bottlenecks |
| :--- | :--- | :--- |
| **P0** | **L1 緩存與核心索引** | SQL #1 (重複查詢), SQL #4 |
| **P1** | **反範式化 (items_count)** | SQL #5 (消除子查詢) |
| **P2** | **物化統計與 L2 緩存** | SQL #2, SQL #3, SQL #1 |

## 4. 驗證計劃
- **監控**：對比優化前後的 D1 控制臺 "Rows Read" 指標。
- **體感**：驗證在多語言切換及搜索時的響應靈敏度。
