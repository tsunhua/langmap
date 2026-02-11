# 总体系统设计

本目录包含 LangMap 项目的总体系统架构文档，反映实际实现情况。

## 文档列表

- [architecture.md](./architecture.md) - 系统总体架构设计（已按实际实现更新）

## 文档说明

### architecture.md
反映 LangMap 项目实际实现状态的系统架构设计文档，包括：

**已实现的技术栈**
- 前端：Vue 3 + Vite + vue-i18n + Tailwind CSS
- 后端：Hono + TypeScript + Cloudflare Workers
- 认证：JWT + bcrypt
- 邮件：Resend
- 数据库：Cloudflare D1 (SQLite 兼容)
- 存储：Cloudflare R2 (用于导出功能)
- 部署：Wrangler CLI + GitHub Actions

**已实现的数据模型**
- Expression 表（表达式主表）
- ExpressionVersion 表（版本历史）
- Meaning 表（语义表）
- ExpressionMeaning 表（表达式-语义关联）
- User 表（用户表）
- Language 表（语言表）
- Collection 表（集合表）
- CollectionItem 表（集合项目表）

**已实现的 API 端点**
- 语言管理、表达式管理、语义管理
- 用户认证、用户信息
- 统计和热力图
- 搜索
- 集合管理
- UI 翻译

**未实现或部分实现的功能**
- 版本回滚和差异比较
- AI 建议生成
- 用户角色管理
- 内容审核队列
- 邮箱验证（部分）
- 地域查询
- 导出功能

**详细设计文档链接**
- 搜索功能：[../features/feat-search.md](../features/feat-search.md)
- 语言地图/热力图：[../features/feat-heatmap.md](../features/feat-heatmap.md)

**已实现的核心页面**
- 首页（包含热力图可视化）、查询词条页（包含搜索）、表达式详情页
- 集合页面、用户认证页面、用户资料页面

**未实现的核心页面**
- AI 补全界面、地域选择器

## 实施状态

- [x] 基础架构
- [x] 核心数据模型
- [x] 基础 API 设计
- [ ] 版本回滚功能
- [ ] 版本比较功能
- [ ] 变更摘要功能

## 相关文档

- [功能模块设计](../features/) - 详细的功能模块设计
- [API 文档](../../api/) - API 接口文档
- [实施指南](../../guides/) - 开发和部署指南
