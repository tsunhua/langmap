import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `tester-${unique}`, email: `${unique}@example.com`, password: 'pass1234' }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

async function createExpression(token: string, text: string, lang = 'nan'): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ lang_code: lang, text }),
  });
  const body = (await res.json()) as { data: { expression: { id: string } } };
  return body.data.expression.id;
}

async function getAdminToken(): Promise<string> {
  const username = `admin-${Date.now()}`;
  const res = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username, email: `${username}@example.com`, password: 'pass1234' }),
  });
  const body = (await res.json()) as { data: { token: string; user: { id: number; username: string } } };
  const fs = await import('node:fs');
  const dbFile = fs.readdirSync('.wrangler/state/v3/d1/miniflare-D1DatabaseObject').find((f) => f.endsWith('.sqlite'));
  if (!dbFile) throw new Error('D1 sqlite not found');
  const { DatabaseSync } = await import('node:sqlite');
  const db = new DatabaseSync(`.wrangler/state/v3/d1/miniflare-D1DatabaseObject/${dbFile}`);
  db.exec(`UPDATE users SET role = 'admin' WHERE id = ${body.data.user.id}`);
  db.close();
  const { SignJWT } = await import('jose');
  const secretKey = process.env.SECRET_KEY
    ?? fs.readFileSync('.dev.vars', 'utf8').match(/SECRET_KEY="([^"]+)"/)?.[1]
    ?? 'dev-secret-change-me-before-deploy';
  return await new SignJWT({ id: body.data.user.id, username: body.data.user.username, role: 'admin' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(new TextEncoder().encode(secretKey));
}

describe('mappings API', () => {
  it('creates an edge between two expressions', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `邊測A${unique}`);
    const idB = await createExpression(token, `邊測B${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ target_expression_id: idB, source: 'contribution' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { edge: { expression_a_id: string; expression_b_id: string }; created: boolean } };
    expect(body.data.created).toBe(true);
    const [low, high] = [idA, idB].sort();
    expect(body.data.edge.expression_a_id).toBe(low);
    expect(body.data.edge.expression_b_id).toBe(high);
  });

  it('reuses an existing edge on duplicate submission', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `重用A${unique}`);
    const idB = await createExpression(token, `重用B${unique}`);
    const post = () =>
      fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ target_expression_id: idB, source: 'contribution' }),
      });
    const first = await post();
    const second = await post();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const firstBody = (await first.json()) as { data: { edge: { id: string }; created: boolean } };
    const secondBody = (await second.json()) as { data: { edge: { id: string }; created: boolean } };
    expect(firstBody.data.edge.id).toBe(secondBody.data.edge.id);
    expect(secondBody.data.created).toBe(false);
  });

  it('lists mappings for an expression with neighbor info', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `列表A${unique}`);
    const idB = await createExpression(token, `列表B${unique}`);
    await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ target_expression_id: idB, source: 'contribution' }),
    });
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { items: Array<{ edge_id: string; neighbor_id: string; neighbor_text: string; score: number }>; total: number; hasMore: boolean };
    };
    expect(body.data.total).toBeGreaterThanOrEqual(1);
    expect(body.data.items.some((item) => item.neighbor_id === idB)).toBe(true);
  });

  it('requires auth to create an edge', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/nan:fake/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ target_expression_id: 'eng:fake', source: 'contribution' }),
    });
    expect(res.status).toBe(401);
  });

  it('rejects identical endpoints', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `同點${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ target_expression_id: idA, source: 'contribution' }),
    });
    expect(res.status).toBe(400);
  });
});

describe('split API', () => {
  it('forbids non-admin users from splitting', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `權限A${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/split`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_ids: [] }),
    });
    expect(res.status).toBe(403);
  });

  it('rejects empty edge_ids from an admin', async () => {
    const adminToken = await getAdminToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(adminToken, `空邊A${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/split`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${adminToken}` },
      body: JSON.stringify({ edge_ids: [] }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('EXPRESSION_SPLIT_EMPTY');
  });
});
