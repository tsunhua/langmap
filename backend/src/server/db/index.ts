// Database integration for Hono with Cloudflare D1

// Type definitions for our data models
export interface Language {
  id: number
  code: string
  name: string
  region_code?: string
  region_name?: string
  region_latitude?: number
  region_longitude?: number
  created_at: string
  updated_at: string
}

export interface Meaning {
  id: number
  gloss: string
  description?: string
  tags?: string
  created_at: string
  updated_at: string
}

export interface Expression {
  id: number
  text: string
  language_code: string
  region_code?: string
  region_name?: string
  region_latitude?: number
  region_longitude?: number
  source_type: string
  review_status: string
  auto_approved: boolean
  tags?: string
  created_at: string
  updated_at: string
}

export interface ExpressionVersion {
  id: number
  expression_id?: number
  note: string
  created_at: string
}

export interface ExpressionMeaning {
  id: number
  expression_id: number
  meaning_id: number
  note?: string
  created_at: string
  updated_at: string
}


import { D1DatabaseService } from './d1-db'

let databaseService: D1DatabaseService | null = null

export function createDatabaseService(env: any): D1DatabaseService {
  // Return cached instance if already created
  if (databaseService) {
    return databaseService
  }

  // Use D1 database (Cloudflare Workers)
  if (!env.DB) {
    throw new Error('D1 database binding not found in environment')
  }
  databaseService = new D1DatabaseService(env.DB)
  
  return databaseService
}

// Fix the export conflict by exporting only the DatabaseService and createDatabaseService
// and importing the types from abstract-db instead of redefining them
export { AbstractDatabaseService } from './abstract-db'
export type { Language as AbstractLanguage, Expression as AbstractExpression, 
              ExpressionVersion as AbstractExpressionVersion, Meaning as AbstractMeaning, 
              ExpressionMeaning as AbstractExpressionMeaning, User } from './abstract-db'