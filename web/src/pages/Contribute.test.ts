import { describe, expect, it, vi, beforeEach } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import Contribute from './Contribute.vue'
import { useContributePrefillStore, type ContributePrefill } from '@/stores/contributePrefill'

vi.mock('@/api/client', () => ({
  default: {
    post: vi.fn().mockResolvedValue({ data: {} }),
  },
}))

vi.mock('@/components/mapping/CliquePreview.vue', () => ({
  default: { name: 'CliquePreview', props: ['expressions'], template: '<div />' },
}))

const mockPush = vi.fn()
vi.mock('vue-router', () => ({
  useRouter: () => ({ push: mockPush }),
}))

const localeByCode = {
  'yue-Hant-CN-x-hegusan': { code: 'yue-Hant-CN-x-hegusan', lang_code: 'yue' },
  'cmn-Hans': { code: 'cmn-Hans', lang_code: 'cmn' },
  'eng-US': { code: 'eng-US', lang_code: 'eng' },
  'nan-Hant-TW': { code: 'nan-Hant-TW', lang_code: 'nan' },
}

const LanguageLocalePickerStub = {
  name: 'LanguageLocalePickerStub',
  props: ['modelValue', 'label', 'allowCreate'],
  emits: ['update:modelValue', 'selected', 'created'],
  template: `
    <div class="stub-picker">
      <label>{{ label }}</label>
      <input class="picker-input" :value="modelValue" @input="select($event.target.value)" />
    </div>
  `,
  methods: {
    select(this: { $emit: (event: string, value: unknown) => void }, code: keyof typeof localeByCode) {
      this.$emit('update:modelValue', code)
      this.$emit('selected', localeByCode[code])
    },
  },
}

function mountPage(pinia = createPinia(), setup?: (pinia: ReturnType<typeof createPinia>) => void) {
  setActivePinia(pinia)
  setup?.(pinia)
  return mount(Contribute, {
    global: {
      plugins: [pinia],
      stubs: {
        LanguageLocalePicker: LanguageLocalePickerStub,
      },
    },
  })
}

const prefillPair: ContributePrefill = {
  sourceLangCode: 'yue',
  sourceLocaleCode: 'yue-Hant-CN-x-hegusan',
  sourceText: 'hello',
  targetLangCode: 'cmn',
  targetLocaleCode: 'cmn-Hans',
  targetText: '你好',
  aiAssisted: true,
}

describe('Contribute page with LanguageLocalePicker', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockPush.mockReset()
  })

  it('renders one locale picker per row', () => {
    const wrapper = mountPage()
    const pickers = wrapper.findAll('.stub-picker')
    expect(pickers.length).toBeGreaterThanOrEqual(2)
  })

  it('preserves row keys so picker state does not shift between rows', async () => {
    const wrapper = mountPage()
    const pickerInputs = wrapper.findAll('.stub-picker input.picker-input')
    await pickerInputs[0].setValue('yue-Hant-CN-x-hegusan')
    await pickerInputs[1].setValue('cmn-Hans')

    expect((wrapper.vm as any).rows[0]).toMatchObject({ lang_code: 'yue', language_locale_code: 'yue-Hant-CN-x-hegusan' })
    expect((wrapper.vm as any).rows[1]).toMatchObject({ lang_code: 'cmn', language_locale_code: 'cmn-Hans' })
  })

  it('submits canonical language codes from picker, not free-text', async () => {
    const api = (await import('@/api/client')).default
    const wrapper = mountPage()

    const pickerInputs = wrapper.findAll('.stub-picker input.picker-input')
    await pickerInputs[0].setValue('yue-Hant-CN-x-hegusan')
    await pickerInputs[1].setValue('cmn-Hans')

    const textInputs = wrapper.findAll('input.ex-text')
    await textInputs[0].setValue('hello')
    await textInputs[1].setValue('你好')

    await wrapper.get('[data-action="submit-contribution"]').trigger('click')

    expect(api.post).toHaveBeenCalledWith('/contributions', {
      expressions: expect.arrayContaining([
        expect.objectContaining({ lang_code: 'yue', language_locale_code: 'yue-Hant-CN-x-hegusan' }),
        expect.objectContaining({ lang_code: 'cmn', language_locale_code: 'cmn-Hans' }),
      ]),
    })
  })

  it('rejects a batch with fewer than two complete expressions', async () => {
    const api = (await import('@/api/client')).default
    const wrapper = mountPage()
    await wrapper.findAll('.stub-picker input.picker-input')[0].setValue('eng-US')
    await wrapper.findAll('input.ex-text')[0].setValue('hello')

    const submitButton = wrapper.get('[data-action="submit-contribution"]')
    expect(submitButton.attributes('disabled')).toBeDefined()
    await submitButton.trigger('click')

    expect(api.post).not.toHaveBeenCalled()
  })

  it('explains the two-row requirement instead of failing silently when only one expression is entered', async () => {
    const wrapper = mountPage()
    const pickers = wrapper.findAll('.stub-picker input.picker-input')
    const texts = wrapper.findAll('input.ex-text')
    await pickers[0].setValue('eng-US')
    await texts[0].setValue('hello')

    expect(wrapper.get('[data-action="submit-contribution"]').attributes('disabled')).toBeDefined()
    expect(wrapper.text()).toContain('At least 2 rows')
  })

  it('keeps the page in place and shows the server error when submission fails', async () => {
    const api = (await import('@/api/client')).default
    vi.mocked(api.post).mockRejectedValueOnce({ response: { data: { error: 'DUPLICATE_PAIR' } } })
    const wrapper = mountPage()
    const pickers = wrapper.findAll('.stub-picker input.picker-input')
    const texts = wrapper.findAll('input.ex-text')
    await pickers[0].setValue('eng-US')
    await pickers[1].setValue('nan-Hant-TW')
    await texts[0].setValue('hello')
    await texts[1].setValue('食飽未')

    await wrapper.get('[data-action="submit-contribution"]').trigger('click')
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('DUPLICATE_PAIR')
    expect(mockPush).not.toHaveBeenCalled()
  })
})

describe('Contribute page prefill handoff', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockPush.mockReset()
  })

  it('fills row 0 with the source and row 1 with the target, keeping both editable', async () => {
    const wrapper = mountPage(createPinia(), (pinia) => useContributePrefillStore(pinia).set(prefillPair))

    const rows = (wrapper.vm as any).rows
    expect(rows[0]).toMatchObject({ lang_code: 'yue', language_locale_code: 'yue-Hant-CN-x-hegusan', text: 'hello' })
    expect(rows[1]).toMatchObject({ lang_code: 'cmn', language_locale_code: 'cmn-Hans', text: '你好' })

    await wrapper.findAll('input.ex-text')[0].setValue('hi')
    expect((wrapper.vm as any).rows[0].text).toBe('hi')
  })

  it('consumes the prefill so a remount without a new set falls back to empty rows', () => {
    const pinia = createPinia()
    const store = useContributePrefillStore(pinia)
    store.set(prefillPair)
    expect(store.prefill).not.toBeNull()

    mountPage(pinia)
    expect(store.prefill).toBeNull()

    const remount = mountPage(pinia)
    const rows = (remount.vm as any).rows
    expect(rows).toHaveLength(2)
    expect(rows[0]).toMatchObject({ lang_code: '', language_locale_code: '', text: '' })
    expect(rows[1]).toMatchObject({ lang_code: '', language_locale_code: '', text: '' })
  })

  it('shows the AI-assisted notice only when the result was AI-assisted', () => {
    const assisted = mountPage(createPinia(), (pinia) => useContributePrefillStore(pinia).set(prefillPair))
    expect(assisted.get('.ai-notice').text()).toContain('AI-assisted')
    expect(assisted.get('.ai-notice').text()).toContain('produced with AI assistance')

    const exact = mountPage(createPinia(), (pinia) => useContributePrefillStore(pinia).set({ ...prefillPair, aiAssisted: false }))
    expect(exact.find('.ai-notice').exists()).toBe(false)
  })

  it('never leaks source or translation text into the URL or query string', async () => {
    const wrapper = mountPage(createPinia(), (pinia) => useContributePrefillStore(pinia).set(prefillPair))

    await wrapper.get('[data-action="submit-contribution"]').trigger('click')
    await flushPromises()

    expect(mockPush).toHaveBeenCalledWith('/')
    for (const call of mockPush.mock.calls) {
      expect(String(call[0])).not.toContain('?')
      expect(String(call[0])).not.toContain('hello')
      expect(String(call[0])).not.toContain('你好')
    }
    expect(window.location.search).toBe('')
  })
})
