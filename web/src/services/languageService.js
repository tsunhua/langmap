import axios from 'axios'

// Create axios instance for language API
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1'
})

// Add interceptor to include auth token in requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Clear auth token if 401 error
      localStorage.removeItem('authToken')
      // Optionally redirect to login page
      window.dispatchEvent(new CustomEvent('auth-error'))
    }
    return Promise.reject(error)
  }
)

// Global cache for language map
let languageMap = {}

/**
 * Fetch all available languages from the backend and update cache
 * @param {number|undefined} isActive - Filter languages by is_active status (1=active, 0=inactive, undefined=all)
 * @returns {Promise<Array>} List of available languages
 */
export async function fetchLanguages(isActive) {
  try {
    let url = '/languages'
    if (isActive !== undefined) {
      url += `?is_active=${isActive}`
    }
    
    const response = await api.get(url)
    const languages = response.data
    
    // Automatically update the language map cache
    const newLanguageMap = {}
    languages.forEach(lang => {
      newLanguageMap[lang.code] = lang.native_name || lang.name
    })
    languageMap = newLanguageMap
    
    return languages
  } catch (error) {
    console.error('Error fetching languages:', error)
    throw error
  }
}

/**
 * Fetch UI translations for a specific language by meaning tags
 * @param {string} languageCode - The language code to fetch translations for
 * @returns {Promise<Array>} List of expressions with langmap meanings
 */
export async function fetchUITranslations(languageCode) {
  try {
    const response = await api.get(`/ui-translations/${languageCode}`)
    return response.data
  } catch (error) {
    console.error(`Error fetching UI translations for ${languageCode}:`, error)
    throw error
  }
}

/**
 * Create a new language
 * @param {Object} languageData - Language data to create
 * @returns {Promise<Object>} Created language object
 */
export async function createLanguage(languageData) {
  try {
    // Ensure we have the latest auth token
    const token = localStorage.getItem('authToken')
    if (token) {
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    }
    
    const response = await api.post('/languages', languageData)
    return response.data
  } catch (error) {
    console.error('Error creating language:', error)
    throw error
  }
}

/**
 * Transform flat expressions list to nested i18n messages object
 * @param {Array} expressions - List of expressions with glosses
 * @returns {Object} Nested messages object for vue-i18n
 */
export function transformTranslations(expressions) {
  const messages = {}
  
  expressions.forEach(expression => {
    // Extract key from gloss (assuming format "langmap.key.path")
    if (!expression.tags) return
    
    const key = JSON.stringify(expression.tags)[0]
    const keys = key.split('.')
    
    // Navigate/create nested objects
    let current = messages
    for (let i = 0; i < keys.length - 1; i++) {
      if (!current[keys[i]]) {
        current[keys[i]] = {}
      }
      current = current[keys[i]]
    }
    
    // Set the final value
    current[keys[keys.length - 1]] = expression.text
  })
  
  return messages
}

/**
 * Get language display name from language code
 * @param {string} languageCode - The language code
 * @param {Object} languageMap - Map of language codes to display names
 * @returns {string} Display name of the language
 */
export function getLanguageDisplayName(languageCode) {
  // Return the display name from the map if available, otherwise return the code itself
  // 如果languageMap 为空，则fetch
  if (!languageMap) {
    fetchLanguages()
  }
  return languageMap[languageCode] || languageCode
}

/**
 * Get the global language map cache
 * @returns {Object} The cached language map
 */
export function getLanguageMapCache() {
  return languageMap
}