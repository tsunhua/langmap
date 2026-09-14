import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { postTranslation, type TranslationRequestInput } from './translation'

type FetchMock = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>

describe('translation API', () => {
  const input: TranslationRequestInput = {
    text: '食飯',
    source_lang_code: null,
    source_locale_code: null,
    target_locale_code: 'cmn-Hant-TW',
  }

  let fetchMock: ReturnType<typeof vi.fn<FetchMock>>

  beforeEach(() => {
    localStorage.clear()
    fetchMock = vi.fn<FetchMock>()
    fetchMock.mockResolvedValue(new Response('{}', { status: 200 }))
    vi.stubGlobal('fetch', fetchMock)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('posts the input as JSON to the translate endpoint without auth by default', async () => {
    const response = await postTranslation(input)
    expect(response).toBeInstanceOf(Response)

    const [url, init] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/v2/translate')
    expect(init?.method).toBe('POST')
    const headers = init?.headers as Record<string, string>
    expect(headers['Content-Type']).toBe('application/json')
    expect(headers.Authorization).toBeUndefined()
    expect(JSON.parse(String(init?.body))).toEqual(input)
  })

  it('sends the bearer token and forwards the abort signal when provided', async () => {
    localStorage.setItem('token', 'secret-token')
    const signal = new AbortController().signal

    await postTranslation(input, { signal })

    const [, init] = fetchMock.mock.calls[0]
    const headers = init?.headers as Record<string, string>
    expect(headers.Authorization).toBe('Bearer secret-token')
    expect(init?.signal).toBe(signal)
  })
})
