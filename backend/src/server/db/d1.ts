// D1 Database Service Implementation
import { D1Database } from '@cloudflare/workers-types'
import { AbstractDatabaseService, Language, Expression, ExpressionVersion, User } from './protocol'

export class D1DatabaseService extends AbstractDatabaseService {

  private db: D1Database

  constructor(db: D1Database) {
    super()
    this.db = db
  }

  // Language operations
  async getLanguages(): Promise<Language[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM languages WHERE is_active = 1 ORDER BY name'
    ).all<Language>()
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

    return result.results[0] as Language
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

    return result.results[0] as Language
  }

  async deleteLanguage(id: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM languages WHERE id = ?'
    ).bind(id).run()

    return result.success
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

      return result.results[0] as Expression
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

    return result.results[0] as Expression
  }

  async deleteExpression(id: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM expressions WHERE id = ?'
    ).bind(id).run()

    return result.success
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
  async getUITranslations(language: string, skip: number = 0, limit: number = 100): Promise<any[]> {
    const { results } = await this.db.prepare(
      `SELECT e.id, e.text, e.language_code as language_code
       FROM expressions e 
       WHERE e.language_code = ? AND e.text LIKE 'langmap.%' 
       LIMIT ? OFFSET ?`
    ).bind(language, limit, skip).all<{ id: number, text: string, language_code: string }>()
    return results
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

    // Filter out undefined values and replace them with null
    const bindValues = [
      id,
      user.username || null,
      user.email || null,
      user.password_hash || null,
      user.role || 'user'
    ];

    const result: any = await this.db.prepare(
      `INSERT INTO users (
        id, username, email, password_hash, role
      ) VALUES (?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).run()

    if (!result.success) {
      throw new Error('Failed to create user')
    }

    return result.results[0] as User
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