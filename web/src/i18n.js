import { createI18n } from 'vue-i18n'
import { languagesApi } from './api/index.ts'

// Dynamically import all locale files using Vite's import.meta.glob
// This will automatically include all .json files from locales directory
const localeModules = import.meta.glob('./locales/*.json', { eager: true })

// Import specific well-known languages for backward compatibility
import enMessages from './locales/en-US.json'
import zhHansMessages from './locales/zh-CN.json'
import zhHantMessages from './locales/zh-TW.json'

// Extract language codes and messages from dynamic imports
const dynamicMessages = {}
const dynamicLanguageCodes = []

for (const path in localeModules) {
  const match = path.match(/\.\/locales\/([^.]+)\.json$/)
  if (match) {
    const langCode = match[1]
    dynamicLanguageCodes.push(langCode)
    dynamicMessages[langCode] = localeModules[path].default
  }
}

// Combine dynamic imports with well-known imports
const staticMessages = {
  'en-US': enMessages,
  'zh-CN': zhHansMessages,
  'zh-TW': zhHantMessages,
  ...dynamicMessages,
}

// Cache for supported languages mapping with browser language codes
let supportedLanguages = {}

// Cache for dynamically loaded messages
const dynamicMessagesCache = {}

// Initialize supported languages
async function initializeSupportedLanguages() {
  try {
    const response = await languagesApi.getAll()
    const languages = response.data || []
    const languageMap = {}

    languages.forEach(lang => {
      languageMap[lang.code] = lang.code
    })

    supportedLanguages = languageMap
  } catch (error) {
    console.error('[i18n] Failed to initialize supported languages:', error)
    supportedLanguages = {}
    dynamicLanguageCodes.forEach(code => {
      supportedLanguages[code] = code
    })
  }
}

// Detect browser language
function detectBrowserLanguage() {
  const savedLang = localStorage.getItem('langmap-lang')
  if (savedLang && (staticMessages[savedLang] || supportedLanguages[savedLang])) {
    return savedLang
  }

  const browserLang = navigator.language || navigator.languages[0] || 'en-US'

  if (supportedLanguages[browserLang]) {
    return supportedLanguages[browserLang]
  }

  return 'en-US'
}

// Create i18n instance first
const i18n = createI18n({
  legacy: false,
  locale: 'en-US',
  fallbackLocale: 'en-US',
  messages: staticMessages
})

// Initialize supported languages and set detected locale asynchronously
initializeSupportedLanguages().then(() => {
  const detectedLanguage = detectBrowserLanguage()
  i18n.global.locale.value = detectedLanguage
}).catch(error => {
  console.error('[i18n] Error during initialization:', error)
})

export async function loadLanguage(languageCode) {
  if (staticMessages[languageCode]) {
    i18n.global.setLocaleMessage(languageCode, staticMessages[languageCode])
    return
  }

  if (dynamicMessagesCache[languageCode]) {
    i18n.global.setLocaleMessage(languageCode, dynamicMessagesCache[languageCode])
    return
  }

  try {
    const uiLocale = await fetchUILocale(languageCode)
    const hasTranslations = uiLocale && Object.keys(uiLocale.locale_json).length > 0

    if (hasTranslations) {
      dynamicMessagesCache[languageCode] = uiLocale.locale_json
      i18n.global.setLocaleMessage(languageCode, uiLocale.locale_json)
    } else {
      const mappedLanguage = detectBrowserLanguage()
      if (mappedLanguage !== languageCode) {
        await loadLanguage(mappedLanguage)
      }
    }
  } catch (error) {
    console.error(`[i18n] Failed to load messages for ${languageCode}:`, error)

    const fallbackLanguage = 'en-US'
    if (languageCode !== fallbackLanguage && staticMessages[fallbackLanguage]) {
      i18n.global.setLocaleMessage(languageCode, staticMessages[fallbackLanguage])
    }
   }
}

export default i18n
