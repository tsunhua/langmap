# 搜索功能设计

## System Reminder

**实现状态**：
- ✅ 后端搜索 API 已实现 - `GET /api/v1/search` + `searchExpressions()` 方法
- ✅ 前端搜索页面已实现 - `Search.vue`
- ✅ 性能优化 - 已集成 L2 边缘缓存 (TTL 1小时)
- ✅ 数据库查询支持 - LIKE 模糊匹配 + 复合索引优化
- ⏳ 高级搜索功能 - 未实现（全文检索、拼写纠正）
- ⏳ 搜索结果排序和过滤 - 部分实现

**已实现的 API 端点**：
- `GET /api/v1/search?q=...&from_lang=...&region=...&skip=...&limit=...` - 搜索表达式

**已实现的功能**：
- 基础搜索（关键词匹配）
- 按语言过滤
- 按地域过滤
- 分页支持

**未实现的功能**：
- 全文检索（Typesense/Elasticsearch）
- 拼写纠正
- 高级过滤（按来源类型、审核状态）
- 搜索历史
- 搜索建议/自动完成

---

## 概述

搜索功能是 LangMap 项目的核心功能之一，允许用户通过关键词检索表达式，并按语言和地域进行过滤。搜索功能支持模糊匹配，帮助用户找到相关的语言表达。

## 数据模型

### 搜索相关字段

搜索主要使用 `Expression` 表的现有字段：

```typescript
interface Expression {
  id: number
  text: string              // 主要搜索字段
  meaning_id?: number
  audio_url?: string
  language_code: string      // 按语言过滤
  region_code?: string       // 按地域过滤
  region_name?: string
  tags?: string            // JSON 数组，用于高级搜索
  source_type?: string      // 按来源类型过滤
  review_status?: string    // 按审核状态过滤
  created_by?: string
  created_at?: string
}
```

## API 设计

### GET /api/v1/search

搜索表达式，支持关键词匹配和多维度过滤。

**查询参数**：
- `q` (string) - 搜索关键词（必需）
- `from_lang` (string) - 源语言代码（可选）
- `region` (string) - 地域代码（可选）
- `skip` (number) - 跳过数量（默认 0）
- `limit` (number) - 返回数量限制（默认 20）

**响应**：
```json
{
  "results": [
    {
      "id": 1,
      "text": "Hello",
      "language_code": "en",
      "region_code": "US",
      "source_type": "user",
      "review_status": "approved",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 125,
  "skip": 0,
  "limit": 20
}
```

### 实现详情

后端使用简单的 LIKE 模糊匹配：

```typescript
async searchExpressions(query: string, fromLang?: string, region?: string, skip: number = 0, limit: number = 20): Promise<Expression[]> {
  let sql = 'SELECT * FROM expressions WHERE text LIKE ?'
  const params = [`%${query}%`]

  if (fromLang) {
    sql += ' AND language_code = ?'
    params.push(fromLang)
  }

  if (region) {
    sql += ' AND region_code = ?'
    params.push(region)
  }

  sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
  params.push(limit, skip)

  const { results } = await this.db.prepare(sql).bind(...params).all<Expression>()
  return results
}
```

## 前端实现

### Search.vue 页面

主要功能：
1. 搜索输入框
2. 语言选择器
3. 地域选择器
4. 搜索结果列表
5. 分页控件

**交互流程**：
1. 用户输入搜索关键词
2. 选择语言和地域（可选）
3. 点击搜索或按回车
4. 调用搜索 API
5. 显示搜索结果
6. 点击结果跳转到详情页

## 搜索策略

### 当前实现（简单匹配）

- **LIKE 模糊匹配**：使用 SQL LIKE `%query%` 进行匹配
- **多维度过滤**：支持按语言、地域过滤
- **分页支持**：使用 skip 和 limit 分页

### 未来改进计划

#### 1. 全文检索

引入 Typesense 或 Elasticsearch：

**优点**：
- 更快的搜索性能
- 支持拼写纠正
- 相关性排序
- 支持复杂查询（AND、OR、NOT）

**实施**：
```typescript
// Typesense 客户端示例
const searchResults = await client.collections('expressions').documents().search({
  q: query,
  query_by: 'text',
  filter_by: `language_code:${fromLang}, region_code:${region}`,
  page: 1,
  per_page: 20
})
```

#### 2. 拼写纠正

使用搜索引擎的拼写纠正功能，自动纠正用户输入的拼写错误。

#### 3. 高级过滤

添加更多过滤选项：
- 按来源类型过滤（authoritative/ai/user）
- 按审核状态过滤（approved/pending）
- 按时间范围过滤
- 按热度过滤（投票数）

#### 4. 搜索历史

- 记录用户的搜索历史
- 提供快速重新搜索
- 支持删除搜索历史

#### 5. 搜索建议/自动完成

- 根据用户输入提供实时搜索建议
- 使用前缀匹配
- 显示匹配的文本和数量

## 性能优化

### 当前优化

- **分页**：避免一次返回过多数据
- **边缘缓存**：集成 L2 缓存，TTL 1小时，针对相同搜索词实现秒开。
- **复合索引**：部署了 `idx_expressions_lang_text` 等索引，优化模糊查找后的排序开销。

### 未来优化

- **缓存**：缓存热门搜索词的结果
- **搜索服务**：使用 Typesense/Elasticsearch 提升性能
- **防抖**：前端搜索输入防抖，减少 API 调用

## 用户界面设计

### 搜索页面布局

```
┌─────────────────────────────────────────┐
│  Search Bar                           │
│  [Search Input]  [Lang]  [Region]    │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Search Results                       │
│  ┌──────────────────────────────────┐ │
│  │ Expression 1                   │ │
│  │ [Language] [Region] [Source]   │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Expression 2                   │ │
│  └──────────────────────────────────┘ │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Pagination                          │
│  [Previous] 1 2 3 ... 10 [Next]    │
└─────────────────────────────────────────┘
```

## 测试策略

### 单元测试
- 测试搜索表达式方法
- 测试过滤逻辑
- 测试分页逻辑

### 集成测试
- 测试搜索 API 端点
- 测试搜索参数验证
- 测试搜索结果格式

### 前端测试
- 测试搜索页面组件
- 测试搜索输入和过滤
- 测试分页交互

## 相关文档

- [系统架构设计](../system/architecture.md)
- [后端 API 指南](../../api/backend-guide.md)
