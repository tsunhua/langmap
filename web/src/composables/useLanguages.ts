import { ref } from 'vue'
import api from '@/api/client'

export function useLanguages() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function list(params: { search?: string; sort?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/languages', { params })
      return Array.isArray(data.data) ? data.data : (data.data?.items || [])
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function detail(code: string) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/languages/${code}`)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function expressions(code: string, params: { sort?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/languages/${code}/expressions`, { params })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, list, detail, expressions }
}
