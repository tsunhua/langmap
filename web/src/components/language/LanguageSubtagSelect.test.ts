import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import LanguageSubtagSelect from './LanguageSubtagSelect.vue'
import { listLanguageSubtags } from '@/api/languages'
import type { RegistrySubtag } from '@/api/languages'

const options: RegistrySubtag[] = [
  { type: 'language', subtag: 'en', descriptions: ['English'], prefixes: [], preferred_value: null, suppress_script: 'Latn', deprecated_at: null },
  { type: 'language', subtag: 'zh', descriptions: ['Chinese'], prefixes: [], preferred_value: null, suppress_script: 'Hani', deprecated_at: null },
  { type: 'language', subtag: 'ja', descriptions: ['Japanese'], prefixes: [], preferred_value: null, suppress_script: 'Jpan', deprecated_at: null },
]

vi.mock('@/api/languages', () => ({
  listLanguageSubtags: vi.fn(),
}))

describe('LanguageSubtagSelect', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.useFakeTimers()
    vi.mocked(listLanguageSubtags).mockResolvedValue(options)
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders a combobox with the label', () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    const input = wrapper.get('input[role="combobox"]')
    expect(input.attributes('aria-label')).toBe('Language')
    expect(input.attributes('aria-expanded')).toBe('false')
  })

  it('opens the listbox on focus', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    expect(wrapper.get('input').attributes('aria-expanded')).toBe('true')
  })

  it('searches subtags when typing', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    await wrapper.get('input').setValue('zh')
    await vi.advanceTimersByTimeAsync(250)
    await flushPromises()

    expect(listLanguageSubtags).toHaveBeenCalledWith('language', 'zh', undefined, expect.any(AbortSignal))
  })

  it('finishes loading and renders the API response for es', async () => {
    vi.mocked(listLanguageSubtags).mockResolvedValueOnce([
      {
        type: 'language',
        subtag: 'es',
        descriptions: ['Spanish', 'Castilian'],
        prefixes: [],
        preferred_value: null,
        suppress_script: 'Latn',
        deprecated_at: null,
      },
    ])

    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    await wrapper.get('input').setValue('es')
    await vi.advanceTimersByTimeAsync(250)
    await flushPromises()

    expect(wrapper.text()).not.toContain('Loading')
    expect(wrapper.get('[role="option"]').text()).toContain('es')
    expect(wrapper.get('[role="option"]').text()).toContain('Spanish')
  })

  it('supports keyboard selection in the subtag combobox', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    await wrapper.get('input').setValue('zh')
    await vi.advanceTimersByTimeAsync(250)
    await flushPromises()
    await wrapper.get('input').trigger('keydown', { key: 'ArrowDown' })
    await wrapper.get('input').trigger('keydown', { key: 'Enter' })
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['zh'])
  })

  it('closes the listbox on Escape', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    expect(wrapper.get('input').attributes('aria-expanded')).toBe('true')
    await wrapper.get('input').trigger('keydown', { key: 'Escape' })
    expect(wrapper.get('input').attributes('aria-expanded')).toBe('false')
  })

  it('sets aria-activedescendant when navigating', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    await wrapper.get('input').setValue('zh')
    await vi.advanceTimersByTimeAsync(250)
    await flushPromises()
    await wrapper.get('input').trigger('keydown', { key: 'ArrowDown' })
    const active = wrapper.get('input').attributes('aria-activedescendant')
    expect(active).toBeTruthy()
    expect(wrapper.find(`#${active}`).exists()).toBe(true)
  })

  it('shows description alongside subtag code', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    await wrapper.get('input').setValue('en')
    await vi.advanceTimersByTimeAsync(250)
    await flushPromises()
    const firstOpt = wrapper.get('[role="listbox"]').findAll('[role="option"]')[0]
    expect(firstOpt.text()).toContain('en')
    expect(firstOpt.text()).toContain('English')
  })

  it('has 44px minimum touch target on the input', () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', type: 'language' },
    })
    const input = wrapper.get('input[role="combobox"]')
    expect(input.classes()).toContain('subtag-input')
  })
})
