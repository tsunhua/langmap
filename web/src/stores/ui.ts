import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface Notification {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  message: string
  duration?: number
}

export const useUIStore = defineStore('ui', () => {
  const notifications = ref<Notification[]>([])
  const sidebarOpen = ref(true)
  const darkMode = ref(localStorage.getItem('darkMode') === 'true')

  function addNotification(notification: Omit<Notification, 'id'>) {
    const id = crypto.randomUUID()
    notifications.value.push({
      id,
      ...notification
    })

    if (notification.duration !== 0) {
      const duration = notification.duration || 3000
      setTimeout(() => {
        removeNotification(id)
      }, duration)
    }
  }

  function removeNotification(id: string) {
    const index = notifications.value.findIndex(n => n.id === id)
    if (index > -1) {
      notifications.value.splice(index, 1)
    }
  }

  function clearNotifications() {
    notifications.value = []
  }

  function toggleSidebar() {
    sidebarOpen.value = !sidebarOpen.value
  }

  function setSidebarOpen(value: boolean) {
    sidebarOpen.value = value
  }

  function toggleDarkMode() {
    darkMode.value = !darkMode.value
    localStorage.setItem('darkMode', darkMode.value.toString())
    document.documentElement.classList.toggle('dark', darkMode.value)
  }

  function setDarkMode(value: boolean) {
    darkMode.value = value
    localStorage.setItem('darkMode', value.toString())
    document.documentElement.classList.toggle('dark', value)
  }

  const pageTitle = ref('')

  return {
    notifications,
    sidebarOpen,
    darkMode,
    addNotification,
    removeNotification,
    clearNotifications,
    toggleSidebar,
    setSidebarOpen,
    toggleDarkMode,
    setDarkMode,
    pageTitle
  }
})
