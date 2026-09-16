import type { D1Database } from '@cloudflare/workers-types';

interface ExpressionLocaleRow {
  expression_id: number;
  locale_code: string;
}

const EXPRESSION_LOCALES_SQL = `SELECT ell.expression_id AS expression_id, ll.code AS locale_code
FROM expression_locale_links ell
JOIN language_locales ll ON ll.id = ell.locale_id
WHERE ell.expression_id IN (__EXPRESSION_IDS__)
ORDER BY ell.expression_id ASC, ll.code ASC`;

/**
 * Loads locale provenance after language-level graph retrieval. Locale links
 * describe the stored form; they are metadata and must not gate the language
 * match itself.
 */
export async function fetchExpressionLocaleCodes(
  db: D1Database,
  expressionIds: readonly number[],
): Promise<Map<number, string[]>> {
  const ids = [...new Set(expressionIds)];
  const byExpression = new Map<number, string[]>();
  if (ids.length === 0) return byExpression;

  const marks = ids.map(() => '?').join(',');
  const { results } = await db
    .prepare(EXPRESSION_LOCALES_SQL.replace('__EXPRESSION_IDS__', marks))
    .bind(...ids)
    .all<ExpressionLocaleRow>();

  for (const row of results) {
    const codes = byExpression.get(row.expression_id) ?? [];
    codes.push(row.locale_code);
    byExpression.set(row.expression_id, codes);
  }
  return byExpression;
}
