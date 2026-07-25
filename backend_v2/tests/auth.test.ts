import { describe, expect, it } from 'vitest';

describe('v2 auth smoke', () => {
  it('exposes a health endpoint under /api/v2', async () => {
    const response = await fetch('http://127.0.0.1:8788/api/v2/auth/health');
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.success).toBe(true);
  });
});
