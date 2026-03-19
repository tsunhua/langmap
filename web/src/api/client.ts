import axios from 'axios'
import { useAuthStore, useUIStore } from '../stores/index.js'

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
    const responseData = response.data

    if (typeof responseData === 'object' && responseData !== null) {
        if ('success' in responseData) {
          if (responseData.success === false) {
            const errorMsg = responseData.error || responseData.message || 'Request failed'
            const errorObj = {
              status: response.status,
              message: errorMsg,
              data: responseData.details || responseData
            }
 
            if (response.status === 401) {
              const authStore = useAuthStore()
              authStore.clearAuth()
              window.location.href = '/#/login'
            } else if (response.status === 403) {
              const uiStore = useUIStore()
              uiStore.addNotification({
                type: 'error',
                message: errorMsg
              })
            }
 
            return Promise.reject(errorObj)
          }
        }
    }

    return response
  },
  (error) => {
    if (error.response) {
      const status = error.response.status
      const responseData = error.response.data
      const message = responseData?.error || responseData?.message || 'An error occurred'

      if (status === 401) {
        const authStore = useAuthStore()
        authStore.clearAuth()
        window.location.href = '/#/login'
      }

      if (status === 403) {
        const uiStore = useUIStore()
        uiStore.addNotification({
          type: 'error',
          message: message
        })
      }

      return Promise.reject({
        status,
        message,
        data: responseData
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
