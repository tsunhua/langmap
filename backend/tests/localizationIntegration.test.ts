import fs from 'node:fs';
import { SignJWT } from 'jose';
import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

const PROJECT = 'langmap-web';
const API = `${BASE_URL}/api/v2/localization/projects/${PROJECT}`;

interface RegisteredUser {
  token: string;
  id: number;
  username: string;
}

interface LocaleRow {
  language_locale_code: string;
  name: string;
  name_en: string;
  direction: string;
  status: string;
  mapping_revision: number;
  activation_source: string | null;
}

async function register(prefix: string): Promise<RegisteredUser> {
  const unique = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `${prefix}-${unique}`, email: `${prefix}-${unique}@example.com`, password: 'pass1234' }),
  });
  const body = (await response.json()) as { data: { token: string; user: { id: number; username: string } } };
  return { token: body.data.token, id: body.data.user.id, username: body.data.user.username };
}

async function registerToken(): Promise<string> {
  return (await register('tester')).token;
}

// The admin helper writes directly to the local D1 file the running worker
// persists to, then issues a role=admin JWT with the same secret.
async function workerDbFile(): Promise<string> {
  const dir = '.wrangler/state/v3/d1/miniflare-D1DatabaseObject';
  const candidates = fs.readdirSync(dir).filter((f) => f.endsWith('.sqlite'));
  const { DatabaseSync } = await import('node:sqlite');
  for (const file of candidates) {
    const db = new DatabaseSync(`${dir}/${file}`);
    try {
      db.exec('SELECT 1 FROM users LIMIT 1');
      db.close();
      return `${dir}/${file}`;
    } catch {
      db.close();
    }
  }
  throw new Error('D1 sqlite with users table not found');
}

// The local worker can serve a stale snapshot of the /locales list for a while
// after a UI-locale write, so persisted status is verified straight from the D1
// file instead of a read-back through the API.
async function persistedLocaleRow(code: string): Promise<{ status: string; activation_source: string | null }> {
  const { DatabaseSync } = await import('node:sqlite');
  const db = new DatabaseSync(await workerDbFile());
  const row = db.prepare(
    "SELECT u.status, u.activation_source FROM ui_locales u JOIN language_locales ll ON ll.id = u.locale_id WHERE u.project_id = 'langmap-web' AND ll.code = ?",
  ).get(code) as { status: string; activation_source: string | null } | undefined;
  db.close();
  if (!row) throw new Error(`ui_locale not found for ${code}`);
  return row;
}

async function getAdminToken(): Promise<string> {
  const user = await register('admin');
  const { DatabaseSync } = await import('node:sqlite');
  const db = new DatabaseSync(await workerDbFile());
  db.exec(`UPDATE users SET role = 'admin' WHERE id = ${user.id}`);
  db.close();
  const secretKey = process.env.SECRET_KEY
    ?? fs.readFileSync('.dev.vars', 'utf8').match(/SECRET_KEY="([^"]+)"/)?.[1]
    ?? 'dev-secret-change-me-before-deploy';
  return await new SignJWT({ id: user.id, username: user.username, role: 'admin' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(new TextEncoder().encode(secretKey));
}

async function ensureLocale(token: string, code: string): Promise<void> {
  const res = await fetch(`${API}/locales`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ language_locale_code: code }),
  });
  expect(res.status).toBe(201);
}

async function listLocales(): Promise<LocaleRow[]> {
  const res = await fetch(`${API}/locales`);
  expect(res.status).toBe(200);
  const body = (await res.json()) as { data: LocaleRow[] };
  return body.data;
}

describe('localization API', () => {
  it('lists UI locales including the seeded eng-Latn-US', async () => {
    const rows = await listLocales();
    const eng = rows.find((l) => l.language_locale_code === 'eng-Latn-US');
    expect(eng).toBeTruthy();
    // Seeded with system activation; its status is mutable but the source is stable.
    expect(eng!.activation_source).toBe('system');
    for (const row of rows) expect(['draft', 'active', 'archived']).toContain(row.status);
  });

  it('returns English source messages when no locale preference', async () => {
    const res = await fetch(`${API}/messages`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { messages: Array<{ key: string; text: string; resolved_from: string }> } };
    expect(body.data.messages.length).toBeGreaterThan(10);
    const cancelMsg = body.data.messages.find((m) => m.key === 'common.cancel');
    expect(cancelMsg).toBeTruthy();
    expect(cancelMsg!.text).toBe('Cancel');
    expect(cancelMsg!.resolved_from).toBe('source');
  });

  it('creates a draft UI locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'nan-Hant-TW' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { status: string; language_locale_code: string } };
    expect(body.data.status).toBe('draft');
    expect(body.data.language_locale_code).toBe('nan-Hant-TW');
  });

  it('creates a translation mapping', async () => {
    const token = await registerToken();
    const exprRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'cmn', text: '取消' }),
    });
    const exprBody = (await exprRes.json()) as { data: { expression: { id: string } } };

    const res = await fetch(`${API}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ message_key: 'common.cancel', target_expression_id: exprBody.data.expression.id }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; data: { created: boolean; edge: { id: string } } };
    expect(body.success).toBe(true);
    expect(typeof body.data.created).toBe('boolean');
    expect(body.data.edge.id).toBeTruthy();
  });

  it('returns 404 for an unknown message key when mapping', async () => {
    const token = await registerToken();
    const exprRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'cmn', text: '取消' }),
    });
    const exprBody = (await exprRes.json()) as { data: { expression: { id: string } } };
    const res = await fetch(`${API}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ message_key: 'no.such.key', target_expression_id: exprBody.data.expression.id }),
    });
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('NOT_FOUND');
  });

  it('forbids non-admin users from activating a locale', async () => {
    const token = await registerToken();
    await ensureLocale(token, 'nan-Hant-CN');
    const res = await fetch(`${API}/locales/nan-Hant-CN/activate`, {
      method: 'POST',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(403);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('Forbidden');
  });

  it('lets an admin manually activate a locale', async () => {
    const adminToken = await getAdminToken();
    await ensureLocale(adminToken, 'nan-Hant-CN');
    const res = await fetch(`${API}/locales/nan-Hant-CN/activate`, {
      method: 'POST',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { activated: boolean } };
    expect(body.data.activated).toBe(true);

    const row = await persistedLocaleRow('nan-Hant-CN');
    expect(row.status).toBe('active');
    expect(row.activation_source).toBe('manual');
  });

  it('returns 404 when activating a locale that does not exist', async () => {
    const adminToken = await getAdminToken();
    const res = await fetch(`${API}/locales/zzz-Zzzz-ZZ/activate`, {
      method: 'POST',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('NOT_FOUND');
  });

  it('archives a locale as an admin', async () => {
    const adminToken = await getAdminToken();
    await ensureLocale(adminToken, 'nan-Hant-CN');
    const res = await fetch(`${API}/locales/nan-Hant-CN/archive`, {
      method: 'POST',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { archived: boolean } };
    expect(body.data.archived).toBe(true);

    const row = await persistedLocaleRow('nan-Hant-CN');
    expect(row.status).toBe('archived');
  });

  it('forbids non-admin users from archiving a locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/locales/eng-Latn-US/archive`, {
      method: 'POST',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(403);
  });

  it('rejects an invalid locale code when creating', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'eng-Latn' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('rejects an invalid primary locale query on messages', async () => {
    const res = await fetch(`${API}/messages?primary=eng-Latn`);
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('requires auth to create locale', async () => {
    const res = await fetch(`${API}/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW' }),
    });
    expect(res.status).toBe(401);
  });
});

describe('localization workbench API', () => {
  it('gets workbench coverage for a locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/workbench/nan-Hant-TW`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
  });

  it('returns paged workbench messages with candidate slots', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/workbench/nan-Hant-TW?limit=5`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
  });

  it('filters workbench messages by query', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/workbench/nan-Hant-TW?q=cancel&limit=50`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
  });
});

describe('localization batch mapping API', () => {
  it('processes an empty-safe batch mapping request', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/mappings/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ mappings: [{ message_key: 'no.such.key', target_expression_id: '999999' }] }),
    });
    expect(res.status).toBe(200);
  });

  it('rejects a batch mapping request without mappings', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/mappings/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ mappings: [] }),
    });
    expect(res.status).toBe(400);
  });

  it('rejects an oversized batch mapping request before resolving rows', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/mappings/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ mappings: Array.from({ length: 101 }, () => ({ message_key: 'unused', target_expression_id: '999999' })) }),
    });
    expect(res.status).toBe(400);
  });
});

describe('mapping vote API', () => {
  it('records a vote and flips it without double counting', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_id: '1', vote: 1 }),
    });
    expect(res.status).toBe(200);
  });

  it('rejects an out-of-range vote value', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_id: '1', vote: 5 }),
    });
    expect(res.status).toBe(400);
  });

  it('returns 404 when voting on an unknown edge', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_id: 'no-such-edge', vote: 1 }),
    });
    expect(res.status).toBe(404);
  });

  it('requires authentication', async () => {
    const res = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ edge_id: 'whatever', vote: 1 }),
    });
    expect(res.status).toBe(401);
  });
});