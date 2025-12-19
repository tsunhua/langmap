# 用户本地化翻译功能设计

## 概述

本文档描述了一个新功能的设计，该功能允许用户通过网页界面贡献本地化翻译。该功能支持社区驱动的本地化工作，并在翻译完成度达到60%时自动激活语言。

## 用户界面设计

### 翻译页面布局

翻译界面将设计为基于表格的形式，包含以下列：
1. **本地化键** - 每个可翻译字符串的键/标识符
2. **参考语言** - 用作参考的源语言（通常是英语）
3. **新语言** - 用户可以输入翻译的输入字段

### 关键组件

1. **语言选择**
   - 用户可以选择要翻译的目标语言（新语言）
   - 用户可以选择用作参考的语言（参考语言）
   - 参考语言和新语言不能相同，如果用户选择了相同的语言，应该显示错误提示
   - 显示所选语言的当前进度百分比
   - 显示语言当前是否处于活动状态（≥60%完成度）

2. **过滤控件**
   - 提供过滤选项，允许用户筛选需要翻译的条目
   - 支持过滤出未翻译的条目（默认显示）
   - 支持显示所有条目（包括已翻译和未翻译）
   - 支持仅显示已翻译的条目
   - 支持按本地化键搜索特定条目
   - 搜索框应支持模糊匹配，方便用户快速找到需要翻译的条目

3. **翻译表格**
   - 每一行代表一个可翻译的UI字符串
   - 中间列显示参考字符串以提供上下文
   - 最右列包含用于翻译的可编辑输入字段
   - 在参考语言列和目标语言列之间添加一个">>"按钮，点击后可将参考翻译填充到待翻译的输入框中
   - 进度指示器显示已翻译的字符串数量
   - 表格应支持分页或虚拟滚动以处理大量数据

4. **提交控件**
   - 保存按钮用于提交翻译
   - 进度可视化显示总体完成百分比
   - 清晰指示语言何时变为活动状态（达到60%阈值时）

### 页面路径设计

- 翻译页面路径：`/translate`
- 页面可通过导航栏中的"翻译"链接访问
- 页面URL可以包含查询参数，用于预选参考语言和目标语言：
  - `/translate?refLang=en-US&targetLang=fr` - 预选参考语言为英语(美国)，目标语言为法语
  - 如果没有查询参数，则默认参考语言为`en-US`，目标语言需要用户选择

## 后端实现

### 数据模型

系统将继续使用现有的[expressions](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/db/d1.ts#L45-L63)表来存储用户贡献的翻译，而不是创建新表。[expressions](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/db/d1.ts#L45-L63)表结构如下：

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

对于用户贡献的翻译，将使用以下字段：
- `text` - 存储翻译后的文本
- `meaning_id` - 指向英文原文的ID，用于关联同一含义的不同语言翻译
- `language_code` - 目标语言代码
- `tags` - 存储本地化键路径，如 ["home.title"]
- `source_type` - 设置为"user"表示用户贡献的翻译
- `review_status` - 初始设置为"pending"，待审核
- `created_by` - 贡献用户的标识

### 现有API利用

我们将充分利用现有的API端点而不是创建新的端点，以最大程度地重用现有功能：

1. 利用现有的 `/api/v1/ui-translations/:language` 端点：
   - 调用两次该端点分别获取参考语言和目标语言的翻译数据
   - 通过 `tags` 字段进行匹配，构建双语对照表
   - 添加过滤参数如 `filter`（支持 untranslated、translated、all）
   - 添加搜索参数 `search`
   - 添加分页参数 `skip` 和 `limit`

2. 利用现有的表达式创建端点 `/api/v1/expressions` 用于提交用户翻译

3. 利用现有的 `/api/v1/languages` 端点获取语言列表

### 完成度跟踪

系统将按以下方式计算完成百分比：
```
完成度 % = (已翻译键数 / 总键数) * 100
```

其中：
- 已翻译键数：目标语言中非空翻译的键的数量
- 总键数：应用程序中可翻译键的总数

系统将通过查询[expressions](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/db/d1.ts#L45-L63)表来统计特定语言的完成度：
```sql
SELECT COUNT(*) FROM expressions 
WHERE language_code = ? AND source_type = 'user' AND review_status = 'approved'
```

### 激活逻辑

当语言完成度达到60%时将自动激活：
- 完成度低于60%的语言被视为"进行中"
- 完成度达到或超过60%的语言被视为"活动"状态，可在[languages](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/db/d1.ts#L5-L27)表中将[is_active](file:///Users/lim/Documents/Code/tsunhua/langmap/scripts/001_d1_schema.sql#L12-L12)字段设置为1
- 每次提交翻译时都会检查激活状态

## 前端实现

### Vue组件结构

翻译页面将包括以下组件：

1. **LanguageSelector.vue** - 用于选择参考语言和目标语言的下拉菜单
2. **FilterControls.vue** - 过滤控件，包括过滤选项和搜索框
3. **TranslationProgress.vue** - 完成百分比的可视化指示器
4. **TranslationTable.vue** - 主表格界面，包含参考列和输入列
5. **Pagination.vue** - 分页控件（如果使用分页）
6. **SubmissionControls.vue** - 保存按钮和激活状态指示器

### 状态管理

关键的响应式数据属性：
- `referenceLanguage`: 用作翻译参考的语言
- `selectedLanguage`: 当前选择的目标语言
- `languages`: 可供选择的所有语言列表
- `referenceTranslations`: 参考语言的翻译数据
- `targetTranslations`: 目标语言的翻译数据
- `mergedTranslations`: 合并后的双语对照数据
- `completionPercentage`: 所选语言的当前完成百分比
- `isActive`: 布尔值，表示语言是否处于活动状态（≥60%完成度）
- `formErrors`: 表单验证错误信息
- `filterOptions`: 过滤选项（未翻译、已翻译、全部）
- `searchQuery`: 搜索关键词
- `currentPage`: 当前页码（如果使用分页）
- `itemsPerPage`: 每页显示的条目数

### 表单验证

- 验证参考语言和目标语言不能相同
- 如果用户尝试选择相同的语言，应显示错误消息："参考语言和目标语言不能相同"
- 在提交翻译前验证所有必填字段

### API集成

前端将通过现有API端点与后端通信：

1. UI翻译端点（调用两次）：
   - GET `/api/v1/ui-translations/:refLang?filter=:filter&search=:search&skip=:skip&limit=:limit` - 获取参考语言翻译数据
   - GET `/api/v1/ui-translations/:targetLang?filter=:filter&search=:search&skip=:skip&limit=:limit` - 获取目标语言翻译数据

2. 其他现有端点：
   - GET `/api/v1/languages` - 获取所有可用语言列表
   - POST `/api/v1/expressions` - 提交新的/更新的翻译
   - GET `/api/v1/statistics` - 获取语言的完成百分比

### 数据处理逻辑

前端需要实现以下数据处理逻辑：

1. 并行调用两次 `/api/v1/ui-translations/:language` 接口获取参考语言和目标语言的数据
2. 根据 `tags` 字段将两种语言的数据进行匹配合并
3. 生成三列数据：本地化键(tag)、参考语言文本、目标语言文本
4. 根据过滤条件筛选数据：
   - 未翻译：目标语言文本为空的条目
   - 已翻译：目标语言文本非空的条目
   - 全部：所有条目
5. 根据搜索关键词过滤数据

## 用户体验考虑

### 实时反馈

- 翻译输入的即时验证
- 用户输入时完成百分比的实时更新
- 语言变为活动状态时的清晰视觉指示

### 性能优化

- 对于大量的本地化键，采用分页或虚拟滚动
- 防抖保存以防止过多的API调用
- 部分完成的翻译的本地缓存
- 搜索和过滤在客户端进行以提高响应速度

### 可访问性

- 为屏幕阅读器正确标记表单元素
- 支持键盘导航
- 所有UI元素具有足够的颜色对比度
- ">>"按钮应有明确的标签，以便辅助技术能够识别其功能

## 安全考虑

- 提交翻译需要用户认证
- 输入净化以防止XSS攻击
- 速率限制以防止滥用翻译系统
- 翻译贡献的审计跟踪

## 审核工作流

为了确保翻译质量，系统将实施审核工作流：
- 用户提交的翻译初始状态为"pending"
- 管理员可以审核并批准翻译，将其状态更改为"approved"
- 只有已批准的翻译才会计算在完成度内
- 被拒绝的翻译可以被重新编辑和提交

## 未来增强功能

1. **协作功能**
   - 多个用户为同一语言做贡献
   - 翻译的讨论功能，允许用户就特定翻译进行交流
   - 翻译排行榜，激励用户贡献

2. **高级工具**
   - 机器翻译建议作为起点
   - 翻译记忆以重用先前批准的翻译
   - 术语表集成以确保术语的一致性

3. **质量保证**
   - 翻译完整性的自动化验证
   - 复数形式处理
   - 上下文信息用于消除歧义的字符串