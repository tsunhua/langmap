import { ref } from 'vue'
import api from '@/api/client'

export function useSearch() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function search(prefix: string, params: { lang: string; limit?: number; cursor?: string; ui_locale?: string; secondary_ui_locale?: string } ) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/expressions/search', {
        params: {
          prefix,
          lang_code: params.lang,
          limit: params.limit,
          ...(params.cursor ? { cursor: params.cursor } : {}),
          ...(params.ui_locale ? { ui_locale: params.ui_locale } : {}),
          ...(params.secondary_ui_locale ? { secondary_ui_locale: params.secondary_ui_locale } : {}),
        },
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
