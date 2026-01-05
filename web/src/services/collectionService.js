import axios from 'axios'

// Create axios instance for collection API
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
 * Get all collections
 * @param {Object} options - Filter options
 * @param {number} options.user_id - Filter by user ID
 * @param {number} options.is_public - Filter by public status (1 for public, 0 for private)
 * @returns {Promise<Array>} List of collections
 */
export async function getCollections(options = {}) {
    try {
        const response = await api.get('/collections', { params: options })
        return response.data
    } catch (error) {
        console.error('Error fetching collections:', error)
        throw error
    }
}

/**
 * Get a specific collection by ID
 * @param {number} id - Collection ID
 * @returns {Promise<Object>} Collection object
 */
export async function getCollectionById(id) {
    try {
        const response = await api.get(`/collections/${id}`)
        return response.data
    } catch (error) {
        console.error(`Error fetching collection ${id}:`, error)
        throw error
    }
}

/**
 * Create a new collection
 * @param {Object} collectionData - Collection data
 * @param {string} collectionData.name - Collection name
 * @param {string} collectionData.description - Collection description
 * @param {boolean} collectionData.is_public - Is public
 * @returns {Promise<Object>} Created collection
 */
export async function createCollection(collectionData) {
    try {
        const response = await api.post('/collections', collectionData)
        return response.data
    } catch (error) {
        console.error('Error creating collection:', error)
        throw error
    }
}

/**
 * Update a collection
 * @param {number} id - Collection ID
 * @param {Object} collectionData - Data to update
 * @returns {Promise<Object>} Updated collection
 */
export async function updateCollection(id, collectionData) {
    try {
        const response = await api.put(`/collections/${id}`, collectionData)
        return response.data
    } catch (error) {
        console.error(`Error updating collection ${id}:`, error)
        throw error
    }
}

/**
 * Delete a collection
 * @param {number} id - Collection ID
 * @returns {Promise<Object>} Response
 */
export async function deleteCollection(id) {
    try {
        const response = await api.delete(`/collections/${id}`)
        return response.data
    } catch (error) {
        console.error(`Error deleting collection ${id}:`, error)
        throw error
    }
}

/**
 * Get items in a collection
 * @param {number} id - Collection ID
 * @param {number} skip - Pagination skip
 * @param {number} limit - Pagination limit
 * @returns {Promise<Array>} List of items
 */
export async function getCollectionItems(id, skip = 0, limit = 50) {
    try {
        const response = await api.get(`/collections/${id}/items`, {
            params: { skip, limit }
        })
        return response.data
    } catch (error) {
        console.error(`Error fetching items for collection ${id}:`, error)
        throw error
    }
}

/**
 * Add an item to a collection
 * @param {number} collectionId - Collection ID
 * @param {number} expressionId - Expression ID to add
 * @param {string} note - Optional note
 * @returns {Promise<Object>} Added item
 */
export async function addCollectionItem(collectionId, expressionId, note = '') {
    try {
        const response = await api.post(`/collections/${collectionId}/items`, {
            expression_id: expressionId,
            note
        })
        return response.data
    } catch (error) {
        console.error(`Error adding item to collection ${collectionId}:`, error)
        throw error
    }
}

/**
 * Remove an item from a collection
 * @param {number} collectionId - Collection ID
 * @param {number} expressionId - Expression ID to remove
 * @returns {Promise<Object>} Response
 */
export async function removeCollectionItem(collectionId, expressionId) {
    try {
        const response = await api.delete(`/collections/${collectionId}/items/${expressionId}`)
        return response.data
    } catch (error) {
        console.error(`Error removing item from collection ${collectionId}:`, error)
        throw error
    }
}

/**
 * Get collections containing a specific expression
 * @param {number} expressionId - Expression ID
 * @returns {Promise<Array>} List of collection IDs
 */
export async function getCollectionsContainingItem(expressionId) {
    try {
        const response = await api.get('/collections/check-item', {
            params: { expression_id: expressionId }
        })
        return response.data
    } catch (error) {
        console.error(`Error checking collections for item ${expressionId}:`, error)
        return []
    }
}

/**
 * Initiate an export job for a collection
 * @param {number} collectionId - Collection ID
 * @param {string} format - 'json' or 'csv'
 * @returns {Promise<Object>} Job ID and status
 */
export async function exportCollection(collectionId, format = 'json') {
    try {
        const response = await api.post('/export', {
            collectionId,
            format
        })
        return response.data
    } catch (error) {
        console.error('Error starting export:', error)
        throw error
    }
}

/**
 * Check status of an export job
 * @param {string} jobId - Job ID
 * @returns {Promise<Object>} Job status and result
 */
export async function getExportStatus(jobId) {
    try {
        const response = await api.get(`/export/${jobId}`)
        return response.data
    } catch (error) {
        console.error(`Error fetching export status ${jobId}:`, error)
        throw error
    }
}
