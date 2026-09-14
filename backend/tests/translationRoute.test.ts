import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Hono } from 'hono';
import { SignJWT } from 'jose';
import type { Ai, D1Database } from '@cloudflare/workers-types';
import translation from '../src/routes/translation';
import { envelopeLine, runTranslation } from '../src/services/translation/orchestrator';

vi.mock('../src/services/translation/orchestrator', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../src/services/translation/orchestrator')>();
  return { ...actual, runTranslation: vi.fn() };
});

const runTranslationMock = vi.mocked(runTranslation);

const SECRET_KEY = 'test-secret';
const USER_SQL = 'SELECT id, username, role FROM users WHERE id = ?';
const LANG_SQL = 'SELECT id FROM languages WHERE code=?';
const LOCALE_SQL = `SELECT ll.id AS id, ll.language_id AS language_id, l.code AS lang_code
FROM language_locales ll
JOIN languages l ON l.id = ll.language_id
WHERE ll.code = ?`;

type Handler = (args: unknown[]) => unknown;

const LANGUAGES: Record<string, { id: number }> = { nan: { id: 1 }, jpn: { id: 3 }, eng: { id: 4 } };
const LOCALES: Record<string, { id: number; language_id: number; lang_code: string }> = {
  'jpn-Jpan-JP': { id: 10, language_id: 3, lang_code: 'jpn' },
  'eng-Latn-US': { id: 11, language_id: 4, lang_code: 'eng' },
  'yue-Hant-HK': { id: 12, language_id: 99, lang_code: 'yue' },
};

function fakeD1(overrides: Record<string, Handler> = {}): D1Database {
  const handlers: Record<string, Handler> = {
    [USER_SQL]: () => ({ id: 1, username: 'tester', role: 'user' }),
    [LANG_SQL]: (args) => LANGUAGES[args[0] as string] ?? null,
    [LOCALE_SQL]: (args) => LOCALES[args[0] as string] ?? null,
    ...overrides,
  };
  const prepare = (sql: string) => ({
    bind: (...args: unknown[]) => ({
      async first<T>() {
        return (handlers[sql]?.(args) ?? null) as T;
      },
      async run() {
        return { success: true };
      },
      async all<T>() {
        return { results: [] as T };
      },
    }),
  });
  return { prepare } as unknown as D1Database;
}

const fakeAI = {} as Ai;

async function authenticate(): Promise<string> {
  return new SignJWT({ id: 1, username: 'tester', role: 'user' })
    .setProtectedHeader({ alg: 'HS256' })
    .sign(new TextEncoder().encode(SECRET_KEY));
}

interface PostOptions {
  body?: BodyInit | null;
  token?: string | null;
  headers?: Record<string, string>;
  db?: D1Database;
  rawBody?: boolean;
}

async function post(options: PostOptions = {}): Promise<Response> {
  const app = new Hono<{ Bindings: { DB: D1Database; SECRET_KEY: string; AI: Ai } }>();
  app.route('/translate', translation);
  const env = { DB: options.db ?? fakeD1(), SECRET_KEY, AI: fakeAI };
  const token = options.token === undefined ? await authenticate() : options.token;
  const headers: Record<string, string> = { 'content-type': 'application/json', ...options.headers };
  if (token) headers.authorization = `Bearer ${token}`;
  const body = options.body === undefined ? JSON.stringify({ text: '你好', target_locale_code: 'jpn-Jpan-JP' }) : options.body;
  if (options.rawBody && body instanceof ReadableStream) {
    const request = new Request('http://example.test/translate', {
      method: 'POST',
      headers,
      body,
      // Node's fetch requires duplex for a streamed body.
      duplex: 'half',
    } as RequestInit);
    return app.request(request, undefined, env);
  }
  return app.request('http://example.test/translate', { method: 'POST', headers, body }, env);
}

async function jsonError(response: Response): Promise<string | undefined> {
  const body = (await response.json()) as { error?: string };
  return body.error;
}

beforeEach(() => {
  runTranslationMock.mockReset();
});

describe('POST /translate auth', () => {
  it('rejects unauthenticated requests with AUTH_REQUIRED and leaks no text', async () => {
    const response = await post({ token: null, body: JSON.stringify({ text: '不需要洩漏的文字', target_locale_code: 'jpn-Jpan-JP' }) });
    expect(response.status).toBe(401);
    const body = (await response.json()) as { error: string; data?: unknown };
    expect(body.error).toBe('AUTH_REQUIRED');
    expect(JSON.stringify(body)).not.toContain('不需要洩漏的文字');
    expect(runTranslationMock).not.toHaveBeenCalled();
  });
});

describe('POST /translate body limits', () => {
  it('rejects a body larger than 16 KiB with PAYLOAD_TOO_LARGE', async () => {
    const body = JSON.stringify({ text: 'a'.repeat(20000), target_locale_code: 'jpn-Jpan-JP' });
    const response = await post({ body });
    expect(response.status).toBe(413);
    expect(await jsonError(response)).toBe('PAYLOAD_TOO_LARGE');
    expect(runTranslationMock).not.toHaveBeenCalled();
  });

  it('short-circuits on an over-cap Content-Length header without reading the body', async () => {
    const response = await post({
      body: JSON.stringify({ text: '好', target_locale_code: 'jpn-Jpan-JP' }),
      headers: { 'content-length': '999999' },
    });
    expect(response.status).toBe(413);
    expect(await jsonError(response)).toBe('PAYLOAD_TOO_LARGE');
  });

  it('rejects an over-cap streamed body as it is read', async () => {
    const stream = new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(new Uint8Array(20000).fill(65));
        controller.close();
      },
    });
    const response = await post({ body: stream, rawBody: true, headers: {}, token: await authenticate() });
    expect(response.status).toBe(413);
    expect(await jsonError(response)).toBe('PAYLOAD_TOO_LARGE');
  });

  it('rejects malformed JSON with VALIDATION_FAILED', async () => {
    const response = await post({ body: '{not json' });
    expect(response.status).toBe(400);
    expect(await jsonError(response)).toBe('VALIDATION_FAILED');
  });

  it('rejects an empty body with VALIDATION_FAILED', async () => {
    const response = await post({ body: '' });
    expect(response.status).toBe(400);
    expect(await jsonError(response)).toBe('VALIDATION_FAILED');
  });
});

describe('POST /translate validation mapping', () => {
  it('rejects more than 500 graphemes with VALIDATION_FAILED', async () => {
    const response = await post({ body: JSON.stringify({ text: 'a'.repeat(501), target_locale_code: 'jpn-Jpan-JP' }) });
    expect(response.status).toBe(400);
    expect(await jsonError(response)).toBe('VALIDATION_FAILED');
  });

  it('rejects HTML tags with PLAIN_TEXT_ONLY', async () => {
    const response = await post({ body: JSON.stringify({ text: '<b>hi</b>', target_locale_code: 'jpn-Jpan-JP' }) });
    expect(response.status).toBe(400);
    expect(await jsonError(response)).toBe('PLAIN_TEXT_ONLY');
  });

  it('rejects fenced Markdown with PLAIN_TEXT_ONLY', async () => {
    const response = await post({ body: JSON.stringify({ text: '```\ncode\n```', target_locale_code: 'jpn-Jpan-JP' }) });
    expect(response.status).toBe(400);
    expect(await jsonError(response)).toBe('PLAIN_TEXT_ONLY');
  });

  it('rejects an unknown source_lang_code with INVALID_LANG_CODE', async () => {
    const response = await post({ body: JSON.stringify({ text: '你好', source_lang_code: 'zzz', target_locale_code: 'jpn-Jpan-JP' }) });
    expect(response.status).toBe(400);
    expect(await jsonError(response)).toBe('INVALID_LANG_CODE');
  });

  it('rejects a source locale that mismatches the source language with INVALID_LANGUAGE_LOCALE_CODE', async () => {
    const response = await post({
      body: JSON.stringify({
        text: '你好',
        source_lang_code: 'nan',
        source_locale_code: 'yue-Hant-HK',
        target_locale_code: 'jpn-Jpan-JP',
      }),
    });
    expect(response.status).toBe(400);
    expect(await jsonError(response)).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('returns 404 TARGET_LOCALE_NOT_FOUND for an unknown target locale', async () => {
    const response = await post({ body: JSON.stringify({ text: '你好', target_locale_code: 'xxx-Yyy-ZZ' }) });
    expect(response.status).toBe(404);
    expect(await jsonError(response)).toBe('TARGET_LOCALE_NOT_FOUND');
  });
});

describe('POST /translate streaming', () => {
  it('streams NDJSON envelopes produced by the orchestrator without emitting its own status', async () => {
    runTranslationMock.mockImplementation(async (_env, request, ctx) => {
      ctx.emit(envelopeLine({ type: 'status', stage: 'retrieving', mode: 'exact_lookup', request_id: request.requestId }));
      ctx.emit(envelopeLine({
        type: 'evidence',
        items: [{
          source_text: '你好',
          target_text: 'こんにちは',
          target_locale_code: 'jpn-Jpan-JP',
          path_type: 'direct',
          match_type: 'exact',
          source_markers: [],
        }],
        omitted_count: 0,
        degraded: false,
      }));
      ctx.emit(envelopeLine({
        type: 'result',
        request_id: request.requestId,
        translation: 'こんにちは',
        alternatives: [],
        source_lang_code: 'cmn',
        target_locale_code: 'jpn-Jpan-JP',
        evidence_present: true,
        model_only: false,
        resolution: 'exact_lookup',
        generation_skipped: true,
      }));
    });

    const response = await post();
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('application/x-ndjson; charset=utf-8');
    expect(response.headers.get('cache-control')).toBe('no-store');

    const events = (await response.text()).trim().split('\n').map((line) => JSON.parse(line) as { success: boolean; data: { type: string } });
    expect(events.map((event) => event.data.type)).toEqual(['status', 'evidence', 'result']);
    expect(events.every((event) => event.success)).toBe(true);

    const statuses = events.filter((event) => event.data.type === 'status');
    expect(statuses).toHaveLength(1);
    const calledRequest = runTranslationMock.mock.calls[0][1];
    expect((statuses[0].data as { request_id?: string }).request_id).toBe(calledRequest.requestId);
  });

  it('forwards an orchestrator error envelope unchanged', async () => {
    runTranslationMock.mockImplementation(async (_env, _request, ctx) => {
      ctx.emit(envelopeLine({ type: 'error', code: 'AI_PROVIDER_FAILED', retryable: true }));
    });

    const response = await post();
    expect(response.status).toBe(200);
    const events = (await response.text()).trim().split('\n').map((line) => JSON.parse(line) as { success: boolean; error?: string; retryable?: boolean });
    expect(events).toHaveLength(1);
    expect(events[0]).toMatchObject({ success: false, error: 'AI_PROVIDER_FAILED', retryable: true });
  });

  it('wires a client stream cancel to the orchestrator abort signal', async () => {
    let capturedSignal: AbortSignal | undefined;
    runTranslationMock.mockImplementation((_env, _request, ctx) => {
      capturedSignal = ctx.signal;
      return new Promise<void>(() => {});
    });

    const response = await post();
    expect(response.status).toBe(200);
    expect(capturedSignal?.aborted).toBe(false);

    const reader = response.body!.getReader();
    await reader.cancel();
    expect(capturedSignal?.aborted).toBe(true);
  });
});
