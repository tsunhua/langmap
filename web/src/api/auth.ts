import apiClient from './client.js'
import type { User } from '../stores/auth.js'

export interface RegisterData {
  username: string
  email: string
  password: string
}

export interface LoginData {
  email: string
  password: string
}

export interface AuthResponse {
  token: string
  user: User
}

export const authApi = {
  async register(data: RegisterData): Promise<{ success: boolean; data: { user: User }; message: string }> {
    const response = await apiClient.post('/auth/register', data)
    return response.data
  },

  async login(data: LoginData): Promise<{ success: boolean; data: AuthResponse }> {
    const response = await apiClient.post('/auth/login', data)
    return response.data
  },

  async logout(): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.post('/auth/logout')
    return response.data
  },

  async verifyEmail(token: string): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.get('/auth/verify-email', { params: { token } })
    return response.data
  },

  async getMe(): Promise<{ success: boolean; data: User }> {
    const response = await apiClient.get('/users/me')
    return response.data
  }
}
