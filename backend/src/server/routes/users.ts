import { Hono } from 'hono'
import { UserService } from '../services/user.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { updateUserSchema } from '../schemas/user.js'
import { success, badRequest, internalError } from '../utils/response.js'

const usersRoutes = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>()

usersRoutes.get('/me', requireAuth, async (c) => {
  try {
    const user = c.get('user')
    const db = createDatabaseService(c.env)
    const service = new UserService(db)
    const fullUser = await service.getById(user.id)

    return success(c, fullUser)
  } catch (error: any) {
    console.error('Get user error:', error)
    return internalError(c, error.message || 'Failed to get user')
  }
})

usersRoutes.patch('/me', requireAuth, async (c) => {
  try {
    const user = c.get('user')
    const db = createDatabaseService(c.env)
    const service = new UserService(db)
    const body = await c.req.json()

    const validated = updateUserSchema.parse(body)
    const updatedUser = await service.update(user.id, validated)

    return success(c, updatedUser)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Update user error:', error)
    return internalError(c, error.message || 'Failed to update user')
  }
})

export default usersRoutes
