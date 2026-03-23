# LangMap 文档中心

欢迎来到 LangMap 项目的文档中心。本文档提供所有项目文档的导航和索引。

## 关于项目

**LangMap** 是一个开源、社区驱动的在线语言地图项目，致力于收集世界各地的语言短语和表达方式，展示不同语言之间的差异，并为语言爱好者提供有价值的资源。

## 文档结构

```
docs/
├── policies/              # 政策与合规文档
├── design/                # 系统设计与架构文档
│   ├── system/            # 总体系统架构
│   └── features/          # 功能模块设计（使用 feat- 前缀）
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

**总体架构 (system/)**
- **[architecture.md](design/system/architecture.md)** - 系统总体架构设计（技术栈、数据模型、API 设计、已实现和未实现状态）

**功能模块设计 (features/)**
各功能模块的详细设计文档（统一使用 `feat-` 前缀），已标注实际实现状态。

- **[feat-user-system.md](design/features/feat-user-system.md)** - 用户与权限系统（角色定义、数据库设计、API 接口、安全考虑、实现状态标注）
- **[feat-collection.md](design/features/feat-collection.md)** - 集合（收藏夹）功能（数据模型、API 设计、前端交互、实现状态标注）
- **[feat-handbook.md](design/features/feat-handbook.md)** - 学习手册功能（Markdown编辑、动态语言词句拉取、数据库与API设计、实现状态标注）
- **[feat-export.md](design/features/feat-export.md)** - 异步导出系统（架构设计、数据模型、API 规范、实现状态标注）
- **[feat-ui-translation.md](design/features/feat-ui-translation.md)** - UI 翻译系统（用户翻译界面、同步方案、审核工作流、实现状态标注）
- **[feat-i18n.md](design/features/feat-i18n.md)** - 国际化动态语言支持（数据库模型、API 设计、前端实现方案、实现状态标注）
- **[feat-dynamic-languages.md](design/features/feat-dynamic-languages.md)** - 前端动态语言支持（动态加载机制、语言切换流程、实现状态标注）
- **[feat-search.md](design/features/feat-search.md)** - 搜索功能设计（API 设计、前端实现、搜索策略、实现状态标注）
- **[feat-heatmap.md](design/features/feat-heatmap.md)** - 语言地图/热力图功能设计（数据模型、API 设计、可视化方案、实现状态标注）
- **[feat-user-profile.md](design/features/feat-user-profile.md)** - 用户资料/个人中心设计（数据模型、API 设计、前端实现、实现状态标注）
- **[feat-database.md](design/features/feat-database.md)** - 数据库设计（表结构、索引、迁移策略、性能优化、备份策略、实现状态标注）
- **[feat-audio-upload.md](design/features/feat-audio-upload.md)** - 词条录音与上传功能（前端直传 R2、预签名设计、低成本架构、实现状态标注）
- **[feat-image-expression.md](design/features/feat-image-expression.md)** - 图片词句功能（图片上传与压缩、R2 直传架构、language_code='image' 标识、前端动态输入方式切换、实现状态标注）

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
项目需求规范、业务分析与技术规格。

- **[BRD.md](specs/BRD.md)** - 业务需求文档（愿景、目标、市场分析）
- **[PRD.md](specs/PRD.md)** - 产品需求文档（功能描述、用户流程）
- **[SRS.md](specs/SRS.md)** - 系统需求规格说明（技术栈、系统架构、接口规范）

## 快速导航

### 按主题查找

- **项目愿景与背景** → [specs/BRD.md](specs/BRD.md)
- **产品核心功能** → [specs/PRD.md](specs/PRD.md)
- **系统架构与技术栈** → [specs/SRS.md](specs/SRS.md), [design/system/architecture.md](design/system/architecture.md)
- **用户系统** → [design/features/feat-user-system.md](design/features/feat-user-system.md)
- **认证与安全** → [design/features/feat-user-system.md](design/features/feat-user-system.md), [guides/email-verification.md](guides/email-verification.md)
- **国际化** → [design/features/feat-i18n.md](design/features/feat-i18n.md), [design/features/feat-ui-translation.md](design/features/feat-ui-translation.md)
- **数据管理** → [design/system/architecture.md](design/system/architecture.md), [design/features/feat-collection.md](design/features/feat-collection.md)
- **数据库设计** → [design/features/feat-database.md](design/features/feat-database.md)
- **搜索功能** → [design/features/feat-search.md](design/features/feat-search.md)
- **语言地图** → [design/features/feat-heatmap.md](design/features/feat-heatmap.md)
- **用户资料** → [design/features/feat-user-profile.md](design/features/feat-user-profile.md)
- **API 参考** → [api/README.md](api/README.md)
- **部署指南** → [api/backend-guide.md](api/backend-guide.md), [guides/corpus-acquisition.md](guides/corpus-acquisition.md)
- **开发计划** → [plans/2026-01-27-ios-app-design.md](plans/2026-01-27-ios-app-design.md)

### 按角色查找

**开发者**
- [系统需求规格 (SRS)](specs/SRS.md)
- [总体架构设计](design/system/architecture.md)
- [功能模块设计](design/features/)
- [API 文档](api/)

**产品经理**
- [业务需求 (BRD)](specs/BRD.md)
- [产品需求 (PRD)](specs/PRD.md)
- [计划与路线图](plans/)

**运维人员**
- [后端部署指南](api/backend-guide.md)
- [系统架构设计](design/system/architecture.md)

**用户**
- [关于项目](specs/ABOUT_US.md)
- [服务条款](policies/terms-privacy-content.md)
- [隐私政策](policies/terms-privacy-content-zh.md)

## 文档规范

### 命名规范

- **总体架构文档**：使用简洁的名称（如 `architecture.md`）
- **功能模块文档**：使用 `feat-` 前缀（如 `feat-user-system.md`）
- 标注要求：所有功能模块文档必须包含 system-reminder 章节

### 更新文档

1. 在对应的目录下创建或更新文档
2. 更新 README.md 以反映变更
3. 提交代码时在 commit message 中说明文档更新

### 新增功能文档

对于新增的功能，应创建对应的设计文档：

1. 在 `design/features/` 目录创建 `feat-{feature-name}.md`
2. 参考现有功能文档的结构和格式
3. 必须包含 system-reminder 章节，标注实现状态
4. 更新 `design/features/README.md` 添加新文档链接
5. 如有 API 变更，更新 `api/` 目录相关文档

---

*本文档最后更新：2026年2月11日*
