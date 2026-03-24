# API 文檔

本文檔描述 LangMap 後端 API 的所有端點、認證機制、請求/響應格式和使用說明。

## 概述

LangMap API 使用 Hono + TypeScript 框架，部署在 Cloudflare Workers 上，使用 Cloudflare D1 作爲數據庫。API 遵循 RESTful 設計原則，所有端點使用 `/api/v1/` 前綴。

## 認證機制

### JWT 認證

系統使用 JWT (JSON Web Token) 進行用戶認證：

**端點**：
- `POST /api/v1/auth/register` - 用戶註冊（含郵箱驗證）
- `POST /api/v1/auth/login` - 用戶登錄
- `POST /api/v1/auth/logout` - 用戶登出
- `GET /api/v1/auth/verify-email` - 驗證郵箱

**認證流程**：
1. 用戶註冊/登錄 → 服務器返回 JWT token
2. 客戶端在請求頭中攜帶 token：`Authorization: Bearer {token}`
3. 服務器驗證 token 有效性，設置用戶上下文
4. token 有效期 24 小時

### 權限控制

**公開端點**：無需認證
- `GET /api/v1/languages`
- `GET /api/v1/statistics`
- `GET /api/v1/heatmap`
- `GET /api/v1/ui-translations/:language`

**需要認證的端點**：
- 用戶信息管理
- 表達式管理
- 語義管理
- 集合管理
- UI 翻譯保存

**管理員端點**：
- `PUT /api/v1/users/:id/role` - 更新用戶角色（超級管理員）

## 數據庫架構

LangMap 使用 Cloudflare D1 (SQLite 兼容邊緣數據庫)，詳細的表結構請參見：[數據庫設計文檔](../design/features/feat-database.md)

**核心表概覽**：
- `languages` - 語言表
- `expressions` - 表達式主表
- `expression_versions` - 版本歷史表
- `meanings` - 語義表
- `expression_meanings` - 表達式-語義關聯表
- `users` - 用戶表
- `collections` - 集合表
- `collection_items` - 集合項目表
- `email_verification_tokens` - 郵箱驗證令牌表

## API 端點總覽

### 按功能分類

#### 公開端點

**語言管理**
- `GET /api/v1/languages` - 獲取支持的語言列表
- `GET /api/v1/languages?is_active=1` - 獲取激活的語言

**統計和熱力圖**
- `GET /api/v1/statistics` - 獲取系統統計信息
- `GET /api/v1/heatmap` - 獲取熱力圖數據

**搜索功能**
- `GET /api/v1/search` - 搜索表達式

**UI 翻譯**
- `GET /api/v1/ui-translations/:language` - 獲取 UI 翻譯
- `POST /api/v1/ui-translations/:language` - 保存 UI 翻譯
- `POST /api/v1/sync-locales` - 同步本地翻譯到數據庫

#### 認證端點

- `POST /api/v1/auth/register` - 用戶註冊
- `POST /api/v1/auth/login` - 用戶登錄
- `POST /api/v1/auth/logout` - 用戶登出
- `GET /api/v1/auth/verify-email` - 驗證郵箱

#### 需要認證的端點

**用戶信息**
- `GET /api/v1/users/me` - 獲取當前用戶信息

**表達式管理**
- `GET /api/v1/expressions` - 獲取表達式列表
- `GET /api/v1/expressions/:id` - 獲取表達式詳情
- `POST /api/v1/expressions` - 創建表達式
- `GET /api/v1/expressions/:id/versions` - 獲取表達式版本歷史
- `GET /api/v1/expressions/:id/meanings` - 獲取表達式含義
- `PATCH /api/v1/expressions/:id` - 更新表達式（編輯）
- `DELETE /api/v1/expressions/:id` - 刪除表達式

**語義管理**
- `POST /api/v1/meanings` - 創建含義
- `POST /api/v1/meanings/:id/link` - 關聯表達式與含義
- `GET /api/v1/meanings/:id` - 獲取語義詳情

**集合管理**
- `GET /api/v1/collections` - 獲取集合列表
- `POST /api/v1/collections` - 創建集合
- `GET /api/v1/collections/:id` - 獲取集合詳情
- `PUT /api/v1/collections/:id` - 更新集合
- `DELETE /api/v1/collections/:id` - 刪除集合
- `GET /api/v1/collections/:id/items` - 獲取集合內容
- `POST /api/v1/collections/:id/items` - 添加內容到集合
- `DELETE /api/v1/collections/:id/items/:expressionId` - 從集合移除內容
- `GET /api/v1/collections/check-item` - 檢查是否已包含項目

#### 管理員端點

- `PUT /api/v1/users/:id/role` - 更新用戶角色（僅超級管理員）

#### 導出功能（部分實現）

- `POST /api/v1/export` - 發起導出任務
- `GET /api/v1/export/:jobId` - 查詢導出任務狀態
- `GET /api/v1/export/health` - 導出服務健康檢查

## 詳細端點說明

### 公開端點

#### GET /api/v1/languages

獲取支持的語言列表。

**查詢參數**：
- `is_active` (number, optional) - 是否只返回激活的語言（0或 1）

**響應**：
```json
[
  {
    "id": 1,
    "code": "en-US",
    "name": "English (United States)",
    "direction": "ltr",
    "is_active": 1,
    "region_code": "US",
    "region_name": "New York",
    "region_latitude": "40.7128",
    "region_longitude": "-74.0060",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T00:00:00Z"
  }
]
```

#### GET /api/v1/statistics

獲取系統統計信息。

**響應**：
```json
{
  "total_expressions": 1250,
  "total_languages": 24,
  "total_regions": 18
}
```

#### GET /api/v1/heatmap

獲取熱力圖數據，用於首頁語言可視化。

**響應**：
```json
{
  "data": [
    {
      "language_code": "en-US",
      "language_name": "English (United States)",
      "region_code": "US",
      "region_name": "New York",
      "count": 42,
      "latitude": "40.7128",
      "longitude": "-74.0060"
    },
    {
      "language_code": "zh-CN",
      "language_name": "Chinese (Simplified)",
      "region_code": "CN",
      "region_name": "Beijing",
      "count": 38,
      "latitude": "39.9042",
      "longitude": "116.4074"
    }
  ]
}
```

**緩存**：10分鐘內存緩存

#### GET /api/v1/search

搜索表達式。

**查詢參數**：
- `q` (string, required) - 搜索關鍵詞
- `from_lang` (string, optional) - 源語言代碼
- `region` (string, optional) - 地域代碼
- `skip` (number, optional) - 跳過數量（默認 0）
- `limit` (number, optional) - 返回數量限制（默認 20）

**響應**：
```json
{
  "results": [
    {
      "id": 1,
      "text": "Hello",
      "language_code": "en",
      "region_code": "US",
      "review_status": "approved",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### GET /api/v1/ui-translations/:language

獲取指定語言的 UI 翻譯。

**路徑參數**：
- `language` (string, required) - 語言代碼（如 "en-US", "zh-CN"）

**查詢參數**：
- `skip` (number, optional) - 跳過數量（默認 0）
- `limit` (number, optional) - 返回數量限制（默認 1000）

**響應**：
```json
[
  {
    "id": 1,
    "text": "Home",
    "language": "en-US",
    "gloss": "langmap.home.title",
    "created_by": "system",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### POST /api/v1/ui-translations/:language

批量保存 UI 翻譯。

**路徑參數**：
- `language` (string, required) - 語言代碼

**請求體**：
```json
{
  "translations": [
    {
      "key": "home.title",
      "text": "首頁"
    }
  ]
}
```

**響應**：
```json
{
  "success": true,
  "processed": 1,
  "results": [
    {
      "key": "home.title",
      "error": null
    }
  ]
}
```

#### POST /api/v1/sync-locales

同步本地 JSON 文件到數據庫。

**請求體**：
```json
{
  "languages": ["en-US", "zh-CN", "es"],
  "localeData": {
    "en-US": { "home.title": "Home" },
    "zh-CN": { "home.title": "首頁" }
  }
}
```

**響應**：
```json
{
  "success": true,
  "results": {
    "en-US": { "added": 5, "updated": 100 },
    "zh-CN": { "added": 3, "updated": 95, "errors": [] }
  }
}
```

### 認證端點

#### POST /api/v1/auth/register

用戶註冊並發送郵箱驗證郵件。

**請求體**：
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**響應**：
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com",
      "role": "user"
    }
  },
  "message": "Please check your email for verification. We've sent a verification link to john@example.com."
}
```

**郵箱驗證流程**：
1. 創建用戶（email_verified = 0）
2. 生成驗證 token（1小時有效）
3. 發送驗證郵件（使用 Resend）
4. 用戶點擊驗證鏈接激活賬戶

#### POST /api/v1/auth/login

用戶登錄並獲取 JWT token。

**請求體**：
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**響應**：
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJp...（24小時有效）",
  "data": {
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com",
      "role": "user",
      "email_verified": 1
    }
  }
}
```

#### POST /api/v1/auth/logout

用戶登出（客戶端通常刪除 token）。

**響應**：
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### GET /api/v1/auth/verify-email

驗證郵箱並激活賬戶。

**查詢參數**：
- `token` (string, required) - 驗證 token

**響應**：
```json
{
  "success": true,
  "message": "Email verified successfully. You can now log in."
}
```

### 需要認證的端點

#### GET /api/v1/users/me

獲取當前登錄用戶的信息。

**響應**：
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "user",
  "email_verified": 1,
  "created_at": "2024-01-01T00:00:00Z"
}
```

### 表達式管理

#### GET /api/v1/expressions

獲取表達式列表，支持過濾和分頁。

**查詢參數**：
- `skip` (number, optional) - 跳過數量（默認 0）
- `limit` (number, optional) - 返回數量限制（默認 20）
- `language` (string, optional) - 語言代碼
- `meaning_id` (number, optional) - 含義 ID

**響應**：
```json
[
  {
    "id": 1,
    "text": "Hello",
    "language_code": "en-US",
    "meaning_id": 5,
    "region_code": "US",
    "review_status": "approved"
  }
]
```

#### GET /api/v1/expressions/:id

獲取表達式詳情。

**路徑參數**：
- `id` (number, required) - 表達式 ID

**響應**：
```json
{
  "id": 1,
  "text": "Hello",
  "language_code": "en-US",
    "meaning_id": 5,
    "audio_url": "https://example.com/audio.mp3",
    "tags": "[\"greeting\"]",
    "source_type": "user",
    "review_status": "approved",
    "created_by": "john_doe",
    "created_at": "2024-01-01T00:00:00Z"
}
```

#### POST /api/v1/expressions

創建新的表達式。

**請求體**：
```json
{
  "text": "Hello",
  "language_code": "en-US",
  "meaning_id": 5,
  "region_code": "US",
  "audio_url": "https://example.com/audio.mp3",
  "tags": "[\"greeting\"]"
}
```

**響應**：
```json
{
  "id": 1,
  "text": "Hello",
  "language_code": "en-US",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### GET /api/v1/expressions/:id/versions

獲取表達式的版本歷史。

**路徑參數**：
- `id` (number, required) - 表達式 ID

**響應**：
```json
[
  {
    "id": 1,
    "expression_id": 1,
    "text": "Hello v2",
    "language_code": "en-US",
    "created_by": "john_doe",
    "created_at": "2024-01-02T10:30:00Z"
  }
]
```

#### GET /api/v1/expressions/:id/meanings

獲取表達式關聯的語義信息。

**路徑參數**：
- `id` (number, required) - 表達式 ID

**響應**：
```json
[
  {
    "id": 1,
    "gloss": "langmap.home.title",
    "description": "首頁標題",
    "tags": "[\"langmap\"]"
  }
]
}
```

#### PATCH /api/v1/expressions/:id

更新表達式（編輯）。

**路徑參數**：
- `id` (number, required) - 表達式 ID

**請求體**：
```json
{
  "text": "Hello World",
  "audio_url": "https://example.com/audio2.mp3",
  "tags": "[\"greeting\"]"
}
```

**響應**：
```json
{
  "id": 1,
  "text": "Hello World",
  "language_code": "en-US",
  "updated_at": "2024-01-02T10:30:00Z"
}
```

#### DELETE /api/v1/expressions/:id

刪除表達式。

**路徑參數**：
- `id` (number, required) - 表達式 ID

**響應**：
```json
{
  "success": true,
  "message": "Expression deleted successfully"
}
```

### 語義管理

#### POST /api/v1/meanings

創建新的語義。

**請求體**：
```json
{
  "gloss": "langmap.home.title",
  "description": "首頁標題",
  "tags": "[\"langmap\"]"
}
```

**響應**：
```json
{
  "id": 1,
  "gloss": "langmap.home.title",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### POST /api/v1/meanings/:id/link

將表達式關聯到語義。

**路徑參數**：
- `id` (number, required) - 語義 ID

**請求體**：
```json
{
  "expression_id": 1
}
```

**響應**：
```json
{
  "success": true,
  "message": "Expression linked to meaning successfully"
}
```

#### GET /api/v1/meanings/:id

獲取語義詳情。

**路徑參數**：
- `id` (number, required) - 語義 ID

**響應**：
```json
{
  "id": 1,
  "gloss": "langmap.home.title",
  "description": "首頁標題",
  "tags": "[\"langmap\"]",
  "expressions": [
    {
      "id": 1,
      "text": "Home"
    },
    {
      "id": 2,
      "text": "首頁"
    }
  ]
}
```

### 集合管理

#### GET /api/v1/collections

獲取集合列表。

**查詢參數**：
- `skip` (number, optional) - 跳過數量（默認 0）
- `limit` (number, optional) - 返回數量限制（默認 20）
- `is_public` (boolean, optional) - 是否只返回公開集合

**響應**：
```json
[
  {
    "id": 1,
    "user_id": 1,
    "name": "My Favorites",
    "description": "My favorite expressions",
    "is_public": 0,
    "items_count": 42,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### POST /api/v1/collections

創建新集合。

**請求體**：
```json
{
  "name": "My Collection",
  "description": "My favorite expressions",
  "is_public": false
}
```

**響應**：
```json
{
  "id": 1,
  "name": "My Collection",
  "description": "My favorite expressions",
  "is_public": 0,
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### GET /api/v1/collections/:id

獲取集合詳情。

**路徑參數**：
- `id` (number, required) - 集合 ID

**響應**：
```json
{
  "id": 1,
  "user_id": 1,
  "name": "My Collection",
  "description": "My favorite expressions",
  "is_public": 0,
  "items_count": 42,
  "created_at": "2024-01-01T00:00:00Z",
  "items": [
    {
      "id": 1,
      "collection_id": 1,
      "expression_id": 1,
      "note": "My favorite"
    }
  ]
}
```

#### PUT /api/v1/collections/:id

更新集合。

**路徑參數**：
- `id` (number, required) - 集合 ID

**請求體**：
```json
{
  "name": "Updated Collection",
  "description": "Updated description",
  "is_public": true
}
```

**響應**：
```json
{
  "id": 1,
  "name": "Updated Collection",
  "description": "Updated description",
  "is_public": 1,
  "updated_at": "2024-01-15T00:00:00Z"
}
```

#### DELETE /api/v1/collections/:id

刪除集合。

**路徑參數**：
- `id` (number, required) - 集合 ID

**響應**：
```json
{
  "success": true,
  "message": "Collection deleted successfully"
}
```

#### GET /api/v1/collections/:id/items

獲取集合內容。

**路徑參數**：
- `id` (number, required) - 集合 ID
- `skip` (number, optional) - 跳過數量（默認 0）
- `limit` (number, optional) - 返回數量限制（默認 20）

**響應**：
```json
[
  {
    "id": 1,
    "collection_id": 1,
    "expression_id": 1,
    "note": "My favorite"
  }
  ]
}
```

#### POST /api/v1/collections/:id/items

添加內容到集合。

**路徑參數**：
- `id` (number, required) - 集合 ID

**請求體**：
```json
{
  "expression_id": 1,
  "note": "My favorite"
}
```

**響應**：
```json
{
  "id": 1,
  "collection_id": 1,
  "expression_id": 1,
    "note": "My favorite",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### DELETE /api/v1/collections/:id/items/:expressionId

從集合中移除內容。

**路徑參數**：
- `id` (number, required) - 集合 ID
- `expressionId` (number, required) - 表達式 ID

**響應**：
```json
{
  "success": true,
  "message": "Item removed from collection"
}
```

#### GET /api/v1/collections/check-item

檢查集合是否包含某個表達式。

**查詢參數**：
- `id` (number, required) - 集合 ID
- `expressionId` (number, required) - 表達式 ID

**響應**：
```json
[
  {
    "id": 1,
    "collection_id": 1,
    "expression_id": 1
  }
]
```

### 管理員端點

#### PUT /api/v1/users/:id/role

更新用戶角色（僅超級管理員）。

**路徑參數**：
- `id` (number, required) - 用戶 ID
- `role` (string, required) - 用戶角色（'user', 'admin', 'super_admin'）

**響應**：
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "admin",
  "updated_at": "2024-01-20T00:00:00Z"
}
```

### 導出功能（部分實現）

#### POST /api/v1/export

發起導出任務。

**請求體**：
```json
{
  "collectionId": 1,
  "format": "csv"
}
```

**響應**：
```json
{
  "jobId": "exp_17045678901234"
}
```

#### GET /api/v1/export/:jobId

查詢導出任務狀態。

**路徑參數**：
- `jobId` (string, required) - 任務 ID

**響應**：
```json
{
  "jobId": "exp_17045678901234",
  "status": "pending",
  "progress": 0,
  "total": 1250
}
```

**狀態值**：
- `pending` - 等待處理
- `processing` - 處理中
- `completed` - 已完成
- `failed` - 失敗

#### GET /api/v1/export/health

檢查導出服務健康狀態。

**響應**：
```json
{
  "status": "healthy",
  "message": "Export service is running"
}
```

## 錯誤響應格式

### 通用錯誤格式

```json
{
  "error": "錯誤描述"
}
```

### HTTP 狀態碼

- `200 OK` - 請求成功
- `400 Bad Request` - 請求參數錯誤
- `401 Unauthorized` - 未認證
- `403 Forbidden` - 權限不足
- `404 Not Found` - 資源未找到
- `500 Internal Server Error` - 服務器內部錯誤

### 常見錯誤

| HTTP 狀態碼 | 錯誤場景 |
|-----------|---------|
| 400 | 缺少必需參數、參數格式錯誤 |
| 401 | Token 無效或過期、認證失敗 |
| 403 | 用戶權限不足（如刪除他人的內容） |
| 404 | 資源不存在（ID 不存在） |
| 500 | 數據庫錯誤、服務器內部錯誤 |

## 相關文檔

- [數據庫設計](../design/features/feat-database.md)
- [系統架構設計](../system/architecture.md)
- [用戶與權限系統設計](../features/feat-user-system.md)
- [搜索功能設計](../features/feat-search.md)
- [熱力圖功能設計](../features/feat-heatmap.md)
- [用戶資料設計](../features/feat-user-profile.md)
