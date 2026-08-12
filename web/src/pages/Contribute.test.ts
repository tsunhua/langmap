import { describe, expect, it, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
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
  return mount(Contribute, {
    global: {
      plugins: [setActivePinia(createPinia())],
      stubs: {
        LanguagePicker: LanguagePickerStub,
      },
    },
  })
}

describe('Contribute page with LanguagePicker', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    mockPush.mockReset()
  })

  it('renders one LanguagePicker per row', () => {
    const wrapper = mountPage()
    const pickers = wrapper.findAll('.stub-picker')
    expect(pickers.length).toBeGreaterThanOrEqual(2)
  })

  it('preserves row keys so picker state does not shift between rows', async () => {
    const wrapper = mountPage()
    const pickerInputs = wrapper.findAll('.stub-picker input.picker-input')
    await pickerInputs[0].setValue('yue-Hant-CN-x-hegusan')
    await pickerInputs[1].setValue('cmn-Hans')

    expect((wrapper.vm as any).rows[0].lang_code).toBe('yue-Hant-CN-x-hegusan')
    expect((wrapper.vm as any).rows[1].lang_code).toBe('cmn-Hans')
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
        expect.objectContaining({ lang_code: 'yue-Hant-CN-x-hegusan' }),
        expect.objectContaining({ lang_code: 'cmn-Hans' }),
      ]),
    })
  })
})
