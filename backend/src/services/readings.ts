import type { D1Database } from '@cloudflare/workers-types';
import type { ReadingRow } from '../types/expression';
import { SourceError } from './sources';
import { resolveSource, type SourceInput } from './provenance';

const READING_COLUMNS = `r.expression_id, r.locale_id, l.code AS language_locale_code, l.name AS locale_display_name, r.scheme, r.value, r.source_id`;
const SCHEME_RE = /^[a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*)?$/;
export class ReadingError extends Error { constructor(public code: string) { super(code); this.name = 'ReadingError'; } }
export function validateReadingScheme(scheme: string): boolean { return SCHEME_RE.test(scheme); }

export async function createReading(db: D1Database, input: { expression_id: number; language_locale_code: string; scheme: string; value: string; source?: SourceInput; created_by: number }): Promise<{ reading: ReadingRow; created: boolean }> {
  const value = input.value.trim();
  if (!value) throw new ReadingError('VALIDATION_FAILED');
  if (!validateReadingScheme(input.scheme)) throw new ReadingError('INVALID_READING_SCHEME');
  const [expression, locale] = await Promise.all([
    db.prepare('SELECT id FROM expressions WHERE id = ?').bind(input.expression_id).first(),
    db.prepare('SELECT id FROM language_locales WHERE code = ?').bind(input.language_locale_code).first<{ id: number }>(),
  ]);
  if (!expression) throw new ReadingError('EXPRESSION_NOT_FOUND');
  if (!locale) throw new ReadingError('INVALID_LANGUAGE_LOCALE_CODE');
  let sourceId: number | null;
  try { sourceId = await resolveSource(db, input.source); } catch (error) { if (error instanceof SourceError) throw new ReadingError(error.code); throw error; }
  const existing = await db.prepare(`SELECT ${READING_COLUMNS} FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? AND r.locale_id=? AND r.scheme=? AND r.value=?`).bind(input.expression_id, locale.id, input.scheme, value).first<ReadingRow>();
  if (existing) return { reading: existing, created: false };
  await db.prepare('INSERT INTO expression_readings(expression_id, locale_id, scheme, value, source_id) VALUES (?, ?, ?, ?, ?)').bind(input.expression_id, locale.id, input.scheme, value, sourceId).run();
  const reading = await db.prepare(`SELECT ${READING_COLUMNS} FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? AND r.locale_id=? AND r.scheme=? AND r.value=?`).bind(input.expression_id, locale.id, input.scheme, value).first<ReadingRow>();
  if (!reading) throw new ReadingError('READING_CREATE_FAILED');
  return { reading, created: true };
}
