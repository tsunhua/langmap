import { Client, types, type QueryResult } from 'pg';
import type { Database, PreparedStatement } from './database';

// ── Normalize bigint → JS number (OID 20 = int8) ───────────────────────────
types.setTypeParser(20, (v: string | null) => (v === null ? null : Number(v)));

// ── Error normalization ──────────────────────────────────────────────────────
// Normalize unique violations for the application error contract.
function normalizePgError(error: unknown): unknown {
  if (error && typeof error === 'object' && (error as { code?: string }).code === '23505') {
    const message = (error as { message?: string }).message ?? 'duplicate key value';
    const wrapped = new Error(`${message} (unique violation)`);
    (wrapped as { code?: string }).code = '23505';
    return wrapped;
  }
  return error;
}

type QueryExecutor = (sql: string, params: unknown[]) => Promise<QueryResult>;

// Hyperdrive already pools origin connections. Cloudflare Workers must not keep
// a pg Client/Pool in module-global state because I/O objects cannot be reused
// safely across request contexts. Each createPgDatabase() call therefore owns
// one Client for one Worker invocation. Workers automatically clean up the
// Worker→Hyperdrive edge connection when the invocation ends.
function createRequestClient(connectionString: string) {
  let client: Client | null = null;
  let connectPromise: Promise<Client> | null = null;
  const getClient = async (): Promise<Client> => {
    if (client) return client;

    if (!connectPromise) {
      const next = new Client({
        connectionString,
        connectionTimeoutMillis: 15000,
        // Let PostgreSQL cancel genuinely slow statements. Keep the client-side
        // timeout longer than statement_timeout so the server gets the first
        // chance to return a useful 57014 error instead of "Query read timeout".
        statement_timeout: 30000,
        query_timeout: 45000,
        application_name: 'langmap-worker',
      });
      const started = Date.now();
      connectPromise = next.connect()
        .then(() => {
          client = next;
          const ms = Date.now() - started;
          if (ms > 2000) console.log(`[pg][connect] ${ms}ms`);
          return next;
        })
        .catch(async (error) => {
          connectPromise = null;
          try { await next.end(); } catch { /* connection never became usable */ }
          throw error;
        });
    }

    return connectPromise;
  };

  const execute: QueryExecutor = async (sql, params) => {
    const started = Date.now();
    const short = sql.replace(/\s+/g, ' ').slice(0, 180);
    let connectMs = 0;
    try {
      const connectStarted = Date.now();
      const active = await getClient();
      connectMs = Date.now() - connectStarted;
      const queryStarted = Date.now();
      const result = await active.query(sql, params);
      const queryMs = Date.now() - queryStarted;
      if (connectMs > 2000 || queryMs > 2500) {
        console.log(`[pg][slow] conn=${connectMs}ms query=${queryMs}ms rows=${result.rowCount ?? 0} ${short}`);
      }
      return result;
    } catch (error) {
      console.error(`[pg][error] total=${Date.now() - started}ms conn=${connectMs}ms ${short}`);
      console.error('[pg][error msg]', (error as { message?: string })?.message);
      throw normalizePgError(error);
    }
  };


  return { getClient, execute };
}

// ── Placeholder / dialect translation ────────────────────────────────────────
interface Segment { code: boolean; text: string }

function tokenize(sql: string): Segment[] {
  const segs: Segment[] = [];
  let segStart = 0;
  let inCode = true;
  let quote: string | null = null;
  let i = 0;

  const pushCode = (end: number) => {
    if (end > segStart) segs.push({ code: true, text: sql.slice(segStart, end) });
    segStart = end;
  };
  const pushNonCode = (end: number) => {
    if (end > segStart) segs.push({ code: false, text: sql.slice(segStart, end) });
    segStart = end;
  };

  while (i < sql.length) {
    const ch = sql[i];
    if (inCode) {
      if (sql.startsWith('--', i)) {
        pushCode(i); inCode = false; quote = null; segStart = i; i += 2;
      } else if (sql.startsWith('/*', i)) {
        pushCode(i); inCode = false; quote = null; segStart = i; i += 2;
      } else if (ch === "'" || ch === '"' || ch === '`') {
        pushCode(i); inCode = false; quote = ch; segStart = i; i++;
      } else {
        i++;
      }
    } else if (quote) {
      if (ch === quote) {
        i++;
        pushNonCode(i);
        inCode = true;
        quote = null;
      } else {
        i++;
      }
    } else {
      // comment (no quote); both DB flavors use backslash literally, so no
      // escape handling here — the first matching quote closes the string.
      if (sql.startsWith('*/', i)) {
        i += 2;
        pushNonCode(i);
        inCode = true;
      } else if (ch === '\n') {
        i++;
        pushNonCode(i);
        inCode = true;
      } else {
        i++;
      }
    }
  }
  pushCode(sql.length);
  return segs;
}

export function transformSql(sql: string): { pgSql: string; needsOnConflict: boolean } {
  const segs = tokenize(sql);
  let paramIdx = 1;

  for (const seg of segs) {
    if (!seg.code) continue;
    // The application contract uses positional placeholders; translate them
    // once at the adapter boundary so services stay database-agnostic.
    seg.text = seg.text.replace(/\?/g, () => `$${paramIdx++}`);
  }

  let pgSql = segs.map((s) => s.text).join('');
  pgSql = pgSql.replace(/\bLIKE (\$\d+)/g, 'ILIKE $1');
  return { pgSql, needsOnConflict: false };
}

// ── Statement wrapper (implements the application PreparedStatement contract) ───────────────────
function createStatement(execute: QueryExecutor, originalSql: string): PreparedStatement {
  let params: unknown[] = [];

  const stmt = {
    bind(...values: unknown[]) {
      params = values;
      return stmt;
    },

    async first<T = Record<string, unknown>>(): Promise<T | null> {
      const { pgSql } = transformSql(originalSql);
      const { rows } = await execute(pgSql, params);
      return (rows[0] as T) ?? null;
    },

    async all<T = Record<string, unknown>>() {
      const { pgSql } = transformSql(originalSql);
      const { rows } = await execute(pgSql, params);
      return { results: rows as T[], success: true, meta: {} };
    },

    async run() {
      const { pgSql } = transformSql(originalSql);
      let finalSql = pgSql;
      if (/^\s*INSERT\b/i.test(finalSql) && !/\bRETURNING\b/i.test(finalSql)) finalSql += ' RETURNING *';
      const { rows, rowCount } = await execute(finalSql, params);
      const lastRowId =
        rows.length > 0 && typeof rows[0] === 'object' && 'id' in rows[0]
          ? Number((rows[0] as Record<string, unknown>).id)
          : 0;
      return { success: true, meta: { last_row_id: lastRowId, changes: rowCount ?? 0 } };
    },

    // expose internals for batch
    _sql: originalSql,
    _params: () => params,
  };

  return stmt;
}

// ── Public factory ───────────────────────────────────────────────────────────
// The underlying Client is request-scoped and PostgreSQL is the only runtime
// database implementation.
export function createPgDatabase(connectionString: string): Database {
  const requestClient = createRequestClient(connectionString);

  return {
    prepare(sql: string) {
      return createStatement(requestClient.execute, sql);
    },

    async batch(statements: PreparedStatement[]) {
      const client = await requestClient.getClient();
      try {
        await client.query('BEGIN');
        const results: unknown[] = [];
        for (const stmt of statements) {
          const { pgSql } = transformSql(stmt._sql);
          const finalSql = pgSql;
          // Batch callers do not consume last_row_id, so do not append RETURNING.
          const { rows, rowCount } = await requestClient.execute(finalSql, stmt._params());
          results.push({ results: rows, meta: { changes: rowCount }, success: true });
        }
        await client.query('COMMIT');
        return results;
      } catch (error) {
        try { await client.query('ROLLBACK'); } catch { /* ignore rollback error */ }
        throw normalizePgError(error);
      }
    }
  };
}
