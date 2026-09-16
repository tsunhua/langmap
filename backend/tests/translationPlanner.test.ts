import { describe, expect, it, vi } from 'vitest';
import type OpenAI from 'openai';
import { MAX_PLANNER_SPANS, PLANNER_TIMEOUT_MS } from '../src/utils/limits';
import {
  DEFAULT_PLANNER_LIMITS,
  DEFAULT_SOURCE_CONFIDENCE_THRESHOLD,
  planTranslation,
  type PlannerInput,
} from '../src/services/translation/planner';
import { TRANSLATION_MODEL } from '../src/services/translation/types';

interface AiCall {
  model: string;
  inputs: Record<string, unknown>;
  options?: Record<string, unknown>;
}

function fakeAi(behavior: (signal?: AbortSignal) => Promise<unknown>): { ai: OpenAI; calls: AiCall[] } {
  const calls: AiCall[] = [];
  const create = async (inputs: Record<string, unknown>, options?: Record<string, unknown>) => {
    calls.push({ model: String(inputs.model), inputs, options });
    const signal = options?.signal instanceof AbortSignal ? options.signal : undefined;
    if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');
    return behavior(signal);
  };
  return {
    ai: { chat: { completions: { create } } } as unknown as OpenAI,
    calls,
  };
}

function pendingUntilSignal(signal?: AbortSignal): Promise<unknown> {
  return new Promise((_resolve, reject) => {
    if (!signal) return;
    if (signal.aborted) {
      reject(new DOMException('Aborted', 'AbortError'));
      return;
    }
    signal.addEventListener('abort', () => reject(new DOMException('Aborted', 'AbortError')), { once: true });
  });
}

function payload(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    source_lang_code: 'eng',
    source_confidence: 0.9,
    uncertain_spans: [{ start: 0, end: 5, text: 'Hello', reason: 'proper_noun', confidence: 0.8 }],
    ...overrides,
  };
}

function asEnvelope(body: unknown): Record<string, unknown> {
  return { choices: [{ message: { content: JSON.stringify(body) } }] };
}

function plannerInput(overrides: Partial<PlannerInput> = {}): PlannerInput {
  return { text: 'Hello', ...overrides };
}

describe('planTranslation — valid model output', () => {
  it('parses the json_object envelope and returns ok with the auto-detected source and span order preserved', async () => {
    const { ai, calls } = fakeAi(async () => asEnvelope(payload({
      uncertain_spans: [
        { start: 0, end: 5, text: 'Hello', reason: 'proper_noun', confidence: 0.7 },
        { start: 6, end: 11, text: 'world', reason: 'unknown_term', confidence: 0.8 },
      ],
    })));
    const result = await planTranslation(ai, plannerInput({ text: 'Hello world' }));
    expect(result).toEqual({
      status: 'ok',
      output: {
        source_lang_code: 'eng',
        source_confidence: 0.9,
        uncertain_spans: [
          { start: 0, end: 5, text: 'Hello', reason: 'proper_noun', confidence: 0.7 },
          { start: 6, end: 11, text: 'world', reason: 'unknown_term', confidence: 0.8 },
        ],
      },
    });
    expect(calls).toHaveLength(1);
    expect(calls[0].model).toBe(TRANSLATION_MODEL);
    expect(calls[0].inputs.response_format).toEqual({ type: 'json_object' });
    expect(calls[0].options?.signal).toBeInstanceOf(AbortSignal);
  });

  it('accepts a raw JSON string payload returned instead of the envelope', async () => {
    const { ai, calls } = fakeAi(async () => JSON.stringify(payload()));
    const result = await planTranslation(ai, plannerInput());
    expect(result).toEqual({
      status: 'ok',
      output: {
        source_lang_code: 'eng',
        source_confidence: 0.9,
        uncertain_spans: [{ start: 0, end: 5, text: 'Hello', reason: 'proper_noun', confidence: 0.8 }],
      },
    });
    expect(calls).toHaveLength(1);
  });

  it('sends the source text as untrusted data inside a delimiter and matches the shared model', async () => {
    const { ai, calls } = fakeAi(async () => payload());
    await planTranslation(ai, plannerInput({ text: 'Bonjour le monde' }));
    expect(calls[0].model).toBe(TRANSLATION_MODEL);
    const messages = calls[0].inputs.messages as Array<{ role: string; content: string }>;
    expect(messages[1].content).toBe('<source>Bonjour le monde</source>');
  });
});

describe('planTranslation — span merging and limits', () => {
  it('merges overlapping spans into the union range with an exact substring and max confidence', async () => {
    const { ai } = fakeAi(async () => payload({
      uncertain_spans: [
        { start: 0, end: 6, text: 'Hello ', reason: 'unknown_term', confidence: 0.5 },
        { start: 4, end: 8, text: 'o wo', reason: 'idiom', confidence: 0.9 },
      ],
    }));
    const result = await planTranslation(ai, plannerInput({ text: 'Hello world' }));
    expect(result).toEqual({
      status: 'ok',
      output: {
        source_lang_code: 'eng',
        source_confidence: 0.9,
        uncertain_spans: [{ start: 0, end: 8, text: 'Hello wo', reason: 'idiom', confidence: 0.9 }],
      },
    });
  });

  it('dedupes identical spans before merging', async () => {
    const { ai } = fakeAi(async () => payload({
      uncertain_spans: [
        { start: 0, end: 5, text: 'Hello', reason: 'unknown_term', confidence: 0.8 },
        { start: 0, end: 5, text: 'Hello', reason: 'unknown_term', confidence: 0.8 },
        { start: 0, end: 5, text: 'Hello', reason: 'unknown_term', confidence: 0.3 },
      ],
    }));
    const result = await planTranslation(ai, plannerInput());
    expect(result.status).toBe('ok');
    if (result.status !== 'ok') return;
    expect(result.output.uncertain_spans).toEqual([{ start: 0, end: 5, text: 'Hello', reason: 'unknown_term', confidence: 0.8 }]);
  });

  it('caps the merged span list at MAX_PLANNER_SPANS in input order', async () => {
    const max = MAX_PLANNER_SPANS;
    const text = Array.from({ length: max + 3 }, (_, i) => String.fromCharCode(97 + i)).join('');
    const uncertain_spans = Array.from({ length: max + 3 }, (_, i) => ({
      start: i,
      end: i + 1,
      text: text[i],
      reason: 'unknown_term',
      confidence: 0.6,
    }));
    const { ai } = fakeAi(async () => payload({ uncertain_spans }));
    const result = await planTranslation(ai, plannerInput({ text }));
    expect(result.status).toBe('ok');
    if (result.status !== 'ok') return;
    expect(result.output.uncertain_spans).toHaveLength(max);
    expect(result.output.uncertain_spans[0]).toEqual({ start: 0, end: 1, text: text[0], reason: 'unknown_term', confidence: 0.6 });
    expect(result.output.uncertain_spans[max - 1]).toEqual({
      start: max - 1,
      end: max,
      text: text[max - 1],
      reason: 'unknown_term',
      confidence: 0.6,
    });
  });
});

describe('planTranslation — malformed spans', () => {
  it('drops spans with mismatched text, inverted bounds, out-of-range offsets, bad reason or bad confidence', async () => {
    const { ai } = fakeAi(async () => payload({
      uncertain_spans: [
        { start: 0, end: 5, text: 'Xello', reason: 'unknown_term', confidence: 0.8 }, // text mismatch
        { start: 3, end: 3, text: 'l', reason: 'unknown_term', confidence: 0.8 }, // start >= end
        { start: 0, end: 100, text: 'Hello', reason: 'unknown_term', confidence: 0.8 }, // out of range
        { start: 0, end: 5, text: 'Hello', reason: 'guess', confidence: 0.8 }, // bad reason
        { start: 0, end: 5, text: 'Hello', reason: 'unknown_term', confidence: 1.5 }, // bad confidence
        { start: '0', end: 5, text: 'Hello', reason: 'unknown_term', confidence: 0.8 }, // non-integer offset
        { start: 0, end: 5, text: 'Hello', reason: 'unknown_term', confidence: 0.8 }, // valid
      ],
    }));
    const result = await planTranslation(ai, plannerInput());
    expect(result).toEqual({
      status: 'ok',
      output: {
        source_lang_code: 'eng',
        source_confidence: 0.9,
        uncertain_spans: [{ start: 0, end: 5, text: 'Hello', reason: 'unknown_term', confidence: 0.8 }],
      },
    });
  });

  it('treats an entirely invalid payload as planner failure', async () => {
    const { ai, calls } = fakeAi(async () => ({ unexpected: true }));
    const result = await planTranslation(ai, plannerInput());
    expect(result).toEqual({ status: 'unavailable' });
    expect(calls).toHaveLength(1);
  });

  it('falls back to the user-specified source with empty spans on an entirely invalid payload', async () => {
    const { ai, calls } = fakeAi(async () => 'not json');
    const result = await planTranslation(ai, plannerInput({ sourceLangCode: 'fra' }));
    expect(result).toEqual({
      status: 'ok',
      output: { source_lang_code: 'fra', source_confidence: 1, uncertain_spans: [] },
    });
    expect(calls).toHaveLength(1);
  });
});

describe('planTranslation — timeout, provider errors and abort', () => {
  it('times out after PLANNER_TIMEOUT_MS without retrying and without leaking timers', async () => {
    vi.useFakeTimers();
    try {
      const { ai, calls } = fakeAi(async (signal) => pendingUntilSignal(signal));
      const promise = planTranslation(ai, plannerInput({ text: 'Hello world' }));
      vi.advanceTimersByTime(PLANNER_TIMEOUT_MS + 1);
      const result = await promise;
      expect(result).toEqual({ status: 'unavailable' });
      expect(calls).toHaveLength(1);
      expect((calls[0].options?.signal as AbortSignal).aborted).toBe(true);
      expect(vi.getTimerCount()).toBe(0);
    } finally {
      vi.useRealTimers();
    }
  });

  it('rejects with AbortError when the caller signal fires mid-call instead of degrading to a fallback', async () => {
    const { ai, calls } = fakeAi(async (signal) => pendingUntilSignal(signal));
    const controller = new AbortController();
    const resultPromise = planTranslation(ai, plannerInput({ signal: controller.signal }));
    controller.abort();
    await expect(resultPromise).rejects.toMatchObject({ name: 'AbortError' });
    expect(calls).toHaveLength(1);
    expect((calls[0].options?.signal as AbortSignal).aborted).toBe(true);
  });

  it('rejects with AbortError when the caller signal is already aborted before the call', async () => {
    const { ai, calls } = fakeAi(async (signal) => pendingUntilSignal(signal));
    const controller = new AbortController();
    controller.abort();
    const resultPromise = planTranslation(ai, plannerInput({ signal: controller.signal }));
    await expect(resultPromise).rejects.toMatchObject({ name: 'AbortError' });
    expect(calls).toHaveLength(1);
  });

  it('converts a provider error into the failure contract with a single call', async () => {
    const { ai, calls } = fakeAi(async () => {
      throw new Error('provider exploded');
    });
    const result = await planTranslation(ai, plannerInput({ sourceLangCode: 'cmn' }));
    expect(result).toEqual({
      status: 'ok',
      output: { source_lang_code: 'cmn', source_confidence: 1, uncertain_spans: [] },
    });
    expect(calls).toHaveLength(1);
  });
});

describe('planTranslation — source handling', () => {
  it('always honors a user-specified source and still passes model spans through', async () => {
    const { ai, calls } = fakeAi(async () => payload({
      source_lang_code: 'eng',
      source_confidence: 0.2,
      uncertain_spans: [
        { start: 0, end: 7, text: 'Bonjour', reason: 'idiom', confidence: 0.75 },
        { start: 0, end: 7, text: 'Bonjour', reason: 'idiom', confidence: 0.75 }, // dup dropped
      ],
    }));
    const result = await planTranslation(ai, plannerInput({ text: 'Bonjour', sourceLangCode: 'FRA' }));
    expect(result).toEqual({
      status: 'ok',
      output: {
        source_lang_code: 'fra',
        source_confidence: 1,
        uncertain_spans: [{ start: 0, end: 7, text: 'Bonjour', reason: 'idiom', confidence: 0.75 }],
      },
    });
    expect(calls).toHaveLength(1);
  });

  it('returns confirmation_required when auto-detected confidence is below the threshold', async () => {
    const { ai } = fakeAi(async () => payload({ source_confidence: DEFAULT_SOURCE_CONFIDENCE_THRESHOLD - 0.01 }));
    const result = await planTranslation(ai, plannerInput());
    expect(result).toEqual({ status: 'confirmation_required' });
  });

  it('applies an overridable confidence threshold', async () => {
    const below = fakeAi(async () => payload({ source_confidence: 0.6 })).ai;
    expect(await planTranslation(below, plannerInput({ sourceConfidenceThreshold: 0.65 })))
      .toEqual({ status: 'confirmation_required' });
    const above = fakeAi(async () => payload({ source_confidence: 0.7 })).ai;
    const result = await planTranslation(above, plannerInput({ sourceConfidenceThreshold: 0.65 }));
    expect(result.status).toBe('ok');
  });

  it('goes unavailable when auto-detect cannot name a concrete language', async () => {
    const { ai } = fakeAi(async () => payload({
      source_lang_code: null,
      source_confidence: 0.9,
      uncertain_spans: [],
    }));
    const result = await planTranslation(ai, plannerInput());
    expect(result).toEqual({ status: 'unavailable' });
  });

  it('keeps a usable auto-detected source when confidence clears the threshold', async () => {
    const { ai } = fakeAi(async () => payload());
    const result = await planTranslation(ai, plannerInput());
    expect(result.status).toBe('ok');
    if (result.status !== 'ok') return;
    expect(result.output.source_lang_code).toBe('eng');
    expect(result.output.source_confidence).toBe(0.9);
  });
});

describe('planTranslation — astral character safety', () => {
  it('validates span offsets as codepoint offsets around surrogate pairs', async () => {
    const text = '👋hi';
    const { ai } = fakeAi(async () => payload({
      uncertain_spans: [
        { start: 0, end: 1, text: '👋', reason: 'idiom', confidence: 0.9 }, // one codepoint, two UTF-16 units
        { start: 0, end: 1, text: '\uD83D', reason: 'idiom', confidence: 0.9 }, // lone surrogate half: text mismatch
        { start: 1, end: 3, text: 'hi', reason: 'unknown_term', confidence: 0.8 }, // beyond the emoji pair
        { start: 1, end: 4, text: 'hi', reason: 'unknown_term', confidence: 0.8 }, // end beyond codepoint length
      ],
    }));
    const result = await planTranslation(ai, plannerInput({ text }));
    expect(result.status).toBe('ok');
    if (result.status !== 'ok') return;
    expect(result.output.uncertain_spans).toEqual([
      { start: 0, end: 1, text: '👋', reason: 'idiom', confidence: 0.9 },
      { start: 1, end: 3, text: 'hi', reason: 'unknown_term', confidence: 0.8 },
    ]);
  });

  it('defaults limits to the shared constants', () => {
    expect(DEFAULT_PLANNER_LIMITS).toEqual({ maxSpans: MAX_PLANNER_SPANS, timeoutMs: PLANNER_TIMEOUT_MS });
  });
});
