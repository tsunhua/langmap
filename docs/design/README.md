# 系统设计文档

本目录包含 LangMap 系统的架构设计和功能设计文档。

## 文档列表

- [system-architecture.md](./system-architecture.md) - 系统总体架构设计
- [user-system.md](./user-system.md) - 用户与权限系统设计
- [collection-feature.md](./collection-feature.md) - 集合功能设计
- [export-system.md](./export-system.md) - 异步导出系统设计
- [ui-translation.md](./ui-translation.md) - UI 翻译系统设计
- [i18n-architecture.md](./i18n-architecture.md) - 国际化动态语言支持方案
- [dynamic-languages.md](./dynamic-languages.md) - 前端动态语言支持

## 文档说明

### system-architecture.md
LangMap 项目的总体架构设计文档，包括：
- 技术栈建议（前端 Vue 3，后端 FastAPI/Python 3.12）
- 数据模型草案
- API 设计示例
- 前端页面与交互流程
- 审核与信任机制
- 版本历史实现状态
- MVP 路线图

### user-system.md
用户管理与权限控制系统的设计文档，包括：
- 用户角色定义（超级管理员、管理员、普通用户）
- 数据库表结构（users, email_verification_tokens, revisions）
- API 接口设计（认证、用户管理、内容管理）
- 权限控制逻辑
- 前端实现要点
- 邮箱验证机制
- 安全考虑与实施步骤

### collection-feature.md
集合（收藏夹）功能的设计文档，包括：
- 数据库设计（collections, collection_items 表）
- 后端 API 设计
- 前端交互设计（添加/移除收藏）
- 集合管理页面设计
- 开发计划

### export-system.md
基于 Cloudflare Workers 的异步数据导出系统设计，包括：
- 架构设计（API Worker, Durable Object, R2 Storage）
- 数据模型（ExportJob 结构）
- API 规范（发起导出、查询状态）
- 实现策略（流式处理、分页查询）
- 幂等性与缓存
- UI 集成方式

### ui-translation.md
UI 翻译系统的整合设计文档，包括：
- 用户翻译界面设计
- 本地化翻译同步方案
- 翻译数据管理机制
- 前后端实现细节
- 完成度计算与激活逻辑
- 审核工作流
- 未来增强功能

### i18n-architecture.md
国际化动态语言支持扩展方案，包括：
- 设计目标与方案概述
- 数据模型设计（languages 表，expressions 表扩展）
- 后端 API 设计
- 前端实现方案（动态加载、语言切换、缓存策略）
- 用户贡献流程与质量控制
- 性能优化策略
- 风险与应对措施

### dynamic-languages.md
前端动态语言支持的设计文档，详细说明如何支持多语言切换和动态加载。

## 实施状态

- [x] system-architecture.md - 已实现基础架构
- [ ] user-system.md - 部分实现（待补充邮箱验证）
- [x] collection-feature.md - 已实现
- [ ] export-system.md - 待实现
- [x] ui-translation.md - 基础功能已实现
- [ ] i18n-architecture.md - 部分实现
- [ ] dynamic-languages.md - 待实施

## 相关文档

- [API 文档](../api/)
- [实施指南](../guides/)
- [需求规范](../specs/)
