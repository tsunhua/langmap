import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Client } from 'pg';
import { readFileSync } from 'node:fs';
import type { Database, PreparedStatement } from '../src/db/database';
import { transformSql } from '../src/db/pgDatabase';
import { DEFAULT_RETRIEVAL_LIMITS, retrieveEvidence } from '../src/services/translation/retrieval';
import { DEFAULT_EXACT_MATCH_LIMITS, findExactTranslation } from '../src/services/translation/exactMatch';

const connectionString = process.env.TRANSLATION_TEST_DATABASE_URL;
// Only explicitly supplied isolated databases run the real-query suite.
describe.skipIf(!connectionString)('translation queries on PostgreSQL', () => {
  const client = new Client({ connectionString });
  const calls: Array<{ sql: string; params: unknown[]; ms: number }> = [];
  let db: Database;
  const target = { locale_id: 101, language_id: 102, lang_code: 'cmn' };
  beforeAll(async () => {
    await client.connect();
    await client.query('BEGIN');
    await client.query('CREATE SCHEMA translation_query_fixture');
    await client.query('SET LOCAL search_path = translation_query_fixture, public');
    await client.query(readFileSync(new URL('../postgres/schema.sql', import.meta.url), 'utf8'));
    await client.query(`
      INSERT INTO languages(id,code,name_en) VALUES (101,'eng','English'),(102,'cmn','Mandarin'),(103,'spa','Spanish');
      INSERT INTO scripts(code,name_en,direction) VALUES ('Latn','Latin','ltr'),('Hant','Traditional Han','ltr'),('Hans','Simplified Han','ltr');
      INSERT INTO regions(code,name_en) VALUES ('TW','Taiwan'),('CN','China'),('US','United States');
      INSERT INTO language_locales(id,code,language_id,script_code,region_code,place_path,name,name_en) VALUES
        (101,'cmn-Hant-TW',102,'Hant','TW','','臺灣普通話','Mandarin Taiwan'),
        (102,'cmn-Hans-CN',102,'Hans','CN','','中國普通話','Mandarin China'),
        (103,'cmn-Hant-TW-place',102,'Hant','TW','Taipei','臺北普通話','Mandarin Taipei'),
        (104,'eng-Latn-US',101,'Latn','US','','英語','English US');
      INSERT INTO expressions(id,language_id,text) VALUES
        (101,101,'Hello'),(102,102,'您好'),(103,102,'你好'),
        (110,101,'Train station'),(111,102,'車站'),(112,102,'火车站'),
        (120,101,'Coffee'),(121,102,'咖啡'),(122,103,'Café'),
        (130,101,'Station'),(131,102,'站'),(132,102,'車站入口');
      INSERT INTO expression_locale_links(expression_id,locale_id) VALUES
        (102,101),(103,102),(111,101),(112,102),(121,101),(131,101),(132,103);
      INSERT INTO expression_edges(id,expression_a_id,expression_b_id,relation_mask,score) VALUES
        (101,101,102,1,1),(102,101,103,1,100),
        (110,110,111,1,1),(111,110,112,1,100),
        (120,120,122,1,1),(121,121,122,1,1),
        (130,130,131,1,1),(131,130,132,1,100);
    `);
    db = { prepare(sql: string): PreparedStatement {
      let params: unknown[] = [];
      const query = async () => {
        const start = performance.now();
        const result = await client.query(transformSql(sql).pgSql, params);
        calls.push({ sql, params: [...params], ms: performance.now() - start });
        return result;
      };
      const statement: PreparedStatement = {
        bind(...values) { params = values; return statement; },
        async all<T>() { return { results: (await query()).rows as T[], success: true, meta: {} }; },
        async first<T>() { return (await query()).rows[0] as T ?? null; },
        async run() { const result = await query(); return { success: true, meta: { last_row_id: 0, changes: result.rowCount ?? 0 } }; },
        _sql: sql, _params: () => params,
      };
      return statement;
    }, async batch() { throw new Error('Unexpected batch mutation'); } };
  });
  afterAll(async () => { await client.query('ROLLBACK'); await client.end(); });
  it('chooses the requested locale before a higher-scored foreign locale', async () => {
    const result = await findExactTranslation(db, { canonicalText: 'Hello', sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW', targetLocale: target, limits: DEFAULT_EXACT_MATCH_LIMITS });
    expect(result.status).toBe('exact_match');
    if (result.status === 'exact_match') {
      expect(result.result.translation).toBe('您好');
      expect(result.locale_compatible).toBe(true);
    }
  });
  it('finds terms and phrases in a sentence with bounded batched queries', async () => {
    const start = calls.length;
    const output = await retrieveEvidence(db, {
      fullText: 'Where is the train station?', sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW', targetLocale: target,
      spans: [{ start: 13, end: 26, text: 'train station', reason: 'phrase', confidence: 1 }],
    });
    expect(output.retrieval_status).toBe('matched');
    expect(output.items[0]).toMatchObject({ source_text: 'Train station', target_text: '車站', match_type: 'exact' });
    expect(calls.length - start).toBeLessThanOrEqual(6);
    console.log(JSON.stringify({ scenario: 'sentence-reference', queries: calls.length - start, sql_ms: Math.round(calls.slice(start).reduce((sum, call) => sum + call.ms, 0) * 10) / 10 }));
  });
  it('retrieves an approved two-hop match and records the pivot', async () => {
    const output = await retrieveEvidence(db, { fullText: 'Coffee', spans: [], sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW', targetLocale: target });
    expect(output.items[0]).toMatchObject({ target_text: '咖啡', path_type: 'two_hop', pivot_lang_code: 'spa' });
  });
  it('uses trigram tolerance for a failed short root without promoting it to exact', async () => {
    const output = await retrieveEvidence(db, { fullText: 'Train statio', spans: [{ start: 0, end: 12, text: 'Train statio', reason: 'phrase', confidence: 1 }], sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW', targetLocale: target });
    expect(output.items[0]).toMatchObject({ source_text: 'Train station', target_text: '車站', match_type: 'prefix' });
    const fuzzy = await retrieveEvidence(db, { fullText: 'Stationx', spans: [], sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW', targetLocale: target });
    expect(fuzzy.items[0]).toMatchObject({ source_text: 'Station', target_text: '站', match_type: 'fuzzy' });
  });
  it('respects place identity: a neighbouring profile needs generation', async () => {
    const result = await findExactTranslation(db, { canonicalText: 'Station', sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW-place', targetLocale: { ...target, locale_id: 103 }, limits: DEFAULT_EXACT_MATCH_LIMITS });
    expect(result.status).toBe('exact_match');
    if (result.status === 'exact_match') { expect(result.result.translation).toBe('車站入口'); expect(result.locale_compatible).toBe(true); }
    const fallback = await findExactTranslation(db, { canonicalText: 'Hello', sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW-place', targetLocale: { ...target, locale_id: 103 }, limits: DEFAULT_EXACT_MATCH_LIMITS });
    if (fallback.status === 'exact_match') expect(fallback.locale_compatible).toBe(false);
  });
  it('filters different languages before trigram matching and uses the GIN index for similarity predicates', async () => {
    const none = await retrieveEvidence(db, { fullText: 'Hello', spans: [], sourceLangCode: 'spa', targetLocaleCode: 'cmn-Hant-TW', targetLocale: target });
    expect(none.items).toHaveLength(0);
    // Give the planner enough unrelated rows to prefer selective text indexes;
    // a tiny dictionary can correctly choose a language index instead.
    await client.query("INSERT INTO expressions(id,language_id,text) SELECT 10000 + n, 101, 'Entry ' || md5(n::text) FROM generate_series(1,20000) n");
    await client.query("SELECT gin_clean_pending_list('idx_expressions_text_trgm'::regclass)");
    await client.query('ANALYZE expressions');
    await client.query('ANALYZE languages');
    await retrieveEvidence(db, { fullText: 'Stationx', spans: [], sourceLangCode: 'eng', targetLocaleCode: 'cmn-Hant-TW', targetLocale: target });
    const fallback = [...calls].reverse().find(call => call.sql.includes('fuzzy_allowed'))!;
    const plan = await client.query(`EXPLAIN (ANALYZE, FORMAT JSON) ${transformSql(fallback.sql).pgSql}`, fallback.params);
    expect(JSON.stringify(plan.rows)).toContain('idx_expressions_text_trgm');
    expect(JSON.stringify(plan.rows)).toContain('expressions_language_id_text_homograph_index_key');
  });
});
