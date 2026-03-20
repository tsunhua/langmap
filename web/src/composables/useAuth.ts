import { useAuthStore } from '../stores/auth.js'
import { authApi } from '../api/auth.js'
import type { RegisterData, LoginData } from '../api/auth.js'

export function useAuth() {
  const authStore = useAuthStore()

  async function register(data: RegisterData) {
    try {
      const result = await authApi.register(data)
      if (result.success && result.data) {
        return { success: true, data: result.data }
      } else {
        return { success: false, error: result.error || result.message || 'Registration failed' }
      }
    } catch (error: any) {
      return { success: false, error: error.message || 'Registration failed' }
    }
  }

  async function login(data: LoginData) {
    try {
      const result = await authApi.login(data)
      if (result.success && result.data) {
        authStore.setToken(result.data.token)
        authStore.setUser(result.data.user)
        return { success: true, data: result.data }
      } else {
        return { success: false, error: result.error || result.message || 'Login failed' }
      }
    } catch (error: any) {
      return { success: false, error: error.message || 'Login failed' }
    }
  }

  async function logout() {
    try {
      await authApi.logout()
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      authStore.logout()
    }
  }

  async function verifyEmail(token: string) {
    try {
      const result = await authApi.verifyEmail(token)
      if (result.success) {
        return { success: true, message: result.message }
      } else {
        return { success: false, error: result.error || result.message || 'Verification failed' }
      }
    } catch (error: any) {
      return { success: false, error: error.message || 'Verification failed' }
    }
  }

  async function fetchUser() {
    try {
      const result = await authApi.getMe()
      if (result.success && result.data) {
        authStore.setUser(result.data)
        return { success: true, data: result.data }
      } else {
        return { success: false, error: result.error || result.message || 'Failed to fetch user' }
      }
    } catch (error: any) {
      return { success: false, error: error.message || 'Failed to fetch user' }
    }
  }

  return {
    isAuthenticated: authStore.isAuthenticated,
    isAdmin: authStore.isAdmin,
    user: authStore.user,
    token: authStore.token,
    register,
    login,
    logout,
    verifyEmail,
    fetchUser
  }
}
