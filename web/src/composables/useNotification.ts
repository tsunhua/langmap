import { useUIStore } from '../stores/ui.js'

export function useNotification() {
  const uiStore = useUIStore()

  function success(message: string, duration?: number) {
    uiStore.addNotification({
      type: 'success',
      message,
      duration
    })
  }

  function error(message: string, duration?: number) {
    uiStore.addNotification({
      type: 'error',
      message,
      duration
    })
  }

  function warning(message: string, duration?: number) {
    uiStore.addNotification({
      type: 'warning',
      message,
      duration
    })
  }

  function info(message: string, duration?: number) {
    uiStore.addNotification({
      type: 'info',
      message,
      duration
    })
  }

  function clear() {
    uiStore.clearNotifications()
  }

  return {
    success,
    error,
    warning,
    info,
    clear
  }
}
