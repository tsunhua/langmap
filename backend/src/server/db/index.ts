// Database integration for Hono with Cloudflare D1

import { D1DatabaseService } from './d1'
import { AbstractDatabaseService } from './protocol'

let databaseService: AbstractDatabaseService | null = null

export function createDatabaseService(env: any): AbstractDatabaseService {
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

// Import and export all types from abstract-db to avoid duplication
export type { Language, Expression, ExpressionVersion, User } from './protocol'
export { AbstractDatabaseService } from './protocol'
