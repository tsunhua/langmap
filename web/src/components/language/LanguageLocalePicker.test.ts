import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import LanguageLocalePicker from './LanguageLocalePicker.vue'

vi.mock('@/api/languageIdentity', () => ({
  listLanguageLocales: vi.fn().mockResolvedValue({ items: [{ code: 'nan-Hant-TW', lang_code: 'nan', script_code: 'Hant', region_code: 'TW', place_path: '', name: '臺語', name_en: 'Taiwanese', display_name: '臺灣話', latitude: null, longitude: null }], total: 1, skip: 0, limit: 20, hasMore: false }),
}))

describe('LanguageLocalePicker', () => {
  it('filters locale searches by the selected language and emits the full code', async () => {
    const wrapper = mount(LanguageLocalePicker, { props: { modelValue: '', label: 'Locale', langCode: 'nan', allowCreate: false }, global: { plugins: [createPinia()] } })
    await wrapper.get('input').trigger('focus')
    await wrapper.get('input').setValue('tai')
    await new Promise((resolve) => setTimeout(resolve, 0))
    expect(wrapper.get('.option-name').text()).toBe('臺灣話')
    await wrapper.get('[role="option"]').trigger('mousedown')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['nan-Hant-TW'])
    expect(wrapper.emitted('selected')?.[0]?.[0]).toMatchObject({ code: 'nan-Hant-TW', lang_code: 'nan' })
    await wrapper.setProps({ modelValue: 'nan-Hant-TW' })
    expect(wrapper.get('.selected-name').text()).toBe('臺灣話')
  })
})
