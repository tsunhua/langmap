import { createI18n } from 'vue-i18n'
import { fetchUITranslations, transformTranslations } from './services/languageService.js'

// Import static messages for default languages
import enMessages from './locales/en.json'
import zhHansMessages from './locales/zh-CN.json'
import zhHantMessages from './locales/zh-TW.json'
import esMessages from './locales/es.json'
import frMessages from './locales/fr.json'
import jaMessages from './locales/ja.json'

// Define static messages for default languages
const staticMessages = {
  en: enMessages,
  'zh-CN': zhHansMessages,
  'zh-TW': zhHantMessages,
  es: esMessages,
  fr: frMessages,
  ja: jaMessages
}


// Cache for dynamically loaded messages
const dynamicMessagesCache = {}

// Create i18n instance
const i18n = createI18n({
  legacy: false, // Use Composition API mode
  locale: 'en', // Default language
  fallbackLocale: 'en', // Fallback language
  messages: staticMessages
})

/**
 * Load UI translations for a given language dynamically
 * @param {string} languageCode - The language code to load translations for
 */
export async function loadLanguage(languageCode) {
  // If it's a static language, no need to fetch anything
  if (staticMessages[languageCode]) {
    return
  }

  // Check if we have cached messages
  if (dynamicMessagesCache[languageCode]) {
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
  } catch (error) {
    console.error(`Failed to load translations for language ${languageCode}:`, error)
    // Fall back to English if failed to load
    i18n.global.setLocaleMessage(languageCode, staticMessages.en)
  }
}

export default i18n