import { defineConfig } from 'vitest/config';

// Integration tests share a single local Worker (127.0.0.1:8788) and one
// PostgreSQL test database. Keep files sequential because the auth smoke test
// performs database mutations while requests are in flight.
export default defineConfig({
  test: {
    fileParallelism: false,
  },
});
