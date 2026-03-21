import apiClient from './client.js'

export interface Handbook {
  id: number
  title: string
  description?: string
  content: string
  is_public: number
  created_by?: string
  created_at: string
  updated_at?: string
  updated_by?: string
  rendered_content?: string
  target_lang?: string
}

export interface CreateHandbookData {
  title: string
  description?: string
  content: string
  is_public?: number
  target_lang?: string
}

export interface UpdateHandbookData {
  title?: string
  description?: string
  content?: string
  is_public?: number
  target_lang?: string
}

export interface ApiResponse<T = any> {
  success: boolean
  data: T
  message?: string
  error?: string
  details?: any
}

function stableHashId(content: string): number {
  let h = 0x811c9dc5
  for (let i = 0; i < content.length; i++) {
    h ^= content.charCodeAt(i)
    h = Math.imul(h, 0x01000193)
  }
  h = h >>> 0
  return (h % (2 ** 31 - 1)) + 1
}

export function stableExpressionId(text: string, languageCode: string): number {
  return stableHashId(`${text}|${languageCode}`)
}

export const handbooksApi = {
  async getAll(options?: { user_id?: number; is_public?: number; skip?: number; limit?: number }): Promise<ApiResponse<Handbook[]>> {
    const response = await apiClient.get('/handbooks', { params: options })
    return response.data as ApiResponse<Handbook[]>
  },

  async getById(id: number, targetLang?: string): Promise<ApiResponse<Handbook>> {
    let url = `/handbooks/${id}`

    if (targetLang) {
      // Use query param for multiple languages or path param for single language
      if (targetLang.includes(',')) {
        url += `?target_lang=${encodeURIComponent(targetLang)}`
      } else {
        url += `/${targetLang}`
      }
    }

    const response = await apiClient.get(url)
    return response.data as ApiResponse<Handbook>
  },

  async create(data: CreateHandbookData): Promise<ApiResponse<Handbook>> {
    const response = await apiClient.post('/handbooks', data)
    return response.data as ApiResponse<Handbook>
  },

  async update(id: number, data: UpdateHandbookData): Promise<ApiResponse<Handbook>> {
    const response = await apiClient.put(`/handbooks/${id}`, data)
    return response.data as ApiResponse<Handbook>
  },

  async delete(id: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/handbooks/${id}`)
    return response.data as ApiResponse<null>
  },

  async rerender(id: number): Promise<ApiResponse<{ message: string }>> {
    const response = await apiClient.post(`/handbooks/${id}/rerender`)
    return response.data as ApiResponse<{ message: string }>
  },

  async getExpressions(languageCode: string, meaningIds: number[]): Promise<ApiResponse<any[]>> {
    if (!meaningIds || meaningIds.length === 0) {
      return { success: true, data: [] }
    }

    const CHUNK_SIZE = 50
    const allResults: any[] = []

    for (let i = 0; i < meaningIds.length; i += CHUNK_SIZE) {
      const chunk = meaningIds.slice(i, i + CHUNK_SIZE)
      const params: any = {
        meaning_id: chunk.join(','),
        limit: 1000,
        include_meanings: 'true'
      }
      if (languageCode) params.language = languageCode

      const response = await apiClient.get('/expressions', { params })
      const responseData = response.data as any
      if (responseData.success && responseData.data) {
        const items = Array.isArray(responseData.data) ? responseData.data : responseData.data.items || []
        if (Array.isArray(items)) {
          allResults.push(...items)
        }
      }
    }

    return { success: true, data: allResults }
  }
}
