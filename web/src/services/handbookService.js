import axios from 'axios'

// Create axios instance for handbook API
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

/**
 * Get all handbooks
 * @param {Object} options - Filter options
 * @param {number} options.user_id - Filter by user ID
 * @param {number} options.is_public - Filter by public status (1 for public, 0 for private)
 * @param {number} options.skip - Pagination skip
 * @param {number} options.limit - Pagination limit
 * @returns {Promise<Array>} List of handbooks
 */
export async function getHandbooks(options = {}) {
    try {
        const response = await api.get('/handbooks', { params: options })
        return response.data
    } catch (error) {
        console.error('Error fetching handbooks:', error)
        throw error
    }
}

/**
 * Get a specific handbook by ID
 * @param {number} id - Handbook ID
 * @returns {Promise<Object>} Handbook object
 */
export async function getHandbookById(id) {
    try {
        const response = await api.get(`/handbooks/${id}`)
        return response.data
    } catch (error) {
        console.error(`Error fetching handbook ${id}:`, error)
        throw error
    }
}

/**
 * Create a new handbook
 * @param {Object} handbookData - Handbook data
 * @param {string} handbookData.title - Handbook title
 * @param {string} handbookData.description - Handbook description
 * @param {string} handbookData.content - Markdown content
 * @param {boolean} handbookData.is_public - Is public
 * @returns {Promise<Object>} Created handbook
 */
export async function createHandbook(handbookData) {
    try {
        const response = await api.post('/handbooks', handbookData)
        return response.data
    } catch (error) {
        console.error('Error creating handbook:', error)
        throw error
    }
}

/**
 * Update a handbook
 * @param {number} id - Handbook ID
 * @param {Object} handbookData - Data to update
 * @returns {Promise<Object>} Updated handbook
 */
export async function updateHandbook(id, handbookData) {
    try {
        const response = await api.put(`/handbooks/${id}`, handbookData)
        return response.data
    } catch (error) {
        console.error(`Error updating handbook ${id}:`, error)
        throw error
    }
}

/**
 * Delete a handbook
 * @param {number} id - Handbook ID
 * @returns {Promise<Object>} Response
 */
export async function deleteHandbook(id) {
    try {
        const response = await api.delete(`/handbooks/${id}`)
        return response.data
    } catch (error) {
        console.error(`Error deleting handbook ${id}:`, error)
        throw error
    }
}

/**
 * Get expressions for handbook rendering
 * @param {string} languageCode - Target language code
 * @param {Array<number>} meaningIds - List of meaning IDs to fetch
 * @returns {Promise<Array>} List of expressions for the given meanings in the target language
 */
export async function getHandbookExpressions(languageCode, meaningIds) {
    if (!meaningIds || meaningIds.length === 0) return []

    try {
        const response = await api.get('/expressions', {
            params: {
                language: languageCode,
                meaning_id: meaningIds.join(','),
                limit: 1000 // Sufficient for most handbooks
            }
        })
        return response.data
    } catch (error) {
        console.error('Error fetching expressions for handbook:', error)
        throw error
    }
}
