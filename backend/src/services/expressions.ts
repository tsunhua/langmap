import type { D1Database } from '@cloudflare/workers-types';
import type { ExpressionRow, LocaleAttestationRow, ReadingRow } from '../types/expression';
import type { SearchFormOfDto } from '../types/morphology';
import { buildExpressionId, canonicalizeExpressionText, computeTextHash } from './expressionIdentity';
import { resolveLanguageNames, type LocaleHints } from './localizedName';
import { attachFormOf } from './morphology';
import { SourceError } from './sources';
import { NULL_SAFE_PROVENANCE_PREDICATE, resolveProvenance, type SourceInput } from './provenance';

const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;
// Expression columns qualified with the `e.` alias so they stay unambiguous
// when the detail query LEFT JOINs sources (which also has id/created_at).
const EXPRESSION_DETAIL_COLUMNS = `e.id, e.lang_code, e.text, e.text_hash, e.homograph_index, e.description, e.tags_json, e.source_id, e.source_ref, e.review_status, e.created_by, e.created_at, e.updated_at`;

const ATTESTATION_COLUMNS = `id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at`;
const READING_DETAIL_COLUMNS = `r.id, r.expression_id, r.language_locale_code, r.scheme, r.value, r.source_id, r.source_ref, r.created_by, r.created_at,
  s.type AS source_type, s.name AS source_name`;
const INSERT_EXPRESSION_SQL = `INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, review_status, created_by)
  VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)`;
const INSERT_ATTESTATION_SQL = `INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by)
  VALUES (?, ?, ?, ?, ?, ?)`;

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
  if (input.language_locale_code) {
    const locale = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(input.language_locale_code).first();
    if (!locale) throw new ExpressionError('INVALID_LANGUAGE_LOCALE_CODE');
  }

  const textHash = await computeTextHash(text);
  const existing = await db
    .prepare('SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1')
    .bind(langCode, textHash)
    .first<{ id: string; text: string }>();
  if (existing) {
    if (existing.text !== text) throw new ExpressionError('EXPRESSION_HASH_COLLISION');
    if (input.language_locale_code) {
      await createLocaleAttestation(db, {
        expression_id: existing.id,
        language_locale_code: input.language_locale_code,
        created_by: input.created_by,
      });
    }
    const expression = await db
      .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
      .bind(existing.id)
      .first<ExpressionRow>();
    return { expression: expression as ExpressionRow, created: false };
  }

  const id = buildExpressionId(langCode, textHash, 1);
  if (input.language_locale_code) {
    await db.batch([
      db.prepare(INSERT_EXPRESSION_SQL).bind(id, langCode, text, textHash, '', '[]', 'pending', input.created_by),
      db.prepare(INSERT_ATTESTATION_SQL).bind(
        crypto.randomUUID(), id, input.language_locale_code, null, null, input.created_by,
      ),
    ]);
  } else {
    await db.prepare(INSERT_EXPRESSION_SQL).bind(id, langCode, text, textHash, '', '[]', 'pending', input.created_by).run();
  }

  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(id)
    .first<ExpressionRow>();
  return { expression: expression as ExpressionRow, created: true };
}

export async function searchExpressions(
  db: D1Database,
  query: { q: string; lang_code?: string; sort: 'hot' | 'new' | 'alpha'; limit: number; offset: number; hints?: LocaleHints },
): Promise<{ items: Array<ExpressionRow & { language_name: string; form_of: SearchFormOfDto[] }>; total: number }> {
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
  const orderBy = query.sort === 'hot'
    ? '(SELECT COUNT(*) FROM expression_edges g WHERE g.expression_a_id = expressions.id OR g.expression_b_id = expressions.id) DESC, text ASC, homograph_index ASC, id ASC'
    : query.sort === 'new'
      ? 'created_at DESC, id ASC'
      : 'text ASC, homograph_index ASC, id ASC';

  const countRow = await db
    .prepare(`SELECT COUNT(*) AS total FROM expressions ${where}`)
    .bind(...params)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions ${where} ORDER BY ${orderBy} LIMIT ? OFFSET ?`)
    .bind(...params, query.limit, query.offset)
    .all<ExpressionRow>();
  const names = await resolveLanguageNames(db, results.map((item) => item.lang_code), query.hints ?? {});
  const formOf = await attachFormOf(db, results.map((item) => item.id), query.hints ?? {});
  return {
    items: results.map((item) => ({
      ...item,
      language_name: names.get(item.lang_code) ?? '',
      form_of: formOf.get(item.id) ?? [],
    })),
    total: countRow?.total ?? 0,
  };
}

export async function getExpression(
  db: D1Database,
  id: string,
): Promise<{ expression: ExpressionRow & { source_type: string | null; source_name: string | null; created_by_username: string | null }; attestations: LocaleAttestationRow[]; readings: Array<ReadingRow & { source_type: string | null; source_name: string | null }> } | null> {
  const expression = await db
    .prepare(`SELECT ${EXPRESSION_DETAIL_COLUMNS}, s.type AS source_type, s.name AS source_name, u.username AS created_by_username FROM expressions e LEFT JOIN sources s ON s.id = e.source_id LEFT JOIN users u ON u.id = e.created_by WHERE e.id = ?`)
    .bind(id)
    .first<ExpressionRow & { created_by_username: string | null }>();
  if (!expression) return null;

  const { results } = await db
    .prepare(
      `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? ORDER BY language_locale_code ASC, created_at ASC, id ASC`,
    )
    .bind(id)
    .all<LocaleAttestationRow>();
  const { results: readings } = await db
    .prepare(
      `SELECT ${READING_DETAIL_COLUMNS} FROM expression_readings r LEFT JOIN sources s ON s.id = r.source_id WHERE r.expression_id = ? ORDER BY r.language_locale_code ASC, r.scheme ASC, r.created_at ASC, r.id ASC`,
    )
    .bind(id)
    .all<ReadingRow & { source_type: string | null; source_name: string | null }>();
  return { expression, attestations: results, readings };
}

export async function createLocaleAttestation(
  db: D1Database,
  input: { expression_id: string; language_locale_code: string; source?: SourceInput; created_by: number },
): Promise<{ attestation: LocaleAttestationRow; created: boolean }> {
  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(input.expression_id)
    .first<ExpressionRow>();
  if (!expression) throw new ExpressionError('EXPRESSION_NOT_FOUND');

  const locale = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(input.language_locale_code).first();
  if (!locale) throw new ExpressionError('INVALID_LANGUAGE_LOCALE_CODE');

  let provenance: { source_id: string | null; source_ref: string | null } | undefined;
  if (input.source) {
    try {
      provenance = await resolveProvenance(db, input.source);
    } catch (error) {
      if (error instanceof SourceError) throw new ExpressionError(error.code);
      throw error;
    }
  }
  const resolved = provenance ?? { source_id: null, source_ref: null };

  const existing = await db.prepare(
    `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND ${NULL_SAFE_PROVENANCE_PREDICATE}`,
  ).bind(input.expression_id, input.language_locale_code, resolved.source_id, resolved.source_ref).first<LocaleAttestationRow>();
  if (existing) return { attestation: existing, created: false };

  const attestationId = crypto.randomUUID();
  await db
    .prepare(INSERT_ATTESTATION_SQL)
    .bind(attestationId, input.expression_id, input.language_locale_code, resolved.source_id, resolved.source_ref, input.created_by)
    .run();

  const attestation = await db
    .prepare(`SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE id = ?`)
    .bind(attestationId)
    .first<LocaleAttestationRow>();
  return { attestation: attestation as LocaleAttestationRow, created: true };
}
