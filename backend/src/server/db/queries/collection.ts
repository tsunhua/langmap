import { D1Database } from '@cloudflare/workers-types'
import { Collection, CollectionItem } from '../protocol.js'

export class CollectionQueries {
  constructor(private db: D1Database) {}

  async findAll(userId?: number, isPublic?: boolean, skip: number = 0, limit: number = 20): Promise<Collection[]> {
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
    return results || []
  }

  async findById(id: number): Promise<Collection | null> {
    const collection = await this.db.prepare(
      'SELECT c.*, c.items_count FROM collections c WHERE c.id = ?'
    ).bind(id).first<Collection>()
    return collection || null
  }

  async create(id: number, userId: number, name: string, description: string | null, isPublic: boolean): Promise<Collection> {
    const bindValues = [
      id,
      userId,
      name,
      description,
      isPublic ? 1 : 0
    ]

    const result = await this.db.prepare(
      `INSERT INTO collections (
        id, user_id, name, description, is_public
      ) VALUES (?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<Collection>()

    if (!result) {
      throw new Error('Failed to create collection')
    }

    return result
  }

  async update(id: number, data: Partial<Collection>): Promise<Collection> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(data).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'user_id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(key === 'is_public' ? (value ? 1 : 0) : value)
      }
    })

    values.push(id)

    const result = await this.db.prepare(
      `UPDATE collections SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).first<Collection>()

    if (!result) {
      throw new Error('Failed to update collection')
    }

    return result
  }

  async delete(id: number): Promise<boolean> {
    // Note: Caller should handle deleting items if cascading isn't automatic
    const result = await this.db.prepare(
      'DELETE FROM collections WHERE id = ?'
    ).bind(id).run()

    return (result.meta?.changes ?? 0) > 0
  }

  async findItems(collectionId: number, skip: number = 0, limit: number = 50): Promise<CollectionItem[]> {
    const { results } = await this.db.prepare(
      'SELECT * FROM collection_items WHERE collection_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?'
    ).bind(collectionId, limit, skip).all<CollectionItem>()
    return results || []
  }

  async addItem(id: number, collectionId: number, expressionId: number, note: string | null): Promise<CollectionItem> {
    const bindValues = [
      id,
      collectionId,
      expressionId,
      note
    ]

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

    return result
  }

  async findItem(collectionId: number, expressionId: number): Promise<CollectionItem | null> {
    return await this.db.prepare(
      'SELECT * FROM collection_items WHERE collection_id = ? AND expression_id = ?'
    ).bind(collectionId, expressionId).first<CollectionItem>() || null
  }

  async removeItem(collectionId: number, expressionId: number): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM collection_items WHERE collection_id = ? AND expression_id = ?'
    ).bind(collectionId, expressionId).run()

    const changed = (result.meta?.changes ?? 0) > 0
    if (changed) {
      // Decrement items_count in collections
      await this.db.prepare('UPDATE collections SET items_count = MAX(0, items_count - 1) WHERE id = ?').bind(collectionId).run()
    }

    return changed
  }

  async findContainingCollections(userId: number, expressionId: number): Promise<number[]> {
    const query = `
      SELECT ci.collection_id
      FROM collection_items ci
      JOIN collections c ON ci.collection_id = c.id
      WHERE ci.expression_id = ? AND c.user_id = ?
    `
    const { results } = await this.db.prepare(query).bind(expressionId, userId).all<{ collection_id: number }>()
    return (results || []).map(r => r.collection_id)
  }

  prepareDeleteItems(collectionId: number) {
    return this.db.prepare('DELETE FROM collection_items WHERE collection_id = ?').bind(collectionId)
  }

  prepareDeleteCollection(collectionId: number) {
    return this.db.prepare('DELETE FROM collections WHERE id = ?').bind(collectionId)
  }
}
