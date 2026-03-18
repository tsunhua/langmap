import { Hono } from 'hono'
import { CollectionService } from '../services/collection.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import { createCollectionSchema, collectionsQuerySchema } from '../schemas/collection.js'
import { success, created, badRequest, forbidden, notFound, internalError } from '../utils/response.js'

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
      return forbidden(c, 'Access denied to private collections')
    }

    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')

    const collections = await service.getAll(userId, isPublic, skip, limit)
    return success(c, collections)
  } catch (error: any) {
    console.error('Error in GET /collections:', error)
    return internalError(c, 'Failed to fetch collections')
  }
})

collectionsRoutes.get('/check-item', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    const expressionId = parseInt(c.req.query('expression_id') || '0')

    if (!expressionId) {
      return badRequest(c, 'Expression ID is required')
    }

    const collectionIds = await service.getContainingCollections(user.id, expressionId)
    return success(c, collectionIds)
  } catch (error) {
    console.error('Error in GET /collections/check-item:', error)
    return internalError(c, 'Failed to check collections')
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

    return created(c, collection)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Error in POST /collections:', error)
    return internalError(c, 'Failed to create collection')
  }
})

collectionsRoutes.get('/:id', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const id = parseInt(c.req.param('id'))

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    const collection = await service.getById(id)

    if (!collection) {
      return notFound(c, 'Collection')
    }

    if (!collection.is_public) {
      const user = c.get('user')
      if (!user || collection.user_id !== user.id) {
        return forbidden(c, 'Access denied')
      }
    }

    return success(c, collection)
  } catch (error: any) {
    console.error('Error in GET /collections/:id:', error)
    return internalError(c, 'Failed to fetch collection')
  }
})

collectionsRoutes.put('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    const existing = await db.getCollectionById(id)
    if (!existing) return notFound(c, 'Collection')

    if (existing.user_id !== user.id) {
      return forbidden(c, 'Access denied')
    }

    const updated = await db.updateCollection(id, body)
    return success(c, updated)
  } catch (error: any) {
    console.error('Error in PUT /collections/:id:', error)
    return internalError(c, 'Failed to update collection')
  }
})

collectionsRoutes.delete('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new CollectionService(db)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    const existing = await db.getCollectionById(id)
    if (!existing) return notFound(c, 'Collection')

    if (existing.user_id !== user.id) {
      return forbidden(c, 'Access denied')
    }

    await service.delete(id)
    return success(c, null, 'Collection deleted')
  } catch (error: any) {
    console.error('Error in DELETE /collections/:id:', error)
    return internalError(c, 'Failed to delete collection')
  }
})

collectionsRoutes.get('/:id/items', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'))
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    const collection = await db.getCollectionById(id)
    if (!collection) return notFound(c, 'Collection')

    const user = c.get('user')
    if (!collection.is_public) {
      if (!user || collection.user_id !== user.id) {
        return forbidden(c, 'Access denied')
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

    return success(c, detailedItems)
  } catch (error: any) {
    console.error('Error in GET /collections/:id/items:', error)
    return internalError(c, 'Failed to fetch collection items')
  }
})

collectionsRoutes.post('/:id/items', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()

    if (isNaN(id)) return badRequest(c, 'Invalid ID')
    if (!body.expression_id) return badRequest(c, 'expression_id is required')

    const collection = await db.getCollectionById(id)
    if (!collection) return notFound(c, 'Collection')

    if (collection.user_id !== user.id) {
      return forbidden(c, 'Access denied')
    }

    const item = await db.addCollectionItem({
      collection_id: id,
      expression_id: body.expression_id,
      note: body.note
    })

    return created(c, item)
  } catch (error: any) {
    console.error('Error in POST /collections/:id/items:', error)
    return internalError(c, 'Failed to add item to collection')
  }
})

collectionsRoutes.delete('/:id/items/:expressionId', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const expressionId = parseInt(c.req.param('expressionId'))

    if (isNaN(id) || isNaN(expressionId)) return badRequest(c, 'Invalid ID')

    const collection = await db.getCollectionById(id)
    if (!collection) return notFound(c, 'Collection')

    if (collection.user_id !== user.id) {
      return forbidden(c, 'Access denied')
    }

    await db.removeCollectionItem(id, expressionId)
    return success(c, null, 'Item removed from collection')
  } catch (error: any) {
    console.error('Error in DELETE /collections/:id/items/:expressionId:', error)
    return internalError(c, 'Failed to remove item from collection')
  }
})

export default collectionsRoutes
