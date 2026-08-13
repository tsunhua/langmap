import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandbookList from './HandbookList.vue'

const { list } = vi.hoisted(() => ({ list: vi.fn() }))
vi.mock('@/composables/useHandbooks', () => ({ useHandbooks: () => ({ list }) }))

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((done) => { resolve = done })
  return { promise, resolve }
}

function item(id: number, title: string) {
  return { id, title, section_count: 1, expression_count: 2, score: 0 }
}

describe('HandbookList', () => {
  beforeEach(() => vi.clearAllMocks())

  it('keeps the newest sort result when requests finish out of order', async () => {
    const newest = deferred<{ items: ReturnType<typeof item>[] }>()
    list.mockImplementation(({ sort }: { sort: string }) => sort === 'new'
      ? newest.promise
      : Promise.resolve({ items: [item(2, 'Popular handbook')] }))

    const wrapper = mount(HandbookList, {
      global: {
        stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } },
      },
    })
    await wrapper.get('button[aria-pressed="false"]').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Popular handbook')

    newest.resolve({ items: [item(1, 'Stale newest handbook')] })
    await flushPromises()

    expect(wrapper.text()).toContain('Popular handbook')
    expect(wrapper.text()).not.toContain('Stale newest handbook')
  })
})
