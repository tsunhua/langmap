import { defineConfig } from 'vitest/config';

// Integration tests share a single local Worker (127.0.0.1:8788) and the same
// local D1 database. The auth smoke test additionally shells out to
// `wrangler d1 execute`, which opens the D1 file directly. Running test files
// in parallel therefore corrupts ongoing HTTP connections (ECONNRESET) when the
// subprocess touches the database mid-request. Run files sequentially.
export default defineConfig({
  test: {
    fileParallelism: false,
  },
});
