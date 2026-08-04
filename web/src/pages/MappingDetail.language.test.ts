import { describe, expect, it, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import MappingDetail from './MappingDetail.vue'

vi.mock('@/api/client', () => ({
  default: {
    get: vi.fn().mockResolvedValue({ data: { data: {} } }),
    post: vi.fn().mockResolvedValue({ data: { data: { expressionId: 99 } } }),
  },
}))

const mockPush = vi.fn()
vi.mock('vue-router', () => ({
  useRoute: () => ({
    params: { id: '1' },
    query: {},
  }),
  useRouter: () => ({
    push: mockPush,
    replace: vi.fn(),
  }),
}))

vi.mock('@/composables/useExpressions', () => ({
  useExpressions: () => ({
    detail: vi.fn().mockResolvedValue({
      id: 1,
      text: 'hello',
      language_profile_code: 'en',
      language_name: 'English',
      region_name: null,
      region_latitude: null,
      region_longitude: null,
      source_type: 'auth',
    }),
    mappingGraph: vi.fn().mockResolvedValue({
      root_id: 1,
      requested_hops: 1,
      resolved_hops: 1,
      nodes: [{ expression_id: 1, text: 'hello', language_profile_code: 'en', language_name: 'English', depth: 0 }],
      edges: [],
      layer_counts: { 0: 1 },
      truncated: false,
      omitted_count: 0,
    }),
  }),
}))

vi.mock('@/components/mapping/MappingGraph.vue', () => ({
  default: { name: 'MappingGraph', template: '<div />' },
}))
vi.mock('@/components/mapping/MappingGraphSkeleton.vue', () => ({
  default: { name: 'MappingGraphSkeleton', template: '<div />' },
}))
vi.mock('@/components/mapping/MappingHierarchyList.vue', () => ({
  default: { name: 'MappingHierarchyList', template: '<div />' },
}))
vi.mock('@/components/mapping/GraphInspector.vue', () => ({
  default: { name: 'GraphInspector', template: '<div />' },
}))
vi.mock('@/components/mapping/GraphMobileInspector.vue', () => ({
  default: { name: 'GraphMobileInspector', template: '<div />' },
}))
vi.mock('@/components/expression/LangBadge.vue', () => ({
  default: { name: 'LangBadge', template: '<span />' },
}))
vi.mock('@/components/ui/LoadingSpinner.vue', () => ({
  default: { name: 'LoadingSpinner', template: '<div />' },
}))
vi.mock('@/components/ui/EmptyState.vue', () => ({
  default: { name: 'EmptyState', template: '<div />' },
}))

const LanguagePickerStub = {
  name: 'LanguagePickerStub',
  props: ['modelValue', 'label', 'allowCreate'],
  emits: ['update:modelValue', 'created'],
  template: `
    <div class="stub-picker">
      <label>{{ label }}</label>
      <input class="picker-input" :value="modelValue" @input="$emit('update:modelValue', $event.target.value)" />
    </div>
  `,
}

function mountPage() {
  return mount(MappingDetail, {
    global: {
      plugins: [setActivePinia(createPinia())],
      stubs: {
        LanguagePicker: LanguagePickerStub,
      },
    },
  })
}

describe('MappingDetail language picker integration', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    mockPush.mockReset()
    setActivePinia(createPinia())
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: vi.fn().mockImplementation((query: string) => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
      })),
    })
  })

  it('uses LanguagePicker for quick-add language input', async () => {
    const wrapper = mountPage()
    await flushPromises()
    await (wrapper.vm as any).openQuickAdd()
    await wrapper.vm.$nextTick()

    const pickers = wrapper.findAll('.stub-picker')
    expect(pickers.length).toBe(1)
  })

  it('sets quickAddLang via picker input', async () => {
    const wrapper = mountPage()
    await flushPromises()
    await (wrapper.vm as any).openQuickAdd()
    await wrapper.vm.$nextTick()

    const pickerInput = wrapper.get('.stub-picker input.picker-input')
    await pickerInput.setValue('yue-Hant-CN-x-hegusan')

    expect((wrapper.vm as any).quickAddLang).toBe('yue-Hant-CN-x-hegusan')
  })

  it('preserves quickAddText when picker emits created', async () => {
    const wrapper = mountPage()
    await flushPromises()
    await (wrapper.vm as any).openQuickAdd()
    await wrapper.vm.$nextTick()

    ;(wrapper.vm as any).quickAddText = '你好世界'
    ;(wrapper.vm as any).quickAddRegion = 'Guangdong'

    const picker = wrapper.findComponent(LanguagePickerStub)
    await picker.vm.$emit('created', { code: 'yue-Hant-CN-x-hegusan', name: 'Hegusan Cantonese' })

    expect((wrapper.vm as any).quickAddText).toBe('你好世界')
    expect((wrapper.vm as any).quickAddRegion).toBe('Guangdong')
    expect((wrapper.vm as any).quickAddLang).toBe('yue-Hant-CN-x-hegusan')
  })

  it('submits the picker-selected language code, not free text', async () => {
    const api = (await import('@/api/client')).default
    const wrapper = mountPage()
    await flushPromises()
    await (wrapper.vm as any).openQuickAdd()
    await wrapper.vm.$nextTick()

    ;(wrapper.vm as any).quickAddText = '你好世界'
    ;(wrapper.vm as any).quickAddLang = 'yue-Hant-CN-x-hegusan'

    await (wrapper.vm as any).submitQuickAdd()

    expect(api.post).toHaveBeenCalledWith('/expressions', {
      text: '你好世界',
      language_profile_code: 'yue-Hant-CN-x-hegusan',
      region_name: undefined,
      related_to: 1,
    })
  })
})
