import { Hono } from 'hono';
import { cors } from 'hono/cors';
import api from './routes';
import { createPgDatabase } from './db/pgDatabase';
import { addCacheHeaders } from './middleware/cacheHeaders';
import type { Bindings, Variables } from './types';

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

app.use('*', cors());
app.use('/api/v2/*', addCacheHeaders);
app.route('/api/v2', api);

app.onError((err, c) => {
  console.error('[route error]', err?.message, err?.stack);
  return c.json({ success: false, error: 'INTERNAL_SERVER_ERROR' }, 500);
});

// D1 → PostgreSQL cutover: DB now resolves to the Hyperdrive-backed pg adapter.
// The cast keeps the D1-shaped type across the codebase; the real type will be
// tightened once the migration is complete.
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const db = createPgDatabase(env.HYPERDRIVE.connectionString);
    const runtimeEnv = { ...env, DB: db } as unknown as Bindings;
    return app.fetch(request, runtimeEnv, ctx);
  },
};
