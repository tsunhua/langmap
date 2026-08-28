import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import localization from '../src/routes/localization';
import { CANDIDATE_SQL } from '../src/services/localizationDomain';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
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
  return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
}

const ACTIVE_MESSAGES_SQL = 'SELECT message_key, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? ORDER BY message_key ASC';
const LOCALE_STATUS_SQL = 'SELECT status FROM ui_locales WHERE project_id = ? AND locale_id = (SELECT id FROM language_locales WHERE code = ?)';

type BundleEntry = { key: string; text: string; resolved_from: 'primary' | 'secondary' | 'source' };

function fetchMessages(db: import('@cloudflare/workers-types').D1Database, query: string): Promise<Response> {
  const app = new Hono<{ Bindings: { DB: import('@cloudflare/workers-types').D1Database; SECRET_KEY: string } }>();
  app.route('/localization', localization);
  return app.request(`http://example.test/localization/projects/langmap-web/messages${query}`, undefined, { DB: db, SECRET_KEY: 'test-secret' });
}

describe('localization messages endpoint (workbench)', () => {
  it('resolves a UI message from an active primary locale candidate', async () => {
    const db = fakeD1({
      [ACTIVE_MESSAGES_SQL]: () => ({ results: [{ message_key: 'greeting', source_text: 'Hello', placeholders_json: '[]' }] }),
      [LOCALE_STATUS_SQL]: () => ({ status: 'active' }),
      [CANDIDATE_SQL]: () => ({ results: [{ message_key: 'greeting', placeholders_json: '[]', target_id: 7, target_text: '你好', score: 1 }] }),
    });
    const response = await fetchMessages(db, '?primary=cmn-Hant-TW');
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { messages: BundleEntry[] } };
    expect(body.data.messages).toEqual([{ key: 'greeting', text: '你好', resolved_from: 'primary' }]);
  });

  it('falls back to the source text when the primary locale is not active', async () => {
    const db = fakeD1({
      [ACTIVE_MESSAGES_SQL]: () => ({ results: [{ message_key: 'greeting', source_text: 'Hello', placeholders_json: '[]' }] }),
      [LOCALE_STATUS_SQL]: () => ({ status: 'draft' }),
    });
    const response = await fetchMessages(db, '?primary=cmn-Hant-TW');
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { messages: BundleEntry[] } };
    expect(body.data.messages).toEqual([{ key: 'greeting', text: 'Hello', resolved_from: 'source' }]);
  });

  it('rejects an invalid locale code with INVALID_LANGUAGE_LOCALE_CODE', async () => {
    const response = await fetchMessages(fakeD1({}), '?primary=not-a-locale');
    expect(response.status).toBe(400);
    expect((await response.json() as { error: string }).error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });
});