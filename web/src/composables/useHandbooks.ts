import { ref } from 'vue'
import api from '@/api/client'
import type { LocaleHints } from '@/api/languageIdentity'

export interface HandbookSummary { id: string; title: string; author_username?: string; section_count: number; expression_count: number; score: number; created_at?: string }
export interface HandbookPage<T = HandbookSummary> { items: T[]; next_cursor: string | null; has_more: boolean }

export function useHandbooks() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function list(params: { sort?: 'new' | 'hot'; search?: string; limit?: number; cursor?: string } = {}, hints: LocaleHints = {}): Promise<HandbookPage> {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/handbooks', { params: { sort: params.sort ?? 'new', limit: params.limit ?? 20, ...(params.cursor ? { cursor: params.cursor } : {}), ...(params.search ? { search: params.search } : {}), ...hints } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function detail(id: string, hints: LocaleHints = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/handbooks/${id}`, { params: hints })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function create(payload: { title: string; visibility?: string; sections: any[] }) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.post('/handbooks', payload)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function update(id: string, payload: any) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.put(`/handbooks/${id}`, payload)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function remove(id: string) {
    loading.value = true
    error.value = null
    try {
      await api.delete(`/handbooks/${id}`)
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function vote(id: string, direction: 'up' | 'down') {
    const { data } = await api.post(`/handbooks/${encodeURIComponent(id)}/vote`, { direction })
    return data.data
  }

  return { loading, error, list, detail, create, update, remove, vote }
}
