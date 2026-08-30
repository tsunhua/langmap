import { ref } from 'vue'

const STORAGE_KEY = 'langmap.search.languages'
const MAX_RECENT = 6

function load(): string[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed.filter((item) => typeof item === 'string') : []
  } catch {
    return []
  }
}

const recent = ref<string[]>(load())

function persist(list: string[]) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list))
  } catch {
    // storage unavailable (private mode); keep in-memory only
  }
}

function remember(code: string) {
  if (!code) return
  const next = [code, ...recent.value.filter((item) => item !== code)].slice(0, MAX_RECENT)
  recent.value = next
  persist(next)
}

function reset() {
  recent.value = []
  persist([])
}

export function useSearchLanguages() {
  return { recent }
}

export function rememberSearchLanguage(code: string) {
  remember(code)
}

export function resetRecentSearchLanguages() {
  reset()
}