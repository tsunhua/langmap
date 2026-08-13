import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandbookEdit from './HandbookEdit.vue'

const { detail, create, update, push } = vi.hoisted(() => ({
  detail: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  push: vi.fn(),
}))

vi.mock('@/composables/useHandbooks', () => ({
  useHandbooks: () => ({ detail, create, update }),
}))

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { id: 'private-handbook' } }),
  useRouter: () => ({ push }),
}))

vi.mock('@/components/handbook/SectionEditor.vue', () => ({
  default: { name: 'SectionEditor', template: '<div class="section-editor" />' },
}))

describe('HandbookEdit', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows a blocking error instead of an empty editor when the handbook cannot be loaded', async () => {
    detail.mockRejectedValueOnce({ response: { data: { error: 'HANDBOOK_NOT_FOUND' } } })

    const wrapper = mount(HandbookEdit)
    await flushPromises()

    expect(wrapper.text()).toContain('HANDBOOK_NOT_FOUND')
    expect(wrapper.find('.he-page').exists()).toBe(false)
    expect(wrapper.find('input').exists()).toBe(false)
  })
})
