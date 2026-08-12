import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import { internalError } from '../src/utils/response';

describe('internalError', () => {
  it('never serializes an internal exception message', async () => {
    const app = new Hono();
    app.get('/', (c) => internalError(c, 'UNIQUE constraint failed: expressions.id'));

    const response = await app.request('http://example.test/');
    const body = await response.json();

    expect(response.status).toBe(500);
    expect(body).toEqual({
      success: false,
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error',
    });
    expect(JSON.stringify(body)).not.toContain('UNIQUE constraint failed');
  });
});
