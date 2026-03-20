import { Hono } from 'hono'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { cacheMiddleware, clearCache } from '../middleware/cache.js'
import { success, badRequest, notFound, internalError } from '../utils/response.js'

const expressionGroupRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

/**
 * GET /api/v1/groups/:id
 * Get a specific expression group by ID
 */
expressionGroupRoutes.get('/:id', cacheMiddleware(300), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'), 10)

    if (isNaN(id)) {
      return badRequest(c, 'Invalid group ID')
    }

    const langParam = c.req.query('lang')
    const languages = langParam ? langParam.split(',').map(l => l.trim()) : undefined

    const group = await db.groups.getGroupInfo(id, languages)

    if (!group) {
      return notFound(c, 'Expression Group')
    }

    return success(c, group)
  } catch (error: any) {
    console.error('Error in GET /groups/:id:', error)
    return internalError(c, 'Failed to fetch expression group')
  }
})

/**
 * GET /api/v1/groups
 * List all expression groups with pagination and optional language filtering
 */
expressionGroupRoutes.get('/', cacheMiddleware(300), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    const langParam = c.req.query('lang')
    const languages = langParam ? langParam.split(',').map(l => l.trim()) : undefined

    if (skip < 0 || limit < 1 || limit > 100) {
      return badRequest(c, 'Invalid pagination parameters')
    }

    const result = await db.groups.listGroups(skip, limit, languages)

    return success(c, result)
  } catch (error: any) {
    console.error('Error in GET /groups:', error)
    return internalError(c, 'Failed to fetch expression groups')
  }
})

/**
 * GET /api/v1/groups/search
 * Search for expression groups
 */
expressionGroupRoutes.get('/search', cacheMiddleware(300), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const query = c.req.query('q') || ''
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    const langParam = c.req.query('lang')
    const languages = langParam ? langParam.split(',').map(l => l.trim()) : undefined

    if (!query) {
      return badRequest(c, 'Query parameter is required')
    }

    if (skip < 0 || limit < 1 || limit > 100) {
      return badRequest(c, 'Invalid pagination parameters')
    }

    const result = await db.groups.searchGroups(query, skip, limit, languages)

    return success(c, result)
  } catch (error: any) {
    console.error('Error in GET /groups/search:', error)
    return internalError(c, 'Failed to search expression groups')
  }
})

/**
 * POST /api/v1/groups
 * Create a new expression group
 */
expressionGroupRoutes.post('/', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const body = await c.req.json()
    const { anchor_expression_id } = body

    if (!anchor_expression_id) {
      return badRequest(c, 'anchor_expression_id is required')
    }

    const anchorExpressionId = parseInt(anchor_expression_id, 10)

    if (isNaN(anchorExpressionId)) {
      return badRequest(c, 'Invalid anchor expression ID')
    }

    const group = await db.groups.createGroup(anchorExpressionId, user.username)

    return success(c, group, 'Expression group created successfully')
  } catch (error: any) {
    console.error('Error in POST /groups:', error)
    return internalError(c, error.message || 'Failed to create expression group')
  }
})

/**
 * POST /api/v1/groups/:id/expressions
 * Add an expression to a group
 */
expressionGroupRoutes.post('/:id/expressions', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const groupId = parseInt(c.req.param('id'), 10)
    const body = await c.req.json()
    const { expression_id } = body

    if (isNaN(groupId)) {
      return badRequest(c, 'Invalid group ID')
    }

    if (!expression_id) {
      return badRequest(c, 'expression_id is required')
    }

    const expressionId = parseInt(expression_id, 10)

    if (isNaN(expressionId)) {
      return badRequest(c, 'Invalid expression ID')
    }

    await db.groups.addToGroup(expressionId, groupId, user.username)
    await clearCache(c, `/api/v1/groups/${groupId}`)

    return success(c, null, 'Expression added to group successfully')
  } catch (error: any) {
    console.error('Error in POST /groups/:id/expressions:', error)
    return internalError(c, error.message || 'Failed to add expression to group')
  }
})

/**
 * DELETE /api/v1/groups/:id/expressions/:expressionId
 * Remove an expression from a group
 */
expressionGroupRoutes.delete('/:id/expressions/:expressionId', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const groupId = parseInt(c.req.param('id'), 10)
    const expressionId = parseInt(c.req.param('expressionId'), 10)

    if (isNaN(groupId) || isNaN(expressionId)) {
      return badRequest(c, 'Invalid IDs')
    }

    await db.groups.removeFromGroup(expressionId, groupId)

    return success(c, null, 'Expression removed from group successfully')
  } catch (error: any) {
    console.error('Error in DELETE /groups/:id/expressions/:expressionId:', error)
    return internalError(c, error.message || 'Failed to remove expression from group')
  }
})

/**
 * POST /api/v1/groups/:id/merge
 * Merge one group into another
 */
expressionGroupRoutes.post('/:id/merge', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const targetGroupId = parseInt(c.req.param('id'), 10)
    const body = await c.req.json()
    const { source_group_id } = body

    if (isNaN(targetGroupId)) {
      return badRequest(c, 'Invalid target group ID')
    }

    if (!source_group_id) {
      return badRequest(c, 'source_group_id is required')
    }

    const sourceGroupId = parseInt(source_group_id, 10)

    if (isNaN(sourceGroupId)) {
      return badRequest(c, 'Invalid source group ID')
    }

    if (sourceGroupId === targetGroupId) {
      return badRequest(c, 'Cannot merge a group into itself')
    }

    const result = await db.groups.mergeGroups(sourceGroupId, targetGroupId)

    return success(c, result, 'Expression groups merged successfully')
  } catch (error: any) {
    console.error('Error in POST /groups/:id/merge:', error)
    return internalError(c, error.message || 'Failed to merge expression groups')
  }
})

/**
 * DELETE /api/v1/groups/:id
 * Delete an expression group
 */
expressionGroupRoutes.delete('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'), 10)

    if (isNaN(id)) {
      return badRequest(c, 'Invalid group ID')
    }

    await db.groups.deleteGroup(id)

    return success(c, null, 'Expression group deleted successfully')
  } catch (error: any) {
    console.error('Error in DELETE /groups/:id:', error)
    return internalError(c, error.message || 'Failed to delete expression group')
  }
})

export default expressionGroupRoutes
