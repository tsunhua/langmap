import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { defineComponent, h } from 'vue'
import { mount } from '@vue/test-utils'
import type { TranslationEvidence, TranslationPlannerSpan, TranslationRequestInput } from '@/api/translation'
import { useTranslationStream } from './useTranslationStream'

type FetchMock = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>

const encoder = new TextEncoder()

function line(event: unknown): string {
  return `${JSON.stringify({ success: true, data: event })}\n`
}

function errorLine(payload: Record<string, unknown>): string {
  return `${JSON.stringify({ success: false, ...payload })}\n`
}

function streamResponse(chunks: string[]): Response {
  return new Response(
    new ReadableStream<Uint8Array>({
      start(controller) {
        for (const chunk of chunks) controller.enqueue(encoder.encode(chunk))
        controller.close()
      },
    }),
    { status: 200, headers: { 'Content-Type': 'application/x-ndjson; charset=utf-8' } },
  )
}

function bytesResponse(chunks: Uint8Array[]): Response {
  return new Response(
    new ReadableStream<Uint8Array>({
      start(controller) {
        for (const chunk of chunks) controller.enqueue(chunk)
        controller.close()
      },
    }),
    { status: 200, headers: { 'Content-Type': 'application/x-ndjson; charset=utf-8' } },
  )
}

interface ControllableStream {
  response: Response
  send: (chunk: string) => void
  close: () => void
}

function controllableResponse(): ControllableStream {
  let controller!: ReadableStreamDefaultController<Uint8Array>
  const response = new Response(
    new ReadableStream<Uint8Array>({
      start(c) {
        controller = c
      },
    }),
    { status: 200, headers: { 'Content-Type': 'application/x-ndjson; charset=utf-8' } },
  )
  return {
    response,
    send: (chunk) => controller.enqueue(encoder.encode(chunk)),
    close: () => controller.close(),
  }
}

function stubFetch() {
  const fetchMock = vi.fn<FetchMock>()
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

const flush = () => new Promise<void>((resolve) => setTimeout(resolve, 0))

const input: TranslationRequestInput = {
  text: '食飯',
  source_lang_code: null,
  source_locale_code: null,
  target_locale_code: 'cmn-Hant-TW',
}

const evidence: TranslationEvidence = {
  source_text: '食飯',
  target_text: '吃飯',
  target_locale_code: 'cmn-Hant-TW',
  path_type: 'direct',
  match_type: 'exact',
  source_markers: ['01'],
}

const segmentationSpan: TranslationPlannerSpan = {
  start: 0,
  end: 2,
  text: '食飯',
  reason: 'phrase',
  confidence: 0.91,
}

function resultLine(overrides: Record<string, unknown> = {}): string {
  return line({
    type: 'result',
    translation: '吃飯',
    alternatives: [],
    source_lang_code: 'nan',
    target_locale_code: 'cmn-Hant-TW',
    evidence_present: true,
    model_only: false,
    resolution: 'assisted',
    generation_skipped: false,
    request_id: 'req-1',
    ...overrides,
  })
}

describe('useTranslationStream', () => {
  beforeEach(() => {
    localStorage.clear()
    // useLatestRequest registers onUnmounted; a bare unit test has no component.
    vi.spyOn(console, 'warn').mockImplementation(() => undefined)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('accumulates deltas and finishes on the result event', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'status', stage: 'analyzing', mode: 'assisted', request_id: 'req-1' }),
      line({ type: 'source_language', code: 'nan', confidence: 0.87 }),
      line({ type: 'segmentation', spans: [segmentationSpan] }),
      line({ type: 'status', stage: 'retrieving', mode: 'assisted', request_id: 'req-1' }),
      line({ type: 'evidence', items: [evidence], omitted_count: 0, degraded: false, retrieval_status: 'matched' }),
      line({ type: 'status', stage: 'generating', mode: 'assisted', request_id: 'req-1' }),
      line({ type: 'translation_delta', text: '吃' }),
      line({ type: 'translation_delta', text: '飯' }),
      resultLine(),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.requestId.value).toBe('req-1')
    expect(stream.stage.value).toBe('generating')
    expect(stream.mode.value).toBe('assisted')
    expect(stream.sourceLanguage.value).toEqual({ code: 'nan', confidence: 0.87 })
    expect(stream.segmentation.value).toEqual([segmentationSpan])
    expect(stream.evidence.value).toEqual({
      items: [evidence],
      omittedCount: 0,
      degraded: false,
      retrievalStatus: 'matched',
    })
    expect(stream.translation.value).toBe('吃飯')
    expect(stream.result.value?.translation).toBe('吃飯')
    expect(stream.result.value?.resolution).toBe('assisted')
    expect(stream.error.value).toBeNull()
    expect(stream.isStreaming.value).toBe(false)
  })

  it('carries evidence truncation and degraded metadata', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'evidence', items: [evidence], omitted_count: 7, degraded: true, retrieval_status: 'failed' }),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.evidence.value).toEqual({
      items: [evidence],
      omittedCount: 7,
      degraded: true,
      retrievalStatus: 'failed',
    })
  })

  it('carries an empty segmentation result when analysis finds no usable spans', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'segmentation', spans: [] }),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.segmentation.value).toEqual([])
  })

  it('uses the result translation for exact lookups that stream no deltas', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'status', stage: 'retrieving', mode: 'exact_lookup', request_id: 'req-4' }),
      line({ type: 'evidence', items: [evidence], omitted_count: 0, degraded: false }),
      resultLine({
        translation: '吃飯',
        alternatives: ['食'],
        resolution: 'exact_lookup',
        generation_skipped: true,
        request_id: 'req-4',
      }),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.translation.value).toBe('吃飯')
    expect(stream.result.value?.generation_skipped).toBe(true)
    expect(stream.result.value?.alternatives).toEqual(['食'])
  })

  it('buffers a JSON line split across chunk boundaries', async () => {
    const payload = line({ type: 'translation_delta', text: '你好' })
    const split = Math.floor(payload.length / 2)
    stubFetch().mockResolvedValue(streamResponse([payload.slice(0, split), payload.slice(split)]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.translation.value).toBe('你好')
  })

  it('stitches a multibyte UTF-8 character split across byte chunks', async () => {
    const payload = encoder.encode(line({ type: 'translation_delta', text: '食飯' }))
    const lead = payload.indexOf(0xe9)
    expect(lead).toBeGreaterThanOrEqual(0)
    const split = lead + 1
    stubFetch().mockResolvedValue(bytesResponse([payload.slice(0, split), payload.slice(split)]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.translation.value).toBe('食飯')
  })

  it('parses a trailing line that has no final newline', async () => {
    const trailing = JSON.stringify({
      success: true,
      data: {
        type: 'result',
        translation: '尾',
        alternatives: [],
        source_lang_code: 'nan',
        target_locale_code: 'cmn-Hant-TW',
        evidence_present: false,
        model_only: true,
        resolution: 'assisted',
        generation_skipped: false,
        request_id: 'req-tail',
      },
    })
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'translation_delta', text: '尾' }),
      trailing,
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.result.value?.translation).toBe('尾')
    expect(stream.translation.value).toBe('尾')
  })

  it('ignores events from a stream superseded by a newer submit', async () => {
    const first = controllableResponse()
    const second = controllableResponse()
    const fetchMock = stubFetch()
    fetchMock.mockResolvedValueOnce(first.response).mockResolvedValueOnce(second.response)

    const stream = useTranslationStream()
    const firstRun = stream.submit(input)
    await flush()
    const secondRun = stream.submit(input)
    await flush()

    first.send(line({ type: 'translation_delta', text: 'OLD' }))
    second.send(line({ type: 'translation_delta', text: 'NEW' }))
    second.close()
    first.close()

    await Promise.all([firstRun, secondRun])

    expect(stream.translation.value).toBe('NEW')
  })

  it('cancels the in-flight request and ignores later chunks', async () => {
    const active = controllableResponse()
    const fetchMock = stubFetch()
    fetchMock.mockResolvedValue(active.response)

    const stream = useTranslationStream()
    const run = stream.submit(input)
    await flush()

    const signal = fetchMock.mock.calls[0][1]?.signal as AbortSignal
    stream.cancel()

    expect(signal.aborted).toBe(true)
    expect(stream.isStreaming.value).toBe(false)

    active.send(line({ type: 'translation_delta', text: 'LATE' }))
    active.close()
    await run

    expect(stream.translation.value).toBe('')
    expect(stream.result.value).toBeNull()
    expect(stream.error.value).toBeNull()
  })

  it('does not surface an error when the request is aborted', async () => {
    stubFetch().mockRejectedValue(new DOMException('Aborted', 'AbortError'))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.error.value).toBeNull()
    expect(stream.isStreaming.value).toBe(false)
  })

  it('surfaces a streamed error envelope with retry hints', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'status', stage: 'generating', mode: 'assisted', request_id: 'req-2' }),
      errorLine({
        error: 'AI_DAILY_QUOTA_EXHAUSTED',
        message: 'Workers AI daily quota exhausted.',
        retryable: false,
        retry_after_seconds: 45,
        reset_at: '2026-09-15T00:00:00.000Z',
      }),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.error.value).toEqual({
      code: 'AI_DAILY_QUOTA_EXHAUSTED',
      message: 'Workers AI daily quota exhausted.',
      retryable: false,
      retryAfterSeconds: 45,
      resetAt: '2026-09-15T00:00:00.000Z',
    })
    expect(stream.retryAfterSeconds.value).toBe(45)
    expect(stream.resetAt.value).toBe('2026-09-15T00:00:00.000Z')
    expect(stream.isStreaming.value).toBe(false)
  })

  it('surfaces an in-stream error event with retry hints', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'status', stage: 'generating', mode: 'assisted', request_id: 'req-5' }),
      line({
        type: 'error',
        code: 'TRANSLATION_TIMEOUT',
        retryable: true,
        retry_after_seconds: 30,
        reset_at: '2026-09-15T00:00:00.000Z',
      }),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.error.value?.code).toBe('TRANSLATION_TIMEOUT')
    expect(stream.error.value?.retryable).toBe(true)
    expect(stream.retryAfterSeconds.value).toBe(30)
    expect(stream.resetAt.value).toBe('2026-09-15T00:00:00.000Z')
    expect(stream.isStreaming.value).toBe(false)
  })

  it('surfaces a pre-stream JSON envelope when the response is not ok', async () => {
    stubFetch().mockResolvedValue(new Response(
      JSON.stringify({ success: false, error: 'AUTH_REQUIRED', message: 'Authentication required.' }),
      { status: 401, headers: { 'Content-Type': 'application/json' } },
    ))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.error.value).toEqual({
      code: 'AUTH_REQUIRED',
      message: 'Authentication required.',
      retryable: false,
    })
    expect(stream.isStreaming.value).toBe(false)
  })

  it('ends streaming when the source language needs confirmation', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'status', stage: 'retrieving', mode: 'exact_lookup', request_id: 'req-3' }),
      line({
        type: 'source_confirmation_required',
        candidates: [{ code: 'nan', confidence: 0.42 }],
        reason: 'Multiple possible source languages',
      }),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.confirmation.value).toEqual({
      candidates: [{ code: 'nan', confidence: 0.42 }],
      reason: 'Multiple possible source languages',
    })
    expect(stream.isStreaming.value).toBe(false)
    expect(stream.result.value).toBeNull()
  })

  it('skips malformed lines and unknown event types without throwing', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      '{not json\n',
      line({ type: 'mystery', payload: 1 }),
      line({ type: 'translation_delta', text: 'ok' }),
    ]))

    const stream = useTranslationStream()
    await expect(stream.submit(input)).resolves.toBeUndefined()

    expect(stream.translation.value).toBe('ok')
    expect(stream.error.value).toBeNull()
    expect(stream.isStreaming.value).toBe(false)
  })

  it('reports a generic error when the network request fails', async () => {
    stubFetch().mockRejectedValue(new TypeError('Failed to fetch'))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.error.value?.code).toBe('NETWORK_ERROR')
    expect(stream.isStreaming.value).toBe(false)
  })

  it('resets all state', async () => {
    stubFetch().mockResolvedValue(streamResponse([resultLine()]))

    const stream = useTranslationStream()
    await stream.submit(input)
    stream.reset()

    expect(stream.translation.value).toBe('')
    expect(stream.result.value).toBeNull()
    expect(stream.error.value).toBeNull()
    expect(stream.evidence.value).toBeNull()
    expect(stream.segmentation.value).toBeNull()
    expect(stream.stage.value).toBeNull()
    expect(stream.isStreaming.value).toBe(false)
  })

  it('aborts the active request when the component unmounts', async () => {
    const active = controllableResponse()
    const fetchMock = stubFetch()
    fetchMock.mockResolvedValue(active.response)

    let stream!: ReturnType<typeof useTranslationStream>
    const wrapper = mount(defineComponent({
      setup() {
        stream = useTranslationStream()
        return () => h('div')
      },
    }))

    const run = stream.submit(input)
    await flush()
    const signal = fetchMock.mock.calls[0][1]?.signal as AbortSignal

    wrapper.unmount()

    expect(signal.aborted).toBe(true)
    expect(stream.isStreaming.value).toBe(false)

    active.close()
    await run
    expect(stream.error.value).toBeNull()
  })
})
