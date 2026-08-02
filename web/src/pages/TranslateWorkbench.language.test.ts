import { describe, expect, it, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import TranslateWorkbench from './TranslateWorkbench.vue'

const mockPush = vi.fn()
const mockReplace = vi.fn()

vi.mock('vue-router', () => ({
  useRoute: () => ({
    params: { code: 'zh-TW' },
    query: {},
  }),
  useRouter: () => ({
    push: mockPush,
    replace: mockReplace,
  }),
}))

vi.mock('@/api/localization', () => ({
  listUiLocales: vi.fn().mockResolvedValue([
    { code: 'en', name: 'English', native_name: 'English', status: 'active' },
    { code: 'zh-TW', name: 'Chinese (Traditional)', native_name: '繁體中文', status: 'active' },
  ]),
  getUiMessages: vi.fn().mockResolvedValue({ locale: 'zh-TW', messages: {} }),
  getTranslationWorkbench: vi.fn().mockResolvedValue({
    project_id: 'langmap-web',
    locale: 'zh-TW',
    coverage: 0,
    total_keys: 0,
    translated_keys: 0,
    messages: [],
  }),
  submitTranslationMappings: vi.fn().mockResolvedValue({}),
  addUiLocale: vi.fn().mockResolvedValue({ code: 'yue-Hant-CN-x-hegusan', name: 'Hegusan Cantonese' }),
  LOCALIZATION_PROJECT_ID: 'langmap-web',
}))

vi.mock('@/api/languages', () => ({
  listRegistryLanguages: vi.fn().mockResolvedValue([]),
}))

vi.mock('@/locales/en', () => ({
  en: {},
}))

vi.mock('@/stores/auth', () => ({
  useAuthStore: () => ({
    isLoggedIn: false,
    user: null,
    token: null,
  }),
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
  return mount(TranslateWorkbench, {
    global: {
      plugins: [setActivePinia(createPinia())],
      stubs: {
        LanguagePicker: LanguagePickerStub,
      },
    },
  })
}

describe('TranslateWorkbench language picker integration', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setActivePinia(createPinia())
  })

  it('uses LanguagePicker for target locale selection', () => {
    const wrapper = mountPage()
    const pickers = wrapper.findAll('.stub-picker')
    expect(pickers.length).toBeGreaterThanOrEqual(1)
  })

  it('calls chooseLocale with selected code when picker updates', async () => {
    const addUiLocale = (await import('@/api/localization')).addUiLocale
    const wrapper = mountPage()
    await wrapper.vm.$nextTick()

    const pickerInput = wrapper.get('.stub-picker input.picker-input')
    await pickerInput.setValue('yue-Hant-CN-x-hegusan')
    await wrapper.vm.$nextTick()

    expect(addUiLocale).toHaveBeenCalledWith('yue-Hant-CN-x-hegusan')
    expect(mockPush).toHaveBeenCalledWith('/translate/yue-Hant-CN-x-hegusan')
  })

  it('navigates using encodeURIComponent for the new language code', async () => {
    const wrapper = mountPage()
    await wrapper.vm.$nextTick()

    const pickerInput = wrapper.get('.stub-picker input.picker-input')
    await pickerInput.setValue('zh-Hans-SG')
    await wrapper.vm.$nextTick()

    expect(mockPush).toHaveBeenCalledWith('/translate/zh-Hans-SG')
  })

  it('does not replace reference locale when selecting a new target', async () => {
    const wrapper = mountPage()
    await wrapper.vm.$nextTick()

    const refLocale = (wrapper.vm as any).referenceLocale
    const pickerInput = wrapper.get('.stub-picker input.picker-input')
    await pickerInput.setValue('yue-Hant-CN-x-hegusan')
    await wrapper.vm.$nextTick()

    expect((wrapper.vm as any).referenceLocale).toBe(refLocale)
  })
})
