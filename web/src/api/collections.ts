import apiClient from './client.js'

export interface Collection {
  id: number
  user_id: number
  name: string
  description?: string
  is_public: number
  created_at: string
  updated_at?: string
}

export interface CreateCollectionData {
  name: string
  description?: string
  is_public?: number
}

export interface UpdateCollectionData {
  name?: string
  description?: string
  is_public?: number
}

export const collectionsApi = {
  async getAll(filters: {
    userId?: number
    isPublic?: boolean
    skip?: number
    limit?: number
  } = {}): Promise<Collection[]> {
    const params: any = {}
    if (filters.userId !== undefined) params.user_id = filters.userId
    if (filters.isPublic !== undefined) params.is_public = filters.isPublic ? '1' : '0'
    if (filters.skip !== undefined) params.skip = filters.skip
    if (filters.limit !== undefined) params.limit = filters.limit

    const response = await apiClient.get('/collections', { params })
    return response.data
  },

  async getById(id: number): Promise<Collection> {
    const response = await apiClient.get(`/collections/${id}`)
    return response.data
  },

  async create(data: CreateCollectionData): Promise<Collection> {
    const response = await apiClient.post('/collections', data)
    return response.data
  },

  async update(id: number, data: UpdateCollectionData): Promise<Collection> {
    const response = await apiClient.put(`/collections/${id}`, data)
    return response.data
  },

  async delete(id: number): Promise<{ message: string }> {
    const response = await apiClient.delete(`/collections/${id}`)
    return response.data
  },

  async checkItem(expressionId: number): Promise<number[]> {
    const response = await apiClient.get('/collections/check-item', {
      params: { expression_id: expressionId }
    })
    return response.data
  }
}
