import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useLocalizationStore } from './localization'
import { getUiMessages, listUiLocales } from '@/api/localization'
import { i18n } from '@/locales'
const { putLanguageLocalePreference } = vi.hoisted(() => ({ putLanguageLocalePreference: vi.fn() }))
vi.mock('@/api/localization', () => ({ listUiLocales: vi.fn().mockResolvedValue([{ language_locale_code: 'nan-Hant-TW', name: '臺語', name_en: 'Taiwanese', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: null }]), getUiMessages: vi.fn().mockResolvedValue([{ key: 'common.ok', text: '好' }]) }))
vi.mock('@/api/preferences', () => ({ getPreferences: vi.fn().mockResolvedValue({}), putLanguageLocalePreference }))
vi.mock('@/stores/auth', () => ({ useAuthStore: () => ({ isLoggedIn: false }) }))
describe('localization store', () => {
  beforeEach(() => { setActivePinia(createPinia()); localStorage.clear(); vi.clearAllMocks() })

  it('saves anonymous preference and loads the server-resolved bundle', async () => {
    const store = useLocalizationStore()
    await store.loadLocales()
    await store.setPreferences({ primary: 'nan-Hant-TW' })
    expect(store.primary).toBe('nan-Hant-TW')
    expect(localStorage.getItem('langmap.language-locales')).toContain('nan-Hant-TW')
    expect(document.documentElement.lang).toBe('nan-Hant-TW')
  })

  it('prefers project JSON translations and falls back to API messages per key', async () => {
    localStorage.setItem('langmap.language-locales', JSON.stringify({ primary: 'cmn-Hant-TW' }))
    vi.mocked(getUiMessages).mockResolvedValueOnce([
      { key: 'common.cancel', text: 'API 取消', resolved_from: 'primary' },
      { key: 'components.edgeSources', text: 'API source markers', resolved_from: 'primary' },
    ])
    const store = useLocalizationStore()
    await store.loadLocales()
    expect(i18n.global.t('common.cancel')).toBe('取消')
    expect(i18n.global.t('components.edgeSources')).toBe('API source markers')
  })

  it('deduplicates repeated locale initialization', async () => {
    const store = useLocalizationStore()
    await Promise.all([store.loadLocales(), store.loadLocales()])
    await store.loadLocales()
    expect(vi.mocked(listUiLocales)).toHaveBeenCalledTimes(1)
    expect(vi.mocked(getUiMessages)).toHaveBeenCalledTimes(1)
  })

  it('rejects equal primary and secondary values', async () => {
    await expect(useLocalizationStore().setPreferences({ primary: 'nan-Hant-TW', secondary: 'nan-Hant-TW' })).rejects.toThrow('INVALID_LANGUAGE_PREFERENCE')
  })
})
