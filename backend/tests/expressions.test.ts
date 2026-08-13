import { describe, expect, it } from 'vitest';
import {
  ExpressionError,
  createExpression,
  createLocaleAttestation,
  getExpression,
  searchExpressions,
} from '../src/services/expressions';
import type { ExpressionRow, LocaleAttestationRow } from '../src/types/expression';

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
          async first<T>() {
            return (await run()) as T;
          },
          async run() {
            return handler ? await handler() : { success: true };
          },
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
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

describe('createExpression', () => {
  const insertedExpression: ExpressionRow = {
    id: 'nan:ftze3os7wcrq4jxihmvmlopcty',
    lang_code: 'nan',
    text: '食',
    text_hash: 'aaaa',
    homograph_index: 1,
    description: '',
    tags_json: '[]',
    source_id: null,
    source_ref: null,
    review_status: 'pending',
    created_by: 1,
    created_at: '2026-08-12 00:00:00',
    updated_at: '2026-08-12 00:00:00',
  };

  it('creates a new expression with computed hash and id', async () => {
    const insertCalled: string[] = [];
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1': () => null,
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => insertedExpression,
      'INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, review_status, created_by)\n       VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)':
        () => {
          insertCalled.push('insert');
          return { success: true };
        },
    });
    const result = await createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 });
    expect(result.created).toBe(true);
    expect(result.expression.id).toBe('nan:ftze3os7wcrq4jxihmvmlopcty');
    expect(insertCalled).toHaveLength(1);
  });

  it('reuses an existing expression when canonical text matches', async () => {
    const existing = { id: 'nan:existing', text: '食' };
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1':
        () => existing,
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => insertedExpression,
    });
    const result = await createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 });
    expect(result.created).toBe(false);
    expect(result.expression.id).toBe(insertedExpression.id);
  });

  it('adds the requested locale when reusing an expression', async () => {
    const inserted: string[] = [];
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1':
        () => ({ id: 'nan:existing', text: '食' }),
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => insertedExpression,
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS ? AND source_ref IS ?':
        () => null,
      'INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?)':
        () => { inserted.push('attestation'); return { success: true }; },
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE id = ?':
        () => ({ id: 'att-new' }),
    });
    const result = await createExpression(db, {
      lang_code: 'nan', text: '食', language_locale_code: 'nan-Hant-TW', created_by: 1,
    });
    expect(result.created).toBe(false);
    expect(inserted).toEqual(['attestation']);
  });

  it('throws EXPRESSION_HASH_COLLISION when a different text hits the same short hash', async () => {
    const existing = { id: 'nan:other', text: 'other text' };
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1':
        () => existing,
    });
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 }))).toBe(
      'EXPRESSION_HASH_COLLISION',
    );
  });

  it('rejects an unknown lang_code with INVALID_LANG_CODE', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => null,
    });
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'zzz', text: '食', created_by: 1 }))).toBe(
      'INVALID_LANG_CODE',
    );
  });

  it('rejects empty canonical text with VALIDATION_FAILED', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'nan', text: '   ', created_by: 1 }))).toBe(
      'VALIDATION_FAILED',
    );
  });

  it('creates a locale attestation when language_locale_code is provided', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1': () => null,
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => insertedExpression,
      'INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, review_status, created_by)\n       VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)':
        () => ({ success: true }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS ? AND source_ref IS ?':
        () => null,
      'INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE id = ?':
        () => ({ id: 'att-1', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' }),
    });
    const result = await createExpression(db, {
      lang_code: 'nan',
      text: '食',
      language_locale_code: 'nan-Hant-TW',
      created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.expression.id).toBe('nan:ftze3os7wcrq4jxihmvmlopcty');
  });
});

describe('searchExpressions', () => {
  it('returns items ordered by text and a total', async () => {
    const rows = [
      { id: 'nan:aaaa', lang_code: 'nan', text: '食', text_hash: 'aaaa', homograph_index: 1, description: '', tags_json: '[]', source_id: null, source_ref: null, review_status: 'pending', created_by: 1, created_at: '2026-08-12 00:00:00', updated_at: '2026-08-12 00:00:00' },
      { id: 'nan:bbbb', lang_code: 'nan', text: '食飯', text_hash: 'bbbb', homograph_index: 1, description: '', tags_json: '[]', source_id: null, source_ref: null, review_status: 'pending', created_by: 1, created_at: '2026-08-12 00:00:00', updated_at: '2026-08-12 00:00:00' },
    ];
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expressions WHERE text LIKE ? ESCAPE \'\\\'': () => ({ total: 2 }),
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE text LIKE ? ESCAPE \'\\\' ORDER BY text ASC, homograph_index ASC, id ASC LIMIT ? OFFSET ?':
        () => ({ results: rows }),
    });
    const result = await searchExpressions(db, { q: '食', sort: 'alpha', limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.text)).toEqual(['食', '食飯']);
  });

  it('filters by lang_code when provided', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expressions WHERE text LIKE ? ESCAPE \'\\\' AND lang_code = ?': () => ({ total: 1 }),
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE text LIKE ? ESCAPE \'\\\' AND lang_code = ? ORDER BY text ASC, homograph_index ASC, id ASC LIMIT ? OFFSET ?':
        () => ({ results: [] }),
    });
    const result = await searchExpressions(db, { q: '食', lang_code: 'nan', sort: 'alpha', limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items).toHaveLength(0);
  });

  it('supports stable hot and newest ordering', async () => {
    const observedSql: string[] = [];
    const db = {
      prepare(sql: string) {
        observedSql.push(sql);
        return { bind() { return {
          async first() { return { total: 0 }; },
          async all() { return { results: [] }; },
        }; } };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;

    await searchExpressions(db, { q: '', sort: 'hot', limit: 20, offset: 0 });
    await searchExpressions(db, { q: '', sort: 'new', limit: 20, offset: 0 });

    const pageQueries = observedSql.filter((sql) => sql.includes(' LIMIT ? OFFSET ?'));
    expect(pageQueries[0]).toContain('ORDER BY (SELECT COUNT(*) FROM expression_edges g WHERE g.expression_a_id = expressions.id OR g.expression_b_id = expressions.id) DESC, text ASC, homograph_index ASC, id ASC');
    expect(pageQueries[1]).toContain('ORDER BY created_at DESC, id ASC');
  });
});

describe('getExpression', () => {
  it('returns the expression with sorted attestations', async () => {
    const expression: ExpressionRow = {
      id: 'nan:aaaa', lang_code: 'nan', text: '食', text_hash: 'aaaa', homograph_index: 1,
      description: '', tags_json: '[]', source_id: null, source_ref: null,
      review_status: 'pending', created_by: 1, created_at: '2026-08-12 00:00:00', updated_at: '2026-08-12 00:00:00',
    };
    const attestations: LocaleAttestationRow[] = [
      { id: 'a1', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-CN', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' },
      { id: 'a2', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' },
    ];
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => expression,
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? ORDER BY language_locale_code ASC, created_at ASC, id ASC':
        () => ({ results: attestations }),
    });
    const result = await getExpression(db, 'nan:aaaa');
    expect(result).not.toBeNull();
    expect(result?.attestations.map((a) => a.language_locale_code)).toEqual(['nan-Hant-CN', 'nan-Hant-TW']);
  });

  it('returns null for a missing expression', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at, s.type AS source_type, s.name AS source_name FROM expressions e LEFT JOIN sources s ON s.id = e.source_id WHERE e.id = ?':
        () => null,
    });
    expect(await getExpression(db, 'nan:missing')).toBeNull();
  });
});

describe('createLocaleAttestation', () => {
  it('creates an attestation with source provenance', async () => {
    const inserted: LocaleAttestationRow = {
      id: 'att-new', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-CN',
      source_id: 'src-1', source_ref: 'https://example.test/1', created_by: 1, created_at: '2026-08-12 00:00:00',
    };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id FROM sources WHERE type = ? AND name = ?': () => null,
      'INSERT INTO sources (id, type, name) VALUES (?, ?, ?)': () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS ? AND source_ref IS ?':
        () => null,
      'INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE id = ?':
        () => inserted,
    });
    const result = await createLocaleAttestation(db, {
      expression_id: 'nan:aaaa',
      language_locale_code: 'nan-Hant-CN',
      source: { type: 'url', name: 'Test Dictionary', ref: 'https://example.test/1' },
      created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.attestation.source_ref).toBe('https://example.test/1');
  });

  it('reuses an existing attestation when the provenance matches', async () => {
    const existing = { id: 'att-old', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-CN', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS ? AND source_ref IS ?':
        () => existing,
    });
    const result = await createLocaleAttestation(db, {
      expression_id: 'nan:aaaa',
      language_locale_code: 'nan-Hant-CN',
      created_by: 1,
    });
    expect(result.created).toBe(false);
    expect(result.attestation.id).toBe('att-old');
  });

  it('reuses a named source attestation when its ref is omitted', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id FROM sources WHERE type = ? AND name = ?': () => ({ id: 'src-dict' }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS ? AND source_ref IS ?':
        () => ({ id: 'att-existing' }),
    });
    const result = await createLocaleAttestation(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      source: { type: 'publication', name: 'Dictionary' }, created_by: 1,
    });
    expect(result).toMatchObject({ created: false, attestation: { id: 'att-existing' } });
  });

  it('throws INVALID_LANGUAGE_LOCALE_CODE for an unknown locale', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => null,
    });
    expect(
      await captureAsyncCode(() => createLocaleAttestation(db, { expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-ZZ', created_by: 1 })),
    ).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('throws EXPRESSION_NOT_FOUND for a missing expression', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => null,
    });
    expect(
      await captureAsyncCode(() => createLocaleAttestation(db, { expression_id: 'nan:missing', language_locale_code: 'nan-Hant-TW', created_by: 1 })),
    ).toBe('EXPRESSION_NOT_FOUND');
  });
});
