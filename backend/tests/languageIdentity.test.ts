import { describe, expect, it } from 'vitest';
import { parseReferenceQuery, queryReferenceTable, escapeLike } from '../src/services/languageIdentity';

describe('parseReferenceQuery', () => {
  it('clamps limit into [1,50] and offsets to >=0', () => {
    expect(parseReferenceQuery({ limit: '999' }).limit).toBe(50);
    expect(parseReferenceQuery({ limit: '0' }).limit).toBe(1);
    expect(parseReferenceQuery({ limit: 'abc' }).limit).toBe(20);
    expect(parseReferenceQuery({ offset: '-5' }).offset).toBe(0);
  });

  it('truncates q to 80 chars', () => {
    expect(parseReferenceQuery({ q: 'x'.repeat(200) }).q).toHaveLength(80);
    expect(parseReferenceQuery({}).q).toBe('');
  });
});

describe('escapeLike', () => {
  it('escapes backslash, percent and underscore', () => {
    expect(escapeLike('a\\b%c_d')).toBe('a\\\\b\\%c\\_d');
  });
});

describe('queryReferenceTable', () => {
  function fakeD1(rows: Record<string, unknown>[], total: number) {
    const prepare = (sql: string) => ({
      bind(..._args: unknown[]) {
        return {
          async first<T>() {
            return { total } as unknown as T;
          },
          async all<T>() {
            return { results: rows as unknown as T[] };
          },
        };
      },
    });
    return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
  }

  it('returns items and total from D1', async () => {
    const db = fakeD1([{ code: 'eng', name_en: 'English' }], 1);
    const result = await queryReferenceTable(db, 'languages', { q: '', limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items[0]).toEqual({ code: 'eng', name_en: 'English' });
  });
});
