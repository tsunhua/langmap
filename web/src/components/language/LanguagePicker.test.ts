import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import LanguagePicker from './LanguagePicker.vue'

vi.mock('@/api/languageIdentity', () => ({
  listLanguages: vi.fn().mockResolvedValue({ items: [{ code: 'nan', name_en: 'Min Nan' }], total: 1, skip: 0, limit: 20, hasMore: false }),
}))

describe('LanguagePicker', () => {
  it('is a labelled ISO language combobox without a create-language action', () => {
    const wrapper = mount(LanguagePicker, { props: { modelValue: '', label: 'Language' } })
    expect(wrapper.get('input[role="combobox"]').attributes('aria-label')).toBe('Language')
    expect(wrapper.find('[data-action="create-language"]').exists()).toBe(false)
  })

  it('emits the selected ISO 639-3 language code', async () => {
    const wrapper = mount(LanguagePicker, { props: { modelValue: '', label: 'Language' } })
    await wrapper.get('input').trigger('focus')
    await wrapper.get('input').setValue('nan')
    await new Promise((resolve) => setTimeout(resolve, 0))
    await wrapper.get('[role="option"]').trigger('mousedown')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['nan'])
  })
})
