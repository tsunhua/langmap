import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import feed from '../src/routes/feed';

type FeedRow = {
  id: number;
  score: number;
  relation_mask: number;
  a_id: number;
  a_text: string;
  a_lang: string;
  b_id: number;
  b_text: string;
  b_lang: string;
};

const SIMPLE_ROW: FeedRow = {
  id: 101, score: 2, relation_mask: 1,
  a_id: 201, a_text: '食', a_lang: 'nan',
  b_id: 202, b_text: 'eat', b_lang: 'eng',
};

function fakeDb(capturedSql: string[] = []) {
  return {
    prepare(sql: string) {
      capturedSql.push(sql);
      return {
        bind(..._args: unknown[]) {
          return {
            async all() {
              return { results: [SIMPLE_ROW] };
            },
          };
        },
      };
    },
  } as unknown as D1Database;
}

describe('feed API', () => {
  it('returns stable hot and new rows with integer ids serialized to strings', async () => {
    const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
    app.route('/feed', feed);
    for (const path of ['/feed/hot?limit=20', '/feed/new?limit=20']) {
      const response = await app.request(`http://example.test${path}`, undefined, { DB: fakeDb(), SECRET_KEY: 'test' });
      expect(response.status).toBe(200);
      const body = await response.json() as { success: boolean; data: Array<{ id: string; a_id: string; b_id: string }> };
      expect(body.success).toBe(true);
      expect(body.data[0]).toMatchObject({ id: '101', a_id: '201', b_id: '202' });
    }
  });

  it('orders hot rows by score and new rows by recency, both limited', async () => {
    const capturedSql: string[] = [];
    const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
    app.route('/feed', feed);

    await app.request('http://example.test/feed/hot?limit=20', undefined, { DB: fakeDb(capturedSql), SECRET_KEY: 'test' });
    await app.request('http://example.test/feed/new?limit=20', undefined, { DB: fakeDb(capturedSql), SECRET_KEY: 'test' });

    const hot = capturedSql.find((sql) => sql.includes('ORDER BY e.score DESC,e.id ASC'));
    const fresh = capturedSql.find((sql) => sql.includes('ORDER BY e.id DESC'));
    expect(hot).toBeDefined();
    expect(fresh).toBeDefined();
    expect(hot).toContain('LIMIT ?');
    expect(fresh).toContain('LIMIT ?');
    expect(capturedSql).toHaveLength(2);
  });

  it('attaches language codes as language names to hot and new rows', async () => {
    const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
    app.route('/feed', feed);

    const hot = await app.request('http://example.test/feed/hot?limit=20', undefined, { DB: fakeDb(), SECRET_KEY: 'test' });
    const hotBody = await hot.json() as { data: Array<{ a_language_name: string; b_language_name: string }> };
    expect(hotBody.data[0]).toMatchObject({ a_language_name: 'nan', b_language_name: 'eng' });

    const fresh = await app.request('http://example.test/feed/new?limit=20', undefined, { DB: fakeDb(), SECRET_KEY: 'test' });
    const newBody = await fresh.json() as { data: Array<{ a_language_name: string; b_language_name: string }> };
    expect(newBody.data[0]).toMatchObject({ a_language_name: 'nan', b_language_name: 'eng' });
  });
});