import { describe, expect, it, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import LanguageTagBuilder from './LanguageTagBuilder.vue'
import type { LanguageSubtags } from '@/api/languages'

const withVariant: LanguageSubtags = {
  language: 'zh',
  script: 'Hant',
  region: 'TW',
  variants: ['guoyu'],
  private_use: [],
}

describe('LanguageTagBuilder', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('renders four subtag fields in BCP 47 order', () => {
    const wrapper = mount(LanguageTagBuilder, {
      props: { modelValue: { language: '', script: null, region: null, variants: [], private_use: [] } },
    })
    const fields = wrapper.findAll('[data-field]')
    expect(fields.map(f => f.attributes('data-field'))).toEqual(['language', 'script', 'region', 'variants'])
  })

  it('clears invalid variants when a prefix field changes', async () => {
    const wrapper = mount(LanguageTagBuilder, { props: { modelValue: withVariant } })
    await wrapper.get('[data-field="language"] input').setValue('en')
    const emitted = wrapper.emitted('update:modelValue')!
    const last = emitted[emitted.length - 1][0] as LanguageSubtags
    expect(last.variants).toEqual([])
    expect(wrapper.get('[role="status"]').text()).toContain('removed')
  })

  it('emits subtags with the correct structure', async () => {
    const wrapper = mount(LanguageTagBuilder, {
      props: { modelValue: { language: '', script: null, region: null, variants: [], private_use: [] } },
    })
    await wrapper.get('[data-field="language"] input').setValue('en')
    const emitted = wrapper.emitted('update:modelValue')!
    const last = emitted[emitted.length - 1][0] as LanguageSubtags
    expect(last.language).toBe('en')
    expect(last.script).toBeNull()
    expect(last.region).toBeNull()
    expect(last.variants).toEqual([])
  })

  it('shows a provisional tag preview', () => {
    const wrapper = mount(LanguageTagBuilder, {
      props: { modelValue: withVariant },
    })
    expect(wrapper.text()).toContain('zh')
    expect(wrapper.text()).toContain('Hant')
    expect(wrapper.text()).toContain('TW')
    expect(wrapper.text()).toContain('guoyu')
  })

  it('labels the preview as provisional', () => {
    const wrapper = mount(LanguageTagBuilder, {
      props: { modelValue: withVariant },
    })
    expect(wrapper.text()).toContain('Provisional')
  })

  it('emits validityChange(true) when a language subtag is entered', async () => {
    const wrapper = mount(LanguageTagBuilder, {
      props: { modelValue: { language: '', script: null, region: null, variants: [], private_use: [] } },
    })
    await wrapper.get('[data-field="language"] input').setValue('en')
    const validity = wrapper.emitted('validityChange')
    expect(validity).toBeDefined()
    const last = validity!
    expect(last[last.length - 1]).toEqual([true])
  })

  it('emits validityChange(false) when language is empty', async () => {
    const wrapper = mount(LanguageTagBuilder, {
      props: { modelValue: { language: 'en', script: null, region: null, variants: [], private_use: [] } },
    })
    await wrapper.get('[data-field="language"] input').setValue('')
    const validity = wrapper.emitted('validityChange')
    expect(validity).toBeDefined()
    const last = validity!
    expect(last[last.length - 1]).toEqual([false])
  })
})
