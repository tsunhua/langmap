import { onUnmounted } from 'vue'

export function useLatestRequest() {
  let latest = 0

  function begin() {
    latest += 1
    return latest
  }

  function current() {
    return latest
  }

  function isCurrent(request: number) {
    return request === latest
  }

  onUnmounted(() => { latest += 1 })

  return { begin, current, isCurrent }
}
