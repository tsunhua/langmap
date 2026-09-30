import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { i18n, DEFAULT_LOCALE } from '@/locales'
import { en } from '@/locales/en'
import { projectTranslations } from '@/locales/project'
import { getUiMessages, listUiLocales, type UiLocale } from '@/api/localization'
import { getPreferences, putLanguageLocalePreference, type LanguageLocalePreference } from '@/api/preferences'
import { useAuthStore } from '@/stores/auth'
import { resolveBrowserUiLocale } from '@/utils/browserUiLocale'

const KEY = 'langmap.language-locales'
function parseLanguageLocalePreference(value: unknown): LanguageLocalePreference | undefined {
  if (typeof value !== 'object' || value === null) return undefined
  const preference = value as Record<string, unknown>
  if (typeof preference.primary !== 'string' || !preference.primary) return undefined
  if (preference.secondary != null && typeof preference.secondary !== 'string') return undefined
  return {
    primary: preference.primary,
    ...(typeof preference.secondary === 'string' ? { secondary: preference.secondary } : {}),
  }
}
function readLocalPreferences(): LanguageLocalePreference | undefined {
  try {
    const value: unknown = JSON.parse(localStorage.getItem(KEY) || '')
    return parseLanguageLocalePreference(value)
  } catch {
    return undefined
  }
}
function saveLocalPreferences(value: LanguageLocalePreference) {
  try {
    localStorage.setItem(KEY, JSON.stringify(value))
  } catch {
    // Keep the current locale usable when browser storage is unavailable.
  }
}
function browserLanguages(): string[] {
  if (typeof navigator === 'undefined') return []
  const preferences = navigator.languages.length ? navigator.languages : [navigator.language]
  return [...new Set(preferences.filter(Boolean))]
}
function nested(messages: Array<{ key: string; text: string }>) { const out: Record<string, unknown> = {}; for (const { key, text } of messages) { let target = out; const parts = key.split('.'); for (const part of parts.slice(0, -1)) target = (target[part] ??= {}) as Record<string, unknown>; target[parts[parts.length - 1]] = text } return out }
function flatten(messages: unknown, prefix = ''): Array<{ key: string; text: string }> {
  if (typeof messages === 'string') return prefix ? [{ key: prefix, text: messages }] : []
  if (!messages || typeof messages !== 'object' || Array.isArray(messages)) return []
  return Object.entries(messages).flatMap(([key, value]) => flatten(value, prefix ? `${prefix}.${key}` : key))
}

const builtInEnglishMessages = flatten(en)
const builtInEnglish = new Map(builtInEnglishMessages.map(({ key, text }) => [key, text]))

function mergeMessages(messages: Array<{ key: string; text: string }>, primary?: string, secondary?: string) {
  const apiMessages = new Map(messages.map(({ key, text }) => [key, text]))
  const primaryMessages = projectTranslations(primary)
  const secondaryMessages = projectTranslations(secondary)
  const keys = new Set([
    ...builtInEnglishMessages.map(({ key }) => key),
    ...Object.keys(primaryMessages),
    ...Object.keys(secondaryMessages),
    ...apiMessages.keys(),
  ])
  return [...keys].flatMap((key) => {
    // The backend bundle can lag the web release; keep missing source copy usable.
    const text = primaryMessages[key] ?? secondaryMessages[key] ?? apiMessages.get(key) ?? builtInEnglish.get(key)
    return text === undefined ? [] : [{ key, text }]
  })
}
export const useLocalizationStore = defineStore('localization', () => {
  const global = i18n.global as unknown as { locale: { value: string }; setLocaleMessage: (c: string, m: Record<string, unknown>) => void }
  const primary = ref(DEFAULT_LOCALE); const secondary = ref<string | undefined>(); const locales = ref<UiLocale[]>([]); const loading = ref(false)
  const locale = primary; const availableCodes = computed(() => locales.value.map((item) => item.language_locale_code))
  let loaded = false
  let loadingPromise: Promise<void> | undefined
  async function loadBundle() { const messages = await getUiMessages({ primary: primary.value, secondary: secondary.value }); global.setLocaleMessage(primary.value, nested(mergeMessages(messages, primary.value, secondary.value))); global.locale.value = primary.value; document.documentElement.lang = primary.value.split('_')[0]; document.documentElement.dir = locales.value.find((item) => item.language_locale_code === primary.value)?.direction ?? 'ltr' }
  async function setPreferences(value: LanguageLocalePreference) {
    if (!value.primary || value.primary === value.secondary) throw new Error('INVALID_LANGUAGE_PREFERENCE')
    const auth = useAuthStore()
    if (auth.isLoggedIn) await putLanguageLocalePreference(value)
    saveLocalPreferences(value)
    primary.value = value.primary
    secondary.value = value.secondary
    await loadBundle()
  }
  async function loadPreferences(): Promise<boolean> {
    const auth = useAuthStore()
    const accountPreferences = auth.isLoggedIn ? await getPreferences() : undefined
    const accountValue = parseLanguageLocalePreference(accountPreferences?.['language.locales'])
    const value = accountValue ?? readLocalPreferences()
    if (!value) return false
    primary.value = value.primary
    secondary.value = value.secondary
    if (accountValue) saveLocalPreferences(accountValue)
    return true
  }
  async function loadLocales() {
    if (loaded) return
    if (loadingPromise) return loadingPromise
    loading.value = true
    loadingPromise = (async () => {
      locales.value = await listUiLocales()
      const hasSavedPreference = await loadPreferences()
      if (!hasSavedPreference) {
        const detected = resolveBrowserUiLocale(browserLanguages(), locales.value)
        if (detected) {
          primary.value = detected
          secondary.value = undefined
          saveLocalPreferences({ primary: detected })
        }
      }
      await loadBundle()
      loaded = true
    })()
    try {
      await loadingPromise
    } finally {
      loading.value = false
      loadingPromise = undefined
    }
  }
  async function setLocale(code: string) { await setPreferences({ primary: code, secondary: secondary.value }) }
  return { locale, primary, secondary, locales, loading, availableCodes, setLocale, setPreferences, loadPreferences, loadBundle, loadLocales }
})
