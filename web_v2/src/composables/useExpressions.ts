import { ref } from 'vue'
import api from '@/api/client'

export function useExpressions() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function detail(id: number) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/expressions/${id}`)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function mappings(id: number, hops = 1) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/expressions/${id}/mappings`, { params: { hops } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function search(q: string, lang?: string, limit = 10) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/expressions/search', { params: { q, lang, limit } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, detail, mappings, search }
}
