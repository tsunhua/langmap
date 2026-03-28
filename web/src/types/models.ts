export interface ExpressionGroup {
  id: number
  expressions: Expression[]
  created_by?: string
  created_at?: string
}

export interface Expression {
  id: number
  text: string
  desc?: string | null
  language_code: string
  audio_url?: string
  created_by: string
  created_at: string
  updated_at?: string
  updated_by?: string
  groups?: ExpressionGroup[]
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

export interface User {
  id: number
  username: string
  email: string
  role: string
  email_verified: number
  created_at: string
  updated_at?: string
}

export interface Meaning {
  id: number
  text?: string
  created_at: string
}

export interface AudioRecord {
  url: string
  speaker: string
}
