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

export interface ApiResponseWithMessage<T = any> {
  success: boolean
  data: T
  message?: string
  error?: string
  details?: any
}

export const authApi = {
  async register(data: RegisterData): Promise<ApiResponseWithMessage<{ user: User }>> {
    const response = await apiClient.post('/auth/register', data)
    return response.data as ApiResponseWithMessage<{ user: User }>
  },

  async login(data: LoginData): Promise<ApiResponseWithMessage<AuthResponse>> {
    const response = await apiClient.post('/auth/login', data)
    return response.data as ApiResponseWithMessage<AuthResponse>
  },

  async logout(): Promise<ApiResponseWithMessage<null>> {
    const response = await apiClient.post('/auth/logout')
    return response.data as ApiResponseWithMessage<null>
  },

  async verifyEmail(token: string): Promise<ApiResponseWithMessage<null>> {
    const response = await apiClient.get('/auth/verify-email', { params: { token } })
    return response.data as ApiResponseWithMessage<null>
  },

  async getMe(): Promise<ApiResponseWithMessage<User>> {
    const response = await apiClient.get('/users/me')
    return response.data as ApiResponseWithMessage<User>
  }
}
