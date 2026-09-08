import { describe, expect, it } from 'vitest';
import { getHandbookTranslations, HandbookTranslationError } from '../src/services/handbookTranslations';

type Row = Record<string, unknown>;

function fakeD1(options: { visibility?: string; userId?: number } = {}) {
  const sql: string[] = [];
  const bindCalls: Array<{ statement: string; args: unknown[] }> = [];
  const db = {
    prepare(statement: string) {
      sql.push(statement);
      return {
        bind(...args: unknown[]) {
          bindCalls.push({ statement, args });
          return {
            async first<T>() {
              if (statement === 'SELECT visibility,user_id FROM handbooks WHERE id=?') {
                return { visibility: options.visibility ?? 'public', user_id: options.userId ?? 1 } as T;
              }
              if (statement === 'SELECT code FROM language_locales WHERE code=?') return { code: 'jpn-Jpan-JP' } as T;
              return null as T;
            },
            async all<T>() {
              if (statement.includes('SELECT * FROM (') && statement.includes('UNION ALL')) {
                return {
                  results: [
                    { source_expression_id: 10, target_expression_id: 20, target_text: 'トイレ', target_lang_code: 'jpn', target_language_name: 'Japanese', target_locale_code: 'jpn-Jpan-JP', section_position: 1, item_position: 1 },
                    { source_expression_id: 10, target_expression_id: 20, target_text: 'トイレ', target_lang_code: 'jpn', target_language_name: 'Japanese', target_locale_code: 'jpn-Jpan-JP', section_position: 1, item_position: 1 },
                    { source_expression_id: 11, target_expression_id: 21, target_text: '駅', target_lang_code: 'jpn', target_language_name: 'Japanese', target_locale_code: 'jpn-Jpan-JP', section_position: 1, item_position: 2 },
                  ],
                } as { results: T[] };
              }
              return { results: [{ expression_id: 20, scheme: 'hepburn', value: 'toire' }] } as { results: T[] };
            },
          };
        },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
  return { db, sql, bindCalls };
}

describe('handbook translations service', () => {
  it('returns deduplicated direct translations and locale readings in handbook order', async () => {
    const { db, sql, bindCalls } = fakeD1();

    const result = await getHandbookTranslations(db, 1, 'jpn-Jpan-JP');

    expect(result).toEqual({
      target_locale: 'jpn-Jpan-JP',
      items: [
        {
          source_expression_id: 10,
          translations: [{
            id: 20,
            text: 'トイレ',
            lang_code: 'jpn',
            language_locale_code: 'jpn-Jpan-JP',
            language_name: 'Japanese',
            readings: [{ scheme: 'hepburn', value: 'toire' }],
          }],
        },
        {
          source_expression_id: 11,
          translations: [{
            id: 21,
            text: '駅',
            lang_code: 'jpn',
            language_locale_code: 'jpn-Jpan-JP',
            language_name: 'Japanese',
            readings: [],
          }],
        },
      ],
    });
    const edgeQuery = sql.find((statement) => statement.includes('SELECT * FROM (')) ?? '';
    expect(edgeQuery).toContain('UNION ALL');
    expect(edgeQuery).not.toMatch(/expression_a_id\s*=.*\sOR\s+expression_b_id\s*=/i);
    expect(sql.filter((statement) => statement.includes('target_expressions'))).toHaveLength(1);
    expect(bindCalls.find(({ statement }) => statement === edgeQuery)?.args).toHaveLength(4);
    expect(bindCalls.find(({ statement }) => statement.includes('target_expressions'))?.args).toHaveLength(5);
  });

  it('rejects an empty locale before issuing database queries', async () => {
    const { db, sql } = fakeD1();

    await expect(getHandbookTranslations(db, 1, ' ')).rejects.toMatchObject<HandbookTranslationError>({ code: 'INVALID_TARGET_LOCALE' });
    expect(sql).toHaveLength(0);
  });

  it('rejects a locale absent from the registry', async () => {
    const { db } = fakeD1();
    const originalPrepare = db.prepare.bind(db);
    db.prepare = ((statement: string) => {
      const prepared = originalPrepare(statement);
      if (statement === 'SELECT code FROM language_locales WHERE code=?') {
        return {
          ...prepared,
          bind(..._args: unknown[]) {
            return { ...prepared.bind(..._args), first: async <T>() => null as T };
          },
        };
      }
      return prepared;
    }) as typeof db.prepare;

    await expect(getHandbookTranslations(db, 1, 'zzz-Latn-ZZ')).rejects.toMatchObject<HandbookTranslationError>({ code: 'INVALID_TARGET_LOCALE' });
  });

  it('keeps private handbooks private while allowing the owner to read them', async () => {
    const { db: privateDb } = fakeD1({ visibility: 'private', userId: 7 });
    await expect(getHandbookTranslations(privateDb, 1, 'jpn-Jpan-JP')).rejects.toMatchObject<HandbookTranslationError>({ code: 'HANDBOOK_PRIVATE' });

    const { db: ownerDb } = fakeD1({ visibility: 'private', userId: 7 });
    const result = await getHandbookTranslations(ownerDb, 1, 'jpn-Jpan-JP', { viewerId: 7 });
    expect(result.target_locale).toBe('jpn-Jpan-JP');
  });
});
