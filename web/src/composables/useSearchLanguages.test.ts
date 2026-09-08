import { beforeEach, describe, expect, it, vi } from 'vitest'
import { listContentLanguages } from '@/api/languageIdentity'
import {
  clearContentLanguageCache,
  loadContentLanguagePage,
} from './contentLanguageCache'
import {
  rememberSearchLanguage,
  resetRecentSearchLanguages,
  useSearchLanguages,
} from './useSearchLanguages'

vi.mock('@/api/languageIdentity', () => ({ listContentLanguages: vi.fn() }))

class MemoryStorage implements Storage {
  private values = new Map<string, string>()

  get length() {
    return this.values.size
  }

  clear() {
    this.values.clear()
  }

  getItem(key: string) {
    return this.values.get(key) ?? null
  }

  key(index: number) {
    return [...this.values.keys()][index] ?? null
  }

  removeItem(key: string) {
    this.values.delete(key)
  }

  setItem(key: string, value: string) {
    this.values.set(key, value)
  }
}

describe('useSearchLanguages', () => {
  const language = (code: string, name: string, expression_count: number) => ({
    code,
    name,
    name_en: name,
    expression_count,
    locale_count: 1,
    active_ui_locale_count: 0,
  })

  beforeEach(() => {
    vi.clearAllMocks()
    clearContentLanguageCache()
    if (typeof globalThis.localStorage?.clear !== 'function') {
      vi.stubGlobal('localStorage', new MemoryStorage())
    }
    localStorage.clear()
    resetRecentSearchLanguages()
  })

  it('keeps three unique recent languages in newest-first order', () => {
    rememberSearchLanguage('eng')
    rememberSearchLanguage('spa')
    rememberSearchLanguage('jpn')
    rememberSearchLanguage('eng')
    rememberSearchLanguage('nan')

    expect(useSearchLanguages().recent.value).toEqual(['nan', 'eng', 'jpn'])
    expect(JSON.parse(localStorage.getItem('langmap.search.languages') ?? '[]'))
      .toEqual(['nan', 'eng', 'jpn'])
  })

  it('loads only the first 20 content languages and searches more by query', async () => {
    vi.mocked(listContentLanguages).mockImplementation((filters = {}) => Promise.resolve({
      items: filters.q
        ? [language('cmn', 'Mandarin Chinese', 12)]
        : [language('eng', 'English', 8), language('empty', 'Empty', 0)],
      total: filters.q ? 1 : 200,
      skip: 0,
      limit: 20,
      hasMore: true,
      has_more: true,
    }))

    const searchLanguages = useSearchLanguages()
    await searchLanguages.loadSearchLanguages({ ui_locale: 'cmn-Hant-TW' })

    expect(searchLanguages.languages.value.map(item => item.code)).toEqual(['eng'])
    expect(listContentLanguages).toHaveBeenNthCalledWith(1, {
      q: '',
      ui_locale: 'cmn-Hant-TW',
      sort: 'count',
      limit: 20,
      offset: 0,
    })

    await searchLanguages.loadSearchLanguages(
      { ui_locale: 'cmn-Hant-TW' },
      { query: 'Mandarin' },
    )

    expect(searchLanguages.languages.value.map(item => item.code)).toEqual(['cmn'])
    expect(listContentLanguages).toHaveBeenNthCalledWith(2, {
      q: 'Mandarin',
      ui_locale: 'cmn-Hant-TW',
      sort: 'count',
      limit: 20,
      offset: 0,
    })
    expect(listContentLanguages).toHaveBeenCalledTimes(2)
  })

  it('sorts non-recent languages by display name and then code', async () => {
    vi.mocked(listContentLanguages).mockResolvedValue({
      items: [
        language('zho', '中文', 2),
        language('cmn', '中文', 4),
        language('eng', 'English', 8),
      ],
      total: 3,
      skip: 0,
      limit: 100,
      hasMore: false,
      has_more: false,
    })

    const searchLanguages = useSearchLanguages()
    await searchLanguages.loadSearchLanguages({ ui_locale: 'eng-Latn-US' })

    expect(searchLanguages.groups.value.alphabetical.map(item => item.code))
      .toEqual(['eng', 'cmn', 'zho'])
  })

  it('shares an in-flight request and reuses the locale cache', async () => {
    type LanguagePage = Awaited<ReturnType<typeof listContentLanguages>>
    let resolvePage!: (value: LanguagePage) => void
    vi.mocked(listContentLanguages).mockImplementation(() => new Promise<LanguagePage>(resolve => {
      resolvePage = resolve
    }))

    const firstLanguages = useSearchLanguages()
    const secondLanguages = useSearchLanguages()
    const first = firstLanguages.loadSearchLanguages({ ui_locale: 'fra-Latn-FR' })
    const second = secondLanguages.loadSearchLanguages({ ui_locale: 'fra-Latn-FR' })

    expect(listContentLanguages).toHaveBeenCalledTimes(1)
    expect(firstLanguages.loading.value).toBe(true)

    resolvePage({
      items: [language('fra', 'Français', 2)],
      total: 1,
      skip: 0,
      limit: 100,
      hasMore: false,
      has_more: false,
    })
    await Promise.all([first, second])

    expect(firstLanguages.loading.value).toBe(false)
    expect(secondLanguages.languages.value.map(item => item.code)).toEqual(['fra'])

    await firstLanguages.loadSearchLanguages({ ui_locale: 'fra-Latn-FR' })
    expect(listContentLanguages).toHaveBeenCalledTimes(1)
  })

  it('reuses the language page cache when the search menu is opened later', async () => {
    vi.mocked(listContentLanguages).mockResolvedValue({
      items: [language('eng', 'English', 8), language('spa', 'Español', 5)],
      total: 2,
      skip: 0,
      limit: 20,
      hasMore: false,
      has_more: false,
    })

    await loadContentLanguagePage({
      sort: 'count',
      limit: 20,
      offset: 0,
      ui_locale: 'ita-Latn-IT',
    })

    const searchLanguages = useSearchLanguages()
    await searchLanguages.loadSearchLanguages({ ui_locale: 'ita-Latn-IT' })

    expect(listContentLanguages).toHaveBeenCalledTimes(1)
    expect(searchLanguages.languages.value.map(item => item.code)).toEqual(['eng', 'spa'])
  })

  it('exposes a stable load error and clears loading after a failed request', async () => {
    vi.mocked(listContentLanguages).mockRejectedValue(new Error('network unavailable'))

    const searchLanguages = useSearchLanguages()
    await expect(searchLanguages.loadSearchLanguages({ ui_locale: 'deu-Latn-DE' }))
      .rejects.toThrow('SEARCH_LANGUAGES_LOAD_FAILED')

    expect(searchLanguages.loadError.value).toBe('SEARCH_LANGUAGES_LOAD_FAILED')
    expect(searchLanguages.loading.value).toBe(false)
    expect(searchLanguages.languages.value).toEqual([])
  })

  it('resolves an available request before falling back to the newest available recent language', async () => {
    localStorage.setItem('langmap.search.languages', JSON.stringify(['spa', 'zzz', 'eng']))
    resetRecentSearchLanguages({ reload: true })
    vi.mocked(listContentLanguages).mockResolvedValue({
      items: [language('eng', 'English', 8), language('spa', 'Español', 5)],
      total: 2,
      skip: 0,
      limit: 100,
      hasMore: false,
      has_more: false,
    })

    const searchLanguages = useSearchLanguages()
    await searchLanguages.loadSearchLanguages({ ui_locale: 'ita-Latn-IT' })

    expect(searchLanguages.isSearchLanguageAvailable('eng')).toBe(true)
    expect(searchLanguages.isSearchLanguageAvailable('zzz')).toBe(false)
    expect(searchLanguages.resolveSearchLanguage('eng')).toBe('eng')
    expect(searchLanguages.resolveSearchLanguage('zzz')).toBe('spa')
    expect(searchLanguages.resolveSearchLanguage()).toBe('spa')
    expect(searchLanguages.recent.value).toEqual(['spa', 'eng'])
    expect(JSON.parse(localStorage.getItem('langmap.search.languages') ?? '[]'))
      .toEqual(['spa', 'eng'])
  })

  it('keeps the search-language request bounded to one page', async () => {
    vi.mocked(listContentLanguages).mockResolvedValue({
      items: [language('eng', 'English', 1)],
      total: 500,
      skip: 0,
      limit: 20,
      hasMore: true,
      has_more: true,
    })

    const searchLanguages = useSearchLanguages()
    await searchLanguages.loadSearchLanguages({ ui_locale: 'rus-Latn-RU' })

    expect(listContentLanguages).toHaveBeenCalledTimes(1)
    expect(searchLanguages.languages.value).toHaveLength(1)
  })
})
