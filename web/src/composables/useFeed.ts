import { ref } from 'vue'
import api from '@/api/client'
import type { LocaleHints } from '@/api/languageIdentity'

export function useFeed() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function hot(limit = 20, hints: LocaleHints = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/feed', { params: { sort: 'hot', limit, ...hints } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function newest(limit = 20, hints: LocaleHints = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/feed', { params: { sort: 'new', limit, ...hints } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, hot, newest }
}
