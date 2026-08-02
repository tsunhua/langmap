import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { i18n, DEFAULT_LOCALE, resolveLocale } from '@/locales'
import { getUiMessages, listUiLocales, type UiLocale } from '@/api/localization'

const RECENT_KEY = 'langmap.recent-locales'
const SELECTED_LOCALE_KEY = 'langmap.locale'

export const useLocalizationStore = defineStore('localization', () => {
  const globalI18n = i18n.global as unknown as {
    locale: { value: string }
    setLocaleMessage: (locale: string, messages: Record<string, unknown>) => void
    getLocaleMessage: (locale: string) => Record<string, unknown>
  }
  const locale = ref(globalI18n.locale.value || DEFAULT_LOCALE)
  const locales = ref<UiLocale[]>([
    { code: DEFAULT_LOCALE, name: 'English', native_name: 'English', status: 'active' },
  ])
  const loading = ref(false)
  const recent = ref<string[]>(readRecent())

  const availableCodes = computed(() => locales.value.map(item => item.code))

  function readRecent(): string[] {
    try { return JSON.parse(localStorage.getItem(RECENT_KEY) || '[]') } catch { return [] }
  }
  function readSelectedLocale(): string | null {
    try { return localStorage.getItem(SELECTED_LOCALE_KEY) } catch { return null }
  }
  function remember(code: string) {
    recent.value = [code, ...recent.value.filter(item => item !== code)].slice(0, 8)
    localStorage.setItem(RECENT_KEY, JSON.stringify(recent.value))
  }
  async function setLocale(input: string) {
    const code = resolveLocale(input, availableCodes.value)
    if (code === DEFAULT_LOCALE) {
      globalI18n.setLocaleMessage(DEFAULT_LOCALE, globalI18n.getLocaleMessage(DEFAULT_LOCALE))
    } else {
      try {
        const bundle = await getUiMessages(code)
        globalI18n.setLocaleMessage(code, bundle.messages)
      } catch {
        // vue-i18n falls back to the built-in English source catalog.
      }
    }
    globalI18n.locale.value = code
    locale.value = code
    remember(code)
    localStorage.setItem(SELECTED_LOCALE_KEY, code)
    document.documentElement.lang = code
    document.documentElement.dir = locales.value.find(item => item.code === code)?.direction || 'ltr'
  }
  async function loadLocales() {
    loading.value = true
    try {
      const remote = await listUiLocales()
      const byCode = new Map([...locales.value, ...(remote || [])].map(item => [item.code, item]))
      locales.value = [...byCode.values()]
      const savedLocale = readSelectedLocale()
      if (savedLocale && savedLocale !== locale.value) await setLocale(savedLocale)
    } finally { loading.value = false }
  }
  return { locale, locales, recent, loading, availableCodes, setLocale, loadLocales }
})
