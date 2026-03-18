import { Hono } from 'hono'
import { Resend } from 'resend'
import { AuthService } from '../services/auth.js'
import { UserService } from '../services/user.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import { registerSchema, loginSchema, verifyEmailQuerySchema } from '../schemas/auth.js'
import { zValidator } from '@hono/zod-validator'

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

    return c.json({
      success: true,
      data: { user: userResponse },
      message: 'User registered successfully. Please check your email for verification.'
    }, 201)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Registration error:', error)
    return c.json({ error: error.message || 'Failed to register user' }, error.statusCode || 500)
  }
})

authRoutes.post('/login', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const body = await c.req.json()
    const validated = loginSchema.parse(body)

    const authService = new AuthService(db)
    const result = await authService.login(validated.email, validated.password, c.env.SECRET_KEY)

    return c.json({
      success: true,
      data: result
    })
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Login error:', error)
    return c.json({ error: error.message || 'Failed to login' }, error.statusCode || 500)
  }
})

authRoutes.post('/logout', (c) => {
  return c.json({
    success: true,
    message: 'Logged out successfully'
  })
})

authRoutes.get('/verify-email', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const validated = verifyEmailQuerySchema.parse(c.req.query())

    const authService = new AuthService(db)
    await authService.verifyEmail(validated.token)

    return c.json({
      success: true,
      message: 'Email verified successfully. You can now log in.'
    })
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Email verification error:', error)
    return c.json({ error: error.message || 'Failed to verify email' }, error.statusCode || 500)
  }
})

authRoutes.get('/me', requireAuth, async (c) => {
  try {
    const user = c.get('user')
    const db = createDatabaseService(c.env)
    const userService = new UserService(db)
    const fullUser = await userService.getById(user.id)

    return c.json({
      success: true,
      data: fullUser
    })
  } catch (error: any) {
    console.error('Get user error:', error)
    return c.json({ error: error.message || 'Failed to get user' }, error.statusCode || 500)
  }
})

export default authRoutes
