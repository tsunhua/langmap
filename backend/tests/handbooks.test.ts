import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import handbooks from '../src/routes/handbooks';

function fakeDb() {
  return {
    prepare(sql: string) {
      return {
        bind(..._args: unknown[]) {
          return {
            async first() {
              if (sql.includes('COUNT(*)')) return { total: 1 };
              if (sql.includes('FROM handbooks h JOIN users')) return { id: '01HANDBOOK', title: 'Starter', visibility: 'public', score: 0, user_id: 1, author_username: 'editor' };
              return null;
            },
            async all() {
              if (sql.includes('FROM handbook_sections')) return { results: [{ id: '01SECTION', handbook_id: '01HANDBOOK', title: 'One', position: 0 }] };
              if (sql.includes('FROM handbook_section_items')) return { results: [{ section_id: '01SECTION', expression_id: 'nan:hash', id: 'nan:hash', text: '食', lang_code: 'nan', language_name: 'Southern Min', position: 0 }] };
              return { results: [{ id: '01HANDBOOK', title: 'Starter', section_count: 1, expression_count: 1 }] };
            },
          };
        },
      };
    },
  } as unknown as D1Database;
}

describe('handbooks API', () => {
  it('reads a handbook containing TEXT expression ids', async () => {
    const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
    app.route('/handbooks', handbooks);
    const response = await app.request('http://example.test/handbooks/01HANDBOOK', undefined, { DB: fakeDb(), SECRET_KEY: 'test-secret' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { sections: Array<{ items: Array<{ id: string; lang_code: string }> }> } };
    expect(body.data.sections[0].items[0]).toMatchObject({ id: 'nan:hash', lang_code: 'nan' });
  });
});
