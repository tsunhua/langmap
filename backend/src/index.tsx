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

// DB resolves to the Hyperdrive-backed PostgreSQL adapter.
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const connectionString = (env as Env & { DATABASE_URL?: string }).DATABASE_URL ?? env.HYPERDRIVE?.connectionString;
    if (!connectionString) throw new Error("DATABASE_URL or HYPERDRIVE connection is required");
    const db = createPgDatabase(connectionString);
    const runtimeEnv = { ...env, DB: db } as Bindings;
    return app.fetch(request, runtimeEnv, ctx);
  },
};
