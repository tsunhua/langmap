import axios from 'axios'
import { markContentChanged } from '@/utils/contentRevision'

const api = axios.create({
  baseURL: '/api/v2',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => {
    const method = res.config.method?.toLowerCase()
    const url = res.config.url ?? ''
    if (method && method !== 'get' && (
      url === '/contributions' ||
      url.startsWith('/expressions') ||
      url.startsWith('/language-locales') ||
      url.includes('/mappings')
    )) markContentChanged()
    return res
  },
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/auth'
    }
    return Promise.reject(err)
  }
)

export default api
