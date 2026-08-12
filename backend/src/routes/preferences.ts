import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, internalError, success, unauthorized } from '../utils/response';
import { PreferenceError, getPreferences, putPreference } from '../services/preferences';
import type { Bindings, Variables } from '../types';

const preferences = new Hono<{ Bindings: Bindings; Variables: Variables }>();

preferences.get('/', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const result = await getPreferences(c.env.DB, user.id);
    return success(c, result);
  } catch (error) {
    console.error('Get preferences error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to get preferences');
  }
});

preferences.put('/:key', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const key = c.req.param('key') ?? '';
    const body = await c.req.json().catch(() => ({}));
    try {
      const result = await putPreference(c.env.DB, user.id, key, body);
      return success(c, result, 'Preference saved');
    } catch (error) {
      if (error instanceof PreferenceError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Put preference error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to save preference');
  }
});

export default preferences;
