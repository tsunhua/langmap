import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { success, internalError } from '../utils/response';
import type { Bindings, Variables } from '../types';
import { dictionaryReleaseSchemaAvailable, edgeEligibilityPredicate } from '../services/dictionaryReleaseEligibility';

interface UserProfileRow {
  id: number;
  username: string;
  email: string;
  role: string;
  created_at: string;
}

interface ActivityRow {
  type: string;
  description: string;
  ref_id: string;
  created_at: string;
}

const users = new Hono<{ Bindings: Bindings; Variables: Variables }>();

const ACTIVITY_QUERY = `
SELECT 'expression' AS type,
       'Added expression "' || e.text || '" (' || e.lang_code || ')' AS description,
       e.id AS ref_id,
       e.created_at
FROM expressions e
WHERE e.created_by = ?
UNION ALL
SELECT 'mapping' AS type,
       'Mapped "' || ea.text || '" → "' || eb.text || '"' AS description,
       ee.id AS ref_id,
       ee.created_at
FROM expression_edges ee
JOIN expressions ea ON ee.expression_a_id = ea.id
JOIN expressions eb ON ee.expression_b_id = eb.id
WHERE ee.created_by = ?
UNION ALL
SELECT 'handbook' AS type,
       'Created handbook "' || h.title || '"' AS description,
       h.id AS ref_id,
       h.created_at
FROM handbooks h
WHERE h.user_id = ?
UNION ALL
SELECT 'vote' AS type,
       CASE WHEN v.vote = 1 THEN 'Upvoted' ELSE 'Downvoted' END || ' a mapping' AS description,
       v.target_id AS ref_id,
       v.created_at
FROM votes v
WHERE v.user_id = ?
ORDER BY created_at DESC
LIMIT 20
`;

function managedActivityQuery(releaseTablesReady: boolean): string {
  if (!releaseTablesReady) return ACTIVITY_QUERY;
  return ACTIVITY_QUERY
    .replace('WHERE ee.created_by = ?', `WHERE ee.created_by = ? AND ${edgeEligibilityPredicate('ee')}`)
    .replace('WHERE v.user_id = ?', `WHERE v.user_id = ? AND EXISTS (SELECT 1 FROM expression_edges vote_edge WHERE vote_edge.id = v.target_id AND ${edgeEligibilityPredicate('vote_edge')})`);
}

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

    const releaseTablesReady = await dictionaryReleaseSchemaAvailable(c.env.DB);
    const { results: activity } = await c.env.DB.prepare(managedActivityQuery(releaseTablesReady))
      .bind(userId, userId, userId, userId)
      .all<ActivityRow>();

    return success(c, { user, activity });
  } catch (error: any) {
    console.error('Users/me error:', error);
    return internalError(c);
  }
});

export default users;
