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

export interface ApiResponse<T = any> {
  success: boolean
  data: T
  message?: string
  error?: string
  details?: any
}

export interface User {
  id?: number
  username?: string
  email?: string
  [key: string]: any
}

// Global cache for language map and locales
let languageMap: Record<string, string> = {}
let localeCache: Record<string, any> = {}

export const languagesApi = {
  async getAll(isActive?: number): Promise<ApiResponse<Language[]>> {
    const params: any = {}
    if (isActive !== undefined) params.is_active = isActive
 
    const response = await apiClient.get('/languages', { params })
    
    // Update language map cache
    if (response.data && response.data.success && Array.isArray(response.data.data)) {
      const newLanguageMap: Record<string, string> = {}
      response.data.data.forEach((lang: Language) => {
        newLanguageMap[lang.code] = lang.name
      })
      languageMap = newLanguageMap
    }
    
    return response.data as ApiResponse<Language[]>
  },

  async create(data: CreateLanguageData): Promise<ApiResponse<Language>> {
    const response = await apiClient.post('/languages', data)
    return response.data as ApiResponse<Language>
  },

  async update(id: number, data: UpdateLanguageData): Promise<ApiResponse<Language>> {
    const response = await apiClient.put(`/languages/${id}`, data)
    return response.data as ApiResponse<Language>
  },

  async delete(id: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/languages/${id}`)
    return response.data as ApiResponse<null>
  },

  async fetchUILocale(languageCode: string): Promise<any> {
    try {
      const response = await apiClient.get(`/ui-locale/${languageCode}`)
      const responseData = response.data as ApiResponse<any>
      localeCache[languageCode] = responseData.data
      return responseData.data || null
    } catch (error: any) {
      if (error.status === 404) {
        console.log(`Locale not found for ${languageCode}`)
        return null
      }
      console.error(`Error fetching UI locale for ${languageCode}:`, error)
      return null
    }
  },

  async saveUILocale(languageCode: string, localeJson: Record<string, any>): Promise<ApiResponse<any>> {
    const response = await apiClient.post(`/ui-locale/${languageCode}`, {
      locale_json: localeJson
    })
    const responseData = response.data as ApiResponse<any>
    localeCache[languageCode] = localeJson
    return responseData
  },

  getLanguageDisplayName(languageCode: string): string {
    return languageMap[languageCode] || languageCode
  },

  getLanguageMapCache(): Record<string, string> {
    return languageMap
  },

  setLanguageMapCache(map: Record<string, string>): void {
    languageMap = map
  },

  getCurrentUser(): User | null {
    try {
      const userStr = localStorage.getItem('user')
      return userStr ? JSON.parse(userStr) : null
    } catch (e) {
      return null
    }
  }
}
