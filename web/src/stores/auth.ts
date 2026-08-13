import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/api/client'

interface User {
  id: number
  username: string
  role: string
}

interface SessionPayload extends User {
  exp?: number
}

function decodeSessionPayload(token: string): SessionPayload {
  const encoded = token.split('.')[1]
  if (!encoded) throw new Error('invalid token')
  const base64 = encoded.replace(/-/g, '+').replace(/_/g, '/')
    .padEnd(Math.ceil(encoded.length / 4) * 4, '=')
  const value: unknown = JSON.parse(atob(base64))
  if (!value || typeof value !== 'object') throw new Error('invalid token')
  const payload = value as Partial<SessionPayload>
  if (typeof payload.id !== 'number' || typeof payload.username !== 'string' || typeof payload.role !== 'string') {
    throw new Error('invalid token')
  }
  return payload as SessionPayload
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))

  const isLoggedIn = computed(() => !!token.value)

  if (token.value) {
    try {
      const payload = decodeSessionPayload(token.value)
      if (payload.exp && payload.exp * 1000 < Date.now()) throw new Error('expired')
      user.value = { id: payload.id, username: payload.username, role: payload.role }
    } catch {
      token.value = null
      localStorage.removeItem('token')
    }
  }

  async function login(email: string, password: string) {
    const { data } = await api.post('/auth/login', { email, password })
    token.value = data.data.token
    user.value = data.data.user
    localStorage.setItem('token', data.data.token)
  }

  async function register(username: string, email: string, password: string) {
    const { data } = await api.post('/auth/register', { username, email, password })
    token.value = data.data.token
    user.value = data.data.user
    localStorage.setItem('token', data.data.token)
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
  }

  return { user, token, isLoggedIn, login, register, logout }
})
