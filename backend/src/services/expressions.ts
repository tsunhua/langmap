import type { D1Database } from '@cloudflare/workers-types';
import type { ExpressionLocaleRow, ExpressionPartOfSpeech, ExpressionRow, ExpressionSourceRow, ReadingRow } from '../types/expression';
import { canonicalizeExpressionText, expressionPrefixUpperBound } from './expressionIdentity';
import { resolveSource, type SourceInput } from './provenance';
import { SourceError } from './sources';

const EXPRESSION_COLUMNS = `e.id, e.language_id, l.code AS lang_code, e.text, e.homograph_index, e.pos_mask, e.source_id, e.created_by, e.created_at`;
const READING_COLUMNS = `r.expression_id, r.locale_id, l.code AS language_locale_code, l.name AS locale_display_name, r.scheme, r.value, r.source_id`;
export class ExpressionError extends Error { constructor(public code: string) { super(code); this.name = 'ExpressionError'; } }

export async function createExpression(db: D1Database, input: { lang_code: string; text: string; language_locale_code?: string; pos_mask?: number; source?: SourceInput; created_by: number }): Promise<{ expression: ExpressionRow; created: boolean }> {
  const text = canonicalizeExpressionText(input.text);
  if (!text) throw new ExpressionError('VALIDATION_FAILED');
  const language = await db.prepare('SELECT id FROM languages WHERE code=?').bind(input.lang_code.toLowerCase()).first<{ id: number }>();
  if (!language) throw new ExpressionError('INVALID_LANG_CODE');
  const locale = input.language_locale_code ? await db.prepare('SELECT id FROM language_locales WHERE code=? AND language_id=?').bind(input.language_locale_code, language.id).first<{ id: number }>() : null;
  if (input.language_locale_code && !locale) throw new ExpressionError('INVALID_LANGUAGE_LOCALE_CODE');
  const posMask = input.pos_mask ?? 0;
  if (!Number.isSafeInteger(posMask) || posMask < 0) throw new ExpressionError('INVALID_POS_MASK');
  let sourceId: number | null;
  try { sourceId = await resolveSource(db, input.source); } catch (error) { if (error instanceof SourceError) throw new ExpressionError(error.code); throw error; }
  const existing = await db.prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.language_id=? AND e.text=? AND e.homograph_index=1`).bind(language.id, text).first<ExpressionRow>();
  if (existing) { if (locale) await db.prepare('INSERT OR IGNORE INTO expression_locale_links(expression_id, locale_id) VALUES (?, ?)').bind(existing.id, locale.id).run(); return { expression: existing, created: false }; }
  const inserted = await db.prepare('INSERT INTO expressions(language_id,text,pos_mask,source_id,created_by) VALUES(?,?,?,?,?) RETURNING id').bind(language.id, text, posMask, sourceId, input.created_by).first<{ id: number }>();
  if (!inserted) throw new ExpressionError('EXPRESSION_CREATE_FAILED');
  try { await db.prepare(`INSERT INTO language_statistics(language_id, expression_count, updated_at) VALUES (?, 1, CURRENT_TIMESTAMP)
    ON CONFLICT(language_id) DO UPDATE SET expression_count=expression_count+1, updated_at=CURRENT_TIMESTAMP`).bind(language.id).run(); } catch (error) {
    if (!String(error).toLowerCase().includes('language_statistics')) throw error;
  }
  if (locale) await db.prepare('INSERT INTO expression_locale_links(expression_id, locale_id) VALUES (?, ?)').bind(inserted.id, locale.id).run();
  const expression = await db.prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?`).bind(inserted.id).first<ExpressionRow>();
  if (!expression) throw new ExpressionError('EXPRESSION_CREATE_FAILED');
  return { expression, created: true };
}

export async function getExpression(db: D1Database, id: number): Promise<{ expression: ExpressionRow; locales: ExpressionLocaleRow[]; readings: ReadingRow[]; parts_of_speech: ExpressionPartOfSpeech[]; sources: ExpressionSourceRow[] } | null> {
  const expression = await db.prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?`).bind(id).first<ExpressionRow>();
  if (!expression) return null;
  const [localeResult, readingResult, posResult] = await Promise.all([
    db.prepare('SELECT x.expression_id,x.locale_id,l.code AS language_locale_code,l.name AS locale_display_name FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=? ORDER BY l.code').bind(id).all<ExpressionLocaleRow>(),
    db.prepare(`SELECT ${READING_COLUMNS} FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? ORDER BY l.code,r.scheme,r.value`).bind(id).all<ReadingRow>(),
    db.prepare('SELECT code,name_en FROM parts_of_speech WHERE (? & (1 << bit_index)) != 0 ORDER BY sort_order').bind(expression.pos_mask).all<ExpressionPartOfSpeech>(),
  ]);
  let sources: ExpressionSourceRow[] = [];
  try {
    const sourceResult = await db.prepare('SELECT source_id,source_marker FROM expression_sources WHERE expression_id=? ORDER BY source_id,source_marker').bind(id).all<{ source_id:number; source_marker:string }>();
    sources = sourceResult.results.map((row) => ({ source_id: row.source_id, marker: row.source_marker || null }));
  } catch {
    // Expression provenance is optional: pre-migration databases return an empty list.
  }
  return {
    expression,
    locales: localeResult.results,
    readings: readingResult.results,
    parts_of_speech: posResult.results,
    sources,
  };
}

export async function searchExpressions(db: D1Database, query: { q: string; lang_code?: string; limit: number; offset: number }): Promise<{ items: ExpressionRow[]; total: number }> {
  const args: Array<string | number> = []; const where: string[] = [];
  if (query.lang_code) { where.push('l.code=?'); args.push(query.lang_code); }
  const q = canonicalizeExpressionText(query.q);
  if (q) { const upper = expressionPrefixUpperBound(q); if (upper) { where.push('e.text>=? AND e.text<?'); args.push(q, upper); } else { where.push('e.text>=?'); args.push(q); } }
  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const count = await db.prepare(`SELECT COUNT(*) AS total FROM expressions e JOIN languages l ON l.id=e.language_id ${clause}`).bind(...args).first<{ total: number }>();
  const rows = await db.prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id ${clause} ORDER BY e.text,e.homograph_index,e.id LIMIT ? OFFSET ?`).bind(...args, query.limit, query.offset).all<ExpressionRow>();
  return { items: rows.results, total: count?.total ?? 0 };
}

export async function createLocaleLink(db: D1Database, input: { expression_id: number; language_locale_code: string }): Promise<{ locale: ExpressionLocaleRow; created: boolean }> {
  const [expression, locale] = await Promise.all([db.prepare('SELECT id FROM expressions WHERE id=?').bind(input.expression_id).first(), db.prepare('SELECT id FROM language_locales WHERE code=?').bind(input.language_locale_code).first<{ id:number }>()]);
  if (!expression) throw new ExpressionError('EXPRESSION_NOT_FOUND'); if (!locale) throw new ExpressionError('INVALID_LANGUAGE_LOCALE_CODE');
  const existing = await db.prepare('SELECT 1 FROM expression_locale_links WHERE expression_id=? AND locale_id=?').bind(input.expression_id, locale.id).first();
  if (!existing) await db.prepare('INSERT INTO expression_locale_links(expression_id,locale_id) VALUES (?,?)').bind(input.expression_id,locale.id).run();
  return { locale: { expression_id: input.expression_id, locale_id: locale.id, language_locale_code: input.language_locale_code }, created: !existing };
}
