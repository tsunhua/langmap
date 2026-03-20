import type { Collection, CollectionItem } from '../types/entity.js'
import { NotFoundError } from '../types/error.js'

interface DBService {
  collections: any
  stableCollectionId(userId: number, name: string): number
  stableCollectionItemId(collectionId: number, expressionId: number): number
}

export class CollectionService {
  constructor(private db: DBService) {}

  async getAll(userId?: number, isPublic?: boolean, skip: number = 0, limit: number = 20): Promise<Collection[]> {
    return this.db.collections.findAll(userId, isPublic, skip, limit)
  }

  async getById(id: number): Promise<Collection> {
    const collection = await this.db.collections.findById(id)
    if (!collection) {
      throw new NotFoundError('Collection')
    }
    return collection
  }

  async create(userId: number, data: any): Promise<Collection> {
    const id = this.db.stableCollectionId(userId, data.name)
    return this.db.collections.create(id, userId, data.name, data.description || null, !!data.is_public)
  }

  async update(id: number, data: any): Promise<Collection> {
    const collection = await this.db.collections.update(id, data)
    if (!collection) {
      throw new NotFoundError('Collection')
    }
    return collection
  }

  async delete(id: number): Promise<void> {
    const success = await this.db.collections.delete(id)
    if (!success) {
      throw new NotFoundError('Collection')
    }
  }

  async getItems(collectionId: number): Promise<CollectionItem[]> {
    return this.db.collections.findItems(collectionId)
  }

  async addItem(collectionId: number, expressionId: number): Promise<CollectionItem> {
    const id = this.db.stableCollectionItemId(collectionId, expressionId)
    return this.db.collections.addItem(id, collectionId, expressionId, null)
  }

  async removeItem(collectionId: number, expressionId: number): Promise<void> {
    const success = await this.db.collections.removeItem(collectionId, expressionId)
    if (!success) {
      throw new NotFoundError('Collection item')
    }
  }

  async getContainingCollections(userId: number, expressionId: number): Promise<number[]> {
    return this.db.collections.findContainingCollections(userId, expressionId)
  }
}
