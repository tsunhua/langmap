# 數據庫設計

## System Reminder

**實現狀態**：
- ✅ Cloudflare D1 數據庫已部署
- ✅ 核心表結構已實現
- ✅ 複合優化索引已部署 (013_optimization_indexes.sql)
- ✅ 多級緩存機制已實施 (L1 Memory + L2 Edge Cache)
- ✅ 反範式化統計已實施 (items_count & language_stats)
- ✅ 數據庫遷移腳本已規範化
- ⏳ 數據備份策略待自動化
- ✅ 數據庫性能監控初步實現 (Edge Log)

**已實現的數據庫表**：
- `languages` - 語言表
- `expressions` - 表達式主表
- `expression_versions` - 版本歷史表
- `users` - 用戶表
- `collections` - 集合表 (含 `items_count` 冗餘字段)
- `collection_items` - 集合項目表
- `email_verification_tokens` - 郵箱驗證令牌表
- `language_stats` - 語言詞數統計表 (物化統計)

**未實現的功能**：
- 數據庫遷移管理工具
- 自動備份機制
- 數據庫性能監控
- 讀寫分離（如需要）
- 分庫分表策略

---

## 概述

LangMap 項目使用 Cloudflare D1 作爲主數據庫，這是一個兼容 SQLite 的邊緣數據庫。D1 提供了低延遲的全球分布式訪問，非常適合需要快速響應的 Web 應用程序。

### 數據庫選擇理由

- **Cloudflare D1**：與 Cloudflare Workers 無縫集成，邊緣部署
- **SQLite 兼容**：熟悉的 SQL 語法，易於開發和測試
- **低延遲**：全球分布式訪問，就近響應
- **Serverless**：無需管理數據庫服務器
- **成本效益**：按使用量計費，適合小到中型應用

### 數據庫特性

- **ACID 事務**：支持事務，保證數據一致性
- **關係型**：支持複雜的關係查詢和聯表
- **邊緣部署**：數據分布在多個邊緣節點
- **自動擴展**：無需手動擴展數據庫容量
- **讀取一致性**：提供最終一致性保證

## 數據庫架構

### 表關係圖

```
languages (語言表)
  ↓ 1:N
expressions (表達式主表)
  ↓ 1:N
expression_versions (版本歷史表)

languages (語言表)
  ↔ 1:1
language_stats (物化統計表)

users (用戶表)
  ↓ 1:N
collections (集合表)
  ↓ 1:N
collection_items (集合項目表)
  ↓ N:1
expressions (表達式主表)
```

## 表結構詳情

### 1. languages 表

存儲支持的語言及其地域信息。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS languages (
    id INTEGER PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,              -- BCP-47 語言代碼 (如 "en-US", "zh-CN")
    name TEXT NOT NULL,                        -- 語言英文名稱
    native_name TEXT,                         -- 語言本地化名稱
    direction TEXT DEFAULT 'ltr',              -- 文本方向: "ltr" 或 "rtl"
    is_active INTEGER DEFAULT 0,              -- 是否激活: 0=否, 1=是
    region_code TEXT,                          -- 地區代碼 (如 "US", "CN")
    region_name TEXT,                          -- 地區名稱 (如 "New York", "Beijing")
    region_latitude TEXT,                       -- 地區緯度
    region_longitude TEXT,                      -- 地區經度
    group_name TEXT,                           -- 語羣名稱 (如 "閩南語", "吳語")
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**索引**：

```sql
CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_languages_is_active ON languages(is_active);
CREATE INDEX idx_languages_active_name ON languages(is_active, name); -- 優化常用語言列表
```

**字段說明**：
- `id` - 主鍵，使用語言代碼的哈希值
- `code` - 唯一鍵，BCP-47 標準語言代碼
- `is_active` - 標識語言是否可用，只有激活的語言在前端顯示
- `region_*` - 支持語言的地域化信息，用於地圖可視化

### 2. expressions 表

存儲語言表達式的當前版本。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,                         -- 表達式文本
    meaning_id INTEGER,                          -- 關聯的語義 ID
    audio_url TEXT,                             -- 音頻 URL
    language_code TEXT NOT NULL,                 -- 語言代碼
    region_code TEXT,                            -- 地區代碼
    region_name TEXT,                            -- 地區名稱
    region_latitude TEXT,                         -- 地區緯度
    region_longitude TEXT,                        -- 地區經度
    tags TEXT,                                  -- JSON 數組，用於標籤分類
    source_type TEXT DEFAULT 'user',              -- 來源類型: "authoritative", "ai", "user"
    source_ref TEXT,                             -- 來源引用 (書名、URL 等)
    review_status TEXT DEFAULT 'pending',          -- 審核狀態: "pending", "approved", "rejected"
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meaning_id) REFERENCES expressions(id)
);
```

**索引**：

```sql
CREATE INDEX idx_expressions_language_code ON expressions(language_code);
CREATE INDEX idx_expressions_meaning_id ON expressions(meaning_id);
CREATE INDEX idx_expressions_text ON expressions(text);
-- 複合索引：優化針對特定語言的分頁列表
CREATE INDEX idx_expressions_lang_meaning_created ON expressions(language_code, meaning_id, created_at DESC);
-- 複合索引：優化同步與去重檢查
CREATE INDEX idx_expressions_lang_text ON expressions(language_code, text);
```

**字段說明**：
- `id` - 主鍵，基於 `text + language_code` 計算的確定性哈希值，確保相同內容的詞句具有唯一且穩定的 ID。
- `meaning_id` - 語義錨點 ID（指向 expressions.id），用於將不同語言的同義詞句分到同一組。同一組的詞句共享相同的 `meaning_id`，通常該 ID 取自該組中第一個被創建或最主要的表達記錄。
- `tags` - JSON 格式存儲標籤，例如 `["home", "title"]`
- `source_type` - 標識內容來源，AI 生成的內容可能自動審核通過
- `review_status` - 用戶提交的內容需要審核
- `region_*` - 地域化信息，支持精細的地理定位

### 3. expression_versions 表

存儲表達式的所有歷史版本，支持版本回滾。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS expression_versions (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,               -- 關聯的表達式 ID
    text TEXT NOT NULL,                         -- 版本文本
    meaning_id INTEGER,                          -- 語義 ID
    audio_url TEXT,                             -- 音頻 URL
    region_name TEXT,                            -- 地區名稱
    region_latitude TEXT,                         -- 地區緯度
    region_longitude TEXT,                        -- 地區經度
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expression_id) REFERENCES expressions(id)
);
```

**索引**：

```sql
CREATE INDEX idx_expression_versions_expr_id ON expression_versions(expression_id);
CREATE INDEX idx_expression_versions_created_at ON expression_versions(created_at);
```

**字段說明**：
- `expression_id` - 指向當前表達式主表記錄
- `meaning_id` - 記錄快照時的語義關聯
- 不包含 `source_type`, `review_status` - 這些字段只在主表中維護


### 5. users 表

存儲用戶賬戶信息。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY NOT NULL,
    username TEXT UNIQUE NOT NULL,                 -- 用戶名
    email TEXT UNIQUE NOT NULL,                    -- 郵箱
    password_hash TEXT NOT NULL,                   -- 密碼哈希 (bcrypt)
    role TEXT DEFAULT 'user',                      -- 角色: "user", "admin", "super_admin"
    email_verified INTEGER DEFAULT 0,              -- 郵箱驗證: 0=未驗證, 1=已驗證
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**索引**：

```sql
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

**字段說明**：
- `role` - 定義用戶權限級別
- `email_verified` - 阻止未驗證郵箱的用戶登錄

### 7. email_verification_tokens 表

存儲郵箱驗證令牌。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    token TEXT PRIMARY KEY NOT NULL,                -- 驗證令牌
    user_id INTEGER NOT NULL,                      -- 用戶 ID
    expires_at TEXT NOT NULL,                      -- 過期時間
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**索引**：

```sql
CREATE INDEX idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_tokens_expires_at ON email_verification_tokens(expires_at);
```

**字段說明**：
- `token` - 唯一標識，一次性使用
- `expires_at` - 令牌有效期，通常設置爲 1 小時

### 8. collections 表

存儲用戶的收藏集合。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,                      -- 創建者 ID
    name TEXT NOT NULL,                            -- 集合名稱
    description TEXT,                               -- 集合描述
    is_public INTEGER DEFAULT 0,                    -- 是否公開: 0=私有, 1=公開
    items_count INTEGER DEFAULT 0,                 -- 反範式化字段：集合項目總數
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**索引**：

```sql
CREATE INDEX idx_collections_user_id ON collections(user_id);
CREATE INDEX idx_collections_name ON collections(name);
-- 複合索引：優化公共/個人列表的分頁排序
CREATE INDEX idx_collections_is_public_created ON collections(is_public, created_at DESC);
CREATE INDEX idx_collections_user_created ON collections(user_id, created_at DESC);
```

**字段說明**：
- `is_public` - 標識集合是否對其他用戶可見

### 9. collection_items 表

存儲集合與表達式的關聯。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS collection_items (
    id INTEGER PRIMARY KEY NOT NULL,
    collection_id INTEGER NOT NULL,                 -- 集合 ID
    expression_id INTEGER NOT NULL,                  -- 表達式 ID
    note TEXT,                                    -- 備註
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, expression_id),
    FOREIGN KEY (collection_id) REFERENCES collections(id),
    FOREIGN KEY (expression_id) REFERENCES expressions(id)
);
```

**索引**：

```sql
CREATE INDEX idx_collection_items_collection_id ON collection_items(collection_id);
CREATE INDEX idx_collection_items_expression_id ON collection_items(expression_id);
-- 複合索引：優化集合詳情頁的加載
CREATE INDEX idx_collection_items_query ON collection_items(collection_id, created_at DESC);
```

**字段說明**：
- `UNIQUE(collection_id, expression_id)` - 保證同一表達式在同一集合中只出現一次
- `note` - 可選的添加說明
- `items_count` (在 collections 表) - 每次增刪 collection_items 時同步更新，避免昂貴的 COUNT 子查詢。

### 10. language_stats 表

物化統計表，用於加速熱力圖和儀錶盤的顯示。

**表結構**：

```sql
CREATE TABLE IF NOT EXISTS language_stats (
    language_code TEXT PRIMARY KEY,               -- 語言代碼
    expression_count INTEGER DEFAULT 0             -- 該語言下的表達式總數
);
```

**字段說明**：
- 物化視圖：取代了所有針對 `expressions` 表的 `GROUP BY language_code` 的聚合查詢。
- 維護機制：在 Expression 進行 CRUD 或批處理遷移時，由後端 Service 實時同步更新。

## 索引設計

### 索引策略

1. **主鍵索引**：所有表都有 `INTEGER PRIMARY KEY`
2. **唯一索引**：用於保證數據唯一性
3. **外鍵索引**：所有外鍵字段都創建索引
4. **查詢索引**：爲常用查詢條件創建索引

### 索引性能考慮

- **避免過度索引**：索引會增加寫入開銷
- **複合索引**：根據查詢模式選擇
- **定期分析**：監控索引使用情況

### 未來優化

- **全文索引 (FTS5)**：爲 `expressions.text` 創建 FTS5 虛擬表，實現毫秒級前綴匹配與全文搜索。
- **R2 整合**：針對靜態資源（如音頻、導出結果）的元數據管理優化

## 數據遷移

### 遷移策略

1. **版本化遷移**：每個遷移文件編號（001, 002, 003...）
2. **冪等性**：遷移腳本可重複執行
3. **回滾支持**：提供降級腳本

### 遷移示例

```sql
-- Migration 001: Add region fields to expressions
ALTER TABLE expressions 
ADD COLUMN region_name TEXT,
ADD COLUMN region_latitude TEXT,
ADD COLUMN region_longitude TEXT;

-- Migration 002: Add email verification support
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    token TEXT PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Migration 003: Add tags column to expressions
ALTER TABLE expressions ADD COLUMN tags TEXT;
```

### 未來改進

- **遷移框架**：自動化遷移管理
- **遷移日誌**：記錄遷移歷史
- **數據校驗**：遷移後驗證數據完整性

## 性能優化

### 1. 多級緩存策略 (Multi-layer Caching)

爲了抵消 Cloudflare D1 的 "Rows Read" 限制並提升響應性能，系統實施了三級緩存：
- **L1 (Isolation Cache)**: 後端單次請求作用域內的 `languagesCache`，TTL 爲 30 分鐘。
- **L2 (Edge Cache)**: 利用 Workers Cache API，在邊緣節點緩存高頻 GET 請求（熱力圖、搜索、UI 翻譯等）。
- **L3 (Materialized)**: 通過 `language_stats` 等物化表將聚合結果持久化，變 O(N) 爲 O(1)。

### 2. 反範式化設計 (De-normalization)

- **items_count**: 在 `collections` 表中冗餘存儲項目數量，消除列表展示時的統計開銷。

### 3. 索引精細化

- 針對分頁查詢（`created_at DESC`）普遍補充了複合索引。
- 針對 UI 翻譯（`WHERE collection.name = 'langmap'`）補充了 `idx_collections_name`。

### 4. 批量操作優化

- **db.batch()**: 在進行批處理提交 (Upsert) 和 ID 遷移時，使用 D1 的原子批處理語句，大幅減少數據庫往返次數。

### 5. 全文檢索 (FTS5) 架構

爲了消除 `LIKE '%query%'` 帶來的全表掃描（High Rows Read），系統引入了 FTS5 虛擬表：
- **虛擬表**：`expressions_fts` (External Content 模式)。
- **同步機制**：通過觸發器（Trigger）在數據增刪改時自動保持主表與搜索索引的實時同步。
- **分詞器**：使用 `unicode61` 以支持全球多語言字符的搜索。

### 事務管理

```sql
BEGIN TRANSACTION;
-- 多個相關操作
COMMIT;
```

### 連接池

- D1 自動管理連接
- 無需手動配置連接池
- 邊緣節點自動路由

## 備份策略

### 當前狀態

- ❌ 自動備份未實現
- ❌ 定期備份未實現
- ⏳ 手動導出可用（通過 Wrangler CLI）

### 建議策略

1. **定期備份**：每日自動備份數據庫
2. **增量備份**：只備份變更數據
3. **多地域備份**：備份到多個存儲位置
4. **備份驗證**：定期驗證備份的完整性

### 備份命令

```bash
# 導出數據庫
wrangler d1 export DB_NAME backup.sql

# 導入數據庫
wrangler d1 execute DB_NAME --file=backup.sql
```

## 數據安全

### 訪問控制

- **環境變量**：數據庫憑證存儲在 Cloudflare Workers 環境變量中
- **最小權限**：應用只訪問必要的表和字段
- **API 鑑權**：JWT 認證保護敏感操作

### 數據加密

- **傳輸加密**：HTTPS 加密所有數據庫通信
- **靜態加密**：敏感字段（如密碼）使用 bcrypt 哈希
- **密鑰管理**：使用 Cloudflare Secrets 管理敏感密鑰

### 數據脫敏

- **日誌脫敏**：日誌中不記錄敏感信息
- **API 響應**：不返回完整敏感數據
- **錯誤消息**：避免泄露數據庫結構

## 監控與維護

### 性能監控

- **查詢時間**：監控慢查詢
- **連接數**：監控並發連接
- **錯誤率**：監控數據庫錯誤

### 維護任務

- **索引重建**：定期重建索引
- **數據清理**：刪除過期數據
- **統計更新**：更新緩存數據

### 未來改進

- **儀錶盤**：實時監控數據庫性能
- **自動告警**：異常情況自動通知
- **自優化**：自動調整數據庫配置

## 相關文檔

- [系統架構設計](../system/architecture.md)
- [後端 API 指南](../../api/backend-guide.md)
- [用戶與權限系統](./feat-user-system.md)
- [UI 翻譯系統](./feat-ui-translation.md)
