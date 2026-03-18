import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { User } from './auth.js'

export const useUserStore = defineStore('user', () => {
  const users = ref<Map<number, User>>(new Map())
  const loading = ref(false)
  const error = ref<string | null>(null)

  function setUser(user: User) {
    users.value.set(user.id, user)
  }

  function removeUser(userId: number) {
    users.value.delete(userId)
  }

  function getUser(userId: number): User | undefined {
    return users.value.get(userId)
  }

  function clearUsers() {
    users.value.clear()
  }

  function setLoading(value: boolean) {
    loading.value = value
  }

  function setError(value: string | null) {
    error.value = value
  }

  return {
    users,
    loading,
    error,
    setUser,
    removeUser,
    getUser,
    clearUsers,
    setLoading,
    setError
  }
})
