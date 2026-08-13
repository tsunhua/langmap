import { flushPromises, mount, shallowMount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { i18n } from '@/locales'
import LanguageList from './LanguageList.vue'

const list = vi.fn()

vi.mock('@/composables/useLanguages', () => ({
  useLanguages: () => ({ loading: { value: false }, list }),
}))

describe('LanguageList', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    list.mockResolvedValue({ items: [], total: 0, skip: 0, limit: 20, hasMore: false })
  })

  it('loads the first server-side page with the active query and count sort', async () => {
    shallowMount(LanguageList, {
      global: { plugins: [i18n] },
    })
    await flushPromises()

    expect(list).toHaveBeenCalledWith({ q: '', sort: 'count', limit: 20, offset: 0 })
  })

  it('keeps loaded languages visible when loading more fails', async () => {
    list
      .mockResolvedValueOnce({
        items: [{ code: 'nan', name: '閩南語', name_en: 'Min Nan Chinese', expression_count: 2, locale_count: 1, active_ui_locale_count: 0 }],
        total: 2, skip: 0, limit: 20, hasMore: true,
      })
      .mockRejectedValueOnce(new Error('Network unavailable'))
    const wrapper = mount(LanguageList, {
      global: { plugins: [i18n] },
    })
    await flushPromises()
    await wrapper.get('.pag button').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('閩南語')
    expect(wrapper.get('[role="alert"]').text()).toContain('Network unavailable')
  })
})
