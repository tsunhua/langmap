// D1 Database Service Implementation
import { D1Database } from '@cloudflare/workers-types'
import { AbstractDatabaseService, Language, Expression, ExpressionVersion, User, Statistics, HeatmapData, Collection, CollectionItem } from './protocol'

// Cache for statistics
let statisticsCache: {
  data: Statistics | null;
  timestamp: number | null;
} = {
  data: null,
  timestamp: null
};
const CACHE_DURATION = 10 * 60 * 1000; // 10 minutes in milliseconds

// Cache for heatmap data
let heatmapCache: {
  data: HeatmapData[] | null;
  timestamp: number | null;
} = {
  data: null,
  timestamp: null
};
const HEATMAP_CACHE_DURATION = 10 * 60 * 1000; // 10 minutes in milliseconds

export class D1DatabaseService extends AbstractDatabaseService {

  private db: D1Database

  constructor(db: D1Database) {
    super()
    this.db = db
  }

  // Language operations
  async getLanguages(isActive?: number): Promise<Language[]> {
    let query = 'SELECT * FROM languages'
    const params: any[] = []

    if (isActive !== undefined) {
      query += ' WHERE is_active = ?'
      params.push(isActive)
    }

    query += ' ORDER BY name'

    const { results } = await this.db.prepare(query).bind(...params).all<Language>()
    return results
  }

  async getLanguageByCode(code: string): Promise<Language | null> {
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

    // Clear statistics and heatmap caches as we've added a new language
    this.clearStatisticsCache();
    this.clearHeatmapCache();

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

    // Clear statistics and heatmap caches as we've updated a language
    this.clearStatisticsCache();
    this.clearHeatmapCache();

    return result;
  }

  async deleteLanguage(id: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM languages WHERE id = ?'
    ).bind(id).run()

    if (result.changes > 0) {
      // Clear statistics and heatmap caches as we've deleted a language
      this.clearStatisticsCache();
      this.clearHeatmapCache();
      return true;
    }

    return false;
  }

  // Expression operations
  async getExpressions(skip: number = 0, limit: number = 50, language?: string, meaningId?: number | number[]): Promise<Expression[]> {
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

    if (whereConditions.length > 0) {
      query += ' WHERE ' + whereConditions.join(' AND ');
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    bindings.push(limit, skip)

    const { results } = await this.db.prepare(query).bind(...bindings).all<Expression>()
    return results
  }

  async getExpressionById(id: number): Promise<Expression | null> {
    const expression = await this.db.prepare(
      'SELECT * FROM expressions WHERE id = ?'
    ).bind(id).first<Expression>()
    return expression || null
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

    return result;
  }

  async deleteExpression(id: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM expressions WHERE id = ?'
    ).bind(id).run()

    if (result.changes > 0) {
      // Clear statistics and heatmap caches as we've deleted an expression
      this.clearStatisticsCache();
      this.clearHeatmapCache();
      return true;
    }

    return false;
  }

  async searchExpressions(query: string, fromLang?: string, region?: string, skip: number = 0, limit: number = 20): Promise<Expression[]> {
    let sqlQuery = 'SELECT * FROM expressions WHERE text LIKE ?'
    const bindings: any[] = [`%${query}%`]

    if (fromLang) {
      sqlQuery += ' AND language_code = ?'
      bindings.push(fromLang)
    }

    if (region) {
      sqlQuery += ' AND region_name LIKE ?'
      bindings.push(`%${region}%`)
    }

    // 使用字符串匹配函数优化排序
    sqlQuery += ' ORDER BY CASE WHEN text = ? THEN 0 WHEN text LIKE ? THEN 1 WHEN text LIKE ? THEN 2 ELSE 3 END, LENGTH(text), created_at DESC LIMIT ? OFFSET ?'
    bindings.push(query, `${query}%`, `%${query}`, limit, skip);

    const { results } = await this.db.prepare(sqlQuery).bind(...bindings).all<Expression>()
    return results
  }


  // Expression version operations
  async getExpressionVersions(expressionId: number): Promise<ExpressionVersion[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM expression_versions WHERE expression_id = ? ORDER BY created_at DESC'
    ).bind(expressionId).all<ExpressionVersion>()
    return results
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
        tags: `["${key}"]`,
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

  async saveUITranslations(language: string, translations: Array<{key: string, text: string, meaning_id?: number}>, username: string): Promise<Array<{key: string, error?: string}>> {
    const results: Array<{key: string, error?: string}> = [];
    
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
    
    return results;
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

    // Get total expressions count
    const totalExpressionsResult = await this.db.prepare(
      'SELECT COUNT(*) as count FROM expressions'
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
        COALESCE(e.expression_count, 0) as count,
        l.region_latitude as latitude,
        l.region_longitude as longitude
      FROM languages l
      LEFT JOIN (
        SELECT 
          language_code, 
          COUNT(*) as expression_count
        FROM expressions 
        GROUP BY language_code
      ) e ON l.code = e.language_code
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

  // Collections
  async getCollections(userId?: number, isPublic?: boolean, skip: number = 0, limit: number = 20): Promise<Collection[]> {
    let query = `
      SELECT c.*, (SELECT COUNT(*) FROM collection_items WHERE collection_id = c.id) as items_count 
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
      'SELECT c.*, (SELECT COUNT(*) FROM collection_items WHERE collection_id = c.id) as items_count FROM collections c WHERE c.id = ?'
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

    return result;
  }

  async removeCollectionItem(collectionId: number, expressionId: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM collection_items WHERE collection_id = ? AND expression_id = ?'
    ).bind(collectionId, expressionId).run()

    return result.changes > 0;
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
  private stableExpressionId(text: string, languageCode: string): number {
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
  private stableExpressionVersionId(expressionId: number, createdAt: string|number): number {
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