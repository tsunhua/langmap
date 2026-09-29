import type { Database } from '../src/db/database';
import { describe, expect, it } from 'vitest';
import { getHandbookTranslations, HandbookTranslationError } from '../src/services/handbookTranslations';

type Row = Record<string, unknown>;

function fakeDatabase(options: {
  visibility?: string;
  userId?: number;
  edgeRows?: Row[];
  readingRows?: Row[];
} = {}) {
  const sql: string[] = [];
  const bindCalls: Array<{ statement: string; args: unknown[] }> = [];
  const defaultEdgeRows: Row[] = [
    { source_expression_id: 10, target_expression_id: 20, target_text: 'トイレ', target_lang_code: 'jpn', target_language_name: 'Japanese', target_locale_code: 'jpn-Jpan-JP', edge_score: 1, translation_rank: 1, translation_count: 1, section_position: 1, item_position: 1 },
    { source_expression_id: 10, target_expression_id: 20, target_text: 'トイレ', target_lang_code: 'jpn', target_language_name: 'Japanese', target_locale_code: 'jpn-Jpan-JP', edge_score: 1, translation_rank: 1, translation_count: 1, section_position: 1, item_position: 1 },
    { source_expression_id: 11, target_expression_id: 21, target_text: '駅', target_lang_code: 'jpn', target_language_name: 'Japanese', target_locale_code: 'jpn-Jpan-JP', edge_score: 0.5, translation_rank: 1, translation_count: 1, section_position: 1, item_position: 2 },
  ];
  const defaultReadingRows: Row[] = [{ expression_id: 20, scheme: 'hepburn', value: 'toire' }];
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
              if (statement === 'SELECT id, code FROM language_locales WHERE code=?') return { code: 'jpn-Jpan-JP', id: 5 } as T;
              return null as T;
            },
            async all<T>() {
              if (statement.includes('SELECT *') && statement.includes('FROM ranked_edges')) {
                return { results: (options.edgeRows ?? defaultEdgeRows) as T[] };
              }
              if (statement.includes('FROM expression_readings')) {
                return { results: (options.readingRows ?? defaultReadingRows) as T[] };
              }
              return { results: [] as T[] };
            },
          };
        },
      };
    },
  } as unknown as import('../src/db/database').Database;
  return { db, sql, bindCalls };
}

describe('handbook translations service', () => {
  it('returns deduplicated direct translations and locale readings in handbook order', async () => {
    const { db, sql, bindCalls } = fakeDatabase();

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
          total_translation_count: 1,
          hidden_translation_count: 0,
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
          total_translation_count: 1,
          hidden_translation_count: 0,
        },
      ],
    });
    const edgeQuery = sql.find((statement) => statement.includes('SELECT *') && statement.includes('FROM ranked_edges')) ?? '';
    expect(edgeQuery).toContain('UNION ALL');
    expect(edgeQuery).toContain('ROW_NUMBER() OVER');
    expect(edgeQuery).toContain('translation_rank <= ?');
    expect(edgeQuery).not.toMatch(/expression_a_id\s*=.*\sOR\s+expression_b_id\s*=/i);
    expect(edgeQuery).toContain('DISTINCT ON (resolved.expression_id)');
    expect(edgeQuery).toContain('source_language_id');
    expect(edgeQuery).not.toContain("source_language.code='eng'");
    expect(edgeQuery).toContain('target_language.id <> source_items.source_language_id');
    const readingQuery = sql.find((statement) => statement.includes('FROM expression_readings')) ?? '';
    expect(readingQuery).toContain('expression_id = ANY(?::bigint[])');
    expect(readingQuery).not.toContain('ranked_edges');
    expect(bindCalls.find(({ statement }) => statement === edgeQuery)?.args).toHaveLength(7);
    expect(bindCalls.find(({ statement }) => statement === readingQuery)?.args).toEqual([[20, 21], 5, 15000]);
    expect(sql).toHaveLength(4);
  });

  it('caps translations per source expression and reports hidden candidates', async () => {
    const { db } = fakeDatabase({
      edgeRows: [1, 2, 3, 4].map((id) => ({
        source_expression_id: 10,
        target_expression_id: 30 + id,
        target_text: `候選${id}`,
        target_lang_code: 'jpn',
        target_language_name: 'Japanese',
        target_locale_code: 'jpn-Jpan-JP',
        edge_score: 1 - id / 10,
        translation_rank: id,
        translation_count: 4,
        section_position: 1,
        item_position: 1,
      })),
    });

    const result = await getHandbookTranslations(db, 1, 'jpn-Jpan-JP');

    expect(result.items).toHaveLength(1);
    expect(result.items[0].translations.map((translation) => translation.id)).toEqual([31, 32, 33]);
    expect(result.items[0].total_translation_count).toBe(4);
    expect(result.items[0].hidden_translation_count).toBe(1);
  });

  it('loads readings only for the unique translations returned after the per-source cap', async () => {
    const { db, bindCalls } = fakeDatabase({
      edgeRows: [
        [10, 20, 1], [10, 21, 2], [10, 22, 3], [10, 23, 4],
        [11, 20, 1],
      ].map(([source_expression_id, target_expression_id, translation_rank]) => ({
        source_expression_id,
        target_expression_id,
        target_text: `譯詞${target_expression_id}`,
        target_lang_code: 'jpn',
        target_language_name: 'Japanese',
        target_locale_code: 'jpn-Jpan-JP',
        edge_score: 1,
        translation_rank,
        translation_count: source_expression_id === 10 ? 4 : 1,
        section_position: 1,
        item_position: source_expression_id - 9,
      })),
    });

    const result = await getHandbookTranslations(db, 1, 'jpn-Jpan-JP');

    const readingCall = bindCalls.find(({ statement }) => statement.includes('FROM expression_readings'));
    expect(readingCall?.args).toEqual([[20, 21, 22], 5, 15000]);
    expect(result.items[0].hidden_translation_count).toBe(1);
  });

  it('skips the readings query when there are no eligible translations', async () => {
    const { db, sql } = fakeDatabase({ edgeRows: [] });

    const result = await getHandbookTranslations(db, 1, 'jpn-Jpan-JP');

    expect(result.items).toEqual([]);
    expect(sql).toHaveLength(3);
    expect(sql.some((statement) => statement.includes('FROM expression_readings'))).toBe(false);
  });

  it('returns only the first 5000 sources and reads only their target IDs', async () => {
    const edgeRows = Array.from({ length: 5001 }, (_, index) => ({
      source_expression_id: index + 1,
      target_expression_id: index + 10001,
      target_text: `譯詞${index}`,
      target_lang_code: 'jpn',
      target_language_name: 'Japanese',
      target_locale_code: 'jpn-Jpan-JP',
      edge_score: 1,
      translation_rank: 1,
      translation_count: 1,
      section_position: 1,
      item_position: index + 1,
    }));
    const { db, bindCalls } = fakeDatabase({ edgeRows, readingRows: [] });

    const result = await getHandbookTranslations(db, 1, 'jpn-Jpan-JP');

    expect(result.items).toHaveLength(5000);
    expect(result.items[0].source_expression_id).toBe(1);
    expect(result.items[result.items.length - 1]?.source_expression_id).toBe(5000);
    const readingCall = bindCalls.find(({ statement }) => statement.includes('FROM expression_readings'));
    expect(readingCall?.args[0]).toHaveLength(5000);
    expect(readingCall?.args[0]).not.toContain(15001);
  });

  it('rejects an empty locale before issuing database queries', async () => {
    const { db, sql } = fakeDatabase();

    await expect(getHandbookTranslations(db, 1, ' ')).rejects.toMatchObject<HandbookTranslationError>({ code: 'INVALID_TARGET_LOCALE' });
    expect(sql).toHaveLength(0);
  });

  it('rejects a locale absent from the registry', async () => {
    const { db } = fakeDatabase();
    const originalPrepare = db.prepare.bind(db);
    db.prepare = ((statement: string) => {
      const prepared = originalPrepare(statement);
      if (statement === 'SELECT id, code FROM language_locales WHERE code=?') {
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
    const { db: privateDb } = fakeDatabase({ visibility: 'private', userId: 7 });
    await expect(getHandbookTranslations(privateDb, 1, 'jpn-Jpan-JP')).rejects.toMatchObject<HandbookTranslationError>({ code: 'HANDBOOK_PRIVATE' });

    const { db: ownerDb } = fakeDatabase({ visibility: 'private', userId: 7 });
    const result = await getHandbookTranslations(ownerDb, 1, 'jpn-Jpan-JP', { viewerId: 7 });
    expect(result.target_locale).toBe('jpn-Jpan-JP');
  });
});
