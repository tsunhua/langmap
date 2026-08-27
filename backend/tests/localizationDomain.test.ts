import { describe, expect, it } from 'vitest';
import { CANDIDATE_SQL, resolveBundle } from '../src/services/localizationDomain';

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

describe('resolveBundle', () => {
  it('uses an active primary locale candidate when its placeholders match', async () => {
    const db = fakeD1({
      'SELECT message_key, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? ORDER BY message_key ASC':
        () => ({ results: [{ message_key: 'greeting', source_text: 'Hello {name}', placeholders_json: '["name"]' }] }),
      'SELECT status FROM ui_locales WHERE project_id = ? AND locale_id = (SELECT id FROM language_locales WHERE code = ?)':
        () => ({ status: 'active' }),
      [CANDIDATE_SQL]: () => ({ results: [{ message_key: 'greeting', placeholders_json: '["name"]', target_id: 7, target_text: '你好 {name}', score: 1 }] }),
    });
    await expect(resolveBundle(db, 'langmap-web', 'cmn-Hant-TW')).resolves.toEqual([
      { key: 'greeting', text: '你好 {name}', resolved_from: 'primary' },
    ]);
  });

  it('falls back to English source when no active locale matches', async () => {
    const db = fakeD1({
      'SELECT message_key, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? ORDER BY message_key ASC':
        () => ({
          results: [
            { message_key: 'greeting', source_text: 'Hello', placeholders_json: '[]' },
          ],
        }),
      'SELECT status FROM ui_locales WHERE project_id = ? AND language_locale_code = ?': () => null,
    });
    const bundle = await resolveBundle(db, 'langmap-web');
    expect(bundle[0].key).toBe('greeting');
    expect(bundle[0].text).toBe('Hello');
    expect(bundle[0].resolved_from).toBe('source');
  });
});
