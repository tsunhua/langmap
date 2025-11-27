import axios from 'axios'

// Create axios instance for language API
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1'
})

/**
 * Fetch all available languages from the backend
 * @returns {Promise<Array>} List of available languages
 */
export async function fetchLanguages() {
  try {
    const response = await api.get('/languages')
    return response.data
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
    if (!expression.gloss || !expression.gloss.startsWith('langmap.')) return
    
    const key = expression.gloss.replace('langmap.', '')
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