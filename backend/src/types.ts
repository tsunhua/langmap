export interface Bindings {
  DB: D1Database;
  ASSETS: { fetch: typeof fetch };
  SECRET_KEY: string;
}

export interface Variables {
  user?: { id: number; username: string; role: string };
}
