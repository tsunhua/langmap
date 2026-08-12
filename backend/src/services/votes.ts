import type { D1Database } from '@cloudflare/workers-types';

export class VoteError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'VoteError';
  }
}

const EDGE_EXISTS_SQL = 'SELECT 1 FROM expression_edges WHERE id = ?';

const SCORE_SQL = 'SELECT COALESCE(SUM(vote), 0) AS score FROM votes WHERE target_type = ? AND target_id = ?';

const UPSERT_SQL = 'INSERT INTO votes (id, user_id, target_type, target_id, vote) VALUES (?, ?, ?, ?, ?) ON CONFLICT(user_id, target_type, target_id) DO UPDATE SET vote = excluded.vote, updated_at = CURRENT_TIMESTAMP';

export async function getVoteScore(
  db: D1Database,
  targetType: string,
  targetId: string,
): Promise<number> {
  const row = await db
    .prepare(SCORE_SQL)
    .bind(targetType, targetId)
    .first<{ score: number }>();
  return row?.score ?? 0;
}

export async function castVote(
  db: D1Database,
  input: { target_type: 'edge'; target_id: string; vote: number; user_id: number },
): Promise<{ score: number; user_vote: number }> {
  if (input.vote !== 1 && input.vote !== -1) throw new VoteError('VOTE_INVALID_VALUE');

  const target = await db.prepare(EDGE_EXISTS_SQL).bind(input.target_id).first();
  if (!target) throw new VoteError('VOTE_TARGET_NOT_FOUND');

  await db
    .prepare(UPSERT_SQL)
    .bind(crypto.randomUUID(), input.user_id, input.target_type, input.target_id, input.vote)
    .run();

  const score = await getVoteScore(db, input.target_type, input.target_id);
  return { score, user_vote: input.vote };
}
