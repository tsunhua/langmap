import api from './client'

export interface LanguageSubtags {
  language: string
  script: string | null
  region: string | null
  variants: string[]
  private_use: string[]
}

export interface RegistrySubtag {
  type: 'language' | 'script' | 'region' | 'variant'
  subtag: string
  descriptions: string[]
  prefixes: string[]
  preferred_value: string | null
  suppress_script: string | null
  deprecated_at: string | null
}

export interface RegistryLanguage {
  code: string
  name: string
  name_en: string | null
  description: string
  direction: 'ltr' | 'rtl'
  base_language: string
  script_code: string | null
  region_code: string | null
  variants: string[]
  private_use: string[]
  variety_key: string
  glottocode: string | null
  origin: 'seed' | 'glottolog' | 'community' | 'system'
  expression_count?: number
}

export interface LanguoidCandidate {
  id: string
  glottocode: string
  preferred_name: string
  level: 'language' | 'dialect'
  iso639_3: string | null
  parent_id: string | null
  parent_name: string | null
  source_version: string
  profiles: RegistryLanguage[]
}

export interface LanguagePreview {
  canonical_code: string
  direction: 'ltr' | 'rtl'
  warnings: string[]
  existing_language: RegistryLanguage | null
  profiles: RegistryLanguage[]
  similar: RegistryLanguage[]
  required_metadata: string[]
}

export interface CreateLanguagePayload {
  subtags: LanguageSubtags
  glottocode: string | null
  language: {
    name: string
    name_en: string | null
    description: string
    reason: 'missing_from_glottolog' | 'community_specific' | 'emerging_variety' | 'other' | null
    alternate_names: string[]
    references: string[]
    parent_languoid_id: string | null
    latitude: number | null
    longitude: number | null
  }
}

export type CreatedLanguage = RegistryLanguage

export async function listRegistryLanguages(search = '', signal?: AbortSignal): Promise<RegistryLanguage[]> {
  const { data } = await api.get('/languages', {
    params: { q: search, sort: 'alpha', limit: 100 },
    signal,
  })
  return data.data?.items ?? []
}

export async function listLanguageSubtags(
  type: string,
  query: string,
  prefix?: string,
  signal?: AbortSignal,
): Promise<RegistrySubtag[]> {
  const params: Record<string, string> = { type, q: query }
  if (prefix) params.prefix = prefix
  const { data } = await api.get('/language-registry/subtags', { params, signal })
  return data.data?.items ?? []
}

export async function searchLanguoids(query: string, signal?: AbortSignal): Promise<LanguoidCandidate[]> {
  const { data } = await api.get('/languoids', {
    params: { q: query },
    signal,
  })
  return data.data?.items ?? []
}

export async function previewLanguage(payload: CreateLanguagePayload, signal?: AbortSignal): Promise<LanguagePreview> {
  const { data } = await api.post('/languages/preview', payload, { signal })
  return data.data
}

export async function createLanguage(payload: CreateLanguagePayload, signal?: AbortSignal): Promise<CreatedLanguage> {
  const { data } = await api.post('/languages', payload, { signal })
  return data.data
}
