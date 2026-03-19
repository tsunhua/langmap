import { D1Database } from '@cloudflare/workers-types'
import { Handbook } from '../protocol.js'

export class HandbookQueries {
  constructor(private db: D1Database) {}

  async findAll(userId?: number, isPublic?: boolean, skip: number = 0, limit: number = 20): Promise<Handbook[]> {
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

    const { results } = await this.db.prepare(query).bind(...bindings).all<Handbook>()
    return results || []
  }

  async findById(id: number): Promise<Handbook | null> {
    const handbook = await this.db.prepare(
      `SELECT h.*, u.username as created_by 
       FROM handbooks h 
       LEFT JOIN users u ON h.user_id = u.id 
       WHERE h.id = ?`
    ).bind(id).first<Handbook & { created_by?: string }>()
    return (handbook as Handbook) || null
  }

  async create(id: number, handbook: Partial<Handbook>): Promise<Handbook> {
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

    return result
  }

  async update(id: number, handbook: Partial<Handbook>): Promise<Handbook> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(handbook).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at' && key !== 'user_id' && key !== 'renders') {
        fields.push(`${key} = ?`)
        values.push(key === 'is_public' ? (value ? 1 : 0) : value)
      }
    })

    if (fields.length === 0) {
      return this.findById(id) as any
    }

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

    return result
  }

  async delete(id: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM handbooks WHERE id = ?'
    ).bind(id).run()
    return (result.meta?.changes ?? 0) > 0
  }

  async findRenders(id: number): Promise<string | null> {
    const result = await this.db.prepare(
      'SELECT renders FROM handbooks WHERE id = ?'
    ).bind(id).first<{ renders: string }>()
    return result?.renders || null
  }

  async updateRenders(id: number, renders: string): Promise<void> {
    await this.db.prepare(
      'UPDATE handbooks SET renders = ? WHERE id = ?'
    ).bind(renders, id).run()
  }

  async getRender(id: number, targetLang: string): Promise<any | null> {
    const result = await this.db.prepare(
      'SELECT renders FROM handbooks WHERE id = ?'
    ).bind(id).first<{ renders: string }>()
    
    if (!result?.renders) return null
    
    try {
      const renders = JSON.parse(result.renders)
      return renders[targetLang] || null
    } catch (e) {
      console.error('Failed to parse renders:', e)
      return null
    }
  }

  async saveRender(data: { handbook_id: number, target_lang: string, rendered_title: string, rendered_description: string, rendered_content: string }): Promise<void> {
    const currentResult = await this.db.prepare(
      'SELECT renders FROM handbooks WHERE id = ?'
    ).bind(data.handbook_id).first<{ renders: string }>()
    
    let renders: any = {}
    if (currentResult?.renders) {
      try {
        renders = JSON.parse(currentResult.renders)
      } catch (e) {
        console.error('Failed to parse current renders:', e)
      }
    }
    
    renders[data.target_lang] = {
      rendered_title: data.rendered_title,
      rendered_description: data.rendered_description,
      rendered_content: data.rendered_content
    }
    
    await this.db.prepare(
      'UPDATE handbooks SET renders = ? WHERE id = ?'
    ).bind(JSON.stringify(renders), data.handbook_id).run()
  }

  prepareInvalidateRenders(id: number) {
    return this.db.prepare('UPDATE handbooks SET renders = ? WHERE id = ?').bind('{}', id)
  }

  prepareDeleteRenders(id: number) {
    return this.db.prepare('UPDATE handbooks SET renders = ? WHERE id = ?').bind('{}', id)
  }

  prepareDeleteHandbook(id: number) {
    return this.db.prepare('DELETE FROM handbooks WHERE id = ?').bind(id)
  }
}
