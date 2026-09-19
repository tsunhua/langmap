import { describe, expect, it } from 'vitest';
import { transformSql } from '../src/db/pgDatabase';

const t = (sql: string) => transformSql(sql);

describe('PostgreSQL query normalization', () => {
  it('rewrites positional placeholders', () => {
    expect(t('SELECT id FROM expressions WHERE id=? AND text=?').pgSql)
      .toBe('SELECT id FROM expressions WHERE id=$1 AND text=$2');
  });

  it('converts LIKE to PostgreSQL ILIKE for user-facing search', () => {
    expect(t("SELECT 1 WHERE code LIKE ? ESCAPE '\\'").pgSql)
      .toBe("SELECT 1 WHERE code ILIKE $1 ESCAPE '\\'");
  });

  it('leaves native jsonb casts and explicit conflict clauses intact', () => {
    const result = t('INSERT INTO l(language_id) VALUES(?) ON CONFLICT(language_id) DO NOTHING RETURNING id');
    expect(result.pgSql).toBe('INSERT INTO l(language_id) VALUES($1) ON CONFLICT(language_id) DO NOTHING RETURNING id');
    expect(result.needsOnConflict).toBe(false);
  });

  it("does not replace '?' inside string literals", () => {
    expect(t("SELECT '?' AS q, ? AS p").pgSql)
      .toBe("SELECT '?' AS q, $1 AS p");
  });

  it('numbers placeholders across string literals in order', () => {
    expect(t("SELECT 'a?b', ? , ?, ?").pgSql)
      .toBe("SELECT 'a?b', $1 , $2, $3");
  });
});
