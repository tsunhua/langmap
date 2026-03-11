# Handbook (学习手册) 功能设计

## System Reminder

**设计来源**：根据用户需求（基于 Markdown 编辑并支持动态切换语言渲染相关词句的手册）设计。

**实现状态**：
- ✅ 数据库模型（handbooks 表，含 `source_lang`、`target_lang`） - 已实现
- ✅ 后端 API 基础实现（CRUD，含语言字段透传） - 已实现
- ✅ 前端 Markdown 编辑器（工具栏、格式化控件、Undo/Redo） - 已实现
- ✅ 编辑器语言设置（编写语言 / 学习语言 选择器） - 已实现
- ✅ 词条搜索按 source_lang 过滤 - 已实现
- ✅ 编辑器预览：按 target_lang 拉取翻译，括号备注显示 - 已实现
- ✅ Markdown 阅读页动态渲染词句，默认使用 handbook.target_lang - 已实现

---

## 概述

Handbook（学习手册）功能允许用户使用 LangMap 中的词句构建结构化的学习内容或笔记。
用户可以通过基于 Markdown 的编辑器编写手册，并在其中嵌入 LangMap 的词句（使用特定语法关联其 `meaning_id` 或 `expression_id`）。

编辑手册时，需要指定：
- **编写语言 (`source_lang`)**：手册内容所用的语言，用于过滤词条搜索结果。
- **学习语言 (`target_lang`)**：预览和阅读时的默认目标语言。

在阅读手册时，系统会自动使用手册的 `target_lang` 作为初始语言，用户也可以手动切换，系统会即时重新拉取对应语言的词汇并更新渲染。

## 数据库设计 (Database Schema)

### 1. handbooks 表

存储学习手册的基本信息和 Markdown 格式的正文内容。

```sql
CREATE TABLE IF NOT EXISTS handbooks (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,          -- 创建者ID，关联 users.id
    title TEXT NOT NULL,               -- 手册标题
    description TEXT,                  -- 手册简介/描述
    content TEXT NOT NULL,             -- Markdown 格式的正文内容
    source_lang TEXT,                   -- 手册编写语言 (e.g., 'en', 'zh-CN')
    target_lang TEXT,                   -- 目标学习语言 (e.g., 'zh-TW', 'nan-TW')
    is_public INTEGER DEFAULT 0,       -- 是否公开 (0: 私有, 1: 公开)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 2. 索引设计

- `CREATE INDEX idx_handbooks_user_id ON handbooks(user_id);`
- `CREATE INDEX idx_handbooks_is_public_created ON handbooks(is_public, created_at DESC);`
- `CREATE INDEX idx_handbooks_user_created ON handbooks(user_id, created_at DESC);`

## 后端接口设计 (API Design)

### 1. 词句表达式查询 API 增强

- **GET `/api/v1/expressions`**：`meaning_id` 支持逗号分隔的多值查询（`?meaning_id=123,456`），用于批量获取手册中引用的所有词句。

### 2. 手册管理 API (Handbooks CRUD)

所有写请求及查看私人手册均需通过 `requireAuth` 中间件验证用户身份。

| Method | Path | 说明 |
|--------|------|------|
| GET | `/api/v1/handbooks` | 获取列表（支持 `user_id`, `is_public`, `skip`, `limit` 筛选） |
| POST | `/api/v1/handbooks` | 创建手册（Body: `title`, `content`, `description`, `source_lang`, `target_lang`, `is_public`）|
| GET | `/api/v1/handbooks/:id` | 获取详情（非公开则校验用户） |
| PUT | `/api/v1/handbooks/:id` | 更新手册 |
| DELETE | `/api/v1/handbooks/:id` | 删除手册 |

## 前端交互与渲染设计 (Frontend Design)

### 1. Markdown 词句嵌入语法

```markdown
点击以下词汇可试听录音：{{exp:123|mid:456|text:测试文本|audio:https://...}}
```

字段含义：
- **`exp`**: 原始词句 ID（用于溯源）
- **`mid`**: 语义 ID（动态切换语言的核心 Key）
- **`text`**: 原始文本（即使离线也能保持内容可读）
- **`audio`**: 原始录音 URL（降级时可用）

### 2. 编辑器交互 (`HandbookEdit.vue`)

- **语言设置面板**：编辑器顶部提供两个下拉选择器：
  - **编写语言 (`source_lang`)**：选择后，工具栏内的词条搜索框将自动过滤，仅返回对应语言的结果。
  - **学习语言 (`target_lang`)**：选择后，预览模式下的词条将以目标语言进行渲染。

- **格式工具栏**：包含加粗、斜体、下划线、删除线、H1-H3、列表、引用、代码等按钮，以及 Undo / Redo。

- **词条搜索插入**：工具栏内集成搜索框，按 `source_lang` 过滤词条，选中后自动插入完整的 `{{exp:...}}` 语法。

- **预览模式（含翻译）**：
  - 点击 "Preview" 时自动扫描内容中所有 `mid`
  - 按 `target_lang` 调用 `/api/v1/expressions` 批量获取翻译
  - 词条以 **`原文 [译文]`** 格式展示，支持点击播放音频
  - 翻译结果按 `mid` 缓存，避免重复请求
  - 若无对应翻译，降级显示原始 `text` 和 `audio`

### 3. 阅读器与动态渲染 (`HandbookView.vue`)

- **初始语言**：默认使用手册本身的 `target_lang`，若未设置则回退至 localStorage 中的用户偏好。
- **语言切换器**：页面顶部提供语言下拉框，切换后立即重新请求翻译并重新生成。
- **渲染逻辑**：
  - 扫描 Markdown 内所有 `mid`，批量请求对应语言的词句
  - 已翻译词条高亮显示、支持点击播放录音
  - 无翻译的词条以灰色降级展示，标注 "fallback"

### 4. 路由与页面入口

- **`/handbooks`**：公开手册大厅 + "我的手册"选项卡
- **`/handbooks/edit/:id?`**：新建 / 编辑手册界面
- **`/handbooks/:id`**：手册阅读页面

## 开发计划 (Implementation Steps)

1. **Database**:
   - `024_handbook_table.sql` 建表，含 `source_lang`、`target_lang` 字段。✅
   - `protocol.ts` 添加 `Handbook` 接口（含语言字段）。✅
   - `d1.ts` 实现 CRUD，透传语言字段。✅
2. **Backend API**:
   - `/api/v1/handbooks` CRUD 路由。✅
   - `GET /expressions` 支持 `meaning_id` 逗号数组查询。✅
3. **Frontend Markdown 解析**:
   - `handbookService.js` 封装接口，含 `getHandbookExpressions`。✅
   - 实现 `mid` 正则提取与翻译批量请求。✅
4. **Frontend UI**:
   - `HandbookEdit.vue`：语言选择器、格式工具栏、Undo/Redo、语言过滤搜索、带翻译的预览。✅
   - `HandbookView.vue`：默认 `target_lang`、动态切换渲染、降级处理。✅
   - `en-US.json` 和 `zh-CN.json` 国际化。✅
