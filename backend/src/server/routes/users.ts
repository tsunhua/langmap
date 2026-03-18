import { Hono } from 'hono'
import { UserService } from '../services/user.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { updateUserSchema } from '../schemas/user.js'

const usersRoutes = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>()

usersRoutes.get('/me', requireAuth, async (c) => {
  try {
    const user = c.get('user')
    const db = createDatabaseService(c.env)
    const service = new UserService(db)
    const fullUser = await service.getById(user.id)

    return c.json({
      success: true,
      data: fullUser
    })
  } catch (error: any) {
    console.error('Get user error:', error)
    return c.json({ error: error.message || 'Failed to get user' }, error.statusCode || 500)
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

    return c.json({
      success: true,
      data: updatedUser
    })
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Update user error:', error)
    return c.json({ error: error.message || 'Failed to update user' }, error.statusCode || 500)
  }
})

export default usersRoutes
