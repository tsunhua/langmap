import { describe, expect, it } from 'vitest';

const BASE_URL = 'http://127.0.0.1:8788';

describe('v2 users', () => {
  it('returns 401 without auth token', async () => {
    const response = await fetch(`${BASE_URL}/api/v2/users/me`);
    expect(response.status).toBe(401);
  });

  it('returns user profile and activity for authenticated user', async () => {
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
    const { data: { token } } = await registerResponse.json();

    const profileResponse = await fetch(`${BASE_URL}/api/v2/users/me`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(profileResponse.status).toBe(200);
    const body = await profileResponse.json();
    expect(body.success).toBe(true);
    expect(body.data.user.username).toBe(`tester-${unique}`);
    expect(body.data.user.email).toBe(`${unique}@example.com`);
    expect(body.data.user.role).toBe('user');
    expect(body.data.user.created_at).toBeDefined();
    expect(Array.isArray(body.data.activity)).toBe(true);
  });

  it('returns activity after creating contributions', async () => {
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
    const { data: { token } } = await registerResponse.json();

    await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
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

    const profileResponse = await fetch(`${BASE_URL}/api/v2/users/me`, {
      headers: { authorization: `Bearer ${token}` },
    });
    const body = await profileResponse.json();
    expect(body.success).toBe(true);
    expect(body.data.activity.length).toBeGreaterThanOrEqual(1);
    expect(body.data.activity[0].type).toBeDefined();
    expect(body.data.activity[0].description).toBeDefined();
    expect(body.data.activity[0].created_at).toBeDefined();
  });
});
