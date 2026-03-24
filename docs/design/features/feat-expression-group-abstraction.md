# Expression Group 抽象層設計

## System Reminder

**設計來源**：基於用戶需求，在上層隱藏 meanings 和 expression_meanings 表，提供 ExpressionGroup 抽象概念

**實現狀態**：
- ✅ 設計文檔已完成
- ⏳ 等待實現

---

## 概述

當前系統中，`meanings` 表和 `expression_meaning` 表直接暴露給上層應用，導致概念不夠直觀。本設計旨在通過引入 `ExpressionGroup` 抽象概念，將底層的 meanings 和 expression_meaning 實現細節對上層隱藏，提供更清晰、更直觀的接口。

## 設計目標

1. **概念抽象化**：用 `ExpressionGroup`（詞句組）概念替代 `meaning`，更貼近用戶理解
2. **實現細節隱藏**：對上層隱藏 meanings 和 expression_meaning 表的存在
3. **接口統一**：原先接口中的 `meaning_id` 改爲 `group_id`，但底層表結構不變
4. **向後兼容**：確保現有數據和 API 的兼容性

## 核心概念

### ExpressionGroup（詞句組）

`ExpressionGroup` 是 `meaning` 的抽象層概念，表示一組共享相同語義的詞句集合。

| 概念 | 上層視角 | 底層實現 |
|------|----------|----------|
| 詞句組 | ExpressionGroup | meanings 表 + expression_meaning 表 |
| 詞句組 ID | group_id | meanings.id |
| 組內詞句 | group expressions | 通過 expression_meaning 表關聯的 expressions |

**設計優勢**：

1. **概念清晰**：ExpressionGroup 比抽象的 meaning 更直觀
2. **操作簡單**：用戶操作的是"詞句組"，而不是底層的多對多關係
3. **封裝性**：底層表結構的變化不會影響上層代碼
4. **靈活性**：未來可以替換底層實現而不改變接口

## 數據庫接口設計

### ExpressionGroup 類型定義

```typescript
// backend/src/server/db/protocol.ts

export interface ExpressionGroup {
  id: number                        // 對應 meanings.id
  expressions: Expression[]         // 組內的所有詞句
  created_by?: string
  created_at?: string
}
```

### ExpressionGroup 查詢接口

**文件位置**：`backend/src/server/db/queries/expression_group.ts`

```typescript
import { D1Database } from '@cloudflare/workers-types'
import { Expression, ExpressionGroup, ExpressionGroupInfo } from '../protocol.js'

export class ExpressionGroupQueries {
  constructor(private db: D1Database) {}

  /**
   * 通過 group_id 查詢組內的所有 expressions
   * @param groupId 詞句組 ID
   * @param languages 語言過濾列表（可選），例如 ['zh-CN', 'en-US']
   * @returns 該組的所有詞句（可按語言過濾）
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
   * 獲取詞句組信息
   * @param groupId 詞句組 ID
   * @param languages 語言過濾列表（可選），例如 ['zh-CN', 'en-US']
   * @returns 詞句組（可按語言過濾）
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
   * 獲取詞句所屬的所有詞句組
   * @param expressionId 詞句 ID
   * @returns 該詞句所屬的所有詞句組
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

    // 爲每個組加載詞句列表
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
   * 將詞句加入詞句組
   * @param expressionId 詞句 ID
   * @param groupId 詞句組 ID
   * @param username 操作用戶
   * @returns 操作是否成功
   */
  async addToGroup(expressionId: number, groupId: number, username: string): Promise<boolean> {
    const now = new Date().toISOString()

    // 確保 meaning 存在
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    // 添加關聯
    const result = await this.db.prepare(
      'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${expressionId}-${groupId}`, expressionId, groupId, now).run()

    return (result.meta?.changes ?? 0) > 0
  }

  /**
   * 將詞句從詞句組移除
   * @param expressionId 詞句 ID
   * @param groupId 詞句組 ID
   * @returns 操作是否成功
   */
  async removeFromGroup(expressionId: number, groupId: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM expression_meaning WHERE expression_id = ? AND meaning_id = ?'
    ).bind(expressionId, groupId).run()

    return (result.meta?.changes ?? 0) > 0
  }

  /**
   * 創建新的詞句組
   * @param anchorExpressionId 作爲錨點的詞句 ID（將作爲 group_id）
   * @param username 操作用戶
   * @returns 創建的詞句組 ID
   */
  async createGroup(anchorExpressionId: number, username: string): Promise<number> {
    const now = new Date().toISOString()
    const groupId = anchorExpressionId

    // 創建 meaning 記錄
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    // 將錨點詞句加入組
    await this.addToGroup(anchorExpressionId, groupId, username)

    return groupId
  }

  /**
   * 批量將詞句加入詞句組
   * @param expressionIds 詞句 ID 列表
   * @param groupId 詞句組 ID
   * @param username 操作用戶
   * @returns 成功加入的數量
   */
  async batchAddToGroup(expressionIds: number[], groupId: number, username: string): Promise<number> {
    const now = new Date().toISOString()

    // 確保 meaning 存在
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    // 批量添加關聯
    const statements = expressionIds.map(exprId =>
      this.db.prepare(
        'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${exprId}-${groupId}`, exprId, groupId, now)
    )

    const batchResult = await this.db.batch(statements)

    // 計算成功數量
    return batchResult.reduce((sum, result) => sum + (result.meta?.changes ?? 0), 0)
  }

  /**
   * 合併詞句組
   * @param sourceGroupId 源詞句組 ID
   * @param targetGroupId 目標詞句組 ID
   * @returns 合併的詞句數量
   */
  async mergeGroups(sourceGroupId: number, targetGroupId: number): Promise<{ success: boolean, merged_count: number }> {
    const expressionsResult = await this.db.prepare(
      'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceGroupId).all<{ expression_id: number }>()

    if (!expressionsResult.results || expressionsResult.results.length === 0) {
      // 仍然刪除空的源詞句組
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
   * 刪除詞句組
   * @param groupId 詞句組 ID
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
   * 獲取所有詞句組列表
   * @param skip 跳過數量
   * @param limit 限制數量
   * @param languages 語言過濾列表（可選），例如 ['zh-CN', 'en-US']
   * @returns 詞句組列表（可按語言過濾）
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
   * 搜索詞句組（通過組內詞句文本）
   * @param query 搜索關鍵詞
   * @param skip 跳過數量
   * @param limit 限制數量
   * @param languages 語言過濾列表（可選），例如 ['zh-CN', 'en-US']
   * @returns 匹配的詞句組列表（可按語言過濾）
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

## DatabaseService 擴展

### 添加 ExpressionGroup 查詢對象

```typescript
// backend/src/server/db/protocol.ts

// 在 AbstractDatabaseService 中添加
export abstract class AbstractDatabaseService {
  // ... 現有方法 ...

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

## API 設計調整

### 後端路由改造

#### 1. expressions.ts 路由調整

**文件**: `backend/src/server/routes/expressions.ts`

**需要調整的端點**:

| 端點 | 舊實現 | 新實現 | 說明 |
|------|--------|--------|------|
| GET /expressions | `meaning_id` 參數 | 支持 `group_id` 參數（兼容 `meaning_id`） | 查詢特定詞句組的詞句 |
| GET /expressions | 無 `lang` 參數 | 支持 `lang` 參數 | 語言過濾 |
| POST /expressions | `meaning_id` 字段 | 支持 `group_id` 字段 | 創建詞句時指定組 |
| POST /expressions/batch | `ensure_new_meaning` | 支持的 `ensure_new_group` | 批量提交時指定組 |
| POST /expressions/associate | 直接操作 meanings | 調用 expressionGroup | 關聯詞句到組 |
| GET /expressions/:id | 返回 `meanings` | 返回 `groups` | 詞句所屬的詞句組列表 |
| POST /expressions/:id/meanings | 添加 meaning | 遷移到 groups 路由 | 改用 addToGroup |
| DELETE /expressions/:id/meanings/:id | 刪除 meaning | 遷移到 groups 路由 | 改用 removeFromGroup |

**具體改造方案**:

```typescript
// 1. GET /expressions - 支持 group_id 參數
expressionsRoutes.get('/', async (c) => {
  const meaningIdParam = c.req.query('meaning_id')  // 舊參數，向後兼容
  const groupIdParam = c.req.query('group_id')       // 新參數
  const langParam = c.req.query('lang')              // 新參數，語言過濾

  // 優先使用 group_id，如果沒有則使用 meaning_id（兼容）
  const groupId = groupIdParam ? parseInt(groupIdParam) :
                 meaningIdParam ? parseInt(meaningIdParam) : undefined

  // 解析語言過濾
  const languages = langParam ? langParam.split(',').map(l => l.trim()) : undefined

  // 查詢邏輯保持不變，只是參數來源變化
})

// 2. POST /expressions/batch - 支持的 ensure_new_group
const { expressions, ensure_new_meaning, ensure_new_group } = validated
const forceNewGroup = ensure_new_group === true || ensure_new_meaning === true

// 返回結果中使用 group_id
return created(c, { group_id: finalGroupId, results })

// 3. POST /expressions/associate - 使用 ExpressionGroup
expressionsRoutes.post('/associate', requireAuth, async (c) => {
  const { expression_ids } = body

  // 使用 expressionGroup 批量添加
  const anchorId = expression_ids[0]
  const user = c.get('user')
  const groupId = await db.groups.createGroup(anchorId, user.username)

  // 批量添加其餘詞句
  await db.groups.batchAddToGroup(expression_ids.slice(1), groupId, user.username)

  return success(c, { group_id: groupId, updated_count: expression_ids.length })
})

// 4. GET /expressions/:id - 返回 groups
const expression = await service.getById(exprId)

// 替換 meanings 爲 groups
if (includeMeanings) {
  expression.groups = await db.groups.getExpressionGroups(exprId)
}
```

#### 2. 新增 expressionGroup.ts 路由

**文件**: `backend/src/server/routes/expressionGroup.ts`

**實現的端點**:

| 端點 | 方法 | 說明 |
|------|------|------|
| GET /api/v1/groups | listGroups | 列出所有詞句組（支持分頁和語言過濾） |
| GET /api/v1/groups/:id | getGroupInfo | 獲取單個詞句組詳情（支持語言過濾） |
| GET /api/v1/groups/search | searchGroups | 搜索詞句組（支持語言過濾） |
| POST /api/v1/groups | createGroup | 創建新詞句組 |
| POST /api/v1/groups/:id/expressions | addToGroup | 添加詞句到組 |
| DELETE /api/v1/groups/:id/expressions/:expressionId | removeFromGroup | 從組中移除詞句 |
| POST /api/v1/groups/:id/merge | mergeGroups | 合併詞句組 |
| DELETE /api/v1/groups/:id | deleteGroup | 刪除詞句組 |
| GET /api/v1/expressions/:id/groups | getExpressionGroups | 獲取詞句所屬的所有組 |

**語言過濾實現**:

```typescript
// 所有 GET 端點都支持 lang 參數
const langParam = c.req.query('lang')
const languages = langParam ? langParam.split(',').map(l => l.trim()) : undefined

// 查詢時傳入 languages 參數
const group = await db.groups.getGroupInfo(groupId, languages)
```

### 前端 API 改造

#### 1. expressions.ts 調整

**文件**: `web/src/api/expressions.ts`

**需要遷移到 expressionGroups.ts 的方法**:

| 方法 | 原位置 | 新位置 | 改名 |
|------|--------|--------|------|
| associate() | expressions.ts | expressionGroups.ts | linkExpressions() |
| addMeaning() | expressions.ts | expressionGroups.ts | addToGroup() |
| removeMeaning() | expressions.ts | expressionGroups.ts | removeFromGroup() |

**需要調整的類型定義**:

```typescript
// 替換 meaning_id 爲 group_id
export interface CreateExpressionData {
  text: string
  language_code: string
  group_id?: number              // 原爲 meaning_id
  audio_url?: string
}

export interface UpdateExpressionData {
  text?: string
  language_code?: string
  group_id?: number              // 原爲 meaning_id
  audio_url?: string
}

export interface BatchExpressionData {
  expressions: Array<{
    text: string
    language_code: string
    group_id?: number           // 原爲 meaning_id
  }>
  ensure_new_group?: boolean    // 原爲 ensure_new_meaning
}

export interface BatchResponse {
  group_id: number               // 原爲 meaning_id
  results: any[]
}
```

**需要調整的方法**:

```typescript
// 1. getAll() - 支持 groupId 和 languages 過濾
async getAll(filters: ExpressionFilters = {}): Promise<PaginatedResponse<Expression>> {
  const params = new URLSearchParams()

  if (filters.skip !== undefined) params.append('skip', filters.skip.toString())
  if (filters.limit !== undefined) params.append('limit', filters.limit.toString())
  if (filters.language) params.append('language', filters.language)

  // 支持 groupId（替換 meaningId）
  if (filters.groupId !== undefined) {
    if (Array.isArray(filters.groupId)) {
      params.append('group_id', filters.groupId.join(','))
    } else {
      params.append('group_id', filters.groupId.toString())
    }
  } else if (filters.meaningId !== undefined) {
    // 向後兼容：仍然支持 meaningId，但內部轉換爲 groupId
    if (Array.isArray(filters.meaningId)) {
      params.append('group_id', filters.meaningId.join(','))
    } else {
      params.append('group_id', filters.meaningId.toString())
    }
  }

  // 支持語言過濾
  if (filters.languages) {
    params.append('lang', filters.languages.join(','))
  }

  // ... 其他參數
}

// 2. batch() - 支持的 ensure_new_group
async batch(data: BatchExpressionData): Promise<ApiResponse<BatchResponse>> {
  // 支持 ensure_new_group（向後兼容 ensure_new_meaning）
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

  // 轉換 meanings 爲 groups（如果是舊響應）
  if (data.data.meanings && !data.data.groups) {
    data.data.groups = data.data.meanings
    delete data.data.meanings
  }

  return data
}
```

#### 2. 新增 expressionGroups.ts

**文件**: `web/src/api/expressionGroups.ts`

**實現所有 ExpressionGroup 相關的 API**:

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
  // 獲取單個詞句組
  async getGroup(id: number, languages?: string[]): Promise<ApiResponse<ExpressionGroup>> {
    const params = languages ? { lang: languages.join(',') } : {}
    const response = await apiClient.get(`/groups/${id}`, { params })
    return response.data as ApiResponse<ExpressionGroup>
  },

  // 列出所有詞句組
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

  // 搜索詞句組
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

  // 創建新詞句組
  async createGroup(data: CreateGroupData): Promise<ApiResponse<ExpressionGroup>> {
    const response = await apiClient.post('/groups', data)
    return response.data as ApiResponse<ExpressionGroup>
  },

  // 添加詞句到組
  async addToGroup(groupId: number, data: AddToGroupData): Promise<ApiResponse<null>> {
    const response = await apiClient.post(`/groups/${groupId}/expressions`, data)
    return response.data as ApiResponse<null>
  },

  // 從組中移除詞句
  async removeFromGroup(groupId: number, expressionId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/groups/${groupId}/expressions/${expressionId}`)
    return response.data as ApiResponse<null>
  },

  // 合併詞句組
  async mergeGroups(targetGroupId: number, data: MergeGroupsData): Promise<ApiResponse<any>> {
    const response = await apiClient.post(`/groups/${targetGroupId}/merge`, data)
    return response.data as ApiResponse<any>
  },

  // 刪除詞句組
  async deleteGroup(groupId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/groups/${groupId}`)
    return response.data as ApiResponse<null>
  },

  // 獲取詞句所屬的所有組
  async getExpressionGroups(expressionId: number): Promise<ApiResponse<ExpressionGroup[]>> {
    const response = await apiClient.get(`/expressions/${expressionId}/groups`)
    return response.data as ApiResponse<ExpressionGroup[]>
  },

  // 批量關聯詞句到組（替代 associate）
  async linkExpressions(expressionIds: number[]): Promise<ApiResponse<{ group_id: number; updated_count: number }>> {
    const response = await apiClient.post('/expressions/associate', { expression_ids: expressionIds })
    const data = response.data as ApiResponse<{ meaning_id: number; updated_count: number }>
    // 轉換響應格式
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

### API 參數變更

| 接口 | 舊參數 | 新參數 | 說明 |
|------|--------|--------|------|
| GET /api/v1/expressions | `meaning_id` | `group_id` | 查詢特定詞句組的詞句 |
| GET /api/v1/expressions | 無 | `lang` | 語言過濾，如 `?lang=zh-CN,en-US` |
| POST /api/v1/expressions/batch | `meaning_id` | `group_id` | 批量提交時指定詞句組 |
| GET /api/v1/expressions/:expr_id | 返回 `meanings` | 返回 `groups` | 詞句所屬的詞句組列表 |
| GET /api/v1/groups | 無 | `lang` | 語言過濾，如 `?lang=zh-CN,en-US` |
| GET /api/v1/groups/:id | 無 | `lang` | 語言過濾，如 `?lang=zh-CN,en-US` |
| GET /api/v1/groups/search | 無 | `lang` | 語言過濾，如 `?lang=zh-CN,en-US` |

### 示例 API 調用

```javascript
// 獲取詞句組的所有詞句
GET /api/v1/expressions?group_id=456&skip=0&limit=20

// 獲取詞句組的所有詞句（僅中文和英文）
GET /api/v1/expressions?group_id=456&lang=zh-CN,en-US&skip=0&limit=20

// 批量提交詞句到指定詞句組
POST /api/v1/expressions/batch
{
  "group_id": 456,
  "expressions": [...]
}

// 獲取詞句所屬的詞句組
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

### 語言過濾功能

支持通過 `lang` 參數過濾詞句組內的詞句語言：

| API | 參數 | 說明 |
|-----|------|------|
| GET /api/v1/groups/:id | `?lang=zh-CN,en-US` | 返回指定語言的詞句 |
| GET /api/v1/groups | `?lang=zh-CN,en-US` | 所有組只返回指定語言的詞句 |
| GET /api/v1/groups/search | `?lang=zh-CN,en-US` | 搜索結果只包含指定語言的詞句 |

**語言參數格式**：
- 單個語言：`?lang=zh-CN`
- 多個語言：`?lang=zh-CN,en-US,en-GB`（逗號分隔）
- 不指定：返回所有語言

**實現示例**：
```typescript
// 後端實現
const langParam = c.req.query('lang')
const languages = langParam ? langParam.split(',') : undefined

// 獲取詞句組（帶語言過濾）
const group = await db.getGroupInfo(groupId, languages)
// 只返回 zh-CN 和 en-US 的詞句

// 列出所有詞句組（帶語言過濾）
const groups = await db.listGroups(skip, limit, languages)
// 所有組只返回 zh-CN 和 en-US 的詞句
```

## 遷移策略

### 階段 1：並行運行（當前階段）

- ✅ 新的 ExpressionGroup API 已就緒
- ✅ 現有的 meaning 相關 API 繼續運行
- ⏳ 新舊 API 同時存在，互不幹擾

**開發者可以開始使用新 API**:

```typescript
// 推薦：使用新的 ExpressionGroup API
import { expressionGroupsApi } from '@/api/expressionGroups'

const group = await expressionGroupsApi.getGroup(123, ['zh-CN', 'en-US'])
const groups = await expressionGroupsApi.listGroups(0, 20)

// 兼容：舊的 API 繼續工作
import { expressionsApi } from '@/api/expressions'

const expressions = await expressionsApi.getAll({ meaningId: 123 })
```

### 階段 2：漸進式遷移

前端逐步從舊 API 遷移到新 API：

**遷移順序建議**:
1. **只讀操作優先** - 先遷移查詢和顯示相關組件
2. **修改操作跟進** - 再遷移添加、更新、刪除操作
3. **批量操作最後** - 最後處理複雜的批量操作

**遷移示例**:

```typescript
// 舊代碼
const expressions = await expressionsApi.getAll({ meaningId: 123 })
const groups = expression.meanings

// 新代碼
const expressions = await expressionsApi.getAll({ groupId: 123 })
const groups = await expressionGroupsApi.getExpressionGroups(expressionId)
```

### 階段 3：完全切換

- 所有前端組件遷移完成
- 舊的 meaning_id 參數標記爲 deprecated
- 添加警告日誌，提醒開發者使用新 API

```typescript
// 後端警告示例
if (meaningIdParam) {
  console.warn('[DEPRECATED] meaning_id parameter is deprecated. Use group_id instead.')
  // 繼續處理以保持兼容
}
```

### 階段 4：清理

- 移除所有 meaning_id 相關代碼
- 移除 deprecated 警告
- 文檔完全更新爲新的概念

## 向後兼容性

### 1. 內部實現保持不變

- meanings 表和 expression_meaning 表結構不變
- 只是在上層接口和類型定義中隱藏這些細節
- ExpressionGroup 作爲封裝層，底層仍使用 meanings 和 expression_meaning

### 2. 遷移策略

```typescript
// 後端可以同時支持新舊參數
async function getExpressions(params: {
  meaningId?: number | number[]  // 舊參數，兼容
  groupId?: number | number[]     // 新參數
}): Promise<Expression[]> {
  const groupId = params.groupId || params.meaningId
  // 使用 groupId 查詢
}

// 前端逐步遷移
// 階段1：繼續使用 meaningId
await fetch('/api/v1/expressions?meaningId=456')

// 階段2：切換到 groupId
await fetch('/api/v1/expressions?groupId=456')
```

### 3. 數據一致性

確保 meanings 表和 ExpressionGroup 的數據一一對應：
```typescript
// meanings.id === ExpressionGroup.id
// expression_meaning.meaning_id === ExpressionGroup.id
```

## 使用示例

### 1. 獲取詞句組（帶語言過濾）

```typescript
// 獲取詞句組 456 的所有詞句
const allExpressions = await db.getGroupExpressions(456)
// 返回：[en, zh-CN, ja-JP, fr-FR, ...]

// 獲取詞句組 456 的中文和英文詞句
const filteredExpressions = await db.getGroupExpressions(456, ['zh-CN', 'en-US'])
// 返回：[zh-CN, en-US]

// 獲取完整詞句組信息（帶語言過濾）
const groupInfo = await db.getGroupInfo(456, ['zh-CN', 'en-US'])
// 返回：{ id: 456, expressions: [zh-CN詞句, en-US詞句], ... }
```

### 2. 列出詞句組（帶語言過濾）

```typescript
// 列出前 20 個詞句組（所有語言）
const allGroups = await db.listGroups(0, 20)
// 每個組包含所有語言的詞句

// 列出前 20 個詞句組（僅中文和英文）
const filteredGroups = await db.listGroups(0, 20, ['zh-CN', 'en-US'])
// 每個組只包含 zh-CN 和 en-US 的詞句
```

### 3. 搜索詞句組（帶語言過濾）

```typescript
// 搜索包含 "hello" 的詞句組（所有語言）
const searchResults = await db.searchGroups('hello', 0, 20)

// 搜索包含 "hello" 的詞句組（僅中文和英文）
const filteredSearchResults = await db.searchGroups('hello', 0, 20, ['zh-CN', 'en-US'])
// 結果中的詞句組只包含 zh-CN 和 en-US 的詞句
```

### 4. API 調用示例

```javascript
// 獲取詞句組 456 的所有詞句
fetch('/api/v1/groups/456')
// 返回所有語言的詞句

// 獲取詞句組 456 的中文和英文詞句
fetch('/api/v1/groups/456?lang=zh-CN,en-US')
// 只返回中文和英文的詞句

// 列出詞句組（所有語言）
fetch('/api/v1/groups')
// 返回所有詞句組，每組包含所有語言的詞句

// 列出詞句組（僅中文和英文）
fetch('/api/v1/groups?lang=zh-CN,en-US')
// 返回所有詞句組，每組只包含中文和英文的詞句

// 搜索詞句組（所有語言）
fetch('/api/v1/groups/search?q=hello')
// 返回匹配的詞句組，每組包含所有語言的詞句

// 搜索詞句組（僅中文和英文）
fetch('/api/v1/groups/search?q=hello&lang=zh-CN,en-US')
// 返回匹配的詞句組，每組只包含中文和英文的詞句
```

## 前端影響

### 類型定義更新

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
  meaningId?: number | number[]    // 向後兼容
  tagPrefix?: string
  excludeTagPrefix?: string
  includeMeanings?: boolean
  languages?: string[]            // 新增：語言過濾
}
```

### API 客戶端結構

```typescript
// web/src/api/
├── client.ts                      // HTTP 客戶端
├── expressions.ts                 // 表達式 API（調整後）
├── expressionGroups.ts           // 詞句組 API（新增）
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

### 組件更新

詞句詳情頁和詞句組彈窗中的概念從 `meaning` 更新爲 `group`：

```typescript
// 詞句詳情頁
const groups = await fetch(`/api/v1/expressions/${expressionId}`)
groups.forEach(group => {
  renderExpressionGroup({
    groupId: group.id,
    expressions: group.expressions
  })
})

// 加入詞句組
await fetch(`/api/v1/expressions/${expressionId}/groups`, {
  method: 'POST',
  body: JSON.stringify({ group_id: targetGroupId })
})
```

## 實施步驟

### 階段 1：類型定義和接口設計
- ✅ 編寫設計文檔
- ✅ 定義 ExpressionGroup 類型
- ✅ 實現 ExpressionGroupQueries 類
- ✅ 擴展 AbstractDatabaseService 接口

### 階段 2：後端實現
- ✅ 在 DatabaseService 中實現 ExpressionGroup 方法
- ✅ 創建 expressionGroup.ts 路由
- ✅ 集成 expressionGroup.ts 到主路由
- ⏳ 更新 expressions.ts 路由，支持 group_id 參數
- ⏳ 保持 meaning_id 參數的向後兼容
- ⏳ 編寫單元測試

### 階段 3：前端適配
- ⏳ 更新前端類型定義（Expression、ExpressionFilters 等）
- ⏳ 創建 expressionGroups.ts API 客戶端
- ⏳ 更新 expressions.ts API 客戶端
- ⏳ 更新詞句詳情頁組件（groups 替代 meanings）
- ⏳ 更新詞句組彈窗組件
- ⏳ 更新使用 meaning_id 的所有組件

### 階段 4：文檔和測試
- ⏳ 更新 API 文檔
- ⏳ 更新前端開發文檔
- ⏳ 進行集成測試

### 階段 5：清理和優化
- ⏳ 逐步廢棄 meaning_id 參數（設置 deprecated 標記）
- ⏳ 監控 API 使用情況
- ⏳ 性能優化

## 注意事項

1. **概念一致性**：確保整個系統都使用 ExpressionGroup 概念，不再向上層暴露 meaning
2. **類型安全**：TypeScript 類型定義要完整，避免 any 類型
3. **文檔同步**：更新所有相關文檔，確保概念統一
4. **測試覆蓋**：爲 ExpressionGroup 接口編寫完整的單元測試
5. **性能考慮**：批量操作使用事務，減少數據庫往返
6. **錯誤處理**：提供清晰的錯誤信息，幫助開發者調試
7. **漸進式遷移**：保持向後兼容，給前端足夠的時間遷移

## 相關文檔

- [詞句與語義多對多關係設計](./feat-meaning-mapping.md)
- [數據庫設計](./feat-database.md)
- [系統架構設計](../system/architecture.md)
- [後端 API 指南](../../api/backend-guide.md)

## 設計優勢總結

1. **更好的抽象**：ExpressionGroup 比 meaning 更直觀，用戶更容易理解
2. **封裝實現**：上層不需要知道 meanings 和 expression_meaning 表的存在
3. **易於維護**：未來可以優化底層實現而不影響上層代碼
4. **概念統一**：整個系統使用統一的詞句組概念
5. **向後兼容**：通過參數別名保持兼容性，降低遷移成本

## 當前進度

### 已完成 ✅

1. **設計文檔**
   - ✅ 創建完整的設計文檔（本文檔）
   - ✅ 更新功能導航和主設計 README

2. **類型定義和數據庫層**
   - ✅ 在 `protocol.ts` 中定義 ExpressionGroup 接口
   - ✅ 實現 `ExpressionGroupQueries` 類（`backend/src/server/db/queries/expression_group.ts`）
   - ✅ 在 `AbstractDatabaseService` 中添加 ExpressionGroup 抽象方法
   - ✅ 在 `D1DatabaseService` 中實現所有 ExpressionGroup 方法

3. **後端 API 路由**
   - ✅ 創建 `expressionGroup.ts` 路由（`backend/src/server/routes/expressionGroup.ts`）
   - ✅ 實現 9 個 ExpressionGroup 端點：
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
   - ✅ 所有端點支持語言過濾（`lang` 參數）
   - ✅ 後端編譯通過，無錯誤

### 待完成 ⏳

1. **後端 expressions.ts 路由調整**
   - ✅ GET /expressions - 支持 `group_id` 和 `lang` 參數
   - ✅ POST /expressions - 支持 `group_id` 字段
   - ✅ POST /expressions/batch - 支持的 `ensure_new_group`
   - ✅ POST /expressions/associate - 使用 ExpressionGroup API
   - ✅ GET /expressions/:id - 返回 `groups` 而不是 `meanings`
   - ✅ 移除 POST /expressions/:id/meanings
   - ✅ 移除 DELETE /expressions/:id/meanings/:id
   - ✅ 清理所有 meaning_id 兼容代碼

2. **前端類型定義**
   - ✅ 更新 `Expression` 接口（添加 `group_id` 和 `groups`，移除 `meaning_id` 和 `meanings`）
   - ✅ 更新 `ExpressionFilters` 接口（添加 `groupId` 和 `languages`，移除 `meaningId`）
   - ✅ 更新 `CreateExpressionData` 接口（添加 `group_id`，移除 `meaning_id`）
   - ✅ 更新 `UpdateExpressionData` 接口（添加 `group_id`，移除 `meaning_id`）
   - ✅ 更新 `BatchExpressionData` 接口（添加 `ensure_new_group`，移除 `meaning_id` 和 `ensure_new_meaning`）
   - ✅ 添加 `ExpressionGroup` 接口定義

3. **前端 API 客戶端**
   - ✅ 創建 `expressionGroups.ts`（完整的 ExpressionGroup API）
   - ✅ 更新 `expressions.ts`（調整參數和類型，清理兼容代碼）
   - ✅ 遷移 `associate()` 到 `expressionGroups.ts`（作爲 `linkExpressions()`）
   - ✅ 移除 `addMeaning()` 和 `removeMeaning()` 方法

4. **前端組件更新**
   - ⏳ 詞句詳情頁 - 顯示 `groups` 而不是 `meanings`
   - ⏳ 詞句組彈窗 - 使用 ExpressionGroup API
   - ⏳ 批量提交組件 - 使用 `group_id` 和 `ensure_new_group`
   - ⏳ 所有使用 `meaningId` 的組件

5. **測試和文檔**
   - ⏳ 編寫後端單元測試
   - ⏳ 編寫集成測試
   - ⏳ 更新 API 文檔
   - ⏳ 更新前端開發文檔

### 技術債務

1. **向後兼容性**
   - `meaning_id` 參數需要保持支持一段時間
   - 考慮添加 deprecation 警告
   - 監控 API 調用統計，評估移除時機

2. **數據一致性**
   - 確保 meanings 表和 ExpressionGroup 的數據映射正確
   - 驗證 expression_meaning 表的數據完整性

3. **性能優化**
   - ExpressionGroup 查詢可能有 N+1 問題（listGroups 時）
   - 考慮批量加載優化
   - 緩存策略調整
