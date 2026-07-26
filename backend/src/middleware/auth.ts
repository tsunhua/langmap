import { Context, Next } from 'hono';
import { jwtVerify } from 'jose';
import { unauthorized } from '../utils/response';

export async function requireAuth(c: Context, next: Next) {
  const auth = c.req.header('Authorization');
  if (!auth?.startsWith('Bearer ')) return unauthorized(c);
  try {
    const { payload } = await jwtVerify(auth.slice(7), new TextEncoder().encode(c.env.SECRET_KEY));
    if (payload.id == null || !payload.username || !payload.role) return unauthorized(c);
    c.set('user', { id: payload.id as number, username: payload.username as string, role: payload.role as string });
    await next();
  } catch {
    return unauthorized(c);
  }
}

export async function optionalAuth(c: Context, next: Next) {
  const auth = c.req.header('Authorization');
  if (auth?.startsWith('Bearer ')) {
    try {
      const { payload } = await jwtVerify(auth.slice(7), new TextEncoder().encode(c.env.SECRET_KEY));
      if (payload.id != null && payload.username && payload.role) {
        c.set('user', { id: payload.id as number, username: payload.username as string, role: payload.role as string });
      }
    } catch { /* ignore */ }
  }
  await next();
}
