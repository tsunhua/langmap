import apiClient from './client.js'
import type { Expression, ExpressionFilters } from '../stores/expressions.js'

export interface CreateExpressionData {
  text: string
  language_code: string
  audio_url?: string
}

export interface UpdateExpressionData {
  text?: string
  language_code?: string
  audio_url?: string
}

export interface BatchExpressionData {
  expressions: Array<{
    text: string
    language_code: string
    group_id?: number
  }>
  ensure_new_group?: boolean
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  skip: number
  limit: number
  hasMore: boolean
}

export interface ApiResponse<T = any> {
  success: boolean
  data: T
  message?: string
  error?: string
  details?: any
}

export interface BatchResponse {
  group_id: number
  results: any[]
}

export const expressionsApi = {
  async getAll(filters: ExpressionFilters = {}): Promise<PaginatedResponse<Expression>> {
    const params = new URLSearchParams()

    if (filters.skip !== undefined) params.append('skip', filters.skip.toString())
    if (filters.limit !== undefined) params.append('limit', filters.limit.toString())
    if (filters.lang) params.append('lang', filters.lang)

    if (filters.tagPrefix) params.append('tag', filters.tagPrefix)
    if (filters.excludeTagPrefix) params.append('exclude_tag', filters.excludeTagPrefix)

    const response = await apiClient.get('/expressions', { params })
    return response.data as PaginatedResponse<Expression>
  },

  async getById(id: number): Promise<ApiResponse<Expression>> {
    const response = await apiClient.get(`/expressions/${id}`)
    return response.data as ApiResponse<Expression>
  },

  async getByIds(ids: number[]): Promise<ApiResponse<Expression[]>> {
    const response = await apiClient.get(`/expressions/${ids.join(',')}`)
    return response.data as ApiResponse<Expression[]>
  },

  async create(data: CreateExpressionData): Promise<ApiResponse<Expression>> {
    const response = await apiClient.post('/expressions', data)
    return response.data as ApiResponse<Expression>
  },

  async batch(data: BatchExpressionData): Promise<ApiResponse<BatchResponse>> {
    const response = await apiClient.post('/expressions/batch', data)
    return response.data as ApiResponse<BatchResponse>
  },

  async ensureExist(data: any): Promise<ApiResponse<any>> {
    const response = await apiClient.post('/expressions/ensure', data)
    return response.data as ApiResponse<any>
  },

  async update(id: number, data: UpdateExpressionData): Promise<ApiResponse<Expression>> {
    const response = await apiClient.patch(`/expressions/${id}`, data)
    return response.data as ApiResponse<Expression>
  },

  async delete(id: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/expressions/${id}`)
    return response.data as ApiResponse<null>
  },

  async getVersions(id: number): Promise<ApiResponse<any[]>> {
    const response = await apiClient.get(`/expressions/${id}/versions`)
    return response.data as ApiResponse<any[]>
  },

  async uploadAudio(id: number, file: File): Promise<ApiResponse<{ audio_url: string }>> {
    const formData = new FormData()
    formData.append('audio_file', file)
    const response = await apiClient.post(`/expressions/${id}/upload-audio`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    return response.data as ApiResponse<{ audio_url: string }>
  },

  async deleteAudio(id: number, speaker: string): Promise<ApiResponse<{ message: string; audio_url: string | null }>> {
    const response = await apiClient.delete(`/expressions/${id}/audio`, { params: { speaker } })
    return response.data as ApiResponse<{ message: string; audio_url: string | null }>
  },

  async search(query: string, filters: {
    fromLang?: string
    region?: string
    skip?: number
    limit?: number
    includeMeanings?: boolean
  } = {}): Promise<ApiResponse<any[]>> {
    const params = new URLSearchParams()
    params.append('q', query)
    
    if (filters.fromLang) params.append('from_lang', filters.fromLang)
    if (filters.region) params.append('region', filters.region)
    if (filters.skip !== undefined) params.append('skip', filters.skip.toString())
    if (filters.limit !== undefined) params.append('limit', filters.limit.toString())
    if (filters.includeMeanings) params.append('include_meanings', 'true')
    
    const response = await apiClient.get('/search', { params })
    return response.data as ApiResponse<any[]>
  }
}
