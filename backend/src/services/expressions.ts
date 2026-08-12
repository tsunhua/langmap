import type { D1Database } from '@cloudflare/workers-types';
import type { ExpressionRow, LocaleAttestationRow } from '../types/expression';
import { buildExpressionId, canonicalizeExpressionText, computeTextHash } from './expressionIdentity';
import { SourceError, findOrCreateSource } from './sources';

const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;

const ATTESTATION_COLUMNS = `id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at`;

export class ExpressionError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'ExpressionError';
  }
}

export async function createExpression(
  db: D1Database,
  input: { lang_code: string; text: string; language_locale_code?: string; created_by: number },
): Promise<{ expression: ExpressionRow; created: boolean }> {
  const text = canonicalizeExpressionText(input.text);
  if (!text) throw new ExpressionError('VALIDATION_FAILED');
  const langCode = input.lang_code.toLowerCase();
  const lang = await db.prepare('SELECT 1 FROM languages WHERE code = ?').bind(langCode).first();
  if (!lang) throw new ExpressionError('INVALID_LANG_CODE');

  const textHash = await computeTextHash(text);
  const existing = await db
    .prepare('SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1')
    .bind(langCode, textHash)
    .first<{ id: string; text: string }>();
  if (existing) {
    if (existing.text !== text) throw new ExpressionError('EXPRESSION_HASH_COLLISION');
    const expression = await db
      .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
      .bind(existing.id)
      .first<ExpressionRow>();
    return { expression: expression as ExpressionRow, created: false };
  }

  const id = buildExpressionId(langCode, textHash, 1);
  await db
    .prepare(
      `INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, review_status, created_by)
       VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)`,
    )
    .bind(id, langCode, text, textHash, '', '[]', 'pending', input.created_by)
    .run();

  if (input.language_locale_code) {
    await createLocaleAttestation(db, {
      expression_id: id,
      language_locale_code: input.language_locale_code,
      created_by: input.created_by,
    });
  }

  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(id)
    .first<ExpressionRow>();
  return { expression: expression as ExpressionRow, created: true };
}

export async function searchExpressions(
  db: D1Database,
  query: { q: string; lang_code?: string; limit: number; offset: number },
): Promise<{ items: ExpressionRow[]; total: number }> {
  const conditions: string[] = [];
  const params: (string | number)[] = [];
  if (query.q) {
    const escaped = query.q.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
    conditions.push("text LIKE ? ESCAPE '\\'");
    params.push(`%${escaped}%`);
  }
  if (query.lang_code) {
    conditions.push('lang_code = ?');
    params.push(query.lang_code);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countRow = await db
    .prepare(`SELECT COUNT(*) AS total FROM expressions ${where}`)
    .bind(...params)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions ${where} ORDER BY text ASC LIMIT ? OFFSET ?`)
    .bind(...params, query.limit, query.offset)
    .all<ExpressionRow>();
  return { items: results, total: countRow?.total ?? 0 };
}

export async function getExpression(
  db: D1Database,
  id: string,
): Promise<{ expression: ExpressionRow; attestations: LocaleAttestationRow[] } | null> {
  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(id)
    .first<ExpressionRow>();
  if (!expression) return null;

  const { results } = await db
    .prepare(
      `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? ORDER BY language_locale_code ASC, created_at ASC`,
    )
    .bind(id)
    .all<LocaleAttestationRow>();
  return { expression, attestations: results };
}

export async function createLocaleAttestation(
  db: D1Database,
  input: { expression_id: string; language_locale_code: string; source?: { type: string; name: string; ref?: string }; created_by: number },
): Promise<{ attestation: LocaleAttestationRow; created: boolean }> {
  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(input.expression_id)
    .first<ExpressionRow>();
  if (!expression) throw new ExpressionError('EXPRESSION_NOT_FOUND');

  const locale = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(input.language_locale_code).first();
  if (!locale) throw new ExpressionError('INVALID_LANGUAGE_LOCALE_CODE');

  let sourceId: string | null = null;
  let sourceRef: string | null = null;
  if (input.source) {
    try {
      sourceId = await findOrCreateSource(db, { type: input.source.type, name: input.source.name });
    } catch (error) {
      if (error instanceof SourceError) throw new ExpressionError(error.code);
      throw error;
    }
    sourceRef = typeof input.source.ref === 'string' && input.source.ref.trim() ? input.source.ref.trim() : null;
  }

  const lookup = sourceId
    ? `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id = ? AND source_ref = ?`
    : `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS NULL AND source_ref IS NULL`;
  const bindArgs = sourceId
    ? [input.expression_id, input.language_locale_code, sourceId, sourceRef]
    : [input.expression_id, input.language_locale_code];
  const existing = await db.prepare(lookup).bind(...bindArgs).first<LocaleAttestationRow>();
  if (existing) return { attestation: existing, created: false };

  const attestationId = crypto.randomUUID();
  await db
    .prepare(
      sourceId
        ? `INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?)`
        : `INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, NULL, NULL, ?)`,
    )
    .bind(
      attestationId,
      input.expression_id,
      input.language_locale_code,
      ...(sourceId ? [sourceId, sourceRef, input.created_by] : [input.created_by]),
    )
    .run();

  const attestation = await db
    .prepare(`SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE id = ?`)
    .bind(attestationId)
    .first<LocaleAttestationRow>();
  return { attestation: attestation as LocaleAttestationRow, created: true };
}
