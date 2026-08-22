import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { i18n, DEFAULT_LOCALE } from '@/locales'
import { getUiMessages, listUiLocales, type UiLocale } from '@/api/localization'
import { getPreferences, putLanguageLocalePreference, type LanguageLocalePreference } from '@/api/preferences'
import { useAuthStore } from '@/stores/auth'

const KEY = 'langmap.language-locales'
function nested(messages: Array<{ key: string; text: string }>) { const out: Record<string, unknown> = {}; for (const { key, text } of messages) { let target = out; const parts = key.split('.'); for (const part of parts.slice(0, -1)) target = (target[part] ??= {}) as Record<string, unknown>; target[parts[parts.length - 1]] = text } return out }
export const useLocalizationStore = defineStore('localization', () => {
  const global = i18n.global as unknown as { locale: { value: string }; setLocaleMessage: (c: string, m: Record<string, unknown>) => void }
  const primary = ref(DEFAULT_LOCALE); const secondary = ref<string | undefined>(); const locales = ref<UiLocale[]>([]); const loading = ref(false)
  const locale = primary; const availableCodes = computed(() => locales.value.map((item) => item.language_locale_code))
  let loaded = false
  let loadingPromise: Promise<void> | undefined
  async function loadBundle() { const messages = await getUiMessages({ primary: primary.value, secondary: secondary.value }); global.setLocaleMessage(primary.value, nested(messages)); global.locale.value = primary.value; document.documentElement.lang = primary.value.split('_')[0]; document.documentElement.dir = locales.value.find((item) => item.language_locale_code === primary.value)?.direction ?? 'ltr' }
  async function setPreferences(value: LanguageLocalePreference) { if (!value.primary || value.primary === value.secondary) throw new Error('INVALID_LANGUAGE_PREFERENCE'); const auth = useAuthStore(); if (auth.isLoggedIn) await putLanguageLocalePreference(value); else localStorage.setItem(KEY, JSON.stringify(value)); primary.value = value.primary; secondary.value = value.secondary; await loadBundle() }
  async function loadPreferences() { const auth = useAuthStore(); let value: LanguageLocalePreference | undefined; if (auth.isLoggedIn) value = (await getPreferences())['language.locales'] as LanguageLocalePreference | undefined; else { try { value = JSON.parse(localStorage.getItem(KEY) || '') } catch {} } if (value?.primary) { primary.value = value.primary; secondary.value = value.secondary } }
  async function loadLocales() {
    if (loaded) return
    if (loadingPromise) return loadingPromise
    loading.value = true
    loadingPromise = (async () => {
      locales.value = await listUiLocales()
      await loadPreferences()
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
