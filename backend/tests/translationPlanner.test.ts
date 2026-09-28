import { describe, expect, it, vi } from 'vitest';
import type OpenAI from 'openai';
import { MAX_PLANNER_SPANS, PLANNER_TIMEOUT_MS } from '../src/utils/limits';
import { DEFAULT_PLANNER_LIMITS, DEFAULT_SOURCE_CONFIDENCE_THRESHOLD, planTranslation, type PlannerInput } from '../src/services/translation/planner';
import { TRANSLATION_MODEL } from '../src/services/translation/types';

function fakeAi(response: (signal?: AbortSignal) => Promise<unknown> = async () => ({ source_lang_code: 'eng', source_confidence: 0.9 })) {
  const create = vi.fn(async (_inputs: Record<string, unknown>, options?: { signal?: AbortSignal }) => response(options?.signal));
  return { ai: { chat: { completions: { create } } } as unknown as OpenAI, create };
}
function input(overrides: Partial<PlannerInput> = {}): PlannerInput { return { text: 'Hello world', ...overrides }; }
function pending(signal?: AbortSignal): Promise<never> {
  return new Promise((_resolve, reject) => {
    if (signal?.aborted) reject(new DOMException('Aborted', 'AbortError'));
    else signal?.addEventListener('abort', () => reject(new DOMException('Aborted', 'AbortError')), { once: true });
  });
}

describe('planTranslation — local explicit source', () => {
  it('skips AI, honors the source, and extracts words plus adjacent phrases', async () => {
    const { ai, create } = fakeAi(async () => { throw new Error('must not call'); });
    const result = await planTranslation(ai, input({ sourceLangCode: ' ENG ' }));
    expect(create).not.toHaveBeenCalled();
    expect(result).toMatchObject({ status: 'ok', output: { source_lang_code: 'eng', source_confidence: 1 } });
    if (result.status !== 'ok') return;
    expect(result.output.retrieval_spans.map(s => s.text)).toEqual(['Hello', 'Hello world', 'world']);
  });
  it.each(['cmn', 'nan', 'jpn', 'eng', 'fra', 'arb', 'tha'])('preserves %s identity and codepoint ranges', async code => {
    const { ai, create } = fakeAi();
    const text = '👋這裡天氣不好。 Hello world';
    const result = await planTranslation(ai, input({ text, sourceLangCode: code }));
    expect(create).not.toHaveBeenCalled();
    if (result.status !== 'ok') throw new Error('expected planning');
    expect(result.output.source_lang_code).toBe(code);
    for (const s of result.output.retrieval_spans) {
      expect(Array.from(text).slice(s.start, s.end).join('')).toBe(s.text);
      expect(s.text.trim()).not.toBe(''); expect(s.text).not.toContain('。');
    }
  });
  it('uses Chinese ISO mapping and extracts short phrases after emoji', async () => {
    const result = await planTranslation(fakeAi().ai, input({ text: '👋這裡天氣不好', sourceLangCode: 'cmn' }));
    if (result.status !== 'ok') throw new Error('expected planning');
    expect(result.output.retrieval_spans).toEqual(expect.arrayContaining([
      expect.objectContaining({ start: 1, end: 3, text: '這裡' }),
      expect.objectContaining({ start: 3, end: 5, text: '天氣' }),
      expect.objectContaining({ start: 3, end: 7, text: '天氣不好', reason: 'phrase' }),
    ]));
  });
  it('covers different positions under the hard cap, deduplicates and sorts deterministically', async () => {
    const { ai } = fakeAi();
    const request = input({ text: 'alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima', sourceLangCode: 'eng' });
    const result = await planTranslation(ai, request);
    expect(await planTranslation(ai, request)).toEqual(result);
    if (result.status !== 'ok') throw new Error('expected planning');
    const spans = result.output.retrieval_spans;
    expect(spans).toHaveLength(MAX_PLANNER_SPANS);
    expect(spans.some(s => s.text === 'alpha')).toBe(true);
    expect(spans.some(s => s.text.includes('lima'))).toBe(true);
    expect(spans.some(s => s.reason === 'phrase')).toBe(true);
    expect(new Set(spans.map(s => s.text)).size).toBe(spans.length);
    expect(spans).toEqual([...spans].sort((a,b) => a.start-b.start || a.end-b.end));
  });
  it('does not cross punctuation or line breaks and deduplicates repeated text', async () => {
    const result = await planTranslation(fakeAi().ai, input({ text: 'hello hello, world\nstation', sourceLangCode: 'eng' }));
    if (result.status !== 'ok') throw new Error('expected planning');
    expect(result.output.retrieval_spans.map(s => s.text)).toEqual(['hello', 'hello hello', 'world', 'station']);
  });
  it('honors zero spans without calling AI', async () => {
    const { ai, create } = fakeAi();
    expect(await planTranslation(ai, input({ sourceLangCode: 'eng', limits: { maxSpans: 0, timeoutMs: 1 } }))).toMatchObject({ output: { retrieval_spans: [] } });
    expect(create).not.toHaveBeenCalled();
  });
});

describe('planTranslation — compact detector', () => {
  it('requests only language/confidence, parses SDK JSON, and builds spans locally', async () => {
    const { ai, create } = fakeAi(async () => ({ choices: [{ message: { content: '{"source_lang_code":"eng","source_confidence":0.9}' }, finish_reason: 'stop' }] }));
    expect(await planTranslation(ai, input())).toMatchObject({ status: 'ok', output: { source_lang_code: 'eng', source_confidence: 0.9 } });
    expect(create).toHaveBeenCalledTimes(1);
    const params = create.mock.calls[0][0];
    expect(params.model).toBe(TRANSLATION_MODEL); expect(params.response_format).toEqual({ type: 'json_object' });
    expect(params.chat_template_kwargs).toEqual({ enable_thinking: false });
    expect(params.reasoning_effort).toBeUndefined(); expect(JSON.stringify(params.messages)).not.toContain('retrieval_spans');
  });
  it('ignores legacy model spans', async () => {
    const { ai } = fakeAi(async () => ({ source_lang_code: 'eng', source_confidence: 0.9, retrieval_spans: [{ start: 0, end: 1, text: 'fake' }] }));
    const result = await planTranslation(ai, input());
    if (result.status !== 'ok') throw new Error('expected planning');
    expect(result.output.retrieval_spans.map(s => s.text)).toEqual(['Hello', 'Hello world', 'world']);
  });
  it('requires confirmation below the threshold and honors an override', async () => {
    const { ai } = fakeAi(async () => ({ source_lang_code: 'eng', source_confidence: DEFAULT_SOURCE_CONFIDENCE_THRESHOLD-0.01 }));
    expect(await planTranslation(ai, input())).toEqual({ status: 'confirmation_required' });
    expect((await planTranslation(ai, input({ sourceConfidenceThreshold: 0.6 }))).status).toBe('ok');
  });
  it.each([null, '', 'en', 'unknown', 'eng-US'])('does not fabricate a language for code %s', async code => {
    const { ai } = fakeAi(async () => ({ source_lang_code: code, source_confidence: 0.9 }));
    expect(await planTranslation(ai, input())).toEqual({ status: 'unavailable' });
  });
  it.each(['malformed', { source_lang_code: 'eng', source_confidence: 2 }, { source_lang_code: 'eng', source_confidence: NaN }])('returns unavailable for malformed payload %j', async payload => {
    expect(await planTranslation(fakeAi(async () => payload).ai, input())).toEqual({ status: 'unavailable' });
  });
  it('rejects truncated detector output', async () => {
    const { ai } = fakeAi(async () => ({ choices: [{ message: { content: '{"source_lang_code":"eng","source_confidence":0.9}' }, finish_reason: 'length' }] }));
    expect(await planTranslation(ai, input())).toEqual({ status: 'unavailable' });
  });
  it('degrades provider error without retry', async () => {
    const { ai, create } = fakeAi(async () => { throw new Error('provider failure'); });
    expect(await planTranslation(ai, input())).toEqual({ status: 'unavailable' }); expect(create).toHaveBeenCalledTimes(1);
  });
  it('times out and cleans timers', async () => {
    vi.useFakeTimers();
    try {
      const { ai, create } = fakeAi(pending); const promise = planTranslation(ai, input());
      await vi.advanceTimersByTimeAsync(PLANNER_TIMEOUT_MS+1);
      expect(await promise).toEqual({ status: 'unavailable' }); expect(create).toHaveBeenCalledTimes(1); expect(vi.getTimerCount()).toBe(0);
    } finally { vi.useRealTimers(); }
  });
  it('rejects caller cancellation during detection', async () => {
    const controller = new AbortController(); const promise = planTranslation(fakeAi(pending).ai, input({ signal: controller.signal }));
    controller.abort(); await expect(promise).rejects.toMatchObject({ name: 'AbortError' });
  });
  it.each([null, 'eng'])('does no work for already aborted source %s', async sourceLangCode => {
    const controller = new AbortController(); controller.abort(); const { ai, create } = fakeAi();
    await expect(planTranslation(ai, input({ sourceLangCode, signal: controller.signal }))).rejects.toMatchObject({ name: 'AbortError' });
    expect(create).not.toHaveBeenCalled();
  });
  it('keeps shared defaults', () => expect(DEFAULT_PLANNER_LIMITS).toEqual({ maxSpans: MAX_PLANNER_SPANS, timeoutMs: PLANNER_TIMEOUT_MS }));
});
