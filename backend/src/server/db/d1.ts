import { AbstractDatabaseService, Language, Expression, Meaning, ExpressionVersion, User, Statistics, HeatmapData, Collection, CollectionItem, Handbook, UILocale, ExpressionGroup } from './protocol.js'
import { ExpressionQueries } from './queries/expression.js'
import { UserQueries } from './queries/user.js'
import { CollectionQueries } from './queries/collection.js'
import { MeaningQueries } from './queries/meaning.js'
import { LanguageQueries } from './queries/language.js'
import { HandbookQueries } from './queries/handbook.js'
import { MetaQueries } from './queries/meta.js'
import { ExpressionGroupQueries } from './queries/expression_group.js'

// Cache for statistics
let statisticsCache: {
  data: Statistics | null;
  timestamp: number | null;
} = {
  data: null,
  timestamp: null
};
const CACHE_DURATION = 30 * 60 * 1000; // 10 minutes in milliseconds

// Cache for heatmap data
let heatmapCache: {
  data: HeatmapData[] | null;
  timestamp: number | null;
} = {
  data: null,
  timestamp: null
};
const HEATMAP_CACHE_DURATION = 30 * 60 * 1000; // 10 minutes in milliseconds

// Cache for languages
let languagesCache: {
  data: Language[] | null;
  timestamp: number | null;
} = {
  data: null,
  timestamp: null
};
const LANGUAGES_CACHE_DURATION = 30 * 60 * 1000; // 30 minutes in milliseconds

export class D1DatabaseService extends AbstractDatabaseService {

  private db: D1Database
  private expressionQueries: ExpressionQueries
  private userQueries: UserQueries
  private collectionQueries: CollectionQueries
  private meaningQueries: MeaningQueries
  private languageQueries: LanguageQueries
  private handbookQueries: HandbookQueries
  private metaQueries: MetaQueries
  private groupQueries: ExpressionGroupQueries

  constructor(db: D1Database) {
    super()
    this.db = db
    this.expressionQueries = new ExpressionQueries(db)
    this.userQueries = new UserQueries(db)
    this.collectionQueries = new CollectionQueries(db)
    this.meaningQueries = new MeaningQueries(db)
    this.languageQueries = new LanguageQueries(db)
    this.handbookQueries = new HandbookQueries(db)
    this.metaQueries = new MetaQueries(db)
    this.groupQueries = new ExpressionGroupQueries(db)
  }

  // Query getters
  get expressions() { return this.expressionQueries }
  get users() { return this.userQueries }
  get collections() { return this.collectionQueries }
  get meanings() { return this.meaningQueries }
  get languages() { return this.languageQueries }
  get handbooks() { return this.handbookQueries }
  get meta() { return this.metaQueries }
  get groups() { return this.groupQueries }
  async getLanguages(isActive?: number): Promise<Language[]> {
    const now = Date.now()

    // Check if cache is valid
    const isCacheValid = !!(languagesCache.data && languagesCache.timestamp &&
      (now - languagesCache.timestamp) < LANGUAGES_CACHE_DURATION)

    if (isCacheValid) {
      console.log('Returning cached languages')
      let results = languagesCache.data || []
      if (isActive !== undefined && !isNaN(isActive)) {
        results = results.filter(l => (l.is_active ? 1 : 0) === isActive)
      }
      return results
    }

    try {
      console.log('Fetching fresh languages from database')
      const results = await this.languageQueries.findAll()

      // Update cache
      languagesCache.data = results
      languagesCache.timestamp = now

      if (isActive !== undefined && !isNaN(isActive)) {
        return results.filter(l => (l.is_active ? 1 : 0) === isActive)
      }

      return results
    } catch (error) {
      console.error('Error in getLanguages:', error)
      throw error
    }
  }

  async getLanguageByCode(code: string): Promise<Language | null> {
    const now = Date.now()
    if (languagesCache.data && languagesCache.timestamp &&
      (now - languagesCache.timestamp) < LANGUAGES_CACHE_DURATION) {
      const language = languagesCache.data.find(l => l.code === code)
      if (language) {
        console.log('Returning cached language by code:', code)
        return language
      }
    }
    return this.languageQueries.findByCode(code)
  }

  async createLanguage(language: Partial<Language>): Promise<Language> {
    const code = language.code || ''
    const id = this.stableHashId(code)
    const result = await this.languageQueries.create(id, language)

    // Clear all related caches
    this.clearStatisticsCache()
    this.clearHeatmapCache()
    this.clearLanguagesCache()

    return result
  }

  async updateLanguage(id: number, language: Partial<Language>): Promise<Language> {
    const result = await this.languageQueries.update(id, language)

    // Clear all related caches
    this.clearStatisticsCache()
    this.clearHeatmapCache()
    this.clearLanguagesCache()

    return result
  }

  async deleteLanguage(id: number): Promise<boolean> {
    const success = await this.languageQueries.delete(id)
    if (success) {
      this.clearStatisticsCache()
      this.clearHeatmapCache()
      this.clearLanguagesCache()
    }
    return success
  }

  // Expression operations
  async getExpressions(skip: number = 0, limit: number = 50, language?: string, meaningId?: number | number[], tagPrefix?: string, excludeTagPrefix?: string, includeMeanings?: boolean): Promise<Expression[]> {
    const results = await this.expressionQueries.findAll(skip, limit, {
      language,
      meaningId,
      tagPrefix,
      excludeTagPrefix
    })

    const formattedResults = results.map(e => this.formatTimestamps(e))

    if (includeMeanings) {
      for (const expr of formattedResults) {
        expr.meanings = await this.getMeaningsByExpressionId(expr.id)
      }
    }

    return formattedResults
  }

  async getExpressionById(id: number): Promise<Expression | null> {
    const expression = await this.expressionQueries.findById(id)
    if (!expression) return null

    const formattedExpr = this.formatTimestamps(expression)

    const meanings = await this.getMeaningsByExpressionId(id)
    formattedExpr.meanings = meanings

    return formattedExpr
  }

  async getExpressionsByIds(ids: number[]): Promise<Expression[]> {
    return this.expressionQueries.findByIds(ids)
  }

  async getExpressionMeaningIds(expressionIds: number[]): Promise<Map<number, number[]>> {
    return this.expressionQueries.findMeaningIds(expressionIds)
  }

  async upsertExpressions(expressions: Partial<Expression>[], forceNewMeaning: boolean = false): Promise<Array<{ id: number, expression?: Expression, error?: string }>> {
    console.log('[upsertExpressions] Starting batch upsert with', expressions.length, 'expressions', 'forceNewMeaning:', forceNewMeaning)

    if (expressions.length === 0) return []

    const LANGUAGE_PRIORITY = [
      'en-GB', 'en-US', 'zh-TW', 'zh-CN',
      'hi-IN', 'es-ES', 'fr-FR', 'ar-SA',
      'bn-IN', 'pt-BR', 'ru-RU', 'ur-PK',
      'id-ID', 'de-DE', 'ja-JP', 'ko-KR',
      'tr-TR', 'it-IT'
    ]

    const results: Array<{ id: number, expression?: Expression, error?: string }> = []

    const ids = expressions
      .filter(e => e.id !== undefined)
      .map(e => e.id!)

    let existingExprs: Expression[] = []
    if (ids.length > 0) {
      existingExprs = await this.getExpressionsByIds(ids)
    }

    const existingMap = new Map<number, Expression>(
      existingExprs.map(e => [e.id, e])
    )

    const existingMeaningIds = await this.getExpressionMeaningIds(ids)

    const sortedExprs = [...expressions].sort((a, b) => {
      if (!a.text || !a.language_code || !b.text || !b.language_code) {
        return 0
      }
      const indexA = LANGUAGE_PRIORITY.indexOf(a.language_code)
      const indexB = LANGUAGE_PRIORITY.indexOf(b.language_code)

      const priorityA = indexA === -1 ? 999 : indexA
      const priorityB = indexB === -1 ? 999 : indexB

      return priorityA - priorityB
    })

    let finalMeaningId: number | undefined

    const meaningIds: number[] = []
    for (const expr of sortedExprs) {
      if (expr.id === undefined) continue
      const existingMeanings = existingMeaningIds.get(expr.id)
      if (existingMeanings && existingMeanings.length > 0) {
        meaningIds.push(...existingMeanings)
      }
    }

    const uniqueMeaningIds = [...new Set(meaningIds)]

    if (forceNewMeaning) {
      console.log('[upsertExpressions] Force new meaning mode enabled')
      console.log('[upsertExpressions] Existing meaning_ids to exclude:', uniqueMeaningIds)

      for (const expr of sortedExprs) {
        if (!expr.id) continue

        const exprId = expr.id
        if (!uniqueMeaningIds.includes(exprId)) {
          finalMeaningId = exprId
          console.log('[upsertExpressions] Selected new expression ID as meaning_id (force new):', finalMeaningId)
          break
        }
      }

      if (!finalMeaningId && sortedExprs.length > 0) {
        finalMeaningId = sortedExprs[0].id
        console.log('[upsertExpressions] All expression IDs already used as meaning_ids, using first as fallback:', finalMeaningId)
      }
    } else {
      if (meaningIds.length === 0) {
        if (sortedExprs.length > 0 && sortedExprs[0].text && sortedExprs[0].language_code) {
          const firstExpr = sortedExprs[0]
          const firstId = this.stableExpressionId(firstExpr.text!, firstExpr.language_code!)
          finalMeaningId = firstId
          console.log('[upsertExpressions] No meaning_ids found, using first expression ID as meaning_id:', finalMeaningId)
        }
      } else {
        if (uniqueMeaningIds.length === 1) {
          finalMeaningId = uniqueMeaningIds[0]
          console.log('[upsertExpressions] All expressions share same meaning_id:', finalMeaningId)
        } else {
          console.log('[upsertExpressions] Multiple different meaning_ids found:', uniqueMeaningIds)
          for (const expr of sortedExprs) {
            if (!expr.id) continue

            const id = this.stableExpressionId(expr.text!, expr.language_code!)
            if (!uniqueMeaningIds.includes(id)) {
              finalMeaningId = id
              console.log('[upsertExpressions] Found expression with ID not in meaning_ids:', finalMeaningId)
              break
            }
          }

          if (!finalMeaningId && sortedExprs.length > 0) {
            finalMeaningId = sortedExprs[0].id
            console.log('[upsertExpressions] Using first expression ID as new meaning_id:', finalMeaningId)
          }
        }
      }
    }

    console.log('[upsertExpressions] Final meaning_id:', finalMeaningId)

    const statements = expressions.map(expr => {
      if (!expr.text || !expr.language_code) {
        throw new Error('Text and language_code are required for all expressions');
      }

      const id = this.stableExpressionId(expr.text, expr.language_code)

      return this.expressionQueries.prepareUpsert(expr)
    })

    const batchSize = 100
    for (let i = 0; i < statements.length; i += batchSize) {
      const batch = statements.slice(i, i + batchSize)
      const batchBatch = await this.db.batch<Expression>(batch)

      batchBatch.forEach((res, index) => {
        const originalIndex = i + index
        const exprId = this.stableExpressionId(expressions[originalIndex].text!, expressions[originalIndex].language_code!)

        if (res.results && res.results.length > 0) {
          results.push({ id: exprId, expression: res.results[0] })
        } else if (res.meta?.changes && res.meta.changes > 0) {
          results.push({ id: exprId })
        } else if (res.error) {
          results.push({ id: exprId, error: res.error })
        } else {
          results.push({ id: exprId, error: 'Statement executed but returned no data' })
        }
      })
    }

    if (finalMeaningId !== undefined) {
      const meaningIdsSet = new Set(meaningIds)
      const meaningExists = meaningIdsSet.has(finalMeaningId)

      if (!meaningExists) {
        console.log('[upsertExpressions] Creating new meaning record for meaning_id:', finalMeaningId)

        const firstExprWithMeaning = sortedExprs.find(e => e.id === finalMeaningId)
        const created_by = firstExprWithMeaning?.created_by || expressions[0]?.created_by

        await this.meaningQueries.ensureMeaningExists(finalMeaningId, created_by!, new Date().toISOString())
      }

      for (const expr of sortedExprs) {
        if (!expr.id) continue

        const exprId = this.stableExpressionId(expr.text!, expr.language_code!)
        const existingMeanings = existingMeaningIds.get(exprId) || []
        const meaningExistsForExpr = existingMeanings.includes(finalMeaningId)

        if (!meaningExistsForExpr) {
          console.log('[upsertExpressions] Creating expression_meaning relation:', exprId, '->', finalMeaningId)

          const now = new Date().toISOString()
          await this.meaningQueries.addExpressionMeaning(exprId, finalMeaningId, now)
        }
      }
    }

    const affectedLanguages = [...new Set(expressions.map(e => e.language_code).filter(Boolean))]
    for (const lang of affectedLanguages) {
      await this.expressionQueries.updateLanguageStatsFromCount(lang as string)
    }

    this.clearStatisticsCache()
    this.clearHeatmapCache()

    console.log('[upsertExpressions] Completed with', results.length, 'results')

    return results
  }

  async createExpression(expression: Partial<Expression>): Promise<Expression> {
    const id = this.stableExpressionId(expression.text!, expression.language_code!)
    const result = await this.expressionQueries.create({ ...expression, id })
    
    if (result) {
      await this.expressionQueries.updateLanguageStats(expression.language_code!, 1)
      this.clearStatisticsCache()
      this.clearHeatmapCache()
      
      if (expression.meaning_id) {
        await this.addExpressionMeaning(id, expression.meaning_id, expression.created_by || 'system')
      }
      return this.formatTimestamps(result)
    } else {
      const existing = await this.getExpressionById(id)
      if (!existing) throw new Error('Failed to create or fetch expression')
      return existing
    }
  }

  async ensureExpressionsExist(expressions: Array<{ text: string, language_code: string }>, username: string): Promise<Record<string, number>> {
    const expressionsWithIds = expressions.map(expr => ({
      ...expr,
      id: this.stableExpressionId(expr.text, expr.language_code)
    }))
    return this.expressionQueries.ensureExist(expressionsWithIds, username)
  }

  async updateExpression(id: number, expression: Partial<Expression>): Promise<Expression> {
    const result = await this.expressionQueries.update(id, expression)

    // Clear statistics and heatmap caches as we've updated an expression
    this.clearStatisticsCache()
    this.clearHeatmapCache()

    return this.formatTimestamps(result)
  }

  async deleteExpression(id: number): Promise<boolean> {
    const expression = await this.getExpressionById(id)
    if (!expression) return false

    try {
      await this.db.batch([
        this.expressionQueries.prepareDeleteMeaning(id),
        this.expressionQueries.prepareDeleteCollectionItems(id),
        this.expressionQueries.prepareDeleteVersions(id),
        this.expressionQueries.prepareDeleteFTS(id),
        this.expressionQueries.prepareDeleteExpression(id)
      ])

      await this.expressionQueries.updateLanguageStats(expression.language_code, -1)

      this.clearStatisticsCache()
      this.clearHeatmapCache()

      return true
    } catch (error) {
      console.error(`Error deleting expression ${id}:`, error)
      throw error
    }
  }

  async migrateExpressionId(oldId: number, newExpression: Partial<Expression>): Promise<Expression> {
    const result = await this.expressionQueries.migrateId(oldId, newExpression)
    return this.formatTimestamps(result) as Expression
  }

  /**
   * 智能语义锚点选择
   * 根据词句的语言优先级选择最合适的语义锚点
   */
  async selectSemanticAnchor(expressionIds: number[]): Promise<number | null> {
    return this.expressionQueries.selectSemanticAnchor(expressionIds)
  }

  async searchExpressions(query: string, fromLang?: string, region?: string, skip: number = 0, limit: number = 20, includeMeanings?: boolean): Promise<Expression[]> {
    if (!query.trim()) return []
    
    const results = await this.expressionQueries.search(query, fromLang, region, skip, limit)
    const formattedResults = results.map(e => this.formatTimestamps(e))

    if (includeMeanings) {
      for (const expr of formattedResults) {
        expr.meanings = await this.getMeaningsByExpressionId(expr.id)
      }
    }

    return formattedResults
  }

  // Meaning operations
  async getMeaningsByExpressionId(expressionId: number): Promise<Meaning[]> {
    return this.meaningQueries.findByExpressionId(expressionId)
  }

  async addExpressionMeaning(expressionId: number, meaningId: number, username: string): Promise<void> {
    const now = new Date().toISOString()
    await this.meaningQueries.ensureMeaningExists(meaningId, username, now)
    await this.meaningQueries.addExpressionMeaning(expressionId, meaningId, now)
    console.log('[addExpressionMeaning] Association created:', expressionId, '->', meaningId)
  }

  async removeExpressionMeaning(expressionId: number, meaningId: number): Promise<boolean> {
    return this.meaningQueries.removeExpressionMeaning(expressionId, meaningId)
  }

  // Clean up FTS index - remove entries for expressions that no longer exist
  async cleanupFTSIndex(): Promise<void> {
    const changes = await this.expressionQueries.cleanupFTSIndex()
    if (changes > 0) {
      console.log(`[FTS Cleanup] Removed ${changes} orphaned FTS entries`)
    }
  }


  // Expression version operations
  async getExpressionVersions(expressionId: number): Promise<ExpressionVersion[]> {
    const results = await this.expressionQueries.getVersions(expressionId)
    return results.map(v => this.formatTimestamps(v) as ExpressionVersion)
  }

  /**
   * Format timestamp fields to ensure ISO 8601 format with 'Z' suffix for UTC
   * This handles SQLite CURRENT_TIMESTAMP format (YYYY-MM-DD HH:MM:SS) by converting to ISO format
   */
  private formatTimestamps<T extends Record<string, any>>(obj: T): T {
    const result = { ...obj }
    const timestampFields = ['created_at', 'updated_at']

    for (const field of timestampFields) {
      if ((result as any)[field] && typeof (result as any)[field] === 'string') {
        const timestamp = (result as any)[field] as string
        if (timestamp.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/)) {
          (result as any)[field] = timestamp + 'Z'
        }
      }
    }

    return result
  }

  async createExpressionVersion(version: Partial<ExpressionVersion>): Promise<ExpressionVersion> {
    const expressionId = version.expression_id
    const text = version.text || ''
    if (!expressionId || !text) {
      throw new Error('expression_id and text are required')
    }
    const now = Date.now()
    const id = this.stableExpressionVersionId(expressionId, version.created_at || now)
    const result = await this.expressionQueries.createVersion(id, version)
    return this.formatTimestamps(result) as ExpressionVersion
  }

  // Users
  async getUserByUsername(username: string): Promise<User | null> {
    return this.userQueries.findByUsername(username)
  }

  async getUserByEmail(email: string): Promise<User | null> {
    return this.userQueries.findByEmail(email)
  }

  async getUserById(id: number): Promise<User | null> {
    return this.userQueries.findById(id)
  }

  async createUser(user: Partial<User>): Promise<User> {
    const username = user.username || ''
    const id = this.stableHashId(username)
    return this.userQueries.create(id, user)
  }

  // Email verification methods
  async createEmailVerificationToken(token: string, userId: number, expiresAt: string): Promise<void> {
    return this.userQueries.createVerificationToken(token, userId, expiresAt)
  }

  async getEmailVerificationToken(token: string): Promise<{ user_id: number, expires_at: string } | null> {
    return this.userQueries.findVerificationToken(token)
  }

  async deleteEmailVerificationToken(token: string): Promise<void> {
    return this.userQueries.deleteVerificationToken(token)
  }

  async setEmailVerified(userId: number): Promise<void> {
    return this.userQueries.setEmailVerified(userId)
  }

  // Statistics
  async getStatistics(): Promise<Statistics> {
    const now = Date.now()
    if (statisticsCache.data && statisticsCache.timestamp &&
      (now - statisticsCache.timestamp) < CACHE_DURATION) {
      return statisticsCache.data
    }

    const stats = await this.metaQueries.getStatistics()
    statisticsCache.data = stats
    statisticsCache.timestamp = now
    return stats
  }

  // Method to clear statistics cache (to be called when data changes)
  clearStatisticsCache(): void {
    statisticsCache.data = null;
    statisticsCache.timestamp = null;
    console.log('Statistics cache cleared');
  }

  // Heatmap
  async getHeatmapData(): Promise<HeatmapData[]> {
    const now = Date.now()
    if (heatmapCache.data && heatmapCache.timestamp &&
      (now - heatmapCache.timestamp) < HEATMAP_CACHE_DURATION) {
      return heatmapCache.data
    }

    const results = await this.metaQueries.getHeatmapData()
    heatmapCache.data = results
    heatmapCache.timestamp = now
    return results
  }

  // Method to clear heatmap cache (to be called when data changes)
  clearHeatmapCache(): void {
    heatmapCache.data = null;
    heatmapCache.timestamp = null;
    console.log('Heatmap cache cleared');
  }

  // Method to clear languages cache
  clearLanguagesCache(): void {
    languagesCache.data = null;
    languagesCache.timestamp = null;
    console.log('Languages cache cleared');
  }

  // Collections
  async getCollections(userId?: number, isPublic?: boolean, skip: number = 0, limit: number = 20): Promise<Collection[]> {
    return this.collectionQueries.findAll(userId, isPublic, skip, limit)
  }

  async getCollectionById(id: number): Promise<Collection | null> {
    return this.collectionQueries.findById(id)
  }

  async createCollection(collection: Partial<Collection>): Promise<Collection> {
    const userId = collection.user_id
    const name = collection.name
    if (!userId || !name) {
      throw new Error('User ID and name are required')
    }
    const id = this.stableCollectionId(userId, name)
    return this.collectionQueries.create(id, userId, name, collection.description || null, !!collection.is_public)
  }

  async updateCollection(id: number, collection: Partial<Collection>): Promise<Collection> {
    return this.collectionQueries.update(id, collection)
  }

  async deleteCollection(id: number): Promise<boolean> {
    // Delete items first (cascade simulation)
    await this.db.batch([
      this.collectionQueries.prepareDeleteItems(id),
      this.collectionQueries.prepareDeleteCollection(id)
    ])
    return true
  }

  // Collection Items
  async getCollectionItems(collectionId: number, skip: number = 0, limit: number = 50): Promise<CollectionItem[]> {
    return this.collectionQueries.findItems(collectionId, skip, limit)
  }

  async addCollectionItem(item: Partial<CollectionItem>): Promise<CollectionItem> {
    const collectionId = item.collection_id
    const expressionId = item.expression_id

    if (!collectionId || !expressionId) {
      throw new Error('Collection ID and Expression ID are required')
    }

    const existing = await this.getCollectionItem(collectionId, expressionId)
    if (existing) return existing

    const id = this.stableCollectionItemId(collectionId, expressionId)
    return this.collectionQueries.addItem(id, collectionId, expressionId, item.note || null)
  }

  async removeCollectionItem(collectionId: number, expressionId: number): Promise<boolean> {
    return this.collectionQueries.removeItem(collectionId, expressionId)
  }

  async getCollectionItem(collectionId: number, expressionId: number): Promise<CollectionItem | null> {
    return this.collectionQueries.findItem(collectionId, expressionId)
  }

  async getCollectionsContainingItem(userId: number, expressionId: number): Promise<number[]> {
    return this.collectionQueries.findContainingCollections(userId, expressionId)
  }

  /**
   * Generate a stable Expression ID using FNV-1a 32-bit hash.
   * @param text 
   * @param languageCode 
   * @returns 
   */
  public stableExpressionId(text: string, languageCode: string): number {
    return this.stableHashId(`${text}|${languageCode}`)
  }

  /**
   * Generate a stable Collection ID using FNV-1a 32-bit hash.
   * @param userId 
   * @param name 
   * @returns 
   */
  private stableCollectionId(userId: number, name: string): number {
    return this.stableHashId(`${userId}|${name}`)
  }

  // Handbooks
  async getHandbooks(userId?: number, isPublic?: boolean, skip: number = 0, limit: number = 20): Promise<Handbook[]> {
    const results = await this.handbookQueries.findAll(userId, isPublic, skip, limit)
    return results.map(h => this.formatTimestamps(h) as Handbook)
  }

  async getHandbookById(id: number): Promise<Handbook | null> {
    const handbook = await this.handbookQueries.findById(id)
    if (!handbook) return null
    return this.formatTimestamps(handbook) as Handbook
  }

  async createHandbook(handbook: Partial<Handbook>): Promise<Handbook> {
    const id = this.stableHashId(`${handbook.user_id}|${handbook.title}|${Date.now()}`)
    const result = await this.handbookQueries.create(id, handbook)
    return this.formatTimestamps(result) as Handbook
  }

  async updateHandbook(id: number, handbook: Partial<Handbook>): Promise<Handbook> {
    const result = await this.handbookQueries.update(id, handbook)
    return this.formatTimestamps(result) as Handbook
  }

  async deleteHandbook(id: number): Promise<boolean> {
    return this.handbookQueries.delete(id)
  }

  // Handbook Renders (JSON column based)
  async getHandbookRender(id: number, targetLang: string): Promise<any | null> {
    const render = await this.handbookQueries.getRender(id, targetLang)
    if (!render) return null

    // Check TTL (24 hours)
    const renderedTime = render.at || new Date(render.created_at).getTime()
    const now = Date.now()
    if (now - renderedTime > 24 * 3600 * 1000) {
      return null // Expired
    }

    return render
  }

  async saveHandbookRender(renderData: {
    handbook_id: number;
    target_lang: string;
    rendered_title: string;
    rendered_description?: string;
    rendered_content: string;
  }): Promise<void> {
    await this.handbookQueries.saveRender({
      ...renderData,
      rendered_description: renderData.rendered_description || ''
    })
  }

  async invalidateHandbookRenders(id: number): Promise<void> {
    await this.handbookQueries.updateRenders(id, '{}')
  }

  // UI Locale methods (NEW - replaces UI translations)
  async getUILocale(languageCode: string): Promise<UILocale | null> {
    const result = await this.metaQueries.getUILocale(languageCode)
    return result ? this.formatTimestamps(result) : null
  }

  async saveUILocale(languageCode: string, localeJson: string, username: string): Promise<UILocale> {
    const result = await this.metaQueries.saveUILocale(languageCode, localeJson, username)
    return this.formatTimestamps(result)
  }

  async deleteUILocale(languageCode: string): Promise<boolean> {
    return this.metaQueries.deleteUILocale(languageCode)
  }

  /**
   * Generate a stable Collection Item ID using FNV-1a 32-bit hash.
   * @param collectionId 
   * @param expressionId 
   * @returns 
   */
  private stableCollectionItemId(collectionId: number, expressionId: number): number {
    return this.stableHashId(`${collectionId}|${expressionId}`)
  }

  /**
   * Generate a stable Expression Version ID using FNV-1a 32-bit hash.
   * @param expressionId 
   * @param createdAt 
   * @returns 
   */
  private stableExpressionVersionId(expressionId: number, createdAt: string | number): number {
    return this.stableHashId(`${expressionId}|${createdAt}`)
  }

  /**
   * Generate a stable ID based on content using FNV-1a 32-bit hash.
   * This ensures that the same content always produces the same ID.
   * 
   * @param content String content to hash
   * @returns Stable integer ID derived from the content hash
   */
  private stableHashId(content: string): number {
    let h = 0x811c9dc5;  // FNV offset basis
    for (let i = 0; i < content.length; i++) {
      h ^= content.charCodeAt(i);
      h = Math.imul(h, 0x01000193); // FNV prime
    }
    h = h >>> 0; // convert to unsigned int32

    // Ensure we don't get 0 as ID (minimum ID should be 1)
    return (h % (2 ** 31 - 1)) + 1;
  }

  /**
   * 合并词句组
   * 将源词句组中的所有词句添加到目标词句组，然后删除源词句组
   */
  async mergeMeaningGroups(sourceMeaningId: number, targetMeaningId: number): Promise<{
    success: boolean
    merged_count: number
    target_meaning_id: number
  }> {
    const result = await this.meaningQueries.mergeGroups(sourceMeaningId, targetMeaningId)
    return {
      ...result,
      target_meaning_id: targetMeaningId
    }
  }

  // ExpressionGroup operations
  async getGroupExpressions(groupId: number, languages?: string[]): Promise<Expression[]> {
    return this.groupQueries.getGroupExpressions(groupId, languages)
  }

  async getGroupInfo(groupId: number, languages?: string[]): Promise<ExpressionGroup | null> {
    return this.groupQueries.getGroupInfo(groupId, languages)
  }

  async getExpressionGroups(expressionId: number): Promise<ExpressionGroup[]> {
    return this.groupQueries.getExpressionGroups(expressionId)
  }

  async addToGroup(expressionId: number, groupId: number, username: string): Promise<boolean> {
    return this.groupQueries.addToGroup(expressionId, groupId, username)
  }

  async removeFromGroup(expressionId: number, groupId: number): Promise<boolean> {
    return this.groupQueries.removeFromGroup(expressionId, groupId)
  }

  async createGroup(anchorExpressionId: number, username: string): Promise<number> {
    return this.groupQueries.createGroup(anchorExpressionId, username)
  }

  async batchAddToGroup(expressionIds: number[], groupId: number, username: string): Promise<number> {
    return this.groupQueries.batchAddToGroup(expressionIds, groupId, username)
  }

  async mergeGroups(sourceGroupId: number, targetGroupId: number): Promise<{ success: boolean, merged_count: number }> {
    return this.groupQueries.mergeGroups(sourceGroupId, targetGroupId)
  }

  async deleteGroup(groupId: number): Promise<boolean> {
    return this.groupQueries.deleteGroup(groupId)
  }

  async listGroups(skip: number = 0, limit: number = 20, languages?: string[]): Promise<ExpressionGroup[]> {
    return this.groupQueries.listGroups(skip, limit, languages)
  }

  async searchGroups(query: string, skip: number = 0, limit: number = 20, languages?: string[]): Promise<ExpressionGroup[]> {
    return this.groupQueries.searchGroups(query, skip, limit, languages)
  }
}
