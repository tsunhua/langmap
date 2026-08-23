import { Hono } from 'hono';
import { success } from '../utils/response';
import { parseLocaleHints, resolveLanguageNames } from '../services/localizedName';
import type { Bindings } from '../types';

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

feed.get('/hot', async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT ${EDGE_COLUMNS}
     FROM expression_edges ed
     JOIN expressions a ON a.id = ed.expression_a_id
     JOIN expressions b ON b.id = ed.expression_b_id
     ORDER BY ed.score DESC, ed.created_at DESC, ed.id ASC
     LIMIT ?`,
  ).bind(parseLimit(c.req.query('limit'))).all<{ a_lang: string; b_lang: string }>();
  const hints = parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale'));
  const names = await resolveLanguageNames(c.env.DB, [...new Set(results.flatMap((row) => [row.a_lang, row.b_lang]))], hints);
  return success(c, results.map((row) => ({ ...row, a_language_name: names.get(row.a_lang) ?? row.a_lang, b_language_name: names.get(row.b_lang) ?? row.b_lang })));
});

feed.get('/new', async (c) => {
  const limit = parseLimit(c.req.query('limit'));
  const { results } = await c.env.DB.prepare(
    `WITH latest_mappings AS (
       SELECT 'mapping' AS type, ed.id AS id, ed.created_at, u.username AS author,
              a.id AS a_id, b.id AS b_id,
              a.text AS left_text, a.lang_code AS left_lang,
              b.text AS right_text, b.lang_code AS right_lang
       FROM expression_edges ed
       JOIN expressions a ON a.id = ed.expression_a_id
       JOIN expressions b ON b.id = ed.expression_b_id
       LEFT JOIN users u ON u.id = ed.created_by
       ORDER BY ed.created_at DESC, ed.id ASC
       LIMIT ?
     ), latest_expressions AS (
       SELECT 'expression' AS type, e.id, e.created_at, u.username AS author,
              NULL AS a_id, NULL AS b_id,
              e.text AS left_text, e.lang_code AS left_lang, NULL AS right_text, NULL AS right_lang
       FROM expressions e
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
     LIMIT ?`,
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
