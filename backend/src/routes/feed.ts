import { Hono } from 'hono';
import { success } from '../utils/response';
import { serializeIntegerId } from '../utils/ids';
import type { Bindings } from '../types';

const feed = new Hono<{ Bindings: Bindings }>();
const limitOf = (value: string | undefined) => Math.min(Math.max(Number.parseInt(value ?? '20', 10) || 20, 1), 100);

async function mappings(c: { env: Bindings; req: { query: (key: string) => string | undefined } }, order: 'hot' | 'new') {
  const limit = limitOf(c.req.query('limit')); const rows = await c.env.DB.prepare(
    `SELECT e.id,e.score,e.relation_mask,a.id AS a_id,a.text AS a_text,la.code AS a_lang,b.id AS b_id,b.text AS b_text,lb.code AS b_lang
     FROM expression_edges e JOIN expressions a ON a.id=e.expression_a_id JOIN languages la ON la.id=a.language_id JOIN expressions b ON b.id=e.expression_b_id JOIN languages lb ON lb.id=b.language_id
     ORDER BY ${order === 'hot' ? 'e.score DESC,e.id ASC' : 'e.id DESC'} LIMIT ?`,
  ).bind(limit).all<Record<string, number | string>>();
  return success(c as never, rows.results.map((row) => ({ ...row, id: serializeIntegerId(Number(row.id)), a_id: serializeIntegerId(Number(row.a_id)), b_id: serializeIntegerId(Number(row.b_id)), a_language_name: row.a_lang, b_language_name: row.b_lang })));
}

feed.get('/', (c) => mappings(c, c.req.query('sort') === 'new' ? 'new' : 'hot'));
feed.get('/hot', (c) => mappings(c, 'hot'));
feed.get('/new', (c) => mappings(c, 'new'));
export default feed;
