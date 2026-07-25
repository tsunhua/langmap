import { ref } from 'vue'
import api from '@/api/client'

export function useHandbooks() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function list(params: { sort?: string; search?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/handbooks', { params })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function detail(id: number) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/handbooks/${id}`)
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

  async function update(id: number, payload: any) {
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

  async function remove(id: number) {
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

  return { loading, error, list, detail, create, update, remove }
}
