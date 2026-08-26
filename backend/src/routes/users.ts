import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { success, internalError } from '../utils/response';
import type { Bindings, Variables } from '../types';

interface UserProfileRow {
  id: number;
  username: string;
  email: string;
  role: string;
  created_at: string;
}


const users = new Hono<{ Bindings: Bindings; Variables: Variables }>();

users.get('/me', requireAuth, async (c) => {
  try {
    const currentUser = c.get('user');
    const userId = currentUser!.id;

    const user = await c.env.DB.prepare(
      'SELECT id, username, email, role, created_at FROM users WHERE id = ?'
    ).bind(userId).first<UserProfileRow>();

    if (!user) {
      return internalError(c);
    }

    return success(c, { user });
  } catch (error) {
    console.error('Users/me error:', error);
    return internalError(c);
  }
});

export default users;
