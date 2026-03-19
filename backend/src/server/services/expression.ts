import type { Expression } from '../types/entity.js'
import { NotFoundError } from '../types/error.js'

interface DBService {
  expressions: any
  meanings: any
  clearStatisticsCache(): void
  clearHeatmapCache(): void
  stableExpressionId(text: string, languageCode: string): number
  formatTimestamps<T>(obj: T): T
  
  // High-level operations still in D1DatabaseService
  upsertExpressions(expressions: any[], forceNewMeaning: boolean): Promise<any[]>
  ensureExpressionsExist(expressions: any[], username: string): Promise<any>
  deleteExpression(id: number): Promise<boolean>
}

export class ExpressionService {
  constructor(private db: DBService) {}

  async getAll(skip: number, limit: number, filters: {
    language?: string
    meaningId?: number | number[]
    tagPrefix?: string
    excludeTagPrefix?: string
    includeMeanings?: boolean
  } = {}): Promise<Expression[]> {
    const results = await this.db.expressions.findAll(skip, limit, filters)
    return results.map((e: any) => this.db.formatTimestamps(e))
  }

  async getById(id: number): Promise<Expression> {
    const expression = await this.db.expressions.findById(id)
    if (!expression) {
      throw new NotFoundError('Expression')
    }
    return this.db.formatTimestamps(expression)
  }

  async getByIds(ids: number[]): Promise<Expression[]> {
    const results = await this.db.expressions.findByIds(ids)
    return results.map((e: any) => this.db.formatTimestamps(e))
  }

  async create(data: any, username: string): Promise<Expression> {
    const id = this.db.stableExpressionId(data.text, data.language_code)
    const expressionData = {
      ...data,
      id,
      created_by: data.created_by || username
    }
    const expression = await this.db.expressions.create(expressionData)
    this.db.clearStatisticsCache()
    return this.db.formatTimestamps(expression)
  }

  async update(id: number, data: any, username: string): Promise<Expression> {
    const expressionData = {
      ...data,
      updated_by: data.updated_by || username
    }
    const expression = await this.db.expressions.update(id, expressionData)
    if (!expression) {
      throw new NotFoundError('Expression')
    }
    return this.db.formatTimestamps(expression)
  }

  async delete(id: number): Promise<void> {
    const success = await this.db.deleteExpression(id)
    if (!success) {
      throw new NotFoundError('Expression')
    }
    this.db.clearStatisticsCache()
  }

  async batchUpsert(expressions: any[], ensureNewMeaning: boolean, username: string): Promise<any> {
    const forceNewMeaning = ensureNewMeaning === true

    const exprsWithIds = expressions.map(expr => {
      if (!expr.text || !expr.language_code) {
        throw new Error('Text and language_code are required for all expressions')
      }
      return {
        ...expr,
        id: this.db.stableExpressionId(expr.text, expr.language_code),
        created_by: expr.created_by || username
      }
    })

    const results = await this.db.upsertExpressions(exprsWithIds, forceNewMeaning)
    return { results }
  }

  async ensureExist(expressions: any[], username: string): Promise<any> {
    return this.db.ensureExpressionsExist(expressions, username)
  }

  async getVersions(id: number): Promise<any[]> {
    const results = await this.db.expressions.getVersions(id)
    return results.map((v: any) => this.db.formatTimestamps(v))
  }

  async addMeaning(expressionId: number, meaningId: number, username: string): Promise<void> {
    const expression = await this.db.expressions.findById(expressionId)
    if (!expression) {
      throw new NotFoundError('Expression')
    }
    const now = new Date().toISOString()
    await this.db.meanings.ensureMeaningExists(meaningId, username, now)
    await this.db.meanings.addExpressionMeaning(expressionId, meaningId, now)
  }

  async removeMeaning(expressionId: number, meaningId: number): Promise<void> {
    const success = await this.db.meanings.removeExpressionMeaning(expressionId, meaningId)
    if (!success) {
      throw new NotFoundError('Expression-meaning relationship')
    }
  }
}
