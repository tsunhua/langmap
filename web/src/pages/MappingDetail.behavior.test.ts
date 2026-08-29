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
  props: ['graph'],
  emits: ['change-hops'],
  template: `
    <div class="mapping-graph-stub">
      <span class="graph-label">{{ graph.nodes[1]?.text }}</span>
      <button class="hop-2" @click="$emit('change-hops', 2)">2 hops</button>
      <button class="hop-3" @click="$emit('change-hops', 3)">3 hops</button>
    </div>
  `,
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

function graph(id: string) {
  return {
    root_id: id,
    requested_hops: 1,
    resolved_hops: 0,
    nodes: [{ expression_id: id, text: id, lang_code: 'eng', language_name: 'English', depth: 0 }],
    edges: [],
    layer_counts: { 0: 1 } as Record<number, number>,
    truncated: false,
    omitted_count: 0,
  }
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
      },
    },
  })
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

    const wrapper = mountPage()
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
        {
          language_locale_code: 'cmn-Hant-TW',
          locale_display_name: 'Mandarin',
          scheme: 'pinyin',
          value: 'nán tiě',
        },
      ],
    })
    mappingGraph.mockResolvedValue(graph('anchor'))

    const wrapper = mountPage()
    await flushPromises()

    const readings = wrapper.findAll('.anchor-reading')
    expect(readings).toHaveLength(1)
    expect(readings[0].text()).toContain('TW:')
    expect(readings[0].text()).toContain('[nán tiě]')
    expect(readings[0].text()).toContain('(pinyin)')
    expect(readings[0].text()).not.toContain('cmn-Hant-TW')
  })
})
