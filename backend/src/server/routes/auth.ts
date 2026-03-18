import { Hono } from 'hono'
import { Resend } from 'resend'
import { AuthService } from '../services/auth.js'
import { UserService } from '../services/user.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import { registerSchema, loginSchema, verifyEmailQuerySchema } from '../schemas/auth.js'
import { zValidator } from '@hono/zod-validator'
import { success, created, badRequest, internalError } from '../utils/response.js'

const authRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

authRoutes.get('/health', (c) => {
  return c.json({ status: 'ok', message: 'Auth API is running' })
})

authRoutes.post('/register', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const body = await c.req.json()
    const validated = registerSchema.parse(body)

    const authService = new AuthService(db)
    const resend = new Resend(c.env.RESEND_API_KEY)
    const baseUrl = c.req.url.split('/api')[0]

    const result = await authService.register(
      validated.username,
      validated.email,
      validated.password,
      resend,
      baseUrl
    )

    const { password_hash: _, ...userResponse } = result.user

    return created(c, { user: userResponse }, 'User registered successfully. Please check your email for verification.')
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Registration error:', error)
    return internalError(c, error.message || 'Failed to register user')
  }
})

authRoutes.post('/login', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const body = await c.req.json()
    const validated = loginSchema.parse(body)

    const authService = new AuthService(db)
    const result = await authService.login(validated.email, validated.password, c.env.SECRET_KEY)

    return success(c, result)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Login error:', error)
    return internalError(c, error.message || 'Failed to login')
  }
})

authRoutes.post('/logout', (c) => {
  return success(c, null, 'Logged out successfully')
})

authRoutes.get('/verify-email', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const validated = verifyEmailQuerySchema.parse(c.req.query())

    const authService = new AuthService(db)
    await authService.verifyEmail(validated.token)

    return success(c, null, 'Email verified successfully. You can now log in.')
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Email verification error:', error)
    return internalError(c, error.message || 'Failed to verify email')
  }
})

authRoutes.get('/me', requireAuth, async (c) => {
  try {
    const user = c.get('user')
    const db = createDatabaseService(c.env)
    const userService = new UserService(db)
    const fullUser = await userService.getById(user.id)

    return success(c, fullUser)
  } catch (error: any) {
    console.error('Get user error:', error)
    return internalError(c, error.message || 'Failed to get user')
  }
})

export default authRoutes
