import { ref } from 'vue'
import api from '@/api/client'

export function useSearch() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function search(q: string, params: { lang?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/expressions/search', {
        params: { q, lang_code: params.lang, limit: params.limit, offset: params.offset },
      })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, search }
}
