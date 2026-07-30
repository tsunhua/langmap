import { Hono } from 'hono';
import { success, badRequest } from '../utils/response';
import type { Bindings } from '../types';

const languageRegistry = new Hono<{ Bindings: Bindings }>();

const VALID_TYPES = ['language', 'script', 'region', 'variant'];
const MAX_LIMIT = 50;
const MAX_Q = 80;

function escapeLike(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

languageRegistry.get('/subtags', async (c) => {
  const type = c.req.query('type');
  const q = c.req.query('q') || '';
  const prefix = c.req.query('prefix') || '';
  const limitRaw = Number(c.req.query('limit') || 20);
  const limit = Math.min(Math.max(Number.isFinite(limitRaw) ? limitRaw : 20, 1), MAX_LIMIT);

  if (!type || !VALID_TYPES.includes(type)) {
    return badRequest(c, 'INVALID_TYPE', `type must be one of: ${VALID_TYPES.join(', ')}`);
  }

  const normalizedQ = q.slice(0, MAX_Q);
  const escapedQ = escapeLike(normalizedQ);
  const escapedPrefix = escapeLike(prefix.slice(0, MAX_Q));

  let query = 'SELECT type, value, descriptions, prefixes, preferred_value, suppress_script, deprecated FROM language_subtags WHERE type = ?';
  const params: string[] = [type];

  if (escapedQ) {
    query += ' AND (value LIKE ? ESCAPE \'\\\' OR descriptions LIKE ? ESCAPE \'\\\')';
    params.push(`%${escapedQ}%`, `%${escapedQ}%`);
  }

  if (type === 'variant' && escapedPrefix) {
    query += ' AND prefixes LIKE ? ESCAPE \'\\\'';
    params.push(`%${escapedPrefix}%`);
  }

  if (escapedQ) {
    query += ' ORDER BY CASE'
      + ' WHEN value = ? COLLATE NOCASE THEN 0'
      + ' WHEN value LIKE ? ESCAPE \'\\\' THEN 1'
      + ' ELSE 2 END, value ASC LIMIT ?';
    params.push(normalizedQ, `${escapedQ}%`);
  } else {
    query += ' ORDER BY value ASC LIMIT ?';
  }
  params.push(String(limit));

  const { results } = await c.env.DB.prepare(query).bind(...params).all();

  return success(c, {
    items: results,
    total: results.length,
  });
});

export default languageRegistry;
