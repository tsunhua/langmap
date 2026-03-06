import axios from 'axios'

// Create axios instance for handbook API
const api = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1'
})

/**
 * Generate a stable ID based on the content using FNV-1a 32-bit hash.
 * Synchronized with backend implementation.
 */
function stableHashId(content) {
    let h = 0x811c9dc5; // FNV offset basis
    for (let i = 0; i < content.length; i++) {
        h ^= content.charCodeAt(i);
        h = Math.imul(h, 0x01000193); // FNV prime
    }
    h = h >>> 0; // convert to unsigned int32

    // Ensure we don't get 0 as ID (minimum ID should be 1)
    return (h % (2 ** 31 - 1)) + 1;
}

/**
 * Generate a stable Expression ID using FNV-1a 32-bit hash.
 */
export function stableExpressionId(text, languageCode) {
    return stableHashId(`${text}|${languageCode}`);
}

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
 * @param {string} targetLang - Optional target language for rendering
 * @returns {Promise<Object>} Handbook object
 */
export async function getHandbookById(id, targetLang) {
    try {
        const url = targetLang ? `/handbooks/${id}/${targetLang}` : `/handbooks/${id}`
        const response = await api.get(url)
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

    const CHUNK_SIZE = 50 // Limit IDs per request to avoid URL length issues
    const allResults = []

    try {
        for (let i = 0; i < meaningIds.length; i += CHUNK_SIZE) {
            const chunk = meaningIds.slice(i, i + CHUNK_SIZE)
            const response = await api.get('/expressions', {
                params: {
                    language: languageCode,
                    meaning_id: chunk.join(','),
                    limit: 1000
                }
            })
            if (response.data) {
                allResults.push(...response.data)
            }
        }
        return allResults
    } catch (error) {
        console.error('Error fetching expressions for handbook:', error)
        throw error
    }
}

/**
 * Get a specific expression by ID
 * @param {number} id - Expression ID
 * @returns {Promise<Object>} Expression with meanings
 */
export async function getExpressionById(id) {
    try {
        const response = await api.get(`/expressions/${id}`)
        return response.data
    } catch (error) {
        console.error(`Error fetching expression ${id}:`, error)
        throw error
    }
}

/**
 * Get multiple expressions by IDs (batch fetch)
 * @param {number[]} ids - Array of expression IDs
 * @returns {Promise<Array>} Array of expressions
 */
export async function getExpressionsByIds(ids) {
    if (!ids || ids.length === 0) return []

    try {
        const CHUNK_SIZE = 50 // Limit IDs per request
        const allResults = []

        for (let i = 0; i < ids.length; i += CHUNK_SIZE) {
            const chunk = ids.slice(i, i + CHUNK_SIZE)
            const response = await api.get(`/expressions/${chunk.join(',')}`)
            if (response.data) {
                allResults.push(...response.data)
            }
        }

        return allResults
    } catch (error) {
        console.error('Error fetching expressions by IDs:', error)
        throw error
    }
}

