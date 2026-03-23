# 功能模块设计导航

本目录包含 LangMap 系统各功能模块的详细设计文档。

## 文档列表

### 核心功能模块

- **[feat-meaning-mapping.md](./feat-meaning-mapping.md)** - 词句与语义多对多关系
  - meanings 和 expression_meaning 表设计
  - 数据迁移方案
  - API 接口设计
  - 前端实现方案
  - 实施状态：设计完成，待实现

- **[feat-expression-group-abstraction.md](./feat-expression-group-abstraction.md)** - Expression Group 抽象层设计
  - ExpressionGroup 概念定义
  - 隐藏 meanings 和 expression_meaning 表实现细节
  - ExpressionGroup 查询接口（expression_group.ts）
  - API 参数从 meaning_id 改为 group_id
  - 实施状态：设计完成，待实现

- **[feat-expression-group-modal.md](./feat-expression-group-modal.md)** - Handbook 词句组快捷弹窗
  - 词句组详情弹窗设计
  - 表格展示所有翻译
  - 快捷添加新翻译功能
  - 组件与 API 集成

### 用户与权限

- **[feat-user-system.md](./feat-user-system.md)** - 用户与权限系统
  - 用户角色定义
  - 数据库表结构
  - API 接口设计
  - 权限控制逻辑
  - 邮箱验证机制

- **[feat-user-profile.md](./feat-user-profile.md)** - 用户资料功能

### 词句与翻译

- **[feat-database.md](./feat-database.md)** - 数据库设计
  - 核心数据表结构
  - 表关系设计
  - 索引设计

- **[feat-batch-meaning-submission.md](./feat-batch-meaning-submission.md)** - 批量语义提交
- **[feat-merge-meaning-groups.md](./feat-merge-meaning-groups.md)** - 合并词句组
- **[feat-search.md](./feat-search.md)** - 搜索功能
- **[feat-smart-search-associate.md](./feat-smart-search-associate.md)** - 智能搜索关联

### 语言与国际化

- **[feat-language-detail.md](./feat-language-detail.md)** - 语言详情页面
  - 语言展示卡片
  - 区域数据可视化
  - 热力图展示

- **[feat-dynamic-languages.md](./feat-dynamic-languages.md)** - 动态语言支持
  - 动态加载机制
  - 语言切换流程
  - 缓存策略

- **[feat-i18n.md](./feat-i18n.md)** - 国际化系统
  - 数据模型设计
  - 后端 API 设计
  - 前端实现方案
  - 用户贡献流程

- **[feat-ui-translation.md](./feat-ui-translation.md)** - UI 翻译系统
  - 用户翻译界面设计
  - 本地化翻译同步方案
  - 完成度计算与激活逻辑
  - 审核工作流

### 内容管理

- **[feat-handbook.md](./feat-handbook.md)** - Handbook 笔记本功能
  - 数据库设计
  - 笔记本管理
  - 笔记内容编辑

- **[feat-handbook-toc.md](./feat-handbook-toc.md)** - Handbook 目录功能
  - 目录结构设计
  - 目录生成逻辑

### 收藏与导出

- **[feat-collection.md](./feat-collection.md)** - 集合（收藏夹）功能
  - 数据库设计
  - 后端 API 设计
  - 前端交互设计
  - 集合管理页面

- **[feat-export.md](./feat-export.md)** - 异步导出系统
  - Cloudflare Workers 架构
  - Durable Object 实现
  - R2 存储集成
  - 流式处理策略

### 数据可视化

- **[feat-heatmap.md](./feat-heatmap.md)** - 热力图功能
  - 数据聚合
  - 地图可视化

### 媒体处理

- **[feat-audio-upload.md](./feat-audio-upload.md)** - 音频上传功能
- **[feat-image-expression.md](./feat-image-expression.md)** - 图片词句功能
  - 图片上传与压缩
  - R2 直传架构
  - language_code='image' 标识
  - 前端动态输入方式切换

## 命名规范

- **功能模块文档**：使用 `feat-` 前缀（如 `feat-user-system.md`）
- **文档组织**：按功能类别分组
- **更新日期**：每次更新文档时在顶部标记实现状态

## 新增功能文档流程

1. 在 `design/features/` 目录创建 `feat-{feature-name}.md`
2. 参考现有功能文档的结构和格式
3. 更新本 `README.md` 添加新文档链接
4. 更新 `../README.md` 添加简要说明

## 实施状态说明

- ✅ 设计文档已完成
- ⏳ 等待实现
- 🔄 实现中
- ✅ 已实现

## 相关文档

- [总体系统设计](../system/)
- [API 文档](../../api/)
- [实施指南](../../guides/)
- [需求规范](../../specs/)
- [计划路线图](../../plans/)
