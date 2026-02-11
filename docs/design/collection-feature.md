# 集合功能设计文档 (Collections Feature Design)

## 1. 概述

集合功能旨在允许用户创建自定义的"收藏夹"或"词单"，将感兴趣的 `Expression`（词条）整理归类。用户可以创建多个集合，并将不同的词条添加到这些集合中，方便后续复习、分享或管理。

## 2. 数据库设计 (Database Schema)

需要新增两张表来支持该功能：`collections` 和 `collection_items`。

### 2.1 Collections 表

存储集合的基本信息。

```sql
CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,          -- 创建者ID，关联 users.id
    name TEXT NOT NULL,                -- 集合名称
    description TEXT,                  -- 集合描述
    is_public INTEGER DEFAULT 0,       -- 是否公开 (0: 私有, 1: 公开)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### 2.2 Collection Items 表

存储集合与词条的关联关系（多对多关系）。

```sql
CREATE TABLE IF NOT EXISTS collection_items (
    id INTEGER PRIMARY KEY NOT NULL,
    collection_id INTEGER NOT NULL,    -- 关联 collections.id
    expression_id INTEGER NOT NULL,    -- 关联 expressions.id
    note TEXT,                         -- 用户对该词条在集合中的备注（可选）
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, expression_id) -- 防止重复添加
);
```

### 2.3 索引

为了提高查询性能，建议添加以下索引：
- `collections(user_id)`
- `collection_items(collection_id)`
- `collection_items(expression_id)`

## 3. 后端接口设计 (API Design)

所有接口均需通过 `requireAuth` 中间件验证用户身份。

### 3.1 集合管理

#### 3.1.1 获取集合列表
- **Endpoint**: `GET /api/v1/collections`
- **Query Params**: 
    - `user_id`: (可选) 筛选特定用户的集合。若不传且已登录，默认返回当前用户的集合。
    - `is_public`: (可选) `1` 为筛选公开集合。
- **Response**: Array of `Collection` objects.

#### 3.1.2 创建集合
- **Endpoint**: `POST /api/v1/collections`
- **Body**:
    ```json
    {
        "name": "我的生词本",
        "description": "记录日常遇到的生词",
        "is_public": 0
    }
    ```
- **Response**: Created `Collection` object.

#### 3.1.3 获取集合详情
- **Endpoint**: `GET /api/v1/collections/:id`
- **Response**: `Collection` object (包含 items 或单独请求 items).

#### 3.1.4 更新集合
- **Endpoint**: `PUT /api/v1/collections/:id`
- **Body**: (Partial) name, description, is_public.
- **Response**: Updated `Collection` object.

#### 3.1.5 删除集合
- **Endpoint**: `DELETE /api/v1/collections/:id`
- **Response**: Success message.

### 3.2 集合条目管理

#### 3.2.1 获取集合内的词条
- **Endpoint**: `GET /api/v1/collections/:id/items`
- **Query Params**: `skip`, `limit`.
- **Response**: Array of `Expression` objects (with `note`).

#### 3.2.2 添加词条到集合
- **Endpoint**: `POST /api/v1/collections/:id/items`
- **Body**:
    ```json
    {
        "expression_id": 123,
        "note": "可选备注"
    }
    ```
- **Response**: Success message / Created Item.

#### 3.2.3 从集合移除词条
- **Endpoint**: `DELETE /api/v1/collections/:id/items/:expressionId`
- **Response**: Success message.

## 4. 前端交互设计 (Frontend Interaction)

### 4.1 "添加/移除" 交互

在词条详情页或列表中，每个词条角落提供一个 "收藏/加入集合" 的图标按钮（如 Bookmark Icon）。

- **未收藏状态**：点击图标，弹出 "添加到集合" 对话框（Modal）。
    - 对话框列出用户当前所有的集合。
    - 提供 "新建集合" 的快速入口。
    - 用户勾选一个或多个集合后，点击确认，调用 API 将词条加入这些集合。
- **已收藏状态**：图标高亮。再次点击可编辑其所属集合（勾选/取消勾选）。

### 4.2 "我的集合" 页面

新增路由页面 `/collections` 或 `/profile/collections`。

- **列表视图**：展示用户创建的所有集合卡片。每张卡片显示集合名、描述、包含词条数、是否公开。
- **新建按钮**：顶部提供 "创建新集合" 按钮。

### 4.3 集合详情页面

点击集合卡片进入详情页 `/collections/:id`。

- **头部**：显示集合名称、描述、编辑/删除按钮。
- **词条列表**：展示该集合下的词条列表。支持分页。
- **操作**：列表项提供 "移除" 按钮。

## 5. 开发计划 (Implementation Steps)

1.  **Database**:
    - 更新 `d1_schema.sql` 添加新表。
    - 更新 `protocol.ts` 添加类型定义。
    - 更新 `d1.ts` 实现 `CollectionsService` 相关方法。
2.  **Backend API**:
    - 在 `types.ts` 或 `v1.ts` 中定义新的 API 路由。
    - 实现 CRUD 逻辑。
3.  **Frontend**:
    - 添加 API Service 方法 (`collectionService.js`).
    - 创建 `CollectionList` 组件。
    - 创建 `CollectionDetail` 组件。
    - 封装 `AddToCollectionModal` 组件。
    - 在 `ExpressionCard` 中集成收藏按钮。

