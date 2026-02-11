# 设计细化：系统架构、数据模型与产品流程

## 概览
基于 `docs/spec.md` 要求，本设计把重点放在可实现的 MVP 上，同时保留可扩展性（例如大规模检索、地域细化与音频托管）。前端采用 `Vue 3`，后端采用 `Python 3.12`（推荐使用 `FastAPI` 以便快速构建异步 API 与自动文档）。

## 技术栈建议（精简优先）
为了尽可能降低初期成本与维护复杂度，建议将初始技术栈限制为最少必要组件，后续按需逐步扩展。

最小可行栈（MVP — 低成本、易维护）：
- 前端：`Vue 3` + `Vite`（轻量且开发体验好）。地图使用 `Leaflet` + OpenStreetMap 瓦片（免费、无需 Mapbox 付费）。`vue-i18n` 可在需要时逐步加入。
- 后端：`FastAPI` + `uvicorn`（保留异步能力但部署与开发简单）。
- 数据库：`PostgreSQL`（单实例），初期**不必**使用 `PostGIS`：以结构化的地域字段（country/province/city）存储地域信息，等到需要做地理空间查询时再引入 PostGIS 并迁移数据。
- 搜索：先使用 `PostgreSQL` 的全文检索（`tsvector`/GIN 索引）满足基本检索与模糊查询需求；仅在查询量或功能需求上升时再引入 `Typesense` 或 `Elasticsearch`。
- 存储：开发与小规模阶段可直接在服务器文件系统保存音频并用 Nginx 提供静态托管；若要扩展再迁移到 S3 兼容存储。
- 后台任务：先用 FastAPI 的 `BackgroundTasks` 或一个非常简单的 worker（Python 脚本 + cron/systemd）替代 Celery，避免 Redis/消息队列的早期运维成本。
- 缓存：暂不引入 Redis；必要时只在查询热点或速率限制时再增加。
- AI：使用第三方 AI API（如 OpenAI）按需调用，避免自建 LLM 基础设施。对接时注意配额与成本控制（请求池、速率限制、成本监控）。
- 部署：单台 VM（或轻量 VPS）+ Docker + GitHub Actions 自动化部署；Kubernetes 可留作后续扩展选项。

可选扩展（当规模或功能需求增长时引入）：
- 引入 `PostGIS` 用于精确地理映射与点到行政区查询。
- 使用 `Typesense` / `Elasticsearch` 提升检索表现与高级搜索功能。
- 引入 `Redis` + `Celery`（或 RQ）构建可靠的异步任务队列与缓存层。
- 迁移音频到 S3 或第三方对象存储以降低磁盘管理负担并便于横向扩展。

权衡说明：此方案以降低运维与成本为主，在初期牺牲部分高级功能（例如实时地理空间查询、高并发检索），但能快速交付可用的 MVP 并在获取用户反馈后有明确的升级路径。

## 数据模型草案（核心表）
- `languages`：id, name, iso_code, parent_lang_id（若需方言层级）、metadata
- `regions`：id, name, country_code, admin_level (国家/省/市/乡镇), geom (PostGIS)，parent_region_id
- `expressions`：id, language_id, region_id, text, normalized_text, source_type (`authoritative`/`ai`/`user`), source_ref (书名/媒体/链接), audio_url, pronunciation_meta, context, created_by, created_at, review_status (`pending`/`approved`/`rejected`), trust_score
- `users`：id, username, role (`user`/`moderator`/`admin`), reputation
- `votes`：id, expression_id, user_id, vote_type (`up`/`down`), created_at
- `meanings`：id, gloss, description, created_by, created_at
- `expression_meanings`：id, expression_id, meaning_id, created_by, created_at, note, parent_version_id
- `audit_logs`：记录 AI 补全来源、审核决策与溯源信息

备注：地域层级仅保留到乡镇（admin_level 最小），`regions` 可通过外部地理数据（如 GADM、OpenStreetMap）导入并裁剪。

## API 设计（示例端点）
- `GET /api/v1/search?q=...&from_lang=zh&to_lang=all&region=...`：检索表达，按来源/可信度排序。
- `GET /api/v1/expressions/{id}`：获取单条表达详情（含音频、来源、审查记录）。
- `POST /api/v1/expressions`：用户提交表达（进入 `pending` 状态），携带地区选择。
 - `POST /api/v1/ai/suggest`：对未命中查询请求 AI 补全（返回 `ai` 标识的候选）。AI 生成的候选在通过自动安全/质量检测后可**自动写入** `expressions` 并标记为 `source_type=ai`、`review_status=approved`（无需人工审核）；用户提交的改动仍进入人工审核流程。
- `POST /api/v1/expressions/{id}/vote`：用户投票（赞/踩）。
- `GET /api/v1/map?q=...&lang=...`：返回适合地图渲染的聚合结果（每个 region 的代表表达、数量、热度值）。
- `GET /api/v1/regions?near=lat,lng&max_level=town`：用于地域选择器，默认基于用户位置。

## 前端页面与交互流程
1. **首页**：创造性可视化（例如：按语言丰富度的散点+地图融合、示例卡片、热门查询云）。
2. **查询词条页面**：
   - 输入查询 + 选择语言与地域（默认用户当前位置）。
   - 若命中语料库：展示按地区分组的表达，跳转到语言地图或条目详情。
   - 若未命中：展示 `AI 补全` 按钮（标识 AI），以及 `用户提交` 模块供填写并提交审核。
   - 每条表达显示来源标签、音频播放控件、赞/踩、审查状态。
3. **语言地图页面**：
   - 地图展示该词在各地域的表达（可点击气泡查看详情）。
   - 支持按来源筛选（仅权威/含 AI/仅用户）。

## 地域选择器实现建议
- 使用地图拾取或基于位置的选择（浏览器地理定位或 IP 回退）。
- 采用分层选择（国家 -> 省/市 -> 区/乡镇），UI 限制到乡镇级别。后台用 PostGIS 做点到行政区域的映射。

## 审核与信任机制
- 流程（用户提交）：用户提交 → AI 自动初筛（内容安全、明显错误检测）→ 人工审核队列（由 `moderator` 处理），通过审核后更新为 `approved`。

- AI 生成内容的流程：AI 补全/生成的内容应首先通过自动化的内容安全与质量检测（检测不当内容、明显低质量或个人信息泄露等）。通过自动检测的 AI 生成条目将**自动标记为 `source_type=ai` 且 `review_status=approved`**，无需人工审核；但所有 AI 内容在界面上必须明显标注为 `AI`，并保留社区举报/投票与管理员回滚或删除的能力，以便后续人工干预。

- 投票机制：用户的赞/踩影响 `trust_score`；高信誉用户的投票权重更高。对 AI 内容，社区投票与报告可触发管理员复核或自动降级（将 `review_status` 置为 `pending` 或移除）。

- 溯源显示：条目必须显示 `source_type` + `source_ref` + `审核状态` + `auto_approved`（若为 AI 自动通过则标记为 true）。

## 音频与朗读策略
- 优先托管可授权的录音或社区上传音频（存 S3）。
- 提供外部朗读跳转（例如调用浏览器 TTS / 链接到 Forvo / 第三方服务），并在 UI 中标注来源。

## 可扩展性与性能考虑
- 大量查询时使用搜索服务（Typesense/Elasticsearch）做模糊匹配、拼写纠正与多语言分词。
- 地图可视化的数据应做服务端聚合，避免传输过多点数据；前端根据缩放级别请求不同粒度数据。

## 隐私与合规
- 明确用户协议与数据使用条款，标注 AI 补全如何生成与存储。
- 对用户上传的敏感个人信息做脱敏或禁止上传声明。

## MVP 路线（建议 3 个月迭代示例）
- 第 0 周：准备基础 infra（Postgres+PostGIS、Typesense、S3）、脚手架项目。
- 第 1-3 周：实现后端基础模型、API 和简单的前端搜索页 + 地图原型（局部数据）。
- 第 4-6 周：加入 AI 补全流程（异步）、用户提交与审核队列、音频上传/播放。
- 第 7-12 周：优化地图可视化、地域选择器、权限与信誉系统、可行的文档和测试，准备数据导入批次。

## 下一步建议（可选实现）
- 我可以为你：
  - 初始化 `FastAPI` 后端模版并生成 `expressions` / `regions` 数据模型。
  - 生成 OpenAPI 形式的 API 规范（初版）。
  - 搭建前端 `Vue 3` 项目骨架并实现搜索页面原型。

## 编辑与版本历史（修订控制）

根据实际实现，`expressions` 表达式系统已实现版本历史功能，但与最初设计存在若干关键差异。以下是基于代码库真实状态的更新设计文档：

### 数据模型实现

- `Expression`（主表）：存储当前活动的表达式版本。**注意**：实际实现中**没有** `current_version_id` 字段，当前版本的数据直接存储在 `Expression` 表中，而所有历史快照（包括当前版本）均记录在 `ExpressionVersion` 表中。
- `ExpressionVersion`（版本表）：采用追加写（append-only）模式记录每次变更。字段包括：`id`, `expression_id`, `language`, `region`, `text`, `source_type`, `created_by`, `created_at`, `review_status`, `auto_approved`。**注意**：`parent_version_id` 字段未在此表中实现。
- `Meaning`（语义表）：存储表达式的语义信息，包括简短的词汇解释（gloss）和详细描述（description）。
- `ExpressionMeaning`（表达式-语义关联表）：实现表达式与语义之间的多对多关系。包含关联创建者、创建时间和备注信息。**注意**：意外地包含了 `parent_version_id` 字段，这可能是一个设计偏差或未来扩展点，但当前版本系统未使用此字段进行版本链追踪。

### 版本策略与工作流

- **版本创建**：每当创建或更新一个表达式时，系统会同时更新 `Expression` 主记录并创建一条新的 `ExpressionVersion` 记录，形成完整的变更历史。
- **审核状态**：版本的 `review_status` 和 `auto_approved` 标志在创建时确定。AI 生成的内容通过 `/ai/suggest` 端点创建，并自动设置 `auto_approved=True` 和 `review_status="approved"`，无需人工审核。
- **版本存储**：严格遵循追加写原则，历史版本不可变，确保了完整的数据可追溯性。
- **无显式回滚机制**：当前实现未提供 API 端点来将某个历史版本恢复为当前版本。这需要后续开发支持。

### API 端点实现

- `GET /api/v1/expressions/{expr_id}/versions`：**已实现**。分页返回指定表达式的所有版本，按创建时间倒序排列。这是前端 `VersionHistory.vue` 组件的数据来源。
- `GET /api/v1/expressions/{expr_id}/versions/{vid}`：**未实现**。无法通过 API 获取单个特定版本的详细信息。
- `PATCH /api/v1/expressions/{id}`：**未实现**。当前 API 使用 `POST` 方法创建新表达式，但没有专门的 `PATCH` 端点来处理编辑和版本创建。
- `POST /api/v1/expressions/{id}/versions/{vid}/revert`：**未实现**。缺少版本回滚功能。
- `GET /api/v1/expressions/{id}/diff?from=vid1&to=vid2`：**未实现**。没有提供版本间差异比较的 API。

### 前端实现

- `VersionHistory.vue` 组件：在 `Detail.vue` 页面中渲染，通过调用 `/api/v1/expressions/{id}/versions` 获取数据，并以列表形式展示每个版本的文本、创建时间和审核状态。
- **变更摘要缺失**：前端和后端均未实现 `change_summary` 功能，无法记录每次修改的具体原因。
- **无差异预览**：由于缺少 diff API，前端无法展示版本间的具体文字差异。

### 关键差异总结

| 设计预期 | 实际实现 |
| :--- | :--- |
| `Expression` 表包含 `current_version_id` 外键 | `Expression` 表直接存储当前数据，`expression_id` 在 `ExpressionVersion` 中关联 | 
| `ExpressionVersion` 包含 `parent_version_id` | `parent_version_id` 字段不存在于 `ExpressionVersion` 表中 |
| 支持版本回滚和 diff 比较 | 相关 API 端点和功能尚未实现 |
| 用户编辑需审核后才成为当前版本 | 当前实现中，任何编辑都会立即成为当前版本，审核状态 (`review_status`) 是版本属性而非决定是否生效的开关 |

### 后续改进建议

1. **实现版本回滚**：添加 `POST /api/v1/expressions/{id}/versions/{vid}/revert` 端点，允许将历史版本恢复为当前状态。
2. **增加变更摘要**：在 `ExpressionVersion` 模型中添加 `change_summary` 字段，并在 API 中接收该参数，以提高版本历史的可读性。
3. **开发 Diff API**：实现一个端点来计算并返回两个版本之间的文本差异。
4. **完善版本关系**：如果需要构建版本树（如分支编辑），应将 `parent_version_id` 移至 `ExpressionVersion` 表并正确维护。

## 添加新含义功能设计（新增）

### 当前实现分析

目前在"Add New Expression"页面中已有"Associate with Existing Meaning"功能，允许用户：
1. 搜索现有表达式
2. 选择一个表达式
3. 从该表达式关联的含义中选择一个，或者创建一个新的含义
4. 将新建的表达式与选定的含义关联

### 功能增强建议

为了更好地支持用户在创建表达式时添加新含义，建议进行以下改进：

#### 方案一：提供明确的选择选项（已实现）

在现有功能基础上，为用户提供明确的选项来选择关联类型：
1. **Associate with Existing Meaning** - 关联到现有含义
2. **Associate with New Meaning** - 关联到新含义

具体实现细节：
- 在界面中提供两个清晰的选项按钮，让用户选择关联类型
- 如果选择"Associate with Existing Meaning"，则显示当前的搜索和选择流程
- 如果选择"Associate with New Meaning"，则直接显示新含义创建表单
- 两种情况下，都将在表达式创建完成后进行含义关联

#### 方案二：扩展现有关联功能

在现有"Associate with Existing Meaning"功能基础上进行增强：
1. 保留在创建表达式时关联现有含义的能力
2. 增强UI，允许用户直接创建全新的含义（不需要先关联一个表达式）
3. 简化流程，让用户可以在同一界面完成表达式创建和新含义定义

#### 方案三：独立的新含义创建功能

添加一个完全独立的"Create New Meaning"功能：
1. 在UI上与"Associate with Existing Meaning"并列
2. 允许用户直接创建不关联任何表达式的独立含义
3. 可以在后续步骤中将表达式与该含义关联

#### 实现状态

方案一已经实现，具有以下特点：
1. **清晰的用户选择**：用户可以明确知道自己是要创建新含义还是关联现有含义
2. **直观的操作流程**：不同的关联类型有不同的界面展示，避免混淆
3. **符合当前系统设计**：含义主要是作为表达式之间的语义桥梁存在
4. **更好的用户体验**：提供清晰的选择路径，减少用户思考时间

### API 端点增强

当前API已经支持所需功能：
- `POST /api/v1/meanings` 可用于创建新含义
- `POST /api/v1/meanings/{mid}/link?expression_id={eid}` 可用于关联表达式和含义
- `GET /api/v1/search` 可用于搜索现有表达式及其含义

在创建表达式页面，流程将是：
1. 用户填写表达式信息并选择关联类型
2. 系统创建表达式（`POST /api/v1/expressions`）
3. 根据用户选择执行相应操作：
   - 如果选择了"Associate with Existing Meaning"：
     * 用户从现有含义中选择一个
     * 系统将表达式与选定含义关联（`POST /api/v1/meanings/{mid}/link?expression_id={eid}`）
   - 如果选择了"Associate with New Meaning"：
     * 系统创建新含义（`POST /api/v1/meanings`）
     * 系统将表达式与新含义关联（`POST /api/v1/meanings/{mid}/link?expression_id={eid}`）

### 前端实现

在`CreateExpression.vue`组件中已经实现：
1. 添加了一个新的状态变量[associationType](file:///Users/share.lim/Documents/code/lshare/langmap/web/src/pages/CreateExpression.vue#L585-L585)来跟踪用户选择的关联类型
2. 在UI中添加选项按钮，让用户选择关联类型
3. 根据用户选择显示相应的界面元素
4. 在提交函数中根据用户选择执行不同的逻辑

这种实现充分利用了现有代码基础，只需要添加选择逻辑和调整UI展示即可实现功能增强。