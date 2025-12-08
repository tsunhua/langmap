import { createI18n } from 'vue-i18n'
import { fetchUITranslations, transformTranslations } from './services/languageService.js'

// Import static messages for default languages
import enMessages from './locales/en-US.json'
import zhHansMessages from './locales/zh-CN.json'
import zhHantMessages from './locales/zh-TW.json'
import esMessages from './locales/es.json'
import frMessages from './locales/fr.json'
import jaMessages from './locales/ja.json'
import nanTWMessages from './locales/nan-TW.json'
import yueHKMessages from './locales/yue-HK.json'

// Define static messages for default languages
const staticMessages = {
  'en-US': enMessages,
  'zh-CN': zhHansMessages,
  'zh-TW': zhHantMessages,
  'nan-TW': nanTWMessages,
  'yue-HK': yueHKMessages,
  es: esMessages,
  fr: frMessages,
  ja: jaMessages,
}

// Supported languages mapping with browser language codes
const supportedLanguages = {
  'en': 'en-US',
  'en-US': 'en-US',
  'en-GB': 'en-US',
  'zh': 'zh-CN',
  'zh-CN': 'zh-CN',
  'zh-TW': 'zh-TW',
  'zh-HK': 'zh-TW',
  'es': 'es',
  'fr': 'fr',
  'ja': 'ja',
  'nan': 'nan-TW',
  'nan-TW': 'nan-TW',
  'yue': 'yue-HK',
  'yue-HK': 'yue-HK'
}

// Cache for dynamically loaded messages
const dynamicMessagesCache = {}

// Detect browser language
function detectBrowserLanguage() {
  // Try to get language from localStorage first
  const savedLang = localStorage.getItem('langmap-lang')
  if (savedLang && staticMessages[savedLang]) {
    console.log(`[i18n] Using saved language from localStorage: ${savedLang}`)
    return savedLang
  }
  
  // Get browser language
  const browserLang = navigator.language || navigator.languages[0] || 'en-US'
  console.log(`[i18n] Detected browser language: ${browserLang}`)
  
  // Check for direct match
  if (supportedLanguages[browserLang]) {
    console.log(`[i18n] Found direct match: ${supportedLanguages[browserLang]}`)
    return supportedLanguages[browserLang]
  }
  
  // Check for partial match (e.g. zh from zh-CN)
  const primaryLang = browserLang.split('-')[0]
  if (supportedLanguages[primaryLang]) {
    console.log(`[i18n] Found primary language match: ${primaryLang} -> ${supportedLanguages[primaryLang]}`)
    return supportedLanguages[primaryLang]
  }
  
  // Default to English
  console.log('[i18n] No match found, defaulting to en-US')
  return 'en-US'
}

// Create i18n instance
const detectedLanguage = detectBrowserLanguage()
console.log(`[i18n] Initializing with language: ${detectedLanguage}`)

const i18n = createI18n({
  legacy: false, // Use Composition API mode
  locale: detectedLanguage, // Set locale based on browser language
  fallbackLocale: 'en-US', // Fallback language
  messages: staticMessages
})

/**
 * Load UI translations for a given language dynamically
 * @param {string} languageCode - The language code to load translations for
 */
export async function loadLanguage(languageCode) {
  console.log(`[i18n] Loading language: ${languageCode}`)
  
  // If it's a static language, no need to fetch anything
  if (staticMessages[languageCode]) {
    console.log(`[i18n] Language ${languageCode} is statically available`)
    return
  }

  // Check if we have cached messages
  if (dynamicMessagesCache[languageCode]) {
    console.log(`[i18n] Using cached messages for ${languageCode}`)
    i18n.global.setLocaleMessage(languageCode, dynamicMessagesCache[languageCode])
    return
  }

  try {
    // Fetch UI translations from backend
    const translations = await fetchUITranslations(languageCode)
    
    // Transform to nested object format
    const messages = transformTranslations(translations)
    
    // Cache the messages
    dynamicMessagesCache[languageCode] = messages
    
    // Set the locale messages
    i18n.global.setLocaleMessage(languageCode, messages)
    console.log(`[i18n] Successfully loaded messages for ${languageCode}`)
  } catch (error) {
    console.error(`[i18n] Failed to load translations for language ${languageCode}:`, error)
    // Fall back to English if failed to load
    i18n.global.setLocaleMessage(languageCode, staticMessages['en-US'])
  }
}

export default i18n