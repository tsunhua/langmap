import { describe, expect, it } from 'vitest';
import { LocalizationError, computeCoverage, recalculateForExpressions, resolveBundle } from '../src/services/localizationDomain';

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

describe('computeCoverage', () => {
  it('returns 0 coverage when there are no active messages', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ?': () => ({ total: 0 }),
      'SELECT lang_code FROM language_locales WHERE code = ?': () => ({ lang_code: 'cmn' }),
    });
    const result = await computeCoverage(db, 'langmap-web', 'cmn-Hant-TW');
    expect(result.coverage).toBe(0);
    expect(result.total).toBe(0);
  });

  it('computes coverage from translated keys with valid candidates', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ?': () => ({ total: 3 }),
      'SELECT lang_code FROM language_locales WHERE code = ?': () => ({ lang_code: 'cmn' }),
      'SELECT m.message_key, m.placeholders_json, m.source_text, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at FROM ui_messages m JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND t.lang_code = ? AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?) ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC':
        () => ({
          results: [
            { message_key: 'a.key', placeholders_json: '[]', source_text: 'Hello', target_id: 'cmn:t1', target_text: '你好', edge_id: 'e1', score: 0, created_at: '2026-01-01' },
            { message_key: 'b.key', placeholders_json: '[]', source_text: 'World', target_id: 'cmn:t2', target_text: '世界', edge_id: 'e2', score: 0, created_at: '2026-01-01' },
          ],
        }),
    });
    const result = await computeCoverage(db, 'langmap-web', 'cmn-Hant-TW');
    expect(result.total).toBe(3);
    expect(result.translated).toBe(2);
    expect(result.coverage).toBeCloseTo(2 / 3);
  });
});

describe('resolveBundle', () => {
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

describe('recalculateForExpressions', () => {
  it('does nothing when the expression list is empty', async () => {
    let prepared = 0;
    const db = {
      prepare(_sql: string) {
        prepared++;
        return {
          bind() {
            return {
              async first() { return null; },
              async run() { return { success: true }; },
              async all() { return { results: [] }; },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    await recalculateForExpressions(db, 'langmap-web', []);
    expect(prepared).toBe(0);
  });
});
