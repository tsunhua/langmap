import { describe, expect, it, vi } from 'vitest';
import type OpenAI from 'openai';
import type { D1Database } from '@cloudflare/workers-types';
import {
  GENERATION_TIMEOUT_MS,
  MAX_ALTERNATIVES,
  MAX_TRANSLATION_OUTPUT_TOKENS,
} from '../src/utils/limits';
import {
  envelopeLine,
  runTranslation,
  writeEnvelope,
  type RunTranslationRequest,
  type TranslationStreamContext,
} from '../src/services/translation/orchestrator';
import { TRANSLATION_MODEL } from '../src/services/translation/types';
import type {
  TranslationStreamErrorEvent,
  TranslationStreamEvent,
} from '../src/services/translation/types';

type Row = Record<string, unknown>;
type Handler = (sql: string, args: unknown[]) => Row[] | Promise<Row[]>;

interface StatementLog {
  sql: string;
  args: unknown[];
}

function fakeD1(handler: Handler, log: StatementLog[] = []): D1Database {
  return {
    prepare(sql: string) {
      return {
        bind(...args: unknown[]) {
          log.push({ sql, args });
          return {
            async all<T>() {
              return { results: ((await handler(sql, args)) ?? []) as T[] };
            },
            async first<T>() {
              return ((await handler(sql, args))?.[0] ?? null) as T;
            },
          };
        },
      };
    },
  } as unknown as D1Database;
}

interface RouteSetup {
  locale?: Row | null;
  targetLocales?: Row[];
  exactFixed?: { direct?: Row[]; twoHop?: Row[] };
  candidate?: Row[];
  retrieval?: { direct?: Row[] | ((args: unknown[]) => Row[] | Promise<Row[]>); twoHop?: Row[] };
  markers?: Row[];
}

const TARGET_LOCALE = 'jpn-Jpan-JP';
const LOCALE_ROW = { id: 30, language_id: 7, lang_code: 'jpn' };
const TARGET_LOCALE_RESOLUTION = { locale_id: 30, language_id: 7, lang_code: 'jpn' };

function route(setup: RouteSetup): Handler {
  return (sql, args) => {
    if (/FROM language_locales ll/.test(sql)) return setup.locale ? [setup.locale] : [];
    if (/FROM expression_locale_links ell/.test(sql)) return setup.targetLocales ?? [];
    const textRoot = /e\.text = \?/.test(sql);
    if (/JOIN expression_edges edge1 ON/.test(sql)) {
      return textRoot ? (setup.exactFixed?.twoHop ?? []) : (setup.retrieval?.twoHop ?? []);
    }
    if (/JOIN expression_edges edge ON/.test(sql)) {
      if (textRoot) return setup.exactFixed?.direct ?? [];
      const direct = setup.retrieval?.direct;
      return typeof direct === 'function' ? direct(args) : (direct ?? []);
    }
    if (/FROM expression_edge_sources es/.test(sql)) return setup.markers ?? [];
    if (/JOIN languages sl ON sl.id = e.language_id/.test(sql)) return setup.candidate ?? [];
    return [];
  };
}

function markerRow(edgeId: number, marker = '1'): Row {
  return { edge_id: edgeId, source_name: 'Cobuild', marker };
}

function expr(id: number, text: string): Row {
  return { expression_id: id, expression_text: text };
}

function exactDirectRow(overrides: Row = {}): Row {
  return {
    edge_id: 11,
    source_expr_id: 1,
    source_text: 'Hello',
    source_lang_code: 'eng',
    target_expr_id: 2,
    target_text: 'こんにちは',
    score: 5,
    marker_count: 1,
    ...overrides,
  };
}

function exactTwoHopRow(overrides: Row = {}): Row {
  return {
    source_expr_id: 10,
    source_text: 'Hello',
    source_lang_code: 'eng',
    pivot_expr_id: 11,
    pivot_text: 'hola',
    pivot_lang_code: 'spa',
    edge1_id: 21,
    edge1_score: 4,
    edge1_markers: 1,
    edge2_id: 22,
    edge2_score: 3,
    edge2_markers: 1,
    target_expr_id: 12,
    target_text: 'こんにちは',
    ...overrides,
  };
}

function retrievalDirectRow(overrides: Row = {}): Row {
  return {
    edge_id: 11,
    score: 1,
    marker_count: 0,
    target_expr_id: 999,
    target_text: 'こんにちは',
    ...overrides,
  };
}

const EMPTY_EXACT: RouteSetup = { exactFixed: { direct: [], twoHop: [] } };

interface AiCall {
  model: string;
  inputs: Record<string, unknown>;
  options?: Record<string, unknown>;
}

function plannerEnvelope(code: string | null = 'eng', confidence = 0.9): Record<string, unknown> {
  return {
    choices: [{ message: { content: JSON.stringify({ source_lang_code: code, source_confidence: confidence, uncertain_spans: [] }) } }],
  };
}

function pendingUntilSignal(signal?: AbortSignal): Promise<never> {
  return new Promise((_resolve, reject) => {
    if (!signal) return;
    if (signal.aborted) {
      reject(new DOMException('Aborted', 'AbortError'));
      return;
    }
    signal.addEventListener('abort', () => reject(new DOMException('Aborted', 'AbortError')), { once: true });
  });
}

interface FakeAiConfig {
  planner?: (signal?: AbortSignal) => unknown | Promise<unknown>;
  generation?: (signal?: AbortSignal) => unknown | Promise<unknown>;
}

function completion(content: string): Record<string, unknown> {
  return { choices: [{ message: { content } }] };
}

function fakeAi(config: FakeAiConfig = {}): { ai: OpenAI; calls: AiCall[] } {
  const calls: AiCall[] = [];
  const create = async (
    inputs: Record<string, unknown>,
    options?: Record<string, unknown>,
  ): Promise<unknown> => {
    calls.push({ model: String(inputs.model), inputs, options });
    const signal = options?.signal instanceof AbortSignal ? options.signal : undefined;
    if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');
    if (inputs.response_format !== undefined) {
      return config.planner ? config.planner(signal) : plannerEnvelope();
    }
    const generated = config.generation ? await config.generation(signal) : '';
    return typeof generated === 'string' ? completion(generated) : generated;
  };
  return {
    ai: { chat: { completions: { create } } } as unknown as OpenAI,
    calls,
  };
}

function request(overrides: Partial<RunTranslationRequest> = {}): RunTranslationRequest {
  return {
    text: 'Hello',
    canonicalText: 'Hello',
    sourceLangCode: 'eng',
    sourceLocaleCode: null,
    targetLocaleCode: TARGET_LOCALE,
    targetLocale: TARGET_LOCALE_RESOLUTION,
    requestId: 'req-1',
    ...overrides,
  };
}

interface Harness {
  db: D1Database;
  ai: OpenAI;
  aiCalls: AiCall[];
  controller: AbortController;
  collector: string[];
  ctx: TranslationStreamContext;
}

function harness(handler: Handler, aiConfig: FakeAiConfig = {}): Harness {
  const db = fakeD1(handler);
  const { ai, calls } = fakeAi(aiConfig);
  const collector: string[] = [];
  const controller = new AbortController();
  return {
    db,
    ai,
    aiCalls: calls,
    controller,
    collector,
    ctx: { signal: controller.signal, emit: (line: string) => collector.push(line) },
  };
}

function runTranslationTest(h: Harness, req: RunTranslationRequest): Promise<void> {
  return runTranslation({ DB: h.db, aiClient: h.ai }, req, h.ctx);
}

interface ParsedLine {
  success: boolean;
  data?: TranslationStreamEvent;
  error?: string;
  message?: string;
  retryable?: boolean;
  reset_at?: string;
}

function parseLines(lines: string[]): ParsedLine[] {
  return lines.map((line) => JSON.parse(line) as ParsedLine);
}

function eventTypes(parsed: ParsedLine[]): Array<string | undefined> {
  return parsed.map((entry) => entry.data?.type ?? entry.error);
}

describe('runTranslation — exact fast path', () => {
  it('direct hit emits status -> evidence -> result only, with zero AI calls', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      markers: [markerRow(11)],
      exactFixed: { direct: [exactDirectRow()], twoHop: [] },
    }));
    await runTranslationTest(h, request());

    expect(h.collector).toHaveLength(3);
    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual(['status', 'evidence', 'result']);
    expect(parsed[0].data).toEqual({
      type: 'status',
      stage: 'retrieving',
      mode: 'exact_lookup',
      request_id: 'req-1',
    });
    expect(parsed[1].data).toMatchObject({
      type: 'evidence',
      omitted_count: 0,
      degraded: false,
      retrieval_status: 'matched',
    });
    expect(parsed[1].data && 'items' in parsed[1].data).toBe(true);
    expect(parsed[2].data).toMatchObject({
      type: 'result',
      request_id: 'req-1',
      translation: 'こんにちは',
      source_lang_code: 'eng',
      target_locale_code: TARGET_LOCALE,
      resolution: 'exact_lookup',
      generation_skipped: true,
      model_only: false,
      evidence_present: true,
    });
    expect(h.aiCalls).toHaveLength(0);
  });

  it('two-hop hit emits the same exact fast-path sequence', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      markers: [markerRow(21, '2'), markerRow(22, '2')],
      exactFixed: { direct: [], twoHop: [exactTwoHopRow()] },
    }));
    await runTranslationTest(h, request());

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual(['status', 'evidence', 'result']);
    expect(parsed[2].data).toMatchObject({
      type: 'result',
      resolution: 'exact_lookup',
      generation_skipped: true,
      translation: 'こんにちは',
    });
    expect((parsed[1].data as { items: unknown[] }).items).toHaveLength(1);
    expect(h.aiCalls).toHaveLength(0);
  });

  it('regenerates language-level evidence when its script differs from the requested locale', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      targetLocales: [{ expression_id: 2, locale_code: 'jpn-Latn-JP' }],
      markers: [markerRow(11)],
      exactFixed: { direct: [exactDirectRow()], twoHop: [] },
    }), {
      generation: () => 'konnichiwa',
    });
    await runTranslationTest(h, request());

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual([
      'status',
      'source_language',
      'status',
      'evidence',
      'status',
      'translation_delta',
      'result',
    ]);
    expect(parsed[0].data).toMatchObject({ type: 'status', stage: 'analyzing', mode: 'assisted' });
    expect(parsed[3].data).toMatchObject({ type: 'evidence', retrieval_status: 'matched' });
    expect(parsed[6].data).toMatchObject({
      type: 'result',
      translation: 'konnichiwa',
      resolution: 'assisted',
      model_only: false,
      evidence_present: true,
    });
    expect(h.aiCalls).toHaveLength(1);
  });

  it('ambiguous exact results end with source_confirmation_required and no AI', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      markers: [markerRow(11), markerRow(12)],
      exactFixed: {
        direct: [
          exactDirectRow({ edge_id: 11, source_expr_id: 1, source_lang_code: 'eng', target_text: 'A' }),
          exactDirectRow({ edge_id: 12, source_expr_id: 3, source_lang_code: 'deu', target_text: 'B' }),
        ],
        twoHop: [],
      },
    }));
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual(['status', 'source_confirmation_required']);
    expect(parsed[0].data).toMatchObject({ type: 'status', mode: 'exact_lookup' });
    expect(parsed[1].data).toMatchObject({ type: 'source_confirmation_required' });
    const confirmation = parsed[1].data as { candidates: unknown[]; reason: string };
    expect(confirmation.candidates).toHaveLength(2);
    expect(typeof confirmation.reason).toBe('string');
    expect(h.aiCalls).toHaveLength(0);
  });
});

describe('runTranslation — assisted path', () => {
  it('runs analyzing -> source_language -> retrieving -> evidence -> generating -> deltas -> result', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      ...EMPTY_EXACT,
      candidate: [expr(1, 'Hello')],
      retrieval: { direct: [retrievalDirectRow()] },
      markers: [markerRow(11)],
    }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: () => 'こんにちは',
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual([
      'status',
      'source_language',
      'status',
      'evidence',
      'status',
      'translation_delta',
      'result',
    ]);
    expect(parsed[0].data).toEqual({ type: 'status', stage: 'analyzing', mode: 'assisted', request_id: 'req-1' });
    expect(parsed[1].data).toEqual({ type: 'source_language', code: 'eng', confidence: 0.9 });
    expect(parsed[2].data).toEqual({ type: 'status', stage: 'retrieving', mode: 'assisted', request_id: 'req-1' });
    expect(parsed[3].data).toMatchObject({
      type: 'evidence',
      omitted_count: 0,
      degraded: false,
    });
    expect((parsed[3].data as { items: unknown[] }).items).toHaveLength(1);
    expect(parsed[4].data).toEqual({ type: 'status', stage: 'generating', mode: 'assisted', request_id: 'req-1' });
    expect(parsed[5].data).toEqual({ type: 'translation_delta', text: 'こんにちは' });
    expect(parsed[6].data).toMatchObject({
      type: 'result',
      request_id: 'req-1',
      translation: 'こんにちは',
      alternatives: [],
      resolution: 'assisted',
      generation_skipped: false,
      model_only: false,
      evidence_present: true,
      source_lang_code: 'eng',
      target_locale_code: TARGET_LOCALE,
    });
    expect(h.aiCalls).toHaveLength(2);
    expect(h.aiCalls.map((call) => call.model)).toEqual([TRANSLATION_MODEL, TRANSLATION_MODEL]);
  });

  it('emits source_confirmation_required when planner auto-detect is below threshold, then ends', async () => {
    const h = harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
      planner: () => plannerEnvelope('eng', 0.5),
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual(['status', 'source_confirmation_required']);
    expect(parsed[0].data).toMatchObject({ type: 'status', stage: 'analyzing', mode: 'assisted' });
    const confirmation = parsed[1].data as { candidates: unknown[]; reason: string };
    expect(confirmation.candidates).toEqual([]);
    expect(typeof confirmation.reason).toBe('string');
    expect(h.aiCalls).toHaveLength(1);
  });

  it('goes model-only with degraded evidence when the planner is unavailable', async () => {
    const h = harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
      planner: () => 'not json',
      generation: () => 'Salut',
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual([
      'status',
      'evidence',
      'status',
      'translation_delta',
      'result',
    ]);
    expect(parsed[1].data).toEqual({
      type: 'evidence',
      items: [],
      omitted_count: 0,
      degraded: false,
      retrieval_status: 'skipped',
    });
    expect(parsed[3].data).toEqual({ type: 'translation_delta', text: 'Salut' });
    expect(parsed[4].data).toMatchObject({
      type: 'result',
      resolution: 'assisted',
      generation_skipped: false,
      model_only: true,
      evidence_present: false,
      source_lang_code: null,
      translation: 'Salut',
    });
    expect(h.aiCalls).toHaveLength(2);
  });

  it('prefers the user-specified source with confidence 1', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      ...EMPTY_EXACT,
      candidate: [expr(1, 'Bonjour')],
      retrieval: { direct: [retrievalDirectRow({ target_text: 'Bonjour le monde' })] },
    }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: () => 'Bonjour le monde',
    });
    await runTranslationTest(h, request({ text: 'Bonjour', canonicalText: 'Bonjour', sourceLangCode: 'fra' }));

    const parsed = parseLines(h.collector);
    expect(parsed[1].data).toEqual({ type: 'source_language', code: 'fra', confidence: 1 });
    const result = parsed.at(-1)?.data as { source_lang_code: string | null; model_only: boolean };
    expect(result.source_lang_code).toBe('fra');
    expect(result.model_only).toBe(false);
  });

  it('emits degraded evidence when retrieval fails, and still generates model-only', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      ...EMPTY_EXACT,
      candidate: [expr(1, 'Hello')],
      retrieval: { direct: () => { throw new Error('D1 failure'); } },
    }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: () => 'Phew',
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual([
      'status',
      'source_language',
      'status',
      'evidence',
      'status',
      'translation_delta',
      'result',
    ]);
    expect(parsed[3].data).toEqual({
      type: 'evidence',
      items: [],
      omitted_count: 0,
      degraded: true,
      retrieval_status: 'failed',
    });
    expect(parsed[6].data).toMatchObject({
      type: 'result',
      resolution: 'assisted',
      model_only: true,
      evidence_present: false,
    });
  });

  it('builds up to two rank-ordered distinct alternatives from evidence', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      ...EMPTY_EXACT,
      candidate: [expr(1, 'Hello')],
      retrieval: {
        direct: [
          retrievalDirectRow({ edge_id: 11, target_text: 'A' }),
          retrievalDirectRow({ edge_id: 12, target_text: 'A' }),
          retrievalDirectRow({ edge_id: 13, target_text: 'B' }),
          retrievalDirectRow({ edge_id: 14, target_text: 'C' }),
        ],
      },
      markers: [markerRow(11), markerRow(12), markerRow(13), markerRow(14)],
    }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: () => 'best',
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const result = parseLines(h.collector).at(-1)?.data as { alternatives: string[] };
    expect(result.alternatives).toEqual(['A', 'B']);
    expect(result.alternatives.length).toBeLessThanOrEqual(MAX_ALTERNATIVES);
  });
});

describe('runTranslation — error mapping', () => {
  it('maps a generation timeout to TRANSLATION_TIMEOUT retryable, with no result', async () => {
    vi.useFakeTimers();
    try {
      const h = harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
        planner: () => plannerEnvelope('eng', 0.9),
        generation: (signal) => pendingUntilSignal(signal),
      });
      const pending = runTranslationTest(h, request({ sourceLangCode: null }));
      await vi.advanceTimersByTimeAsync(GENERATION_TIMEOUT_MS + 1000);
      await pending;

      const parsed = parseLines(h.collector);
      expect(eventTypes(parsed)).toEqual([
        'status',
        'source_language',
        'status',
        'evidence',
        'status',
        'TRANSLATION_TIMEOUT',
      ]);
      const error = parsed.at(-1);
      expect(error).toMatchObject({ success: false, error: 'TRANSLATION_TIMEOUT', retryable: true });
      expect(typeof error?.message).toBe('string');
      expect(parsed.some((entry) => entry.data?.type === 'result')).toBe(false);
    } finally {
      vi.useRealTimers();
    }
  });

  it('maps a provider failure to AI_PROVIDER_FAILED retryable', async () => {
    const h = harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: () => { throw new Error('provider exploded'); },
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual([
      'status',
      'source_language',
      'status',
      'evidence',
      'status',
      'AI_PROVIDER_FAILED',
    ]);
    expect(parsed.at(-1)).toMatchObject({ success: false, error: 'AI_PROVIDER_FAILED', retryable: true });
    expect(parsed.some((entry) => entry.data?.type === 'result')).toBe(false);
  });

  it('maps a Workers AI daily quota error to AI_DAILY_QUOTA_EXHAUSTED with reset_at', async () => {
    const h = harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: () => { throw new Error('Limit: daily rate for this model exceeded: Neurons quota for today exhausted'); },
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    const error = parsed.at(-1);
    expect(eventTypes(parsed)).toEqual([
      'status',
      'source_language',
      'status',
      'evidence',
      'status',
      'AI_DAILY_QUOTA_EXHAUSTED',
    ]);
    expect(error).toMatchObject({ success: false, error: 'AI_DAILY_QUOTA_EXHAUSTED', retryable: false });
    const resetAt = error?.reset_at as string;
    expect(resetAt).toMatch(/^\d{4}-\d{2}-\d{2}T00:00:00\.000Z$/);
    expect(Number.isNaN(Date.parse(resetAt))).toBe(false);
    expect(parsed.some((entry) => entry.data?.type === 'result')).toBe(false);
  });

  it('maps an oversized translation to TRANSLATION_OUTPUT_TOO_LARGE with no result', async () => {
    const h = harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: () => 'partial' + 'X'.repeat(MAX_TRANSLATION_OUTPUT_TOKENS + 100),
    });
    await runTranslationTest(h, request({ sourceLangCode: null }));

    const parsed = parseLines(h.collector);
    expect(eventTypes(parsed)).toEqual([
      'status',
      'source_language',
      'status',
      'evidence',
      'status',
      'TRANSLATION_OUTPUT_TOO_LARGE',
    ]);
    const errorIndex = eventTypes(parsed).indexOf('TRANSLATION_OUTPUT_TOO_LARGE');
    expect(errorIndex).toBeGreaterThanOrEqual(0);
    expect(parsed.at(-1)).toMatchObject({ success: false, error: 'TRANSLATION_OUTPUT_TOO_LARGE', retryable: false });
    expect(parsed.some((entry) => entry.data?.type === 'result')).toBe(false);
  });

  it('closes silently on caller abort mid-generation with no error and no result', async () => {
    const h = harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
      planner: () => plannerEnvelope('eng', 0.9),
      generation: (signal) => pendingUntilSignal(signal),
    });
    const pending = runTranslationTest(h, request({ sourceLangCode: null }));
    setTimeout(() => h.controller.abort(), 5);
    await pending;

    const parsed = parseLines(h.collector);
    expect(parsed.some((entry) => entry.success === false)).toBe(false);
    expect(parsed.some((entry) => entry.data?.type === 'result')).toBe(false);
    expect(parsed.some((entry) => entry.data?.type === 'error')).toBe(false);
  });

  it('maps an unexpected database failure to TRANSLATION_FAILED as a last resort', async () => {
    const h = harness((sql) => {
      if (/FROM language_locales ll/.test(sql)) return [LOCALE_ROW];
      if (/JOIN expression_edges edge ON/.test(sql)) throw new Error('unexpected');
      return [];
    });
    await runTranslationTest(h, request());

    const parsed = parseLines(h.collector);
    expect(parsed.at(-1)).toMatchObject({ success: false, error: 'TRANSLATION_FAILED', retryable: false });
    expect(h.aiCalls).toHaveLength(0);
  });
});

describe('runTranslation — envelope contract', () => {
  it('success envelopes carry success:true with the event under data; every line parses', async () => {
    const h = harness(route({
      locale: LOCALE_ROW,
      markers: [markerRow(11)],
      exactFixed: { direct: [exactDirectRow()], twoHop: [] },
    }));
    await runTranslationTest(h, request());

    const parsed = parseLines(h.collector);
    expect(parsed.length).toBe(3);
    for (const entry of parsed) {
      expect(entry.success).toBe(true);
      expect(entry.data?.type).toBeTruthy();
    }
    expect(parsed[2].data?.type).toBe('result');
    expect(parsed.every((entry) => h.collector[parsed.indexOf(entry)].endsWith('\n'))).toBe(true);
  });

  it('every request begins with a status event', async () => {
    const cases: Array<() => { harness: () => Harness; request: RunTranslationRequest }> = [
      () => ({
        harness: () => harness(route({ locale: LOCALE_ROW, markers: [markerRow(11)], exactFixed: { direct: [exactDirectRow()], twoHop: [] } })),
        request: request(),
      }),
      () => ({
        harness: () => harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), { planner: () => plannerEnvelope('eng', 0.5) }),
        request: request({ sourceLangCode: null }),
      }),
      () => ({
        harness: () => harness(route({ locale: LOCALE_ROW, ...EMPTY_EXACT }), {
          planner: () => plannerEnvelope('eng', 0.9),
          generation: () => { throw new Error('provider exploded'); },
        }),
        request: request({ sourceLangCode: null }),
      }),
    ];
    for (const build of cases) {
      const { harness: makeHarness, request } = build();
      const h = makeHarness();
      await runTranslationTest(h, request);
      const first = parseLines(h.collector)[0];
      expect(first.success).toBe(true);
      expect(first.data?.type).toBe('status');
    }
  });
});

describe('writeEnvelope', () => {
  it('writes one newline-terminated JSON envelope line to the writable', async () => {
    let written = '';
    const writable = new WritableStream({
      write(chunk: Uint8Array) {
        written += new TextDecoder().decode(chunk);
      },
    });
    const event: TranslationStreamEvent = {
      type: 'status',
      stage: 'analyzing',
      mode: 'assisted',
      request_id: 'req-1',
    };
    const errorEvent: TranslationStreamErrorEvent = {
      type: 'error',
      code: 'AI_PROVIDER_FAILED',
      retryable: true,
    };
    await writeEnvelope(writable, event);
    await writeEnvelope(writable, errorEvent);

    expect(written).toBe(envelopeLine(event) + envelopeLine(errorEvent));
    const parsed = written.trim().split('\n').map((line) => JSON.parse(line));
    expect(parsed[0]).toEqual({ success: true, data: event });
    expect(parsed[1]).toMatchObject({ success: false, error: 'AI_PROVIDER_FAILED', retryable: true });
  });

  it('exposes net-newline terminated lines from the shared envelope serialization', () => {
    const event: TranslationStreamEvent = {
      type: 'evidence',
      items: [],
      omitted_count: 0,
      degraded: true,
      retrieval_status: 'failed',
    };
    expect(envelopeLine(event)).toBe(`${JSON.stringify({ success: true, data: event })}\n`);
  });
});
