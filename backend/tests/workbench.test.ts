import { describe, expect, it } from 'vitest';
import { loadWorkbenchMessages } from '../src/services/workbench';

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

const COUNT_SQL = 'SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ? AND (? = \'\' OR message_key LIKE ? ESCAPE \'\\\' OR source_text LIKE ? ESCAPE \'\\\')';
const PAGE_SQL = 'SELECT message_key, source_expression_id, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? AND (? = \'\' OR message_key LIKE ? ESCAPE \'\\\' OR source_text LIKE ? ESCAPE \'\\\') ORDER BY message_key ASC LIMIT ? OFFSET ?';
const LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';
const CANDIDATES_SQL = 'SELECT m.message_key, m.placeholders_json, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at FROM ui_messages m JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END WHERE m.project_id = ? AND m.status = ? AND m.message_key IN (SELECT value FROM json_each(?)) AND t.lang_code = ? AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?) ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC LIMIT 500';

describe('loadWorkbenchMessages', () => {
  it('returns messages with empty candidates when the locale has no language row', async () => {
    const db = fakeD1({
      [COUNT_SQL]: () => ({ total: 1 }),
      [PAGE_SQL]: () => ({ results: [{ message_key: 'common.cancel', source_expression_id: 'eng:x1', source_text: 'Cancel', placeholders_json: '[]' }] }),
      [LANG_SQL]: () => null,
    });
    const result = await loadWorkbenchMessages(db, 'langmap-web', 'zzz-Zzzz-ZZ', { limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items[0].key).toBe('common.cancel');
    expect(result.items[0].candidates).toEqual([]);
  });

  it('attaches ordered candidates and flags placeholder mismatches', async () => {
    const db = fakeD1({
      [COUNT_SQL]: () => ({ total: 2 }),
      [PAGE_SQL]: () => ({
        results: [
          { message_key: 'a.key', source_expression_id: 'eng:a', source_text: 'Hello {name}', placeholders_json: '["name"]' },
          { message_key: 'b.key', source_expression_id: 'eng:b', source_text: 'World', placeholders_json: '[]' },
        ],
      }),
      [LANG_SQL]: () => ({ lang_code: 'cmn' }),
      [CANDIDATES_SQL]: () => ({
        results: [
          { message_key: 'a.key', placeholders_json: '["name"]', target_id: 'cmn:a1', target_text: '你好 {name}', edge_id: 'e1', score: 3, created_at: '2026-01-01' },
          { message_key: 'a.key', placeholders_json: '["name"]', target_id: 'cmn:a2', target_text: '哈囉', edge_id: 'e2', score: 1, created_at: '2026-01-02' },
        ],
      }),
    });
    const result = await loadWorkbenchMessages(db, 'langmap-web', 'cmn-Hant-TW', { limit: 20, offset: 0 });
    expect(result.items[0].candidates.map((candidate) => candidate.edge_id)).toEqual(['e1', 'e2']);
    expect(result.items[0].candidates[0].placeholders_ok).toBe(true);
    expect(result.items[0].candidates[1].placeholders_ok).toBe(false);
    expect(result.items[0].placeholders).toEqual(['name']);
    expect(result.items[1].candidates).toEqual([]);
  });

  it('does not query candidates when the page is empty', async () => {
    const seen: string[] = [];
    const db = {
      prepare(sql: string) {
        seen.push(sql);
        return {
          bind() {
            return {
              async first() { return { total: 0 }; },
              async run() { return { success: true }; },
              async all() { return { results: [] }; },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    const result = await loadWorkbenchMessages(db, 'langmap-web', 'cmn-Hant-TW', { limit: 20, offset: 0 });
    expect(result.items).toEqual([]);
    expect(seen.some((sql) => sql.includes('json_each'))).toBe(false);
  });
});
