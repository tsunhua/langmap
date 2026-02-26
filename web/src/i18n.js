import { createI18n } from 'vue-i18n'
import { fetchUITranslations, fetchLanguages, transformTranslations } from './services/languageService.js'

// Dynamically import all locale files using Vite's import.meta.glob
// This will automatically include all .json files from the locales directory
const localeModules = import.meta.glob('./locales/*.json', { eager: true })

// Import specific well-known languages for backward compatibility
import enMessages from './locales/en-US.json'
import zhHansMessages from './locales/zh-CN.json'
import zhHantMessages from './locales/zh-TW.json'

// Extract language codes and messages from dynamic imports
const dynamicMessages = {}
const dynamicLanguageCodes = []

for (const path in localeModules) {
  // Extract language code from path (e.g., './locales/en-US.json' -> 'en-US')
  const match = path.match(/\.\/locales\/([^.]+)\.json$/)
  if (match) {
    const langCode = match[1]
    dynamicLanguageCodes.push(langCode)
    dynamicMessages[langCode] = localeModules[path].default
  }
}

console.log('[i18n] Dynamically loaded locales:', dynamicLanguageCodes)

// Combine dynamic imports with well-known imports
// Well-known imports ensure backward compatibility and can be removed over time
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
    const languages = await fetchLanguages()
    const languageMap = {}
    
    languages.forEach(lang => {
      // Use direct mapping only, without primary language fallback
      languageMap[lang.code] = lang.code
    })
    
    supportedLanguages = languageMap
    console.log('[i18n] Supported languages initialized:', supportedLanguages)
  } catch (error) {
    console.error('[i18n] Failed to initialize supported languages:', error)
    // Fallback to all dynamically loaded languages
    supportedLanguages = {}
    dynamicLanguageCodes.forEach(code => {
      supportedLanguages[code] = code
    })
  }
}

// Detect browser language
function detectBrowserLanguage() {
  // Try to get language from localStorage first
  const savedLang = localStorage.getItem('langmap-lang')
  if (savedLang && (staticMessages[savedLang] || supportedLanguages[savedLang])) {
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
  
  // Default to English
  console.log('[i18n] No match found, defaulting to en-US')
  return 'en-US'
}

// Create i18n instance
// Initialize supported languages before creating i18n instance
let detectedLanguage = 'en-US'
initializeSupportedLanguages().then(() => {
  detectedLanguage = detectBrowserLanguage()
  i18n.global.locale.value = detectedLanguage
  console.log(`[i18n] Initializing with language: ${detectedLanguage}`)
}).catch(error => {
  console.error('[i18n] Error during initialization:', error)
})

const i18n = createI18n({
  legacy: false, // Use Composition API mode
  locale: detectedLanguage, // Set locale based on browser language
  fallbackLocale: 'en-US', // Fallback language
  messages: staticMessages
})

/**
 * Load UI translations for a given language dynamically
 * @param {string} languageCode - The Language code to load translations for
 */
export async function loadLanguage(languageCode) {
  console.log(`[i18n] Loading language: ${languageCode}`)
  
  // If it's a static language, no need to fetch anything
  if (staticMessages[languageCode]) {
    console.log(`[i18n] Language ${languageCode} is statically available`)
    i18n.global.setLocaleMessage(languageCode, staticMessages[languageCode])
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
    
    // Check if we have any actual translations
    const hasTranslations = Object.keys(messages).length > 0
    
    if (hasTranslations) {
      // Cache the messages
      dynamicMessagesCache[languageCode] = messages
      
      // Set locale messages
      i18n.global.setLocaleMessage(languageCode, messages)
      console.log(`[i18n] Successfully loaded messages for ${languageCode}`)
    } else {
      // If no translations, map to closest supported language
      const mappedLanguage = detectBrowserLanguage()
      console.log(`[i18n] No translations for ${languageCode}, mapping to ${mappedLanguage}`)
      
      // Use messages from mapped language
      const fallbackMessages = staticMessages[mappedLanguage] || staticMessages['en-US']
      i18n.global.setLocaleMessage(languageCode, fallbackMessages)
    }
  } catch (error) {
    console.error(`[i18n] Failed to load translations for language ${languageCode}:`, error)
    // Fall back to English if failed to load
    i18n.global.setLocaleMessage(languageCode, staticMessages['en-US'])
  }
}

export default i18n
