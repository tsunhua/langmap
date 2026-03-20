import { Context, Next } from 'hono'
import * as jose from 'jose'
import type { JWTPayload } from '../types/auth.js'

interface Bindings {
  SECRET_KEY: string;
}

async function verifyJWT(token: string, secretKey: string): Promise<any> {
  try {
    const secret = new TextEncoder().encode(secretKey)
    const { payload } = await jose.jwtVerify(token, secret)
    return payload
  } catch (error) {
    return null
  }
}

export async function requireAuth(c: Context<{ Bindings: Bindings, Variables: { user: JWTPayload } }>, next: Next) {
  const authHeader = c.req.header('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Authentication required' }, 401)
  }

  const token = authHeader.substring(7)
  const payload = await verifyJWT(token, c.env.SECRET_KEY)

  if (!payload) {
    return c.json({ error: 'Invalid or expired token' }, 401)
  }

  c.set('user', payload)
  await next()
}

export async function requireAdmin(c: Context<{ Bindings: Bindings, Variables: { user: JWTPayload } }>, next: Next) {
  const authHeader = c.req.header('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Authentication required' }, 401)
  }

  const token = authHeader.substring(7)
  const payload = await verifyJWT(token, c.env.SECRET_KEY)

  if (!payload) {
    return c.json({ error: 'Invalid or expired token' }, 401)
  }

  if (payload.role !== 'admin') {
    return c.json({ error: 'Admin access required' }, 403)
  }

  c.set('user', payload)
  await next()
}

export async function optionalAuth(c: Context<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>, next: Next) {
  const authHeader = c.req.header('Authorization')
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7)
    const payload = await verifyJWT(token, c.env.SECRET_KEY)
    if (payload) {
      c.set('user', payload)
    }
  }
  await next()
}
