import { flushPromises, shallowMount } from '@vue/test-utils'
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
    list.mockResolvedValue([])
  })

  it('requests the API page-size limit so the registry is not truncated at 50 rows', async () => {
    shallowMount(LanguageList, {
      global: { plugins: [i18n] },
    })
    await flushPromises()

    expect(list).toHaveBeenCalledWith({ limit: 100 })
  })
})
