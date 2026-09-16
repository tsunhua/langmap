import { describe, expect, it, vi } from 'vitest';
import type OpenAI from 'openai';
import { GENERATION_TIMEOUT_MS, MAX_TRANSLATION_OUTPUT_TOKENS } from '../src/utils/limits';
import {
  DEFAULT_GENERATION_LIMITS,
  streamTranslation,
  type GenerationRequest,
} from '../src/services/translation/generation';
import { TRANSLATION_MODEL } from '../src/services/translation/types';
import type { TranslationEvidence } from '../src/services/translation/types';

interface AiCall {
  model: string;
  inputs: Record<string, unknown>;
  options?: Record<string, unknown>;
}

function completion(content: string): Record<string, unknown> {
  return { choices: [{ message: { content } }] };
}

function fakeCompletionAi(
  content: string,
): { ai: OpenAI; calls: AiCall[] } {
  const calls: AiCall[] = [];
  const create = async (
    inputs: Record<string, unknown>,
    options?: Record<string, unknown>,
  ): Promise<Record<string, unknown>> => {
    calls.push({ model: String(inputs.model), inputs, options });
    const signal = options?.signal instanceof AbortSignal ? options.signal : undefined;
    if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');

    return completion(content);
  };
  return {
    ai: { chat: { completions: { create } } } as unknown as OpenAI,
    calls,
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

function fakeBlockingAi(): { ai: OpenAI; calls: AiCall[] } {
  const calls: AiCall[] = [];
  const create = async (
    inputs: Record<string, unknown>,
    options?: Record<string, unknown>,
  ): Promise<Record<string, unknown>> => {
    calls.push({ model: String(inputs.model), inputs, options });
    const signal = options?.signal instanceof AbortSignal ? options.signal : undefined;
    if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');
    await pendingUntilSignal(signal);
    return completion('');
  };
  return {
    ai: { chat: { completions: { create } } } as unknown as OpenAI,
    calls,
  };
}

function evidence(overrides: Partial<TranslationEvidence> = {}): TranslationEvidence {
  return {
    source_text: 'hello',
    target_text: 'hola',
    target_locale_code: 'es-ES',
    path_type: 'direct',
    match_type: 'exact',
    source_markers: [],
    ...overrides,
  };
}

function genRequest(overrides: Partial<GenerationRequest> = {}): GenerationRequest {
  return {
    text: 'Hello',
    sourceLangCode: 'eng',
    targetLocaleCode: 'zh-TW',
    evidence: [],
    ...overrides,
  };
}

function collectDeltas(request: GenerationRequest): { deltas: string[]; patched: GenerationRequest } {
  const deltas: string[] = [];
  const patched = {
    ...request,
    onDelta: (chunk: string) => {
      deltas.push(chunk);
      request.onDelta?.(chunk);
    },
  };
  return { deltas, patched };
}

describe('streamTranslation — happy path', () => {
  it('returns the SDK completion with the correct model and options', async () => {
    const { ai, calls } = fakeCompletionAi('Hello world');
    const result = await streamTranslation(ai, genRequest({ text: 'Hello world' }));
    expect(result).toEqual({ translation: 'Hello world', alternatives: [], model_only: true });
    expect(calls).toHaveLength(1);
    expect(calls[0].model).toBe(TRANSLATION_MODEL);
    expect(calls[0].inputs.stream).toBe(false);
  });

  it('delivers the complete SDK response via onDelta callback', async () => {
    const { ai } = fakeCompletionAi('Hello world');
    const request = genRequest({ text: 'Hello world' });
    const { deltas, patched } = collectDeltas(request);
    const result = await streamTranslation(ai, patched);
    expect(deltas).toEqual(['Hello world']);
    expect(result.translation).toBe('Hello world');
  });

  it('works without onDelta callback', async () => {
    const { ai } = fakeCompletionAi('Hello world');
    const result = await streamTranslation(ai, genRequest({ text: 'Hello world' }));
    expect(result.translation).toBe('Hello world');
  });
});

describe('streamTranslation — evidence handling', () => {
  it('sets model_only=false when evidence is present', async () => {
    const { ai } = fakeCompletionAi('Hola');
    const ev = [evidence()];
    const result = await streamTranslation(ai, genRequest({ evidence: ev }));
    expect(result.model_only).toBe(false);
  });

  it('sets model_only=true when evidence is absent', async () => {
    const { ai } = fakeCompletionAi('Hola');
    const result = await streamTranslation(ai, genRequest({ evidence: [] }));
    expect(result.model_only).toBe(true);
  });

  it('sets model_only=true when evidence is undefined', async () => {
    const { ai } = fakeCompletionAi('Hola');
    const result = await streamTranslation(
      ai,
      genRequest({ evidence: undefined as unknown as TranslationEvidence[] }),
    );
    expect(result.model_only).toBe(true);
  });

  it('includes evidence path labels in the prompt when evidence is present', async () => {
    const ev = [
      evidence({ source_text: 'cat', target_text: 'gato', path_type: 'direct', match_type: 'exact' }),
      evidence({ source_text: 'dog', target_text: 'perro', path_type: 'two_hop', pivot_lang_code: 'eng', match_type: 'prefix' }),
    ];
    const { ai, calls } = fakeCompletionAi('gato');
    await streamTranslation(ai, genRequest({ text: 'cat', evidence: ev }));
    const userContent = (calls[0].inputs.messages as Array<{ role: string; content: string }>)[1].content;
    expect(userContent).toContain('1. cat → gato [eng→es-ES, exact, reference locale: unspecified]');
    expect(userContent).toContain('2. dog → perro [eng→eng→es-ES, prefix, reference locale: unspecified]');
  });

  it('omits evidence section when evidence is empty', async () => {
    const { ai, calls } = fakeCompletionAi('Hello');
    await streamTranslation(ai, genRequest({ text: 'Hello', evidence: [] }));
    const userContent = (calls[0].inputs.messages as Array<{ role: string; content: string }>)[1].content;
    expect(userContent).not.toContain('reference translation');
  });
});

describe('streamTranslation — timeout', () => {
  it('throws AbortError after GENERATION_TIMEOUT_MS without retrying and cleans up', async () => {
    vi.useFakeTimers();
    try {
      const { ai, calls } = fakeBlockingAi();
      const promise = streamTranslation(ai, genRequest());
      vi.advanceTimersByTime(GENERATION_TIMEOUT_MS + 1);
      await expect(promise).rejects.toMatchObject({ name: 'AbortError' });
      expect(calls).toHaveLength(1);
      expect(vi.getTimerCount()).toBe(0);
    } finally {
      vi.useRealTimers();
    }
  });
});

describe('streamTranslation — client abort', () => {
  it('throws AbortError when signal fires mid-stream without retrying', async () => {
    const { ai, calls } = fakeBlockingAi();
    const controller = new AbortController();
    const resultPromise = streamTranslation(ai, genRequest({ signal: controller.signal }));
    controller.abort();
    await expect(resultPromise).rejects.toMatchObject({ name: 'AbortError' });
    expect(calls).toHaveLength(1);
  });

  it('throws AbortError immediately when signal is already aborted before the call', async () => {
    const { ai, calls } = fakeCompletionAi('');
    const controller = new AbortController();
    controller.abort();
    await expect(streamTranslation(ai, genRequest({ signal: controller.signal })))
      .rejects.toMatchObject({ name: 'AbortError' });
    expect(calls).toHaveLength(0);
  });
});

describe('streamTranslation — TRANSLATION_OUTPUT_TOO_LARGE', () => {
  it('throws when accumulated translation exceeds max output tokens', async () => {
    const longChunk = 'A'.repeat(MAX_TRANSLATION_OUTPUT_TOKENS + 100);
    const { ai } = fakeCompletionAi(longChunk);
    const resultPromise = streamTranslation(ai, genRequest());
    await expect(resultPromise).rejects.toMatchObject({ code: 'TRANSLATION_OUTPUT_TOO_LARGE' });
  });

  it('partial translation is not treated as complete', async () => {
    const halfChunk = 'A'.repeat(Math.floor(MAX_TRANSLATION_OUTPUT_TOKENS / 2));
    const { ai } = fakeCompletionAi(halfChunk + 'B'.repeat(MAX_TRANSLATION_OUTPUT_TOKENS));
    const resultPromise = streamTranslation(ai, genRequest());
    await expect(resultPromise).rejects.toMatchObject({ code: 'TRANSLATION_OUTPUT_TOO_LARGE' });
  });
});

describe('streamTranslation — provider error', () => {
  it('surfaces the provider error with a single call', async () => {
    const { ai, calls } = {
      ai: {
        chat: { completions: { create: async () => { throw new Error('provider exploded'); } } },
      } as unknown as OpenAI,
      calls: [] as AiCall[],
    };
    await expect(streamTranslation(ai, genRequest())).rejects.toThrow('provider exploded');
    expect(calls).toHaveLength(0);
  });
});

describe('streamTranslation — empty response', () => {
  it('throws when the AI returns no text chunks', async () => {
    const { ai } = fakeCompletionAi('');
    await expect(streamTranslation(ai, genRequest())).rejects.toThrow('AI returned no translation text');
  });
});

describe('streamTranslation — prompt structure', () => {
  it('wraps source text in <source> delimiters', async () => {
    const { ai, calls } = fakeCompletionAi('translation');
    await streamTranslation(ai, genRequest({ text: 'Hello world' }));
    const messages = calls[0].inputs.messages as Array<{ role: string; content: string }>;
    expect(messages[0].role).toBe('system');
    expect(messages[1].content).toContain('<source>Hello world</source>');
  });

  it('identifies the source language explicitly for short or ambiguous inputs', async () => {
    const { ai, calls } = fakeCompletionAi('translation');
    await streamTranslation(ai, genRequest({ sourceLangCode: 'cmn', targetLocaleCode: 'nan-Hant-TW' }));
    const systemContent = (calls[0].inputs.messages as Array<{ role: string; content: string }>)[0].content;
    expect(systemContent).toContain('source language code cmn');
    expect(systemContent).toContain('target locale nan-Hant-TW');
  });

  it('includes evidence as ranked reference when present', async () => {
    const ev = [
      evidence({ source_text: 'hello', target_text: 'hola' }),
      evidence({ source_text: 'goodbye', target_text: 'adiós' }),
    ];
    const { ai, calls } = fakeCompletionAi('hola');
    await streamTranslation(ai, genRequest({ text: 'hello', evidence: ev }));
    const messages = calls[0].inputs.messages as Array<{ role: string; content: string }>;
    expect(messages).toHaveLength(2);
    expect(messages[1].content).toContain('reference translation');
    expect(messages[1].content).toContain('hello → hola');
    expect(messages[1].content).toContain('goodbye → adiós');
    expect(messages[1].content).toContain('<source>hello</source>');
  });

  it('includes resolved language and locale names so regional varieties are not flattened', async () => {
    const { ai, calls } = fakeCompletionAi('我今仔日欲去市場。');
    await streamTranslation(ai, genRequest({
      targetLocaleCode: 'nan-Hant-TW',
      targetLanguageCode: 'nan',
      targetLocaleName: '台語',
      targetLocaleNameEn: 'Taiwanese Hokkien',
    }));
    const systemContent = (calls[0].inputs.messages as Array<{ role: string; content: string }>)[0].content;
    expect(systemContent).toContain('language code nan');
    expect(systemContent).toContain('Taiwanese Hokkien / 台語');
  });
});

describe('streamTranslation — defaults', () => {
  it('DEFAULT_GENERATION_LIMITS matches shared constants', () => {
    expect(DEFAULT_GENERATION_LIMITS).toEqual({
      timeoutMs: GENERATION_TIMEOUT_MS,
      maxOutputTokens: MAX_TRANSLATION_OUTPUT_TOKENS,
    });
  });
});
