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
  author?: string
  published_at?: string
  has_pages?: number
  page_count?: number
}

export interface CreateHandbookData {
  title: string
  description?: string
  content: string
  is_public?: number
  target_lang?: string
  author?: string
  published_at?: string
}

export interface UpdateHandbookData {
  title?: string
  description?: string
  content?: string
  is_public?: number
  target_lang?: string
  author?: string
  published_at?: string
}

export interface HandbookPage {
  id: number
  handbook_id: number
  title: string
  content: string
  sort_order: number
  created_at: string
  updated_at?: string
  rendered_content?: string
  rendered_title?: string
}

export interface CreateHandbookPageData {
  title: string
  content?: string
  sort_order?: number
}

export interface UpdateHandbookPageData {
  title?: string
  content?: string
  sort_order?: number
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

  async getById(id: number, targetLang?: string, targetLangsParam?: string): Promise<ApiResponse<Handbook>> {
    let url = `/handbooks/${id}`

    if (targetLangsParam) {
      // Use query param for multiple languages or path param for single language
      if (targetLangsParam.includes(',')) {
        url += `?target_langs=${encodeURIComponent(targetLangsParam)}`
      } else {
        url += `/${targetLangsParam}`
      }
    } else if (targetLang) {
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

  async getPages(handbookId: number): Promise<ApiResponse<HandbookPage[]>> {
    const response = await apiClient.get(`/handbooks/${handbookId}/pages`)
    return response.data as ApiResponse<HandbookPage[]>
  },

  async getPageById(handbookId: number, pageId: number, targetLang?: string): Promise<ApiResponse<HandbookPage>> {
    let url = `/handbooks/${handbookId}/pages/${pageId}`
    if (targetLang) {
      url += `?target_lang=${encodeURIComponent(targetLang)}`
    }
    const response = await apiClient.get(url)
    return response.data as ApiResponse<HandbookPage>
  },

  async createPage(handbookId: number, data: CreateHandbookPageData): Promise<ApiResponse<HandbookPage>> {
    const response = await apiClient.post(`/handbooks/${handbookId}/pages`, data)
    return response.data as ApiResponse<HandbookPage>
  },

  async updatePage(handbookId: number, pageId: number, data: UpdateHandbookPageData): Promise<ApiResponse<HandbookPage>> {
    const response = await apiClient.put(`/handbooks/${handbookId}/pages/${pageId}`, data)
    return response.data as ApiResponse<HandbookPage>
  },

  async deletePage(handbookId: number, pageId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/handbooks/${handbookId}/pages/${pageId}`)
    return response.data as ApiResponse<null>
  },

  async reorderPages(handbookId: number, pages: Array<{ id: number; sort_order: number }>): Promise<ApiResponse<null>> {
    const response = await apiClient.put(`/handbooks/${handbookId}/pages/reorder`, { pages })
    return response.data as ApiResponse<null>
  },

  async rerenderPage(handbookId: number, pageId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.post(`/handbooks/${handbookId}/pages/${pageId}/rerender`)
    return response.data as ApiResponse<null>
  },

  async previewPage(handbookId: number, data: { title?: string; content?: string; source_lang?: string; target_lang?: string }): Promise<ApiResponse<any>> {
    const response = await apiClient.post(`/handbooks/${handbookId}/pages/preview`, data)
    return response.data as ApiResponse<any>
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
