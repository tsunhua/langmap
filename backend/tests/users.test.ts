import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

interface ProfileBody {
  success: boolean;
  data: { user: { id: number; username: string; email: string; role: string; created_at: string } };
}

async function register(): Promise<{ token: string; username: string; email: string }> {
  const unique = Math.random().toString(36).slice(2, 10);
  const registerResponse = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username: `tester-${unique}`,
      email: `${unique}@example.com`,
      password: 'pass1234',
    }),
  });
  expect(registerResponse.status).toBe(201);
  const body = (await registerResponse.json()) as { data: { token: string } };
  return { token: body.data.token, username: `tester-${unique}`, email: `${unique}@example.com` };
}

describe('v2 users', () => {
  it('returns 401 without auth token', async () => {
    const response = await fetch(`${BASE_URL}/api/v2/users/me`);
    expect(response.status).toBe(401);
  });

  it('returns the user profile for an authenticated user', async () => {
    const { token, username, email } = await register();

    const profileResponse = await fetch(`${BASE_URL}/api/v2/users/me`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(profileResponse.status).toBe(200);
    const body = (await profileResponse.json()) as ProfileBody;
    expect(body.success).toBe(true);
    expect(body.data.user.username).toBe(username);
    expect(body.data.user.email).toBe(email);
    expect(body.data.user.role).toBe('user');
    expect(body.data.user.created_at).toBeDefined();
    expect(Number.isInteger(body.data.user.id)).toBe(true);
  });

  it('keeps the profile available after creating contributions', async () => {
    const { token, username } = await register();

    const unique = Math.random().toString(36).slice(2, 10);
    const batchResponse = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        expressions: [
          { lang_code: 'cmn', text: `測試-${unique}` },
          { lang_code: 'eng', text: `test-${unique}` },
        ],
      }),
    });
    expect(batchResponse.status).toBe(201);

    const profileResponse = await fetch(`${BASE_URL}/api/v2/users/me`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(profileResponse.status).toBe(200);
    const body = (await profileResponse.json()) as ProfileBody;
    expect(body.data.user.username).toBe(username);
    expect(body.data.user.role).toBe('user');
  });
});