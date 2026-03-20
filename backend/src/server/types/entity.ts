export interface Expression {
  id: number
  text: string
  language_code: string
  meaning_id?: number
  audio_url?: string
  created_by: string
  created_at: string
  updated_at?: string
  updated_by?: string
}

export interface Language {
  id: number
  code: string
  name: string
  native_name?: string
  is_active: number
  created_by?: string
  created_at: string
  updated_at?: string
  updated_by?: string
}

export interface Collection {
  id: number
  user_id: number
  name: string
  description?: string
  is_public: number
  created_at: string
  updated_at?: string
}

export interface CollectionItem {
  id: number
  collection_id: number
  expression_id: number
  created_at: string
}
