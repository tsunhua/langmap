import { D1Database } from '@cloudflare/workers-types'
import { Meaning } from '../protocol.js'

export class MeaningQueries {
  constructor(private db: D1Database) {}

  async findByExpressionId(expressionId: number): Promise<Meaning[]> {
    const { results } = await this.db.prepare(
      'SELECT m.* FROM meanings m JOIN expression_meaning em ON m.id = em.meaning_id WHERE em.expression_id = ? ORDER BY em.created_at DESC'
    ).bind(expressionId).all<Meaning>()
    return results || []
  }

  async ensureMeaningExists(meaningId: number, username: string, now: string): Promise<void> {
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(meaningId, username, now).run()
  }

  async addExpressionMeaning(expressionId: number, meaningId: number, now: string): Promise<void> {
    await this.db.prepare(
      'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${expressionId}-${meaningId}`, expressionId, meaningId, now).run()
  }

  async removeExpressionMeaning(expressionId: number, meaningId: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM expression_meaning WHERE expression_id = ? AND meaning_id = ?'
    ).bind(expressionId, meaningId).run()
    return (result.meta?.changes ?? 0) > 0
  }

  async mergeGroups(sourceMeaningId: number, targetMeaningId: number): Promise<{ success: boolean, merged_count: number }> {
    const expressionsResult = await this.db.prepare(
      'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceMeaningId).all<{ expression_id: number }>()

    if (!expressionsResult.results || expressionsResult.results.length === 0) {
      // Still delete the source meaning if it's empty
      await this.db.prepare('DELETE FROM meanings WHERE id = ?').bind(sourceMeaningId).run()
      return { success: true, merged_count: 0 }
    }

    const now = new Date().toISOString()
    const insertStatements = expressionsResult.results.map(e =>
      this.db.prepare(
        'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${e.expression_id}-${targetMeaningId}`, e.expression_id, targetMeaningId, now)
    )

    const deleteExpressionMeaningStmt = this.db.prepare(
      'DELETE FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceMeaningId)

    const deleteMeaningStmt = this.db.prepare(
      'DELETE FROM meanings WHERE id = ?'
    ).bind(sourceMeaningId)

    await this.db.batch([...insertStatements, deleteExpressionMeaningStmt, deleteMeaningStmt])

    return {
      success: true,
      merged_count: expressionsResult.results.length
    }
  }
}
