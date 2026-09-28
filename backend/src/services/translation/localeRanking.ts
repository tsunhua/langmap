// Rank stored locale claims before SQL LIMIT so a popular regional variant
// cannot crowd out the user's requested spelling or place profile.
export function localeRankSql(expressionAlias: string, requestedAlias = 'requested'): string {
  return `COALESCE((SELECT MIN(CASE
    WHEN reference.id = ${requestedAlias}.id THEN 0
    WHEN reference.script_code IS NOT DISTINCT FROM ${requestedAlias}.script_code
      AND reference.orthography IS NOT DISTINCT FROM ${requestedAlias}.orthography
      AND reference.region_code IS NOT DISTINCT FROM ${requestedAlias}.region_code THEN 1
    WHEN reference.script_code IS NOT DISTINCT FROM ${requestedAlias}.script_code
      AND reference.orthography IS NOT DISTINCT FROM ${requestedAlias}.orthography THEN 2
    ELSE 3 END)
    FROM expression_locale_links locale_claim
    JOIN language_locales reference ON reference.id = locale_claim.locale_id
    WHERE locale_claim.expression_id = ${expressionAlias}.id), 3)`;
}
