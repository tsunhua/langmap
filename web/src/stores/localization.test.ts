import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { i18n } from '@/locales'
import { useLocalizationStore } from './localization'

const globalI18n = i18n.global as unknown as { locale: { value: string } }

vi.mock('@/api/localization', () => ({
  listUiLocales: vi.fn().mockResolvedValue([
    { code: 'en-US', name: 'English', native_name: 'English', status: 'active' },
    { code: 'zh-Hans-CN', name: 'Simplified Chinese', native_name: '简体中文', status: 'active' },
  ]),
  getUiMessages: vi.fn().mockResolvedValue({ locale: 'zh-Hans-CN', messages: {} }),
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
    globalI18n.locale.value = 'en-US'
  })

  it('restores the selected interface language after loading locales', async () => {
    localStorage.setItem('langmap.locale', 'zh-Hans-CN')

    const store = useLocalizationStore()
    await store.loadLocales()

    expect(store.locale).toBe('zh-Hans-CN')
    expect(globalI18n.locale.value).toBe('zh-Hans-CN')
    expect(document.documentElement.lang).toBe('zh-Hans-CN')
  })

  it('persists the selected interface language for the next page load', async () => {
    const store = useLocalizationStore()
    await store.loadLocales()

    await store.setLocale('zh-Hans-CN')

    expect(localStorage.getItem('langmap.locale')).toBe('zh-Hans-CN')
  })
})
