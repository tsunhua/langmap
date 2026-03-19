// D1 Database Service Implementation
import { D1Database } from '@cloudflare/workers-types'
import { AbstractDatabaseService, Language, Expression, Meaning, ExpressionVersion, User, Statistics, HeatmapData, Collection, CollectionItem, Handbook } from './protocol'

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

  constructor(db: D1Database) {
    super()
    this.db = db
  }

  // Language operations
  async getLanguages(isActive?: number): Promise<Language[]> {
    const now = Date.now();

    // Check if cache is valid
    const isCacheValid = !!(languagesCache.data && languagesCache.timestamp &&
      (now - languagesCache.timestamp) < LANGUAGES_CACHE_DURATION);

    if (isCacheValid) {
      console.log('Returning cached languages');
      let results = languagesCache.data || [];
      if (isActive !== undefined && !isNaN(isActive)) {
        // Use loose equality or cast to number to handle 0/1 vs boolean
        results = results.filter(l => (l.is_active ? 1 : 0) === isActive);
      }
      return results;
    }

    try {
      console.log('Fetching fresh languages from database');
      const response = await this.db.prepare('SELECT * FROM languages ORDER BY code').all<Language>();

      const results = response.results || [];

      // Update cache
      languagesCache.data = results;
      languagesCache.timestamp = now;

      if (isActive !== undefined && !isNaN(isActive)) {
        return results.filter(l => (l.is_active ? 1 : 0) === isActive);
      }

      return results;
    } catch (error) {
      console.error('Error in getLanguages:', error);
      throw error;
    }
  }

  async getLanguageByCode(code: string): Promise<Language | null> {
    const now = Date.now();
    if (languagesCache.data && languagesCache.timestamp &&
      (now - languagesCache.timestamp) < LANGUAGES_CACHE_DURATION) {
      const language = languagesCache.data.find(l => l.code === code);
      if (language) {
        console.log('Returning cached language by code:', code);
        return language;
      }
    }

    const language = await this.db.prepare(
      'SELECT * FROM languages WHERE code = ?'
    ).bind(code).first<Language>()
    return language || null
  }

  async createLanguage(language: Partial<Language>): Promise<Language> {
    // Generate stable ID based on language code
    const code = language.code || '';
    const id = this.stableHashId(code);

    // Filter out undefined values and replace them with null
    const bindValues = [
      id,
      language.code || null,
      language.name || null,
      language.direction || 'ltr',
      language.is_active !== undefined ? language.is_active : 0,
      language.region_code || null,
      language.region_name || null,
      language.region_latitude !== undefined ? language.region_latitude : null,
      language.region_longitude !== undefined ? language.region_longitude : null,
      language.group_name || null,
      language.created_by || null,
      language.updated_by || null
    ];

    const result = await this.db.prepare(
      `INSERT INTO languages (
        id, code, name, direction, is_active, region_code, region_name, 
        region_latitude, region_longitude, group_name, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<Language>()

    if (!result) {
      throw new Error('Failed to create language')
    }

    // Clear all related caches
    this.clearStatisticsCache();
    this.clearHeatmapCache();
    this.clearLanguagesCache();

    return result;
  }

  async updateLanguage(id: number, language: Partial<Language>): Promise<Language> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(language).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(value)
      }
    })

    values.push(id)

    const result = await this.db.prepare(
      `UPDATE languages SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).first<Language>()

    if (!result) {
      throw new Error('Failed to update language')
    }

    // Clear all related caches
    this.clearStatisticsCache();
    this.clearHeatmapCache();
    this.clearLanguagesCache();

    return result;
  }

  async deleteLanguage(id: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM languages WHERE id = ?'
    ).bind(id).run()

    if (result.changes > 0) {
      // Clear all related caches
      this.clearStatisticsCache();
      this.clearHeatmapCache();
      this.clearLanguagesCache();
      return true;
    }

    return false;
  }

  // Expression operations
  async getExpressions(skip: number = 0, limit: number = 50, language?: string, meaningId?: number | number[], tagPrefix?: string, excludeTagPrefix?: string, includeMeanings?: boolean): Promise<Expression[]> {
    let query = 'SELECT * FROM expressions'
    const bindings: any[] = []

    // Handle WHERE conditions
    const whereConditions: string[] = [];

    if (language) {
      whereConditions.push('language_code = ?');
      bindings.push(language);
    }

    if (meaningId !== undefined) {
      // Use expression_meaning table instead of expressions.meaning_id field
      query = 'SELECT e.* FROM expressions e'

      if (Array.isArray(meaningId)) {
        // Handle array of meaning IDs
        if (meaningId.length > 0) {
          whereConditions.push(`e.id IN (SELECT expression_id FROM expression_meaning WHERE meaning_id IN (SELECT value FROM json_each(?)))`);
          bindings.push(JSON.stringify(meaningId));
        } else {
          // Empty array means no results should be returned
          whereConditions.push('1 = 0'); // Always false condition
        }
      } else {
        // Handle single meaning ID
        if (meaningId === -1) {
          // Special case: get expressions with any meaning (has entry in expression_meaning)
          whereConditions.push('EXISTS (SELECT 1 FROM expression_meaning WHERE expression_id = e.id)');
        } else {
          whereConditions.push('e.id IN (SELECT expression_id FROM expression_meaning WHERE meaning_id = ?)');
          bindings.push(meaningId);
        }
      }
    }

    if (tagPrefix) {
      // Filter expressions that have the specified tag
      // tags is JSON array string like ["langmap.key", "category.name"]
      // Match the tag name anywhere in the tags field
      whereConditions.push("tags LIKE ?");
      bindings.push(`%${tagPrefix}%`);
    }

    if (excludeTagPrefix) {
      // Filter expressions that do NOT have the specified tag
      whereConditions.push("(tags IS NULL OR tags NOT LIKE ?)");
      bindings.push(`%${excludeTagPrefix}%`);
    }

    if (whereConditions.length > 0) {
      query += ' WHERE ' + whereConditions.join(' AND ');
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    bindings.push(limit, skip)

    console.log('[getExpressions] SQL:', query);
    console.log('[getExpressions] Bindings:', bindings);
    console.log('[getExpressions] Filter: tagPrefix=', tagPrefix, 'excludeTagPrefix=', excludeTagPrefix);

    const { results } = await this.db.prepare(query).bind(...bindings).all<Expression>()

    // Log first few results for debugging
    console.log('[getExpressions] Result count:', results.length);
    if (results.length > 0) {
      console.log('[getExpressions] First result id:', results[0].id, 'tags:', results[0].tags);
      if (excludeTagPrefix) {
        const tags = results[0].tags;
        const includesMatch = tags?.includes(excludeTagPrefix);
        const likeMatch = tags?.includes(excludeTagPrefix);
        console.log('[getExpressions] Exclude filter check:', {
          excludeTagPrefix,
          tagsValue: tags,
          tagsType: typeof tags,
          tagsLength: tags?.length,
          matchPattern: `%${excludeTagPrefix}%`,
          includesMatch,
          likeMatch,
          firstChar: tags?.[0],
          lastChar: tags?.[tags.length - 1]
        });
      }
    }

    const formattedResults = results.map(e => this.formatTimestamps(e))

    if (includeMeanings) {
      for (const expr of formattedResults) {
        const meanings = await this.getMeaningsByExpressionId(expr.id)
        expr.meanings = meanings
      }
    }

    return formattedResults
  }

  async getExpressionById(id: number): Promise<Expression | null> {
    const expression = await this.db.prepare(
      'SELECT * FROM expressions WHERE id = ?'
    ).bind(id).first<Expression>()
    if (!expression) return null

    const formattedExpr = this.formatTimestamps(expression)

    const meanings = await this.getMeaningsByExpressionId(id)
    formattedExpr.meanings = meanings

    return formattedExpr
  }

  async getExpressionsByIds(ids: number[]): Promise<Expression[]> {
    if (ids.length === 0) return [];

    const { results } = await this.db.prepare(
      `SELECT * FROM expressions WHERE id IN (SELECT value FROM json_each(?))`
    ).bind(JSON.stringify(ids)).all<Expression>();

    return results;
  }

  async getExpressionMeaningIds(expressionIds: number[]): Promise<Map<number, number[]>> {
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

      const bindValues = [
        id,
        expr.text,
        expr.audio_url || null,
        expr.language_code,
        expr.region_code || null,
        expr.region_name || null,
        expr.region_latitude !== undefined ? expr.region_latitude : null,
        expr.region_longitude !== undefined ? expr.region_longitude : null,
        expr.tags || null,
        expr.source_type || 'user',
        expr.source_ref || null,
        expr.review_status || 'pending',
        expr.created_by || null,
        expr.updated_by || null
      ]

      return this.db.prepare(
        `INSERT INTO expressions (
          id, text, audio_url, language_code, region_code, region_name, region_latitude,
          region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          tags = CASE WHEN excluded.tags IS NOT NULL THEN excluded.tags ELSE tags END,
          updated_at = CURRENT_TIMESTAMP,
          updated_by = CASE WHEN excluded.updated_by IS NOT NULL THEN excluded.updated_by ELSE updated_by END
        RETURNING *`
      ).bind(...bindValues)
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

        await this.db.prepare(
          'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)'
        ).bind(finalMeaningId, created_by).run()
      }

      for (const expr of sortedExprs) {
        if (!expr.id) continue

        const exprId = this.stableExpressionId(expr.text!, expr.language_code!)
        const existingMeanings = existingMeaningIds.get(exprId) || []
        const meaningExistsForExpr = existingMeanings.includes(finalMeaningId)

        if (!meaningExistsForExpr) {
          console.log('[upsertExpressions] Creating expression_meaning relation:', exprId, '->', finalMeaningId)

          const now = new Date().toISOString()
          await this.db.prepare(
            'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
          ).bind(`${exprId}-${finalMeaningId}`, exprId, finalMeaningId, now).run()
        }
      }
    }

    const affectedLanguages = [...new Set(expressions.map(e => e.language_code).filter(Boolean))]
    for (const lang of affectedLanguages) {
      await this.db.prepare(`
        INSERT OR REPLACE INTO language_stats (language_code, expression_count)
        SELECT ?, COUNT(*) FROM expressions WHERE language_code = ?
      `).bind(lang, lang).run()
    }

    this.clearStatisticsCache()
    this.clearHeatmapCache()

    console.log('[upsertExpressions] Completed with', results.length, 'results')

    return results
  }

  async createExpression(expression: Partial<Expression>): Promise<Expression> {
    try {
      if (!expression.text || !expression.language_code) {
        throw new Error('Text and language_code are required');
      }
      // Generate stable ID based on text, language_code and region_code
      const text = expression.text;
      const languageCode = expression.language_code;
      const id = this.stableExpressionId(text, languageCode);

      // Filter out undefined values and replace them with null
      const bindValues = [
        id,
        expression.text,
        expression.audio_url || null,
        expression.language_code,
        expression.region_code || null,
        expression.region_name || null,
        expression.region_latitude !== undefined ? expression.region_latitude : null,
        expression.region_longitude !== undefined ? expression.region_longitude : null,
        expression.tags || null,
        expression.source_type || 'user',
        expression.source_ref || null,
        expression.review_status || 'pending',
        expression.created_by || null,
        expression.updated_by || null
      ];

      const result = await this.db.prepare(
        `INSERT OR IGNORE INTO expressions (
          id, text, audio_url, language_code, region_code, region_name, region_latitude,
          region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
      ).bind(...bindValues).first<Expression>()

      let resultExpression: Expression;

      if (!result) {
        // Expression already exists, fetch it
        const existing = await this.db.prepare(
          'SELECT * FROM expressions WHERE id = ?'
        ).bind(id).first<Expression>()

        if (!existing) {
          console.error('Failed to fetch existing expression:', id);
          throw new Error('Failed to fetch existing expression')
        }

        resultExpression = existing;
      } else {
        // New expression inserted, update language_stats
        await this.db.prepare(`
          INSERT OR REPLACE INTO language_stats (language_code, expression_count)
          VALUES (?, COALESCE((SELECT expression_count FROM language_stats WHERE language_code = ?), 0) + 1)
        `).bind(languageCode, languageCode).run();

        // Clear statistics and heatmap caches as we've added a new expression
        this.clearStatisticsCache();
        this.clearHeatmapCache();

        resultExpression = result;
      }

      // Handle meaning_id association if provided
      if (expression.meaning_id !== undefined && expression.meaning_id !== null) {
        console.log('[createExpression] Adding meaning association:', id, '->', expression.meaning_id);
        await this.addExpressionMeaning(id, expression.meaning_id, expression.created_by || 'system');
      }

      return resultExpression;
    } catch (error) {
      console.error('Error creating expression:', error);
      throw error;
    }
  }

  async ensureExpressionsExist(expressions: Array<{ text: string, language_code: string }>, username: string): Promise<Record<string, number>> {
    const results: Record<string, number> = {}
    const now = new Date().toISOString()

    // Calculate IDs for all expressions
    const expressionsWithIds = expressions.map(expr => ({
      ...expr,
      id: this.stableExpressionId(expr.text, expr.language_code)
    }))

    // Batch check existing IDs (chunk to avoid "too many SQL variables")
    const idsToCheck = expressionsWithIds.map(e => e.id)
    const existingIdSet = new Set<number>()

    if (idsToCheck.length > 0) {
      const CHUNK_SIZE = 50
      for (let i = 0; i < idsToCheck.length; i += CHUNK_SIZE) {
        const chunk = idsToCheck.slice(i, i + CHUNK_SIZE)
        const placeholders = chunk.map(() => '?').join(',')
        const existingIds = await this.db.prepare(`
          SELECT id FROM expressions WHERE id IN (${placeholders})
        `).bind(...chunk).all<{ id: number }>()

        for (const row of existingIds.results || []) {
          existingIdSet.add(row.id)
        }
      }
    }

    // Separate new and existing expressions
    const newExpressions = expressionsWithIds.filter(e => !existingIdSet.has(e.id))
    const existingExpressions = expressionsWithIds.filter(e => existingIdSet.has(e.id))

    // Add existing expressions to results immediately
    for (const expr of existingExpressions) {
      results[`${expr.text}|${expr.language_code}`] = expr.id
    }

    // Batch insert new expressions in chunks
    if (newExpressions.length > 0) {
      const BATCH_SIZE = 50
      for (let i = 0; i < newExpressions.length; i += BATCH_SIZE) {
        const chunk = newExpressions.slice(i, i + BATCH_SIZE)
        const statements: any[] = []

        for (const expr of chunk) {
          statements.push(
            this.db.prepare(
              `INSERT INTO expressions (
                id, text, audio_url, language_code, region_code, region_name, region_latitude,
                region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
              ) VALUES (?, ?, NULL, ?, NULL, NULL, NULL, NULL, NULL, 'handbook', NULL, 'approved', ?, ?)`
            ).bind(expr.id, expr.text, expr.language_code, username, username)
          )
        }

        try {
          const batchResults = await this.db.batch(statements)
          for (let j = 0; j < chunk.length; j++) {
            const expr = chunk[j]
            results[`${expr.text}|${expr.language_code}`] = expr.id
          }
        } catch (error) {
          console.error('Failed to batch insert expressions:', error)
        }
      }
    }

    return results
  }

  async updateExpression(id: number, expression: Partial<Expression>): Promise<Expression> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(expression).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(value)
      }
    })

    values.push(id)

    const result = await this.db.prepare(
      `UPDATE expressions SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).first<Expression>()

    if (!result) {
      throw new Error('Failed to update expression')
    }

    // Clear statistics and heatmap caches as we've updated an expression
    this.clearStatisticsCache();
    this.clearHeatmapCache();

    return this.formatTimestamps(result);
  }

  async deleteExpression(id: number): Promise<boolean> {
    const expression = await this.getExpressionById(id);
    if (!expression) return false;

    try {
      // Use batch to delete all related records in a single transaction
      // This avoids foreign key constraint failures
      await this.db.batch([
        // 1. Delete from junction tables first
        this.db.prepare('DELETE FROM expression_meaning WHERE expression_id = ?').bind(id),
        this.db.prepare('DELETE FROM collection_items WHERE expression_id = ?').bind(id),

        // 2. Delete versions
        this.db.prepare('DELETE FROM expression_versions WHERE expression_id = ?').bind(id),

        // 3. Delete from FTS index
        this.db.prepare('DELETE FROM expressions_fts WHERE rowid = ?').bind(id),

        // 4. Finally delete the expression itself
        this.db.prepare('DELETE FROM expressions WHERE id = ?').bind(id),

        // 5. Update language_stats
        this.db.prepare(`
          UPDATE language_stats
          SET expression_count = MAX(0, expression_count - 1)
          WHERE language_code = ?
        `).bind(expression.language_code)
      ]);

      // Clear statistics and heatmap caches
      this.clearStatisticsCache();
      this.clearHeatmapCache();

      return true;
    } catch (error) {
      console.error(`Error deleting expression ${id}:`, error);
      throw error;
    }
  }

  async migrateExpressionId(oldId: number, newExpression: Partial<Expression>): Promise<Expression> {
    const db = this.db;

    // 1. Fetch current expression to ensure it exists and get its data
    const current = await this.getExpressionById(oldId);
    if (!current) {
      throw new Error('Expression not found');
    }

    // 2. Determine new ID
    const text = newExpression.text || current.text;
    const languageCode = newExpression.language_code || current.language_code;
    const newId = this.stableExpressionId(text, languageCode);

    // Get current regional data if not provided
    const regionName = newExpression.region_name !== undefined ? newExpression.region_name : current.region_name;
    const regionLat = newExpression.region_latitude !== undefined ? newExpression.region_latitude : current.region_latitude;
    const regionLong = newExpression.region_longitude !== undefined ? newExpression.region_longitude : current.region_longitude;

    if (oldId === newId) {
      // If ID hasn't changed, just do a normal update
      return this.updateExpression(oldId, newExpression);
    }

    // 3. Check if new ID already exists (collision)
    // If it exists, we might want to merge, but for now we throw error to be safe
    // or we could handle it by deleting old and letting the existing one stand.
    const collision = await this.getExpressionById(newId);
    if (collision) {
      // If target ID already exists, we effectively delete old one 
      // and redirect all its references to existing one.

      const statements: any[] = [];

      // - Update expression_meaning references (replace old expression_id with new expression_id)
      statements.push(db.prepare(`UPDATE expression_meaning SET expression_id = ? WHERE expression_id = ?`).bind(newId, oldId));

      // - Update collection items
      statements.push(db.prepare(`UPDATE collection_items SET expression_id = ? WHERE expression_id = ?`).bind(newId, oldId));

      // - Delete old
      statements.push(db.prepare(`DELETE FROM expressions WHERE id = ?`).bind(oldId));

      // - Delete from FTS index
      statements.push(db.prepare(`DELETE FROM expressions_fts WHERE rowid = ?`).bind(oldId));

      await db.batch(statements);

      // Update language_stats if collision occurred (old record deleted)
      await this.db.prepare(`
          UPDATE language_stats SET expression_count = MAX(0, expression_count - 1)
          WHERE language_code = ?
        `).bind(current.language_code).run();

      return collision;
    }

    // 4. Prepare the new record data
    const merged = { ...current, ...newExpression, id: newId };

    // 5. Execute migration in a single transaction (batch)
    const statements: any[] = [];

    // - Create version snapshot of OLD record (meaning_id field in expression_versions is deprecated, kept for historical reference)
    statements.push(db.prepare(
      `INSERT INTO expression_versions (expression_id, text, meaning_id, audio_url, region_name, region_latitude, region_longitude, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      oldId, current.text, current.meaning_id || null, current.audio_url || null,
      current.region_name || null, current.region_latitude || null, current.region_longitude || null,
      newExpression.updated_by || current.created_by || 'system'
    ));

    // - Update expression_meaning references (replace old expression_id with new expression_id)
    statements.push(db.prepare(
      `UPDATE expression_meaning SET expression_id = ? WHERE expression_id = ?`
    ).bind(newId, oldId));

    // - Update collection items
    statements.push(db.prepare(
      `UPDATE collection_items SET expression_id = ? WHERE expression_id = ?`
    ).bind(newId, oldId));

    // - Insert the NEW expression (meaning_id field is deprecated, always set to null)
    const bindValues = [
      newId,
      merged.text,
      null, // meaning_id is deprecated, use expression_meaning table instead
      merged.audio_url || null,
      merged.language_code,
      merged.region_code || null,
      merged.region_name || null,
      merged.region_latitude !== undefined ? merged.region_latitude : null,
      merged.region_longitude !== undefined ? merged.region_longitude : null,
      merged.tags || null,
      merged.source_type || 'user',
      merged.source_ref || null,
      merged.review_status || 'pending',
      merged.created_by || null,
      merged.updated_by || null
    ];

    statements.push(db.prepare(
      `INSERT INTO expressions (
        id, text, meaning_id, audio_url, language_code, region_code, region_name, region_latitude,
        region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(...bindValues));

    // - Delete the OLD record
    statements.push(db.prepare(`DELETE FROM expressions WHERE id = ?`).bind(oldId));

    // - Delete from FTS index
    statements.push(db.prepare(`DELETE FROM expressions_fts WHERE rowid = ?`).bind(oldId));

    // Run the batch
    await db.batch(statements);

    // Update language_stats if language changed or just to be safe
    const affectedLangs = [...new Set([current.language_code, merged.language_code])];
    for (const lang of affectedLangs) {
      await this.db.prepare(`
        INSERT OR REPLACE INTO language_stats (language_code, expression_count)
        SELECT ?, COUNT(*) FROM expressions WHERE language_code = ?
      `).bind(lang, lang).run();
    }

    // Fetch and return the new record
    const result = await this.getExpressionById(newId);
    if (!result) throw new Error('Migration failed');

    // Clear caches
    this.clearStatisticsCache();
    this.clearHeatmapCache();

    return result;
  }

  /**
   * 智能语义锚点选择
   * 根据词句的语言优先级选择最合适的语义锚点
   */
  async selectSemanticAnchor(expressionIds: number[]): Promise<number | null> {
    if (expressionIds.length === 0) return null;

    const LANGUAGE_PRIORITY = [
      'en-GB', 'en-US', 'zh-TW', 'zh-CN',
      'hi-IN', 'es-ES', 'fr-FR', 'ar-SA',
      'bn-IN', 'pt-BR', 'ru-RU', 'ur-PK',
      'id-ID', 'de-DE', 'ja-JP', 'ko-KR',
      'tr-TR', 'it-IT'
    ];

    try {
      const expressions = await this.getExpressionsByIds(expressionIds);
      const existingMeaningIds = await this.getExpressionMeaningIds(expressionIds);

      // 按语言优先级排序
      const sortedExprs = [...expressions].sort((a, b) => {
        const indexA = LANGUAGE_PRIORITY.indexOf(a.language_code);
        const indexB = LANGUAGE_PRIORITY.indexOf(b.language_code);

        const priorityA = indexA === -1 ? 999 : indexA;
        const priorityB = indexB === -1 ? 999 : indexB;

        return priorityA - priorityB;
      });

      // 遍历排序后的表达式，找到第一个有 meaning 关联的
      for (const expr of sortedExprs) {
        const meanings = existingMeaningIds.get(expr.id);
        if (meanings && meanings.length > 0) {
          return meanings[0];
        }
      }

      // 如果都没有 meaning 关联，返回排序后第一个表达式的 ID
      if (sortedExprs.length > 0) {
        return sortedExprs[0].id;
      }

      return null;
    } catch (error) {
      console.error('Error selecting semantic anchor:', error);
      return null;
    }
  }

  async searchExpressions(query: string, fromLang?: string, region?: string, skip: number = 0, limit: number = 20, includeMeanings?: boolean): Promise<Expression[]> {
    if (!query.trim()) return []
    // FTS5 搜索逻辑：使用 MATCH 实现极速检索
    // 将查询转义并添加 * 实现前缀匹配
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

    // 排序策略：精确匹配优先 > FTS 相关性 (rank) > 文本长度 > 创建时间
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

    // Format timestamps
    const formattedResults = results.map(e => this.formatTimestamps(e))

    // Add meanings if requested
    if (includeMeanings) {
      for (const expr of formattedResults) {
        const meanings = await this.getMeaningsByExpressionId(expr.id)
        expr.meanings = meanings
      }
    }

    return formattedResults
  }

  // Meaning operations
  async getMeaningsByExpressionId(expressionId: number): Promise<Meaning[]> {
    const { results } = await this.db.prepare(
      'SELECT m.* FROM meanings m JOIN expression_meaning em ON m.id = em.meaning_id WHERE em.expression_id = ? ORDER BY em.created_at DESC'
    ).bind(expressionId).all<Meaning>()
    return results || []
  }

  async addExpressionMeaning(expressionId: number, meaningId: number, username: string): Promise<void> {
    const now = new Date().toISOString()

    // Ensure meaning record exists
    await this.db.prepare(
      'INSERT OR IGNORE INTO meanings (id, created_by, created_at) VALUES (?, ?, ?)'
    ).bind(meaningId, username, now).run()

    // Create expression-meaning association
    const result: any = await this.db.prepare(
      'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${expressionId}-${meaningId}`, expressionId, meaningId, now).run()

    console.log('[addExpressionMeaning] Association created:', expressionId, '->', meaningId, 'result:', result);
  }

  async removeExpressionMeaning(expressionId: number, meaningId: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM expression_meaning WHERE expression_id = ? AND meaning_id = ?'
    ).bind(expressionId, meaningId).run()
    console.log('[removeExpressionMeaning] Result:', result);
    return result.success
  }

  // Clean up FTS index - remove entries for expressions that no longer exist
  async cleanupFTSIndex(): Promise<void> {
    try {
      const result = await this.db.prepare(`
        DELETE FROM expressions_fts
        WHERE rowid NOT IN (SELECT id FROM expressions)
      `).run();

      if (result.meta?.changes > 0) {
        console.log(`[FTS Cleanup] Removed ${result.meta.changes} orphaned FTS entries`);
      }
    } catch (error) {
      console.error('[FTS Cleanup] Error:', error);
    }
  }


  // Expression version operations
  async getExpressionVersions(expressionId: number): Promise<ExpressionVersion[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM expression_versions WHERE expression_id = ? ORDER BY created_at DESC'
    ).bind(expressionId).all<ExpressionVersion>()
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
    // Generate stable ID based on expression_id and text
    const expressionId = version.expression_id;
    const text = version.text || '';
    if (!expressionId || !text) {
      throw new Error('expression_id and text are required');
    }
    const now = Date.now();
    const id = this.stableExpressionVersionId(expressionId, version.created_at || now);

    // Filter out undefined values and replace them with null
    // Note: meaning_id field in expression_versions is deprecated, kept for historical reference only
    const bindValues = [
      id,
      version.expression_id || null,
      version.text || null,
      version.meaning_id !== undefined ? version.meaning_id : null,
      version.audio_url || null,
      version.region_name || null,
      version.region_latitude !== undefined ? version.region_latitude : null,
      version.region_longitude !== undefined ? version.region_longitude : null,
      version.created_by || null
    ];

    const result = await this.db.prepare(
      `INSERT INTO expression_versions (
        id, expression_id, text, meaning_id, audio_url, region_name, region_latitude,
        region_longitude, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<ExpressionVersion>()

    if (!result) {
      throw new Error('Failed to create expression version')
    }

    return result;
  }

  // Users
  async getUserByUsername(username: string): Promise<User | null> {
    const user = await this.db.prepare(
      'SELECT * FROM users WHERE username = ?'
    ).bind(username).first<User>()
    return user || null
  }

  async getUserByEmail(email: string): Promise<User | null> {
    const user = await this.db.prepare(
      'SELECT * FROM users WHERE email = ?'
    ).bind(email).first<User>()
    return user || null
  }

  async getUserById(id: number): Promise<User | null> {
    const user = await this.db.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(id).first<User>()
    return user || null
  }

  async createUser(user: Partial<User>): Promise<User> {
    // Generate stable ID based on username
    const username = user.username || '';
    const id = this.stableHashId(username);

    // Convert boolean email_verified to integer (0/1) for database storage
    const emailVerifiedInt = user.email_verified !== undefined
      ? (user.email_verified ? 1 : 0)
      : 0;

    // Filter out undefined values and replace them with null
    const bindValues = [
      id,
      user.username || null,
      user.email || null,
      user.password_hash || null,
      user.role || 'user',
      emailVerifiedInt
    ];

    const result: any = await this.db.prepare(
      `INSERT INTO users (
        id, username, email, password_hash, role, email_verified
      ) VALUES (?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).run()

    if (!result.success) {
      throw new Error('Failed to create user')
    }

    return result.results[0] as User
  }

  // Email verification methods
  async createEmailVerificationToken(token: string, userId: number, expiresAt: string): Promise<void> {
    const result: any = await this.db.prepare(
      'INSERT INTO email_verification_tokens (token, user_id, expires_at) VALUES (?, ?, ?)'
    ).bind(token, userId, expiresAt).run()

    if (!result.success) {
      throw new Error('Failed to create email verification token')
    }
  }

  async getEmailVerificationToken(token: string): Promise<{ user_id: number, expires_at: string } | null> {
    const result = await this.db.prepare(
      'SELECT user_id, expires_at FROM email_verification_tokens WHERE token = ?'
    ).bind(token).first<{ user_id: number, expires_at: string }>()

    return result || null
  }

  async deleteEmailVerificationToken(token: string): Promise<void> {
    await this.db.prepare(
      'DELETE FROM email_verification_tokens WHERE token = ?'
    ).bind(token).run()
  }

  async setEmailVerified(userId: number): Promise<void> {
    const result: any = await this.db.prepare(
      'UPDATE users SET email_verified = 1 WHERE id = ?'
    ).bind(userId).run()

    if (!result.success) {
      throw new Error('Failed to set email verified')
    }
  }

  // Statistics
  async getStatistics(): Promise<Statistics> {
    // Check if we have valid cache
    const now = Date.now();
    if (statisticsCache.data && statisticsCache.timestamp &&
      (now - statisticsCache.timestamp) < CACHE_DURATION) {
      console.log('Returning cached statistics');
      return statisticsCache.data;
    }

    console.log('Fetching fresh statistics from database');

    // Get total expressions count from language_stats (materialized)
    const totalExpressionsResult = await this.db.prepare(
      'SELECT SUM(expression_count) as count FROM language_stats'
    ).first<{ count: number }>();
    console.log('Total expressions result:', totalExpressionsResult);

    // Get total languages count
    const totalLanguagesResult = await this.db.prepare(
      'SELECT COUNT(*) as count FROM languages WHERE is_active = 1'
    ).first<{ count: number }>();
    console.log('Total languages result:', totalLanguagesResult);

    // Get total regions count - from languages table as suggested
    const totalRegionsResult = await this.db.prepare(
      `SELECT COUNT(DISTINCT region_name) as count 
       FROM languages 
       WHERE region_name IS NOT NULL AND region_name != ''`
    ).first<{ count: number }>();
    console.log('Total regions result:', totalRegionsResult);

    const statistics = {
      total_expressions: totalExpressionsResult?.count || 0,
      total_languages: totalLanguagesResult?.count || 0,
      total_regions: totalRegionsResult?.count || 0
    };
    console.log('Constructed statistics object:', statistics);

    // Update cache
    statisticsCache.data = statistics;
    statisticsCache.timestamp = now;

    return statistics;
  }

  // Method to clear statistics cache (to be called when data changes)
  clearStatisticsCache(): void {
    statisticsCache.data = null;
    statisticsCache.timestamp = null;
    console.log('Statistics cache cleared');
  }

  // Heatmap
  async getHeatmapData(): Promise<HeatmapData[]> {
    // Check if we have valid cache
    const now = Date.now();
    if (heatmapCache.data && heatmapCache.timestamp &&
      (now - heatmapCache.timestamp) < HEATMAP_CACHE_DURATION) {
      console.log('Returning cached heatmap data');
      return heatmapCache.data;
    }

    console.log('Fetching fresh heatmap data from database');

    const query = `
      SELECT 
        l.code as language_code,
        l.name as language_name,
        l.region_name,
        l.region_code,
        COALESCE(ls.expression_count, 0) as count,
        l.region_latitude as latitude,
        l.region_longitude as longitude
      FROM languages l
      LEFT JOIN language_stats ls ON l.code = ls.language_code
      WHERE l.is_active = 1 
        AND l.region_name IS NOT NULL 
        AND l.region_latitude IS NOT NULL 
        AND l.region_longitude IS NOT NULL
      ORDER BY count DESC
      LIMIT 1000
    `;

    const result = await this.db.prepare(query).all<HeatmapData>();
    const heatmapData = result.results || [];

    // Update cache
    heatmapCache.data = heatmapData;
    heatmapCache.timestamp = now;

    return heatmapData;
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
    let query = `
      SELECT c.*, c.items_count 
      FROM collections c
    `
    const params: any[] = []
    const conditions: string[] = []

    if (userId !== undefined) {
      conditions.push('c.user_id = ?')
      params.push(userId)
    }

    if (isPublic !== undefined) {
      conditions.push('c.is_public = ?')
      params.push(isPublic ? 1 : 0)
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ')
    }

    query += ' ORDER BY c.created_at DESC'
    query += ' LIMIT ? OFFSET ?'
    params.push(limit, skip)

    const { results } = await this.db.prepare(query).bind(...params).all<Collection>()
    return results
  }

  async getCollectionById(id: number): Promise<Collection | null> {
    const collection = await this.db.prepare(
      'SELECT c.*, c.items_count FROM collections c WHERE c.id = ?'
    ).bind(id).first<Collection>()
    return collection || null
  }

  async createCollection(collection: Partial<Collection>): Promise<Collection> {
    const userId = collection.user_id;
    const name = collection.name;
    if (!userId || !name) {
      throw new Error('User ID and name are required');
    }
    const id = this.stableCollectionId(userId, name);

    const bindValues = [
      id,
      userId,
      name,
      collection.description || null,
      collection.is_public !== undefined ? (collection.is_public ? 1 : 0) : 0
    ];

    const result = await this.db.prepare(
      `INSERT INTO collections (
        id, user_id, name, description, is_public
      ) VALUES (?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<Collection>()

    if (!result) {
      throw new Error('Failed to create collection')
    }

    return result;
  }

  async updateCollection(id: number, collection: Partial<Collection>): Promise<Collection> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(collection).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'user_id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(value)
      }
    })

    values.push(id)

    const result = await this.db.prepare(
      `UPDATE collections SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).first<Collection>()

    if (!result) {
      throw new Error('Failed to update collection')
    }

    return result;
  }

  async deleteCollection(id: number): Promise<boolean> {
    // Delete items first (cascade simulation)
    await this.db.prepare('DELETE FROM collection_items WHERE collection_id = ?').bind(id).run();

    const result: any = await this.db.prepare(
      'DELETE FROM collections WHERE id = ?'
    ).bind(id).run()

    return result.changes > 0;
  }

  // Collection Items
  async getCollectionItems(collectionId: number, skip: number = 0, limit: number = 50): Promise<CollectionItem[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM collection_items WHERE collection_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?'
    ).bind(collectionId, limit, skip).all<CollectionItem>()
    return results
  }

  async addCollectionItem(item: Partial<CollectionItem>): Promise<CollectionItem> {
    const collectionId = item.collection_id;
    const expressionId = item.expression_id;

    if (!collectionId || !expressionId) {
      throw new Error('Collection ID and Expression ID are required');
    }

    // Check if exists
    const existing = await this.getCollectionItem(collectionId!, expressionId!);
    if (existing) {
      return existing;
    }

    // Since SQLite doesn't have a simple way to return the inserted ID with stableHash if using autoincrement,
    // but here we are not generating ID manually for items assuming it's autoincrement in D1 usually or we should.
    // However, the schema says id INTEGER PRIMARY KEY NOT NULL, which usually implies we should adding ID if strict.
    // Let's generate a stable ID.
    const id = this.stableCollectionItemId(collectionId, expressionId);

    const bindValues = [
      id,
      collectionId,
      expressionId,
      item.note || null
    ];

    const result = await this.db.prepare(
      `INSERT INTO collection_items (
        id, collection_id, expression_id, note
      ) VALUES (?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<CollectionItem>()

    if (!result) {
      throw new Error('Failed to add item to collection')
    }

    // Increment items_count in collections
    await this.db.prepare('UPDATE collections SET items_count = items_count + 1 WHERE id = ?').bind(collectionId).run()

    return result;
  }

  async removeCollectionItem(collectionId: number, expressionId: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM collection_items WHERE collection_id = ? AND expression_id = ?'
    ).bind(collectionId, expressionId).run()

    const changed = result.changes > 0;
    if (changed) {
      // Decrement items_count in collections
      await this.db.prepare('UPDATE collections SET items_count = MAX(0, items_count - 1) WHERE id = ?').bind(collectionId).run()
    }

    return changed;
  }

  async getCollectionItem(collectionId: number, expressionId: number): Promise<CollectionItem | null> {
    const item = await this.db.prepare(
      'SELECT * FROM collection_items WHERE collection_id = ? AND expression_id = ?'
    ).bind(collectionId, expressionId).first<CollectionItem>()
    return item || null
  }

  async getCollectionsContainingItem(userId: number, expressionId: number): Promise<number[]> {
    const query = `
      SELECT ci.collection_id
      FROM collection_items ci
      JOIN collections c ON ci.collection_id = c.id
      WHERE ci.expression_id = ? AND c.user_id = ?
    `
    const { results } = await this.db.prepare(query).bind(expressionId, userId).all<{ collection_id: number }>()
    return results.map(r => r.collection_id)
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
    let query = 'SELECT * FROM handbooks'
    const bindings: any[] = []
    const conditions: string[] = []

    if (isPublic !== undefined) {
      conditions.push('is_public = ?')
      bindings.push(isPublic ? 1 : 0)
    } else if (userId !== undefined) {
      conditions.push('user_id = ?')
      bindings.push(userId)
    } else {
      return []
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ')
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    bindings.push(limit, skip)

    console.log(query, bindings)

    const { results } = await this.db.prepare(query).bind(...bindings).all<Handbook>()
    return (results || []).map(h => this.formatTimestamps(h) as Handbook)
  }

  async getHandbookById(id: number): Promise<Handbook | null> {
    const handbook = await this.db.prepare(
      `SELECT h.*, u.username as created_by 
       FROM handbooks h 
       LEFT JOIN users u ON h.user_id = u.id 
       WHERE h.id = ?`
    ).bind(id).first<Handbook & { created_by?: string }>()
    if (!handbook) return null
    return this.formatTimestamps(handbook) as Handbook
  }

  async createHandbook(handbook: Partial<Handbook>): Promise<Handbook> {
    const id = this.stableHashId(`${handbook.user_id}|${handbook.title}|${Date.now()}`)
    const bindValues = [
      id,
      handbook.user_id,
      handbook.title,
      handbook.description || null,
      handbook.content || '',
      handbook.source_lang || null,
      handbook.target_lang || null,
      handbook.is_public ? 1 : 0,
      handbook.lang_colors || '{}'
    ]

    const result = await this.db.prepare(
      `INSERT INTO handbooks (id, user_id, title, description, content, source_lang, target_lang, is_public, lang_colors)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<Handbook>()

    if (!result) {
      throw new Error('Failed to create handbook')
    }

    return this.formatTimestamps(result) as Handbook
  }

  async updateHandbook(id: number, handbook: Partial<Handbook>): Promise<Handbook> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(handbook).forEach(([key, value]) => {
      // Don't update renders directly via this method unless explicitly passed
      if (key !== 'id' && key !== 'created_at' && key !== 'user_id') {
        fields.push(`${key} = ?`)
        values.push(key === 'is_public' ? (value ? 1 : 0) : value)
      }
    })

    if (fields.length === 0) {
      const current = await this.getHandbookById(id);
      if (!current) throw new Error('Handbook not found');
      return current;
    }

    // Always invalidate all renders on any handbook update
    fields.push('renders = ?')
    values.push('{}')

    fields.push('updated_at = CURRENT_TIMESTAMP')
    values.push(id)

    const result = await this.db.prepare(
      `UPDATE handbooks SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).first<Handbook>()

    if (!result) {
      throw new Error('Failed to update handbook')
    }

    return this.formatTimestamps(result) as Handbook
  }

  async deleteHandbook(id: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM handbooks WHERE id = ?'
    ).bind(id).run()
    return (result.meta?.changes ?? 0) > 0
  }

  // Handbook Renders (JSON column based)
  async getHandbookRender(id: number, targetLang: string): Promise<any | null> {
    const handbook = await this.db.prepare(
      'SELECT renders FROM handbooks WHERE id = ?'
    ).bind(id).first<Handbook>()

    if (!handbook || !handbook.renders) return null

    try {
      const renders = JSON.parse(handbook.renders)
      const render = renders[targetLang]
      if (!render) return null

      // Check TTL (24 hours)
      const renderedTime = render.at
      const now = Date.now()
      if (now - renderedTime > 24 * 3600 * 1000) {
        return null // Expired
      }

      return render
    } catch (e) {
      console.error('Error parsing handbook renders:', e)
      return null
    }
  }

  async saveHandbookRender(renderData: {
    handbook_id: number;
    target_lang: string;
    rendered_title: string;
    rendered_description?: string;
    rendered_content: string;
  }): Promise<void> {
    // 1. Get current renders
    const handbook = await this.db.prepare(
      'SELECT renders FROM handbooks WHERE id = ?'
    ).bind(renderData.handbook_id).first<Handbook>()

    if (!handbook) return

    let renders: Record<string, any> = {}
    try {
      renders = JSON.parse(handbook.renders || '{}')
    } catch (e) {
      renders = {}
    }

    // 2. Update specific language
    renders[renderData.target_lang] = {
      rendered_title: renderData.rendered_title,
      rendered_description: renderData.rendered_description,
      rendered_content: renderData.rendered_content,
      at: Date.now()
    }

    // 3. Save back
    await this.db.prepare(
      'UPDATE handbooks SET renders = ? WHERE id = ?'
    ).bind(JSON.stringify(renders), renderData.handbook_id).run()
  }

  async invalidateHandbookRenders(id: number): Promise<void> {
    await this.db.prepare(
      'UPDATE handbooks SET renders = ? WHERE id = ?'
    ).bind('{}', id).run()
  }

  // UI Locale methods (NEW - replaces UI translations)
  async getUILocale(languageCode: string): Promise<UILocale | null> {
    const result = await this.db.prepare(
      'SELECT * FROM ui_locales WHERE language_code = ?'
    ).bind(languageCode).first<UILocale>()

    return result ? this.formatTimestamps(result) : null
  }

  async saveUILocale(languageCode: string, localeJson: string, username: string): Promise<UILocale> {
    const now = new Date().toISOString()

    // Check if locale already exists
    const existing = await this.getUILocale(languageCode)

    if (existing) {
      // Update existing locale
      await this.db.prepare(
        'UPDATE ui_locales SET locale_json = ?, updated_by = ?, updated_at = ? WHERE language_code = ?'
      ).bind(localeJson, username, now, languageCode).run()

      return {
        ...existing,
        locale_json: localeJson,
        updated_by: username,
        updated_at: now
      }
    } else {
      // Create new locale
      const result = await this.db.prepare(
        'INSERT INTO ui_locales (language_code, locale_json, created_by, created_at, updated_by, updated_at) VALUES (?, ?, ?, ?, ?, ?) RETURNING *'
      ).bind(languageCode, localeJson, username, now, username, now).first<UILocale>()

      if (!result) {
        throw new Error('Failed to create UI locale')
      }

      return this.formatTimestamps(result)
    }
  }

  async deleteUILocale(languageCode: string): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM ui_locales WHERE language_code = ?'
    ).bind(languageCode).run()

    return result.meta.changes > 0
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
    const db = this.db;

    // 1. 验证词句组存在
    const sourceMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(sourceMeaningId).first();
    const targetMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(targetMeaningId).first();

    if (!sourceMeaning) {
      throw new Error('Source meaning group not found');
    }

    if (!targetMeaning) {
      throw new Error('Target meaning group not found');
    }

    // 2. 获取源词句组的所有词句
    const expressionsResult = await db.prepare(
      'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceMeaningId).all<{ expression_id: number }>();

    if (!expressionsResult.results || expressionsResult.results.length === 0) {
      return {
        success: true,
        merged_count: 0,
        target_meaning_id: targetMeaningId
      };
    }

    // 3. 批量插入新的 expression_meaning 关联
    const now = new Date().toISOString();
    const insertStatements = expressionsResult.results.map(e =>
      db.prepare(
        'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${e.expression_id}-${targetMeaningId}`, e.expression_id, targetMeaningId, now)
    );

    // 4. 批量删除源词句组的关联
    const deleteExpressionMeaningStmt = db.prepare(
      'DELETE FROM expression_meaning WHERE meaning_id = ?'
    ).bind(sourceMeaningId);

    // 5. 删除源词句组
    const deleteMeaningStmt = db.prepare(
      'DELETE FROM meanings WHERE id = ?'
    ).bind(sourceMeaningId);

    // 6. 使用 batch 执行所有操作
    try {
      await db.batch([...insertStatements, deleteExpressionMeaningStmt, deleteMeaningStmt]);

      return {
        success: true,
        merged_count: expressionsResult.results.length,
        target_meaning_id: targetMeaningId
      };
    } catch (error) {
      console.error('Failed to merge meaning groups:', error);
      throw new Error('Failed to merge meaning groups');
    }
  }
}
