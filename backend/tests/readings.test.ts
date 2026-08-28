import { describe, expect, it } from 'vitest';
import { createReading, validateReadingScheme } from '../src/services/readings';
import type { ReadingRow } from '../src/types/expression';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
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
  return { prepare, batch } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(() => '', (e: unknown) => String((e as { code?: string }).code ?? ''));
}

const EXPRESSION_SQL = 'SELECT id FROM expressions WHERE id = ?';
const LOCALE_SQL = 'SELECT id FROM language_locales WHERE code = ?';
const READING_COLUMNS = 'r.expression_id, r.locale_id, l.code AS language_locale_code, r.scheme, r.value, r.source_id';
const FIND_READING_SQL = `SELECT ${READING_COLUMNS} FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? AND r.locale_id=? AND r.scheme=? AND r.value=?`;
const INSERT_READING_SQL = 'INSERT INTO expression_readings(expression_id, locale_id, scheme, value, source_id) VALUES (?, ?, ?, ?, ?)';
const SOURCE_SQL = 'SELECT id FROM sources WHERE type = ? AND name = ?';

const readingRow: ReadingRow = {
  expression_id: 1, locale_id: 5, language_locale_code: 'nan-Hant-TW',
  scheme: 'ipa', value: 't͡sit', source_id: null,
};

describe('validateReadingScheme', () => {
  it('accepts valid schemes', () => {
    expect(validateReadingScheme('ipa')).toBe(true);
    expect(validateReadingScheme('pinyin')).toBe(true);
    expect(validateReadingScheme('wade-giles')).toBe(true);
    expect(validateReadingScheme('phonics:synthetic')).toBe(true);
  });

  it('rejects invalid schemes', () => {
    expect(validateReadingScheme('')).toBe(false);
    expect(validateReadingScheme('IPA')).toBe(false);
    expect(validateReadingScheme('a b')).toBe(false);
    expect(validateReadingScheme('1abc')).toBe(false);
  });
});

describe('createReading', () => {
  it('creates a reading after ensuring the locale exists', async () => {
    let stored: ReadingRow | null = null;
    const db = fakeD1({
      [EXPRESSION_SQL]: () => ({ id: 1 }),
      [LOCALE_SQL]: () => ({ id: 5 }),
      [FIND_READING_SQL]: () => stored,
      [INSERT_READING_SQL]: () => { stored = readingRow; return { success: true }; },
    });
    const result = await createReading(db, {
      expression_id: 1, language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.reading).toEqual(readingRow);
  });

  it('reuses an existing reading on duplicate', async () => {
    const db = fakeD1({
      [EXPRESSION_SQL]: () => ({ id: 1 }),
      [LOCALE_SQL]: () => ({ id: 5 }),
      [FIND_READING_SQL]: () => readingRow,
    });
    const result = await createReading(db, {
      expression_id: 1, language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', created_by: 1,
    });
    expect(result.created).toBe(false);
    expect(result.reading).toBe(readingRow);
  });

  it('resolves an optional source to its integer id before storing', async () => {
    let stored: ReadingRow | null = null;
    const db = fakeD1({
      [EXPRESSION_SQL]: () => ({ id: 1 }),
      [LOCALE_SQL]: () => ({ id: 5 }),
      [SOURCE_SQL]: () => ({ id: 3 }),
      [FIND_READING_SQL]: () => stored,
      [INSERT_READING_SQL]: () => { stored = { ...readingRow, source_id: 3 }; return { success: true }; },
    });
    const result = await createReading(db, {
      expression_id: 1, language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit',
      source: { type: 'publication', name: 'Tâi-lô Pronunciation Guide' },
      created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.reading.source_id).toBe(3);
  });

  it('rejects an invalid scheme with INVALID_READING_SCHEME', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 1, language_locale_code: 'nan-Hant-TW',
      scheme: 'Invalid', value: 'x', created_by: 1,
    }))).toBe('INVALID_READING_SCHEME');
  });

  it('rejects an empty value with VALIDATION_FAILED', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 1, language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: '  ', created_by: 1,
    }))).toBe('VALIDATION_FAILED');
  });

  it('rejects a missing expression with EXPRESSION_NOT_FOUND', async () => {
    const db = fakeD1({
      [EXPRESSION_SQL]: () => null,
      [LOCALE_SQL]: () => ({ id: 5 }),
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 999, language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 'x', created_by: 1,
    }))).toBe('EXPRESSION_NOT_FOUND');
  });

  it('rejects an unknown locale with INVALID_LANGUAGE_LOCALE_CODE', async () => {
    const db = fakeD1({
      [EXPRESSION_SQL]: () => ({ id: 1 }),
      [LOCALE_SQL]: () => null,
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 1, language_locale_code: 'nan-Hant-ZZ',
      scheme: 'ipa', value: 'x', created_by: 1,
    }))).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });
});