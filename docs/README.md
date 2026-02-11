# LangMap 文档中心

欢迎来到 LangMap 项目的文档中心。本文档提供所有项目文档的导航和索引。

## 关于项目

**LangMap** 是一个开源、社区驱动的在线语言地图项目，致力于收集世界各地的语言短语和表达方式，展示不同语言之间的差异，并为语言爱好者提供有价值的资源。

- [项目介绍](./ABOUT_US.md)

## 文档结构

```
docs/
├── policies/              # 政策与合规文档
├── design/                # 系统设计与架构文档
├── api/                   # API 接口文档
├── guides/                # 实施与操作指南
├── plans/                 # 计划与路线图
├── specs/                 # 需求与规范文档
└── README.md            # 文档导航索引（本文件）
```

## 文档目录

### 📋 政策与合规 (policies/)
法律政策文档，定义平台的使用规则和数据处理规范。

- **[terms-privacy-content.md](policies/terms-privacy-content.md)** - 服务条款、隐私政策与内容政策（英文版）
- **[terms-privacy-content-zh.md](policies/terms-privacy-content-zh.md)** - 服务条款、隐私政策与内容政策（中文版）

### 🏗️ 系统设计 (design/)
系统架构、数据模型和功能设计的详细技术文档。

- **[system-architecture.md](design/system-architecture.md)** - 系统总体架构设计（技术栈、数据模型、API 设计、MVP 路线）
- **[user-system.md](design/user-system.md)** - 用户与权限系统设计（角色定义、数据库设计、API 接口、安全考虑）
- **[collection-feature.md](design/collection-feature.md)** - 集合（收藏夹）功能设计（数据模型、API 设计、前端交互）
- **[export-system.md](design/export-system.md)** - 异步导出系统设计（基于 Cloudflare Workers 的架构、Durable Objects、R2 Storage）
- **[ui-translation.md](design/ui-translation.md)** - UI 翻译系统设计（用户翻译界面、同步方案、审核工作流）
- **[i18n-architecture.md](design/i18n-architecture.md)** - 国际化动态语言支持方案（数据库模型、API 设计、前端实现）
- **[dynamic-languages.md](design/dynamic-languages.md)** - 前端动态语言支持设计

### 🔌 API 文档 (api/)
后端 API 的技术文档、端点说明和部署指南。

- **[backend-guide.md](api/backend-guide.md)** - 后端部署与配置指南（数据库架构、API 端点、国际化实现）
- **[statistics-api.md](api/statistics-api.md)** - 统计 API 设计（优化查询逻辑、缓存机制）
- **[heatmap-api.md](api/heatmap-api.md)** - 热力图 API 设计（数据聚合、缓存策略）

### 📖 实施指南 (guides/)
开发和部署的操作指南和最佳实践。

- **[corpus-acquisition.md](guides/corpus-acquisition.md)** - 语料获取指南（开源数据源、预处理、地域标注）
- **[email-verification.md](guides/email-verification.md)** - 邮箱验证实施指南（Resend 集成、前后端实现）

### 📋 计划与路线图 (plans/)
项目开发计划、路线图和版本历史。

- **[2026-01-27-ios-app-design.md](plans/2026-01-27-ios-app-design.md)** - iOS 应用设计文档（SwiftUI、MVVM 架构、核心屏幕）

### 📄 需求与规范 (specs/)
项目需求规范、市场调研和可行性分析。

- **[project-spec.md](specs/project-spec.md)** - 项目需求规范（目标、语料来源、页面结构、粗略架构）
- **[market-research.md](specs/market-research.md)** - 市场调研与可行性分析（竞品分析、目标用户、差异化策略）

## 快速导航

### 按主题查找

- **用户系统** → [design/user-system.md](design/user-system.md)
- **认证与安全** → [design/user-system.md](design/user-system.md), [guides/email-verification.md](guides/email-verification.md)
- **国际化** → [design/i18n-architecture.md](design/i18n-architecture.md), [design/ui-translation.md](design/ui-translation.md)
- **数据管理** → [design/system-architecture.md](design/system-architecture.md), [design/collection-feature.md](design/collection-feature.md)
- **API 参考** → [api/README.md](api/README.md)
- **部署指南** → [api/backend-guide.md](api/backend-guide.md), [guides/corpus-acquisition.md](guides/corpus-acquisition.md)
- **产品定位** → [specs/market-research.md](specs/market-research.md)
- **开发计划** → [plans/README.md](plans/README.md)

### 按角色查找

**开发者**
- [系统架构设计](design/system-architecture.md)
- [API 文档](api/)
- [实施指南](guides/)

**产品经理**
- [需求规范](specs/)
- [市场调研](specs/market-research.md)
- [计划与路线图](plans/)

**运维人员**
- [后端部署指南](api/backend-guide.md)
- [系统架构设计](design/system-architecture.md)

**用户**
- [服务条款](policies/terms-privacy-content.md)
- [隐私政策](policies/terms-privacy-content.md)
- [内容政策](policies/terms-privacy-content.md)

## 文档更新

本文档结构于 **2026年2月** 重新组织，将 24 个分散的文档整理为 6 个主要目录，删除了过时的 TODO 文档，合并了重复的设计文档。

### 主要变更

1. **删除过时文档**（7个）
   - todo_user.md
   - todo_user_translation.md
   - ui_translation_refactor.md
   - REGION_MIGRATION_README.md
   - verify_email.md（已重构为 guides/email-verification.md）

2. **合并相关文档**
   - UI 翻译：design_ui_translation.md + user_translate_locales_design.md → design/ui-translation.md
   - 用户系统：design_user.md + todo_user.md 的设计部分 → design/user-system.md

3. **重新组织目录结构**
   - 按功能模块分类：policies/, design/, api/, guides/, plans/, specs/
   - 每个目录添加 README 文档作为导航

4. **重命名文档**（14个）
   - 政策文档移至 policies/ 目录
   - API 文档移至 api/ 目录
   - 实施指南移至 guides/ 目录
   - 规范文档移至 specs/ 目录

## 文档统计

- **总文档数**：23 个（从 24 个整理为 23 个）
  - policies/: 2 个文件
  - design/: 7 个文件
  - api/: 3 个文件
  - guides/: 2 个文件
  - plans/: 1 个文件
  - specs/: 2 个文件
  - 根目录: 1 个文件
  - README 文件: 7 个

## 贡献指南

### 文档规范

- 使用 Markdown 格式
- 标题层级清晰（最多 3 级）
- 代码块标注语言
- 表格用于结构化数据
- 使用 Mermaid 图表展示流程

### 更新文档

1. 在对应的目录下创建或更新文档
2. 更新目录的 README.md 以反映变更
3. 提交代码时在 commit message 中说明文档更新

### 新增功能文档

对于新增的功能，应创建对应的设计文档：

1. 在 `design/` 目录创建功能设计文档
2. 更新 `design/README.md` 添加新文档链接
3. 如有 API 变更，更新 `api/` 目录相关文档
4. 如需要实施指南，在 `guides/` 目录创建指南

## 联系方式

如有文档相关疑问或建议，请通过项目提供的联系方式与我们联系。

---

*本文档最后更新：2026年2月11日*
