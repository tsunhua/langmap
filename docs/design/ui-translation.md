# UI 翻译系统设计

## 概述

本文档整合了 LangMap 项目的 UI 翻译系统设计，包括：
- 用户翻译界面设计
- 本地化翻译同步方案
- 翻译数据管理机制

## 用户翻译功能

### 翻译界面设计

翻译界面采用基于表格的形式，包含以下列：
1. **本地化键** - 每个可翻译字符串的键/标识符
2. **参考语言** - 用作参考的源语言（通常是英语）
3. **目标语言** - 用户可以输入翻译的输入字段

#### 关键组件

**语言选择**
- 用户可以选择要翻译的目标语言
- 用户可以选择用作参考的语言
- 参考语言和目标语言不能相同
- 显示所选语言的当前进度百分比
- 显示语言当前是否处于活动状态（≥60%完成度）

**过滤控件**
- 过滤选项：未翻译（默认）、已翻译、全部
- 搜索框：支持模糊匹配，快速查找需要翻译的条目

**翻译表格**
- 每一行代表一个可翻译的UI字符串
- 中间列显示参考字符串以提供上下文
- 最右列包含用于翻译的可编辑输入字段
- 在参考语言列和目标语言列之间添加">>"按钮，点击后可将参考翻译填充到待翻译的输入框中
- 进度指示器显示已翻译的字符串数量
- 表格支持分页或虚拟滚动以处理大量数据

**提交控件**
- 保存按钮用于提交翻译
- 进度可视化显示总体完成百分比
- 清晰指示语言何时变为活动状态（达到60%阈值时）

#### 页面路径

- 翻译页面路径：`/translate`
- 页面URL可包含查询参数：`/translate?refLang=en-US&targetLang=fr`
- 如果没有查询参数，则默认参考语言为`en-US`，目标语言需要用户选择

### 后端实现

#### 数据模型

系统使用现有的 `expressions` 表存储用户贡献的翻译：

```sql
CREATE TABLE IF NOT EXISTS expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    meaning_id INTEGER, -- 关联的 en-US 的 expression_id
    audio_url TEXT,
    language_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    tags TEXT,
    source_type TEXT DEFAULT 'user',
    source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

对于用户贡献的翻译：
- `text` - 存储翻译后的文本
- `meaning_id` - 指向英文原文的ID，用于关联同一含义的不同语言翻译
- `language_code` - 目标语言代码
- `tags` - 存储本地化键路径，如 `["home.title"]`
- `source_type` - 设置为 `"user"` 表示用户贡献的翻译
- `review_status` - 初始设置为 `"pending"`，待审核

#### API 端点

**GET /api/v1/ui-translations/:language**
- 获取指定语言的UI翻译
- 支持过滤参数：`filter` (untranslated/translated/all)
- 支持搜索参数：`search`
- 支持分页参数：`skip` 和 `limit`

**POST /api/v1/ui-translations/:language**
- 批量提交用户翻译
- 请求体示例：
```json
{
  "translations": [
    {
      "key": "home.title",
      "text": "首页标题"
    }
  ]
}
```

#### 完成度计算

```javascript
完成度 % = (已翻译键数 / 总键数) * 100
```

- 已翻译键数：目标语言中非空翻译的键的数量
- 总键数：应用程序中可翻译键的总数

#### 激活逻辑

当语言完成度达到60%时将自动激活：
- 完成度低于60%的语言被视为"进行中"
- 完成度达到或超过60%的语言被视为"活动"状态
- 在 `languages` 表中将 `is_active` 字段设置为 1
- 每次提交翻译时都会检查激活状态

### 前端实现

#### Vue 组件结构

1. **TranslateInterface.vue** - 翻译页面的主容器组件
2. **LanguageSelector.vue** - 语言选择下拉菜单
3. **FilterControls.vue** - 过滤控件
4. **TranslationProgress.vue** - 完成百分比的可视化指示器
5. **TranslationTable.vue** - 主表格界面

#### 状态管理

关键响应式数据：
- `referenceLanguage` - 参考语言
- `selectedLanguage` - 目标语言
- `languages` - 所有可用语言列表
- `referenceTranslations` - 参考语言翻译数据
- `targetTranslations` - 目标语言翻译数据
- `mergedTranslations` - 合并后的双语对照数据
- `completionPercentage` - 当前完成百分比
- `isActive` - 语言是否处于活动状态
- `filterOptions` - 过滤选项
- `searchQuery` - 搜索关键词

#### 表单验证

- 验证参考语言和目标语言不能相同
- 提交翻译前验证所有必填字段

#### 数据处理逻辑

1. 并行调用两次 `/api/v1/ui-translations/:language` 接口获取数据
2. 根据 `tags` 字段将两种语言的数据进行匹配合并
3. 生成三列数据：本地化键、参考语言文本、目标语言文本
4. 根据过滤条件和搜索关键词筛选数据

---

## 翻译同步系统

### 问题背景

当前系统中，翻译 key 的管理存在数据流断裂问题：

1. **静态 locales 文件**（`web/src/locales/en-US.json` 等）是前端 UI 翻译的权威来源
2. **数据库 expressions 表**通过 `langmap` 收藏集存储翻译
3. **缺失环节**：从 locales 文件到数据库没有自动同步机制
4. **结果**：开发者新增的翻译 key 在前端可见，但在翻译界面不可见

### 系统架构

```
┌─────────────────────────────────────────┐
│     前端 (Vue + Vue I18n)            │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  1. 静态文件加载                 │
│     8种核心语言: en-US, zh-CN...  │
│     直接从 locales/*.json 导入        │
│  2. 动态加载 (其他语言)            │
│     i18n.js: loadLanguage(langCode)   │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         后端 API (Hono)             │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│       Cloudflare D1 数据库            │
│  expressions 表 + collections 表       │
└─────────────────────────────────────────┘
```

### 数据关联机制

- **meaning_id**：不同语言的翻译通过 meaning_id 关联到同一含义
- **对于 en-US**：meaning_id 就是其自身的 id
- **对于其他语言**：meaning_id 指向 en-US 的对应翻译 id
- **tags 字段**：存储本地化键（如 `["home.title"]`）

---

## 推荐同步方案

### 方案零：前端直接显示本地 JSON（推荐）

**核心思路**：翻译界面直接读取本地 `locales/en-US.json` 文件作为参考语言，合并数据库中的目标语言翻译。

**优点**：
- 最简单：无需后端同步，无需数据库操作
- 最快速：立即可用，新增 key 自动显示
- 无风险：不修改数据库，不影响现有数据
- 易维护：纯前端改动，逻辑清晰

**实现方式**：

修改 `web/src/pages/TranslateInterface.vue`：

```javascript
import enMessages from '../locales/en-US.json'

// 扁平化 en-US.json
const flattenObject = (obj, prefix = '') => {
  const flattened = {}
  for (const key in obj) {
    const newKey = prefix ? `${prefix}.${key}` : key
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      Object.assign(flattened, flattenObject(obj[key], newKey))
    } else {
      flattened[newKey] = obj[key]
    }
  }
  return flattened
}

// 在组件加载时使用本地 en-US
const loadReferenceTranslations = () => {
  const flattened = flattenObject(enMessages)
  referenceTranslations.value = Object.entries(flattened).map(([key, text]) => ({
    key,
    text,
    meaning_id: key,
    fromLocal: true
  }))
}
```

### 管理员同步功能（可选）

在翻译界面添加一个**同步按钮**，仅管理员可见：

**功能描述**：
- 新增：数据库中不存在的 key 会被创建
- 忽略：数据库中已存在的 key 不会被覆盖（保持数据安全）

**设计考虑**：
1. 权限控制：仅管理员可见同步按钮
2. 幂等性：多次同步不会产生重复数据
3. 安全性：不覆盖已有翻译，避免误操作
4. 反馈：显示同步进度和结果统计

---

## 审核工作流

为了确保翻译质量，系统将实施审核工作流：

- 用户提交的翻译初始状态为 `"pending"`
- 管理员可以审核并批准翻译，将其状态更改为 `"approved"`
- 只有已批准的翻译才会计算在完成度内
- 被拒绝的翻译可以被重新编辑和提交

---

## 未来增强功能

1. **协作功能**
   - 多个用户为同一语言做贡献
   - 翻译的讨论功能
   - 翻译排行榜

2. **高级工具**
   - 机器翻译建议作为起点
   - 翻译记忆以重用先前批准的翻译
   - 术语表集成以确保术语的一致性

3. **质量保证**
   - 翻译完整性的自动化验证
   - 复数形式处理
   - 上下文信息用于消除歧义的字符串

---

## 相关文档

- [国际化设计方案](./i18n-architecture.md)
- [导出系统设计](./export-system.md)
- [用户系统设计](./user-system.md)
