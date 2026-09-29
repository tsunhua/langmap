import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Client } from 'pg';
import { readFileSync } from 'node:fs';
import type { Database, PreparedStatement } from '../src/db/database';
import { transformSql } from '../src/db/pgDatabase';
import { getHandbookTranslations } from '../src/services/handbookTranslations';

const connectionString = process.env.TRANSLATION_TEST_DATABASE_URL;

describe.skipIf(!connectionString)('handbook translations on PostgreSQL', () => {
  const client = new Client({ connectionString });
  const calls: Array<{ sql: string; params: unknown[] }> = [];
  let db: Database;

  beforeAll(async () => {
    await client.connect();
    await client.query('BEGIN');
    await client.query('CREATE SCHEMA handbook_translation_fixture');
    await client.query('SET LOCAL search_path = handbook_translation_fixture, public');
    await client.query(readFileSync(new URL('../postgres/schema.sql', import.meta.url), 'utf8'));
    await client.query(`
      INSERT INTO users(id, username, email, password_hash) VALUES (1, 'fixture', 'fixture@example.test', 'unused');
      INSERT INTO languages(id, code, name_en) VALUES
        (1, 'eng', 'English'), (2, 'cmn', 'Mandarin Chinese');
      INSERT INTO scripts(code, name_en, direction) VALUES
        ('Latn', 'Latin', 'ltr'), ('Hant', 'Traditional Chinese', 'ltr'), ('Hans', 'Simplified Chinese', 'ltr');
      INSERT INTO regions(code, name_en) VALUES
        ('US', 'United States'), ('TW', 'Taiwan'), ('CN', 'China');
      INSERT INTO language_locales(id, code, language_id, script_code, region_code, place_path, name, name_en) VALUES
        (1, 'eng-Latn-US', 1, 'Latn', 'US', '', 'English', 'English'),
        (2, 'cmn-Hant-TW', 2, 'Hant', 'TW', '', 'Traditional Chinese', 'Traditional Chinese'),
        (3, 'cmn-Hans-CN', 2, 'Hans', 'CN', '', 'Simplified Chinese', 'Simplified Chinese');
    `);

    db = {
      prepare(sql: string): PreparedStatement {
        let params: unknown[] = [];
        const query = async () => {
          const { pgSql } = transformSql(sql);
          calls.push({ sql, params: [...params] });
          return client.query(pgSql, params);
        };
        const statement: PreparedStatement = {
          bind(...values) { params = values; return statement; },
          async all<T>() { return { results: (await query()).rows as T[], success: true, meta: {} }; },
          async first<T>() { return ((await query()).rows[0] as T) ?? null; },
          async run() {
            const result = await query();
            return { success: true, meta: { last_row_id: 0, changes: result.rowCount ?? 0 } };
          },
          _sql: sql,
          _params: () => params,
        };
        return statement;
      },
      async batch() { throw new Error('Unexpected batch mutation'); },
    };
  });

  afterAll(async () => {
    await client.query('ROLLBACK');
    await client.end();
  });

  async function createHandbook(id: number, sections: Array<{ id: number; position: number }>) {
    await client.query(
      "INSERT INTO handbooks(id, user_id, title, visibility, status) VALUES ($1, 1, $2, 'public', 'published')",
      [id, `Fixture ${id}`],
    );
    for (const section of sections) {
      await client.query('INSERT INTO handbook_sections(id, handbook_id, position) VALUES ($1, $2, $3)', [section.id, id, section.position]);
    }
  }

  async function addExpression(id: number, languageId: number, text: string, localeId: number) {
    await client.query('INSERT INTO expressions(id, language_id, text) VALUES ($1, $2, $3)', [id, languageId, text]);
    await client.query('INSERT INTO expression_locale_links(expression_id, locale_id) VALUES ($1, $2)', [id, localeId]);
  }

  async function addItem(sectionId: number, position: number, localeId: number, text: string) {
    await client.query(
      'INSERT INTO handbook_section_items(section_id, position, language_locale_id, text) VALUES ($1, $2, $3, $4)',
      [sectionId, position, localeId, text],
    );
  }

  async function addEdge(id: number, first: number, second: number, score: number) {
    const [expressionA, expressionB] = first < second ? [first, second] : [second, first];
    await client.query(
      'INSERT INTO expression_edges(id, expression_a_id, expression_b_id, score) VALUES ($1, $2, $3, $4)',
      [id, expressionA, expressionB, score],
    );
  }

  it('uses each item language, exact target locale, and both edge directions', async () => {
    await createHandbook(100, [{ id: 1000, position: 1 }]);
    for (const row of [
      [99, 1, 'Hello! ', 1], [101, 2, '你好', 2], [102, 1, 'hello', 1],
      [201, 2, '您好', 2], [202, 2, '你好嗎', 3], [203, 2, '妳好', 2],
      [205, 2, '您安', 2], [206, 1, 'hello there', 1], [207, 1, 'Hi!', 1],
    ] as const) {
      await addExpression(...row);
    }
    await addItem(1000, 1, 2, '你好');
    await addItem(1000, 2, 1, 'hello');
    await addEdge(100, 99, 101, 0);
    await addEdge(101, 101, 203, 50);
    await addEdge(102, 102, 201, 5);
    await addEdge(103, 102, 202, 100);
    await addEdge(104, 102, 205, -1);
    await addEdge(105, 102, 206, 200);
    await addEdge(106, 101, 207, 1);

    const traditionalChinese = await getHandbookTranslations(db, 100, 'cmn-Hant-TW');
    expect(traditionalChinese.items.map((item) => [item.source_expression_id, item.translations.map(({ id }) => id)])).toEqual([
      [102, [201]],
    ]);

    const english = await getHandbookTranslations(db, 100, 'eng-Latn-US');
    expect(english.items.map((item) => [item.source_expression_id, item.translations.map(({ id }) => id)])).toEqual([
      [101, [207, 99]],
    ]);
  });

  it('keeps the earliest real source position as one ordered tuple', async () => {
    await createHandbook(101, [{ id: 1100, position: 1 }, { id: 1101, position: 2 }]);
    await addExpression(111, 2, 'second item', 2);
    await addExpression(112, 2, 'first occurrence', 2);
    await addExpression(211, 1, 'Second translation', 1);
    await addExpression(212, 1, 'First translation', 1);
    await addItem(1100, 4, 2, 'second item');
    await addItem(1100, 8, 2, 'first occurrence');
    await addItem(1101, 0, 2, 'first occurrence');
    await addEdge(111, 111, 211, 1);
    await addEdge(112, 112, 212, 1);

    const result = await getHandbookTranslations(db, 101, 'eng-Latn-US');

    expect(result.items.map(({ source_expression_id }) => source_expression_id)).toEqual([111, 112]);
  });

  it('reads only unique returned targets after the translation cap', async () => {
    await createHandbook(102, [{ id: 1200, position: 1 }]);
    await addExpression(120, 2, 'source', 2);
    await addExpression(121, 2, 'another source', 2);
    for (const [id, text] of [[220, 'Hidden'], [221, 'Third'], [222, 'Second'], [223, 'First']] as const) {
      await addExpression(id, 1, text, 1);
      await client.query(
        'INSERT INTO expression_readings(expression_id, locale_id, scheme, value) VALUES ($1, 1, $2, $3)',
        [id, 'scheme', `reading-${id}`],
      );
    }
    await addItem(1200, 1, 2, 'source');
    await addItem(1200, 2, 2, 'another source');
    await addEdge(120, 120, 220, 1);
    await addEdge(121, 120, 221, 2);
    await addEdge(122, 120, 222, 3);
    await addEdge(123, 120, 223, 4);
    await addEdge(124, 121, 223, 1);
    const start = calls.length;

    const result = await getHandbookTranslations(db, 102, 'eng-Latn-US');

    expect(result.items[0].translations.map(({ id }) => id)).toEqual([223, 222, 221]);
    expect(result.items[0]).toMatchObject({ total_translation_count: 4, hidden_translation_count: 1 });
    const readingCalls = calls.slice(start).filter(({ sql }) => sql.includes('FROM expression_readings'));
    expect(readingCalls).toHaveLength(1);
    expect(readingCalls[0].sql).toContain('expression_id = ANY(?::bigint[])');
    expect(readingCalls[0].params).toEqual([[221, 222, 223], 1, 15000]);
  });

  it('omits the readings statement when no target edge matches', async () => {
    await createHandbook(103, [{ id: 1300, position: 1 }]);
    await addExpression(130, 2, 'unmapped source', 2);
    await addItem(1300, 1, 2, 'unmapped source');
    const start = calls.length;

    const result = await getHandbookTranslations(db, 103, 'eng-Latn-US');

    expect(result.items).toEqual([]);
    expect(calls.slice(start).some(({ sql }) => sql.includes('FROM expression_readings'))).toBe(false);
  });

  it('caps returned sources and the globally ordered reading rows', async () => {
    await createHandbook(104, [{ id: 1400, position: 1 }]);
    await client.query(`
      INSERT INTO expressions(id, language_id, text)
      SELECT 300000 + n, 2, 'source-' || n FROM generate_series(1, 5001) AS n;
      INSERT INTO expression_locale_links(expression_id, locale_id)
      SELECT 300000 + n, 2 FROM generate_series(1, 5001) AS n;
      INSERT INTO expressions(id, language_id, text)
      SELECT 400000 + n, 1, 'target-' || n FROM generate_series(1, 5001) AS n;
      INSERT INTO expression_locale_links(expression_id, locale_id)
      SELECT 400000 + n, 1 FROM generate_series(1, 5001) AS n;
      INSERT INTO handbook_section_items(section_id, position, language_locale_id, text)
      SELECT 1400, n, 2, 'source-' || n FROM generate_series(1, 5001) AS n;
      INSERT INTO expression_edges(id, expression_a_id, expression_b_id, score)
      SELECT 500000 + n, 300000 + n, 400000 + n, 1 FROM generate_series(1, 5001) AS n;
      INSERT INTO expression_readings(expression_id, locale_id, scheme, value)
      SELECT 400000 + n, 1, 'scheme-' || r, 'reading-' || n || '-' || r
      FROM generate_series(1, 5001) AS n CROSS JOIN generate_series(1, 4) AS r;
    `);
    const start = calls.length;

    const result = await getHandbookTranslations(db, 104, 'eng-Latn-US');

    expect(result.items).toHaveLength(5000);
    expect(result.items[0].source_expression_id).toBe(300001);
    expect(result.items.at(-1)?.source_expression_id).toBe(305000);
    const targetIds = result.items.flatMap((item) => item.translations.map(({ id }) => id));
    expect(targetIds).toEqual(Array.from({ length: 5000 }, (_, index) => index + 400001));
    expect(result.items.reduce((sum, item) => sum + item.translations.reduce((n, translation) => n + translation.readings.length, 0), 0)).toBe(15000);
    const readingCalls = calls.slice(start).filter(({ sql }) => sql.includes('FROM expression_readings'));
    expect(readingCalls).toHaveLength(1);
    expect(readingCalls[0].params).toEqual([targetIds, 1, 15000]);
  });
});
