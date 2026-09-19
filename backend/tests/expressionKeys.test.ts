import { describe, expect, it } from 'vitest';
import { parseExpressionKey, resolveExpressionKey } from '../src/services/expressionKeys';
import type { ExpressionRow } from '../src/types/expression';

type Handler = () => unknown;

type D1Mock = import('@cloudflare/workers-types').D1Database & {
  sqlLog: string[];
};

function fakeD1(handlers: Record<string, Handler>): D1Mock {
  const sqlLog: string[] = [];
  const prepare = (sql: string) => {
    sqlLog.push(sql);
    const handler = handlers[sql] ?? Object.entries(handlers).find(
      ([registered]) => registered.replace(/\s+/g, ' ').trim() === sql.replace(/\s+/g, ' ').trim(),
    )?.[1];
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
  const batch = async (statements: Array<{ run(): Promise<unknown> }>) => Promise.all(statements.map((statement) => statement.run()));
  return { prepare, batch, sqlLog } as unknown as D1Mock;
}

const EXPRESSION_COLUMNS = 'e.id, e.language_id, l.code AS lang_code, e.text, e.homograph_index, e.pos_mask, e.source_id, e.created_by, e.created_at';
const RESOLVE_SQL = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text=? AND e.homograph_index=?`;

describe('parseExpressionKey', () => {
  it('parses a plain key as homograph 1', () => {
    expect(parseExpressionKey('en', 'hello')).toEqual({ lang_code: 'en', text: 'hello', homograph_index: 1 });
  });

  it('parses a trailing homograph suffix', () => {
    expect(parseExpressionKey('en', 'hello~2')).toEqual({ lang_code: 'en', text: 'hello', homograph_index: 2 });
  });

  it('takes only the last suffix so literal tildes survive', () => {
    expect(parseExpressionKey('en', 'hello~2~1')).toEqual({ lang_code: 'en', text: 'hello~2', homograph_index: 1 });
    expect(parseExpressionKey('en', 'spa~1~3')).toEqual({ lang_code: 'en', text: 'spa~1', homograph_index: 3 });
  });

  it('lowercases the language code', () => {
    expect(parseExpressionKey('EN', 'hello')?.lang_code).toBe('en');
  });

  it('rejects invalid language codes', () => {
    expect(parseExpressionKey('en-US extra', 'hello')).toBeNull();
    expect(parseExpressionKey('e:n', 'hello')).toBeNull();
    expect(parseExpressionKey('', 'hello')).toBeNull();
  });

  it('rejects a zero homograph suffix', () => {
    expect(parseExpressionKey('en', 'hello~0')).toBeNull();
  });

  it('keeps a trailing tilde without digits as text', () => {
    expect(parseExpressionKey('en', 'hello~')).toEqual({ lang_code: 'en', text: 'hello~', homograph_index: 1 });
  });
});

describe('resolveExpressionKey', () => {
  it('finds an expression by natural key', async () => {
    const row: ExpressionRow = {
      id: 7, language_id: 1, lang_code: 'en', text: 'hello', homograph_index: 2,
      pos_mask: 0, source_id: null, created_by: 1, created_at: '2026-08-12 00:00:00',
    };
    const db = fakeD1({ [RESOLVE_SQL]: () => row });
    const result = await resolveExpressionKey(db, { lang_code: 'en', text: 'hello', homograph_index: 2 });
    expect(result).toEqual(row);
  });

  it('returns null when no row matches', async () => {
    const db = fakeD1({ [RESOLVE_SQL]: () => null });
    const result = await resolveExpressionKey(db, { lang_code: 'en', text: 'missing', homograph_index: 1 });
    expect(result).toBeNull();
  });
});
