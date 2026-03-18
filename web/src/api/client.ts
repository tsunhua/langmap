import axios from 'axios'
import { useAuthStore } from '../stores/auth.js'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8787/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

apiClient.interceptors.request.use(
  (config) => {
    const authStore = useAuthStore()
    if (authStore.token) {
      config.headers.Authorization = `Bearer ${authStore.token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

apiClient.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    if (error.response) {
      const status = error.response.status
      const message = error.response.data?.error || error.response.data?.message || 'An error occurred'

      if (status === 401) {
        const authStore = useAuthStore()
        authStore.clearAuth()
        window.location.href = '/#/login'
      }

      if (status === 403) {
        const uiStore = useUIStore()
        uiStore.addNotification({
          type: 'error',
          message: 'Access denied'
        })
      }

      return Promise.reject({
        status,
        message,
        data: error.response.data
      })
    }

    if (error.request) {
      const uiStore = useUIStore()
      uiStore.addNotification({
        type: 'error',
        message: 'Network error. Please check your connection.'
      })
      return Promise.reject({
        message: 'Network error'
      })
    }

    return Promise.reject(error)
  }
)

export default apiClient
