import apiClient from './client.js'
import type { Expression, ExpressionFilters } from '../stores/expressions.js'

export interface CreateExpressionData {
  text: string
  language_code: string
  meaning_id?: number
  audio_url?: string
}

export interface UpdateExpressionData {
  text?: string
  language_code?: string
  meaning_id?: number
  audio_url?: string
}

export interface BatchExpressionData {
  expressions: Array<{
    text: string
    language_code: string
    meaning_id?: number
  }>
  ensure_new_meaning?: boolean
}

export const expressionsApi = {
  async getAll(filters: ExpressionFilters = {}): Promise<Expression[]> {
    const params = new URLSearchParams()
    
    if (filters.skip !== undefined) params.append('skip', filters.skip.toString())
    if (filters.limit !== undefined) params.append('limit', filters.limit.toString())
    if (filters.language) params.append('language', filters.language)
    if (filters.meaningId !== undefined) {
      if (Array.isArray(filters.meaningId)) {
        params.append('meaning_id', filters.meaningId.join(','))
      } else {
        params.append('meaning_id', filters.meaningId.toString())
      }
    }
    if (filters.tagPrefix) params.append('tag', filters.tagPrefix)
    if (filters.excludeTagPrefix) params.append('exclude_tag', filters.excludeTagPrefix)
    if (filters.includeMeanings) params.append('include_meanings', 'true')

    const response = await apiClient.get('/expressions', { params })
    return response.data
  },

  async getById(id: number): Promise<Expression> {
    const response = await apiClient.get(`/expressions/${id}`)
    return response.data
  },

  async getByIds(ids: number[]): Promise<Expression[]> {
    const response = await apiClient.get(`/expressions/${ids.join(',')}`)
    return response.data
  },

  async create(data: CreateExpressionData): Promise<Expression> {
    const response = await apiClient.post('/expressions', data)
    return response.data
  },

  async batch(data: BatchExpressionData): Promise<any> {
    const response = await apiClient.post('/expressions/batch', data)
    return response.data
  },

  async ensureExist(data: any): Promise<any> {
    const response = await apiClient.post('/expressions/ensure', data)
    return response.data
  },

  async update(id: number, data: UpdateExpressionData): Promise<Expression> {
    const response = await apiClient.patch(`/expressions/${id}`, data)
    return response.data
  },

  async delete(id: number): Promise<{ message: string }> {
    const response = await apiClient.delete(`/expressions/${id}`)
    return response.data
  },

  async getVersions(id: number): Promise<any[]> {
    const response = await apiClient.get(`/expressions/${id}/versions`)
    return response.data
  },

  async addMeaning(id: number, meaningId: number): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.post(`/expressions/${id}/meanings`, { meaning_id: meaningId })
    return response.data
  },

  async removeMeaning(id: number, meaningId: number): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.delete(`/expressions/${id}/meanings/${meaningId}`)
    return response.data
  },

  async search(query: string, filters: {
    fromLang?: string
    region?: string
    skip?: number
    limit?: number
    includeMeanings?: boolean
  } = {}): Promise<any[]> {
    const params = new URLSearchParams()
    params.append('q', query)
    
    if (filters.fromLang) params.append('from_lang', filters.fromLang)
    if (filters.region) params.append('region', filters.region)
    if (filters.skip !== undefined) params.append('skip', filters.skip.toString())
    if (filters.limit !== undefined) params.append('limit', filters.limit.toString())
    if (filters.includeMeanings) params.append('include_meanings', 'true')

    const response = await apiClient.get('/search', { params })
    return response.data
  }
}
