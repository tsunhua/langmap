# 词句与语义多对多关系设计

## System Reminder

**设计来源**：基于用户需求，改造现有数据结构以支持多对多关系

**实现状态**：
- ✅ 设计文档已完成
- ⏳ 等待实现

---

## 概述

当前系统中，`expressions` 表通过 `meaning_id` 字段实现词句与语义的关联，但这种方式只支持单一语义关联。为了支持一个词句对应多个语义，以及一个语义对应多个词句的多对多关系，需要引入新的数据模型。

## 需求分析

### 当前问题
- 每个 expression 只能关联一个 meaning（通过 `meaning_id` 字段）
- 无法表达一个词句的多个不同语义（例如中文的"意思"可以表示"meaning"、"interesting"等）
- 无法为多个词句共享相同的语义定义

### 新需求
- **多对多关系**：一个 expression 可以有多个 meanings，一个 meaning 可以关联多个 expressions
- **语义独立性**：meanings 作为独立实体，有简单的创建时间追踪
- **兼容性考虑**：需要考虑现有数据的迁移方案

## 数据模型设计

### 1. meanings 表

存储语义定义的独立表。

```sql
CREATE TABLE IF NOT EXISTS meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**字段说明**：
- `id`: 主键，使用第一个关联的 expression 的 id 作为 meaning 的 id


### 2. expression_meaning 表

词句与语义的多对多关联表。

```sql
CREATE TABLE IF NOT EXISTS expression_meaning (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,                 -- 关联 expressions.id
    meaning_id INTEGER NOT NULL,                    -- 关联 meanings.id
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(expression_id, meaning_id),             -- 防止重复关联
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (meaning_id) REFERENCES meanings(id)
);
```

**字段说明**：
- `expression_id`: 关联到 expressions 表
- `meaning_id`: 关联到 meanings 表
- `UNIQUE(expression_id, meaning_id)`: 确保同一个词句不会重复关联同一个语义

**索引**：

```sql
CREATE INDEX IF NOT EXISTS idx_expression_meaning_expression_id ON expression_meaning(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meaning_meaning_id ON expression_meaning(meaning_id);
```

### 3. expressions 表的修改

保留 `meaning_id` 字段以保持向后兼容，但不再作为主要的语义关联方式。

```sql
-- expressions 表保持不变，但 meaning_id 字段标记为 deprecated
-- 新代码应使用 expression_meaning 表进行关联
```

## 数据库关系图

```
languages (语言表)
  ↓ 1:N
expressions (词句表)
  ↔ N:M
expression_meaning (关联表)
  ↔ N:1
meanings (语义表)

expressions (词句表)
  ↓ 1:N
expression_versions (版本历史表)
```

## 数据迁移方案

### 迁移策略

1. **创建新表**：创建 `meanings` 和 `expression_meaning` 表
2. **数据迁移**：
   - 从 `expressions` 表中读取所有有 `meaning_id` 的记录
   - 为每个 `meaning_id` 创建对应的 `meanings` 记录（使用 meaning_id 作为 id）
   - 创建 `expression_meaning` 关联记录
3. **保留旧字段**：`expressions.meaning_id` 字段保留，但标记为 deprecated
4. **代码适配**：更新 API 和查询逻辑以使用新的多对多关系

### 迁移脚本

迁移脚本将创建为 `scripts/025_meaning_mapping.sql`，包含以下内容：

```sql
-- LangMap Meaning Mapping - 多对多关系改造
-- Date: 2026-03-04
-- Description: 添加 meanings 和 expression_meaning 表，支持词句与语义的多对多关系
-- 执行：npx wrangler d1 execute langmap --remote --file=../scripts/025_meaning_mapping.sql --y

--------------------------------------------------------------------------------
-- 1. 创建 meanings 表
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------------------------------------
-- 2. 创建 expression_meaning 表
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expression_meaning (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    meaning_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(expression_id, meaning_id),
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (meaning_id) REFERENCES meanings(id)
);

--------------------------------------------------------------------------------
-- 3. 数据迁移：将现有的 meaning_id 迁移到新的多对多关系
--------------------------------------------------------------------------------

-- 步骤 3.1: 为每个唯一的 meaning_id 创建 meanings 记录
-- 使用 meaning_id 作为 meanings.id，使用关联的表达式文本和语言作为语义内容
INSERT INTO meanings (id, created_by, created_at)
SELECT DISTINCT
    e.meaning_id,
    (SELECT created_by FROM expressions WHERE id = e.meaning_id),
    (SELECT created_at FROM expressions WHERE id = e.meaning_id)
FROM expressions e
WHERE e.meaning_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM meanings WHERE id = e.meaning_id);

-- 步骤 3.2: 创建 expression_meaning 关联记录
-- 为每个有 meaning_id 的 expression 创建关联
INSERT INTO expression_meaning (id, expression_id, meaning_id, created_at)
SELECT
    -- 生成唯一的关联 ID，避免冲突
    (e.id * 10000) + e.meaning_id,
    e.id,
    e.meaning_id,
    CURRENT_TIMESTAMP
FROM expressions e
WHERE e.meaning_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM expression_meaning em
    WHERE em.expression_id = e.id AND em.meaning_id = e.meaning_id
);

--------------------------------------------------------------------------------
-- 4. 创建索引
--------------------------------------------------------------------------------

-- expression_meaning 表索引
CREATE INDEX IF NOT EXISTS idx_expression_meaning_expression_id ON expression_meaning(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meaning_meaning_id ON expression_meaning(meaning_id);
```

**迁移说明**：
- 迁移脚本会为每个现有的 `meaning_id` 创建对应的 `meanings` 记录
- 使用 `meaning_id` 作为 `meanings.id`，保持与现有数据的关联
- meanings 表仅保留必要的元数据（id, created_by, created_at）
- 使用 `UNIQUE` 和 `NOT EXISTS` 确保数据不重复

## API 设计

考虑到 meanings 表的极简设计（只有 id, created_by, created_at），以及现有的 API 模式，我们通过扩展现有接口来实现多对多关系，尽量减少新增 API。

### 核心设计原则

**语义关联自动化**：系统通过智能决策自动处理词句与语义的多对多关联，用户无需手动管理复杂的关联关系。

### 1. 获取词句详情（扩展）

**Endpoint**: `GET /api/v1/expressions/:expr_id`

**变化**：返回数据中增加 `meanings` 字段，包含该词句关联的所有语义 ID。

**Response**:
```json
{
    "id": 123,
    "text": "hello",
    "language_code": "en-US",
    "meaning_id": 456,
    "meanings": [
        {
            "id": 456,
            "created_by": "user123",
            "created_at": "2026-03-04T00:00:00Z"
        }
    ]
}
```

### 2. 获取词句列表（扩展）

**Endpoint**: `GET /api/v1/expressions`

**Query Params**:
- `meaning_id`: (可选) 按语义 ID 筛选词句（现有参数，支持多个用逗号分隔）
- `include_meanings`: (可选) 是否包含关联的语义列表，默认 false

**变化**：当 `include_meanings=true` 时，返回的每个 expression 包含 `meanings` 字段。

### 3. 批量提交词句（扩展核心接口）

**Endpoint**: `POST /api/v1/expressions/batch`

**核心变化**：扩展现有的智能语义锚点决策逻辑，支持多对多关系。

**Body**:
```json
{
    "meaning_id": 456
}
```

**参数说明**：
- `meaning_id`: (可选) 指定要关联的语义 ID
  - 如果不指定，系统会自动决策
  - 如果指定，所有词句都会关联到这个语义

**自动决策逻辑**：

1. **情况1：所有词句都没有 meaning 关联**
   - 按照语种优先级（en-GB > en-US > zh-TW > zh-CN > ...）选择第一个词句
   - 使用该词句的 ID 作为 meaning_id
   - 如果选中的词句 ID 已经作为 meaning_id 存在（冲突），则选择下一级的词句 ID
   - 所有词句关联到这个 meaning

2. **情况2：所有有 meaning_id 的词句都有共同的 meaning_id**
   - 使用这个共同的 meaning_id
   - 没有 meaning_id 的词句也关联到这个 meaning

3. **情况3：存在多个不同的 meaning_id**
   - 按照语种优先级选择词句作为新的 meaning_id
   - 如果选中的词句 ID 已经作为 meaning_id 存在（冲突），则选择下一级的词句 ID
   - 所有词句关联到这个新的 meaning

**实现逻辑**：
```javascript
// 伪代码：自动决策逻辑
function autoSelectMeaning(expressions) {
  // 步骤1: 批量查询现有词句的 meaning_id
  const existingExprs = await getExpressionsByIds(expressions.map(e => e.id));

  // 步骤2: 分析现有的 meaning_id 分布
  const meaningIds = existingExprs
    .filter(e => e.meaning_id !== null)
    .map(e => e.meaning_id);

  // 步骤3: 决策
  if (meaningIds.length === 0) {
    // 情况1: 都没有 meaning_id，按语种优先级选择
    const sortedExprs = sortByLanguagePriority(expressions);
    return sortedExprs[0].id; // 使用第一个词句的 ID 作为 meaning_id
  }

  const uniqueMeaningIds = [...new Set(meaningIds)];
  if (uniqueMeaningIds.length === 1) {
    // 情况2: 都有相同的 meaning_id
    return uniqueMeaningIds[0];
  }

  // 情况3: 存在多个不同的 meaning_id，按语种优先级选择新的 meaning
  const sortedExprs = sortByLanguagePriority(expressions);

  // 检查每个词句 ID 是否已经是 meaning_id（冲突检查）
  for (const expr of sortedExprs) {
    if (!uniqueMeaningIds.includes(expr.id)) {
      // 找到未作为 meaning_id 的词句，使用其 ID
      return expr.id;
    }
  }

  // 如果所有词句 ID 都已经是 meaning_id（极端情况），选择第一个词句的 ID
  // 这意味着会创建新的 meanings 表记录，即使 ID 已经存在
  return sortedExprs[0].id;
}
```

**Response**:
```json
{
    "success": true,
    "meaning_id": 456,
    "results": [...]
}
```

**与现有的 /expressions/associate 接口的关系**：
- `/expressions/batch` 的自动决策逻辑与 `/expressions/associate` 的 `selectSemanticAnchor` 方法类似
- 主要区别在于 `batch` 接口同时处理新词句的创建和现有词句的更新
- `associate` 接口只处理现有词句的关联更新

### 4. 关联词句与语义（新增，用于高级场景）

**Endpoint**: `POST /api/v1/expressions/:expr_id/meanings`

**用途**：为已有词句添加额外的语义关联（多对多关系）

**Body**:
```json
{
    "meaning_id": 456
}
```

**Response**: Success message

### 5. 解除词句与语义的关联（新增，用于高级场景）

**Endpoint**: `DELETE /api/v1/expressions/:expr_id/meanings/:meaning_id`

**用途**：删除词句与特定语义的关联

**Response**: Success message

## 设计说明

### 前端设计理念

**词句组 vs 语义**

在 LangMap 的前端设计中，我们采用了"词句组"的概念来代替抽象的"语义"：

| 概念 | 后端视角 | 前端视角 |
|------|----------|----------|
| 语义 | meanings 表 + expression_meaning 表 | 词句组 |
| meaning_id | meanings.id | 词句组 ID |
| 多对多关系 | 一个词句可属于多个 meanings | 一个词句可属于多个词句组 |

**设计优势**：

1. **直观易懂**：用户通过实际的词句组理解语义关联，而不是抽象的概念
2. **可视化强**：每个词句组包含可见的词句列表，用户一目了然
3. **操作简单**：通过"关联词句"按钮，用户可以直观地将词句添加到组
4. **渐进式**：普通用户只需使用词句组功能，高级用户可以通过 API 直接操作语义

**交互设计原则**：

- **隐式关联**：用户不需要明确创建"语义"，而是通过批量提交词句自动形成词句组
- **显式管理**：用户可以在词句详情页看到所有词句组，并管理组内词句
- **搜索关联**：通过搜索功能找到词句，然后将其关联到现有词句组
- **灵活组织**：一个词句可以属于多个词句组，支持复杂的语义关系

### API 最小化原则

### 核心设计理念

**词句组概念**：在前端中，"语义"不那么明显，通过"词句组"来体现。每个 meaning_id 对应的一组词句就是一个"词句组"。

**用户视角**：
- 用户看到的不是"语义"，而是"词句组"
- 每个词句组包含共享相同含义的一组词句
- 用户可以通过"关联词句"按钮将新的词句添加到组中
- 用户可以从组中移除词句

**数据视角**：
- meanings 表只包含元数据（id, created_by, created_at）
- 语义的实际内容通过关联的 expressions 体现
- 多个词句可以属于同一个词句组（多对多关系）

### API 最小化原则

1. **核心自动化**：通过 `POST /api/v1/expressions/batch` 的自动决策逻辑，处理绝大多数场景
2. **手动管理**：仅在需要复杂多对多关系时，使用额外的关联/解关联接口
3. **语义通过词句体现**：meanings 表只包含元数据，语义的实际内容通过关联的 expressions 体现

### 与现有 API 的兼容性

1. **保留 meaning_id 字段**：expressions 表的 meaning_id 字段继续保留，用于向后兼容和翻译功能
2. **迁移脚本兼容**：数据迁移后，现有的基于 meaning_id 的查询仍然有效
3. **渐进式升级**：前端可以选择使用新的 meanings 数组字段，或者继续使用 meaning_id 字段

### 查询示例

```sql
-- 获取词句的所有语义（在 GET /api/v1/expressions/:id 中使用）
SELECT m.*
FROM meanings m
JOIN expression_meaning em ON m.id = em.meaning_id
WHERE em.expression_id = ?
ORDER BY em.created_at DESC;

-- 按语义查询词句（在 GET /api/v1/expressions 中使用，当 meaning_id 参数存在时）
SELECT DISTINCT e.*
FROM expressions e
JOIN expression_meaning em ON e.id = em.expression_id
WHERE em.meaning_id IN (?)
ORDER BY e.created_at DESC
LIMIT ? OFFSET ?;
```

## 前端实现

**设计理念**：语义在前端中不那么明显，通过"词句组"的概念来体现。每个 meaning_id 对应的一组词句就是一个"语义组"。

### 1. 词句详情页

词句详情页展示该词句关联的多个"词句组"（即语义）：

- **词句组列表**：展示该词句所属的所有词句组
- **词句组内容**：每个词句组包含共享相同 meaning_id 的所有词句
- **关联词句按钮**：每个词句组旁边提供"关联词句"按钮，用于将搜索到的词句关联到该语义
- **词句组管理**：支持移除某个词句从该组

**组件结构**：
```
ExpressionDetail
├── ExpressionCard (当前词句基本信息)
├── ExpressionGroups (词句组列表)
│   └── ExpressionGroup (单个词句组)
│       ├── GroupHeader (组标识，如 "语义组 #456"）
│       ├── GroupExpressions (该组的所有词句)
│       │   └── ExpressionCard (词句卡片）
│       └── AssociateButton (关联词句按钮）
└── AssociateModal (关联词句弹窗）
    ├── SearchBar (搜索词句）
    ├── SearchResults (搜索结果）
    └── AssociateButton (确认关联）
```

**交互流程**：

1. **查看词句组**：用户打开词句详情页，看到该词句所属的所有词句组
   ```javascript
   // 获取词句详情（包含 meanings 数组）
   const response = await fetch(`/api/v1/expressions/${expressionId}`);
   const expression = await response.json();

   // meanings 数组中的每个 meaning_id 对应一个词句组
   expression.meanings.forEach(async (meaning) => {
     // 获取该语义组的所有词句
     const groupResponse = await fetch(`/api/v1/expressions?meaning_id=${meaning.id}`);
     const groupExpressions = await groupResponse.json();

     // 渲染词句组
     renderExpressionGroup({
       meaningId: meaning.id,
       expressions: groupExpressions
     });
   });
   ```

2. **关联词句到组**：点击某个词句组的"关联词句"按钮
   ```javascript
   // 打开关联弹窗，用户搜索要关联的词句
   openAssociateModal({
     targetMeaningId: 456,  // 目标词句组
     onSearch: async (query) => {
       // 搜索词句
       const searchResponse = await fetch(`/api/v1/search?q=${query}&skip=0&limit=20`);
       return await searchResponse.json();
     },
     onAssociate: async (selectedExpressions) => {
       // 将选中的词句关联到目标词句组
       const batchResponse = await fetch('/api/v1/expressions/batch', {
         method: 'POST',
         headers: {
           'Content-Type': 'application/json',
           'Authorization': `Bearer ${token}`
         },
         body: JSON.stringify({
           meaning_id: targetMeaningId,
           expressions: selectedExpressions.map(expr => ({
             id: expr.id,  // 已存在的词句
             text: expr.text,
             language_code: expr.language_code
           }))
         })
       });

       const result = await batchResponse.json();
       showSuccess(`Successfully associated ${result.results.length} expressions to meaning #${targetMeaningId}`);

       // 刷新页面
       reloadExpressionDetail();
     }
   });
   ```

3. **移除词句从组**：点击词句旁边的"移除"按钮
   ```javascript
   async function removeFromGroup(expressionId, meaningId) {
     const response = await fetch(`/api/v1/expressions/${expressionId}/meanings/${meaningId}`, {
       method: 'DELETE',
       headers: {
         'Authorization': `Bearer ${token}`
       }
     });

     if (response.ok) {
       showSuccess('Expression removed from group');
       // 刷新页面
       reloadExpressionDetail();
     }
   }
   ```

**界面示例**：

```
┌─────────────────────────────────────────────────┐
│ 词句详情: "hello" (en-US)                   │
├─────────────────────────────────────────────────┤
│                                             │
│ 词句组 1 (3 个词句) [关联词句 +]          │
│ ┌───────────────────────────────────────────┐  │
│ │ hello (en-US) [当前]                 │  │
│ │ 你好 (zh-CN)                         │  │
│ │ こんにちは (ja-JP) [移除]           │  │
│ └───────────────────────────────────────────┘  │
│                                             │
│ 词句组 2 (2 个词句) [关联词句 +]          │
│ ┌───────────────────────────────────────────┐  │
│ │ hi (en-US)                           │  │
│ │ 嗨 (zh-CN)                          │  │
│ └───────────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────────┘
```

### 2. 语义列表页

### 2. 词句列表页

扩展现有的词句列表页，支持按词句组（语义）筛选：

- **词句组筛选**：通过 GET /api/v1/expressions?meaning_id=xxx 查询特定词句组的所有词句
- **多组筛选**：通过逗号分隔的 meaning_id 参数查询多个词句组的词句
- **包含词句组信息**：通过 GET /api/v1/expressions?include_meanings=true 获取词句时同时加载其所属的词句组

**路由**：复用 `/expressions` 路由，增加筛选参数

**组件结构**：
```
ExpressionsPage
├── SearchBar (搜索和筛选)
│   └── GroupFilter (词句组筛选器)
└── ExpressionsList
    └── ExpressionCard
        └── GroupsPreview (所属词句组预览)
```

### 3. 批量提交词句（核心功能）

在批量提交词句时，利用系统的自动决策逻辑：

```javascript
// 场景1: 不指定 meaning_id，系统自动决策
const response1 = await fetch('/api/v1/expressions/batch', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    expressions: [
      {
        text: 'hello',
        language_code: 'en-US'
      },
      {
        text: '你好',
        language_code: 'zh-CN'
      }
    ]
    // 不指定 meaning_id，系统会自动按语种优先级选择
  })
})
// 响应: { success: true, meaning_id: 123, results: [...] }

// 场景2: 指定 meaning_id，所有词句关联到该语义
const response2 = await fetch('/api/v1/expressions/batch', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    meaning_id: 456,  // 明确指定
    expressions: [
      {
        text: 'hi',
        language_code: 'en-US'
      },
      {
        text: '嗨',
        language_code: 'zh-CN'
      }
    ]
  })
})
// 响应: { success: true, meaning_id: 456, results: [...] }

// 场景3: 自动决策选择新的 meaning（有冲突的 meaning_id）
const response3 = await fetch('/api/v1/expressions/batch', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    expressions: [
      {
        id: 100,  // 已存在，meaning_id = 456
        text: 'hello',
        language_code: 'en-US'
      },
      {
        id: 101,  // 已存在，meaning_id = 789（冲突）
        text: 'world',
        language_code: 'en-US'
      },
      {
        id: 102,  // 已存在，没有 meaning_id
        text: 'new',
        language_code: 'en-US'
      }
    ]
    // 没有指定 meaning_id，且存在冲突
  })
})
// 响应: { success: true, meaning_id: 102, results: [...] }
// 系统选择了没有 meaning_id 的词句（ID 102）作为新的 meaning_id
```

### 4. 错误处理和用户反馈

由于自动决策会处理所有情况，批量提交几乎不会失败。前端需要提供友好的成功反馈：

```javascript
// 批量提交示例
async function submitBatch(expressions, options = {}) {
  try {
    const body: any = { expressions };

    // 可选：用户可以明确指定 meaning_id
    if (options.meaningId) {
      body.meaning_id = options.meaningId;
    }

    const response = await fetch('/api/v1/expressions/batch', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify(body)
    });

    if (!response.ok) {
      const error = await response.json();
      showGenericError(error.error);
      return;
    }

    const data = await response.json();

    // 显示成功信息，包含使用的 meaning_id（词句组 ID）
    showSuccess({
      message: `Success! ${data.results.length} expressions processed.`,
      meaningId: data.meaning_id,
      meaningInfo: data.meaning_id === options.meaningId
        ? 'Used specified group'
        : 'Auto-selected group'
    });

    return data;
  } catch (error) {
    showGenericError('Network error. Please try again.');
    throw error;
  }
}

// 使用示例
// 自动决策（推荐）
await submitBatch(expressions);

// 明确指定 meaning_id（高级用户）
await submitBatch(expressions, { meaningId: 456 });
```

### 5. 搜索和筛选

支持基于词句组（语义）的搜索和筛选：

- **按词句组筛选词句**：在词句列表页，通过 `meaning_id` 参数筛选词句
  ```javascript
  // 示例：查询词句组 ID 456 的所有词句
  const response = await fetch('/api/v1/expressions?meaning_id=456&skip=0&limit=20')

  // 示例：查询多个词句组的词句
  const response = await fetch('/api/v1/expressions?meaning_id=456,457,458&skip=0&limit=20')
  ```

- **包含词句组信息**：在查询词句时，通过 `include_meanings=true` 参数同时加载其所属的词句组
  ```javascript
  // 示例：获取词句时同时加载其所属的词句组
  const response = await fetch('/api/v1/expressions?include_meanings=true&skip=0&limit=20')
  ```

- **词句详情页的词句组展示**：在词句详情页，通过 `meanings` 数组展示该词句所属的所有词句组，每个组包含共享相同 meaning_id 的所有词句

## 性能优化

### 1. 查询优化

- 使用 `idx_expression_meaning_expression_id` 优化查询词句的所有语义
- 使用 `idx_expression_meaning_meaning_id` 优化查询语义的所有词句
- 对于高频查询，利用现有的 `cacheMiddleware` 缓存

**优化示例**：
```sql
-- 查询词句的所有语义（在 GET /api/v1/expressions/:id 中使用）
SELECT m.*
FROM meanings m
JOIN expression_meaning em ON m.id = em.meaning_id
WHERE em.expression_id = ?
ORDER BY em.created_at DESC;

-- 按语义查询词句（在 GET /api/v1/expressions 中使用，当 meaning_id 参数存在时）
SELECT DISTINCT e.*
FROM expressions e
JOIN expression_meaning em ON e.id = em.expression_id
WHERE em.meaning_id IN (?)
ORDER BY e.created_at DESC
LIMIT ? OFFSET ?;
```

### 2. 批量操作

- 扩展现有的 `POST /api/v1/expressions/batch` 接口，支持批量关联多个语义
- 使用批量插入语句减少数据库往返

**批量关联示例**：
```sql
-- 批量创建词句与语义的关联
INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at)
VALUES
  (?, ?, ?, CURRENT_TIMESTAMP),
  (?, ?, ?, CURRENT_TIMESTAMP);
```

### 3. 分页查询

- 词句列表接口已支持分页（`skip`, `limit` 参数）
- 语义关联的词句列表复用现有的分页机制

## 向后兼容性

### 1. 保留旧字段

- `expressions.meaning_id` 字段保留，但标记为 deprecated
- 在过渡期内，旧 API 继续使用该字段

### 2. 渐进式迁移

- 新功能使用新的多对多关系
- 旧功能逐步迁移到新的数据模型

### 3. 数据一致性

- 在迁移期间，确保新旧数据模型的一致性
- 定期检查和修复不一致的数据

### 4. API 兼容

```javascript
// 旧 API（保持兼容）
GET /api/v1/expressions/:id
// 返回 meaning_id（如果存在）

// 新 API
GET /api/v1/expressions/:id/meanings
// 返回所有语义的详细信息
```

## 实施步骤

### 阶段 1：数据库设计
- ✅ 编写设计文档
- ⏳ 编写迁移脚本（`scripts/025_meaning_mapping.sql`）
- ⏳ 在测试环境验证迁移脚本

### 阶段 2：后端实现
- ⏳ 扩展 DatabaseService，添加语义关联查询方法
- ⏳ 实现 `autoSelectMeaning` 方法：扩展现有的 `selectSemanticAnchor` 逻辑，支持多对多关系
- ⏳ 更新现有 API 路由：
  - `GET /api/v1/expressions/:expr_id`：增加 `meanings` 字段
  - `GET /api/v1/expressions`：增加 `include_meanings` 参数支持
- ⏳ 扩展 `POST /api/v1/expressions/batch`：实现自动决策逻辑
- ⏳ 新增 API 路由（高级功能）：
  - `POST /api/v1/expressions/:expr_id/meanings`
  - `DELETE /api/v1/expressions/:expr_id/meanings/:meaning_id`
- ⏳ 编写单元测试

### 阶段 3：前端实现
- ⏳ 扩展 Expression 详情页：展示和管理语义关联
- ⏳ 扩展 Expressions 列表页：支持语义筛选
- ⏳ 扩展批量提交功能：处理自动决策逻辑和展示结果
- ⏳ 更新 API Service 层

### 阶段 4：测试和优化
- ⏳ 集成测试
- ⏳ 性能测试和优化
- ⏳ 数据验证

### 阶段 5：部署和监控
- ⏳ 数据库迁移
- ⏳ 代码部署
- ⏳ 监控和错误跟踪

## 注意事项

1. **ID 生成策略**：meanings.id 使用第一个关联的 expression 的 id，确保数据一致性
2. **词句组概念**：前端通过"词句组"来体现语义，每个 meaning_id 对应一个词句组
3. **自动决策优先**：批量提交时优先使用自动决策逻辑，减少用户操作复杂度
4. **向后兼容**：保留 expressions.meaning_id 字段，确保现有功能不受影响
5. **性能影响**：多对多关系会增加查询复杂度，通过索引和缓存优化
6. **数据完整性**：确保外键约束和唯一性约束正确配置
7. **冲突处理**：自动选择新的 meaning 时，如果词句 ID 已作为 meaning_id 存在，则按语种优先级选择下一级词句
8. **前端体验**：用户无需理解"语义"的抽象概念，通过"词句组"的直观界面进行操作

## 自动决策逻辑详解

### 语种优先级

系统按照以下优先级选择词句组（meaning_id）：

```javascript
const LANGUAGE_PRIORITY = [
  'en-GB', 'en-US', 'zh-TW', 'zh-CN',
  'hi-IN', 'es-ES', 'fr-FR', 'ar-SA',
  'bn-IN', 'pt-BR', 'ru-RU', 'ur-PK',
  'id-ID', 'de-DE', 'ja-JP', 'ko-KR',
  'tr-TR', 'it-IT'
];
```

### 决策流程

```mermaid
graph TD
    A[批量提交词句] --> B{指定 meaning_id?}
    B -->|是| C[使用指定词句组]
    B -->|否| D[查询现有词句的词句组]
    D --> E{有词句组?}
    E -->|没有| F[按语种优先级选择第一个词句]
    F --> G[使用该词句 ID 创建新词句组]
    E -->|有| H{所有词句都属同一组?}
    H -->|是| I[使用现有的词句组]
    H -->|否| J[按语种优先级选择词句]
    J --> K{该词句 ID 已作为组ID?}
    K -->|否| L[使用该词句 ID 创建新词句组]
    K -->|是| M[选择下一级词句]
    M --> N{下一级词句 ID 已作为组ID?}
    N -->|否| L
    N -->|是| O[继续下一级，直到找到未使用的 ID]
    C --> P[所有词句关联到同一组]
    G --> P
    I --> P
    L --> P
    O --> L
```

### 与现有系统的集成

- **复用 `selectSemanticAnchor` 方法**：现有的 `/expressions/associate` 接口已经实现了类似的智能选择逻辑
- **扩展到 batch 场景**：将相同的决策逻辑应用到批量提交接口
- **保持一致性**：确保批量提交和单个关联的词句组选择策略一致

## 相关文档

- [数据库设计](./feat-database.md)
- [系统架构设计](../system/architecture.md)
- [后端 API 指南](../../api/backend-guide.md)
