import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

interface User {
  id: number
  username: string
  role: string
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))

  const isLoggedIn = computed(() => !!token.value)

  if (token.value) {
    try {
      const payload = JSON.parse(atob(token.value.split('.')[1]))
      if (payload.exp && payload.exp * 1000 < Date.now()) throw new Error('expired')
      user.value = { id: payload.id, username: payload.username, role: payload.role }
    } catch {
      token.value = null
      localStorage.removeItem('token')
    }
  }

  async function login(username: string, password: string) {
    const { data } = await axios.post('/api/v1/auth/login', { username, password })
    token.value = data.data.token
    user.value = data.data.user
    localStorage.setItem('token', data.data.token)
  }

  async function register(username: string, email: string, password: string) {
    const { data } = await axios.post('/api/v1/auth/register', { username, email, password })
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
