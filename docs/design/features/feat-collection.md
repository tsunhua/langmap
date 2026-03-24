# 集合功能設計

## System Reminder

**設計來源**：本設計基於原始 `design_collection.md`

**實現狀態**：
- ✅ 數據庫模型（collections, collection_items 表）- 已實現
- ✅ 後端 API 基礎實現 - 已實現（CRUD 操作）
- ✅ 反範式化計數優化 - 已實現 (`items_count` 自動維護)
- ✅ 前端基礎功能 - 已實現
- ✅ 集合管理頁面 - 已實現
- ⏳ 管理界面優化 - 部分實現
- ❌ 公開集合分享 - 未實現

**未實現的功能**：
- 集合導出功能
- 集合搜索和篩選
- 集合協作功能

---

## 概述

集合功能允許用戶創建自定義的"收藏夾"或"詞單"，將感興趣的 `Expression`（詞條）整理歸類。用戶可以創建多個集合，並將不同的詞條添加到這些集合中，方便後續複習、分享或管理。

## 2. 數據庫設計 (Database Schema)

需要新增兩張表來支持該功能：`collections` 和 `collection_items`。

### 2.1 Collections 表

存儲集合的基本信息。

```sql
CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,          -- 創建者ID，關聯 users.id
    name TEXT NOT NULL,                -- 集合名稱
    description TEXT,                  -- 集合描述
    is_public INTEGER DEFAULT 0,       -- 是否公開 (0: 私有, 1: 公開)
    items_count INTEGER DEFAULT 0,     -- 反範式化字段：集合項目總數
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### 2.2 Collection Items 表

存儲集合與詞條的關聯關係（多對多關係）。

```sql
CREATE TABLE IF NOT EXISTS collection_items (
    id INTEGER PRIMARY KEY NOT NULL,
    collection_id INTEGER NOT NULL,    -- 關聯 collections.id
    expression_id INTEGER NOT NULL,    -- 關聯 expressions.id
    note TEXT,                         -- 用戶對該詞條在集合中的備註（可選）
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, expression_id) -- 防止重複添加
);
```

### 2.3 索引

爲了提高查詢性能，建議添加以下索引：
- `collections(user_id)`
- `collections(name)` -- 優化 UI 翻譯檢索
- `collections(is_public, created_at DESC)` -- 優化公開列表分頁
- `collection_items(collection_id, created_at DESC)` -- 優化集合條目檢索
- `collection_items(expression_id)`

## 3. 後端接口設計 (API Design)

所有接口均需通過 `requireAuth` 中間件驗證用戶身份。

### 3.1 集合管理

#### 3.1.1 獲取集合列表
- **Endpoint**: `GET /api/v1/collections`
- **Query Params**: 
    - `user_id`: (可選) 篩選特定用戶的集合。若不傳且已登錄，默認返回當前用戶的集合。
    - `is_public`: (可選) `1` 爲篩選公開集合。
- **Response**: Array of `Collection` objects.

#### 3.1.2 創建集合
- **Endpoint**: `POST /api/v1/collections`
- **Body**:
    ```json
    {
        "name": "我的生詞本",
        "description": "記錄日常遇到的生詞",
        "is_public": 0
    }
    ```
- **Response**: Created `Collection` object.

#### 3.1.3 獲取集合詳情
- **Endpoint**: `GET /api/v1/collections/:id`
- **Response**: `Collection` object (包含 items 或單獨請求 items).

#### 3.1.4 更新集合
- **Endpoint**: `PUT /api/v1/collections/:id`
- **Body**: (Partial) name, description, is_public.
- **Response**: Updated `Collection` object.

#### 3.1.5 刪除集合
- **Endpoint**: `DELETE /api/v1/collections/:id`
- **Response**: Success message.

### 3.2 集合條目管理

#### 3.2.1 獲取集合內的詞條
- **Endpoint**: `GET /api/v1/collections/:id/items`
- **Query Params**: `skip`, `limit`.
- **Response**: Array of `Expression` objects (with `note`).

#### 3.2.2 添加詞條到集合
- **Endpoint**: `POST /api/v1/collections/:id/items`
- **Body**:
    ```json
    {
        "expression_id": 123,
        "note": "可選備註"
    }
    ```
- **Response**: Success message / Created Item.

#### 3.2.3 從集合移除詞條
- **Endpoint**: `DELETE /api/v1/collections/:id/items/:expressionId`
- **Response**: Success message.

## 4. 前端交互設計 (Frontend Interaction)

### 4.1 "添加/移除" 交互

在詞條詳情頁或列表中，每個詞條角落提供一個 "收藏/加入集合" 的圖標按鈕（如 Bookmark Icon）。

- **未收藏狀態**：點擊圖標，彈出 "添加到集合" 對話框（Modal）。
    - 對話框列出用戶當前所有的集合。
    - 提供 "新建集合" 的快速入口。
    - 用戶勾選一個或多個集合後，點擊確認，調用 API 將詞條加入這些集合。
- **已收藏狀態**：圖標高亮。再次點擊可編輯其所屬集合（勾選/取消勾選）。

### 4.2 "我的集合" 頁面

新增路由頁面 `/collections` 或 `/profile/collections`。

- **列表視圖**：展示用戶創建的所有集合卡片。每張卡片顯示集合名、描述、包含詞條數、是否公開。
- **新建按鈕**：頂部提供 "創建新集合" 按鈕。

### 4.3 集合詳情頁面

點擊集合卡片進入詳情頁 `/collections/:id`。

- **頭部**：顯示集合名稱、描述、編輯/刪除按鈕。
- **詞條列表**：展示該集合下的詞條列表。支持分頁。
- **操作**：列表項提供 "移除" 按鈕。

## 5. 開發計劃 (Implementation Steps)

1.  **Database**:
    - 更新 `d1_schema.sql` 添加新表。
    - 更新 `protocol.ts` 添加類型定義。
    - 更新 `d1.ts` 實現 `CollectionsService` 相關方法。
2.  **Backend API**:
    - 在 `types.ts` 或 `v1.ts` 中定義新的 API 路由。
    - 實現 CRUD 邏輯。
3.  **Frontend**:
    - 添加 API Service 方法 (`collectionService.js`).
    - 創建 `CollectionList` 組件。
    - 創建 `CollectionDetail` 組件。
    - 封裝 `AddToCollectionModal` 組件。
    - 在 `ExpressionCard` 中集成收藏按鈕。

