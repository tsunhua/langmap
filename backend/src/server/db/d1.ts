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

    const result: any = await this.db.prepare(
      `INSERT INTO languages (
        id, code, name, direction, is_active, region_code, region_name, 
        region_latitude, region_longitude, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).run()

    if (!result.success) {
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

    const result: any = await this.db.prepare(
      `UPDATE languages SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).run()

    if (!result.success) {
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
      // Generate stable ID based on text, language_code and region_code
      const text = expression.text;
      const languageCode = expression.language_code;
      const regionCode = expression.region_code || '';
      const idContent = `${text}|${languageCode}|${regionCode}`;
      const id = this.stableHashId(idContent);

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

      const result: any = await this.db.prepare(
        `INSERT INTO expressions (
          id, text, meaning_id, audio_url, language_code, region_code, region_name, region_latitude,
          region_longitude, tags, source_type, source_ref, review_status, created_by, updated_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
      ).bind(...bindValues).run()

      if (!result.success) {
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

    const result: any = await this.db.prepare(
      `UPDATE expressions SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).run()

    if (!result.success) {
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
    const expressionId = version.expression_id || 0;
    const text = version.text || '';
    const idContent = `${expressionId}|${text}`;
    const id = this.stableHashId(idContent);

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

    const result: any = await this.db.prepare(
      `INSERT INTO expression_versions (
        id, expression_id, text, meaning_id, audio_url, region_name, region_latitude, 
        region_longitude, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).run()

    if (!result.success) {
      throw new Error('Failed to create expression version')
    }

    return result.results[0] as ExpressionVersion
  }

  // UI translations
  async getUITranslations(language: string, skip: number = 0, limit: number = 200): Promise<any[]> {
    const { results } = await this.db.prepare(
      `SELECT e.id, e.text, e.tags, e.language_code as language_code
       FROM expressions e 
       WHERE e.language_code = ? AND e.created_by = 'langmap'
       LIMIT ? OFFSET ?`
    ).bind(language, limit, skip).all<{ id: number, text: string, language_code: string }>()
    return results
  }

  async saveUITranslation(language: string, key: string, text: string, username: string): Promise<any> {
    // 1. Check if an expression with this language and tag (key) exists
    // Note: tags is stored as a JSON string or simple string, we search using LIKE
    // Ideally tags should be normalized. Here we assume tags contains the key.

    // First, try to find existing expression
    // Since tags might be stored as '["key"]' or just "key", we need to be careful.
    // However, getUITranslations returns tags directly. 
    // Let's assume tags is stored as a simple string containing the key for UI translations,
    // or we construct a query to find it.

    const existing = await this.db.prepare(
      `SELECT * FROM expressions 
       WHERE language_code = ? 
       AND (tags = ? OR tags LIKE ?)`
    ).bind(language, `["${key}"]`, `%"${key}"%`).first<Expression>();

    if (existing) {
      // Update existing
      return await this.updateExpression(existing.id, {
        text,
        updated_by: username,
        updated_at: new Date().toISOString() // Although DB has default, we update explicitly to track
      });
    } else {
      // Create new
      // We need to find the meaning_id from the reference language (en-US)
      // This is best effort.
      const reference = await this.db.prepare(
        `SELECT * FROM expressions 
         WHERE language_code = 'en-US' 
         AND (tags = ? OR tags LIKE ?)`
      ).bind(`["${key}"]`, `%"${key}"%`).first<Expression>();

      const meaningId = reference ? (reference.meaning_id || reference.id) : null;

      return await this.createExpression({
        text,
        language_code: language,
        tags: `["${key}"]`,
        meaning_id: meaningId || undefined,
        source_type: 'user',
        created_by: username,
        updated_by: username
      });
    }
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
  async getCollections(userId?: number, isPublic?: boolean): Promise<Collection[]> {
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
    const name = collection.name || 'Untitled Collection';
    const idContent = `${userId}|${name}|${Date.now()}`;
    const id = this.stableHashId(idContent);

    const bindValues = [
      id,
      userId,
      name,
      collection.description || null,
      collection.is_public !== undefined ? (collection.is_public ? 1 : 0) : 0
    ];

    const result: any = await this.db.prepare(
      `INSERT INTO collections (
        id, user_id, name, description, is_public
      ) VALUES (?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).run()

    if (!result.success) {
      throw new Error('Failed to create collection')
    }

    return result.results[0] as Collection
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

    const result: any = await this.db.prepare(
      `UPDATE collections SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).run()

    if (!result.success) {
      throw new Error('Failed to update collection')
    }

    return result.results[0] as Collection
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

    // Check if exists
    const existing = await this.getCollectionItem(collectionId!, expressionId!);
    if (existing) {
      return existing;
    }

    // Since SQLite doesn't have a simple way to return the inserted ID with stableHash if using autoincrement,
    // but here we are not generating ID manually for items assuming it's autoincrement in D1 usually or we should.
    // However, the schema says id INTEGER PRIMARY KEY NOT NULL, which usually implies we should adding ID if strict.
    // Let's generate a stable ID.
    const idContent = `${collectionId}|${expressionId}`;
    const id = this.stableHashId(idContent);

    const bindValues = [
      id,
      collectionId,
      expressionId,
      item.note || null
    ];

    const result: any = await this.db.prepare(
      `INSERT INTO collection_items (
        id, collection_id, expression_id, note
      ) VALUES (?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).run()

    if (!result.success) {
      throw new Error('Failed to add item to collection')
    }

    return result.results[0] as CollectionItem
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