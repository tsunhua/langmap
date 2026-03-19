import type { Collection, CollectionItem } from '../types/entity.js'
import { NotFoundError } from '../types/error.js'

interface DBService {
  getCollections(userId?: number, isPublic?: boolean, skip?: number, limit?: number): Promise<Collection[]>
  getCollectionById(id: number): Promise<Collection | null>
  createCollection(data: any): Promise<Collection>
  updateCollection(id: number, data: any): Promise<Collection | null>
  deleteCollection(id: number): Promise<boolean>
  getCollectionItems(collectionId: number): Promise<CollectionItem[]>
  addCollectionItem(item: Partial<CollectionItem>): Promise<CollectionItem>
  removeCollectionItem(collectionId: number, expressionId: number): Promise<boolean>
  getCollectionsContainingItem(userId: number, expressionId: number): Promise<number[]>
}

export class CollectionService {
  constructor(private db: DBService) {}

  async getAll(userId?: number, isPublic?: boolean, skip: number = 0, limit: number = 20): Promise<Collection[]> {
    return this.db.getCollections(userId, isPublic, skip, limit)
  }

  async getById(id: number): Promise<Collection> {
    const collection = await this.db.getCollectionById(id)
    if (!collection) {
      throw new NotFoundError('Collection')
    }
    return collection
  }

  async create(userId: number, data: any): Promise<Collection> {
    const collectionData = {
      user_id: userId,
      ...data
    }
    return this.db.createCollection(collectionData)
  }

  async update(id: number, data: any): Promise<Collection> {
    const collection = await this.db.updateCollection(id, data)
    if (!collection) {
      throw new NotFoundError('Collection')
    }
    return collection
  }

  async delete(id: number): Promise<void> {
    const success = await this.db.deleteCollection(id)
    if (!success) {
      throw new NotFoundError('Collection')
    }
  }

  async getItems(collectionId: number): Promise<CollectionItem[]> {
    return this.db.getCollectionItems(collectionId)
  }

  async addItem(collectionId: number, expressionId: number): Promise<CollectionItem> {
    return this.db.addCollectionItem({ collection_id: collectionId, expression_id: expressionId })
  }

  async removeItem(collectionId: number, expressionId: number): Promise<void> {
    const success = await this.db.removeCollectionItem(collectionId, expressionId)
    if (!success) {
      throw new NotFoundError('Collection item')
    }
  }

  async getContainingCollections(userId: number, expressionId: number): Promise<number[]> {
    return this.db.getCollectionsContainingItem(userId, expressionId)
  }
}
