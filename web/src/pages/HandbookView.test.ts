import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { createPinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandbookView from './HandbookView.vue'

const { detail, expressionDetail, mappingGraph } = vi.hoisted(() => ({
  detail: vi.fn(),
  expressionDetail: vi.fn(),
  mappingGraph: vi.fn(),
}))
const route = reactive({ params: { id: 'old-handbook' } })

vi.mock('@/composables/useHandbooks', () => ({ useHandbooks: () => ({ detail }) }))
vi.mock('@/composables/useExpressions', () => ({
  useExpressions: () => ({ detail: expressionDetail, mappingGraph }),
}))
vi.mock('vue-router', () => ({ useRoute: () => route }))
vi.mock('@/components/mapping/VotePill.vue', () => ({ default: { template: '<div />' } }))
vi.mock('@/components/handbook/HandbookExpressionInspector.vue', () => ({
  default: { name: 'HandbookExpressionInspector', template: '<aside />' },
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
})
