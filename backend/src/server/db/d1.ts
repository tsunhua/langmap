// D1 Database Service Implementation
import { D1Database } from '@cloudflare/workers-types'
import { AbstractDatabaseService, Language, Expression, ExpressionVersion, User, Statistics, HeatmapData, Collection, CollectionItem, Handbook } from './protocol'

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
      const response = await this.db.prepare('SELECT * FROM languages ORDER BY name').all<Language>();

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
      language.created_by || null,
      language.updated_by || null
    ];

    const result = await this.db.prepare(
      `INSERT INTO languages (
        id, code, name, direction, is_active, region_code, region_name, 
        region_latitude, region_longitude, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
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
      if (Array.isArray(meaningId)) {
        // Handle array of meaning IDs
        if (meaningId.length > 0) {
          const placeholders = meaningId.map(() => '?').join(',');
          whereConditions.push(`meaning_id IN (${placeholders})`);
          bindings.push(...meaningId);
        } else {
          // Empty array means no results should be returned
          whereConditions.push('1 = 0'); // Always false condition
        }
      } else {
        // Handle single meaning ID (backward compatibility)
        if (meaningId === -1) {
          // Special case: get expressions with any meaning_id (not null)
          whereConditions.push('meaning_id IS NOT NULL');
        } else {
          whereConditions.push('meaning_id = ?');
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

    // Process in chunks to avoid D1 parameter limits
    const chunkSize = 100;
    const allResults: Expression[] = [];

    for (let i = 0; i < ids.length; i += chunkSize) {
      const chunk = ids.slice(i, i + chunkSize);
      const placeholders = chunk.map(() => '?').join(',');
      const { results } = await this.db.prepare(
        `SELECT * FROM expressions WHERE id IN (${placeholders})`
      ).bind(...chunk).all<Expression>();
      allResults.push(...results);
    }

    return allResults;
  }

  async upsertExpressions(expressions: Partial<Expression>[]): Promise<Array<{ id: number, expression?: Expression, error?: string }>> {
    console.log('[upsertExpressions] Starting batch upsert with', expressions.length, 'expressions')

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
      const existing = existingMap.get(expr.id)
      if (existing && existing.meaning_id) {
        meaningIds.push(existing.meaning_id)
      }
    }

    if (meaningIds.length === 0) {
      if (sortedExprs.length > 0 && sortedExprs[0].text && sortedExprs[0].language_code) {
        const firstExpr = sortedExprs[0]
        const firstId = this.stableExpressionId(firstExpr.text!, firstExpr.language_code!)
        finalMeaningId = firstId
        console.log('[upsertExpressions] No meaning_ids found, using first expression ID as meaning_id:', finalMeaningId)
      }
    } else {
      const uniqueMeaningIds = [...new Set(meaningIds)]
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

    console.log('[upsertExpressions] Final meaning_id:', finalMeaningId)

    const statements = expressions.map(expr => {
      if (!expr.text || !expr.language_code) {
        throw new Error('Text and language_code are required for all expressions');
      }

      const id = this.stableExpressionId(expr.text, expr.language_code)
      const meaningId = finalMeaningId !== undefined ? finalMeaningId : (expr.meaning_id !== undefined ? expr.meaning_id : null)

      const bindValues = [
        id,
        expr.text,
        meaningId,
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
          id, text, meaning_id, audio_url, language_code, region_code, region_name, region_latitude,
          region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          meaning_id = CASE WHEN excluded.meaning_id IS NOT NULL THEN excluded.meaning_id ELSE meaning_id END,
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
      const meaningExists = existingExprs.some(e => e.meaning_id === finalMeaningId)
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
        const meaningExistsForExpr = existingMap.get(exprId)?.meaning_id === finalMeaningId

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
        expression.meaning_id !== undefined ? expression.meaning_id : null,
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
        `INSERT INTO expressions (
          id, text, meaning_id, audio_url, language_code, region_code, region_name, region_latitude,
          region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
      ).bind(...bindValues).first<Expression>()

      if (!result) {
        console.error('Failed to create expression in database:', result);
        throw new Error('Failed to create expression')
      }

      // Update language_stats
      await this.db.prepare(`
        INSERT OR REPLACE INTO language_stats (language_code, expression_count)
        VALUES (?, COALESCE((SELECT expression_count FROM language_stats WHERE language_code = ?), 0) + 1)
      `).bind(languageCode, languageCode).run();

      // Clear statistics and heatmap caches as we've added a new expression
      this.clearStatisticsCache();
      this.clearHeatmapCache();

      return result;
    } catch (error) {
      console.error('Error creating expression:', error);
      throw error;
    }
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

    const { success } = await this.db.prepare(
      'DELETE FROM expressions WHERE id = ?'
    ).bind(id).run()

    if (success) {
      // Update language_stats
      await this.db.prepare(`
        UPDATE language_stats
        SET expression_count = MAX(0, expression_count - 1)
        WHERE language_code = ?
      `).bind(expression.language_code).run();

      // Delete from FTS index to keep in sync
      await this.db.prepare('DELETE FROM expressions_fts WHERE rowid = ?').bind(id).run();

      // Clear statistics and heatmap caches as we've deleted an expression
      this.clearStatisticsCache();
      this.clearHeatmapCache();
    }

    return success
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
      // If the target ID already exists, we effectively delete the old one 
      // and redirect all its references to the existing one.

      const statements: any[] = [];

      // - Update meaning_id references
      statements.push(db.prepare(`UPDATE expressions SET meaning_id = ? WHERE meaning_id = ?`).bind(newId, oldId));

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

    // - Create version snapshot of OLD record
    statements.push(db.prepare(
      `INSERT INTO expression_versions (expression_id, text, meaning_id, audio_url, region_name, region_latitude, region_longitude, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      oldId, current.text, current.meaning_id || null, current.audio_url || null,
      current.region_name || null, current.region_latitude || null, current.region_longitude || null,
      newExpression.updated_by || current.created_by || 'system'
    ));

    // - Update all expressions that point to oldId as meaning_id to point to newId
    statements.push(db.prepare(
      `UPDATE expressions SET meaning_id = ? WHERE meaning_id = ?`
    ).bind(newId, oldId));

    // - Update collection items
    statements.push(db.prepare(
      `UPDATE collection_items SET expression_id = ? WHERE expression_id = ?`
    ).bind(newId, oldId));

    // - Insert the NEW expression
    const bindValues = [
      newId,
      merged.text,
      merged.meaning_id !== undefined ? merged.meaning_id : null,
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

      // 按语言优先级排序
      const sortedExprs = [...expressions].sort((a, b) => {
        const indexA = LANGUAGE_PRIORITY.indexOf(a.language_code);
        const indexB = LANGUAGE_PRIORITY.indexOf(b.language_code);

        const priorityA = indexA === -1 ? 999 : indexA;
        const priorityB = indexB === -1 ? 999 : indexB;

        return priorityA - priorityB;
      });

      // 遍历排序后的表达式，找到第一个有 meaning_id 的
      for (const expr of sortedExprs) {
        if (expr.meaning_id) {
          return expr.meaning_id;
        }
      }

      // 如果都没有 meaning_id，返回排序后第一个表达式的 ID
      if (sortedExprs.length > 0) {
        return sortedExprs[0].id;
      }

      return null;
    } catch (error) {
      console.error('Error selecting semantic anchor:', error);
      return null;
    }
  }

  async searchExpressions(query: string, fromLang?: string, region?: string, skip: number = 0, limit: number = 20): Promise<Expression[]> {
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
    return results
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

    const result: any = await this.db.prepare(
      'INSERT INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${expressionId}-${meaningId}`, expressionId, meaningId, now).run()

    if (!result.success) {
      throw new Error('Failed to add expression-meaning relationship')
    }
  }

  async removeExpressionMeaning(expressionId: number, meaningId: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM expression_meaning WHERE expression_id = ? AND meaning_id = ?'
    ).bind(expressionId, meaningId).run()

    return result.changes > 0
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
      if (result[field] && typeof result[field] === 'string') {
        const timestamp = result[field] as string
        if (timestamp.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/)) {
          result[field] = timestamp + 'Z'
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

  // UI translations
  async getUITranslations(language: string, skip: number = 0, limit: number = 200): Promise<any[]> {
    const { results } = await this.db.prepare(
      `SELECT e.id, e.text, e.tags, e.language_code as language_code, COALESCE(e.meaning_id, e.id) as meaning_id
       FROM expressions e 
       JOIN collection_items ci ON e.id = ci.expression_id
       JOIN collections c ON ci.collection_id = c.id
       WHERE c.name = 'langmap' AND e.language_code = ?
       LIMIT ? OFFSET ?`
    ).bind(language, limit, skip).all<{ id: number, text: string, language_code: string, meaning_id: number | null }>()
    return results
  }

  async saveUITranslation(language: string, key: string, text: string, username: string, meaningId?: number): Promise<any> {
    if (!meaningId) {
      throw new Error(`meaning_id is required for saving UI translations`);
    }

    // 1. Try to find existing translation by meaning_id within the collection
    const existingInCollection = await this.db.prepare(
      `SELECT e.* FROM expressions e
       JOIN collection_items ci ON e.id = ci.expression_id
       JOIN collections c ON ci.collection_id = c.id
       WHERE c.name = 'langmap' AND e.language_code = ? AND e.meaning_id = ?`
    ).bind(language, meaningId).first<Expression>();

    if (existingInCollection) {
      console.log('Updating existing expression in collection:', existingInCollection.id);
      // Update existing record in collection
      return await this.updateExpression(existingInCollection.id, {
        text,
        updated_by: username,
        updated_at: new Date().toISOString()
      });
    }

    // 2. Not in collection. Check if an expression with the same text/lang ID already exists globally
    const id = this.stableExpressionId(text, language);
    const globalExisting = await this.getExpressionById(id);

    let expr: Expression;
    if (globalExisting) {
      console.log('Re-using existing expression:', globalExisting.id);
      // Re-use existing expression: update its meaning_id and tags
      // Merge the new key with existing tags
      let mergedTags = [key];
      if (globalExisting.tags) {
        try {
          const existingTags = JSON.parse(globalExisting.tags);
          if (Array.isArray(existingTags)) {
            // Add new key if it's not already in the array
            if (!existingTags.includes(key)) {
              mergedTags = [...existingTags, key];
            } else {
              mergedTags = existingTags;
            }
          }
        } catch (e) {
          // If parsing fails, start fresh with just the new key
          console.warn('Failed to parse existing tags, starting fresh:', globalExisting.tags);
        }
      }

      expr = await this.updateExpression(id, {
        meaning_id: meaningId,
        tags: JSON.stringify(mergedTags),
        updated_by: username,
        updated_at: new Date().toISOString()
      });
    } else {
      console.log('Creating new expression:', text);
      // Create truly new expression
      expr = await this.createExpression({
        text,
        language_code: language,
        tags: JSON.stringify([key]),
        meaning_id: meaningId,
        source_type: 'user',
        created_by: username,
        updated_by: username
      });
    }

    // 3. Ensure it is linked to 'langmap' collection
    const langmapCol = await this.db.prepare("SELECT id FROM collections WHERE name = 'langmap'").first<{ id: number }>();
    if (langmapCol) {
      console.log('Adding expression to langmap collection:', expr.id);
      await this.addCollectionItem({
        collection_id: langmapCol.id,
        expression_id: expr.id,
        note: 'UI Translation'
      });
    }

    return expr;
  }

  async saveUITranslations(language: string, translations: Array<{ key: string, text: string, meaning_id?: number }>, username: string): Promise<Array<{ key: string, error?: string }>> {
    const results: Array<{ key: string, error?: string }> = [];

    // Process translations in batches to avoid hitting database limits
    const batchSize = 100;
    for (let i = 0; i < translations.length; i += batchSize) {
      const batch = translations.slice(i, i + batchSize);
      const batchResults = await Promise.all(
        batch.map(async (item) => {
          if (!item.key || !item.text) {
            return { key: item.key, error: 'Missing key or text' };
          }

          try {
            const result = await this.saveUITranslation(language, item.key, item.text, username, item.meaning_id);
            return { key: item.key };
          } catch (err: any) {
            console.error(`Failed to save translation for key ${item.key}:`, err);
            return { key: item.key, error: err.message };
          }
        })
      );

      results.push(...batchResults);
    }

    // After saving all translations, check if we should activate the language
    try {
      await this.checkAndActivateLanguage(language);
    } catch (err) {
      console.error(`Failed to check/activate language ${language} after saving translations:`, err);
    }

    return results;
  }

  // Sync locales from local JSON to database
  async syncLocalesToDatabase(localeData: Record<string, any>, username: string): Promise<Record<string, { added: number, updated: number, errors: string[] }>> {
    const results: Record<string, { added: number, updated: number, errors: string[] }> = {}

    // Get langmap collection ID
    const langmapCol = await this.db.prepare(
      "SELECT id FROM collections WHERE name = 'langmap'"
    ).first<{ id: number }>()

    if (!langmapCol) {
      throw new Error('langmap collection not found')
    }

    const timestamp = new Date().toISOString()

    // Flatten en-US messages to map keys to English text for meaning resolution
    const enUSData = localeData['en-US'] || {}
    const flattenedEnUS = this.flattenObject(enUSData)

    // Process each language
    for (const [langCode, messages] of Object.entries(localeData)) {
      try {
        const result = { added: 0, updated: 0, errors: [] }
        const flattened = this.flattenObject(messages)

        // Prepare batch operations
        const insertExpressions: any[] = []
        const updateExpressions: any[] = []
        const insertCollectionItems: any[] = []

        // For each key in this language, calculate id and meaning_id directly
        for (const [key, text] of Object.entries(flattened)) {
          const expressionId = this.stableExpressionId(text, langCode)
          const tags = JSON.stringify([`langmap.${key}`])

          // Calculate meaning_id: for en-US it's self, for others use en-US text
          let meaningId: number
          if (langCode === 'en-US') {
            meaningId = expressionId
          } else {
            let enText: string | undefined = flattenedEnUS[key]

            // If no en-US in uploaded data, query from database
            if (!enText) {
              const enUsExpr = await this.db.prepare(`
                 SELECT e.text
                 FROM expressions e
                 JOIN collection_items ci ON e.id = ci.expression_id
                 WHERE ci.collection_id = ? AND e.language_code = 'en-US' AND e.tags LIKE ?
               `).bind(langmapCol.id, `%"langmap.${key}"%`).first<{ text: string }>()
              enText = enUsExpr?.text
            }

            if (enText) {
              meaningId = this.stableExpressionId(enText, 'en-US')
            } else {
              meaningId = expressionId // fallback: self
            }
          }

          insertExpressions.push({ expressionId, text, meaningId, langCode, tags, username, timestamp })
        }

        // Batch check existing IDs (chunk to avoid "too many SQL variables")
        const idsToCheck = insertExpressions.map(e => e.expressionId)
        let existingIdSet: Set<number> = new Set()

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

          console.log(`[Sync] ${langCode}: Total IDs to check: ${idsToCheck.length}, Found existing: ${existingIdSet.size}`)
        }

        const BATCH_SIZE = 50

        // Separate new and existing expressions
        const newExpressions = insertExpressions.filter(e => !existingIdSet.has(e.expressionId))
        const existingExpressions = insertExpressions.filter(e => existingIdSet.has(e.expressionId))

        // Insert new expressions
        for (let i = 0; i < newExpressions.length; i += BATCH_SIZE) {
          const chunk = newExpressions.slice(i, i + BATCH_SIZE)
          const statements = chunk.map(expr =>
            this.db.prepare(`
              INSERT INTO expressions
              (id, text, meaning_id, language_code, tags, source_type, review_status, created_by, created_at, updated_at)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).bind(
              expr.expressionId, expr.text, expr.meaningId, expr.langCode,
              expr.tags, 'system', 'approved',
              expr.username, expr.timestamp, expr.timestamp
            )
          )
          await this.db.batch(statements)
        }

        // Update existing expressions (only update text, tags, updated_by, and updated_at)
        for (let i = 0; i < existingExpressions.length; i += BATCH_SIZE) {
          const chunk = existingExpressions.slice(i, i + BATCH_SIZE)
          const statements = chunk.map(expr =>
            this.db.prepare(`
              UPDATE expressions
              SET text = ?, tags = ?, updated_by = ?, updated_at = ?
              WHERE id = ?
            `).bind(
              expr.text, expr.tags, expr.username, expr.timestamp,
              expr.expressionId
            )
          )
          await this.db.batch(statements)
        }

        // Batch insert collection_items (use INSERT OR IGNORE to handle conflicts)
        for (let i = 0; i < insertExpressions.length; i += BATCH_SIZE) {
          const chunk = insertExpressions.slice(i, i + BATCH_SIZE)
          const statements = chunk.map(expr =>
            this.db.prepare(`
              INSERT OR IGNORE INTO collection_items (collection_id, expression_id, created_at)
              VALUES (?, ?, ?)
            `).bind(langmapCol.id, expr.expressionId, timestamp)
          )
          await this.db.batch(statements)
        }

        result.added = newExpressions.length
        result.updated = existingExpressions.length

        results[langCode] = result

        // After syncing this language, check if we should activate it
        try {
          await this.checkAndActivateLanguage(langCode);
        } catch (err) {
          console.error(`Failed to check/activate language ${langCode} after sync:`, err);
        }
      } catch (error: any) {
        results[langCode] = { added: 0, updated: 0, errors: [error.message] }
      }
    }

    return results
  }

  async calculateUITranslationCompletion(languageCode: string): Promise<number> {
    if (languageCode === 'en-US') return 100;

    // Get total items in langmap collection (using en-US as baseline)
    const totalQuery = `
      SELECT COUNT(DISTINCT COALESCE(e.meaning_id, e.id)) as count
      FROM expressions e
      JOIN collection_items ci ON e.id = ci.expression_id
      JOIN collections c ON ci.collection_id = c.id
      WHERE c.name = 'langmap' AND e.language_code = 'en-US'
    `;
    const totalResult = await this.db.prepare(totalQuery).first<{ count: number }>();
    const totalCount = totalResult?.count || 0;

    if (totalCount === 0) return 0;

    // Get translated items for target language
    const translatedQuery = `
      SELECT COUNT(DISTINCT e.meaning_id) as count
      FROM expressions e
      JOIN collection_items ci ON e.id = ci.expression_id
      JOIN collections c ON ci.collection_id = c.id
      WHERE c.name = 'langmap' AND e.language_code = ? AND e.meaning_id IS NOT NULL
    `;
    const translatedResult = await this.db.prepare(translatedQuery).bind(languageCode).first<{ count: number }>();
    const translatedCount = translatedResult?.count || 0;

    return Math.round((translatedCount / totalCount) * 100);
  }

  private async checkAndActivateLanguage(languageCode: string): Promise<void> {
    if (languageCode === 'en-US') return;

    const completion = await this.calculateUITranslationCompletion(languageCode);
    if (completion >= 60) {
      const lang = await this.getLanguageByCode(languageCode);
      // is_active might be returned as 1/0 or true/false depending on D1 driver version and schema
      if (lang && !lang.is_active) {
        await this.updateLanguage(lang.id, { is_active: true });
        console.log(`[Activation] Language ${languageCode} activated (completion: ${completion}%)`);
      }
    }
  }

  // Helper function to flatten nested objects
  private flattenObject(obj: any, prefix = ''): Record<string, string> {
    const flattened: Record<string, string> = {}
    for (const key in obj) {
      const newKey = prefix ? `${prefix}.${key}` : key
      if (typeof obj[key] === 'object' && obj[key] !== null) {
        Object.assign(flattened, this.flattenObject(obj[key], newKey))
      } else {
        flattened[newKey] = obj[key]
      }
    }
    return flattened
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

    if (userId !== undefined) {
      conditions.push('user_id = ?')
      bindings.push(userId)
    }

    if (isPublic !== undefined) {
      conditions.push('is_public = ?')
      bindings.push(isPublic ? 1 : 0)
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ')
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    bindings.push(limit, skip)

    const { results } = await this.db.prepare(query).bind(...bindings).all<Handbook>()
    return (results || []).map(h => this.formatTimestamps(h) as Handbook)
  }

  async getHandbookById(id: number): Promise<Handbook | null> {
    const handbook = await this.db.prepare(
      'SELECT * FROM handbooks WHERE id = ?'
    ).bind(id).first<Handbook>()
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
      handbook.is_public ? 1 : 0
    ]

    const result = await this.db.prepare(
      `INSERT INTO handbooks (id, user_id, title, description, content, source_lang, target_lang, is_public)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
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
   * Generate a stable ID based on the content using FNV-1a 32-bit hash.
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
}