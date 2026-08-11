import { Hono } from 'hono';
import { paginated } from '../utils/response';
import { parseReferenceQuery, queryReferenceTable, type ReferenceTable } from '../services/languageIdentity';
import type { Bindings } from '../types';

const languageRegistry = new Hono<{ Bindings: Bindings }>();

function parseQs(c: { req: { query: (k: string) => string | undefined } }) {
  return {
    q: c.req.query('q'),
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  };
}

async function respond(c: Parameters<Parameters<typeof languageRegistry.get>[1]>[0], table: ReferenceTable) {
  const query = parseReferenceQuery(parseQs(c));
  const { items, total } = await queryReferenceTable(c.env.DB, table, query);
  return paginated(c, items, total, query.offset, query.limit);
}

languageRegistry.get('/languages', (c) => respond(c, 'languages'));
languageRegistry.get('/scripts', (c) => respond(c, 'scripts'));
languageRegistry.get('/regions', (c) => respond(c, 'regions'));

export default languageRegistry;
