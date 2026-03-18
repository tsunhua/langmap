export interface JWTPayload {
  id: number
  username: string
  email: string
  role: string
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
