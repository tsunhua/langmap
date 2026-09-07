import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { createPinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandbookView from './HandbookView.vue'

const { detail, expressionDetail, mappingGraph, translations } = vi.hoisted(() => ({
  detail: vi.fn(),
  expressionDetail: vi.fn(),
  mappingGraph: vi.fn(),
  translations: vi.fn(),
}))
const route = reactive<{ params: { id: string }; query?: Record<string, unknown> }>({ params: { id: 'old-handbook' }, query: {} })
const router = { replace: vi.fn() }

vi.mock('@/composables/useHandbooks', () => ({ useHandbooks: () => ({ detail, translations }) }))
vi.mock('@/composables/useExpressions', () => ({
  useExpressions: () => ({ detail: expressionDetail, mappingGraph }),
}))
vi.mock('vue-router', () => ({ useRoute: () => route, useRouter: () => router }))
vi.mock('@/components/mapping/VotePill.vue', () => ({ default: { template: '<div />' } }))
vi.mock('@/components/handbook/HandbookExpressionInspector.vue', () => ({
  default: { name: 'HandbookExpressionInspector', template: '<aside />' },
}))
vi.mock('@/components/handbook/HandbookTranslationPicker.vue', () => ({
  default: { name: 'HandbookTranslationPicker', props: ['modelValue'], template: '<button data-action="pick-locale">{{ modelValue }}</button>' },
}))

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((done) => { resolve = done })
  return { promise, resolve }
}

function handbook(id: string, title: string) {
  return { id, title, score: 0, sections: [] }
}

describe('HandbookView', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    route.params.id = 'old-handbook'
    route.query = {}
  })

  it('keeps the newest route result when an older request finishes later', async () => {
    const old = deferred<ReturnType<typeof handbook>>()
    detail.mockImplementation((id: string) => id === 'old-handbook'
      ? old.promise
      : Promise.resolve(handbook('new-handbook', 'Newest handbook')))

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    route.params.id = 'new-handbook'
    await flushPromises()
    expect(wrapper.text()).toContain('Newest handbook')

    old.resolve(handbook('old-handbook', 'Stale handbook'))
    await flushPromises()

    expect(wrapper.text()).toContain('Newest handbook')
    expect(wrapper.text()).not.toContain('Stale handbook')
  })

  it('loads selected-locale translations once and renders readings below English items', async () => {
    route.params.id = 'managed-handbook'
    route.query = { target_locale: 'jpn-Jpan-JP' }
    detail.mockResolvedValue({
      ...handbook('managed-handbook', 'English phrasebook'),
      managed: true,
      can_edit: false,
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: 'Where is the toilet?', lang_code: 'eng' }] }],
    })
    translations.mockResolvedValue({
      target_locale: 'jpn-Jpan-JP',
      items: [{ source_expression_id: '10', translations: [{ id: '20', text: 'トイレはどこですか？', lang_code: 'jpn', language_locale_code: 'jpn-Jpan-JP', language_name: 'Japanese', readings: [{ scheme: 'hepburn', value: 'toire wa doko desu ka' }] }] }],
    })

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(translations).toHaveBeenCalledWith('managed-handbook', 'jpn-Jpan-JP', expect.any(Object), expect.any(AbortSignal))
    expect(wrapper.text()).toContain('トイレはどこですか？')
    expect(wrapper.text()).toContain('hepburn: toire wa doko desu ka')
    expect(wrapper.find('.hb-edit-btn').exists()).toBe(false)
  })

  it('does not render translation slots for an unmanaged handbook', async () => {
    route.params.id = 'user-handbook'
    route.query = { target_locale: 'jpn-Jpan-JP' }
    detail.mockResolvedValue({
      ...handbook('user-handbook', 'User handbook'),
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: 'Hello', lang_code: 'eng' }] }],
    })

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(translations).not.toHaveBeenCalled()
    expect(wrapper.find('.hb-no-translation').exists()).toBe(false)
  })
})
