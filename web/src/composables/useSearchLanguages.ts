import { computed, readonly, ref } from 'vue'
import {
  listContentLanguages,
  type ContentLanguage,
  type LocaleHints,
} from '@/api/languageIdentity'

const STORAGE_KEY = 'langmap.search.languages'
const MAX_RECENT = 3
const DEFAULT_PAGE_SIZE = 100
const MAX_PAGES = 100

function readStoredRecent(): string[] {
  try {
    const storage = globalThis.localStorage
    if (typeof storage?.getItem !== 'function') return []
    const parsed: unknown = JSON.parse(storage.getItem(STORAGE_KEY) ?? '[]')
    return Array.isArray(parsed)
      ? [...new Set(parsed.filter((item): item is string => typeof item === 'string' && item.length > 0))]
      : []
  } catch {
    return []
  }
}

function persist(codes: string[]) {
  try {
    const storage = globalThis.localStorage
    if (typeof storage?.setItem === 'function') {
      storage.setItem(STORAGE_KEY, JSON.stringify(codes))
    }
  } catch {
    // Storage may be unavailable; reactive in-memory state remains usable.
  }
}

export interface SearchLanguageGroups {
  recent: ContentLanguage[]
  alphabetical: ContentLanguage[]
}

let recentHistory = readStoredRecent()
const recent = ref<string[]>(recentHistory.slice(0, MAX_RECENT))
const languages = ref<ContentLanguage[]>([])
const loading = ref(false)
const loadError = ref('')

const languageCache = new Map<string, ContentLanguage[]>()
const pendingLoads = new Map<string, Promise<ContentLanguage[]>>()
let activeLocaleKey = ''
let activeLoadCount = 0

function localeKey(hints: LocaleHints): string {
  return `${hints.ui_locale ?? ''}|${hints.secondary_ui_locale ?? ''}`
}

function compareLanguages(a: ContentLanguage, b: ContentLanguage): number {
  return a.name.localeCompare(b.name) || a.code.localeCompare(b.code)
}

function cleanRecent(available: ReadonlySet<string>) {
  recentHistory = recentHistory.filter(code => available.has(code))
  recent.value = recentHistory.slice(0, MAX_RECENT)
  persist(recent.value)
}

function activateLanguages(key: string, nextLanguages: ContentLanguage[]) {
  languageCache.set(key, nextLanguages)
  if (activeLocaleKey !== key) return
  languages.value = nextLanguages
  cleanRecent(new Set(nextLanguages.map(item => item.code)))
}

const groups = computed<SearchLanguageGroups>(() => {
  const byCode = new Map(languages.value.map(item => [item.code, item]))
  const recentItems = recent.value.flatMap(code => {
    const item = byCode.get(code)
    return item ? [item] : []
  })
  const recentCodes = new Set(recentItems.map(item => item.code))
  return {
    recent: recentItems,
    alphabetical: languages.value
      .filter(item => !recentCodes.has(item.code))
      .sort(compareLanguages),
  }
})

function normalizedPageSize(value: number | undefined): number {
  if (!Number.isFinite(value)) return DEFAULT_PAGE_SIZE
  return Math.max(1, Math.min(Math.trunc(value ?? DEFAULT_PAGE_SIZE), DEFAULT_PAGE_SIZE))
}

async function fetchSearchLanguages(
  hints: LocaleHints,
  pageSize: number,
): Promise<ContentLanguage[]> {
  const byCode = new Map<string, ContentLanguage>()
  let offset = 0

  for (let pageNumber = 0; pageNumber < MAX_PAGES; pageNumber += 1) {
    const page = await listContentLanguages({
      ...hints,
      sort: 'alpha',
      limit: pageSize,
      offset,
    })
    for (const item of page.items) {
      if (item.expression_count > 0) byCode.set(item.code, item)
    }
    if (page.items.length === 0 || !(page.hasMore ?? page.has_more)) break
    offset += page.items.length
  }

  return [...byCode.values()]
}

export async function loadSearchLanguages(
  hints: LocaleHints = {},
  options: { pageSize?: number } = {},
): Promise<void> {
  const key = localeKey(hints)
  const keyChanged = activeLocaleKey !== key
  activeLocaleKey = key

  const cached = languageCache.get(key)
  if (cached) {
    languages.value = cached
    cleanRecent(new Set(cached.map(item => item.code)))
    loadError.value = ''
    return
  }

  const pending = pendingLoads.get(key)
  if (pending) {
    if (keyChanged) languages.value = []
    loadError.value = ''
    try {
      const result = await pending
      activateLanguages(key, result)
    } catch (cause: unknown) {
      if (activeLocaleKey === key) {
        languages.value = []
        loadError.value = 'SEARCH_LANGUAGES_LOAD_FAILED'
      }
      if (cause instanceof Error && cause.message === 'SEARCH_LANGUAGES_LOAD_FAILED') throw cause
      throw new Error('SEARCH_LANGUAGES_LOAD_FAILED')
    }
    return
  }

  loadError.value = ''
  languages.value = []
  activeLoadCount += 1
  loading.value = true

  const request = fetchSearchLanguages(hints, normalizedPageSize(options.pageSize))
  pendingLoads.set(key, request)
  try {
    const result = await request
    activateLanguages(key, result)
  } catch {
    if (activeLocaleKey === key) {
      languages.value = []
      loadError.value = 'SEARCH_LANGUAGES_LOAD_FAILED'
    }
    throw new Error('SEARCH_LANGUAGES_LOAD_FAILED')
  } finally {
    if (pendingLoads.get(key) === request) pendingLoads.delete(key)
    activeLoadCount -= 1
    loading.value = activeLoadCount > 0
  }
}

function isSearchLanguageAvailable(code: string): boolean {
  return languages.value.some(item => item.code === code)
}

function resolveSearchLanguage(requested = ''): string {
  if (requested && isSearchLanguageAvailable(requested)) return requested
  return recent.value.find(isSearchLanguageAvailable) ?? ''
}

export function rememberSearchLanguage(code: string) {
  if (!code) return
  recentHistory = [code, ...recentHistory.filter(item => item !== code)]
  recent.value = recentHistory.slice(0, MAX_RECENT)
  recentHistory = recent.value
  persist(recent.value)
}

export function resetRecentSearchLanguages(options: { reload?: boolean } = {}) {
  recentHistory = options.reload ? readStoredRecent() : []
  recent.value = recentHistory.slice(0, MAX_RECENT)
  if (!options.reload) persist([])
}

export function useSearchLanguages() {
  return {
    recent: readonly(recent),
    languages: readonly(languages),
    groups,
    loading: readonly(loading),
    loadError: readonly(loadError),
    loadSearchLanguages,
    resolveSearchLanguage,
    isSearchLanguageAvailable,
    rememberSearchLanguage,
    resetRecentSearchLanguages,
  }
}

export { isSearchLanguageAvailable, resolveSearchLanguage }
