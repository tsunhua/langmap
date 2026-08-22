import { describe, expect, it } from 'vitest';
import { ReadingError, createReading, validateReadingScheme } from '../src/services/readings';

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
  it('creates a reading after ensuring attestation exists', async () => {
    const mockReading = {
      id: 'r1', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', source_id: null, source_ref: null,
      created_by: 1, created_at: '2026-08-14',
    };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ?':
        () => null,
      'INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id IS ? AND source_ref IS ?':
        () => null,
      'INSERT INTO expression_readings (id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at FROM expression_readings WHERE id = ?':
        () => mockReading,
    });
    const result = await createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.reading.scheme).toBe('ipa');
  });

  it('reuses an existing reading on duplicate', async () => {
    const existing = {
      id: 'r-old', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', source_id: null, source_ref: null,
      created_by: 1, created_at: '2026-08-14',
    };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ?':
        () => ({ id: 'att-old' }),
      'SELECT id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id IS ? AND source_ref IS ?':
        () => existing,
    });
    const result = await createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', created_by: 1,
    });
    expect(result.created).toBe(false);
    expect(result.reading.id).toBe('r-old');
  });

  it('rejects an invalid scheme with INVALID_READING_SCHEME', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'Invalid', value: 'x', created_by: 1,
    }))).toBe('INVALID_READING_SCHEME');
  });

  it('rejects an empty value with VALIDATION_FAILED', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: '  ', created_by: 1,
    }))).toBe('VALIDATION_FAILED');
  });

  it('rejects a missing expression with EXPRESSION_NOT_FOUND', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => null,
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 'nan:missing', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 'x', created_by: 1,
    }))).toBe('EXPRESSION_NOT_FOUND');
  });
});
