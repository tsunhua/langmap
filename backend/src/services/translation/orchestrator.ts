import type { Ai, D1Database } from '@cloudflare/workers-types';
import { MAX_ALTERNATIVES } from '../../utils/limits';
import {
  DEFAULT_EXACT_MATCH_LIMITS,
  findExactTranslation,
  type ExactMatchLimits,
} from './exactMatch';
import {
  DEFAULT_GENERATION_LIMITS,
  streamTranslation,
  type GenerationLimits,
} from './generation';
import {
  DEFAULT_PLANNER_LIMITS,
  planTranslation,
  type PlannerLimits,
  type PlannerOutput,
  type PlannerResult,
} from './planner';
import {
  DEFAULT_RETRIEVAL_LIMITS,
  retrieveEvidence,
  type RetrievalLimits,
} from './retrieval';
import type { TargetLocaleResolution } from './validation';
import type {
  TranslationEvidence,
  TranslationMode,
  TranslationStage,
  TranslationStreamErrorEvent,
  TranslationStreamEvent,
} from './types';

export interface OrchestratorLimits {
  exactMatch: ExactMatchLimits;
  planner: PlannerLimits;
  retrieval: RetrievalLimits;
  generation: GenerationLimits;
  maxAlternatives: number;
}

// Per-stage overrides only; every stage falls back to its own service defaults.
export interface TranslationLimitsInput {
  exactMatch?: Partial<ExactMatchLimits>;
  planner?: Partial<PlannerLimits>;
  retrieval?: Partial<RetrievalLimits>;
  generation?: Partial<GenerationLimits>;
  maxAlternatives?: number;
}

export interface RunTranslationEnv {
  DB: D1Database;
  AI: Ai;
}

// Input is already validated and resolved by the route (Task 1.7); this service
// never re-reads request text into the DB or touches the registry.
export interface RunTranslationRequest {
  text: string;
  canonicalText: string;
  sourceLangCode: string | null;
  sourceLocaleCode: string | null;
  targetLocaleCode: string;
  targetLocale: TargetLocaleResolution;
  requestId: string;
  limits?: TranslationLimitsInput;
}

// The NDJSON line sink: emit accepts the full envelope line (newline included).
// The route wires this to the Web stream writer; tests use a collector array.
export interface TranslationStreamContext {
  signal: AbortSignal;
  emit: (line: string) => void;
}

export interface TranslationSuccessEnvelope {
  success: true;
  data: TranslationStreamEvent;
}

export interface TranslationErrorEnvelope {
  success: false;
  error: string;
  message: string;
  retryable: boolean;
  retry_after_seconds?: number;
  reset_at?: string;
}

const CONFIRMATION_REASON_MULTIPLE_SOURCES =
  'Multiple possible source languages; choose one to continue.';
const CONFIRMATION_REASON_LOW_CONFIDENCE =
  'Source language could not be detected with enough confidence; choose one to continue.';

const ERROR_MESSAGES: Record<string, string> = {
  TRANSLATION_TIMEOUT: 'Translation timed out.',
  TRANSLATION_OUTPUT_TOO_LARGE: 'Translation output exceeded the allowed size.',
  AI_DAILY_QUOTA_EXHAUSTED: 'Workers AI daily quota exhausted.',
  AI_PROVIDER_FAILED: 'Translation provider failed.',
  TRANSLATION_FAILED: 'Translation failed.',
};

// Workers AI surfaces account Neurons exhaustion in message text; recognize it
// so the client can show the reset instead of retrying the same failed call.
const DAILY_QUOTA_PATTERN = /daily rate|quota|neurons/i;

function errorMessage(code: string): string {
  return ERROR_MESSAGES[code] ?? ERROR_MESSAGES.TRANSLATION_FAILED;
}

function isAbortError(error: unknown): boolean {
  return error instanceof DOMException && error.name === 'AbortError';
}

function isDailyQuotaError(error: unknown): boolean {
  if (typeof error !== 'object' || error === null) return false;
  const message = (error as { message?: unknown }).message;
  return typeof message === 'string' && DAILY_QUOTA_PATTERN.test(message);
}

function nextUtcMidnightIso(): string {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 0, 0, 0),
  ).toISOString();
}

function resolveLimits(input?: TranslationLimitsInput): OrchestratorLimits {
  return {
    exactMatch: { ...DEFAULT_EXACT_MATCH_LIMITS, ...input?.exactMatch },
    planner: { ...DEFAULT_PLANNER_LIMITS, ...input?.planner },
    retrieval: { ...DEFAULT_RETRIEVAL_LIMITS, ...input?.retrieval },
    generation: { ...DEFAULT_GENERATION_LIMITS, ...input?.generation },
    maxAlternatives: input?.maxAlternatives ?? MAX_ALTERNATIVES,
  };
}

export function envelopeFor(
  event: TranslationStreamEvent,
): TranslationSuccessEnvelope | TranslationErrorEnvelope {
  if (event.type === 'error') {
    const envelope: TranslationErrorEnvelope = {
      success: false,
      error: event.code,
      message: errorMessage(event.code),
      retryable: event.retryable,
    };
    if (event.retry_after_seconds !== undefined) envelope.retry_after_seconds = event.retry_after_seconds;
    if (event.reset_at !== undefined) envelope.reset_at = event.reset_at;
    return envelope;
  }
  return { success: true, data: event };
}

// Serialized NDJSON line shared by the internal emit sink and the route helper.
export function envelopeLine(event: TranslationStreamEvent): string {
  return `${JSON.stringify(envelopeFor(event))}\n`;
}

export async function writeEnvelope(
  writable: WritableStream,
  event: TranslationStreamEvent,
): Promise<void> {
  const writer = writable.getWriter();
  try {
    await writer.write(new TextEncoder().encode(envelopeLine(event)));
  } finally {
    writer.releaseLock();
  }
}

function statusEvent(
  stage: TranslationStage,
  mode: TranslationMode,
  requestId: string,
): TranslationStreamEvent {
  return { type: 'status', stage, mode, request_id: requestId };
}

function errorEvent(
  code: string,
  retryable: boolean,
  extra?: Partial<Pick<TranslationStreamErrorEvent, 'reset_at' | 'retry_after_seconds'>>,
): TranslationStreamEvent {
  return { type: 'error', code, retryable, ...extra };
}

function emitEvent(ctx: TranslationStreamContext, event: TranslationStreamEvent): void {
  ctx.emit(envelopeLine(event));
}

function distinctTargetTexts(items: TranslationEvidence[], mainTranslation: string, max: number): string[] {
  const seen = new Set<string>([mainTranslation]);
  const out: string[] = [];
  for (const item of items) {
    if (seen.has(item.target_text)) continue;
    seen.add(item.target_text);
    out.push(item.target_text);
    if (out.length >= max) break;
  }
  return out;
}

export async function runTranslation(
  env: RunTranslationEnv,
  request: RunTranslationRequest,
  ctx: TranslationStreamContext,
): Promise<void> {
  const limits = resolveLimits(request.limits);
  try {
    if (ctx.signal.aborted) return;
    await runPipeline(env, request, ctx, limits);
  } catch {
    // Last resort only: every stage maps its own failures above. An error here
    // must still surface as a stream error, never as an unhandled rejection.
    if (ctx.signal.aborted) return;
    try {
      emitEvent(ctx, errorEvent('TRANSLATION_FAILED', false));
    } catch {
      // The sink itself failed; runTranslation must never reject, so swallow.
    }
  }
}

async function runPipeline(
  env: RunTranslationEnv,
  request: RunTranslationRequest,
  ctx: TranslationStreamContext,
  limits: OrchestratorLimits,
): Promise<void> {
  // Quota reservation happens in the route before the stream starts (Task 1.7).
  const exact = await findExactTranslation(env.DB, {
    canonicalText: request.canonicalText,
    sourceLangCode: request.sourceLangCode,
    targetLocaleCode: request.targetLocaleCode,
    limits: limits.exactMatch,
  });
  if (ctx.signal.aborted) return;

  switch (exact.status) {
    case 'exact_match':
      emitEvent(ctx, statusEvent('retrieving', 'exact_lookup', request.requestId));
      emitEvent(ctx, { type: 'evidence', items: exact.evidence, omitted_count: 0, degraded: false });
      emitEvent(ctx, { type: 'result', ...exact.result, request_id: request.requestId });
      return;
    case 'ambiguous':
      emitEvent(ctx, statusEvent('retrieving', 'exact_lookup', request.requestId));
      emitEvent(ctx, {
        type: 'source_confirmation_required',
        candidates: exact.candidates,
        reason: CONFIRMATION_REASON_MULTIPLE_SOURCES,
      });
      return;
    default:
      break;
  }

  await assistedPath(env, request, ctx, limits);
}

async function assistedPath(
  env: RunTranslationEnv,
  request: RunTranslationRequest,
  ctx: TranslationStreamContext,
  limits: OrchestratorLimits,
): Promise<void> {
  emitEvent(ctx, statusEvent('analyzing', 'assisted', request.requestId));

  let planner: PlannerResult;
  try {
    planner = await planTranslation(env.AI, {
      text: request.text,
      sourceLangCode: request.sourceLangCode,
      limits: limits.planner,
      signal: ctx.signal,
    });
  } catch {
    // The planner only rethrows on a caller abort; any other rejection degrades
    // to an unknown source rather than guessing a language.
    if (ctx.signal.aborted) return;
    planner = { status: 'unavailable' };
  }
  if (ctx.signal.aborted) return;

  if (planner.status === 'confirmation_required') {
    emitEvent(ctx, {
      type: 'source_confirmation_required',
      candidates: [],
      reason: CONFIRMATION_REASON_LOW_CONFIDENCE,
    });
    return;
  }

  let plannerOutput: PlannerOutput | null = null;
  let sourceLangCode: string | null = null;
  if (planner.status === 'ok' && planner.output.source_lang_code) {
    // The user's explicit choice always wins over auto-detection confidence 1.
    sourceLangCode = request.sourceLangCode ?? planner.output.source_lang_code;
    plannerOutput = planner.output;
    emitEvent(ctx, {
      type: 'source_language',
      code: sourceLangCode,
      confidence: request.sourceLangCode ? 1 : planner.output.source_confidence,
    });
  }
  if (ctx.signal.aborted) return;

  let evidence: TranslationEvidence[] = [];
  if (plannerOutput && sourceLangCode) {
    emitEvent(ctx, statusEvent('retrieving', 'assisted', request.requestId));
    let retrieval;
    try {
      retrieval = await retrieveEvidence(env.DB, {
        fullText: request.text,
        spans: plannerOutput.uncertain_spans,
        sourceLangCode,
        targetLocaleCode: request.targetLocaleCode,
        limits: limits.retrieval,
        signal: ctx.signal,
      });
    } catch {
      if (ctx.signal.aborted) return;
      retrieval = null;
    }
    if (ctx.signal.aborted) return;

    if (!retrieval || retrieval.degraded || retrieval.items.length === 0) {
      emitEvent(ctx, { type: 'evidence', items: [], omitted_count: 0, degraded: true });
    } else {
      evidence = retrieval.items;
      emitEvent(ctx, {
        type: 'evidence',
        items: retrieval.items,
        omitted_count: retrieval.omitted_count,
        degraded: false,
      });
    }
  } else {
    // Source could not be determined safely: skip graph retrieval rather than
    // guess a language, and fall back to model-only generation.
    emitEvent(ctx, { type: 'evidence', items: [], omitted_count: 0, degraded: true });
  }
  if (ctx.signal.aborted) return;

  emitEvent(ctx, statusEvent('generating', 'assisted', request.requestId));

  let generation;
  try {
    generation = await streamTranslation(env.AI, {
      text: request.text,
      sourceLangCode: sourceLangCode ?? '',
      targetLocaleCode: request.targetLocaleCode,
      evidence,
      signal: ctx.signal,
      limits: limits.generation,
      onDelta: (chunk) => emitEvent(ctx, { type: 'translation_delta', text: chunk }),
    });
  } catch (error) {
    if (ctx.signal.aborted) return;
    if (isAbortError(error)) {
      // Timeout paths already throw AbortError only when the caller signal is
      // intact; the generation service derives its deadline from its own timer.
      emitEvent(ctx, errorEvent('TRANSLATION_TIMEOUT', true));
      return;
    }
    if (
      error instanceof Error &&
      (error as { code?: string }).code === 'TRANSLATION_OUTPUT_TOO_LARGE'
    ) {
      // Partial text was streamed but is not a complete result.
      emitEvent(ctx, errorEvent('TRANSLATION_OUTPUT_TOO_LARGE', false));
      return;
    }
    if (isDailyQuotaError(error)) {
      emitEvent(ctx, errorEvent('AI_DAILY_QUOTA_EXHAUSTED', false, { reset_at: nextUtcMidnightIso() }));
      return;
    }
    emitEvent(ctx, errorEvent('AI_PROVIDER_FAILED', true));
    return;
  }
  if (ctx.signal.aborted) return;

  emitEvent(ctx, {
    type: 'result',
    request_id: request.requestId,
    translation: generation.translation,
    alternatives: distinctTargetTexts(evidence, generation.translation, limits.maxAlternatives),
    source_lang_code: sourceLangCode,
    target_locale_code: request.targetLocaleCode,
    evidence_present: evidence.length > 0,
    model_only: generation.model_only,
    resolution: 'assisted',
    generation_skipped: false,
  });
}