import { describe, expect, it } from 'vitest';
import { transformSql } from '../src/db/pgDatabase';

const t = (sql: string) => transformSql(sql);

describe('transformSql (SQLite → PostgreSQL dialect translation)', () => {
  it('rewrites positional placeholders', () => {
    expect(t('SELECT id FROM expressions WHERE id=? AND text=?').pgSql)
      .toBe('SELECT id FROM expressions WHERE id=$1 AND text=$2');
  });

  it('converts LIKE to ILIKE and keeps ESCAPE', () => {
    expect(t("SELECT 1 WHERE code LIKE ? ESCAPE '\\'").pgSql)
      .toBe("SELECT 1 WHERE code ILIKE $1 ESCAPE '\\'");
  });

  it('leaves native jsonb casts untouched', () => {
    expect(t('SELECT value FROM jsonb_array_elements_text(?::jsonb)').pgSql)
      .toBe('SELECT value FROM jsonb_array_elements_text($1::jsonb)');
  });

  it('strips INSERT OR IGNORE and flags ON CONFLICT handling', () => {
    const r = t('INSERT OR IGNORE INTO x(a,b) VALUES(?,?)');
    expect(r.pgSql).toBe('INSERT INTO x(a,b) VALUES($1,$2)');
    expect(r.needsOnConflict).toBe(true);
  });

  it('rewrites COLLATE NOCASE equality and LIKE inside CASE', () => {
    expect(t("ORDER BY CASE WHEN code = ? COLLATE NOCASE THEN 0 WHEN code LIKE ? ESCAPE '\\' THEN 1 ELSE 2 END, code ASC LIMIT ? OFFSET ?").pgSql)
      .toBe("ORDER BY CASE WHEN LOWER(code) = LOWER($1) THEN 0 WHEN code ILIKE $2 ESCAPE '\\' THEN 1 ELSE 2 END, code ASC LIMIT $3 OFFSET $4");
  });

  it("rewrites CURRENT_TIMESTAMP to a UTC text timestamp", () => {
    expect(t('UPDATE t SET updated_at=CURRENT_TIMESTAMP WHERE id=?').pgSql)
      .toBe("UPDATE t SET updated_at=to_char(now() AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS') WHERE id=$1");
  });

  it('rewrites COLLATE NOCASE in ORDER BY positions', () => {
    expect(t('ORDER BY edge_score DESC, target_text COLLATE NOCASE, target_expression_id').pgSql)
      .toBe('ORDER BY edge_score DESC, LOWER(target_text), target_expression_id');
  });

  it("does not replace '?' inside string literals", () => {
    expect(t("SELECT '?' AS q, ? AS p").pgSql)
      .toBe('SELECT \'?\' AS q, $1 AS p');
  });

  it('numbers placeholders across string literals in order', () => {
    expect(t("SELECT 'a?b', ? , ?, ?").pgSql)
      .toBe('SELECT \'a?b\', $1 , $2, $3');
  });

  it('keeps an explicit ON CONFLICT clause without the ignore flag', () => {
    const r = t('INSERT INTO l(language_id, expression_count, updated_at) VALUES(?,1,CURRENT_TIMESTAMP) ON CONFLICT(language_id) DO UPDATE SET expression_count=l.expression_count+1, updated_at=CURRENT_TIMESTAMP');
    expect(r.needsOnConflict).toBe(false);
    expect(/ON CONFLICT\(language_id\) DO UPDATE/.test(r.pgSql)).toBe(true);
  });
});
