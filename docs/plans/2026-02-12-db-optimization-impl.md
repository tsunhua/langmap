# 实施计划：数据库性能优化 (Database Optimization Implementation)

**日期**：2026-02-12
**状态**：待评审
**目标**：实施多级缓存与索引优化，显著降低 Cloudflare D1 的查询负载。

## 1. 缓存层优化 (Multi-layer Cache)

### 1.1 L1: 内存级缓存 (Isolate Level)
**目标**：消除基础数据的重复查询（如语言列表）。
- **对象**：`getLanguages`, `getLanguageByCode`。
- **实施**：在 `d1.ts` 中引入 `languagesCache` 变量，设置 30 分钟 TTL。
- **失效**：在 `createLanguage` 或 `updateLanguage` 时手动清空。

### 1.2 L2: Cloudflare Workers Cache API (Edge Level)
**目标**：针对高频请求（如搜索、列表分页）缓存 JSON 响应。
- **对象**：`GET /api/v1/expressions`, `GET /api/v1/expressions/search`。
- **优点**：
    - **极低延迟**：直接在边缘节点返回，无需经过数据库。
    - **成本优化**：完全免费（包含在 Worker 计划内），且减少 D1 的行读取额度。
- **实施**：在 API 层（v1.ts）集成 `caches.default`。
- **失效**：通过 `Cache-Control: max-age=3600` 设置自动过期，或通过版本号（?v=...）进行全局强制失效。

## 2. 针对高负载查询的专项优化 (Targeted SQL Fixes)

根据最新的统计，我们将针对 Rows Read 排名前五的语句实施专项优化：

### 2.1 搜索优化 (针对 SQL #1)
- **现状**：`text LIKE ?` 在百万级数据下会导致全表扫描。
- **优化**：
    - **L2 缓存**：使用 Workers Cache API 缓存高频搜索关键词的结果，避免重复穿透。
    - **FTS5 (长期)**：评估引入 SQLite 的 FTS5 虚拟表，实现高性能的前缀匹配与全文搜索。

### 2.2 计数与统计优化 (针对 SQL #2, #3, #5)
- **现状**：`COUNT(*)` 和 `GROUP BY language_code` 每次都会扫描整张 Expressions 表。
- **优化**：
    - **反范式化 (De-normalization)**：在 `collections` 表中增加 `items_count` 字段。每次添加/删除成员时同步更新，以此消除 SQL #5 中的相关子查询。
    - **物化统计表**：建立 `language_stats` 表记录各语言的词句总数。`getHeatmapData` (SQL #3) 直接读取此表，不再进行全表聚合。
    - **强力缓存**：对 SQL #2 的总数查询实施更持久的 L1 缓存或存储在 KV 中。

### 2.3 索引精细化 (针对 SQL #4, #5)
- **优化**：
    - **复合索引**：创建 `idx_collection_items_query: (collection_id, created_at DESC)`。这将同时满足 SQL #4 的过滤与排序需求。
    - **关联优化**：为 `collections` 增加 `(is_public, created_at DESC)` 复合索引，优化公共列表分页。

### 2.4 UI 翻译性能优化 (针对 /ui-translations/:language)
- **现状**：该接口涉及 `expressions`, `collection_items`, `collections` 三表联查，且缺少 `collections(name)` 索引。
- **优化**：
    - **补充索引**：为 `collections(name)` 创建索引，确保联表查询能快速锁定 `langmap` 集合。
    - **L2 缓存集成**：该接口返回的数据相对静态，非常适合使用 **Workers Cache API**。设置 `max-age=3600` (1小时)，大幅减少数据库负载。

## 3. 实施路线图 (更新版)

| 优先级 | 任务内容 | 解决的 Bottlenecks |
| :--- | :--- | :--- |
| **P0** | **L1 缓存与核心索引** | SQL #1 (重复查询), SQL #4 |
| **P1** | **反范式化 (items_count)** | SQL #5 (消除子查询) |
| **P2** | **物化统计与 L2 缓存** | SQL #2, SQL #3, SQL #1 |

## 4. 验证计划
- **监控**：对比优化前后的 D1 控制台 "Rows Read" 指标。
- **体感**：验证在多语言切换及搜索时的响应灵敏度。
