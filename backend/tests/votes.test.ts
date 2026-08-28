import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import { SignJWT } from 'jose';
import handbooks from '../src/routes/handbooks';

const SECRET_KEY = 'test-secret';

type Handler = (args: unknown[]) => unknown;

type D1Mock = import('@cloudflare/workers-types').D1Database & { batchSql: string[][] };

function fakeD1(handlers: Record<string, Handler>): D1Mock {
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
  } as unknown as D1Mock;
}

const USER_SQL = 'SELECT id, username, role FROM users WHERE id = ?';
const HANDBOOK_EXISTS_SQL = 'SELECT 1 FROM handbooks WHERE id=?';
const UPSERT_VOTE_SQL = 'INSERT INTO handbook_votes(user_id,handbook_id,vote) VALUES(?,?,?) ON CONFLICT(user_id,handbook_id) DO UPDATE SET vote=excluded.vote';
const UPDATE_SCORE_SQL = 'UPDATE handbooks SET score=(SELECT COALESCE(SUM(vote),0) FROM handbook_votes WHERE handbook_id=?) WHERE id=?';
const SCORE_SQL = 'SELECT score FROM handbooks WHERE id=?';

async function authenticate(): Promise<{ headers: { 'content-type': string; authorization: string } }> {
  const token = await new SignJWT({ id: 1, username: 'editor', role: 'admin' })
    .setProtectedHeader({ alg: 'HS256' })
    .sign(new TextEncoder().encode(SECRET_KEY));
  return { headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` } };
}

async function voteApp(db: D1Mock): Promise<Response> {
  const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
  app.route('/handbooks', handbooks);
  return app.request('http://example.test/handbooks/1/vote', {
    method: 'POST',
    headers: (await authenticate()).headers,
    body: JSON.stringify({ vote: 1 }),
  }, { DB: db, SECRET_KEY });
}

describe('handbook vote endpoint', () => {
  it('rejects a vote value outside -1 and 1', async () => {
    const db = fakeD1({ [USER_SQL]: () => ({ id: 1, username: 'editor', role: 'admin' }) });
    const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
    app.route('/handbooks', handbooks);
    const response = await app.request('http://example.test/handbooks/1/vote', {
      method: 'POST',
      headers: (await authenticate()).headers,
      body: JSON.stringify({ vote: 5 }),
    }, { DB: db, SECRET_KEY });
    expect(response.status).toBe(400);
    expect((await response.json() as { error: string }).error).toBe('VOTE_INVALID_VALUE');
  });

  it('rejects a vote against a missing handbook', async () => {
    const db = fakeD1({
      [USER_SQL]: () => ({ id: 1, username: 'editor', role: 'admin' }),
      [HANDBOOK_EXISTS_SQL]: () => null,
    });
    const response = await voteApp(db);
    expect(response.status).toBe(404);
    const body = await response.json() as { success: boolean };
    expect(body.success).toBe(false);
  });

  it('returns the recomputed score after upserting a vote', async () => {
    const db = fakeD1({
      [USER_SQL]: () => ({ id: 1, username: 'editor', role: 'admin' }),
      [HANDBOOK_EXISTS_SQL]: () => ({ ok: 1 }),
      [UPSERT_VOTE_SQL]: () => ({ success: true }),
      [UPDATE_SCORE_SQL]: () => ({ success: true }),
      [SCORE_SQL]: () => ({ score: 3 }),
    });
    const response = await voteApp(db);
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { score: number; user_vote: number } };
    expect(body.data).toEqual({ score: 3, user_vote: 1 });
  });

  it('updates the handbook score in the same batch as the vote', async () => {
    const db = fakeD1({
      [USER_SQL]: () => ({ id: 1, username: 'editor', role: 'admin' }),
      [HANDBOOK_EXISTS_SQL]: () => ({ ok: 1 }),
      [UPSERT_VOTE_SQL]: () => ({ success: true }),
      [UPDATE_SCORE_SQL]: () => ({ success: true }),
      [SCORE_SQL]: () => ({ score: 3 }),
    });
    const response = await voteApp(db);
    expect(response.status).toBe(200);
    expect(db.batchSql).toEqual([[
      expect.stringContaining('INSERT INTO handbook_votes'),
      expect.stringContaining('UPDATE handbooks SET score'),
    ]]);
    const body = await response.json() as { data: { score: number; user_vote: number } };
    expect(body.data).toEqual({ score: 3, user_vote: 1 });
  });
});