import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `contrib-${unique}`, email: `contrib-${unique}@example.com`, password: 'pass1234' }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

describe('contributions API', () => {
  it('requires auth', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ expressions: [] }),
    });
    expect(res.status).toBe(401);
  });

  it('rejects a batch with fewer than two expressions', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ expressions: [{ lang_code: 'eng', text: 'lonely' }] }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('CONTRIBUTION_TOO_FEW_EXPRESSIONS');
  });

  it('creates a clique from three expressions', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 8);
    const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({
        expressions: [
          { lang_code: 'eng', text: `water-${unique}` },
          { lang_code: 'cmn', text: `水-${unique}` },
          { lang_code: 'nan', text: `水泉-${unique}` },
        ],
      }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as {
      data: { expressions: unknown[]; edges: unknown[]; created_edge_count: number };
    };
    expect(body.data.expressions).toHaveLength(3);
    expect(body.data.edges).toHaveLength(3);
    expect(body.data.created_edge_count).toBe(3);
  });

  it('reuses duplicate pairs on a repeated batch', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 8);
    const payload = {
      expressions: [
        { lang_code: 'eng', text: `reuse-${unique}` },
        { lang_code: 'cmn', text: `重用-${unique}` },
      ],
    };
    const post = () =>
      fetch(`${BASE_URL}/api/v2/contributions/batch`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify(payload),
      });

    const first = (await (await post()).json()) as { data: { created_edge_count: number } };
    const second = (await (await post()).json()) as { data: { created_edge_count: number } };
    expect(first.data.created_edge_count).toBe(1);
    expect(second.data.created_edge_count).toBe(0);
  });
});
