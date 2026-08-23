import type { D1Database } from '@cloudflare/workers-types';
import { dictionaryReleaseSchemaAvailable, edgeEligibilityPredicate } from './dictionaryReleaseEligibility';

export class VoteError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'VoteError';
  }
}

const EDGE_EXISTS_SQL = 'SELECT 1 FROM expression_edges WHERE id = ?';

const SCORE_SQL = 'SELECT COALESCE(SUM(vote), 0) AS score FROM votes WHERE target_type = ? AND target_id = ?';

const UPSERT_SQL = 'INSERT INTO votes (id, user_id, target_type, target_id, vote) VALUES (?, ?, ?, ?, ?) ON CONFLICT(user_id, target_type, target_id) DO UPDATE SET vote = excluded.vote, updated_at = CURRENT_TIMESTAMP';

const UPDATE_EDGE_SCORE_SQL = "UPDATE expression_edges SET score = (SELECT COALESCE(SUM(vote), 0) FROM votes WHERE target_type = 'edge' AND target_id = ?) WHERE id = ?";

const EDGE_SCORE_SQL = 'SELECT score FROM expression_edges WHERE id = ?';

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

  const releaseTablesReady = await dictionaryReleaseSchemaAvailable(db);
  const targetQuery = releaseTablesReady
    ? `SELECT 1 FROM expression_edges e WHERE e.id = ? AND ${edgeEligibilityPredicate('e')}`
    : EDGE_EXISTS_SQL;
  const target = await db.prepare(targetQuery).bind(input.target_id).first();
  if (!target) throw new VoteError('VOTE_TARGET_NOT_FOUND');

  const upsertVote = db
    .prepare(UPSERT_SQL)
    .bind(crypto.randomUUID(), input.user_id, input.target_type, input.target_id, input.vote);
  const updateScore = db
    .prepare(UPDATE_EDGE_SCORE_SQL)
    .bind(input.target_id, input.target_id);
  const readScore = db.prepare(EDGE_SCORE_SQL).bind(input.target_id);
  const results = await db.batch([upsertVote, updateScore, readScore]);
  const scoreResult = results[2] as unknown as { results?: Array<{ score?: number }> } | undefined;
  const score = Number(scoreResult?.results?.[0]?.score ?? 0);
  return { score, user_vote: input.vote };
}
