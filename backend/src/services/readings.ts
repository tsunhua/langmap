import type { D1Database } from '@cloudflare/workers-types';
import type { ReadingRow } from '../types/expression';
import { createLocaleAttestation, ExpressionError } from './expressions';
import { findOrCreateSource, SourceError } from './sources';

const READING_COLUMNS = `id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at`;
const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;
const SCHEME_RE = /^[a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*)?$/;

export class ReadingError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'ReadingError';
  }
}

export function validateReadingScheme(scheme: string): boolean {
  return SCHEME_RE.test(scheme);
}

export async function createReading(
  db: D1Database,
  input: {
    expression_id: string;
    language_locale_code: string;
    scheme: string;
    value: string;
    source?: { type: string; name: string; ref?: string };
    created_by: number;
  },
): Promise<{ reading: ReadingRow; created: boolean }> {
  const trimmedValue = input.value.trim();
  if (!trimmedValue) throw new ReadingError('VALIDATION_FAILED');
  if (!validateReadingScheme(input.scheme)) throw new ReadingError('INVALID_READING_SCHEME');

  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(input.expression_id)
    .first();
  if (!expression) throw new ReadingError('EXPRESSION_NOT_FOUND');

  const locale = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(input.language_locale_code).first();
  if (!locale) throw new ReadingError('INVALID_LANGUAGE_LOCALE_CODE');

  try {
    await createLocaleAttestation(db, {
      expression_id: input.expression_id,
      language_locale_code: input.language_locale_code,
      ...(input.source ? { source: input.source } : {}),
      created_by: input.created_by,
    });
  } catch (error) {
    if (error instanceof ExpressionError) throw new ReadingError(error.code);
    throw error;
  }

  let sourceId: string | null = null;
  let sourceRef: string | null = null;
  if (input.source) {
    try {
      sourceId = await findOrCreateSource(db, { type: input.source.type, name: input.source.name });
    } catch (error) {
      if (error instanceof SourceError) throw new ReadingError(error.code);
      throw error;
    }
    sourceRef = typeof input.source.ref === 'string' && input.source.ref.trim() ? input.source.ref.trim() : null;
  }

  const lookup = sourceId
    ? `SELECT ${READING_COLUMNS} FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id = ? AND source_ref = ?`
    : `SELECT ${READING_COLUMNS} FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id IS NULL AND source_ref IS NULL`;
  const bindArgs = sourceId
    ? [input.expression_id, input.language_locale_code, input.scheme, trimmedValue, sourceId, sourceRef]
    : [input.expression_id, input.language_locale_code, input.scheme, trimmedValue];
  const existing = await db.prepare(lookup).bind(...bindArgs).first<ReadingRow>();
  if (existing) return { reading: existing, created: false };

  const id = crypto.randomUUID();
  await db
    .prepare(
      sourceId
        ? `INSERT INTO expression_readings (id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        : `INSERT INTO expression_readings (id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, NULL, NULL, ?)`,
    )
    .bind(
      id, input.expression_id, input.language_locale_code, input.scheme, trimmedValue,
      ...(sourceId ? [sourceId, sourceRef, input.created_by] : [input.created_by]),
    )
    .run();

  const reading = await db
    .prepare(`SELECT ${READING_COLUMNS} FROM expression_readings WHERE id = ?`)
    .bind(id)
    .first<ReadingRow>();
  return { reading: reading as ReadingRow, created: true };
}
