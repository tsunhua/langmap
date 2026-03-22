import { D1Database } from '@cloudflare/workers-types'
import { Language } from '../protocol.js'

export class LanguageQueries {
  constructor(private db: D1Database) {}

  async findAll(): Promise<Language[]> {
    const { results } = await this.db.prepare('SELECT * FROM languages ORDER BY code').all<Language>()
    return results || []
  }

  async findByCode(code: string): Promise<Language | null> {
    return await this.db.prepare(
      'SELECT * FROM languages WHERE code = ?'
    ).bind(code).first<Language>() || null
  }

  async create(id: number, language: Partial<Language>): Promise<Language> {
    const bindValues = [
      id,
      language.code || null,
      language.name || null,
      language.direction || 'ltr',
      0,
      language.region_code || null,
      language.region_name || null,
      language.region_latitude !== undefined ? language.region_latitude : null,
      language.region_longitude !== undefined ? language.region_longitude : null,
      language.group_name || null,
      language.created_by || null,
      language.updated_by || null
    ]

    const result = await this.db.prepare(
      `INSERT INTO languages (
        id, code, name, direction, is_active, region_code, region_name, 
        region_latitude, region_longitude, group_name, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<Language>()

    if (!result) {
      throw new Error('Failed to create language')
    }

    return result
  }

  async update(id: number, language: Partial<Language>): Promise<Language> {
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

    return result
  }

  async delete(id: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM languages WHERE id = ?'
    ).bind(id).run()
    return (result.meta?.changes ?? 0) > 0
  }

  async getLanguageStats(code: string): Promise<{ expression_count: number } | null> {
    return await this.db.prepare(
      'SELECT expression_count FROM language_stats WHERE language_code = ?'
    ).bind(code).first<{ expression_count: number }>() || null
  }
}
