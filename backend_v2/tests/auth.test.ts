import { execFileSync } from 'node:child_process';
import { describe, expect, it } from 'vitest';

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const BASE_URL = 'http://127.0.0.1:8788';

describe('v2 auth smoke', () => {
  it('exposes a health endpoint under /api/v2', async () => {
    const response = await fetch(`${BASE_URL}/api/v2/auth/health`);
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.success).toBe(true);
  });

  it('reuses an existing expression instead of creating a duplicate when the same text/lang is submitted again', async () => {
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
    const registerBody = await registerResponse.json();
    const token = registerBody.data.token;

    const query = "SELECT COUNT(*) as c FROM expressions WHERE text = '你好' AND language_code = 'zh-CN';";
    const beforeOutput = execFileSync('npx', ['wrangler', 'd1', 'execute', 'langmap-v2', '--local', '--command', query], {
      cwd: process.cwd(),
      encoding: 'utf-8',
    });
    const beforeCount = Number(beforeOutput.match(/"c":\s*(\d+)/)?.[1] || 0);

    const response = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        expressions: [
          { lang: 'zh-CN', text: '你好' },
          { lang: 'en-US', text: 'Hello' },
        ],
      }),
    });

    expect(response.status).toBe(200);

    const afterOutput = execFileSync('npx', ['wrangler', 'd1', 'execute', 'langmap-v2', '--local', '--command', query], {
      cwd: process.cwd(),
      encoding: 'utf-8',
    });
    const afterCount = Number(afterOutput.match(/"c":\s*(\d+)/)?.[1] || 0);

    expect(afterCount).toBe(beforeCount);
  });
});
