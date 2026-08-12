import { describe, expect, it } from 'vitest';
import { getExpression } from '../src/services/expressions';

describe('getExpression', () => {
  it('returns readings with provenance in stable locale, scheme, time, id order', async () => {
    const queries: string[] = [];
    const db = {
      prepare(sql: string) {
        queries.push(sql);
        return {
          bind(..._args: unknown[]) {
            return {
              async first<T>() {
                return (sql.includes('FROM expressions e LEFT JOIN sources')
                  ? { id: 'nan:hash', lang_code: 'nan', text: '食', source_type: 'url', source_name: 'Dictionary' }
                  : null) as T;
              },
              async all<T>() {
                if (sql.includes('expression_locale_attestations')) return { results: [] as T[] };
                return { results: [{ id: 'read-1', expression_id: 'nan:hash', language_locale_code: 'nan-Hant-TW', scheme: 'poj', value: 'chia̍h', source_type: 'url', source_name: 'Dictionary' }] as T[] };
              },
            };
          },
        };
      },
    } as unknown as D1Database;

    const detail = await getExpression(db, 'nan:hash');
    expect(detail?.readings[0]).toMatchObject({ id: 'read-1', source_name: 'Dictionary' });
    expect(queries.find((sql) => sql.includes('FROM expression_readings'))).toContain(
      'ORDER BY r.language_locale_code ASC, r.scheme ASC, r.created_at ASC, r.id ASC',
    );
  });
});
