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

export interface LanguageRow {
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
}

export interface LanguagePreview {
  canonical_code: string
  direction: 'ltr' | 'rtl'
  warnings: string[]
  existing_language: LanguageRow | null
  profiles: LanguageRow[]
  similar: LanguageRow[]
  required_metadata: string[]
}
