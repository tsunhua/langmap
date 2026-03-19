import { D1Database } from '@cloudflare/workers-types'
import { Expression, ExpressionGroup } from '../protocol.js'

export class ExpressionGroupQueries {
  constructor(private db: D1Database) {}

  private buildLanguageFilter(languages?: string[]): string {
    if (!languages || languages.length === 0) {
      return ''
    }
    const placeholders = languages.map(() => '?').join(',')
    return `AND e.language_code IN (${placeholders})`
  }

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

  async addToGroup(expressionId: number, groupId: number, username: string): Promise<boolean> {
    const now = new Date().toISOString()

    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    const result = await this.db.prepare(
      'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${expressionId}-${groupId}`, expressionId, groupId, now).run()

    return (result.meta?.changes ?? 0) > 0
  }

  async removeFromGroup(expressionId: number, groupId: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM expression_meaning WHERE expression_id = ? AND meaning_id = ?'
    ).bind(expressionId, groupId).run()

    return (result.meta?.changes ?? 0) > 0
  }

  async createGroup(anchorExpressionId: number, username: string): Promise<number> {
    const now = new Date().toISOString()
    const groupId = anchorExpressionId

    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    await this.addToGroup(anchorExpressionId, groupId, username)

    return groupId
  }

  async batchAddToGroup(expressionIds: number[], groupId: number, username: string): Promise<number> {
    const now = new Date().toISOString()

    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(groupId, username, now).run()

    const statements = expressionIds.map(exprId =>
      this.db.prepare(
        'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${exprId}-${groupId}`, exprId, groupId, now)
    )

    const batchResult = await this.db.batch(statements)

    return batchResult.reduce((sum, result) => sum + (result.meta?.changes ?? 0), 0)
  }

  async mergeGroups(sourceGroupId: number, targetGroupId: number): Promise<{ success: boolean, merged_count: number }> {
    const expressionsResult = await this.db.prepare(
      'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceGroupId).all<{ expression_id: number }>()

    if (!expressionsResult.results || expressionsResult.results.length === 0) {
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
