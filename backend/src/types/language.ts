export interface LanguageSubtags {
  language: string
  script: string | null
  region: string | null
  variants: string[]
  private_use: string[]
}

export interface CanonicalLanguageTag extends LanguageSubtags {
  code: string
}

export type VarietyOrigin = 'seed' | 'glottolog' | 'community' | 'system'

export interface VarietyRow {
  id: string
  code: string
  name: string
  name_en: string | null
  description: string
  glottocode: string | null
  origin: VarietyOrigin
  community_reason: string | null
  alternate_names: string[]
  references: string[]
  parent_languoid_id: string | null
}

export interface ProfileRow {
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

export interface VarietyPreview {
  canonical_profile_code: string
  direction: 'ltr' | 'rtl'
  warnings: string[]
  existing_variety: VarietyRow | null
  existing_profile: ProfileRow | null
  profiles_of_variety: ProfileRow[]
  similar_varieties: VarietyRow[]
  required_metadata: string[]
}
