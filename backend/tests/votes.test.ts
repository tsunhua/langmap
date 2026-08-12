import { describe, expect, it } from 'vitest';
import { VoteError, castVote, getVoteScore } from '../src/services/votes';

type Handler = (args: unknown[]) => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const batchSql: string[][] = [];
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(...args: unknown[]) {
        const run = async () => (handler ? handler(args) : { results: [] });
        return {
          __sql: sql,
          async first<T>() { return (await run()) as T; },
          async run() { return handler ? await handler(args) : { success: true }; },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  return {
    prepare,
    batch: async (statements: Array<{ __sql?: string }>) => {
      batchSql.push(statements.map((statement) => statement.__sql ?? ''));
      return statements.map((statement) => {
        const result = handlers[statement.__sql ?? '']?.([]) ?? { results: [] };
        return result;
      });
    },
    batchSql,
  } as unknown as import('@cloudflare/workers-types').D1Database & { batchSql: string[][] };
}

const EDGE_EXISTS_SQL = 'SELECT 1 FROM expression_edges WHERE id = ?';
const SCORE_SQL = 'SELECT COALESCE(SUM(vote), 0) AS score FROM votes WHERE target_type = ? AND target_id = ?';

describe('castVote', () => {
  it('rejects a vote value outside -1 and 1', async () => {
    const db = fakeD1({});
    await expect(
      castVote(db, { target_type: 'edge', target_id: 'e1', vote: 5, user_id: 1 }),
    ).rejects.toMatchObject({ code: 'VOTE_INVALID_VALUE' });
  });

  it('rejects a vote against a missing edge', async () => {
    const db = fakeD1({ [EDGE_EXISTS_SQL]: () => null });
    await expect(
      castVote(db, { target_type: 'edge', target_id: 'nope', vote: 1, user_id: 1 }),
    ).rejects.toMatchObject({ code: 'VOTE_TARGET_NOT_FOUND' });
  });

  it('returns the recomputed score after upserting a vote', async () => {
    const db = fakeD1({
      [EDGE_EXISTS_SQL]: () => ({ 1: 1 }),
      'SELECT score FROM expression_edges WHERE id = ?': () => ({ results: [{ score: 3 }] }),
    });
    const result = await castVote(db, { target_type: 'edge', target_id: 'e1', vote: 1, user_id: 7 });
    expect(result.score).toBe(3);
    expect(result.user_vote).toBe(1);
  });

  it('updates the edge score in the same batch as the vote', async () => {
    const updateScoreSql = "UPDATE expression_edges SET score = (SELECT COALESCE(SUM(vote), 0) FROM votes WHERE target_type = 'edge' AND target_id = ?) WHERE id = ?";
    const readScoreSql = 'SELECT score FROM expression_edges WHERE id = ?';
    const db = fakeD1({
      [EDGE_EXISTS_SQL]: () => ({ 1: 1 }),
      [readScoreSql]: () => ({ results: [{ score: 3 }] }),
      [updateScoreSql]: () => ({ success: true }),
    });

    const result = await castVote(db, { target_type: 'edge', target_id: 'e1', vote: 1, user_id: 7 });

    expect(db.batchSql).toEqual([
      [
        expect.stringContaining('INSERT INTO votes'),
        updateScoreSql,
        readScoreSql,
      ],
    ]);
    expect(result).toEqual({ score: 3, user_vote: 1 });
  });
});

describe('getVoteScore', () => {
  it('returns 0 when there are no votes', async () => {
    const db = fakeD1({ [SCORE_SQL]: () => ({ score: 0 }) });
    expect(await getVoteScore(db, 'edge', 'e1')).toBe(0);
  });
});
