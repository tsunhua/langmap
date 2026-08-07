import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { i18n } from '@/locales'
import { useLocalizationStore } from './localization'

const globalI18n = i18n.global as unknown as { locale: { value: string } }

vi.mock('@/api/localization', () => ({
  listUiLocales: vi.fn().mockResolvedValue([
    { code: 'en', name: 'English', native_name: 'English', status: 'active' },
    { code: 'cmn-Hans', name: 'Mandarin Chinese (Simplified)', native_name: '华语', status: 'active' },
  ]),
  getUiMessages: vi.fn().mockResolvedValue({ locale: 'cmn-Hans', messages: {} }),
}))

describe('localization store', () => {
  beforeEach(() => {
    const entries = new Map<string, string>()
    Object.defineProperty(globalThis, 'localStorage', {
      configurable: true,
      value: {
        getItem: (key: string) => entries.get(key) ?? null,
        setItem: (key: string, value: string) => entries.set(key, value),
        removeItem: (key: string) => entries.delete(key),
        clear: () => entries.clear(),
      },
    })
    setActivePinia(createPinia())
    globalI18n.locale.value = 'en-Latn'
  })

  it('restores the selected interface language after loading locales', async () => {
    localStorage.setItem('langmap.locale', 'cmn-Hans')

    const store = useLocalizationStore()
    await store.loadLocales()

    expect(store.locale).toBe('cmn-Hans')
    expect(globalI18n.locale.value).toBe('cmn-Hans')
    expect(document.documentElement.lang).toBe('cmn-Hans')
  })

  it('persists the selected interface language for the next page load', async () => {
    const store = useLocalizationStore()
    await store.loadLocales()

    await store.setLocale('cmn-Hans')

    expect(localStorage.getItem('langmap.locale')).toBe('cmn-Hans')
  })
})
