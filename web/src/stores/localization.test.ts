import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useLocalizationStore } from './localization'
const { putLanguageLocalePreference } = vi.hoisted(() => ({ putLanguageLocalePreference: vi.fn() }))
vi.mock('@/api/localization', () => ({ listUiLocales: vi.fn().mockResolvedValue([{ language_locale_code: 'nan-Hant-TW', name: '臺語', name_en: 'Taiwanese', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: null }]), getUiMessages: vi.fn().mockResolvedValue([{ key: 'common.ok', text: '好' }]) }))
vi.mock('@/api/preferences', () => ({ getPreferences: vi.fn().mockResolvedValue({}), putLanguageLocalePreference }))
vi.mock('@/stores/auth', () => ({ useAuthStore: () => ({ isLoggedIn: false }) }))
describe('localization store', () => { beforeEach(() => { setActivePinia(createPinia()); localStorage.clear(); vi.clearAllMocks() }); it('saves anonymous preference and loads the server-resolved bundle', async () => { const store = useLocalizationStore(); await store.loadLocales(); await store.setPreferences({ primary: 'nan-Hant-TW' }); expect(store.primary).toBe('nan-Hant-TW'); expect(localStorage.getItem('langmap.language-locales')).toContain('nan-Hant-TW'); expect(document.documentElement.lang).toBe('nan-Hant-TW') }); it('rejects equal primary and secondary values', async () => { await expect(useLocalizationStore().setPreferences({ primary: 'nan-Hant-TW', secondary: 'nan-Hant-TW' })).rejects.toThrow('INVALID_LANGUAGE_PREFERENCE') }) })
