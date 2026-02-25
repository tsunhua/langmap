# Handbook (学习手册) 功能设计

## System Reminder

**设计来源**：根据用户需求（基于 Markdown 编辑并支持动态切换语言渲染相关词句的手册）设计。

**实现状态**：
- ⏳ 数据库模型（handbooks 表） - 未实现
- ⏳ 后端 API 基础实现 - 未实现
- ⏳ 前端 Markdown 编辑器与渲染 - 未实现
- ⏳ Markdown 中动态拉取词句逻辑 - 未实现

---

## 概述

Handbook（学习手册）功能允许用户使用 LangMap 中的词句构建结构化的学习内容或笔记。
用户可以通过基于 Markdown 的编辑器编写手册，并在其中嵌入 LangMap 的词句（使用特定语法关联其 `meaning_id` 或 `expression_id`）。
在阅读手册时，用户可以随时切换“目标学习语言”，系统会自动根据用户选择的语言，从数据库中拉取对应语言的词汇，并在渲染时将嵌入的代码自动替换为该语言的表达。

## 数据库设计 (Database Schema)

需要新增一张表来存储手册内容。

### 1. handbooks 表

存储学习手册的基本信息和 Markdown 格式的正文内容。

```sql
CREATE TABLE IF NOT EXISTS handbooks (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,          -- 创建者ID，关联 users.id
    title TEXT NOT NULL,               -- 手册标题
    description TEXT,                  -- 手册简介/描述
    content TEXT NOT NULL,             -- Markdown 格式的正文内容
    is_public INTEGER DEFAULT 0,       -- 是否公开 (0: 私有, 1: 公开)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 2. 索引设计

为了提高查询性能，建议为该表添加以下索引：
- `CREATE INDEX idx_handbooks_user_id ON handbooks(user_id);`
- `CREATE INDEX idx_handbooks_is_public_created ON handbooks(is_public, created_at DESC);`
- `CREATE INDEX idx_handbooks_user_created ON handbooks(user_id, created_at DESC);`

## 后端接口设计 (API Design)

除了增删改查 API 接口外，还需要对现有查询接口进行增强。

### 1. 词句表达式查询 API 增强

目前 `/api/v1/expressions` 支持 `meaning_id` 查询参数。但为了能够支持在渲染手册时，前端通过一次请求获取所有需要的词语，必须修改由于逗号分隔的格式支持。

- **GET `/api/v1/expressions`**
  - **修改点**：`meaning_id` 参数解析逻辑从 `parseInt(c.req.query('meaning_id'))` 增强为能够解析多值，例如通过逗号分隔的 `?meaning_id=123,456`，使得其可以向数据库查询 `meaning_id IN (123, 456)`。

### 2. 手册管理 API (Handbooks CRUD)

所有写请求及查看私人手册均需通过 `requireAuth` 中间件验证用户身份。

- **GET `/api/v1/handbooks`**
  - **Query Params**: `user_id` (可选), `is_public` (可选), `skip`, `limit`
  - 获取手册列表。支持分页与公开筛选。

- **POST `/api/v1/handbooks`**
  - **Body**: `{ title, description, content, is_public }`
  - **Response**: Created Handbook object.

- **GET `/api/v1/handbooks/:id`**
  - 获取指定手册详情，若为未公开手册则校验 user_id 是否一致。

- **PUT `/api/v1/handbooks/:id`**
  - **Body**: (Partial) title, description, content, is_public.
  - **Response**: Updated Handbook object.

- **DELETE `/api/v1/handbooks/:id`**
  - 删除手册。

## 前端交互与渲染设计 (Frontend Design)

### 1. Markdown 语法与组件映射设计
为了在 Markdown 中嵌入 LangMap 词条并保留上下文内容，需要设计一种自定义拓展语法：
```markdown
这里是一段学习笔记的示范，您可以点击这个词汇： {{exp:123|mid:456|text:测试文本|audio:https://...}}
```
- 使用 `{{exp:<expr_id>|mid:<meaning_id>|text:<文本内容>|audio:<音频URL>}}` 来结构化存储词句信息。
  - **`exp`**: (Original expression ID) 保存添加时的原始词句 ID，可用于溯源。
  - **`mid`**: (Meaning ID) 关联的语义 ID，这是动态切换语言的核心。无论切换什么语言，都可以通过这个 `mid` 统一查询到对应的当地语言表达。
  - **`text`**: 原文内容，确保即使在无法联网或数据丢失时，Markdown 仍然具有可读性。
  - **`audio`**: 原始音频 URL，支持在离线或降级状态下依然能听到原始录音。

### 2. 编辑器交互
- **编辑器引入**：在一个支持 Markdown 的编辑器中进行开发（如使用 `v-md-editor` 或其他轻量级原生组件）。
- **工具栏拓展**：提供一个“插入词库引用”的辅助按钮。用户点击后弹出一个搜索面板，搜索 LangMap 的已有词句，选中后，编辑器自动在其光标位置插入包含该词句信息的完整语法标记，如 `{{exp:123|mid:456|text:Apple|audio:https://...}}`。

### 3. 阅读器与动态渲染 (Dynamic Rendering)
- **扫描与搜集**：前置获取手册正文的 Markdown。首先通过正则或 Markdown 插件扫描出正文所需的所有 `mid`，收集成一个数组。
- **批量语言获取**：由所选择的“目标学习语言”（通过下拉框进行选择，默认可以是用户的当前 Locale），调用接口 `GET /api/v1/expressions?language=<target_lang>&meaning_id=456,789` 批量获取这些表达。将返回的数据以 `meaning_id` 为 Key 构成一个 Map 结构。
- **动态替换与渲染**：
  - 在 Markdown 解析为 HTML 时，寻找 `{{exp:...}}` 标记。
  - 如果拿到了当前目标语言下对应该 `mid` 的句子文本，将标记渲染为对应的高亮文本或交互式 Vue 组件（允许点击播放录音或进入详细页面）。
  - **降级处理**：如果当前目标语言下该词还没有被收录或翻译，则降级使用标记中保存的原始 `text` 及其对应的 `audio`（如果有）进行展示，并加上特殊标识。

### 4. 路由与页面入口
- **`/handbooks`**：主页导航增设入口，展现公开学习手册大厅，以及“我的手册”选项卡模式。
- **`/handbooks/edit/:id?`**：新建或编辑手册界面。
- **`/handbooks/:id`**：手册阅读页面。在头部工具栏或者右侧悬浮区域增加一个“目标学习语言”的全局切换组件（Select / Dropdown）。一旦切换，立即触发批量查询和重新渲染。

## 开发计划 (Implementation Steps)

1. **Database**:
   - `d1_schema.sql` 增加 `handbooks` 建表语句。
   - `protocol.ts` 下添加 `Handbook` 实体类型与 `HandbooksService` 抽象接口。
   - `d1.ts` 实现抽象接口针对 `handbooks` 表的读写（CRUD）方法。
2. **Backend API**:
   - 增加所有相关的 `/api/v1/handbooks` CRUD 路由。
   - 更新 `api/v1.ts`：更新 `GET /expressions` 路由，使其正确支持 `meaning_id` 的逗号分隔数组查询。
3. **Frontend Markdown 解析**:
   - 在前端创建 `handbookService.ts` 进行接口管理。
   - 实现 Markdown 内 `meaning_id` 的正则提取与请求封装逻辑。
   - 实现目标语言（学习语言）的选择器共享状态。
4. **Frontend UI**:
   - 实现对应的三个模块路由与页面视图：大厅展示列表、新建/编辑页、文章渲染页。
   - 多语言化（i18n）翻译所有相关的提示、占位符。
