import { describe, expect, it, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import LanguageSubtagSelect from './LanguageSubtagSelect.vue'
import type { RegistrySubtag } from '@/api/languages'

const options: RegistrySubtag[] = [
  { type: 'language', subtag: 'en', descriptions: ['English'], prefixes: [], preferred_value: null, suppress_script: 'Latn', deprecated_at: null },
  { type: 'language', subtag: 'zh', descriptions: ['Chinese'], prefixes: [], preferred_value: null, suppress_script: 'Hani', deprecated_at: null },
  { type: 'language', subtag: 'ja', descriptions: ['Japanese'], prefixes: [], preferred_value: null, suppress_script: 'Jpan', deprecated_at: null },
]

describe('LanguageSubtagSelect', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('renders a combobox with the label', () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    const input = wrapper.get('input[role="combobox"]')
    expect(input.attributes('aria-label')).toBe('Language')
    expect(input.attributes('aria-expanded')).toBe('false')
  })

  it('opens the listbox on focus and shows options', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    expect(wrapper.get('input').attributes('aria-expanded')).toBe('true')
    expect(wrapper.get('[role="listbox"]').findAll('[role="option"]')).toHaveLength(3)
  })

  it('supports keyboard selection in the subtag combobox', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    await wrapper.get('input').trigger('keydown', { key: 'ArrowDown' })
    await wrapper.get('input').trigger('keydown', { key: 'Enter' })
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['zh'])
  })

  it('closes the listbox on Escape', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    expect(wrapper.get('input').attributes('aria-expanded')).toBe('true')
    await wrapper.get('input').trigger('keydown', { key: 'Escape' })
    expect(wrapper.get('input').attributes('aria-expanded')).toBe('false')
  })

  it('sets aria-activedescendant when navigating', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    await wrapper.get('input').trigger('keydown', { key: 'ArrowDown' })
    const active = wrapper.get('input').attributes('aria-activedescendant')
    expect(active).toBeTruthy()
    expect(wrapper.find(`#${active}`).exists()).toBe(true)
  })

  it('filters options based on query text', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    await wrapper.get('input').setValue('chi')
    await wrapper.get('input').trigger('keydown', { key: 'ArrowDown' })
    const opts = wrapper.get('[role="listbox"]').findAll('[role="option"]')
    expect(opts).toHaveLength(1)
    expect(opts[0].text()).toContain('zh')
  })

  it('shows description alongside subtag code', async () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    await wrapper.get('input[role="combobox"]').trigger('focus')
    const firstOpt = wrapper.get('[role="listbox"]').findAll('[role="option"]')[0]
    expect(firstOpt.text()).toContain('en')
    expect(firstOpt.text()).toContain('English')
  })

  it('has 44px minimum touch target on the input', () => {
    const wrapper = mount(LanguageSubtagSelect, {
      props: { label: 'Language', modelValue: '', options },
    })
    const input = wrapper.get('input[role="combobox"]')
    expect(input.classes()).toContain('subtag-input')
  })
})
