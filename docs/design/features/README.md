# 功能模块设计

本目录包含 LangMap 系统的各功能模块详细设计文档。所有功能模块文档使用 `feat-` 前缀统一命名。

## 文档列表

- [feat-user-system.md](./feat-user-system.md) - 用户与权限系统设计
- [feat-collection.md](./feat-collection.md) - 集合（收藏夹）功能设计
- [feat-export.md](./feat-export.md) - 异步导出系统设计
- [feat-ui-translation.md](./feat-ui-translation.md) - UI 翻译系统设计
- [feat-i18n.md](./feat-i18n.md) - 国际化动态语言支持方案
- [feat-dynamic-languages.md](./feat-dynamic-languages.md) - 前端动态语言支持
- [feat-search.md](./feat-search.md) - 搜索功能设计
- [feat-heatmap.md](./feat-heatmap.md) - 语言地图/热力图功能设计
- [feat-user-profile.md](./feat-user-profile.md) - 用户资料/个人中心设计
- [feat-database.md](./feat-database.md) - 数据库设计

## 文档说明

### feat-user-system.md
用户管理与权限控制系统的设计文档，包括：

**核心内容**：
- 用户角色定义（超级管理员、管理员、普通用户）
- 数据库表结构
  - `users` - 用户信息（含 `email_verified` 字段）
  - `email_verification_tokens` - 邮箱验证令牌
  - `revisions` - 待审核的内容修改
- API 接口设计（认证、用户管理、内容管理）
- 权限控制逻辑
  - 超级管理员：批量删除、管理用户、分配角色
  - 管理员：单条删除、编辑内容
  - 普通用户：删除自己内容、编辑自己内容、提交他人内容需审核
- 前端实现要点
- 邮箱验证机制
- 安全考虑与实施步骤

**实施状态**：
- [x] 基础用户认证
- [x] 邮箱验证（参见 [../../guides/email-verification.md](../../guides/email-verification.md)）
- [x] 权限控制基础
- [ ] 审核队列完善
- [ ] 两步验证

---

### feat-collection.md
集合（收藏夹）功能的设计文档，包括：

**核心内容**：
- 数据库设计
  - `collections` - 集合基本信息
  - `collection_items` - 集合与词条关联
- 后端 API 设计
  - GET/POST/PUT/DELETE `/api/v1/collections`
  - GET/POST/DELETE `/api/v1/collections/:id/items`
- 前端交互设计
  - 添加/移除收藏交互
  - "我的集合" 页面
  - 集合详情页面
  - 管理界面
- 开发计划

**实施状态**：
- [x] 数据库表结构
- [x] 后端 API 实现
- [x] 前端基础功能
- [ ] 管理界面优化
- [ ] 公开集合分享

---

### feat-export.md
基于 Cloudflare Workers 的异步数据导出系统设计，包括：

**核心内容**：
- 架构设计
  - API Worker - 请求入口
  - Durable Object - 导出引擎（长时任务）
  - Cloudflare R2 - 对象存储
- 数据模型
  - `ExportJob` - 导出任务结构
- API 规范
  - `POST /api/export` - 发起导出
  - `GET /api/export/{jobId}` - 查询状态
- 实现策略
  - 流式传输（分批查询 + ZIP 压缩）
  - 分页处理（避免内存溢出）
  - 幂等性与缓存
  - 检查点与恢复
- UI 集成方式
  - 导出入口（导出按钮）
  - 交互流程（格式选择 → 触发任务 → 轮询状态 → 下载）

**实施状态**：
- [ ] 架构设计
- [ ] Durable Object 实现
- [ ] R2 存储集成
- [ ] API 端点实现
- [ ] 前端 UI 集成

---

### feat-ui-translation.md
UI 翻译系统的整合设计文档，包括：

**核心内容**：
- 用户翻译界面设计
  - 语言选择器
  - 过滤控件（未翻译/已翻译/全部）
  - 翻译表格
  - 提交控件
  - 完成度显示
- 本地化翻译同步方案
  - 问题背景（静态 locales 与数据库脱节）
  - 推荐方案：前端直接读取本地 JSON
  - 可选方案：管理员同步功能
- 翻译数据管理机制
- 前后端实现细节
- 完成度计算与激活逻辑（≥60% 自动激活）
- 审核工作流
- 未来增强功能（协作、机器翻译建议、质量保证）

**实施状态**：
- [x] 翻译界面基础功能
- [x] 后端 API 基础实现
- [x] 完成度计算
- [ ] 自动激活逻辑
- [ ] 管理员同步功能
- [ ] 审核队列完善

---

### feat-i18n.md
国际化动态语言支持扩展方案，包括：

**核心内容**：
- 设计目标与方案概述
  - 支持动态添加新语言
  - 允许用户贡献翻译
  - 支持无标准 BCP-47 代码的小众语言
- 数据模型设计
  - `languages` 表结构
  - `expressions` 表扩展（tags 字段）
- 后端 API 设计
  - `GET /api/v1/languages` - 语言列表
  - `GET /api/v1/expressions?language={lang}&tags=langmap` - UI 翻译
  - `POST /api/v1/languages` - 提交新语言
  - `POST /api/v1/expressions` - 提交翻译
- 前端实现方案
  - 动态加载翻译
  - 语言切换流程
  - 用户自定义语言创建
  - 缓存策略（localStorage/IndexedDB）
- 混合模式实现
  - 核心语言静态配置
  - 动态语言数据库加载
- 用户贡献流程
  - 语言贡献
  - 翻译贡献
  - 质量控制（投票、信誉、举报）
- 性能优化
  - 按需加载
  - 多级缓存
  - 分批加载
- 风险与应对（性能、数据一致性、用户贡献质量）

**实施状态**：
- [x] 基础架构设计
- [x] 数据模型扩展
- [x] 后端 API 部分
- [ ] 动态语言加载
- [ ] 用户自定义语言
- [ ] 性能优化完善

---

### feat-dynamic-languages.md
前端动态语言支持的设计文档，详细说明：

**核心内容**：
- 动态语言加载机制
  - 应用启动时从后端获取翻译
  - 转换为 i18n 所需格式
  - 实现缓存避免重复请求
- 语言切换流程
  - 用户选择新语言
  - 检查本地缓存
  - 无缓存则从后端获取
  - 更新 i18n 实例
  - 保存到本地存储
- 缓存策略
  - 使用 localStorage 或 IndexedDB
  - 实现缓存过期机制（24小时）
  - 提供强制刷新功能

**实施状态**：
- [x] 基础设计
- [ ] 前端实现
- [ ] 浏览器兼容性测试

---

### feat-search.md
搜索功能的设计文档，包括：

**核心内容**：
- 概述
- 数据模型（搜索相关的扩展）
- API 设计
  - `GET /api/v1/search` - 搜索表达式（支持关键词、语言、地域过滤）
- 前端实现
  - Search.vue 页面
  - 搜索输入、语言选择、地域选择
  - 搜索结果列表和分页
- 搜索策略
  - 当前实现（LIKE 模糊匹配）
  - 未来改进（全文检索、拼写纠正、高级过滤）
- 性能优化
  - 当前优化（分页、索引）
  - 未来优化（缓存、搜索服务）
- 用户界面设计
  - 搜索页面布局
  - 分页控件
- 测试策略

**实施状态**：
- ✅ 后端搜索 API 已实现
- ✅ 前端搜索页面已实现
- ✅ 数据库查询支持（LIKE 模糊匹配）
- ⏳ 高级搜索功能（全文检索、拼写纠正）
- ⏳ 搜索结果排序和过滤
- ❌ 搜索历史
- ❌ 搜索建议/自动完成

---

### feat-heatmap.md
语言地图/热力图功能的设计文档，包括：

**核心内容**：
- 概述（首页语言可视化）
- 数据模型
  - HeatmapData 接口
  - 数据来源（languages 表和 expressions 表关联查询）
- API 设计
  - `GET /api/v1/heatmap` - 获取热力图数据
- 缓存机制（10分钟缓存）
- 前端实现
  - Home.vue 地图组件
  - Leaflet + OpenStreetMap 集成
  - 地图标记渲染
  - 统计数据显示
- 可视化策略
  - 当前实现（标记点）
  - 未来改进（热力密度、按语言分层、缩放级别数据粒度）
- 性能优化（缓存、数据聚合）
- 用户交互设计（地图操作、搜索定位）
- 测试策略

**实施状态**：
- ✅ 后端热力图 API 已实现
- ✅ 前端热力图页面已实现
- ✅ 数据模型已定义（HeatmapData 接口）
- ✅ 数据聚合已实现
- ✅ 缓存机制已实现
- ⏳ 地图交互功能（点击事件、缩放）
- ❌ 地域选择器
- ❌ 热力密度可视化

---

### feat-user-profile.md
用户资料/个人中心功能的设计文档，包括：

**核心内容**：
- 概述
- 数据模型
  - User 表（现有）
  - 扩展字段（avatar_url, bio, display_name, website_url, location, language_preference, theme_preference）
- API 设计
  - 已实现：`GET /api/v1/users/me`
  - 未实现：`PUT /api/v1/users/me`（更新资料）、`POST /api/v1/users/avatar`（上传头像）、`GET /api/v1/users/me/stats`（统计信息）、`GET /api/v1/users/me/activity`（活动记录）、`POST /api/v1/users/me/change-password`（修改密码）
- 前端实现
  - UserProfile.vue 页面
  - 头像上传和管理
  - 基本信息编辑
  - 账户设置（语言、主题）
  - 活动记录和统计
- 安全考虑（头像上传、密码修改）
- 用户体验优化（实时预览、表单验证、加载状态）
- 测试策略

**实施状态**：
- ✅ 前端用户资料页面已实现
- ⏳ 后端用户资料 API（`GET /api/v1/users/me` 已实现，其他需实现）
- ⏳ 用户资料更新 API
- ⏳ 头像上传功能
- ❌ 用户统计 API
- ❌ 用户活动记录 API
- ❌ 修改密码功能
- ❌ 用户设置功能

---

### feat-database.md
数据库的设计文档，包括：

**核心内容**：
- 概述
  - Cloudflare D1 数据库选择
  - 数据库特性和优势
- 数据库架构
  - 表关系图
  - 表结构详情（9个表）
    - languages（语言表）
    - expressions（表达式主表）
    - expression_versions（版本历史表）
    - meanings（语义表）
    - expression_meanings（表达式-语义关联表）
    - users（用户表）
    - email_verification_tokens（邮箱验证令牌表）
    - collections（集合表）
    - collection_items（集合项目表）
- 索引设计
  - 索引策略
  - 性能考虑
  - 未来优化
- 数据迁移
  - 迁移策略
  - 迁移示例
  - 未来改进
- 性能优化
  - 查询优化
  - 事务管理
  - 连接池
- 备份策略
  - 当前状态
  - 建议策略
  - 备份命令
- 数据安全
  - 访问控制
  - 数据加密
  - 数据脱敏
- 监控与维护
  - 性能监控
  - 维护任务
  - 未来改进

**实施状态**：
- ✅ Cloudflare D1 数据库已部署
- ✅ 核心表结构已实现
- ✅ 基础索引已创建
- ⏳ 数据库迁移脚本未完善
- ⏳ 数据备份策略未实现
- ❌ 数据库性能监控未实现
- ❌ 读写分离未实现

**已实现的数据库表**：
- ✅ languages - 语言表
- ✅ expressions - 表达式主表
- ✅ expression_versions - 版本历史表
- ✅ meanings - 语义表
- ✅ expression_meanings - 表达式-语义关联表
- ✅ users - 用户表
- ✅ collections - 集合表
- ✅ collection_items - 集合项目表
- ✅ email_verification_tokens - 邮箱验证令牌表

**未实现的功能**：
- 数据库迁移管理工具
- 自动备份机制
- 数据库性能监控
- 读写分离（如需要）
- 分库分表策略

---

## 实施总览

### 已实现 ✅
- 用户系统基础认证
- 集合功能
- UI 翻译基础功能
- 部分国际化支持
- 搜索功能（基础）
- 热力图功能（基础）
- 数据库设计（Cloudflare D1）

### 进行中 🚧
- UI 翻译系统完善
- 邮箱验证集成
- 权限系统完善
- 用户资料功能

### 计划中 📋
- 导出系统（异步）
- 完整的动态语言支持
- 前端动态语言加载
- 高级搜索功能
- 数据库迁移工具
- 数据库备份策略
- 用户资料高级功能

## 命名规范

所有功能模块文档使用统一的 `feat-` 前缀：
- `feat-user-system.md` - 用户系统
- `feat-collection.md` - 集合功能
- `feat-export.md` - 导出功能
- `feat-ui-translation.md` - UI 翻译
- `feat-i18n.md` - 国际化
- `feat-dynamic-languages.md` - 动态语言
- `feat-search.md` - 搜索功能
- `feat-heatmap.md` - 热力图/语言地图
- `feat-user-profile.md` - 用户资料
- `feat-database.md` - 数据库设计

新增功能模块请遵循此命名规范：`feat-{feature-name}.md`

## 相关文档

- [总体系统设计](../system/)
- [API 文档](../../api/)
- [实施指南](../../guides/)
