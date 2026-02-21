# 系统总体架构设计

## 技术栈（已实现）

### 前端
- Vue 3 + Vite
- vue-i18n (国际化)
- Tailwind CSS (样式)
- Leaflet + OpenStreetMap (地图)

### 后端
- Hono + TypeScript
- Cloudflare Workers (无服务器运行时)
- JWT 认证
- bcrypt 密码加密
- Resend (邮件服务)

### 数据库
- Cloudflare D1 (SQLite 兼容边缘数据库)
- Cloudflare R2 (对象存储，用于导出功能)
- Cloudflare KV (缓存和会话存储，可选)

**详细设计**：完整的数据库设计、表结构、索引策略、性能优化等内容，请参见 [feat-database.md](features/feat-database.md)

### 部署
- Wrangler CLI (Cloudflare Workers 开发和部署工具)
- GitHub Actions (CI/CD)

## 数据模型（已实现）

### 核心表

**注意**：以下列出了所有核心表的简要说明。完整的数据库设计（包括详细字段、索引、迁移策略、性能优化等），请参见 [feat-database.md](features/feat-database.md)

**Expression 表** - 表达式主表
- 存储当前活动的表达式版本
- 字段：id, text, meaning_id, audio_url, language_code, region_code, region_name, region_latitude, region_longitude, tags, source_type, source_ref, review_status, created_by, created_at, updated_by, updated_at

**ExpressionVersion 表** - 版本历史表
- 采用追加写（append-only）模式记录每次变更
- 字段：id, expression_id, text, meaning_id, audio_url, region_name, region_latitude, region_longitude, created_by, created_at
- 注意：实际实现中没有 `parent_version_id` 字段

**Meaning 表** - 语义表
- 字段：id, gloss, description, tags, created_by, created_at

**ExpressionMeaning 表** - 表达式-语义关联表
- 字段：id, expression_id, meaning_id, created_by, created_at, note
- 注意：包含了 `parent_version_id` 字段，但当前版本系统未使用

**User 表** - 用户表
- 字段：id, username, email, password_hash, role, email_verified, created_at, updated_at

**Language 表** - 语言表
- 字段：id, code, name, direction, is_active, region_code, region_name, region_latitude, region_longitude, created_by, updated_at

**Collection 表** - 集合表
- 字段：id, user_id, name, description, is_public, created_at, updated_at

**CollectionItem 表** - 集合项目表
- 字段：id, collection_id, expression_id, note, created_at

## API 端点

### 已实现的端点

**语言管理**
- `GET /api/v1/languages` - 获取支持的语言列表
- `GET /api/v1/languages?is_active=1` - 获取激活的语言

**表达式管理**
- `GET /api/v1/expressions` - 获取表达式列表（支持过滤）
- `GET /api/v1/expressions/:id` - 获取表达式详情
- `POST /api/v1/expressions` - 创建表达式
- `GET /api/v1/expressions/:id/versions` - ⚠️ 已实现 - 获取表达式版本历史
- `GET /api/v1/expressions/:id/translations` - 获取表达式翻译
- `GET /api/v1/expressions/:id/meanings` - 获取表达式含义

**语义管理**
- `POST /api/v1/meanings` - 创建含义
- `POST /api/v1/meanings/:id/link` - 关联表达式与含义

**用户认证**
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/logout` - 用户登出

**统计和热力图**
- `GET /api/v1/statistics` - 获取系统统计信息
- `GET /api/v1/heatmap` - 获取热力图数据

**搜索**
- `GET /api/v1/search` - 搜索表达式（支持关键词、语言、地域过滤）

**集合管理**
- `GET /api/v1/collections` - 获取集合列表
- `POST /api/v1/collections` - 创建集合
- `GET /api/v1/collections/:id` - 获取集合详情
- `PUT /api/v1/collections/:id` - 更新集合
- `DELETE /api/v1/collections/:id` - 删除集合
- `GET /api/v1/collections/:id/items` - 获取集合内容
- `POST /api/v1/collections/:id/items` - 添加内容到集合
- `DELETE /api/v1/collections/:id/items/:expressionId` - 从集合移除内容

### 未实现或部分实现的端点

**版本历史相关**
- `GET /api/v1/expressions/:id/versions/:vid` - ❌ 未实现 - 无法获取单个版本的详细信息
- `PATCH /api/v1/expressions/:id` - ⚠️ 仅定义未实现 - 没有专门的编辑和版本创建端点
- `POST /api/v1/expressions/:id/versions/:vid/revert` - ❌ 未实现 - 缺少版本回滚功能
- `GET /api/v1/expressions/:id/diff?from=vid1&to=vid2` - ❌ 未实现 - 没有版本差异比较 API

**AI 建议**
- `POST /api/v1/ai/suggest` - ❌ 未实现 - AI 生成表达式建议

**用户管理**
- `GET /api/v1/users/me` - ✅ 已实现 - 获取当前用户信息
- `PUT /api/v1/users/:id/role` - ❌ 未实现 - 更新用户角色（仅超级管理员）

**内容审核**
- `PUT /api/v1/expressions/:id/revision/:revision_id/approve` - ❌ 未实现 - 审核内容修改

**UI 翻译**
- `POST /api/v1/ui-translations/:language` - ✅ 已实现 - 保存 UI 翻译

**邮件验证**
- `GET /api/v1/auth/verify-email` - ⚠️ 部分实现 - 文档已设计，端点可能已实现需确认
- `POST /api/v1/auth/resend-verification` - ❌ 未实现 - 重发验证邮件

**搜索**
- `GET /api/v1/search` - ✅ 已实现 - 搜索表达式（支持关键词、语言、地域过滤）
- **详细设计**：参见 [feat-search.md](features/feat-search.md)

**地域查询**
- `GET /api/v1/regions?near=lat,lng&max_level=town` - ❌ 未实现 - 地域选择器

**导出功能**
- `POST /api/v1/export` - ❌ 未实现 - 发起导出
- `GET /api/v1/export/:jobId` - ❌ 未实现 - 查询导出状态

## 版本历史实现状态

### 数据模型
- ✅ 已实现版本存储（`ExpressionVersion` 表）
- ✅ 已实现版本查询 API
- ⚠️ `Expression` 表不包含 `current_version_id` 外键
- ❌ `ExpressionVersion` 缺少 `parent_version_id` 字段
- ❌ `ExpressionVersion` 缺少 `source_type`, `review_status`, `auto_approved` 字段

### API 端点
- ✅ `GET /api/v1/expressions/:expr_id/versions` - 已实现
- ❌ `GET /api/v1/expressions/:expr_id/versions/:vid` - 未实现
- ⚠️ `PATCH /api/v1/expressions/:id` - 仅定义未实现
- ❌ `POST /api/v1/expressions/:id/versions/:vid/revert` - 未实现
- ❌ `GET /api/v1/expressions/:id/diff` - 未实现

### 前端
- ✅ `VersionHistory.vue` 组件已实现
- ❌ 变更摘要功能未实现
- ❌ 差异预览功能未实现

### 关键差异

| 设计预期 | 实际实现 |
|---------|---------|
| `Expression` 表包含 `current_version_id` 外键 | `Expression` 表直接存储当前数据 |
| `ExpressionVersion` 包含 `parent_version_id` | `parent_version_id` 字段不存在 |
| 支持版本回滚和 diff 比较 | 相关 API 端点和功能尚未实现 |
| 用户编辑需审核后才成为当前版本 | 当前实现中，任何编辑都会立即成为当前版本 |

## 核心页面

### 已实现
- 首页：表达式展示和语言统计（包含热力图可视化）
- 查询词条页面：搜索和浏览表达式
- 表达式详情页：显示表达式信息、关联翻译、版本历史
- 集合页面：创建和管理收藏集
- 用户认证页面：登录和注册

### 未实现
- AI 补全功能界面
- 地域选择器

## 架构特点

### 已实现
- 无服务器架构（Cloudflare Workers）
- 边缘数据库（D1）
- 边缘对象存储（R2，用于导出）
- JWT 认证
- 前后端分离
- 版本历史追踪

### 设计中但未实现
- 实时地理空间查询（PostGIS）
- 高并发检索（Typesense/Elasticsearch）
- 异步任务队列（Durable Objects 用于导出）
- 分布式缓存（KV 存储）

## 相关文档

- [功能模块设计](../features/)
- [API 文档](../../api/)
- [实施指南](../../guides/)
