import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<any>(null)
  const token = ref<string | null>(localStorage.getItem('token'))

  if (token.value) {
    try {
      const payload = JSON.parse(atob(token.value.split('.')[1]))
      user.value = { id: payload.id, username: payload.username, role: payload.role }
    } catch {
      token.value = null
      localStorage.removeItem('token')
    }
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
  }

  return { user, token, logout }
})
