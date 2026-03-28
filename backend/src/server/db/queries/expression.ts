import { D1Database, D1Result } from '@cloudflare/workers-types'
import { Expression, ExpressionVersion } from '../protocol.js'

export class ExpressionQueries {
  constructor(private db: D1Database) { }

  async findById(id: number): Promise<Expression | null> {
    const expression = await this.db.prepare(
      'SELECT * FROM expressions WHERE id = ?'
    ).bind(id).first<Expression>()
    return expression || null
  }

  async findByIds(ids: number[]): Promise<Expression[]> {
    if (ids.length === 0) return []
    const { results } = await this.db.prepare(
      `SELECT * FROM expressions WHERE id IN (SELECT value FROM json_each(?))`
    ).bind(JSON.stringify(ids)).all<Expression>()
    return results || []
  }

  async findAll(skip: number = 0, limit: number = 50, filters: {
    languages?: string[]
    tagPrefix?: string
    excludeTagPrefix?: string
  } = {}): Promise<Expression[]> {
    let query = 'SELECT * FROM expressions'
    const bindings: any[] = []
    const whereConditions: string[] = []

    if (filters.languages) {
      whereConditions.push('language_code IN (?)')
      bindings.push(filters.languages.join(','))
    }

    if (filters.tagPrefix) {
      whereConditions.push('tags LIKE ?')
      bindings.push(`%${filters.tagPrefix}%`)
    }

    if (filters.excludeTagPrefix) {
      whereConditions.push('(tags IS NULL OR tags NOT LIKE ?)')
      bindings.push(`%${filters.excludeTagPrefix}%`)
    }

    if (whereConditions.length > 0) {
      query += ' WHERE ' + whereConditions.join(' AND ')
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    bindings.push(limit, skip)

    const { results } = await this.db.prepare(query).bind(...bindings).all<Expression>()
    return results || []
  }

  async search(query: string, fromLang?: string, region?: string, skip: number = 0, limit: number = 20): Promise<Expression[]> {
    const ftsQuery = `"${query.replace(/"/g, '""')}"*`
    let sqlQuery = `
      SELECT e.*
      FROM expressions e
      INNER JOIN expressions_fts fts ON e.id = fts.rowid
      WHERE expressions_fts MATCH ?
    `
    const bindings: any[] = [ftsQuery]

    if (fromLang) {
      sqlQuery += ' AND e.language_code = ?'
      bindings.push(fromLang)
    }

    if (region) {
      sqlQuery += ' AND e.region_name LIKE ?'
      bindings.push(`%${region}%`)
    }

    sqlQuery += ` 
      ORDER BY 
        CASE WHEN e.text = ? THEN 0 ELSE 1 END,
        fts.rank, 
        LENGTH(e.text), 
        e.created_at DESC 
    LIMIT ? OFFSET ?
    `
    bindings.push(query, limit, skip)

    const { results } = await this.db.prepare(sqlQuery).bind(...bindings).all<Expression>()
    return results || []
  }

  async findMeaningIds(expressionIds: number[]): Promise<Map<number, number[]>> {
    if (expressionIds.length === 0) return new Map()
    const result = new Map<number, number[]>()
    const { results: rows } = await this.db.prepare(
      `SELECT expression_id, meaning_id FROM expression_meaning WHERE expression_id IN (SELECT value FROM json_each(?))`
    ).bind(JSON.stringify(expressionIds)).all<{ expression_id: number, meaning_id: number }>()

    rows?.forEach(row => {
      if (!result.has(row.expression_id)) {
        result.set(row.expression_id, [])
      }
      result.get(row.expression_id)!.push(row.meaning_id)
    })
    return result
  }

  async create(data: Partial<Expression>): Promise<Expression> {
    const bindValues = [
      data.id,
      data.text,
      data.desc || null,
      data.audio_url || null,
      data.language_code,
      data.region_code || null,
      data.region_name || null,
      data.region_latitude !== undefined ? data.region_latitude : null,
      data.region_longitude !== undefined ? data.region_longitude : null,
      data.tags || null,
      data.source_type || 'user',
      data.source_ref || null,
      data.review_status || 'pending',
      data.created_by || null,
      data.updated_by || null
    ]

    await this.db.prepare(
      `INSERT OR IGNORE INTO expressions (
        id, text, desc, audio_url, language_code, region_code, region_name, region_latitude,
        region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(...bindValues).run()

    const resultExpr = await this.findById(data.id!)
    if (!resultExpr) throw new Error('Failed to create or fetch expression')
    return resultExpr
  }

  async ensureExist(expressions: Array<{ id: number, text: string, language_code: string }>, username: string): Promise<Record<string, number>> {
    const results: Record<string, number> = {}

    // Batch check existing IDs in chunks
    const idsToCheck = expressions.map(e => e.id)
    const existingIdSet = new Set<number>()

    if (idsToCheck.length > 0) {
      const CHUNK_SIZE = 50
      for (let i = 0; i < idsToCheck.length; i += CHUNK_SIZE) {
        const chunk = idsToCheck.slice(i, i + CHUNK_SIZE)
        const placeholders = chunk.map(() => '?').join(',')
        const { results: existingRows } = await this.db.prepare(`
          SELECT id FROM expressions WHERE id IN (${placeholders})
        `).bind(...chunk).all<{ id: number }>()

        existingRows?.forEach(row => existingIdSet.add(row.id))
      }
    }

    const newExpressions = expressions.filter(e => !existingIdSet.has(e.id))
    expressions.forEach(e => { results[`${e.text}|${e.language_code}`] = e.id })

    if (newExpressions.length > 0) {
      const BATCH_SIZE = 50
      for (let i = 0; i < newExpressions.length; i += BATCH_SIZE) {
        const chunk = newExpressions.slice(i, i + BATCH_SIZE)
        const statements = chunk.map(expr =>
          this.db.prepare(
            `INSERT INTO expressions (
              id, text, audio_url, language_code, source_type, review_status, created_by, updated_by
            ) VALUES (?, ?, NULL, ?, 'handbook', 'approved', ?, ?)`
          ).bind(expr.id, expr.text, expr.language_code, username, username)
        )
        await this.db.batch(statements)
      }
    }

    return results
  }

  async upsertBatch(expressions: Partial<Expression>[], forceNewMeaning: boolean = false): Promise<any[]> {
    // This is a simplified version, the actual heavy lifting is in D1DatabaseService.upsertExpressions
    // using prepareUpsert for batching.
    return []
  }

  prepareUpsert(data: Partial<Expression>) {
    const bindValues = [
      data.id,
      data.text,
      data.desc || null,
      data.audio_url || null,
      data.language_code,
      data.region_code || null,
      data.region_name || null,
      data.region_latitude !== undefined ? data.region_latitude : null,
      data.region_longitude !== undefined ? data.region_longitude : null,
      data.tags || null,
      data.source_type || 'user',
      data.source_ref || null,
      data.review_status || 'pending',
      data.created_by || null,
      data.updated_by || null
    ]

    return this.db.prepare(
      `INSERT INTO expressions (
        id, text, desc, audio_url, language_code, region_code, region_name, region_latitude,
        region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        tags = CASE WHEN excluded.tags IS NOT NULL THEN excluded.tags ELSE tags END,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = CASE WHEN excluded.updated_by IS NOT NULL THEN excluded.updated_by ELSE updated_by END
      RETURNING *`
    ).bind(...bindValues)
  }

  async updateLanguageStatsFromCount(languageCode: string): Promise<void> {
    await this.db.prepare(`
      INSERT OR REPLACE INTO language_stats (language_code, expression_count)
      SELECT ?, COUNT(*) FROM expressions WHERE language_code = ?
    `).bind(languageCode, languageCode).run()
  }

  async update(id: number, data: Partial<Expression>): Promise<Expression> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(data).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(value)
      }
    })

    values.push(id)

    const result = await this.db.prepare(
      `UPDATE expressions SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).first<Expression>()

    if (!result) throw new Error('Failed to update expression')
    return result
  }

  async delete(id: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM expressions WHERE id = ?'
    ).bind(id).run()
    return (result.meta?.changes ?? 0) > 0
  }

  async getVersions(expressionId: number): Promise<ExpressionVersion[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM expression_versions WHERE expression_id = ? ORDER BY created_at DESC'
    ).bind(expressionId).all<ExpressionVersion>()
    return results || []
  }

  async createVersion(id: number, version: Partial<ExpressionVersion>): Promise<ExpressionVersion> {
    const bindValues = [
      id,
      version.expression_id || null,
      version.text || null,
      version.desc || null,
      version.meaning_id !== undefined ? version.meaning_id : null,
      version.audio_url || null,
      version.region_name || null,
      version.region_latitude !== undefined ? version.region_latitude : null,
      version.region_longitude !== undefined ? version.region_longitude : null,
      version.created_by || null
    ]

    const result = await this.db.prepare(
      `INSERT INTO expression_versions (
        id, expression_id, text, desc, meaning_id, audio_url, region_name, region_latitude,
        region_longitude, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<ExpressionVersion>()

    if (!result) throw new Error('Failed to create expression version')
    return result
  }

  async updateLanguageStats(languageCode: string, delta: number): Promise<void> {
    await this.prepareUpdateLanguageStats(languageCode, delta).run()
  }

  prepareUpdateLanguageStats(languageCode: string, delta: number) {
    return this.db.prepare(`
      INSERT OR REPLACE INTO language_stats (language_code, expression_count)
      VALUES (?, COALESCE((SELECT expression_count FROM language_stats WHERE language_code = ?), 0) + ?)
    `).bind(languageCode, languageCode, delta)
  }

  // Helper for batch operations
  prepareDeleteMeaning(id: number) {
    return this.db.prepare('DELETE FROM expression_meaning WHERE expression_id = ?').bind(id)
  }

  prepareDeleteCollectionItems(id: number) {
    return this.db.prepare('DELETE FROM collection_items WHERE expression_id = ?').bind(id)
  }

  prepareDeleteVersions(id: number) {
    return this.db.prepare('DELETE FROM expression_versions WHERE expression_id = ?').bind(id)
  }

  prepareDeleteFTS(id: number) {
    // For FTS5 external content, we use the 'delete' command to remove the entry from the index
    return this.db.prepare("INSERT INTO expressions_fts(expressions_fts, rowid, text) SELECT 'delete', id, text FROM expressions WHERE id = ?").bind(id)
  }

  prepareDeleteExpression(id: number) {
    return this.db.prepare('DELETE FROM expressions WHERE id = ?').bind(id)
  }

  async migrateId(oldId: number, newExpression: Partial<Expression>): Promise<Expression> {
    const text = newExpression.text || ''
    const languageCode = newExpression.language_code || ''
    const now = new Date().toISOString()
    const newId = Math.abs(this.hashCode(`${text}|${languageCode}`))

    // Use a batch to ensure atomicity
    await this.db.batch([
      this.db.prepare('DELETE FROM expressions WHERE id = ?').bind(oldId),
      this.db.prepare(
        'INSERT INTO expressions (id, text, language_code, audio_url, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)'
      ).bind(newId, text, languageCode, newExpression.audio_url || null, now, now)
    ])

    const result = await this.findById(newId)
    if (!result) {
      throw new Error('Failed to migrate expression ID')
    }
    return result
  }

  async selectSemanticAnchor(expressionIds: number[]): Promise<number | null> {
    if (expressionIds.length === 0) return null

    const placeholders = expressionIds.map(() => '?').join(',')
    const query = `
      SELECT expression_id, COUNT(*) as association_count
      FROM expression_meaning
      WHERE expression_id IN (${placeholders})
      GROUP BY expression_id
      ORDER BY association_count DESC
      LIMIT 1
    `
    const result = await this.db.prepare(query).bind(...expressionIds).first<{ expression_id: number }>()
    return result?.expression_id || expressionIds[0]
  }

  private hashCode(s: string): number {
    let hash = 0
    for (let i = 0; i < s.length; i++) {
      const char = s.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // Convert to 32bit integer
    }
    return hash
  }

  async cleanupFTSIndex(): Promise<number> {
    const result = await this.db.prepare(`
      DELETE FROM expressions_fts
      WHERE rowid NOT IN (SELECT id FROM expressions)
    `).run()
    return result.meta?.changes ?? 0
  }
}
