import type { Database } from './db/database';

export type Bindings = Omit<Env, 'DB'> & {
  DB: Database;
  DATABASE_URL?: string;
  // Wrangler loads this Worker secret from .dev.vars locally and from the
  // production secret store after deployment; it is intentionally absent from
  // wrangler.jsonc and never exposed to the frontend.
  CLOUDFLARE_API_TOKEN: string;
};

export interface Variables {
  user?: { id: number; username: string; role: string };
}
