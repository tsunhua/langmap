import { Context, Next } from 'hono';
import { jwtVerify } from 'jose';
import { unauthorized } from '../utils/response';

interface AuthUser {
  id: number;
  username: string;
  role: string;
}

async function authenticatedUser(c: Context): Promise<AuthUser | null> {
  const auth = c.req.header('Authorization');
  if (!auth?.startsWith('Bearer ')) return null;

  const { payload } = await jwtVerify(auth.slice(7), new TextEncoder().encode(c.env.SECRET_KEY));
  if (typeof payload.id !== 'number' || !Number.isInteger(payload.id)) return null;

  return await c.env.DB.prepare('SELECT id, username, role FROM users WHERE id = ?')
    .bind(payload.id)
    .first<AuthUser>();
}

export async function requireAuth(c: Context, next: Next) {
  try {
    const user = await authenticatedUser(c);
    if (!user) return unauthorized(c);
    c.set('user', user);
    await next();
  } catch {
    return unauthorized(c);
  }
}

export async function optionalAuth(c: Context, next: Next) {
  try {
    const user = await authenticatedUser(c);
    if (user) c.set('user', user);
  } catch { /* ignore */ }
  await next();
}
