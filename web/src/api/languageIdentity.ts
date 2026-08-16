import api from './client'

export interface Page<T> {
  items: T[]
  total: number
  skip: number
  limit: number
  hasMore: boolean
}

export interface LocaleHints { ui_locale?: string; secondary_ui_locale?: string }

export interface Language { code: string; name_en: string; name?: string }
export interface Script { code: string; name_en: string; direction: 'ltr' | 'rtl' }
export interface Region { code: string; name_en: string; latitude: number | null; longitude: number | null }
export interface LanguageLocale {
  code: string
  lang_code: string
  script_code: string
  region_code: string
  place_path: string
  name: string
  name_en: string
  display_name?: string
  latitude: number | null
  longitude: number | null
  coordinate_source?: 'locale' | 'region' | null
}

export interface CreateLanguageLocaleInput {
  lang_code: string
  script_code: string
  region_code: string
  place_segments: string[]
  name: string
  name_en: string
  latitude?: number
  longitude?: number
  source?: { type: 'publication' | 'url'; name: string; ref?: string }
}

export interface LocaleFilters { lang_code?: string; script_code?: string; region_code?: string; q?: string; limit?: number; offset?: number; ui_locale?: string; secondary_ui_locale?: string }
export interface ContentLanguage {
  code: string
  name: string
  name_en: string
  expression_count: number
  locale_count: number
  active_ui_locale_count: number
}

export interface ContentLanguagePageQuery {
  q?: string
  sort?: 'count' | 'alpha'
  limit?: number
  offset?: number
  /** UI locale the caller renders in; the API resolves `name` against it. */
  ui_locale?: string
  secondary_ui_locale?: string
}

export interface LanguageExpressionPageQuery {
  q?: string
  sort?: 'hot' | 'new' | 'alpha'
  locale?: string
  limit?: number
  offset?: number
  ui_locale?: string
  secondary_ui_locale?: string
}

export interface LanguageDetail extends ContentLanguage {
  reading_count: number
  mapped_expression_count: number
  locales: LanguageLocale[]
}

export interface LanguageExpressionSummary {
  id: string
  lang_code: string
  text: string
  description: string
  homograph_index: number
  review_status: string
  created_at: string
  reading_count: number
  mapping_count: number
}

function page<T>(data: unknown): Page<T> {
  const result = data as { data?: Partial<Page<T>> }
  return {
    items: result.data?.items ?? [], total: result.data?.total ?? 0,
    skip: result.data?.skip ?? 0, limit: result.data?.limit ?? 20, hasMore: result.data?.hasMore ?? false,
  }
}

function hintParams(hints?: LocaleHints): { ui_locale?: string; secondary_ui_locale?: string } {
  const params: { ui_locale?: string; secondary_ui_locale?: string } = {}
  if (hints?.ui_locale) params.ui_locale = hints.ui_locale
  if (hints?.secondary_ui_locale) params.secondary_ui_locale = hints.secondary_ui_locale
  return params
}

async function listReference<T>(path: string, q = '', limit = 20, offset = 0, hints?: LocaleHints, signal?: AbortSignal): Promise<Page<T>> {
  const { data } = await api.get(path, { params: { q, limit, offset, ...hintParams(hints) }, signal })
  return page<T>(data)
}

export const listLanguages = (q = '', limit = 20, offset = 0, hints?: LocaleHints, signal?: AbortSignal) => listReference<Language>('/language-registry/languages', q, limit, offset, hints, signal)
export const listScripts = (q = '', limit = 20, offset = 0, signal?: AbortSignal) => listReference<Script>('/language-registry/scripts', q, limit, offset, undefined, signal)
export const listRegions = (q = '', limit = 20, offset = 0, signal?: AbortSignal) => listReference<Region>('/language-registry/regions', q, limit, offset, undefined, signal)

export async function listLanguageLocales(filters: LocaleFilters = {}, signal?: AbortSignal): Promise<Page<LanguageLocale>> {
  const { data } = await api.get('/language-locales', { params: { q: '', limit: 20, offset: 0, ...filters }, signal })
  return page<LanguageLocale>(data)
}

export async function getLanguageLocale(code: string, signal?: AbortSignal): Promise<LanguageLocale> {
  const { data } = await api.get(`/language-locales/${encodeURIComponent(code)}`, { signal })
  return (data as { data: LanguageLocale }).data
}

export async function createLanguageLocale(input: CreateLanguageLocaleInput, signal?: AbortSignal): Promise<LanguageLocale> {
  const { data } = await api.post('/language-locales', input, { signal })
  return (data as { data: LanguageLocale }).data
}

export async function listContentLanguages(filters: ContentLanguagePageQuery = {}, signal?: AbortSignal): Promise<Page<ContentLanguage>> {
  const params: Record<string, string | number> = {
    q: filters.q ?? '',
    sort: filters.sort ?? 'count',
    limit: filters.limit ?? 20,
    offset: filters.offset ?? 0,
    ui_locale: filters.ui_locale ?? '',
  }
  if (filters.secondary_ui_locale) params.secondary_ui_locale = filters.secondary_ui_locale
  const { data } = await api.get('/languages', { params, signal })
  return page<ContentLanguage>(data)
}

export async function getLanguageDetail(code: string, hints: LocaleHints = {}, signal?: AbortSignal): Promise<LanguageDetail> {
  const { data } = await api.get(`/languages/${encodeURIComponent(code)}`, { params: hintParams(hints), signal })
  return (data as { data: LanguageDetail }).data
}

export async function listLanguageExpressions(code: string, filters: LanguageExpressionPageQuery = {}, signal?: AbortSignal): Promise<Page<LanguageExpressionSummary>> {
  const params: Record<string, string | number> = {
    q: filters.q ?? '',
    sort: filters.sort ?? 'hot',
    locale: filters.locale ?? '',
    limit: filters.limit ?? 20,
    offset: filters.offset ?? 0,
    ui_locale: filters.ui_locale ?? '',
  }
  if (filters.secondary_ui_locale) params.secondary_ui_locale = filters.secondary_ui_locale
  const { data } = await api.get(`/languages/${encodeURIComponent(code)}/expressions`, { params, signal })
  return page<LanguageExpressionSummary>(data)
}
