import api from './client'

export interface Page<T> { items: T[]; next_cursor?: string | null; has_more?: boolean; total?: number; skip?: number; limit?: number; hasMore?: boolean }

export interface LocaleHints { ui_locale?: string; secondary_ui_locale?: string }

export interface Language { code: string; name_en: string; name?: string }
export interface Script { code: string; name_en: string; name?: string; direction: 'ltr' | 'rtl' }
export interface Region { code: string; name_en: string; name?: string; latitude: number | null; longitude: number | null }
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

export interface LocaleFilters { lang_code?: string; script_code?: string; region_code?: string; q?: string; limit?: number; offset?: number; cursor?: string; ui_locale?: string; secondary_ui_locale?: string }
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
  sort?: 'new' | 'alpha'
  limit?: number
  cursor?: string | number
  offset?: number
  /** UI locale the caller renders in; the API resolves `name` against it. */
  ui_locale?: string
  secondary_ui_locale?: string
}

export interface LanguageExpressionPageQuery {
  prefix?: string
  /** @deprecated use prefix. Kept for old callers during the cutover. */
  q?: string
  sort?: 'new' | 'alpha'
  locale?: string
  limit?: number
  cursor?: string | number
  /** @deprecated canonical API uses cursor. */
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
  description?: string
  homograph_index: number
  created_at: string
  reading_count: number
  mapping_count: number
  review_status?: string
}

function page<T>(data: unknown): Page<T> {
  const result = data as { data?: Partial<Page<T>> }
  return {
    items: result.data?.items ?? [], next_cursor: result.data?.next_cursor ?? null,
    has_more: result.data?.has_more ?? false,
  }
}

function hintParams(hints?: LocaleHints): { ui_locale?: string; secondary_ui_locale?: string } {
  const params: { ui_locale?: string; secondary_ui_locale?: string } = {}
  if (hints?.ui_locale) params.ui_locale = hints.ui_locale
  if (hints?.secondary_ui_locale) params.secondary_ui_locale = hints.secondary_ui_locale
  return params
}

async function listReference<T>(path: string, q = '', limit = 20, cursor: string | number = '', hints?: LocaleHints, signal?: AbortSignal): Promise<Page<T>> {
  const { data } = await api.get(path, { params: { q, limit, ...(cursor ? { cursor } : {}), ...hintParams(hints) }, signal })
  return page<T>(data)
}

export const listLanguages = (q = '', limit = 20, cursor: string | number = '', hints?: LocaleHints, signal?: AbortSignal) => listReference<Language>('/language-registry/languages', q, limit, cursor, hints, signal)
export const listScripts = (q = '', limit = 20, cursor: string | number = '', hints?: LocaleHints, signal?: AbortSignal) => listReference<Script>('/language-registry/scripts', q, limit, cursor, hints, signal)
export const listRegions = (q = '', limit = 20, cursor: string | number = '', hints?: LocaleHints, signal?: AbortSignal) => listReference<Region>('/language-registry/regions', q, limit, cursor, hints, signal)

export async function listLanguageLocales(filters: LocaleFilters = {}, signal?: AbortSignal): Promise<Page<LanguageLocale>> {
  const { cursor, offset: _offset, ...rest } = filters
  const { data } = await api.get('/language-locales', { params: { q: '', limit: 20, ...rest, ...(cursor ? { cursor } : {}) }, signal })
  return page<LanguageLocale>(data)
}

export async function getLanguageLocale(code: string | number, signal?: AbortSignal): Promise<LanguageLocale> {
  const { data } = await api.get(`/language-locales/${encodeURIComponent(String(code))}`, { signal })
  return (data as { data: LanguageLocale }).data
}

export async function createLanguageLocale(input: CreateLanguageLocaleInput, signal?: AbortSignal): Promise<LanguageLocale> {
  const { data } = await api.post('/language-locales', input, { signal })
  return (data as { data: LanguageLocale }).data
}

export async function listContentLanguages(filters: ContentLanguagePageQuery = {}, signal?: AbortSignal): Promise<Page<ContentLanguage>> {
  const params: Record<string, string | number> = {
    q: filters.q ?? '',
    sort: filters.sort ?? 'alpha',
    limit: filters.limit ?? 20,
    ...(filters.cursor ? { cursor: filters.cursor } : {}),
    ui_locale: filters.ui_locale ?? '',
  }
  if (filters.secondary_ui_locale) params.secondary_ui_locale = filters.secondary_ui_locale
  const { data } = await api.get('/languages', { params, signal })
  return page<ContentLanguage>(data)
}

export async function getLanguageDetail(code: string | number, hints: LocaleHints = {}, locale = '', signal?: AbortSignal): Promise<LanguageDetail> {
  const params: Record<string, string> = { ...hintParams(hints) }
  if (locale) params.locale = locale
  const { data } = await api.get(`/languages/${encodeURIComponent(String(code))}`, { params, signal })
  return (data as { data: LanguageDetail }).data
}

export async function listLanguageExpressions(code: string | number, filters: LanguageExpressionPageQuery = {}, signal?: AbortSignal): Promise<Page<LanguageExpressionSummary>> {
  const params: Record<string, string | number> = {
    prefix: filters.prefix ?? filters.q ?? '',
    sort: filters.sort ?? 'alpha',
    locale: filters.locale ?? '',
    limit: filters.limit ?? 20,
    ...(filters.cursor ? { cursor: filters.cursor } : {}),
    ui_locale: filters.ui_locale ?? '',
  }
  if (filters.secondary_ui_locale) params.secondary_ui_locale = filters.secondary_ui_locale
  const { data } = await api.get(`/languages/${encodeURIComponent(String(code))}/expressions`, { params, signal })
  return page<LanguageExpressionSummary>(data)
}
