import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia, type Pinia } from 'pinia'
import { reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MappingDetail from './MappingDetail.vue'
import { useAuthStore } from '@/stores/auth'

const { detail, mappingGraph, push, replace } = vi.hoisted(() => ({
  detail: vi.fn(),
  mappingGraph: vi.fn(),
  push: vi.fn(),
  replace: vi.fn(),
}))

vi.mock('@/stores/languages', () => ({
  useLanguagesStore: () => ({
    fetchLanguages: vi.fn().mockResolvedValue(undefined),
    getName: (code: string) => ({ eng: 'English', nan: 'Taiwanese', jpn: 'Japanese' }[code] ?? code),
  }),
}))
const route = reactive<{ params: { id: string }; query: Record<string, string> }>({
  params: { id: 'old' },
  query: {},
})

vi.mock('@/composables/useExpressions', () => ({
  useExpressions: () => ({ detail, mappingGraph }),
}))
vi.mock('@/api/expressions', () => ({
  createExpression: vi.fn(),
  getExpressionEdges: vi.fn(),
  splitExpression: vi.fn(),
}))
vi.mock('vue-router', () => ({
  useRoute: () => route,
  useRouter: () => ({ push, replace }),
}))

const passiveComponent = { template: '<div><slot /></div>' }
const MappingGraphStub = {
  props: ['graph', 'currentHops', 'maxHops'],
  emits: ['change-hops'],
  template: `
    <div class="mapping-graph-stub" :data-hops="currentHops">
      <span class="graph-label">{{ graph.nodes[1]?.text }}</span>
      <button v-if="maxHops >= 2" class="hop-2" @click="$emit('change-hops', 2)">2 hops</button>
      <button v-if="maxHops >= 3" class="hop-3" @click="$emit('change-hops', 3)">3 hops</button>
    </div>
  `,
}
const LanguageSelectStub = {
  name: 'LanguageSelect',
  props: ['modelValue', 'options'],
  template: '<div data-testid="language-options">{{ JSON.stringify(options) }}</div>',
}

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((done) => { resolve = done })
  return { promise, resolve }
}

function expression(id: string, text: string) {
  return {
    expression: { id, text, lang_code: 'eng', source_type: 'user', source_name: null },
    attestations: [],
    readings: [],
  }
}

function graph(id: string, requestedHops: 1 | 2 | 3 = 1) {
  return {
    root_id: id,
    requested_hops: requestedHops,
    resolved_hops: 0,
    nodes: [{ expression_id: id, text: id, lang_code: 'eng', language_name: 'English', depth: 0 }],
    edges: [],
    layer_counts: { 0: 1 } as Record<number, number>,
    truncated: false,
    omitted_count: 0,
  }
}

function languageGraph(id: string, requestedHops: 1 | 2 | 3 = 2) {
  const value = graph(id, requestedHops)
  value.nodes.push(
    { expression_id: 'nan-1', text: 'nan 1', lang_code: 'nan', language_name: 'Taiwanese', depth: 1 },
    { expression_id: 'nan-2', text: 'nan 2', lang_code: 'nan', language_name: 'Taiwanese', depth: 2 },
    { expression_id: 'eng-1', text: 'eng 1', lang_code: 'eng', language_name: 'English', depth: 1 },
  )
  value.layer_counts[1] = 2
  value.layer_counts[2] = 1
  return value
}

function mountPage(pinia: Pinia = createPinia()) {
  return mount(MappingDetail, {
    global: {
      plugins: [pinia],
      stubs: {
        RouterLink: { props: ['to'], template: '<a><slot /></a>' },
        LanguagePicker: passiveComponent,
        MappingGraph: MappingGraphStub,
        MappingGraphSkeleton: passiveComponent,
        MappingHierarchyList: passiveComponent,
        GraphInspector: passiveComponent,
        GraphMobileInspector: passiveComponent,
        ExpressionSplitDialog: passiveComponent,
        MorphologyPanel: passiveComponent,
        LangBadge: passiveComponent,
        LanguageSelect: LanguageSelectStub,
      },
    },
  })
}

function signedInPinia() {
  const pinia = createPinia()
  setActivePinia(pinia)
  useAuthStore().token = 'session'
  return pinia
}

describe('MappingDetail page state', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    route.params.id = 'old'
    route.query = {}
    Object.defineProperty(window, 'matchMedia', {
      configurable: true,
      value: vi.fn(() => ({
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })),
    })
  })

  it('passes counted languages from the unfiltered graph to LanguageSelect', async () => {
    route.params.id = 'anchor'
    route.query = { hops: '2' }
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    mappingGraph.mockResolvedValue(languageGraph('anchor'))

    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.get('[data-testid="language-options"]').text()).toBe(JSON.stringify([
      { code: 'nan', name: 'Taiwanese', count: 2 },
      { code: 'eng', name: 'English', count: 1 },
    ]))
  })

  it('keeps the full option list when a filtered graph contains only the root', async () => {
    route.params.id = 'anchor'
    route.query = { target_language: 'eng' }
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    mappingGraph.mockImplementation((_id: string, _hops: number, _hints: unknown, target?: string) =>
      Promise.resolve(target ? graph('anchor') : languageGraph('anchor')))

    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.get('[data-testid="language-options"]').text()).toContain('nan')
    expect(wrapper.get('[data-testid="language-options"]').text()).toContain('eng')
    expect(mappingGraph).toHaveBeenCalledWith('anchor', 1, expect.anything(), 'eng')
    expect(mappingGraph).toHaveBeenCalledWith('anchor', 1, expect.anything())
  })

  it('keeps the newest route result when an older request finishes later', async () => {
    const oldDetail = deferred<ReturnType<typeof expression>>()
    detail.mockImplementation((id: string) => id === 'old'
      ? oldDetail.promise
      : Promise.resolve(expression('new', 'Newest expression')))
    mappingGraph.mockImplementation((id: string) => Promise.resolve(graph(id)))

    const wrapper = mountPage()
    route.params.id = 'new'
    await flushPromises()
    expect(wrapper.text()).toContain('Newest expression')

    oldDetail.resolve(expression('old', 'Stale expression'))
    await flushPromises()

    expect(wrapper.text()).toContain('Newest expression')
    expect(wrapper.text()).not.toContain('Stale expression')
  })

  it('keeps the newest hop result when hop requests finish out of order', async () => {
    route.params.id = 'anchor'
    const secondHop = deferred<ReturnType<typeof graph>>()
    const thirdHop = deferred<ReturnType<typeof graph>>()
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    mappingGraph.mockImplementation((_id: string, hops: number) => {
      if (hops === 2) return secondHop.promise
      if (hops === 3) return thirdHop.promise
      const value = graph('anchor')
      value.nodes.push({ expression_id: 'initial', text: 'Initial graph', lang_code: 'nan', language_name: 'Taiwanese', depth: 1 })
      value.layer_counts[1] = 1
      return Promise.resolve(value)
    })

    const wrapper = mountPage(signedInPinia())
    await flushPromises()
    const hop2 = wrapper.get('.hop-2').element as HTMLButtonElement
    const hop3 = wrapper.get('.hop-3').element as HTMLButtonElement
    hop2.click()
    hop3.click()

    const newest = graph('anchor')
    newest.nodes.push({ expression_id: 'newest', text: 'Newest graph', lang_code: 'nan', language_name: 'Taiwanese', depth: 1 })
    newest.layer_counts[1] = 1
    thirdHop.resolve(newest)
    await flushPromises()
    expect(wrapper.text()).toContain('Newest graph')

    const stale = graph('anchor')
    stale.nodes.push({ expression_id: 'stale', text: 'Stale graph', lang_code: 'nan', language_name: 'Taiwanese', depth: 1 })
    stale.layer_counts[1] = 1
    secondHop.resolve(stale)
    await flushPromises()

    expect(wrapper.text()).toContain('Newest graph')
    expect(wrapper.text()).not.toContain('Stale graph')
  })

  it('keeps the hop selector aligned with the loaded graph when a hop request fails', async () => {
    route.params.id = 'anchor'
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    const initial = graph('anchor')
    initial.nodes.push({ expression_id: 'initial', text: 'Initial graph', lang_code: 'nan', language_name: 'Taiwanese', depth: 1 })
    initial.layer_counts[1] = 1
    mappingGraph.mockImplementation((_id: string, hops: number) => hops === 3
      ? Promise.reject(new Error('hop request failed'))
      : Promise.resolve(initial))

    const wrapper = mountPage(signedInPinia())
    await flushPromises()
    await wrapper.get('.hop-3').trigger('click')
    await flushPromises()

    expect(wrapper.get('.mapping-graph-stub').attributes('data-hops')).toBe('1')
    expect(wrapper.text()).toContain('Initial graph')
    expect(wrapper.find('.md-graph-error').exists()).toBe(true)
  })

  it('limits anonymous users to two hops', async () => {
    route.params.id = 'anchor'
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    const value = graph('anchor')
    value.nodes.push({ expression_id: 'related', text: 'Related', lang_code: 'nan', language_name: 'Taiwanese', depth: 1 })
    value.layer_counts[1] = 1
    mappingGraph.mockResolvedValue(value)

    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.find('.hop-2').exists()).toBe(true)
    expect(wrapper.find('.hop-3').exists()).toBe(false)
  })

  it('downgrades a three-hop URL for anonymous users', async () => {
    route.params.id = 'anchor'
    route.query = { hops: '3' }
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    mappingGraph.mockResolvedValue(graph('anchor'))

    const wrapper = mountPage()
    await flushPromises()

    expect(mappingGraph).toHaveBeenCalledWith('anchor', 2, expect.anything(), undefined)
    expect((wrapper.vm as any).hops).toBe(2)
  })

  it('does not show the no-mappings state when the graph has a related expression', async () => {
    route.params.id = 'anchor'
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    const value = graph('anchor')
    value.nodes.push({ expression_id: 'related', text: 'Related', lang_code: 'nan', language_name: 'Taiwanese', depth: 1 })
    value.layer_counts[1] = 1
    mappingGraph.mockResolvedValue(value)

    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.find('.mapping-graph-stub').exists()).toBe(true)
    expect(wrapper.find('.md-empty').exists()).toBe(false)
  })

  it('sends signed-out users to /auth when adding a word-form link', async () => {
    route.params.id = 'anchor'
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    mappingGraph.mockResolvedValue(graph('anchor'))

    const wrapper = mountPage()
    await flushPromises()

    await wrapper.get('[aria-controls="morph-form"]').trigger('click')
    expect(push).toHaveBeenCalledWith('/auth')
  })

  it('toggles the word-form form for signed-in users', async () => {
    route.params.id = 'anchor'
    detail.mockResolvedValue(expression('anchor', 'Anchor'))
    mappingGraph.mockResolvedValue(graph('anchor'))
    const pinia = createPinia()
    setActivePinia(pinia)
    useAuthStore().token = 'session'

    const wrapper = mountPage(pinia)
    await flushPromises()

    expect((wrapper.vm as any).morphFormOpen).toBe(false)
    await wrapper.get('[aria-controls="morph-form"]').trigger('click')
    expect((wrapper.vm as any).morphFormOpen).toBe(true)
    await wrapper.get('[aria-controls="morph-form"]').trigger('click')
    expect((wrapper.vm as any).morphFormOpen).toBe(false)
  })

  it('does not show the word-form action for non-word expressions', async () => {
    route.params.id = 'anchor'
    detail.mockResolvedValue({
      expression: { id: 'anchor', text: '🐈', lang_code: 'x-emoji', source_type: 'user', source_name: null },
      attestations: [],
      readings: [],
    })
    mappingGraph.mockResolvedValue(graph('anchor'))

    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.find('[aria-controls="morph-form"]').exists()).toBe(false)
  })

  it('shows the anchor expression readings under the title', async () => {
    route.params.id = 'anchor'
    detail.mockResolvedValue({
      expression: { id: 'anchor', text: 'peg', lang_code: 'eng', source_type: 'user', source_name: null },
      attestations: [],
      readings: [
        { language_locale_code: 'cmn-Hant-TW', locale_display_name: 'Mandarin', scheme: 'pinyin', value: 'nán tiě' },
        { language_locale_code: 'cmn-Hant-TW', scheme: 'pinyin', value: 'nántiě' },
        { language_locale_code: 'cmn-Hant-CN', scheme: 'pinyin', value: 'nán tiě' },
        { language_locale_code: 'cmn-Hant-SG', scheme: 'pinyin', value: 'nan tie' },
      ],
    })
    mappingGraph.mockResolvedValue(graph('anchor'))

    const wrapper = mountPage()
    await flushPromises()

    const readings = wrapper.findAll('.anchor-reading')
    expect(readings).toHaveLength(2)
    expect(readings[0].text()).toContain('[nán tiě]')
    expect(readings[0].text()).toContain('CN, TW · Mandarin')
    expect(readings[0].text()).not.toContain('nántiě')
    expect(readings[0].text()).not.toContain('漢語拼音')
    expect(readings[0].text()).not.toContain('cmn-Hant-TW')
    expect(readings[1].text()).toContain('[nan tie]')
  })
})
