// D1 Database Service Implementation
import { D1Database } from '@cloudflare/workers-types'
import { AbstractDatabaseService, Language, Expression, ExpressionVersion, Meaning, ExpressionMeaning, User } from './abstract-db'

export class D1DatabaseService extends AbstractDatabaseService {
  private db: D1Database

  constructor(db: D1Database) {
    super()
    this.db = db
  }

  // Language operations
  async getLanguages(): Promise<Language[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM languages ORDER BY name'
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
    const now = new Date().toISOString()
    const result: any = await this.db.prepare(
      `INSERT INTO languages (
        code, name, native_name, direction, is_active, region_name, 
        native_region_name, latitude, longitude, created_by, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(
      language.code,
      language.name,
      language.native_name,
      language.direction || 'ltr',
      language.is_active !== undefined ? language.is_active : true,
      language.region_name,
      language.native_region_name,
      language.latitude,
      language.longitude,
      language.created_by,
      now,
      now
    ).run()
    
    if (!result.success) {
      throw new Error('Failed to create language')
    }
    
    return result.results[0] as Language
  }

  async updateLanguage(id: number, language: Partial<Language>): Promise<Language> {
    const now = new Date().toISOString()
    const fields: string[] = []
    const values: any[] = []
    
    Object.entries(language).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(value)
      }
    })
    
    values.push(now, id)
    
    const result: any = await this.db.prepare(
      `UPDATE languages SET ${fields.join(', ')}, updated_at = ? WHERE id = ? RETURNING *`
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
  async getExpressions(skip: number = 0, limit: number = 50, language?: string): Promise<Expression[]> {
    let query = 'SELECT * FROM expressions'
    const bindings: any[] = []
    
    if (language) {
      query += ' WHERE language = ?'
      bindings.push(language)
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
    const now = new Date().toISOString()
    const result: any = await this.db.prepare(
      `INSERT INTO expressions (
        language, region_name, region_latitude, region_longitude, country_code,
        country_name, text, source_type, source_ref, audio_url, created_by,
        created_at, review_status, auto_approved, tags
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(
      expression.language,
      expression.region_name,
      expression.region_latitude,
      expression.region_longitude,
      expression.country_code,
      expression.country_name,
      expression.text,
      expression.source_type || 'user',
      expression.source_ref,
      expression.audio_url,
      expression.created_by,
      now,
      expression.review_status || 'pending',
      expression.auto_approved !== undefined ? expression.auto_approved : false,
      expression.tags
    ).run()
    
    if (!result.success) {
      throw new Error('Failed to create expression')
    }
    
    return result.results[0] as Expression
  }

  async updateExpression(id: number, expression: Partial<Expression>): Promise<Expression> {
    const now = new Date().toISOString()
    const fields: string[] = []
    const values: any[] = []
    
    Object.entries(expression).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(value)
      }
    })
    
    values.push(now, id)
    
    const result: any = await this.db.prepare(
      `UPDATE expressions SET ${fields.join(', ')}, updated_at = ? WHERE id = ? RETURNING *`
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
      sqlQuery += ' AND language = ?'
      bindings.push(fromLang)
    }
    
    if (region) {
      sqlQuery += ' AND region_name LIKE ?'
      bindings.push(`%${region}%`)
    }
    
    sqlQuery += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    bindings.push(limit, skip)
    
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
    const now = new Date().toISOString()
    const result: any = await this.db.prepare(
      `INSERT INTO expression_versions (
        expression_id, language, region_name, region_latitude, region_longitude,
        country_code, country_name, text, source_type, created_by, created_at,
        review_status, auto_approved, parent_version_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(
      version.expression_id,
      version.language,
      version.region_name,
      version.region_latitude,
      version.region_longitude,
      version.country_code,
      version.country_name,
      version.text,
      version.source_type || 'user',
      version.created_by,
      now,
      version.review_status || 'pending',
      version.auto_approved !== undefined ? version.auto_approved : false,
      version.parent_version_id
    ).run()
    
    if (!result.success) {
      throw new Error('Failed to create expression version')
    }
    
    return result.results[0] as ExpressionVersion
  }

  // Meaning operations
  async getMeanings(skip: number = 0, limit: number = 50): Promise<Meaning[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM meanings ORDER BY created_at DESC LIMIT ? OFFSET ?'
    ).bind(limit, skip).all<Meaning>()
    return results
  }

  async getMeaningById(id: number): Promise<Meaning | null> {
    const meaning = await this.db.prepare(
      'SELECT * FROM meanings WHERE id = ?'
    ).bind(id).first<Meaning>()
    return meaning || null
  }

  async createMeaning(meaning: Partial<Meaning>): Promise<Meaning> {
    const now = new Date().toISOString()
    const result: any = await this.db.prepare(
      `INSERT INTO meanings (
        gloss, description, tags, created_by, created_at
      ) VALUES (?, ?, ?, ?, ?) RETURNING *`
    ).bind(
      meaning.gloss,
      meaning.description,
      meaning.tags,
      meaning.created_by,
      now
    ).run()
    
    if (!result.success) {
      throw new Error('Failed to create meaning')
    }
    
    return result.results[0] as Meaning
  }

  async updateMeaning(id: number, meaning: Partial<Meaning>): Promise<Meaning> {
    const now = new Date().toISOString()
    const fields: string[] = []
    const values: any[] = []
    
    Object.entries(meaning).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(value)
      }
    })
    
    values.push(now, id)
    
    const result: any = await this.db.prepare(
      `UPDATE meanings SET ${fields.join(', ')}, created_at = ? WHERE id = ? RETURNING *`
    ).bind(...values).run()
    
    if (!result.success) {
      throw new Error('Failed to update meaning')
    }
    
    return result.results[0] as Meaning
  }

  async deleteMeaning(id: number): Promise<boolean> {
    const result: any = await this.db.prepare(
      'DELETE FROM meanings WHERE id = ?'
    ).bind(id).run()
    
    return result.success
  }

  async getMeaningMembers(meaningId: number, limit: number = 100): Promise<Expression[]> {
    const { results } = await this.db.prepare(
      `SELECT e.* FROM expressions e 
       JOIN expression_meanings em ON e.id = em.expression_id 
       WHERE em.meaning_id = ? 
       LIMIT ?`
    ).bind(meaningId, limit).all<Expression>()
    return results
  }

  // Expression-Meaning operations
  async linkExpressionAndMeaning(expressionId: number, meaningId: number, note?: string): Promise<ExpressionMeaning> {
    const now = new Date().toISOString()
    const result: any = await this.db.prepare(
      `INSERT INTO expression_meanings (
        expression_id, meaning_id, note, created_by, created_at
      ) VALUES (?, ?, ?, ?, ?) RETURNING *`
    ).bind(
      expressionId,
      meaningId,
      note,
      null, // created_by
      now
    ).run()
    
    if (!result.success) {
      throw new Error('Failed to link expression and meaning')
    }
    
    return result.results[0] as ExpressionMeaning
  }

  async getExpressionMeanings(expressionId: number): Promise<Meaning[]> {
    const { results } = await this.db.prepare(
      `SELECT m.* FROM meanings m 
       JOIN expression_meanings em ON m.id = em.meaning_id 
       WHERE em.expression_id = ?`
    ).bind(expressionId).all<Meaning>()
    return results
  }
  
  // UI translations
  async getUITranslations(language: string, skip: number = 0, limit: number = 100): Promise<any[]> {
    const { results } = await this.db.prepare(
      `SELECT e.id, e.text, e.language as language_code, m.gloss 
       FROM expressions e 
       JOIN expression_meanings em ON e.id = em.expression_id 
       JOIN meanings m ON m.id = em.meaning_id 
       WHERE e.language = ? AND m.gloss LIKE 'langmap.%' 
       LIMIT ? OFFSET ?`
    ).bind(language, limit, skip).all<{id: number, text: string, language_code: string, gloss: string}>()
    return results
  }

  // Users
  async getUserByUsername(username: string): Promise<User | null> {
    const user = await this.db.prepare(
      'SELECT * FROM users WHERE username = ?'
    ).bind(username).first<User>()
    return user || null
  }
}