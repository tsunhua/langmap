import apiClient from './client.js'

export interface Language {
  id: number
  code: string
  name: string
  native_name?: string
  is_active: number
  created_by?: string
  created_at: string
  updated_at?: string
  updated_by?: string
}

export interface CreateLanguageData {
  code: string
  name: string
  native_name?: string
  is_active?: number
}

export interface UpdateLanguageData {
  code?: string
  name?: string
  native_name?: string
  is_active?: number
}

export const languagesApi = {
  async getAll(isActive?: number): Promise<Language[]> {
    const params: any = {}
    if (isActive !== undefined) params.is_active = isActive
    
    const response = await apiClient.get('/languages', { params })
    return response.data
  },

  async create(data: CreateLanguageData): Promise<Language> {
    const response = await apiClient.post('/languages', data)
    return response.data
  },

  async update(id: number, data: UpdateLanguageData): Promise<Language> {
    const response = await apiClient.put(`/languages/${id}`, data)
    return response.data
  },

  async delete(id: number): Promise<{ message: string }> {
    const response = await apiClient.delete(`/languages/${id}`)
    return response.data
  }
}
