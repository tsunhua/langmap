import { Hono } from 'hono';
import type { Context, Next } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, notFoundCode, unauthorized } from '../utils/response';
import { MAX_TRANSLATION_BODY_BYTES } from '../utils/limits';
import { canonicalizeExpressionText } from '../services/expressionIdentity';
import {
  runTranslation,
  type RunTranslationRequest,
} from '../services/translation/orchestrator';
import {
  resolveSourceLanguage,
  resolveTargetLocale,
  utf8ByteLength,
  validateTranslationText,
  TranslationValidationError,
  type SourceLanguageResolution,
  type TargetLocaleResolution,
} from '../services/translation/validation';
import type { Bindings, Variables } from '../types';

const translation = new Hono<{ Bindings: Bindings; Variables: Variables }>();

const ENVELOPE_CODES = new Set([
  'VALIDATION_FAILED',
  'PLAIN_TEXT_ONLY',
  'INVALID_LANG_CODE',
  'INVALID_LANGUAGE_LOCALE_CODE',
]);

// requireAuth emits the generic "Unauthorized" envelope; the translation
// contract exposes AUTH_REQUIRED, so translate the middleware outcome here
// without changing the shared auth middleware.
async function requireTranslationAuth(c: Context, next: Next): Promise<Response | void> {
  await requireAuth(c, async () => {});
  if (!c.get('user')) return unauthorized(c, 'AUTH_REQUIRED');
  await next();
}

type BoundedBody = { ok: true; text: string } | { ok: false; tooLarge: true };

async function readBoundedBody(c: Context, maxBytes: number): Promise<BoundedBody> {
  const declared = c.req.header('content-length');
  if (declared !== undefined) {
    const declaredBytes = Number.parseInt(declared, 10);
    if (Number.isFinite(declaredBytes) && declaredBytes > maxBytes) {
      return { ok: false, tooLarge: true };
    }
  }

  const raw = c.req.raw.body;
  if (!raw) return { ok: true, text: '' };

  const reader = raw.getReader();
  const decoder = new TextDecoder();
  let text = '';
  let bytes = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (!value) continue;
      const chunk = decoder.decode(value, { stream: true });
      bytes += utf8ByteLength(chunk);
      if (bytes > maxBytes) {
        await reader.cancel().catch(() => undefined);
        return { ok: false, tooLarge: true };
      }
      text += chunk;
    }
    text += decoder.decode();
  } finally {
    try {
      reader.releaseLock();
    } catch {
      // Reader already released by cancel; nothing left to do.
    }
  }
  return { ok: true, text };
}

function payloadTooLarge(c: Context) {
  return c.json({ success: false, error: 'PAYLOAD_TOO_LARGE', message: 'Request body too large' }, 413);
}

// Spec 8.1: every translation request/response is uncacheable, including the
// 400/401/404/413 failures produced before the stream exists.
translation.use('*', async (c, next) => {
  c.header('Cache-Control', 'no-store');
  await next();
});

translation.post('/', requireTranslationAuth, async (c) => {
  const body = await readBoundedBody(c, MAX_TRANSLATION_BODY_BYTES);
  if (!body.ok) return payloadTooLarge(c);

  let parsed: unknown;
  try {
    parsed = JSON.parse(body.text);
  } catch {
    return badRequest(c, 'VALIDATION_FAILED');
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    return badRequest(c, 'VALIDATION_FAILED');
  }
  const record = parsed as Record<string, unknown>;

  if (typeof record.text !== 'string') return badRequest(c, 'VALIDATION_FAILED');
  const text = record.text;
  const sourceLangInput = (record.source_lang_code === undefined ? null : record.source_lang_code) as string | null;
  const sourceLocaleInput = (record.source_locale_code === undefined ? null : record.source_locale_code) as string | null;
  const targetLocaleInput = record.target_locale_code as string;

  let source!: SourceLanguageResolution;
  let target!: TargetLocaleResolution;
  try {
    validateTranslationText(text);
    source = await resolveSourceLanguage(c.env.DB, {
      source_lang_code: sourceLangInput,
      source_locale_code: sourceLocaleInput,
    });
    target = await resolveTargetLocale(c.env.DB, targetLocaleInput);
  } catch (error) {
    if (error instanceof TranslationValidationError) {
      if (error.code === 'TARGET_LOCALE_NOT_FOUND') {
        // notFoundCode echoes its message arg as the error code (utils/response.ts).
        return notFoundCode(c, 'TARGET_LOCALE_NOT_FOUND', 'TARGET_LOCALE_NOT_FOUND');
      }
      if (ENVELOPE_CODES.has(error.code)) return badRequest(c, error.code);
    }
    // Only the validators/resolvers are expected to throw TranslationValidationError;
    // anything else (e.g. a D1 fault) is a server error, not a client error.
    throw error;
  }

  const canonicalText = canonicalizeExpressionText(text);
  const requestId = crypto.randomUUID();
  const controller = new AbortController();

  if (c.req.raw.signal.aborted) controller.abort();
  else c.req.raw.signal.addEventListener('abort', () => controller.abort(), { once: true });

  // quota reservation point

  const encoder = new TextEncoder();
  let streamController: ReadableStreamDefaultController<Uint8Array> | null = null;
  let closed = false;

  const readable = new ReadableStream<Uint8Array>({
    start(controller) {
      streamController = controller;
    },
    cancel() {
      controller.abort();
    },
  });

  const emit = (line: string): void => {
    if (closed || !streamController) return;
    try {
      streamController.enqueue(encoder.encode(line));
    } catch {
      // Stream already errored/closed; the orchestrator never rejects.
    }
  };

  const request: RunTranslationRequest = {
    text,
    canonicalText,
    sourceLangCode: source.source_lang_code,
    sourceLocaleCode: sourceLocaleInput,
    targetLocaleCode: targetLocaleInput,
    targetLocale: target,
    requestId,
  };

  void runTranslation(c.env, request, { signal: controller.signal, emit })
    .catch(() => controller.abort())
    .finally(() => {
      if (closed) return;
      closed = true;
      try {
        streamController?.close();
      } catch {
        // Already closed by a client cancel.
      }
    });

  c.header('Content-Type', 'application/x-ndjson; charset=utf-8');
  c.header('Cache-Control', 'no-store');
  return c.body(readable);
});

export default translation;
