import { Hono } from 'hono';
import { success } from '../utils/response';
import { parseLocaleHints, resolveLanguageNames } from '../services/localizedName';
import type { Bindings } from '../types';
import { dictionaryReleaseSchemaAvailable, edgeEligibilityPredicate } from '../services/dictionaryReleaseEligibility';

const feed = new Hono<{ Bindings: Bindings }>();

// Canonical collection endpoint; retain /hot and /new as compatibility aliases.
feed.get('/', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = `/${c.req.query('sort') === 'new' ? 'new' : 'hot'}`;
  return feed.fetch(new Request(url, c.req.raw), c.env, c.executionCtx);
});

function parseLimit(value: string | undefined): number {
  const parsed = Number.parseInt(value ?? '20', 10);
  return Number.isFinite(parsed) ? Math.min(Math.max(parsed, 1), 100) : 20;
}

const EDGE_COLUMNS = `ed.id, ed.score, ed.source, ed.created_at,
  a.id AS a_id, a.text AS a_text, a.lang_code AS a_lang,
  b.id AS b_id, b.text AS b_text, b.lang_code AS b_lang`;

// The compatibility all_* views are useful for ordinary reads, but a feed
// query that joins the same UNION view twice forces SQLite to materialize the
// complete dictionary catalog.  The packed branches below join by integer
// keys first and format the public IDs only at the boundary.
function packedHotSql(edgePredicate: string): string {
  return `SELECT ed.id, ed.score, ed.source, ed.created_at,
    ed.a_id, ed.a_text, ed.a_lang, ed.b_id, ed.b_text, ed.b_lang
    FROM (
      SELECT ${EDGE_COLUMNS}
      FROM expression_edges ed
      JOIN expressions a ON a.id = ed.expression_a_id
      JOIN expressions b ON b.id = ed.expression_b_id
      ${edgePredicate}
      UNION ALL
      SELECT 'e' || printf('%08d', de.edge_id), 0, 'dictionary', dr.created_at,
        'd' || printf('%08d', de.expression_a_id), ta.text, la.code,
        'd' || printf('%08d', de.expression_b_id), tb.text, lb.code
      FROM dictionary_edges de
      JOIN dictionary_terms ta ON ta.term_id = de.expression_a_id
      JOIN dictionary_languages la ON la.language_id = ta.language_id
      JOIN dictionary_terms tb ON tb.term_id = de.expression_b_id
      JOIN dictionary_languages lb ON lb.language_id = tb.language_id
      JOIN dictionary_dataset_state ds
        ON ds.dataset_key = 'managed-dictionaries' AND ds.active_release_id IS NOT NULL
      JOIN dictionary_dataset_releases dr ON dr.id = ds.active_release_id
    ) ed
    ORDER BY ed.score DESC, ed.created_at DESC, ed.id ASC
    LIMIT ?`;
}

function packedNewSql(edgePredicate: string): string {
  return `WITH latest_mappings AS (
      SELECT * FROM (
        SELECT 'mapping' AS type, ed.id AS id, ed.created_at, u.username AS author,
          a.id AS a_id, b.id AS b_id,
          a.text AS left_text, a.lang_code AS left_lang,
          b.text AS right_text, b.lang_code AS right_lang
        FROM expression_edges ed
        JOIN expressions a ON a.id = ed.expression_a_id
        JOIN expressions b ON b.id = ed.expression_b_id
        LEFT JOIN users u ON u.id = ed.created_by
        ${edgePredicate}
        UNION ALL
        SELECT 'mapping', 'e' || printf('%08d', de.edge_id), dr.created_at, NULL,
          'd' || printf('%08d', de.expression_a_id),
          'd' || printf('%08d', de.expression_b_id),
          ta.text, la.code, tb.text, lb.code
        FROM dictionary_edges de
        JOIN dictionary_terms ta ON ta.term_id = de.expression_a_id
        JOIN dictionary_languages la ON la.language_id = ta.language_id
        JOIN dictionary_terms tb ON tb.term_id = de.expression_b_id
        JOIN dictionary_languages lb ON lb.language_id = tb.language_id
        JOIN dictionary_dataset_state ds
          ON ds.dataset_key = 'managed-dictionaries' AND ds.active_release_id IS NOT NULL
        JOIN dictionary_dataset_releases dr ON dr.id = ds.active_release_id
      ) ed
      ORDER BY ed.created_at DESC, ed.id ASC
      LIMIT ?
    ), latest_expressions AS (
      SELECT * FROM (
        SELECT 'expression' AS type, e.id, e.created_at, u.username AS author,
          NULL AS a_id, NULL AS b_id,
          e.text AS left_text, e.lang_code AS left_lang,
          NULL AS right_text, NULL AS right_lang
        FROM expressions e
        LEFT JOIN users u ON u.id = e.created_by
        UNION ALL
        SELECT 'expression', 'd' || printf('%08d', dt.term_id), dr.created_at, NULL,
          NULL, NULL, dt.text, dl.code, NULL, NULL
        FROM dictionary_terms dt
        JOIN dictionary_languages dl ON dl.language_id = dt.language_id
        JOIN dictionary_dataset_state ds
          ON ds.dataset_key = 'managed-dictionaries' AND ds.active_release_id IS NOT NULL
        JOIN dictionary_dataset_releases dr ON dr.id = ds.active_release_id
      ) e
      ORDER BY e.created_at DESC, e.id ASC
      LIMIT ?
    )
    SELECT * FROM (
      SELECT * FROM latest_mappings
      UNION ALL
      SELECT * FROM latest_expressions
    )
    ORDER BY created_at DESC, id ASC
    LIMIT ?`;
}

feed.get('/hot', async (c) => {
  const releaseTablesReady = await dictionaryReleaseSchemaAvailable(c.env.DB);
  const edgePredicate = releaseTablesReady ? ` WHERE ${edgeEligibilityPredicate('ed')}` : '';
  const sql = releaseTablesReady
    ? packedHotSql(edgePredicate)
    : `SELECT ${EDGE_COLUMNS}
       FROM all_expression_edges ed
       JOIN all_expression_rows a ON a.id = ed.expression_a_id
       JOIN all_expression_rows b ON b.id = ed.expression_b_id
       ${edgePredicate}
       ORDER BY ed.score DESC, ed.created_at DESC, ed.id ASC
       LIMIT ?`;
  const { results } = await c.env.DB.prepare(
    sql,
  ).bind(parseLimit(c.req.query('limit'))).all<{ a_lang: string; b_lang: string }>();
  const hints = parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale'));
  const names = await resolveLanguageNames(c.env.DB, [...new Set(results.flatMap((row) => [row.a_lang, row.b_lang]))], hints);
  return success(c, results.map((row) => ({ ...row, a_language_name: names.get(row.a_lang) ?? row.a_lang, b_language_name: names.get(row.b_lang) ?? row.b_lang })));
});

feed.get('/new', async (c) => {
  const limit = parseLimit(c.req.query('limit'));
  const releaseTablesReady = await dictionaryReleaseSchemaAvailable(c.env.DB);
  const mappingPredicate = releaseTablesReady ? ` WHERE ${edgeEligibilityPredicate('ed')}` : '';
  const sql = releaseTablesReady
    ? packedNewSql(mappingPredicate)
    : `WITH latest_mappings AS (
       SELECT 'mapping' AS type, ed.id AS id, ed.created_at, u.username AS author,
              a.id AS a_id, b.id AS b_id,
              a.text AS left_text, a.lang_code AS left_lang,
              b.text AS right_text, b.lang_code AS right_lang
       FROM all_expression_edges ed
       JOIN all_expression_rows a ON a.id = ed.expression_a_id
       JOIN all_expression_rows b ON b.id = ed.expression_b_id
       LEFT JOIN users u ON u.id = ed.created_by
       ${mappingPredicate}
       ORDER BY ed.created_at DESC, ed.id ASC
       LIMIT ?
     ), latest_expressions AS (
       SELECT 'expression' AS type, e.id, e.created_at, u.username AS author,
              NULL AS a_id, NULL AS b_id,
              e.text AS left_text, e.lang_code AS left_lang, NULL AS right_text, NULL AS right_lang
       FROM all_expression_rows e
       LEFT JOIN users u ON u.id = e.created_by
       ORDER BY e.created_at DESC, e.id ASC
       LIMIT ?
     )
     SELECT * FROM (
       SELECT * FROM latest_mappings
       UNION ALL
       SELECT * FROM latest_expressions
     )
     ORDER BY created_at DESC, id ASC
     LIMIT ?`;
  const { results } = await c.env.DB.prepare(
    sql,
  ).bind(limit, limit, limit).all<{ left_lang: string | null; right_lang: string | null }>();
  const hints = parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale'));
  const names = await resolveLanguageNames(c.env.DB, [...new Set(results.flatMap((row) => [row.left_lang, row.right_lang]).filter((code): code is string => Boolean(code)))], hints);
  return success(c, results.map((row) => ({
    ...row,
    left_language_name: row.left_lang ? names.get(row.left_lang) ?? row.left_lang : null,
    right_language_name: row.right_lang ? names.get(row.right_lang) ?? row.right_lang : null,
  })));
});

export default feed;
