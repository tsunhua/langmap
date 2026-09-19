/**
 * The application database contract.  PostgreSQL is the only runtime
 * implementation; keeping this small interface prevents routes and services
 * from depending on a provider SDK.
 */
export interface PreparedStatement {
  bind(...values: unknown[]): PreparedStatement;
  first<T = Record<string, unknown>>(): Promise<T | null>;
  all<T = Record<string, unknown>>(): Promise<{ results: T[]; success: boolean; meta: Record<string, unknown> }>;
  run(): Promise<{ success: boolean; meta: { last_row_id: number; changes: number } }>;
  readonly _sql: string;
  _params(): unknown[];
}

export interface Database {
  prepare(sql: string): PreparedStatement;
  batch(statements: PreparedStatement[]): Promise<unknown[]>;
}
