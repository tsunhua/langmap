import type { D1Database } from '@cloudflare/workers-types';
import type { ReadingRow } from '../types/expression';
import { SourceError } from './sources';
import { NULL_SAFE_PROVENANCE_PREDICATE, resolveProvenance, type SourceInput } from './provenance';

const READING_COLUMNS = `id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at`;
const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;
const SCHEME_RE = /^[a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*)?$/;
const INSERT_ATTESTATION_SQL = `INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by)
  VALUES (?, ?, ?, ?, ?, ?)`;
const INSERT_READING_SQL = `INSERT INTO expression_readings (id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;

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
    source?: SourceInput;
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

  let provenance: { source_id: string | null; source_ref: string | null } | undefined;
  if (input.source) {
    try {
      provenance = await resolveProvenance(db, input.source);
    } catch (error) {
      if (error instanceof SourceError) throw new ReadingError(error.code);
      throw error;
    }
  }
  const resolved = provenance ?? { source_id: null, source_ref: null };

  const existing = await db.prepare(
    `SELECT ${READING_COLUMNS} FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND ${NULL_SAFE_PROVENANCE_PREDICATE}`,
  ).bind(input.expression_id, input.language_locale_code, input.scheme, trimmedValue, resolved.source_id, resolved.source_ref).first<ReadingRow>();
  if (existing) return { reading: existing, created: false };

  const existingAttestation = await db.prepare(
    `SELECT id FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND ${NULL_SAFE_PROVENANCE_PREDICATE}`,
  ).bind(input.expression_id, input.language_locale_code, resolved.source_id, resolved.source_ref).first<{ id: string }>();

  const id = crypto.randomUUID();
  const statements = [];
  if (!existingAttestation) {
    statements.push(db.prepare(INSERT_ATTESTATION_SQL).bind(
      crypto.randomUUID(), input.expression_id, input.language_locale_code,
      resolved.source_id, resolved.source_ref, input.created_by,
    ));
  }
  statements.push(db.prepare(INSERT_READING_SQL).bind(
    id, input.expression_id, input.language_locale_code, input.scheme, trimmedValue,
    resolved.source_id, resolved.source_ref, input.created_by,
  ));
  await db.batch(statements);

  const reading = await db
    .prepare(`SELECT ${READING_COLUMNS} FROM expression_readings WHERE id = ?`)
    .bind(id)
    .first<ReadingRow>();
  return { reading: reading as ReadingRow, created: true };
}
