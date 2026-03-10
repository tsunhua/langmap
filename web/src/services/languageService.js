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
 * Fetch all available languages from backend and update cache
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

    // Automatically update language map cache
    const newLanguageMap = {}
    languages.forEach(lang => {
      newLanguageMap[lang.code] = lang.name
    })
    languageMap = newLanguageMap

    return languages
  } catch (error) {
    console.error('Error fetching languages:', error)
    throw error
  }
}

/**
 * Fetch UI locale for a specific language
 * @param {string} languageCode - The language code to fetch locale for
 * @returns {Promise<Object|null>} Locale JSON object or null if not found
 */
export async function fetchUILocale(languageCode) {
  try {
    const response = await api.get(`/ui-locale/${languageCode}`)
    return response.data || null
  } catch (error) {
    if (error.response?.status === 404) {
      console.log(`Locale not found for ${languageCode}, will create new one`)
      return null
    }
    console.error(`Error fetching UI locale for ${languageCode}:`, error)
    return null
  }
}

/**
 * Save UI locale for a specific language
 * @param {string} languageCode - The language code
 * @param {Object} localeJson - Flattened locale JSON object to save
 * @returns {Promise<Object>} Response from server
 */
export async function saveUILocale(languageCode, localeJson) {
  try {
    const response = await api.post(`/ui-locale/${languageCode}`, {
      locale_json: localeJson
    })
    return response.data
  } catch (error) {
    console.error(`Error saving UI locale for ${languageCode}:`, error)
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
    // Ensure we have latest auth token
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
 * Get language display name from language code
 * @param {string} languageCode - The language code
 * @param {Object} languageMap - Map of language codes to display names
 * @returns {string} Display name of language
 */
export function getLanguageDisplayName(languageCode) {
  // Return display name from map if available, otherwise return code itself
  // 如果languageMap 为空，则fetch
  if (!languageMap) {
    fetchLanguages()
  }
  return languageMap[languageCode] || languageCode
}

/**
 * Get global language map cache
 * @returns {Object} The cached language map
 */
export function getLanguageMapCache() {
  return languageMap
}

/**
 * Get current user from localStorage
 * @returns {Object|null} User object or null
 */
export function getCurrentUser() {
  const userStr = localStorage.getItem('user')
  if (userStr) {
    try {
      return JSON.parse(userStr)
    } catch (e) {
      return null
    }
  }
  return null
}
