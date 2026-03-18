import { Hono } from 'hono'
import { CollectionService } from '../services/collection.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import { createCollectionSchema, collectionsQuerySchema } from '../schemas/collection.js'

const collectionsRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

collectionsRoutes.get('/', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    
    const userIdParam = c.req.query('user_id')
    let userId: number | undefined = userIdParam ? parseInt(userIdParam) : undefined
    
    const isPublicParam = c.req.query('is_public')
    const isPublic = isPublicParam === '1' ? true : (isPublicParam === '0' ? false : undefined)
    
    if (userId === undefined && user && isPublic !== true) {
      userId = user.id
    }
    
    if (isPublic === false && (!user || userId !== user.id)) {
      return c.json({ error: 'Access denied to private collections' }, 403)
    }
    
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    
    const collections = await service.getAll(userId, isPublic, skip, limit)
    return c.json(collections)
  } catch (error: any) {
    console.error('Error in GET /collections:', error)
    return c.json({ error: 'Failed to fetch collections' }, 500)
  }
})

collectionsRoutes.get('/check-item', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    const expressionId = parseInt(c.req.query('expression_id') || '0')
    
    if (!expressionId) {
      return c.json({ error: 'Expression ID is required' }, 400)
    }
    
    const collectionIds = await service.getContainingCollections(user.id, expressionId)
    return c.json(collectionIds)
  } catch (error) {
    console.error('Error in GET /collections/check-item:', error)
    return c.json({ error: 'Failed to check collections' }, 500)
  }
})

collectionsRoutes.post('/', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    const body = await c.req.json()
    
    const validated = createCollectionSchema.parse(body)
    const collection = await service.create(user.id, validated)
    
    return c.json(collection, 201)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Error in POST /collections:', error)
    return c.json({ error: 'Failed to create collection' }, 500)
  }
})

collectionsRoutes.get('/:id', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const id = parseInt(c.req.param('id'))
    
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)
    
    const collection = await service.getById(id)
    
    if (!collection) {
      return c.json({ error: 'Collection not found' }, 404)
    }
    
    if (!collection.is_public) {
      const user = c.get('user')
      if (!user || collection.user_id !== user.id) {
        return c.json({ error: 'Access denied' }, 403)
      }
    }
    
    return c.json(collection)
  } catch (error: any) {
    console.error('Error in GET /collections/:id:', error)
    return c.json({ error: 'Failed to fetch collection' }, 500)
  }
})

collectionsRoutes.put('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()
    
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)
    
    const existing = await db.getCollectionById(id)
    if (!existing) return c.json({ error: 'Collection not found' }, 404)
    
    if (existing.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }
    
    const updated = await db.updateCollection(id, body)
    return c.json(updated)
  } catch (error: any) {
    console.error('Error in PUT /collections/:id:', error)
    return c.json({ error: 'Failed to update collection' }, 500)
  }
})

collectionsRoutes.delete('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)
    
    const existing = await db.getCollectionById(id)
    if (!existing) return c.json({ error: 'Collection not found' }, 404)
    
    if (existing.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }
    
    await service.delete(id)
    return c.json({ message: 'Collection deleted' })
  } catch (error: any) {
    console.error('Error in DELETE /collections/:id:', error)
    return c.json({ error: 'Failed to delete collection' }, 500)
  }
})

collectionsRoutes.get('/:id/items', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'))
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)
    
    const collection = await db.getCollectionById(id)
    if (!collection) return c.json({ error: 'Collection not found' }, 404)
    
    const user = c.get('user')
    if (!collection.is_public) {
      if (!user || collection.user_id !== user.id) {
        return c.json({ error: 'Access denied' }, 403)
      }
    }
    
    const items = await db.getCollectionItems(id, skip, limit)
    
    const detailedItems = await Promise.all(items.map(async (item) => {
      const expression = await db.getExpressionById(item.expression_id)
      return {
        ...item,
        expression
      }
    }))
    
    return c.json(detailedItems)
  } catch (error: any) {
    console.error('Error in GET /collections/:id/items:', error)
    return c.json({ error: 'Failed to fetch collection items' }, 500)
  }
})

collectionsRoutes.post('/:id/items', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()
    
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)
    if (!body.expression_id) return c.json({ error: 'expression_id is required' }, 400)
    
    const collection = await db.getCollectionById(id)
    if (!collection) return c.json({ error: 'Collection not found' }, 404)
    
    if (collection.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }
    
    const item = await db.addCollectionItem({
      collection_id: id,
      expression_id: body.expression_id,
      note: body.note
    })
    
    return c.json(item, 201)
  } catch (error: any) {
    console.error('Error in POST /collections/:id/items:', error)
    return c.json({ error: 'Failed to add item to collection' }, 500)
  }
})

collectionsRoutes.delete('/:id/items/:expressionId', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const expressionId = parseInt(c.req.param('expressionId'))
    
    if (isNaN(id) || isNaN(expressionId)) return c.json({ error: 'Invalid ID' }, 400)
    
    const collection = await db.getCollectionById(id)
    if (!collection) return c.json({ error: 'Collection not found' }, 404)
    
    if (collection.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }
    
    await db.removeCollectionItem(id, expressionId)
    return c.json({ message: 'Item removed from collection' })
  } catch (error: any) {
    console.error('Error in DELETE /collections/:id/items/:expressionId:', error)
    return c.json({ error: 'Failed to remove item from collection' }, 500)
  }
})

export default collectionsRoutes
