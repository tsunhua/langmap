import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { TranslationEvidence, TranslationRequestInput } from '@/api/translation'
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
      line({ type: 'status', stage: 'retrieving', mode: 'assisted', request_id: 'req-1' }),
      line({ type: 'evidence', items: [evidence], omitted_count: 0, degraded: false }),
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
    expect(stream.evidence.value).toEqual([evidence])
    expect(stream.translation.value).toBe('吃飯')
    expect(stream.result.value?.translation).toBe('吃飯')
    expect(stream.result.value?.resolution).toBe('assisted')
    expect(stream.error.value).toBeNull()
    expect(stream.isStreaming.value).toBe(false)
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
  })

  it('surfaces a streamed error envelope with reset_at', async () => {
    stubFetch().mockResolvedValue(streamResponse([
      line({ type: 'status', stage: 'generating', mode: 'assisted', request_id: 'req-2' }),
      errorLine({
        error: 'AI_DAILY_QUOTA_EXHAUSTED',
        message: 'Workers AI daily quota exhausted.',
        retryable: false,
        reset_at: '2026-09-15T00:00:00.000Z',
      }),
    ]))

    const stream = useTranslationStream()
    await stream.submit(input)

    expect(stream.error.value).toEqual({
      code: 'AI_DAILY_QUOTA_EXHAUSTED',
      message: 'Workers AI daily quota exhausted.',
      retryable: false,
      resetAt: '2026-09-15T00:00:00.000Z',
    })
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
    expect(stream.evidence.value).toEqual([])
    expect(stream.stage.value).toBeNull()
    expect(stream.isStreaming.value).toBe(false)
  })
})
