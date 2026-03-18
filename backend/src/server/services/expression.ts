import type { Expression } from '../types/entity.js'
import { NotFoundError } from '../types/error.js'

interface DBService {
  getExpressions(skip: number, limit: number, language?: string, meaningId?: number | number[], tagPrefix?: string, excludeTagPrefix?: string, includeMeanings?: boolean): Promise<Expression[]>
  getExpressionById(id: number): Promise<Expression | null>
  getExpressionsByIds(ids: number[]): Promise<Expression[]>
  createExpression(data: any): Promise<Expression>
  updateExpression(id: number, data: any): Promise<Expression | null>
  deleteExpression(id: number): Promise<boolean>
  upsertExpressions(expressions: any[], forceNewMeaning: boolean): Promise<any[]>
  ensureExpressionsExist(expressions: any[], username: string): Promise<any>
  getExpressionVersions(id: number): Promise<any[]>
  getExpressionMeaningIds(expressionIds: number[]): Promise<Map<number, number[]>>
  addExpressionMeaning(expressionId: number, meaningId: number, username: string): Promise<void>
  removeExpressionMeaning(expressionId: number, meaningId: number): Promise<boolean>
  migrateExpressionId(oldId: number, newData: any): Promise<Expression | null>
  stableExpressionId(text: string, languageCode: string): number
  selectSemanticAnchor(expressionIds: number[]): Promise<number | undefined>
  clearStatisticsCache(): void
  clearHeatmapCache(): void
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
    return this.db.getExpressions(
      skip,
      limit,
      filters.language,
      filters.meaningId,
      filters.tagPrefix,
      filters.excludeTagPrefix,
      filters.includeMeanings
    )
  }

  async getById(id: number): Promise<Expression> {
    const expression = await this.db.getExpressionById(id)
    if (!expression) {
      throw new NotFoundError('Expression')
    }
    return expression
  }

  async getByIds(ids: number[]): Promise<Expression[]> {
    return this.db.getExpressionsByIds(ids)
  }

  async create(data: any, username: string): Promise<Expression> {
    const expressionData = {
      ...data,
      created_by: data.created_by || username
    }
    const expression = await this.db.createExpression(expressionData)
    this.db.clearStatisticsCache()
    return expression
  }

  async update(id: number, data: any, username: string): Promise<Expression> {
    const expressionData = {
      ...data,
      updated_by: data.updated_by || username
    }
    const expression = await this.db.updateExpression(id, expressionData)
    if (!expression) {
      throw new NotFoundError('Expression')
    }
    return expression
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
    return this.db.getExpressionVersions(id)
  }

  async addMeaning(expressionId: number, meaningId: number, username: string): Promise<void> {
    const expression = await this.db.getExpressionById(expressionId)
    if (!expression) {
      throw new NotFoundError('Expression')
    }
    await this.db.addExpressionMeaning(expressionId, meaningId, username)
  }

  async removeMeaning(expressionId: number, meaningId: number): Promise<void> {
    const success = await this.db.removeExpressionMeaning(expressionId, meaningId)
    if (!success) {
      throw new NotFoundError('Expression-meaning relationship')
    }
  }
}
