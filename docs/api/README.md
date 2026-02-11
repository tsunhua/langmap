# API 文档

本目录包含 LangMap 后端 API 的技术文档和实施指南。

## 文档列表

- [backend-guide.md](./backend-guide.md) - 后端部署与配置指南
- [statistics-api.md](./statistics-api.md) - 统计 API 设计文档
- [heatmap-api.md](./heatmap-api.md) - 热力图 API 设计文档

## 文档说明

### backend-guide.md
LangMap 后端的部署与配置指南，包括：
- 数据库架构说明
  - Languages 表
  - Expressions 表
  - Meanings 表
  - ExpressionMeaning 表
- API 端点说明
  - Language Management
  - Expression Management
  - Meaning Management
  - UI Translation Endpoints
- 国际化实现机制
- 数据库迁移脚本
- 环境变量配置
- 运行应用方式

### statistics-api.md
系统统计接口的设计文档，包括：
- 概述（解决前端计算统计信息的问题）
- API 端点 `GET /api/v1/statistics`
- 响应格式与字段说明
- SQL 查询逻辑（优化的查询方式）
- 实现细节
- 缓存机制（10分钟缓存）
- 性能优势
- 测试用例
- 后续优化建议

### heatmap-api.md
首页热力图 API 的设计文档，包括：
- 概述（替代前端数据聚合）
- API 端点 `GET /api/v1/heatmap`
- 响应格式与字段说明
- SQL 查询逻辑（使用 languages 表作为主数据源）
- 缓存策略（10分钟缓存）
- 实现细节
- 性能优势
- 测试用例
- 未来增强功能

## API 端点总览

### 公开端点（无需认证）
- `GET /api/v1/languages` - 获取支持的语言列表
- `GET /api/v1/expressions` - 获取表达式列表（支持过滤）
- `GET /api/v1/search` - 搜索表达式
- `GET /api/v1/statistics` - 获取系统统计信息
- `GET /api/v1/heatmap` - 获取热力图数据
- `GET /api/v1/ui-translations/:language` - 获取 UI 翻译

### 认证端点
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/logout` - 用户登出
- `GET /api/v1/auth/verify-email` - 验证邮箱
- `POST /api/v1/auth/resend-verification` - 重发验证邮件

### 需要认证的端点
- `GET /api/v1/users/me` - 获取当前用户信息
- `GET /api/v1/expressions/{id}` - 获取表达式详情
- `POST /api/v1/expressions` - 创建表达式
- `POST /api/v1/ai/suggest` - AI 建议表达式
- `GET /api/v1/expressions/{id}/versions` - 获取表达式版本历史
- `GET /api/v1/expressions/{id}/translations` - 获取表达式翻译
- `GET /api/v1/expressions/{id}/meanings` - 获取表达式含义
- `POST /api/v1/meanings` - 创建含义
- `POST /api/v1/meanings/{id}/link` - 关联表达式与含义
- `POST /api/v1/ui-translations/:language` - 保存 UI 翻译
- `GET /api/v1/collections` - 获取集合列表
- `POST /api/v1/collections` - 创建集合
- `GET /api/v1/collections/:id` - 获取集合详情
- `PUT /api/v1/collections/:id` - 更新集合
- `DELETE /api/v1/collections/:id` - 删除集合
- `GET /api/v1/collections/:id/items` - 获取集合内容
- `POST /api/v1/collections/:id/items` - 添加内容到集合
- `DELETE /api/v1/collections/:id/items/:expressionId` - 从集合移除内容

### 管理员端点
- `PUT /api/v1/users/{id}/role` - 更新用户角色（超级管理员）
- `DELETE /api/v1/expressions/{id}` - 删除表达式（管理员）
- `PUT /api/v1/expressions/{id}/revision/{revision_id}/approve` - 审核修订（管理员）
- `DELETE /api/v1/expressions/batch` - 批量删除表达式（超级管理员）

## 实施状态

- [x] backend-guide.md - 已实现
- [x] statistics-api.md - 已实现
- [x] heatmap-api.md - 已实现

## 相关文档

- [系统设计](../design/)
- [实施指南](../guides/)
