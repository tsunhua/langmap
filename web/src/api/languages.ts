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

interface RegistrySubtagResponse {
  type: RegistrySubtag['type']
  value: string
  descriptions: string | string[]
  prefixes: string | string[]
  preferred_value: string | null
  suppress_script: string | null
  deprecated: string | null
}

export interface Variety {
  id: string
  code: string
  name: string
  name_en: string | null
  description: string
  glottocode: string | null
  origin: 'seed' | 'glottolog' | 'community' | 'system'
  community_reason: string | null
  alternate_names: string[]
  references: string[]
  parent_languoid_id: string | null
  profile_count?: number
  expression_count?: number
}

export interface LanguageProfile {
  code: string
  language_variety_id: string
  language_variety_code: string
  name: string
  name_en: string | null
  direction: 'ltr' | 'rtl'
  base_language: string
  script_code: string | null
  region_code: string | null
  variants: string[]
  private_use: string[]
}

export interface RepresentativeCity {
  city_name: string
  city_name_en: string | null
  territory_code: string
  script_code: string
  latitude: number
  longitude: number
  reference: string
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
  profiles: LanguageProfile[]
}

export interface VarietyPreview {
  canonical_profile_code: string
  direction: 'ltr' | 'rtl'
  warnings: string[]
  existing_variety: Variety | null
  existing_profile: LanguageProfile | null
  profiles_of_variety: LanguageProfile[]
  similar_varieties: Variety[]
  required_metadata: string[]
}

export interface CreateVarietyPayload {
  subtags: LanguageSubtags
  glottocode: string | null
  variety: {
    name: string
    name_en: string | null
    description: string
    reason: 'missing_from_glottolog' | 'community_specific' | 'emerging_variety' | 'other' | null
    alternate_names: string[]
    references: string[]
    parent_languoid_id: string | null
  }
  profile: {
    name?: string
    name_en?: string | null
  }
}

export interface CreatedVarietyResult {
  variety: Variety
  profile: LanguageProfile
}

export async function listRegistryLanguages(search = '', signal?: AbortSignal): Promise<Variety[]> {
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
  const items = (data.data?.items ?? []) as RegistrySubtagResponse[]
  return items.map(item => ({
    type: item.type,
    subtag: item.value,
    descriptions: parseStringArray(item.descriptions),
    prefixes: parseStringArray(item.prefixes),
    preferred_value: item.preferred_value,
    suppress_script: item.suppress_script,
    deprecated_at: item.deprecated,
  }))
}

function parseStringArray(value: string | string[]): string[] {
  if (Array.isArray(value)) return value
  try {
    const parsed: unknown = JSON.parse(value)
    return Array.isArray(parsed) && parsed.every(item => typeof item === 'string') ? parsed : []
  } catch {
    return []
  }
}

export async function searchLanguoids(query: string, signal?: AbortSignal): Promise<LanguoidCandidate[]> {
  const { data } = await api.get('/languoids', {
    params: { q: query, matchable: '1' },
    signal,
  })
  return data.data?.items ?? []
}

export async function previewVariety(payload: CreateVarietyPayload, signal?: AbortSignal): Promise<VarietyPreview> {
  const { data } = await api.post('/languages/preview', payload, { signal })
  return data.data
}

export async function createVariety(payload: CreateVarietyPayload, signal?: AbortSignal): Promise<CreatedVarietyResult> {
  const { data } = await api.post('/languages', payload, { signal })
  return data.data
}
