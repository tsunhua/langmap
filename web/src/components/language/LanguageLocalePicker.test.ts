import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import LanguageLocalePicker from './LanguageLocalePicker.vue'

vi.mock('@/api/languageIdentity', () => ({
  listLanguageLocales: vi.fn().mockResolvedValue({ items: [{ code: 'nan-Hant-TW', lang_code: 'nan', script_code: 'Hant', region_code: 'TW', place_path: '', name: '臺語', name_en: 'Taiwanese', latitude: null, longitude: null }], total: 1, skip: 0, limit: 20, hasMore: false }),
}))

describe('LanguageLocalePicker', () => {
  it('filters locale searches by the selected language and emits the full code', async () => {
    const wrapper = mount(LanguageLocalePicker, { props: { modelValue: '', label: 'Locale', langCode: 'nan', allowCreate: false } })
    await wrapper.get('input').trigger('focus')
    await wrapper.get('input').setValue('tai')
    await new Promise((resolve) => setTimeout(resolve, 0))
    await wrapper.get('[role="option"]').trigger('mousedown')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['nan-Hant-TW'])
  })
})
