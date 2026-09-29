import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { createPinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandbookView from './HandbookView.vue'
import HandbookExpressionInspector from '@/components/handbook/HandbookExpressionInspector.vue'

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

function sourceFingerprint(ids: string[]): string {
  let hash = 2166136261
  for (const character of [...ids].sort().join('\u0000')) {
    hash ^= character.charCodeAt(0)
    hash = Math.imul(hash, 16777619)
  }
  return `${ids.length}-${(hash >>> 0).toString(16)}`
}

function translationCacheKey(handbookId: string, locale: string, ids: string[], version = 'v2'): string {
  const versionSegment = version === 'legacy' ? '' : `${version}:`
  return `handbook:${handbookId}:translations:${versionSegment}${locale}:${sourceFingerprint(ids)}`
}

function lastGraphTargetLanguage(): unknown {
  const calls = mappingGraph.mock.calls
  return calls[calls.length - 1]?.[3]
}

describe('HandbookView', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    window.sessionStorage.clear()
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
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: 'Where is the toilet?', lang_code: 'eng', homograph_index: 1 }] }],
    })
    translations.mockResolvedValue({
      target_locale: 'jpn-Jpan-JP',
      items: [{ source_expression_id: '10', total_translation_count: 3, hidden_translation_count: 2, translations: [{ id: '20', text: 'トイレはどこですか？', lang_code: 'jpn', language_locale_code: 'jpn-Jpan-JP', language_name: 'Japanese', readings: [{ scheme: 'hepburn', value: 'toire wa doko desu ka' }] }] }],
    })

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(translations).toHaveBeenCalledWith('managed-handbook', 'jpn-Jpan-JP', expect.any(Object), expect.any(AbortSignal))
    expect(wrapper.text()).toContain('トイレはどこですか？')
    expect(wrapper.text()).toContain('hepburn: toire wa doko desu ka')
    expect(wrapper.text()).toContain('2 more translations hidden')
    expect(wrapper.find('.hb-no-translation').exists()).toBe(false)
    expect(wrapper.find('.hb-edit-btn').exists()).toBe(false)
  })

  it('does not reuse a translation cache created for a previous handbook expression set', async () => {
    route.params.id = 'managed-handbook'
    route.query = { target_locale: 'jpn-Jpan-JP' }
    window.sessionStorage.setItem(translationCacheKey('managed-handbook', 'jpn-Jpan-JP', ['10'], 'legacy'), JSON.stringify({
      target_locale: 'jpn-Jpan-JP',
      items: [{ source_expression_id: 'old-10', translations: [{ id: '20', text: '舊翻譯', lang_code: 'jpn', language_locale_code: 'jpn-Jpan-JP', language_name: 'Japanese', readings: [] }] }],
    }))
    detail.mockResolvedValue({
      ...handbook('managed-handbook', 'English phrasebook'),
      managed: true,
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: 'Where is the toilet?', lang_code: 'eng', homograph_index: 1 }] }],
    })
    translations.mockResolvedValue({
      target_locale: 'jpn-Jpan-JP',
      items: [{ source_expression_id: '10', translations: [{ id: '21', text: '新翻譯', lang_code: 'jpn', language_locale_code: 'jpn-Jpan-JP', language_name: 'Japanese', readings: [] }] }],
    })

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(translations).toHaveBeenCalledWith('managed-handbook', 'jpn-Jpan-JP', expect.any(Object), expect.any(AbortSignal))
    expect(wrapper.text()).toContain('新翻譯')
    expect(wrapper.text()).not.toContain('舊翻譯')
  })

  it('ignores old empty translation cache entries after the direction change', async () => {
    route.params.id = 'managed-handbook'
    route.query = { target_locale: 'jpn-Jpan-JP' }
    window.sessionStorage.setItem(translationCacheKey('managed-handbook', 'jpn-Jpan-JP', ['10'], 'legacy'), JSON.stringify({
      target_locale: 'jpn-Jpan-JP',
      items: [],
    }))
    detail.mockResolvedValue({
      ...handbook('managed-handbook', 'Chinese phrasebook'),
      managed: true,
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: '你好', lang_code: 'cmn', homograph_index: 1 }] }],
    })
    translations.mockResolvedValue({
      target_locale: 'jpn-Jpan-JP',
      items: [{ source_expression_id: '10', translations: [{ id: '20', text: 'こんにちは', lang_code: 'jpn', language_locale_code: 'jpn-Jpan-JP', language_name: 'Japanese', readings: [] }] }],
    })

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(translations).toHaveBeenCalledOnce()
    expect(wrapper.text()).toContain('こんにちは')
  })

  it('rejects cached translations for a different target locale and reuses a valid v2 entry', async () => {
    route.params.id = 'managed-handbook'
    route.query = { target_locale: 'jpn-Jpan-JP' }
    window.sessionStorage.setItem(translationCacheKey('managed-handbook', 'jpn-Jpan-JP', ['10']), JSON.stringify({
      target_locale: 'cmn-Hant-TW',
      items: [{ source_expression_id: '10', translations: [{ id: '19', text: '錯誤語言快取', lang_code: 'cmn', language_locale_code: 'cmn-Hant-TW', language_name: 'Chinese', readings: [] }] }],
    }))
    detail.mockResolvedValue({
      ...handbook('managed-handbook', 'Chinese phrasebook'),
      managed: true,
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: '你好', lang_code: 'cmn', homograph_index: 1 }] }],
    })
    translations.mockResolvedValue({
      target_locale: 'jpn-Jpan-JP',
      items: [{ source_expression_id: '10', translations: [{ id: '20', text: 'こんにちは', lang_code: 'jpn', language_locale_code: 'jpn-Jpan-JP', language_name: 'Japanese', readings: [] }] }],
    })

    const first = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()
    expect(translations).toHaveBeenCalledOnce()
    expect(first.text()).toContain('こんにちは')
    expect(first.text()).not.toContain('錯誤語言快取')
    first.unmount()

    translations.mockClear()
    const second = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(translations).not.toHaveBeenCalled()
    expect(second.text()).toContain('こんにちは')
    expect(Object.keys(window.sessionStorage).some((key) => key.startsWith('handbook:managed-handbook:translations:v2:jpn-Jpan-JP:'))).toBe(true)
  })

  it('filters graphs by target language for non-English sources but preserves target-language roots', async () => {
    route.params.id = 'managed-handbook'
    route.query = { target_locale: 'jpn-Jpan-JP' }
    detail.mockResolvedValue({
      ...handbook('managed-handbook', 'Chinese phrasebook'),
      managed: true,
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: '你好', lang_code: 'cmn', homograph_index: 1 }] }],
    })
    translations.mockResolvedValue({
      target_locale: 'jpn-Jpan-JP',
      items: [{ source_expression_id: '10', translations: [{ id: '20', text: 'こんにちは', lang_code: 'jpn', language_locale_code: 'jpn-Jpan-JP', language_name: 'Japanese', readings: [] }] }],
    })
    expressionDetail.mockImplementation(async (id: string) => ({
      expression: { id, text: id === '10' ? '你好' : id === '20' ? 'こんにちは' : 'unknown', lang_code: id === '10' ? 'cmn' : 'jpn', homograph_index: 1, source_type: null, source_name: null, language_name: null },
      locales: [], attestations: [], readings: [],
    }))
    mappingGraph.mockResolvedValue({
      root_id: '10', requested_hops: 1, resolved_hops: 0,
      nodes: [{ expression_id: '10', text: '你好', lang_code: 'cmn', homograph_index: 1, language_name: null, depth: 0 }],
      edges: [], layer_counts: { 0: 1, 1: 0 }, truncated: false, omitted_count: 0,
    })

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()
    await wrapper.find('.hb-expr').trigger('click')
    await flushPromises()
    expect(lastGraphTargetLanguage()).toBe('jpn')

    await wrapper.findComponent(HandbookExpressionInspector).vm.$emit('select-expression', '999')
    await flushPromises()
    expect(lastGraphTargetLanguage()).toBeUndefined()

    await wrapper.find('.hb-expr').trigger('click')
    await flushPromises()
    await wrapper.find('.hb-translation').trigger('click')
    await flushPromises()
    expect(lastGraphTargetLanguage()).toBeUndefined()
  })

  it('links the selected expression to its stable text-key mapping path', async () => {
    detail.mockResolvedValue({
      ...handbook('food-handbook', 'Food handbook'),
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '7', text: '食', lang_code: 'nan', homograph_index: 1 }] }],
    })
    expressionDetail.mockResolvedValue({
      expression: { id: '7', text: '食', lang_code: 'nan', homograph_index: 1, source_type: null, source_name: null, language_name: null },
      locales: [],
      attestations: [],
      readings: [],
    })
    mappingGraph.mockResolvedValue({
      root_id: '7',
      requested_hops: 1,
      resolved_hops: 0,
      nodes: [{ expression_id: '7', text: '食', lang_code: 'nan', homograph_index: 1, language_name: null, depth: 0 }],
      edges: [],
      layer_counts: { 0: 1, 1: 0 },
      truncated: false,
      omitted_count: 0,
    })
    route.params.id = 'food-handbook'

    const wrapper = mount(HandbookView, {
      global: {
        plugins: [createPinia()],
        stubs: { RouterLink: { props: ['to'], template: '<a :href="to"><slot /></a>' } },
      },
    })
    await flushPromises()
    await wrapper.find('.hb-expr').trigger('click')
    await flushPromises()

    expect(wrapper.find('a[href="/mapping/nan/%E9%A3%9F"]').exists()).toBe(true)
  })

  it('does not render translation slots for an unmanaged handbook', async () => {
    route.params.id = 'user-handbook'
    route.query = { target_locale: 'jpn-Jpan-JP' }
    detail.mockResolvedValue({
      ...handbook('user-handbook', 'User handbook'),
      sections: [{ id: 'section-1', title: 'Basics', items: [{ id: '10', text: 'Hello', lang_code: 'eng', homograph_index: 1 }] }],
    })

    const wrapper = mount(HandbookView, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(translations).not.toHaveBeenCalled()
    expect(wrapper.find('.hb-no-translation').exists()).toBe(false)
  })
})
