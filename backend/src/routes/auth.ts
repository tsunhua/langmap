import { Hono } from 'hono';
import { SignJWT } from 'jose';
import bcrypt from 'bcryptjs';
import { requireAuth } from '../middleware/auth';
import { success, created, badRequest, conflict, internalError, unauthorized } from '../utils/response';
import type { Bindings, Variables } from '../types';

interface AuthUserRow {
  id: number;
  username: string;
  email: string;
  role: string;
  email_verified: number;
}

const auth = new Hono<{ Bindings: Bindings; Variables: Variables }>();

export async function hashPassword(password: string) {
  const salt = crypto.randomUUID().replace(/-/g, '');
  const input = new TextEncoder().encode(`${salt}:${password}`);
  const digest = await crypto.subtle.digest('SHA-256', input);
  const hex = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
  return `${salt}:${hex}`;
}

function isBcryptHash(storedHash: string): boolean {
  return /^\$2[aby]\$\d{2}\$/.test(storedHash);
}

export async function verifyPassword(password: string, storedHash: string): Promise<boolean> {
  if (!storedHash) return false;
  if (isBcryptHash(storedHash)) {
    return bcrypt.compare(password, storedHash);
  }
  if (!storedHash.includes(':')) return false;
  const [salt, expectedHash] = storedHash.split(':');
  const input = new TextEncoder().encode(`${salt}:${password}`);
  const digest = await crypto.subtle.digest('SHA-256', input);
  const actualHash = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
  return actualHash === expectedHash;
}

async function issueToken(c: { env: Bindings }, user: AuthUserRow) {
  return await new SignJWT({ id: user.id, username: user.username, role: user.role })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(new TextEncoder().encode(c.env.SECRET_KEY));
}

auth.get('/health', (c) => success(c, { status: 'ok' }));

auth.post('/register', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const username = typeof body?.username === 'string' ? body.username.trim() : '';
    const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : '';
    const password = typeof body?.password === 'string' ? body.password : '';

    if (!username || !email || !password) {
      return badRequest(c, 'VALIDATION_FAILED', 'Username, email, and password are required');
    }

    const existing = await c.env.DB.prepare(
      'SELECT id FROM users WHERE email = ? OR username = ?'
    ).bind(email, username).first<{ id: number }>();

    if (existing) {
      return conflict(c, 'USER_EXISTS', 'An account with that email or username already exists');
    }

    const passwordHash = await hashPassword(password);
    const insertResult = await c.env.DB.prepare(
      'INSERT INTO users (username, email, password_hash, role, email_verified) VALUES (?, ?, ?, ?, 1)'
    ).bind(username, email, passwordHash, 'user').run();

    const userId = Number(insertResult.meta.last_row_id || 0);
    const user = await c.env.DB.prepare(
      'SELECT id, username, email, role, email_verified FROM users WHERE id = ?'
    ).bind(userId).first<AuthUserRow>();

    if (!user) {
      return internalError(c);
    }

    const token = await issueToken(c, user);
    return created(c, { user: { id: user.id, username: user.username, email: user.email, role: user.role, email_verified: user.email_verified }, token }, 'User registered successfully');
  } catch (error: any) {
    console.error('Register error:', error);
    return internalError(c);
  }
});

auth.post('/login', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : '';
    const password = typeof body?.password === 'string' ? body.password : '';

    if (!email || !password) {
      return badRequest(c, 'VALIDATION_FAILED', 'Email and password are required');
    }

    const user = await c.env.DB.prepare(
      'SELECT id, username, email, password_hash, role, email_verified FROM users WHERE email = ?'
    ).bind(email).first<AuthUserRow & { password_hash: string }>();

    if (!user) {
      return unauthorized(c, 'INVALID_CREDENTIALS', 'Invalid email or password');
    }

    const valid = await verifyPassword(password, user.password_hash);
    if (!valid) {
      return unauthorized(c, 'INVALID_CREDENTIALS', 'Invalid email or password');
    }

    const token = await issueToken(c, user);
    return success(c, {
      user: { id: user.id, username: user.username, email: user.email, role: user.role, email_verified: user.email_verified },
      token,
    }, 'Logged in successfully');
  } catch (error: any) {
    console.error('Login error:', error);
    return internalError(c);
  }
});

auth.post('/logout', (c) => success(c, null, 'Logged out successfully'));

auth.get('/me', requireAuth, async (c) => {
  try {
    const currentUser = c.get('user');
    const user = await c.env.DB.prepare(
      'SELECT id, username, email, role, email_verified FROM users WHERE id = ?'
    ).bind(currentUser?.id).first<AuthUserRow>();

    return success(c, user);
  } catch (error: any) {
    console.error('Me error:', error);
    return internalError(c);
  }
});

export default auth;
