import { describe, expect, it, vi } from 'vitest'
import { createPinia } from 'pinia'
import { mount } from '@vue/test-utils'
import LanguageLocaleCreateDialog from './LanguageLocaleCreateDialog.vue'

const { createLanguageLocale } = vi.hoisted(() => ({ createLanguageLocale: vi.fn() }))
vi.mock('@/api/languageIdentity', () => ({
  createLanguageLocale,
  listScripts: vi.fn().mockResolvedValue({ items: [], total: 0, skip: 0, limit: 20, hasMore: false }),
  listRegions: vi.fn().mockResolvedValue({ items: [], total: 0, skip: 0, limit: 20, hasMore: false }),
}))

describe('LanguageLocaleCreateDialog', () => {
  it('submits structured fields and adopts the code returned by the server', async () => {
    createLanguageLocale.mockResolvedValueOnce({ code: 'nan-Hant-CN_Quanzhou', lang_code: 'nan' })
    const wrapper = mount(LanguageLocaleCreateDialog, { props: { open: true, langCode: 'nan' }, global: { stubs: { teleport: true }, plugins: [createPinia()] } })
    await wrapper.get('[name="script_code"]').setValue('Hant')
    await wrapper.get('[name="region_code"]').setValue('CN')
    await wrapper.get('[name="name"]').setValue('泉州話')
    await wrapper.get('[name="name_en"]').setValue('Quanzhou')
    await wrapper.get('form').trigger('submit')
    expect(createLanguageLocale).toHaveBeenCalledWith(expect.objectContaining({ lang_code: 'nan', script_code: 'Hant', region_code: 'CN' }))
    expect(wrapper.emitted('created')?.[0]).toEqual([expect.objectContaining({ code: 'nan-Hant-CN_Quanzhou' })])
  })
})
