import { useAuthStore } from '../stores/auth.js'
import { authApi } from '../api/auth.js'
import type { RegisterData, LoginData } from '../api/auth.js'

export function useAuth() {
  const authStore = useAuthStore()

  async function register(data: RegisterData) {
    try {
      const response = await authApi.register(data)
      return { success: true, data: response.data }
    } catch (error: any) {
      return { success: false, error: error.message || 'Registration failed' }
    }
  }

  async function login(data: LoginData) {
    try {
      const response = await authApi.login(data)
      authStore.setToken(response.data.token)
      authStore.setUser(response.data.user)
      return { success: true, data: response.data }
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
      const response = await authApi.verifyEmail(token)
      return { success: true, message: response.message }
    } catch (error: any) {
      return { success: false, error: error.message || 'Verification failed' }
    }
  }

  async function fetchUser() {
    try {
      const response = await authApi.getMe()
      authStore.setUser(response.data)
      return { success: true, data: response.data }
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
