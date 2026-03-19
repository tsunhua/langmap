# Expression Group 抽象层设计

## System Reminder

**设计来源**：基于用户需求，在上层隐藏 meanings 和 expression_meanings 表，提供 ExpressionGroup 抽象概念

**实现状态**：
- ✅ 设计文档已完成
- ⏳ 等待实现

---

## 概述

当前系统中，`meanings` 表和 `expression_meaning` 表直接暴露给上层应用，导致概念不够直观。本设计旨在通过引入 `ExpressionGroup` 抽象概念，将底层的 meanings 和 expression_meaning 实现细节对上层隐藏，提供更清晰、更直观的接口。

## 设计目标

1. **概念抽象化**：用 `ExpressionGroup`（词句组）概念替代 `meaning`，更贴近用户理解
2. **实现细节隐藏**：对上层隐藏 meanings 和 expression_meaning 表的存在
3. **接口统一**：原先接口中的 `meaning_id` 改为 `group_id`，但底层表结构不变
4. **向后兼容**：确保现有数据和 API 的兼容性

## 核心概念

### ExpressionGroup（词句组）

`ExpressionGroup` 是 `meaning` 的抽象层概念，表示一组共享相同语义的词句集合。

| 概念 | 上层视角 | 底层实现 |
|------|----------|----------|
| 词句组 | ExpressionGroup | meanings 表 + expression_meaning 表 |
| 词句组 ID | group_id | meanings.id |
| 组内词句 | group expressions | 通过 expression_meaning 表关联的 expressions |

**设计优势**：

1. **概念清晰**：ExpressionGroup 比抽象的 meaning 更直观
2. **操作简单**：用户操作的是"词句组"，而不是底层的多对多关系
3. **封装性**：底层表结构的变化不会影响上层代码
4. **灵活性**：未来可以替换底层实现而不改变接口

## 数据库接口设计

### ExpressionGroup 类型定义

```typescript
// backend/src/server/db/protocol.ts

export interface ExpressionGroup {
  id: number                        // 对应 meanings.id
  expressions: Expression[]         // 组内的所有词句
  created_by?: string
  created_at?: string
}
```

### ExpressionGroup 查询接口

**文件位置**：`backend/src/server/db/queries/expression_group.ts`

```typescript
import { D1Database } from '@cloudflare/workers-types'
import { Expression, ExpressionGroup, ExpressionGroupInfo } from '../protocol.js'

export class ExpressionGroupQueries {
  constructor(private db: D1Database) {}

  /**
   * 通过 group_id 查询组内的所有 expressions
   * @param groupId 词句组 ID
   * @param languages 语言过滤列表（可选），例如 ['zh-CN', 'en-US']
   * @returns 该组的所有词句（可按语言过滤）
   */
  async getGroupExpressions(groupId: number, languages?: string[]): Promise<Expression[]> {
    let sql = `
      SELECT e.*
      FROM expressions e
      JOIN expression_meaning em ON e.id = em.expression_id
      WHERE em.meaning_id = ?
    `
    const bindParams: (number | string)[] = [groupId]

    if (languages && languages.length > 0) {
      sql += ` AND e.language_code IN (${languages.map(() => '?').join(',')})`
      bindParams.push(...languages)
    }

    sql += ' ORDER BY e.created_at DESC'

    const stmt = this.db.prepare(sql)
    const { results } = await stmt.bind(...bindParams).all<Expression>()

    return results || []
  }

  /**
   * 获取词句组信息
   * @param groupId 词句组 ID
   * @param languages 语言过滤列表（可选），例如 ['zh-CN', 'en-US']
   * @returns 词句组（可按语言过滤）
   */
  async getGroupInfo(groupId: number, languages?: string[]): Promise<ExpressionGroup | null> {
    const meaningResult = await this.db.prepare(`
      SELECT id, created_by, created_at
      FROM meanings
      WHERE id = ?
    `).bind(groupId).first<{ id: number, created_by?: string, created_at?: string }>()

    if (!meaningResult) {
      return null
    }

    const expressions = await this.getGroupExpressions(groupId, languages)

    return {
      id: meaningResult.id,
      expressions,
      created_by: meaningResult.created_by,
      created_at: meaningResult.created_at
    }
  }

  /**
   * 获取词句所属的所有词句组
   * @param expressionId 词句 ID
   * @returns 该词句所属的所有词句组
   */
  async getExpressionGroups(expressionId: number): Promise<ExpressionGroup[]> {
    const { results } = await this.db.prepare(`
      SELECT
        m.id,
        m.created_by,
        m.created_at
      FROM meanings m
      JOIN expression_meaning em ON m.id = em.meaning_id
      WHERE em.expression_id = ?
      ORDER BY em.created_at DESC
    `).bind(expressionId).all<{ id: number, created_by?: string, created_at?: string }>()

    if (!results || results.length === 0) {
      return []
    }

    // 为每个组加载词句列表
    const groups: ExpressionGroup[] = []
    for (const result of results) {
      const expressions = await this.getGroupExpressions(result.id)
      groups.push({
        id: result.id,
        expressions,
        created_by: result.created_by,
        created_at: result.created_at
      })
    }

    return groups
  }

  /**
   * 将词句加入词句组
   * @param expressionId 词句 ID
   * @param groupId 词句组 ID
   * @param username 操作用户
   * @returns 操作是否成功
   */
  async addToGroup(expressionId: number, groupId: number, username: string): Promise<boolean> {
    const now = new Date().toISOString()

    // 确保 meaning 存在
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    // 添加关联
    const result = await this.db.prepare(
      'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${expressionId}-${groupId}`, expressionId, groupId, now).run()

    return (result.meta?.changes ?? 0) > 0
  }

  /**
   * 将词句从词句组移除
   * @param expressionId 词句 ID
   * @param groupId 词句组 ID
   * @returns 操作是否成功
   */
  async removeFromGroup(expressionId: number, groupId: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM expression_meaning WHERE expression_id = ? AND meaning_id = ?'
    ).bind(expressionId, groupId).run()

    return (result.meta?.changes ?? 0) > 0
  }

  /**
   * 创建新的词句组
   * @param anchorExpressionId 作为锚点的词句 ID（将作为 group_id）
   * @param username 操作用户
   * @returns 创建的词句组 ID
   */
  async createGroup(anchorExpressionId: number, username: string): Promise<number> {
    const now = new Date().toISOString()
    const groupId = anchorExpressionId

    // 创建 meaning 记录
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    // 将锚点词句加入组
    await this.addToGroup(anchorExpressionId, groupId, username)

    return groupId
  }

  /**
   * 批量将词句加入词句组
   * @param expressionIds 词句 ID 列表
   * @param groupId 词句组 ID
   * @param username 操作用户
   * @returns 成功加入的数量
   */
  async batchAddToGroup(expressionIds: number[], groupId: number, username: string): Promise<number> {
    const now = new Date().toISOString()

    // 确保 meaning 存在
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    // 批量添加关联
    const statements = expressionIds.map(exprId =>
      this.db.prepare(
        'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${exprId}-${groupId}`, exprId, groupId, now)
    )

    const batchResult = await this.db.batch(statements)

    // 计算成功数量
    return batchResult.reduce((sum, result) => sum + (result.meta?.changes ?? 0), 0)
  }

  /**
   * 合并词句组
   * @param sourceGroupId 源词句组 ID
   * @param targetGroupId 目标词句组 ID
   * @returns 合并的词句数量
   */
  async mergeGroups(sourceGroupId: number, targetGroupId: number): Promise<{ success: boolean, merged_count: number }> {
    const expressionsResult = await this.db.prepare(
      'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceGroupId).all<{ expression_id: number }>()

    if (!expressionsResult.results || expressionsResult.results.length === 0) {
      // 仍然删除空的源词句组
      await this.deleteGroup(sourceGroupId)
      return { success: true, merged_count: 0 }
    }

    const now = new Date().toISOString()
    const insertStatements = expressionsResult.results.map(e =>
      this.db.prepare(
        'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${e.expression_id}-${targetGroupId}`, e.expression_id, targetGroupId, now)
    )

    const deleteExpressionMeaningStmt = this.db.prepare(
      'DELETE FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceGroupId)

    const deleteMeaningStmt = this.db.prepare(
      'DELETE FROM meanings WHERE id = ?'
    ).bind(sourceGroupId)

    await this.db.batch([...insertStatements, deleteExpressionMeaningStmt, deleteMeaningStmt])

    return {
      success: true,
      merged_count: expressionsResult.results.length
    }
  }

  /**
   * 删除词句组
   * @param groupId 词句组 ID
   * @returns 操作是否成功
   */
  async deleteGroup(groupId: number): Promise<boolean> {
    const deleteExpressionMeaningStmt = this.db.prepare(
      'DELETE FROM expression_meaning WHERE meaning_id = ?'
    ).bind(groupId)

    const deleteMeaningStmt = this.db.prepare(
      'DELETE FROM meanings WHERE id = ?'
    ).bind(groupId)

    await this.db.batch([deleteExpressionMeaningStmt, deleteMeaningStmt])

    return true
  }

  /**
   * 获取所有词句组列表
   * @param skip 跳过数量
   * @param limit 限制数量
   * @param languages 语言过滤列表（可选），例如 ['zh-CN', 'en-US']
   * @returns 词句组列表（可按语言过滤）
   */
  async listGroups(skip: number = 0, limit: number = 20, languages?: string[]): Promise<ExpressionGroup[]> {
    const { results } = await this.db.prepare(`
      SELECT id, created_by, created_at
      FROM meanings
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `).bind(limit, skip).all<{ id: number, created_by?: string, created_at?: string }>()

    if (!results || results.length === 0) {
      return []
    }

    const groups: ExpressionGroup[] = []
    for (const result of results) {
      const expressions = await this.getGroupExpressions(result.id, languages)
      groups.push({
        id: result.id,
        expressions,
        created_by: result.created_by,
        created_at: result.created_at
      })
    }

    return groups
  }

  /**
   * 搜索词句组（通过组内词句文本）
   * @param query 搜索关键词
   * @param skip 跳过数量
   * @param limit 限制数量
   * @param languages 语言过滤列表（可选），例如 ['zh-CN', 'en-US']
   * @returns 匹配的词句组列表（可按语言过滤）
   */
  async searchGroups(query: string, skip: number = 0, limit: number = 20, languages?: string[]): Promise<ExpressionGroup[]> {
    let sql = `
      SELECT DISTINCT
        m.id,
        m.created_by,
        m.created_at
      FROM meanings m
      JOIN expression_meaning em ON m.id = em.meaning_id
      JOIN expressions e ON em.expression_id = e.id
      WHERE e.text LIKE ?
    `
    const bindParams: (string | number)[] = [`%${query}%`]

    if (languages && languages.length > 0) {
      sql += ` AND e.language_code IN (${languages.map(() => '?').join(',')})`
      bindParams.push(...languages)
    }

    sql += ' ORDER BY m.created_at DESC LIMIT ? OFFSET ?'
    bindParams.push(limit, skip)

    const stmt = this.db.prepare(sql)
    const { results } = await stmt.bind(...bindParams).all<{ id: number, created_by?: string, created_at?: string }>()

    if (!results || results.length === 0) {
      return []
    }

    const groups: ExpressionGroup[] = []
    for (const result of results) {
      const expressions = await this.getGroupExpressions(result.id, languages)
      groups.push({
        id: result.id,
        expressions,
        created_by: result.created_by,
        created_at: result.created_at
      })
    }

    return groups
  }
}
```

## DatabaseService 扩展

### 添加 ExpressionGroup 查询对象

```typescript
// backend/src/server/db/protocol.ts

// 在 AbstractDatabaseService 中添加
export abstract class AbstractDatabaseService {
  // ... 现有方法 ...

  // ExpressionGroup operations
  abstract getGroupExpressions(groupId: number): Promise<Expression[]>
  abstract getGroupInfo(groupId: number): Promise<ExpressionGroup | null>
  abstract getExpressionGroups(expressionId: number): Promise<ExpressionGroup[]>
  abstract addToGroup(expressionId: number, groupId: number, username: string): Promise<boolean>
  abstract removeFromGroup(expressionId: number, groupId: number): Promise<boolean>
  abstract createGroup(anchorExpressionId: number, username: string): Promise<number>
  abstract batchAddToGroup(expressionIds: number[], groupId: number, username: string): Promise<number>
  abstract mergeGroups(sourceGroupId: number, targetGroupId: number): Promise<{ success: boolean, merged_count: number }>
  abstract deleteGroup(groupId: number): Promise<boolean>
  abstract listGroups(skip?: number, limit?: number): Promise<ExpressionGroup[]>
  abstract searchGroups(query: string, skip?: number, limit?: number): Promise<ExpressionGroup[]>

  // Query objects for direct access
  abstract get expressions(): any
  abstract get users(): any
  abstract get collections(): any
  abstract get meanings(): any
  abstract get languages(): any
  abstract get handbooks(): any
  abstract get groups(): any  // 新增
}
```

## API 设计调整

### 后端路由改造

#### 1. expressions.ts 路由调整

**文件**: `backend/src/server/routes/expressions.ts`

**需要调整的端点**:

| 端点 | 旧实现 | 新实现 | 说明 |
|------|--------|--------|------|
| GET /expressions | `meaning_id` 参数 | 支持 `group_id` 参数（兼容 `meaning_id`） | 查询特定词句组的词句 |
| GET /expressions | 无 `lang` 参数 | 支持 `lang` 参数 | 语言过滤 |
| POST /expressions | `meaning_id` 字段 | 支持 `group_id` 字段 | 创建词句时指定组 |
| POST /expressions/batch | `ensure_new_meaning` | 支持的 `ensure_new_group` | 批量提交时指定组 |
| POST /expressions/associate | 直接操作 meanings | 调用 expressionGroup | 关联词句到组 |
| GET /expressions/:id | 返回 `meanings` | 返回 `groups` | 词句所属的词句组列表 |
| POST /expressions/:id/meanings | 添加 meaning | 迁移到 groups 路由 | 改用 addToGroup |
| DELETE /expressions/:id/meanings/:id | 删除 meaning | 迁移到 groups 路由 | 改用 removeFromGroup |

**具体改造方案**:

```typescript
// 1. GET /expressions - 支持 group_id 参数
expressionsRoutes.get('/', async (c) => {
  const meaningIdParam = c.req.query('meaning_id')  // 旧参数，向后兼容
  const groupIdParam = c.req.query('group_id')       // 新参数
  const langParam = c.req.query('lang')              // 新参数，语言过滤

  // 优先使用 group_id，如果没有则使用 meaning_id（兼容）
  const groupId = groupIdParam ? parseInt(groupIdParam) :
                 meaningIdParam ? parseInt(meaningIdParam) : undefined

  // 解析语言过滤
  const languages = langParam ? langParam.split(',').map(l => l.trim()) : undefined

  // 查询逻辑保持不变，只是参数来源变化
})

// 2. POST /expressions/batch - 支持的 ensure_new_group
const { expressions, ensure_new_meaning, ensure_new_group } = validated
const forceNewGroup = ensure_new_group === true || ensure_new_meaning === true

// 返回结果中使用 group_id
return created(c, { group_id: finalGroupId, results })

// 3. POST /expressions/associate - 使用 ExpressionGroup
expressionsRoutes.post('/associate', requireAuth, async (c) => {
  const { expression_ids } = body

  // 使用 expressionGroup 批量添加
  const anchorId = expression_ids[0]
  const user = c.get('user')
  const groupId = await db.groups.createGroup(anchorId, user.username)

  // 批量添加其余词句
  await db.groups.batchAddToGroup(expression_ids.slice(1), groupId, user.username)

  return success(c, { group_id: groupId, updated_count: expression_ids.length })
})

// 4. GET /expressions/:id - 返回 groups
const expression = await service.getById(exprId)

// 替换 meanings 为 groups
if (includeMeanings) {
  expression.groups = await db.groups.getExpressionGroups(exprId)
}
```

#### 2. 新增 expressionGroup.ts 路由

**文件**: `backend/src/server/routes/expressionGroup.ts`

**实现的端点**:

| 端点 | 方法 | 说明 |
|------|------|------|
| GET /api/v1/groups | listGroups | 列出所有词句组（支持分页和语言过滤） |
| GET /api/v1/groups/:id | getGroupInfo | 获取单个词句组详情（支持语言过滤） |
| GET /api/v1/groups/search | searchGroups | 搜索词句组（支持语言过滤） |
| POST /api/v1/groups | createGroup | 创建新词句组 |
| POST /api/v1/groups/:id/expressions | addToGroup | 添加词句到组 |
| DELETE /api/v1/groups/:id/expressions/:expressionId | removeFromGroup | 从组中移除词句 |
| POST /api/v1/groups/:id/merge | mergeGroups | 合并词句组 |
| DELETE /api/v1/groups/:id | deleteGroup | 删除词句组 |
| GET /api/v1/expressions/:id/groups | getExpressionGroups | 获取词句所属的所有组 |

**语言过滤实现**:

```typescript
// 所有 GET 端点都支持 lang 参数
const langParam = c.req.query('lang')
const languages = langParam ? langParam.split(',').map(l => l.trim()) : undefined

// 查询时传入 languages 参数
const group = await db.groups.getGroupInfo(groupId, languages)
```

### 前端 API 改造

#### 1. expressions.ts 调整

**文件**: `web/src/api/expressions.ts`

**需要迁移到 expressionGroups.ts 的方法**:

| 方法 | 原位置 | 新位置 | 改名 |
|------|--------|--------|------|
| associate() | expressions.ts | expressionGroups.ts | linkExpressions() |
| addMeaning() | expressions.ts | expressionGroups.ts | addToGroup() |
| removeMeaning() | expressions.ts | expressionGroups.ts | removeFromGroup() |

**需要调整的类型定义**:

```typescript
// 替换 meaning_id 为 group_id
export interface CreateExpressionData {
  text: string
  language_code: string
  group_id?: number              // 原为 meaning_id
  audio_url?: string
}

export interface UpdateExpressionData {
  text?: string
  language_code?: string
  group_id?: number              // 原为 meaning_id
  audio_url?: string
}

export interface BatchExpressionData {
  expressions: Array<{
    text: string
    language_code: string
    group_id?: number           // 原为 meaning_id
  }>
  ensure_new_group?: boolean    // 原为 ensure_new_meaning
}

export interface BatchResponse {
  group_id: number               // 原为 meaning_id
  results: any[]
}
```

**需要调整的方法**:

```typescript
// 1. getAll() - 支持 groupId 和 languages 过滤
async getAll(filters: ExpressionFilters = {}): Promise<PaginatedResponse<Expression>> {
  const params = new URLSearchParams()

  if (filters.skip !== undefined) params.append('skip', filters.skip.toString())
  if (filters.limit !== undefined) params.append('limit', filters.limit.toString())
  if (filters.language) params.append('language', filters.language)

  // 支持 groupId（替换 meaningId）
  if (filters.groupId !== undefined) {
    if (Array.isArray(filters.groupId)) {
      params.append('group_id', filters.groupId.join(','))
    } else {
      params.append('group_id', filters.groupId.toString())
    }
  } else if (filters.meaningId !== undefined) {
    // 向后兼容：仍然支持 meaningId，但内部转换为 groupId
    if (Array.isArray(filters.meaningId)) {
      params.append('group_id', filters.meaningId.join(','))
    } else {
      params.append('group_id', filters.meaningId.toString())
    }
  }

  // 支持语言过滤
  if (filters.languages) {
    params.append('lang', filters.languages.join(','))
  }

  // ... 其他参数
}

// 2. batch() - 支持的 ensure_new_group
async batch(data: BatchExpressionData): Promise<ApiResponse<BatchResponse>> {
  // 支持 ensure_new_group（向后兼容 ensure_new_meaning）
  const ensureNewGroup = data.ensure_new_group ?? data.ensure_new_meaning

  const requestData = {
    ...data,
    ensure_new_group: ensureNewGroup
  }

  const response = await apiClient.post('/expressions/batch', requestData)
  return response.data as ApiResponse<BatchResponse>
}

// 3. getById() - 返回 groups 而不是 meanings
async getById(id: number, includeGroups = false): Promise<ApiResponse<Expression>> {
  const params = includeGroups ? { include_meanings: 'true' } : {}
  const response = await apiClient.get(`/expressions/${id}`, { params })
  const data = response.data as ApiResponse<Expression>

  // 转换 meanings 为 groups（如果是旧响应）
  if (data.data.meanings && !data.data.groups) {
    data.data.groups = data.data.meanings
    delete data.data.meanings
  }

  return data
}
```

#### 2. 新增 expressionGroups.ts

**文件**: `web/src/api/expressionGroups.ts`

**实现所有 ExpressionGroup 相关的 API**:

```typescript
import apiClient from './client.js'
import type { ExpressionGroup, ExpressionFilters } from '../types/models.js'

export interface CreateGroupData {
  anchor_expression_id: number
}

export interface MergeGroupsData {
  source_group_id: number
}

export interface AddToGroupData {
  expression_id: number
}

export const expressionGroupsApi = {
  // 获取单个词句组
  async getGroup(id: number, languages?: string[]): Promise<ApiResponse<ExpressionGroup>> {
    const params = languages ? { lang: languages.join(',') } : {}
    const response = await apiClient.get(`/groups/${id}`, { params })
    return response.data as ApiResponse<ExpressionGroup>
  },

  // 列出所有词句组
  async listGroups(
    skip: number = 0,
    limit: number = 20,
    languages?: string[]
  ): Promise<ApiResponse<{ items: ExpressionGroup[], total: number }>> {
    const params: any = { skip, limit }
    if (languages) {
      params.lang = languages.join(',')
    }
    const response = await apiClient.get('/groups', { params })
    return response.data as ApiResponse<{ items: ExpressionGroup[], total: number }>
  },

  // 搜索词句组
  async searchGroups(
    query: string,
    skip: number = 0,
    limit: number = 20,
    languages?: string[]
  ): Promise<ApiResponse<ExpressionGroup[]>> {
    const params: any = { q: query, skip, limit }
    if (languages) {
      params.lang = languages.join(',')
    }
    const response = await apiClient.get('/groups/search', { params })
    return response.data as ApiResponse<ExpressionGroup[]>
  },

  // 创建新词句组
  async createGroup(data: CreateGroupData): Promise<ApiResponse<ExpressionGroup>> {
    const response = await apiClient.post('/groups', data)
    return response.data as ApiResponse<ExpressionGroup>
  },

  // 添加词句到组
  async addToGroup(groupId: number, data: AddToGroupData): Promise<ApiResponse<null>> {
    const response = await apiClient.post(`/groups/${groupId}/expressions`, data)
    return response.data as ApiResponse<null>
  },

  // 从组中移除词句
  async removeFromGroup(groupId: number, expressionId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/groups/${groupId}/expressions/${expressionId}`)
    return response.data as ApiResponse<null>
  },

  // 合并词句组
  async mergeGroups(targetGroupId: number, data: MergeGroupsData): Promise<ApiResponse<any>> {
    const response = await apiClient.post(`/groups/${targetGroupId}/merge`, data)
    return response.data as ApiResponse<any>
  },

  // 删除词句组
  async deleteGroup(groupId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/groups/${groupId}`)
    return response.data as ApiResponse<null>
  },

  // 获取词句所属的所有组
  async getExpressionGroups(expressionId: number): Promise<ApiResponse<ExpressionGroup[]>> {
    const response = await apiClient.get(`/expressions/${expressionId}/groups`)
    return response.data as ApiResponse<ExpressionGroup[]>
  },

  // 批量关联词句到组（替代 associate）
  async linkExpressions(expressionIds: number[]): Promise<ApiResponse<{ group_id: number; updated_count: number }>> {
    const response = await apiClient.post('/expressions/associate', { expression_ids: expressionIds })
    const data = response.data as ApiResponse<{ meaning_id: number; updated_count: number }>
    // 转换响应格式
    return {
      ...data,
      data: {
        group_id: data.data.meaning_id,
        updated_count: data.data.updated_count
      }
    }
  }
}
```

### API 参数变更

| 接口 | 旧参数 | 新参数 | 说明 |
|------|--------|--------|------|
| GET /api/v1/expressions | `meaning_id` | `group_id` | 查询特定词句组的词句 |
| GET /api/v1/expressions | 无 | `lang` | 语言过滤，如 `?lang=zh-CN,en-US` |
| POST /api/v1/expressions/batch | `meaning_id` | `group_id` | 批量提交时指定词句组 |
| GET /api/v1/expressions/:expr_id | 返回 `meanings` | 返回 `groups` | 词句所属的词句组列表 |
| GET /api/v1/groups | 无 | `lang` | 语言过滤，如 `?lang=zh-CN,en-US` |
| GET /api/v1/groups/:id | 无 | `lang` | 语言过滤，如 `?lang=zh-CN,en-US` |
| GET /api/v1/groups/search | 无 | `lang` | 语言过滤，如 `?lang=zh-CN,en-US` |

### 示例 API 调用

```javascript
// 获取词句组的所有词句
GET /api/v1/expressions?group_id=456&skip=0&limit=20

// 获取词句组的所有词句（仅中文和英文）
GET /api/v1/expressions?group_id=456&lang=zh-CN,en-US&skip=0&limit=20

// 批量提交词句到指定词句组
POST /api/v1/expressions/batch
{
  "group_id": 456,
  "expressions": [...]
}

// 获取词句所属的词句组
GET /api/v1/expressions/123
Response:
{
  "id": 123,
  "text": "hello",
  "language_code": "en-US",
  "groups": [
    {
      "id": 456,
      "expressions": [...],
      "created_by": "user123",
      "created_at": "2026-03-19T00:00:00Z"
    }
  ]
}
```

### 语言过滤功能

支持通过 `lang` 参数过滤词句组内的词句语言：

| API | 参数 | 说明 |
|-----|------|------|
| GET /api/v1/groups/:id | `?lang=zh-CN,en-US` | 返回指定语言的词句 |
| GET /api/v1/groups | `?lang=zh-CN,en-US` | 所有组只返回指定语言的词句 |
| GET /api/v1/groups/search | `?lang=zh-CN,en-US` | 搜索结果只包含指定语言的词句 |

**语言参数格式**：
- 单个语言：`?lang=zh-CN`
- 多个语言：`?lang=zh-CN,en-US,en-GB`（逗号分隔）
- 不指定：返回所有语言

**实现示例**：
```typescript
// 后端实现
const langParam = c.req.query('lang')
const languages = langParam ? langParam.split(',') : undefined

// 获取词句组（带语言过滤）
const group = await db.getGroupInfo(groupId, languages)
// 只返回 zh-CN 和 en-US 的词句

// 列出所有词句组（带语言过滤）
const groups = await db.listGroups(skip, limit, languages)
// 所有组只返回 zh-CN 和 en-US 的词句
```

## 迁移策略

### 阶段 1：并行运行（当前阶段）

- ✅ 新的 ExpressionGroup API 已就绪
- ✅ 现有的 meaning 相关 API 继续运行
- ⏳ 新旧 API 同时存在，互不干扰

**开发者可以开始使用新 API**:

```typescript
// 推荐：使用新的 ExpressionGroup API
import { expressionGroupsApi } from '@/api/expressionGroups'

const group = await expressionGroupsApi.getGroup(123, ['zh-CN', 'en-US'])
const groups = await expressionGroupsApi.listGroups(0, 20)

// 兼容：旧的 API 继续工作
import { expressionsApi } from '@/api/expressions'

const expressions = await expressionsApi.getAll({ meaningId: 123 })
```

### 阶段 2：渐进式迁移

前端逐步从旧 API 迁移到新 API：

**迁移顺序建议**:
1. **只读操作优先** - 先迁移查询和显示相关组件
2. **修改操作跟进** - 再迁移添加、更新、删除操作
3. **批量操作最后** - 最后处理复杂的批量操作

**迁移示例**:

```typescript
// 旧代码
const expressions = await expressionsApi.getAll({ meaningId: 123 })
const groups = expression.meanings

// 新代码
const expressions = await expressionsApi.getAll({ groupId: 123 })
const groups = await expressionGroupsApi.getExpressionGroups(expressionId)
```

### 阶段 3：完全切换

- 所有前端组件迁移完成
- 旧的 meaning_id 参数标记为 deprecated
- 添加警告日志，提醒开发者使用新 API

```typescript
// 后端警告示例
if (meaningIdParam) {
  console.warn('[DEPRECATED] meaning_id parameter is deprecated. Use group_id instead.')
  // 继续处理以保持兼容
}
```

### 阶段 4：清理

- 移除所有 meaning_id 相关代码
- 移除 deprecated 警告
- 文档完全更新为新的概念

## 向后兼容性

### 1. 内部实现保持不变

- meanings 表和 expression_meaning 表结构不变
- 只是在上层接口和类型定义中隐藏这些细节
- ExpressionGroup 作为封装层，底层仍使用 meanings 和 expression_meaning

### 2. 迁移策略

```typescript
// 后端可以同时支持新旧参数
async function getExpressions(params: {
  meaningId?: number | number[]  // 旧参数，兼容
  groupId?: number | number[]     // 新参数
}): Promise<Expression[]> {
  const groupId = params.groupId || params.meaningId
  // 使用 groupId 查询
}

// 前端逐步迁移
// 阶段1：继续使用 meaningId
await fetch('/api/v1/expressions?meaningId=456')

// 阶段2：切换到 groupId
await fetch('/api/v1/expressions?groupId=456')
```

### 3. 数据一致性

确保 meanings 表和 ExpressionGroup 的数据一一对应：
```typescript
// meanings.id === ExpressionGroup.id
// expression_meaning.meaning_id === ExpressionGroup.id
```

## 使用示例

### 1. 获取词句组（带语言过滤）

```typescript
// 获取词句组 456 的所有词句
const allExpressions = await db.getGroupExpressions(456)
// 返回：[en, zh-CN, ja-JP, fr-FR, ...]

// 获取词句组 456 的中文和英文词句
const filteredExpressions = await db.getGroupExpressions(456, ['zh-CN', 'en-US'])
// 返回：[zh-CN, en-US]

// 获取完整词句组信息（带语言过滤）
const groupInfo = await db.getGroupInfo(456, ['zh-CN', 'en-US'])
// 返回：{ id: 456, expressions: [zh-CN词句, en-US词句], ... }
```

### 2. 列出词句组（带语言过滤）

```typescript
// 列出前 20 个词句组（所有语言）
const allGroups = await db.listGroups(0, 20)
// 每个组包含所有语言的词句

// 列出前 20 个词句组（仅中文和英文）
const filteredGroups = await db.listGroups(0, 20, ['zh-CN', 'en-US'])
// 每个组只包含 zh-CN 和 en-US 的词句
```

### 3. 搜索词句组（带语言过滤）

```typescript
// 搜索包含 "hello" 的词句组（所有语言）
const searchResults = await db.searchGroups('hello', 0, 20)

// 搜索包含 "hello" 的词句组（仅中文和英文）
const filteredSearchResults = await db.searchGroups('hello', 0, 20, ['zh-CN', 'en-US'])
// 结果中的词句组只包含 zh-CN 和 en-US 的词句
```

### 4. API 调用示例

```javascript
// 获取词句组 456 的所有词句
fetch('/api/v1/groups/456')
// 返回所有语言的词句

// 获取词句组 456 的中文和英文词句
fetch('/api/v1/groups/456?lang=zh-CN,en-US')
// 只返回中文和英文的词句

// 列出词句组（所有语言）
fetch('/api/v1/groups')
// 返回所有词句组，每组包含所有语言的词句

// 列出词句组（仅中文和英文）
fetch('/api/v1/groups?lang=zh-CN,en-US')
// 返回所有词句组，每组只包含中文和英文的词句

// 搜索词句组（所有语言）
fetch('/api/v1/groups/search?q=hello')
// 返回匹配的词句组，每组包含所有语言的词句

// 搜索词句组（仅中文和英文）
fetch('/api/v1/groups/search?q=hello&lang=zh-CN,en-US')
// 返回匹配的词句组，每组只包含中文和英文的词句
```

## 前端影响

### 类型定义更新

```typescript
// web/src/types/models.ts
export interface ExpressionGroup {
  id: number
  expressions: Expression[]
  created_by?: string
  created_at?: string
}

export interface Expression {
  id: number
  text: string
  language_code: string
  group_id?: number              // 替代 meaning_id
  groups?: ExpressionGroup[]      // 替代 meanings
  audio_url?: string | Array<{ url: string; speaker: string }>
  tags?: string
  created_by?: string
  created_at?: string
  updated_by?: string
  updated_at?: string
  // ... 其他字段
}

export interface ExpressionFilters {
  skip?: number
  limit?: number
  language?: string
  groupId?: number | number[]      // 替代 meaningId
  meaningId?: number | number[]    // 向后兼容
  tagPrefix?: string
  excludeTagPrefix?: string
  includeMeanings?: boolean
  languages?: string[]            // 新增：语言过滤
}
```

### API 客户端结构

```typescript
// web/src/api/
├── client.ts                      // HTTP 客户端
├── expressions.ts                 // 表达式 API（调整后）
├── expressionGroups.ts           // 词句组 API（新增）
├── auth.ts
├── languages.ts
├── collections.ts
└── ...
```

```typescript
// web/src/types/models.ts
export interface ExpressionGroup {
  id: number
  expressions: Expression[]
  created_by?: string
  created_at?: string
}

export interface Expression {
  id: number
  text: string
  language_code: string
  group_id?: number              // 替代 meaning_id
  groups?: ExpressionGroup[]      // 替代 meanings
  // ... 其他字段
}
```

### 组件更新

词句详情页和词句组弹窗中的概念从 `meaning` 更新为 `group`：

```typescript
// 词句详情页
const groups = await fetch(`/api/v1/expressions/${expressionId}`)
groups.forEach(group => {
  renderExpressionGroup({
    groupId: group.id,
    expressions: group.expressions
  })
})

// 加入词句组
await fetch(`/api/v1/expressions/${expressionId}/groups`, {
  method: 'POST',
  body: JSON.stringify({ group_id: targetGroupId })
})
```

## 实施步骤

### 阶段 1：类型定义和接口设计
- ✅ 编写设计文档
- ✅ 定义 ExpressionGroup 类型
- ✅ 实现 ExpressionGroupQueries 类
- ✅ 扩展 AbstractDatabaseService 接口

### 阶段 2：后端实现
- ✅ 在 DatabaseService 中实现 ExpressionGroup 方法
- ✅ 创建 expressionGroup.ts 路由
- ✅ 集成 expressionGroup.ts 到主路由
- ⏳ 更新 expressions.ts 路由，支持 group_id 参数
- ⏳ 保持 meaning_id 参数的向后兼容
- ⏳ 编写单元测试

### 阶段 3：前端适配
- ⏳ 更新前端类型定义（Expression、ExpressionFilters 等）
- ⏳ 创建 expressionGroups.ts API 客户端
- ⏳ 更新 expressions.ts API 客户端
- ⏳ 更新词句详情页组件（groups 替代 meanings）
- ⏳ 更新词句组弹窗组件
- ⏳ 更新使用 meaning_id 的所有组件

### 阶段 4：文档和测试
- ⏳ 更新 API 文档
- ⏳ 更新前端开发文档
- ⏳ 进行集成测试

### 阶段 5：清理和优化
- ⏳ 逐步废弃 meaning_id 参数（设置 deprecated 标记）
- ⏳ 监控 API 使用情况
- ⏳ 性能优化

## 注意事项

1. **概念一致性**：确保整个系统都使用 ExpressionGroup 概念，不再向上层暴露 meaning
2. **类型安全**：TypeScript 类型定义要完整，避免 any 类型
3. **文档同步**：更新所有相关文档，确保概念统一
4. **测试覆盖**：为 ExpressionGroup 接口编写完整的单元测试
5. **性能考虑**：批量操作使用事务，减少数据库往返
6. **错误处理**：提供清晰的错误信息，帮助开发者调试
7. **渐进式迁移**：保持向后兼容，给前端足够的时间迁移

## 相关文档

- [词句与语义多对多关系设计](./feat-meaning-mapping.md)
- [数据库设计](./feat-database.md)
- [系统架构设计](../system/architecture.md)
- [后端 API 指南](../../api/backend-guide.md)

## 设计优势总结

1. **更好的抽象**：ExpressionGroup 比 meaning 更直观，用户更容易理解
2. **封装实现**：上层不需要知道 meanings 和 expression_meaning 表的存在
3. **易于维护**：未来可以优化底层实现而不影响上层代码
4. **概念统一**：整个系统使用统一的词句组概念
5. **向后兼容**：通过参数别名保持兼容性，降低迁移成本

## 当前进度

### 已完成 ✅

1. **设计文档**
   - ✅ 创建完整的设计文档（本文档）
   - ✅ 更新功能导航和主设计 README

2. **类型定义和数据库层**
   - ✅ 在 `protocol.ts` 中定义 ExpressionGroup 接口
   - ✅ 实现 `ExpressionGroupQueries` 类（`backend/src/server/db/queries/expression_group.ts`）
   - ✅ 在 `AbstractDatabaseService` 中添加 ExpressionGroup 抽象方法
   - ✅ 在 `D1DatabaseService` 中实现所有 ExpressionGroup 方法

3. **后端 API 路由**
   - ✅ 创建 `expressionGroup.ts` 路由（`backend/src/server/routes/expressionGroup.ts`）
   - ✅ 实现 9 个 ExpressionGroup 端点：
     - GET /groups/:id
     - GET /groups
     - GET /groups/search
     - POST /groups
     - POST /groups/:id/expressions
     - DELETE /groups/:id/expressions/:expressionId
     - POST /groups/:id/merge
     - DELETE /groups/:id
     - GET /expressions/:id/groups
   - ✅ 集成到主路由（`routes/index.ts`）
   - ✅ 所有端点支持语言过滤（`lang` 参数）
   - ✅ 后端编译通过，无错误

### 待完成 ⏳

1. **后端 expressions.ts 路由调整**
   - ✅ GET /expressions - 支持 `group_id` 和 `lang` 参数
   - ✅ POST /expressions - 支持 `group_id` 字段
   - ✅ POST /expressions/batch - 支持的 `ensure_new_group`
   - ✅ POST /expressions/associate - 使用 ExpressionGroup API
   - ✅ GET /expressions/:id - 返回 `groups` 而不是 `meanings`
   - ✅ 移除 POST /expressions/:id/meanings
   - ✅ 移除 DELETE /expressions/:id/meanings/:id
   - ✅ 清理所有 meaning_id 兼容代码

2. **前端类型定义**
   - ✅ 更新 `Expression` 接口（添加 `group_id` 和 `groups`，移除 `meaning_id` 和 `meanings`）
   - ✅ 更新 `ExpressionFilters` 接口（添加 `groupId` 和 `languages`，移除 `meaningId`）
   - ✅ 更新 `CreateExpressionData` 接口（添加 `group_id`，移除 `meaning_id`）
   - ✅ 更新 `UpdateExpressionData` 接口（添加 `group_id`，移除 `meaning_id`）
   - ✅ 更新 `BatchExpressionData` 接口（添加 `ensure_new_group`，移除 `meaning_id` 和 `ensure_new_meaning`）
   - ✅ 添加 `ExpressionGroup` 接口定义

3. **前端 API 客户端**
   - ✅ 创建 `expressionGroups.ts`（完整的 ExpressionGroup API）
   - ✅ 更新 `expressions.ts`（调整参数和类型，清理兼容代码）
   - ✅ 迁移 `associate()` 到 `expressionGroups.ts`（作为 `linkExpressions()`）
   - ✅ 移除 `addMeaning()` 和 `removeMeaning()` 方法

4. **前端组件更新**
   - ⏳ 词句详情页 - 显示 `groups` 而不是 `meanings`
   - ⏳ 词句组弹窗 - 使用 ExpressionGroup API
   - ⏳ 批量提交组件 - 使用 `group_id` 和 `ensure_new_group`
   - ⏳ 所有使用 `meaningId` 的组件

5. **测试和文档**
   - ⏳ 编写后端单元测试
   - ⏳ 编写集成测试
   - ⏳ 更新 API 文档
   - ⏳ 更新前端开发文档

### 技术债务

1. **向后兼容性**
   - `meaning_id` 参数需要保持支持一段时间
   - 考虑添加 deprecation 警告
   - 监控 API 调用统计，评估移除时机

2. **数据一致性**
   - 确保 meanings 表和 ExpressionGroup 的数据映射正确
   - 验证 expression_meaning 表的数据完整性

3. **性能优化**
   - ExpressionGroup 查询可能有 N+1 问题（listGroups 时）
   - 考虑批量加载优化
   - 缓存策略调整
