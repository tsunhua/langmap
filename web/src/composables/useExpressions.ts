import { ref } from 'vue'
import api from '@/api/client'
import { getExpression, getMappingGraph } from '@/api/expressions'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'

export function useExpressions() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function detail(id: string) {
    loading.value = true
    error.value = null
    try {
      return await getExpression(id)
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function mappingGraph(id: string, hops: 1 | 2 | 3 = 1): Promise<MappingGraphResponse> {
    loading.value = true
    error.value = null
    try {
      return await getMappingGraph(id, hops)
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
      const { data } = await api.get('/expressions/search', { params: { q, lang_code: lang, limit } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, detail, mappingGraph, search }
}
