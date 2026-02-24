# API 文档

本文档描述 LangMap 后端 API 的所有端点、认证机制、请求/响应格式和使用说明。

## 概述

LangMap API 使用 Hono + TypeScript 框架，部署在 Cloudflare Workers 上，使用 Cloudflare D1 作为数据库。API 遵循 RESTful 设计原则，所有端点使用 `/api/v1/` 前缀。

## 认证机制

### JWT 认证

系统使用 JWT (JSON Web Token) 进行用户认证：

**端点**：
- `POST /api/v1/auth/register` - 用户注册（含邮箱验证）
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/logout` - 用户登出
- `GET /api/v1/auth/verify-email` - 验证邮箱

**认证流程**：
1. 用户注册/登录 → 服务器返回 JWT token
2. 客户端在请求头中携带 token：`Authorization: Bearer {token}`
3. 服务器验证 token 有效性，设置用户上下文
4. token 有效期 24 小时

### 权限控制

**公开端点**：无需认证
- `GET /api/v1/languages`
- `GET /api/v1/statistics`
- `GET /api/v1/heatmap`
- `GET /api/v1/ui-translations/:language`

**需要认证的端点**：
- 用户信息管理
- 表达式管理
- 语义管理
- 集合管理
- UI 翻译保存

**管理员端点**：
- `PUT /api/v1/users/:id/role` - 更新用户角色（超级管理员）

## 数据库架构

LangMap 使用 Cloudflare D1 (SQLite 兼容边缘数据库)，详细的表结构请参见：[数据库设计文档](../design/features/feat-database.md)

**核心表概览**：
- `languages` - 语言表
- `expressions` - 表达式主表
- `expression_versions` - 版本历史表
- `meanings` - 语义表
- `expression_meanings` - 表达式-语义关联表
- `users` - 用户表
- `collections` - 集合表
- `collection_items` - 集合项目表
- `email_verification_tokens` - 邮箱验证令牌表

## API 端点总览

### 按功能分类

#### 公开端点

**语言管理**
- `GET /api/v1/languages` - 获取支持的语言列表
- `GET /api/v1/languages?is_active=1` - 获取激活的语言

**统计和热力图**
- `GET /api/v1/statistics` - 获取系统统计信息
- `GET /api/v1/heatmap` - 获取热力图数据

**搜索功能**
- `GET /api/v1/search` - 搜索表达式

**UI 翻译**
- `GET /api/v1/ui-translations/:language` - 获取 UI 翻译
- `POST /api/v1/ui-translations/:language` - 保存 UI 翻译
- `POST /api/v1/sync-locales` - 同步本地翻译到数据库

#### 认证端点

- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/logout` - 用户登出
- `GET /api/v1/auth/verify-email` - 验证邮箱

#### 需要认证的端点

**用户信息**
- `GET /api/v1/users/me` - 获取当前用户信息

**表达式管理**
- `GET /api/v1/expressions` - 获取表达式列表
- `GET /api/v1/expressions/:id` - 获取表达式详情
- `POST /api/v1/expressions` - 创建表达式
- `GET /api/v1/expressions/:id/versions` - 获取表达式版本历史
- `GET /api/v1/expressions/:id/translations` - 获取表达式翻译
- `GET /api/v1/expressions/:id/meanings` - 获取表达式含义
- `PATCH /api/v1/expressions/:id` - 更新表达式（编辑）
- `DELETE /api/v1/expressions/:id` - 删除表达式

**语义管理**
- `POST /api/v1/meanings` - 创建含义
- `POST /api/v1/meanings/:id/link` - 关联表达式与含义
- `GET /api/v1/meanings/:id` - 获取语义详情

**集合管理**
- `GET /api/v1/collections` - 获取集合列表
- `POST /api/v1/collections` - 创建集合
- `GET /api/v1/collections/:id` - 获取集合详情
- `PUT /api/v1/collections/:id` - 更新集合
- `DELETE /api/v1/collections/:id` - 删除集合
- `GET /api/v1/collections/:id/items` - 获取集合内容
- `POST /api/v1/collections/:id/items` - 添加内容到集合
- `DELETE /api/v1/collections/:id/items/:expressionId` - 从集合移除内容
- `GET /api/v1/collections/check-item` - 检查是否已包含项目

#### 管理员端点

- `PUT /api/v1/users/:id/role` - 更新用户角色（仅超级管理员）

#### 导出功能（部分实现）

- `POST /api/v1/export` - 发起导出任务
- `GET /api/v1/export/:jobId` - 查询导出任务状态
- `GET /api/v1/export/health` - 导出服务健康检查

## 详细端点说明

### 公开端点

#### GET /api/v1/languages

获取支持的语言列表。

**查询参数**：
- `is_active` (number, optional) - 是否只返回激活的语言（0或 1）

**响应**：
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

获取系统统计信息。

**响应**：
```json
{
  "total_expressions": 1250,
  "total_languages": 24,
  "total_regions": 18
}
```

#### GET /api/v1/heatmap

获取热力图数据，用于首页语言可视化。

**响应**：
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

**缓存**：10分钟内存缓存

#### GET /api/v1/search

搜索表达式。

**查询参数**：
- `q` (string, required) - 搜索关键词
- `from_lang` (string, optional) - 源语言代码
- `region` (string, optional) - 地域代码
- `skip` (number, optional) - 跳过数量（默认 0）
- `limit` (number, optional) - 返回数量限制（默认 20）

**响应**：
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

获取指定语言的 UI 翻译。

**路径参数**：
- `language` (string, required) - 语言代码（如 "en-US", "zh-CN"）

**查询参数**：
- `skip` (number, optional) - 跳过数量（默认 0）
- `limit` (number, optional) - 返回数量限制（默认 1000）

**响应**：
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

批量保存 UI 翻译。

**路径参数**：
- `language` (string, required) - 语言代码

**请求体**：
```json
{
  "translations": [
    {
      "key": "home.title",
      "text": "首页"
    }
  ]
}
```

**响应**：
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

同步本地 JSON 文件到数据库。

**请求体**：
```json
{
  "languages": ["en-US", "zh-CN", "es"],
  "localeData": {
    "en-US": { "home.title": "Home" },
    "zh-CN": { "home.title": "首页" }
  }
}
```

**响应**：
```json
{
  "success": true,
  "results": {
    "en-US": { "added": 5, "updated": 100 },
    "zh-CN": { "added": 3, "updated": 95, "errors": [] }
  }
}
```

### 认证端点

#### POST /api/v1/auth/register

用户注册并发送邮箱验证邮件。

**请求体**：
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**响应**：
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

**邮箱验证流程**：
1. 创建用户（email_verified = 0）
2. 生成验证 token（1小时有效）
3. 发送验证邮件（使用 Resend）
4. 用户点击验证链接激活账户

#### POST /api/v1/auth/login

用户登录并获取 JWT token。

**请求体**：
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**响应**：
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJp...（24小时有效）",
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

用户登出（客户端通常删除 token）。

**响应**：
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### GET /api/v1/auth/verify-email

验证邮箱并激活账户。

**查询参数**：
- `token` (string, required) - 验证 token

**响应**：
```json
{
  "success": true,
  "message": "Email verified successfully. You can now log in."
}
```

### 需要认证的端点

#### GET /api/v1/users/me

获取当前登录用户的信息。

**响应**：
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

### 表达式管理

#### GET /api/v1/expressions

获取表达式列表，支持过滤和分页。

**查询参数**：
- `skip` (number, optional) - 跳过数量（默认 0）
- `limit` (number, optional) - 返回数量限制（默认 20）
- `language` (string, optional) - 语言代码
- `meaning_id` (number, optional) - 含义 ID

**响应**：
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

获取表达式详情。

**路径参数**：
- `id` (number, required) - 表达式 ID

**响应**：
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

创建新的表达式。

**请求体**：
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

**响应**：
```json
{
  "id": 1,
  "text": "Hello",
  "language_code": "en-US",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### GET /api/v1/expressions/:id/versions

获取表达式的版本历史。

**路径参数**：
- `id` (number, required) - 表达式 ID

**响应**：
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

#### GET /api/v1/expressions/:id/translations

获取表达式的跨语言翻译。

**路径参数**：
- `id` (number, required) - 表达式 ID
- `language_code` (string, optional) - 语言代码

**响应**：
```json
[
  {
    "id": 1,
    "text": "Hello",
    "language_code": "zh-CN",
    "created_by": "john_doe",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### GET /api/v1/expressions/:id/meanings

获取表达式关联的语义信息。

**路径参数**：
- `id` (number, required) - 表达式 ID

**响应**：
```json
[
  {
    "id": 1,
    "gloss": "langmap.home.title",
    "description": "首页标题",
    "tags": "[\"langmap\"]"
  }
]
}
```

#### PATCH /api/v1/expressions/:id

更新表达式（编辑）。

**路径参数**：
- `id` (number, required) - 表达式 ID

**请求体**：
```json
{
  "text": "Hello World",
  "audio_url": "https://example.com/audio2.mp3",
  "tags": "[\"greeting\"]"
}
```

**响应**：
```json
{
  "id": 1,
  "text": "Hello World",
  "language_code": "en-US",
  "updated_at": "2024-01-02T10:30:00Z"
}
```

#### DELETE /api/v1/expressions/:id

删除表达式。

**路径参数**：
- `id` (number, required) - 表达式 ID

**响应**：
```json
{
  "success": true,
  "message": "Expression deleted successfully"
}
```

### 语义管理

#### POST /api/v1/meanings

创建新的语义。

**请求体**：
```json
{
  "gloss": "langmap.home.title",
  "description": "首页标题",
  "tags": "[\"langmap\"]"
}
```

**响应**：
```json
{
  "id": 1,
  "gloss": "langmap.home.title",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### POST /api/v1/meanings/:id/link

将表达式关联到语义。

**路径参数**：
- `id` (number, required) - 语义 ID

**请求体**：
```json
{
  "expression_id": 1
}
```

**响应**：
```json
{
  "success": true,
  "message": "Expression linked to meaning successfully"
}
```

#### GET /api/v1/meanings/:id

获取语义详情。

**路径参数**：
- `id` (number, required) - 语义 ID

**响应**：
```json
{
  "id": 1,
  "gloss": "langmap.home.title",
  "description": "首页标题",
  "tags": "[\"langmap\"]",
  "expressions": [
    {
      "id": 1,
      "text": "Home"
    },
    {
      "id": 2,
      "text": "首页"
    }
  ]
}
```

### 集合管理

#### GET /api/v1/collections

获取集合列表。

**查询参数**：
- `skip` (number, optional) - 跳过数量（默认 0）
- `limit` (number, optional) - 返回数量限制（默认 20）
- `is_public` (boolean, optional) - 是否只返回公开集合

**响应**：
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

创建新集合。

**请求体**：
```json
{
  "name": "My Collection",
  "description": "My favorite expressions",
  "is_public": false
}
```

**响应**：
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

获取集合详情。

**路径参数**：
- `id` (number, required) - 集合 ID

**响应**：
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

**路径参数**：
- `id` (number, required) - 集合 ID

**请求体**：
```json
{
  "name": "Updated Collection",
  "description": "Updated description",
  "is_public": true
}
```

**响应**：
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

删除集合。

**路径参数**：
- `id` (number, required) - 集合 ID

**响应**：
```json
{
  "success": true,
  "message": "Collection deleted successfully"
}
```

#### GET /api/v1/collections/:id/items

获取集合内容。

**路径参数**：
- `id` (number, required) - 集合 ID
- `skip` (number, optional) - 跳过数量（默认 0）
- `limit` (number, optional) - 返回数量限制（默认 20）

**响应**：
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

添加内容到集合。

**路径参数**：
- `id` (number, required) - 集合 ID

**请求体**：
```json
{
  "expression_id": 1,
  "note": "My favorite"
}
```

**响应**：
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

从集合中移除内容。

**路径参数**：
- `id` (number, required) - 集合 ID
- `expressionId` (number, required) - 表达式 ID

**响应**：
```json
{
  "success": true,
  "message": "Item removed from collection"
}
```

#### GET /api/v1/collections/check-item

检查集合是否包含某个表达式。

**查询参数**：
- `id` (number, required) - 集合 ID
- `expressionId` (number, required) - 表达式 ID

**响应**：
```json
[
  {
    "id": 1,
    "collection_id": 1,
    "expression_id": 1
  }
]
```

### 管理员端点

#### PUT /api/v1/users/:id/role

更新用户角色（仅超级管理员）。

**路径参数**：
- `id` (number, required) - 用户 ID
- `role` (string, required) - 用户角色（'user', 'admin', 'super_admin'）

**响应**：
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "admin",
  "updated_at": "2024-01-20T00:00:00Z"
}
```

### 导出功能（部分实现）

#### POST /api/v1/export

发起导出任务。

**请求体**：
```json
{
  "collectionId": 1,
  "format": "csv"
}
```

**响应**：
```json
{
  "jobId": "exp_17045678901234"
}
```

#### GET /api/v1/export/:jobId

查询导出任务状态。

**路径参数**：
- `jobId` (string, required) - 任务 ID

**响应**：
```json
{
  "jobId": "exp_17045678901234",
  "status": "pending",
  "progress": 0,
  "total": 1250
}
```

**状态值**：
- `pending` - 等待处理
- `processing` - 处理中
- `completed` - 已完成
- `failed` - 失败

#### GET /api/v1/export/health

检查导出服务健康状态。

**响应**：
```json
{
  "status": "healthy",
  "message": "Export service is running"
}
```

## 错误响应格式

### 通用错误格式

```json
{
  "error": "错误描述"
}
```

### HTTP 状态码

- `200 OK` - 请求成功
- `400 Bad Request` - 请求参数错误
- `401 Unauthorized` - 未认证
- `403 Forbidden` - 权限不足
- `404 Not Found` - 资源未找到
- `500 Internal Server Error` - 服务器内部错误

### 常见错误

| HTTP 状态码 | 错误场景 |
|-----------|---------|
| 400 | 缺少必需参数、参数格式错误 |
| 401 | Token 无效或过期、认证失败 |
| 403 | 用户权限不足（如删除他人的内容） |
| 404 | 资源不存在（ID 不存在） |
| 500 | 数据库错误、服务器内部错误 |

## 相关文档

- [数据库设计](../design/features/feat-database.md)
- [系统架构设计](../system/architecture.md)
- [用户与权限系统设计](../features/feat-user-system.md)
- [搜索功能设计](../features/feat-search.md)
- [热力图功能设计](../features/feat-heatmap.md)
- [用户资料设计](../features/feat-user-profile.md)
