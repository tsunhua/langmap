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

export interface ApiResponse<T = any> {
  data: T
  message?: string
}

export interface CollectionItem {
  id: number
  collection_id: number
  expression_id: number
  note?: string
  created_at: string
  expression?: any
}

export const collectionsApi = {
  async getAll(filters: {
    userId?: number
    isPublic?: boolean
    skip?: number
    limit?: number
  } = {}): Promise<ApiResponse<Collection[]>> {
    const params: any = {}
    if (filters.userId !== undefined) params.user_id = filters.userId
    if (filters.isPublic !== undefined) params.is_public = filters.isPublic ? '1' : '0'
    if (filters.skip !== undefined) params.skip = filters.skip
    if (filters.limit !== undefined) params.limit = filters.limit
 
    const response = await apiClient.get('/collections', { params })
    return response.data as ApiResponse<Collection[]>
  },

  async getById(id: number): Promise<ApiResponse<Collection>> {
    const response = await apiClient.get(`/collections/${id}`)
    return response.data as ApiResponse<Collection>
  },

  async create(data: CreateCollectionData): Promise<ApiResponse<Collection>> {
    const response = await apiClient.post('/collections', data)
    return response.data as ApiResponse<Collection>
  },

  async update(id: number, data: UpdateCollectionData): Promise<ApiResponse<Collection>> {
    const response = await apiClient.put(`/collections/${id}`, data)
    return response.data as ApiResponse<Collection>
  },

  async delete(id: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/collections/${id}`)
    return response.data as ApiResponse<null>
  },

  async checkItem(expressionId: number): Promise<ApiResponse<number[]>> {
    const response = await apiClient.get('/collections/check-item', {
      params: { expression_id: expressionId }
    })
    return response.data as ApiResponse<number[]>
  },

  async getItems(id: number, filters: {
    skip?: number
    limit?: number
  } = {}): Promise<ApiResponse<CollectionItem[]>> {
    const params: any = {}
    if (filters.skip !== undefined) params.skip = filters.skip
    if (filters.limit !== undefined) params.limit = filters.limit
 
    const response = await apiClient.get(`/collections/${id}/items`, { params })
    return response.data as ApiResponse<CollectionItem[]>
  },

  async addItem(id: number, expressionId: number, note?: string): Promise<ApiResponse<CollectionItem>> {
    const response = await apiClient.post(`/collections/${id}/items`, {
      expression_id: expressionId,
      note
    })
    return response.data as ApiResponse<ApiResponse<CollectionItem>>
  },

  async removeItem(id: number, expressionId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/collections/${id}/items/${expressionId}`)
    return response.data as ApiResponse<null>
  }
}
