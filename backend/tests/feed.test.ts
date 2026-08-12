import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import feed from '../src/routes/feed';

function fakeDb() {
  return {
    prepare(sql: string) {
      return {
        bind(..._args: unknown[]) {
          return {
            async all() {
              if (sql.includes("'mapping' AS type")) {
                return { results: [{ id: 'edge-1', type: 'mapping', left_text: '食', left_lang: 'nan', right_text: 'eat', right_lang: 'eng', created_at: '2026-08-12' }] };
              }
              return { results: [{ edge_id: 'edge-1', id: 'edge-1', a_text: '食', a_lang: 'nan', b_text: 'eat', b_lang: 'eng', score: 2 }] };
            },
          };
        },
      };
    },
  } as unknown as D1Database;
}

describe('feed API', () => {
  it('returns stable hot and new feed rows using text expression ids', async () => {
    const app = new Hono<{ Bindings: { DB: D1Database } }>();
    app.route('/feed', feed);
    for (const path of ['/feed/hot?limit=20', '/feed/new?limit=20']) {
      const response = await app.request(`http://example.test${path}`, undefined, { DB: fakeDb() });
      expect(response.status).toBe(200);
      const body = await response.json() as { success: boolean; data: Array<{ id: string }> };
      expect(body.success).toBe(true);
      expect(body.data[0].id).toBe('edge-1');
    }
  });
});
