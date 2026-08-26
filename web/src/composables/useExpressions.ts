import { ref } from 'vue'
import api from '@/api/client'
import { getExpression, getMappingGraph } from '@/api/expressions'
import type { LocaleHints } from '@/api/languageIdentity'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'

export function useExpressions() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function detail(id: string, hints: LocaleHints = {}) {
    loading.value = true
    error.value = null
    try {
      return await getExpression(id, hints)
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function mappingGraph(id: string, hops: 1 | 2 | 3 = 1, hints: LocaleHints = {}, targetLanguage?: string): Promise<MappingGraphResponse> {
    loading.value = true
    error.value = null
    try {
      return await getMappingGraph(id, hops, hints, targetLanguage)
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function search(prefix: string, lang?: string, limit = 10, cursor?: string | LocaleHints, hints: LocaleHints = {}) {
    loading.value = true
    error.value = null
    try {
      const resolvedHints = typeof cursor === 'object' ? cursor : hints
      const resolvedCursor = typeof cursor === 'string' ? cursor : undefined
      const { data } = await api.get('/expressions/search', { params: { q: prefix, ...(lang ? { lang_code: lang } : {}), limit, ...(resolvedCursor ? { cursor: resolvedCursor } : {}), ...resolvedHints } })
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
