import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TranslateWorkbench from './TranslateWorkbench.vue'

const {
  addUiLocale,
  authState,
  createExpression,
  getLanguageLocale,
  getTranslationWorkbench,
  listUiLocales,
  push,
  replace,
  submitTranslationMapping,
} = vi.hoisted(() => ({
  addUiLocale: vi.fn(),
  authState: { isLoggedIn: true, user: { role: 'user' } },
  createExpression: vi.fn(),
  getLanguageLocale: vi.fn(),
  getTranslationWorkbench: vi.fn(),
  listUiLocales: vi.fn(),
  push: vi.fn(),
  replace: vi.fn(),
  submitTranslationMapping: vi.fn(),
}))

vi.mock('@/api/localization', () => ({
  addUiLocale,
  getTranslationWorkbench,
  listUiLocales,
  submitTranslationMapping,
}))

vi.mock('@/api/expressions', () => ({ createExpression }))
vi.mock('@/api/languageIdentity', () => ({ getLanguageLocale }))
vi.mock('@/stores/auth', () => ({ useAuthStore: () => authState }))
vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { code: 'nan-Hant-TW' } }),
  useRouter: () => ({ push, replace }),
}))

const LanguageLocalePickerStub = {
  props: ['modelValue', 'label'],
  emits: ['update:modelValue'],
  template: '<button class="locale-picker" @click="$emit(\'update:modelValue\', \'yue-Hant-HK\')">{{ label }}</button>',
}

function mountPage() {
  return mount(TranslateWorkbench, {
    global: { stubs: { LanguageLocalePicker: LanguageLocalePickerStub } },
  })
}

function workbench() {
  return {
    locale: {
      language_locale_code: 'nan-Hant-TW',
      name: '臺語',
      name_en: 'Taiwanese',
      direction: 'ltr',
      status: 'active',
      mapping_revision: 2,
      activation_source: 'auto',
    },
    coverage: { coverage: 0.5, translated: 1, total: 2 },
    messages: [
      { key: 'common.ok', source_text: 'OK', candidates: [{ edge_id: 'e1', expression_id: 'old', text: '好', score: 4 }] },
      { key: 'common.cancel', source_text: 'Cancel', candidates: [] },
    ],
    total: 2,
    skip: 0,
    limit: 20,
  }
}

describe('TranslateWorkbench', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    authState.isLoggedIn = true
    listUiLocales.mockResolvedValue([
      { language_locale_code: 'nan-Hant-TW', status: 'active', direction: 'ltr' },
    ])
  })

  it('shows a visible error when the workbench cannot be loaded', async () => {
    getTranslationWorkbench.mockRejectedValueOnce(new Error('Workbench unavailable'))

    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Workbench unavailable')
    expect(wrapper.find('table').exists()).toBe(false)
  })

  it('filters messages and exposes an accessible translation input', async () => {
    getTranslationWorkbench.mockResolvedValueOnce(workbench())
    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.get('textarea[aria-label="Translate common.ok"]').element).toBeTruthy()
    await wrapper.get('input[type="search"]').setValue('cancel')

    expect(wrapper.text()).toContain('common.cancel')
    expect(wrapper.text()).not.toContain('common.ok')
  })

  it('submits only changed non-empty translations and refreshes confirmed state', async () => {
    getTranslationWorkbench.mockResolvedValue(workbench())
    getLanguageLocale.mockResolvedValue({ code: 'nan-Hant-TW', lang_code: 'nan' })
    createExpression.mockResolvedValue({ expression: { id: 'nan:new' } })
    submitTranslationMapping.mockResolvedValue({ score: 1 })
    const wrapper = mountPage()
    await flushPromises()

    const inputs = wrapper.findAll('textarea')
    await inputs[0].setValue('好')
    await inputs[1].setValue('取消')
    await wrapper.get('button.btn-primary').trigger('click')
    await flushPromises()

    expect(createExpression).toHaveBeenCalledTimes(1)
    expect(createExpression).toHaveBeenCalledWith({
      lang_code: 'nan',
      language_locale_code: 'nan-Hant-TW',
      text: '取消',
    })
    expect(submitTranslationMapping).toHaveBeenCalledWith({
      message_key: 'common.cancel',
      target_expression_id: 'nan:new',
    })
    expect(getTranslationWorkbench).toHaveBeenCalledTimes(2)
  })

  it('does not call the authenticated workbench endpoint while anonymous', async () => {
    authState.isLoggedIn = false
    const wrapper = mountPage()
    await flushPromises()

    expect(getTranslationWorkbench).not.toHaveBeenCalled()
    expect(wrapper.find('.login-note').exists()).toBe(true)
  })
})
