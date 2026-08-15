import { describe, expect, it, vi, beforeEach } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import Contribute from './Contribute.vue'

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

function mountPage() {
  return mount(Contribute, {
    global: {
      plugins: [setActivePinia(createPinia())],
      stubs: {
        LanguageLocalePicker: LanguageLocalePickerStub,
      },
    },
  })
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

    expect(api.post).toHaveBeenCalledWith('/contributions/batch', {
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
