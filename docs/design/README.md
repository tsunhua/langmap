# 设计文档

本目录包含 LangMap 系统的总体架构设计和功能模块设计文档。

## 目录结构

```
design/
├── system/                    # 总体系统架构设计
│   ├── architecture.md         # 系统总体架构设计
│   └── README.md             # 系统设计导航
├── features/                   # 功能模块设计（所有使用 feat- 前缀）
│   ├── feat-user-system.md       # 用户与权限系统
│   ├── feat-collection.md        # 集合功能
│   ├── feat-export.md           # 导出系统
│   ├── feat-ui-translation.md    # UI 翻译
│   ├── feat-i18n.md            # 国际化
│   ├── feat-dynamic-languages.md # 动态语言
│   └── README.md              # 功能模块导航
└── README.md                  # 本文档
```

## 文档分类

### 📗 总体系统设计 (system/)
系统整体架构设计文档。

- **[architecture.md](system/architecture.md)** - 系统总体架构设计
  - 技术栈建议
  - 数据模型草案
  - API 设计示例
  - 前端页面与交互流程
  - 审核与信任机制
  - 版本历史实现状态
  - MVP 路线图

### ⚙️ 功能模块设计 (features/)
各功能模块的详细设计文档（统一使用 `feat-` 前缀）。

- **[feat-user-system.md](features/feat-user-system.md)** - 用户与权限系统
  - 用户角色定义
  - 数据库表结构
  - API 接口设计
  - 权限控制逻辑
  - 邮箱验证机制

- **[feat-collection.md](features/feat-collection.md)** - 集合（收藏夹）功能
  - 数据库设计
  - 后端 API 设计
  - 前端交互设计
  - 集合管理页面

- **[feat-export.md](features/feat-export.md)** - 异步导出系统
  - Cloudflare Workers 架构
  - Durable Object 实现
  - R2 存储集成
  - 流式处理策略

- **[feat-ui-translation.md](features/feat-ui-translation.md)** - UI 翻译系统
  - 用户翻译界面设计
  - 本地化翻译同步方案
  - 完成度计算与激活逻辑
  - 审核工作流

- **[feat-i18n.md](features/feat-i18n.md)** - 国际化动态语言支持
  - 数据模型设计
  - 后端 API 设计
  - 前端实现方案
  - 用户贡献流程
  - 性能优化策略

 - **[feat-dynamic-languages.md](features/feat-dynamic-languages.md)** - 前端动态语言支持
   - 动态加载机制
   - 语言切换流程
   - 缓存策略
 - **[feat-meaning-mapping.md](features/feat-meaning-mapping.md)** - 词句与语义多对多关系
   - 数据模型设计（meanings、expression_meaning 表）
   - 数据迁移方案
   - API 接口设计
   - 前端交互实现

## 实施状态

### 总体架构 (system/)
- [x] 基础架构设计
- [x] 核心数据模型
- [x] 基础 API 设计
- [ ] 版本回滚功能
- [ ] 版本比较功能
- [ ] 变更摘要功能

### 功能模块 (features/)
- [x] feat-user-system - 基础实现
- [x] feat-collection - 已实现
- [ ] feat-export - 待实现
- [x] feat-ui-translation - 基础实现
- [ ] feat-i18n - 部分实现
- [ ] feat-dynamic-languages - 待实施
- [ ] feat-meaning-mapping - 设计完成，待实现

## 文档规范

### 命名规范

- **总体设计文档**：使用简洁的名称（如 `architecture.md`）
- **功能模块文档**：使用 `feat-` 前缀（如 `feat-user-system.md`）
- **README 文档**：用于各子目录的导航和说明

### 新增功能文档

当需要新增功能模块时：

1. 在 `design/features/` 目录创建 `feat-{feature-name}.md`
2. 参考现有功能文档的结构和格式
3. 更新 `design/features/README.md` 添加新文档链接
4. 更新 `design/README.md` 添加简要说明

### 文档结构建议

功能模块文档应包含以下章节：

```markdown
# 功能名称设计

## 概述
简述功能的用途和目标

## 数据模型
相关数据库表结构

## API 设计
涉及的 API 端点

## 前端实现
Vue 组件和交互逻辑

## 实施状态
当前的完成度

## 相关文档
其他相关的设计文档链接
```

## 相关文档

- [API 文档](../api/)
- [实施指南](../guides/)
- [需求规范](../specs/)
- [计划路线图](../plans/)
