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

为了保证可追溯性与数据质量，`expressions` 必须支持可编辑的版本历史。下面是推荐的设计要点与 API：

数据模型扩展：
- `expressions`（主表）：保持当前最新通过审核的版本引用 `current_version_id`（nullable，当被删除时置空）。
- `expression_versions`（版本表）：id, expression_id, language_id, region_id, text, normalized_text, source_type, source_ref, audio_url, context, created_by, created_at, review_status, change_summary, parent_version_id
- `version_votes`：对某个版本的赞/踩（用于信任评分）。
- `audit_logs`：记录谁在何时做了什么修改（包括 AI 自动生成的写入）。

 版本策略：
 - 用户编辑：每次用户编辑都会创建一个新的 `expression_versions` 行；只有通过人工审核并达到信任阈值后，`expressions.current_version_id` 才会被更新为该版本。
 - AI 生成的版本：AI 自动生成且通过自动检测的版本也会创建 `expression_versions` 行，但可以被设计为**自动成为当前版本**（即立即更新 `expressions.current_version_id` 指向该 AI 版本），并在元数据中记录 `auto_approved=true` 与 `source_type=ai`，以便溯源与界面展示。
 - 保持历史版本不可变（append-only），并允许管理员或有权限的用户回滚到任意历史版本（在 `expressions` 表中把 `current_version_id` 指向所选版本并写入审计日志）。
 - 支持草稿模式：用户在前端提交修改时先生成 `pending` 版本，不会立即替换当前版本，除非是高信誉用户或经过审核。

并发与冲突处理：
- 使用乐观锁或在前端显示“基于版本 X 编辑”的元信息；提交时若当前最新版本已变更，提示用户合并或重新编辑。

API 示例：
- `GET /api/v1/expressions/{id}/versions`：列出该表达的版本历史（分页），返回每个版本的元数据（id, created_by, created_at, review_status, change_summary）。
- `GET /api/v1/expressions/{id}/versions/{vid}`：获取指定版本的完整内容。
- `PATCH /api/v1/expressions/{id}`：提交编辑（作为新版本创建），请求体可包含 `change_summary`，返回新版本 id 和审核状态。
- `POST /api/v1/expressions/{id}/versions/{vid}/revert`：管理员/有权限用户将当前版本回滚到 `vid`（生成一次新的版本记录，说明为回滚操作）。
- `GET /api/v1/expressions/{id}/diff?from=vid1&to=vid2`：返回两个版本之间的差异摘要（可选，供 UI 显示）。

前端交互建议：
- 在条目详情页展示“版本历史”按钮，弹窗或侧栏列出历史版本与差异预览，并允许投票、评论或提交争议。
- 在编辑界面显示当前基准版本号与变更摘要框，鼓励贡献者填写 `change_summary`（例如“修正拼写/改进例句/补充音频”）。
 - 对于 AI 补全生成的版本，UI 必须明显标注为 `AI`；AI 生成的版本不强制进入人工审核流程，但应当经过自动检测并允许社区投票/报告与管理员回滚或删除。

权限与审核：
- 普通注册用户可以提交并创建 `pending` 版本；高信誉用户或 `moderator` 可以直接标记为 `approved`（或在通过审核后自动提升）。
- 所有版本修改都写入 `audit_logs`，并可导出以满足学术或合规要求。

隐私与合规延伸：
- 在版本历史中对用户信息做最小化展示（例如匿名化用户 ID），并提供用户删除其个人数据的流程（删除请求仅影响可标识数据，不删除学术审计所需的元数据）。

实现要点总结：
- 采用 append-only 的版本存储保证可追溯；
- 明确审核流（pending -> approved -> current）；
- 前端展示清晰的出处与变更摘要；
- 提供回滚、diff 与导出功能以支持研究需求。
