import { ref } from 'vue'
import { getLanguageDetail, listContentLanguages, listLanguageExpressions } from '@/api/languageIdentity'

export function useLanguages() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function list(params: { search?: string; sort?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      return (await listContentLanguages({ q: params.search, limit: params.limit, offset: params.offset })).items
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
      return await getLanguageDetail(code)
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function expressions(code: string, params: { limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      return await listLanguageExpressions(code, params)
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, list, detail, expressions }
}
