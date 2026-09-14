import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount, type VueWrapper } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import { createMemoryHistory, createRouter, type Router } from 'vue-router'
import type { LanguageLocale } from '@/api/languageIdentity'
import type { TranslationEvidence } from '@/api/translation'
import { useContributePrefillStore } from '@/stores/contributePrefill'
import ExpressionTranslation from './ExpressionTranslation.vue'

vi.mock('@/api/translation', () => ({ postTranslation: vi.fn() }))
vi.mock('@/api/languageIdentity', () => ({
  listLanguages: vi.fn().mockResolvedValue({ items: [], total: 0 }),
  listLanguageLocales: vi.fn().mockResolvedValue({ items: [], total: 0 }),
  getLanguageLocale: vi.fn(),
}))

import { postTranslation } from '@/api/translation'
import { getLanguageLocale } from '@/api/languageIdentity'

const encoder = new TextEncoder()

function line(event: unknown): string {
  return `${JSON.stringify({ success: true, data: event })}\n`
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

const flush = () => new Promise<void>((resolve) => setTimeout(resolve, 0))

async function settle() {
  await flush()
  await flushPromises()
  await flush()
  await flushPromises()
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

const LanguagePickerStub = {
  name: 'LanguagePicker',
  props: { modelValue: { type: String, default: '' }, label: { type: String, default: '' } },
  emits: ['update:modelValue'],
  template:
    '<div class="lang-picker-stub"><button type="button" class="pick-source" @click="$emit(\'update:modelValue\', \'nan\')">{{ label }}</button></div>',
}

const LanguageLocalePickerStub = {
  name: 'LanguageLocalePicker',
  props: { modelValue: { type: String, default: '' }, label: { type: String, default: '' } },
  emits: ['update:modelValue'],
  template:
    '<div class="locale-picker-stub"><button type="button" class="pick-target" @click="$emit(\'update:modelValue\', \'cmn-Hant-TW\')">{{ label }}</button></div>',
}

function tokenFor(payload: Record<string, unknown>): string {
  const encoded = btoa(JSON.stringify(payload))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  return `header.${encoded}.signature`
}

interface PageVm {
  submit: () => void
}

interface MountResult {
  wrapper: VueWrapper
  router: Router
}

async function mountPage(options: { loggedIn?: boolean } = {}): Promise<MountResult> {
  const { loggedIn = true } = options
  localStorage.clear()
  if (loggedIn) localStorage.setItem('token', tokenFor({ id: 1, username: 'alice', role: 'user' }))

  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<p>Home</p>' } },
      { path: '/translate', component: ExpressionTranslation },
      { path: '/auth', component: { template: '<p>Auth</p>' } },
      { path: '/contribute', component: { template: '<p>Contribute</p>' } },
    ],
  })
  await router.push('/translate')
  await router.isReady()

  const wrapper = mount(ExpressionTranslation, {
    global: {
      plugins: [pinia, router],
      stubs: {
        LanguagePicker: LanguagePickerStub,
        LanguageLocalePicker: LanguageLocalePickerStub,
      },
    },
    attachTo: document.body,
  })
  return { wrapper, router }
}

async function fillValidForm(wrapper: VueWrapper) {
  await wrapper.get('.pick-target').trigger('click')
  await wrapper.get('#translation-text').setValue('食飯')
}

describe('ExpressionTranslation page', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  it('redirects anonymous visitors to auth with the return path and renders no form', async () => {
    const { wrapper, router } = await mountPage({ loggedIn: false })
    await settle()

    expect(router.currentRoute.value.path).toBe('/auth')
    expect(router.currentRoute.value.query.return).toBe('/translate')
    expect(wrapper.find('form').exists()).toBe(false)
    expect(router.currentRoute.value.fullPath).not.toContain('食飯')
  })

  it('renders the form when logged in and sends the picked source/target and text', async () => {
    vi.mocked(postTranslation).mockImplementation(() => Promise.resolve(streamResponse([resultLine()])))
    const { wrapper } = await mountPage()

    expect(wrapper.find('form').exists()).toBe(true)
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    expect(postTranslation).toHaveBeenCalledTimes(1)
    expect(vi.mocked(postTranslation).mock.calls[0][0]).toEqual({
      text: '食飯',
      source_lang_code: null,
      source_locale_code: null,
      target_locale_code: 'cmn-Hant-TW',
    })
  })

  it('advances the three-stage progress as the stream reports each stage', async () => {
    const stream = controllableResponse()
    vi.mocked(postTranslation).mockImplementation(() => Promise.resolve(stream.response))
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await flush()

    stream.send(line({ type: 'status', stage: 'analyzing', mode: 'assisted', request_id: 'req-1' }))
    await flush()
    await nextTick()
    expect(wrapper.findAll('.stage')).toHaveLength(3)
    expect(wrapper.get('.stage[data-state="active"]').text()).toContain('Analyzing')
    expect(wrapper.get('.translation-progress').attributes('aria-live')).toBe('polite')
    expect(wrapper.get('.translation-progress').attributes('role')).toBe('status')

    stream.send(line({ type: 'status', stage: 'retrieving', mode: 'assisted', request_id: 'req-1' }))
    await flush()
    await nextTick()
    expect(wrapper.get('.stage[data-state="active"]').text()).toContain('Retrieving')

    stream.send(line({ type: 'status', stage: 'generating', mode: 'assisted', request_id: 'req-1' }))
    await flush()
    await nextTick()
    expect(wrapper.get('.stage[data-state="active"]').text()).toContain('Generating')

    stream.close()
    await settle()
  })

  it('omits the analyzing stage on the exact-match fast path', async () => {
    vi.mocked(postTranslation).mockImplementation(() =>
      Promise.resolve(streamResponse([
        line({ type: 'status', stage: 'retrieving', mode: 'exact_lookup', request_id: 'req-1' }),
        line({ type: 'evidence', items: [evidence], omitted_count: 0, degraded: false }),
        resultLine({ resolution: 'exact_lookup', generation_skipped: true }),
      ])),
    )
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    const stages = wrapper.findAll('.stage')
    expect(stages).toHaveLength(1)
    expect(stages[0].text()).toContain('Retrieving')
    expect(wrapper.text()).not.toContain('Analyzing the text')
  })

  it('renders the evidence panel when references arrive', async () => {
    vi.mocked(postTranslation).mockImplementation(() =>
      Promise.resolve(streamResponse([
        line({ type: 'status', stage: 'retrieving', mode: 'assisted', request_id: 'req-1' }),
        line({ type: 'evidence', items: [evidence], omitted_count: 0, degraded: false }),
        resultLine(),
      ])),
    )
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    expect(wrapper.findAll('.evidence-item')).toHaveLength(1)
    expect(wrapper.get('.evidence-source').text()).toBe('食飯')
  })

  it('shows a degraded, empty evidence panel for model-only results', async () => {
    vi.mocked(postTranslation).mockImplementation(() =>
      Promise.resolve(streamResponse([
        line({ type: 'status', stage: 'retrieving', mode: 'assisted', request_id: 'req-1' }),
        line({ type: 'evidence', items: [], omitted_count: 0, degraded: true }),
        resultLine({ model_only: true }),
      ])),
    )
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    expect(wrapper.findAll('.evidence-item')).toHaveLength(0)
    expect(wrapper.find('.evidence-degraded').exists()).toBe(true)
    expect(wrapper.find('.evidence-empty').exists()).toBe(true)
  })

  it('shows at most two reference alternatives', async () => {
    vi.mocked(postTranslation).mockImplementation(() =>
      Promise.resolve(streamResponse([resultLine({ alternatives: ['一', '二', '三'] })])),
    )
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    const alternatives = wrapper.findAll('.alternatives li')
    expect(alternatives).toHaveLength(2)
    expect(alternatives.map((item) => item.text())).toEqual(['一', '二'])
  })

  it('offers copy handled by the result component', async () => {
    vi.mocked(postTranslation).mockImplementation(() => Promise.resolve(streamResponse([resultLine()])))
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    expect(wrapper.find('[data-action="copy"]').exists()).toBe(true)
  })

  it('resubmits the last input on retry', async () => {
    vi.mocked(postTranslation).mockImplementation(() => Promise.resolve(streamResponse([resultLine()])))
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    await wrapper.get('[data-action="retry"]').trigger('click')
    await settle()

    expect(postTranslation).toHaveBeenCalledTimes(2)
    expect(vi.mocked(postTranslation).mock.calls[0][0]).toEqual(vi.mocked(postTranslation).mock.calls[1][0])
  })

  it('keeps the user text and focuses the form on edit', async () => {
    vi.mocked(postTranslation).mockImplementation(() => Promise.resolve(streamResponse([resultLine()])))
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    await wrapper.get('[data-action="edit"]').trigger('click')
    await nextTick()

    const textarea = wrapper.get('#translation-text').element
    expect((textarea as HTMLTextAreaElement).value).toBe('食飯')
    expect(document.activeElement).toBe(textarea)
  })

  it('aborts the in-flight request when canceled', async () => {
    const stream = controllableResponse()
    vi.mocked(postTranslation).mockImplementation(() => Promise.resolve(stream.response))
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await flush()

    const signal = vi.mocked(postTranslation).mock.calls[0][1]?.signal
    expect(signal?.aborted).toBe(false)

    await wrapper.get('[data-action="cancel"]').trigger('click')

    expect(signal?.aborted).toBe(true)
    expect(wrapper.find('[data-action="cancel"]').exists()).toBe(false)

    stream.close()
    await settle()
  })

  it('discards deltas from a stale stream after a newer submit', async () => {
    const first = controllableResponse()
    const second = controllableResponse()
    vi.mocked(postTranslation)
      .mockReturnValueOnce(Promise.resolve(first.response))
      .mockReturnValueOnce(Promise.resolve(second.response))
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await flush()

    first.send(line({ type: 'translation_delta', text: 'OLD' }))
    await flush()

    ;(wrapper.vm as unknown as PageVm).submit()
    await flush()

    second.send(line({ type: 'translation_delta', text: 'NEW' }))
    second.close()
    await settle()
    first.close()
    await settle()

    expect(wrapper.get('.translation').text()).toContain('NEW')
    expect(wrapper.get('.translation').text()).not.toContain('OLD')
  })

  it('resubmits with the chosen source language when confirmation is required', async () => {
    const stream = controllableResponse()
    vi.mocked(postTranslation)
      .mockReturnValueOnce(Promise.resolve(stream.response))
      .mockImplementation(() => Promise.resolve(streamResponse([resultLine()])))
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await flush()

    stream.send(line({
      type: 'source_confirmation_required',
      candidates: [{ code: 'nan', confidence: 0.42 }],
      reason: 'Multiple possible source languages',
    }))
    await settle()

    expect(wrapper.find('.source-confirmation').exists()).toBe(true)
    expect(wrapper.get('.source-confirmation').text()).toContain('Confirm the source language')

    await wrapper.get('.source-confirmation .pick-source').trigger('click')
    await wrapper.get('[data-action="confirm-source"]').trigger('click')
    await settle()

    expect(postTranslation).toHaveBeenCalledTimes(2)
    expect(vi.mocked(postTranslation).mock.calls[1][0]).toMatchObject({
      source_lang_code: 'nan',
      target_locale_code: 'cmn-Hant-TW',
    })
  })

  it('populates the contribute prefill with the main pair and navigates without a query', async () => {
    vi.mocked(getLanguageLocale).mockResolvedValue({ code: 'cmn-Hant-TW', lang_code: 'cmn' } as LanguageLocale)
    vi.mocked(postTranslation).mockImplementation(() =>
      Promise.resolve(streamResponse([
        line({ type: 'source_language', code: 'nan', confidence: 0.9 }),
        resultLine({ alternatives: ['參考一', '參考二'] }),
      ])),
    )
    const { wrapper, router } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    await wrapper.get('[data-action="send-to-contribute"]').trigger('click')
    await settle()

    const store = useContributePrefillStore()
    expect(store.prefill).toEqual({
      sourceLangCode: 'nan',
      sourceLocaleCode: '',
      sourceText: '食飯',
      targetLangCode: 'cmn',
      targetLocaleCode: 'cmn-Hant-TW',
      targetText: '吃飯',
      aiAssisted: true,
    })
    expect(JSON.stringify(store.prefill)).not.toContain('參考一')
    expect(router.currentRoute.value.path).toBe('/contribute')
    expect(router.currentRoute.value.fullPath).toBe('/contribute')
    expect(router.currentRoute.value.query).toEqual({})
  })

  it('marks exact-match results as not AI-assisted in the prefill', async () => {
    vi.mocked(getLanguageLocale).mockResolvedValue({ code: 'cmn-Hant-TW', lang_code: 'cmn' } as LanguageLocale)
    vi.mocked(postTranslation).mockImplementation(() =>
      Promise.resolve(streamResponse([
        line({ type: 'source_language', code: 'nan', confidence: 1 }),
        resultLine({ resolution: 'exact_lookup', generation_skipped: true }),
      ])),
    )
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    await wrapper.get('[data-action="send-to-contribute"]').trigger('click')
    await settle()

    expect(useContributePrefillStore().prefill?.aiAssisted).toBe(false)
  })

  it('exposes an alert for errors and a polite live region for progress', async () => {
    vi.mocked(postTranslation).mockImplementation(() =>
      Promise.resolve(streamResponse([
        line({ type: 'status', stage: 'generating', mode: 'assisted', request_id: 'req-1' }),
        line({ type: 'error', code: 'TRANSLATION_TIMEOUT', retryable: true }),
      ])),
    )
    const { wrapper } = await mountPage()
    await fillValidForm(wrapper)
    await wrapper.get('[data-action="submit"]').trigger('click')
    await settle()

    const alert = wrapper.get('[role="alert"]')
    expect(alert.text()).toContain('Translation failed')
    expect(wrapper.get('.translation-progress').attributes('aria-live')).toBe('assertive')
  })
})
