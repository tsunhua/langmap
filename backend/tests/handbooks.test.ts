import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import handbooks from '../src/routes/handbooks';

type Handler = () => unknown;

type D1Mock = import('@cloudflare/workers-types').D1Database & { sqlLog: string[] };

function fakeD1(handlers: Record<string, Handler>): D1Mock {
  const sqlLog: string[] = [];
  const prepare = (sql: string) => {
    sqlLog.push(sql);
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async run() { return handler ? await handler() : { success: true }; },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  return { prepare } as unknown as D1Mock;
}

const HANDBOOK_SQL = 'SELECT h.*,u.username AS author_username FROM handbooks h JOIN users u ON u.id=h.user_id WHERE h.id=?';
const SECTIONS_SQL = 'SELECT id,title,position,parent_section_id FROM handbook_sections WHERE handbook_id=? ORDER BY position,id';
const ITEMS_SQL = 'SELECT i.section_id,i.position,e.id,e.text,l.code AS lang_code FROM handbook_section_items i JOIN handbook_sections s ON s.id=i.section_id JOIN expressions e ON e.id=i.expression_id JOIN languages l ON l.id=e.language_id WHERE s.handbook_id=? ORDER BY i.section_id,i.position';

describe('handbooks API', () => {
  it('reads a handbook with integer ids serialized and language names from lang codes', async () => {
    const db = fakeD1({
      [HANDBOOK_SQL]: () => ({
        id: 1, user_id: 1, title: 'Starter', visibility: 'public', status: 'published',
        score: 0, created_at: '2026-08-12 00:00:00', updated_at: '2026-08-12 00:00:00',
        author_username: 'editor',
      }),
      [SECTIONS_SQL]: () => ({ results: [{ id: 1, title: 'One', position: 0, parent_section_id: null }] }),
      [ITEMS_SQL]: () => ({ results: [{ section_id: 1, position: 0, id: 101, text: '食', lang_code: 'nan' }] }),
    });
    const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
    app.route('/handbooks', handbooks);
    const response = await app.request('http://example.test/handbooks/1', undefined, { DB: db, SECRET_KEY: 'test-secret' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { id: string; sections: Array<{ id: string; parent_section_id: null; items: Array<{ id: string; section_id: string; lang_code: string; language_name: string }> }> } };
    expect(body.data.id).toBe('1');
    expect(body.data.sections[0].items[0]).toMatchObject({ id: '101', section_id: '1', lang_code: 'nan', language_name: 'nan' });
  });

  it('rejects a non-canonical id with INVALID_HANDBOOK_ID and a missing handbook with 404', async () => {
    const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string } }>();
    app.route('/handbooks', handbooks);

    const bad = await app.request('http://example.test/handbooks/01HANDBOOK', undefined, { DB: fakeD1({}), SECRET_KEY: 'test-secret' });
    expect(bad.status).toBe(400);
    expect((await bad.json() as { error: string }).error).toBe('INVALID_HANDBOOK_ID');

    const missing = await app.request('http://example.test/handbooks/999', undefined, { DB: fakeD1({ [HANDBOOK_SQL]: () => null }), SECRET_KEY: 'test-secret' });
    expect(missing.status).toBe(404);
  });
});