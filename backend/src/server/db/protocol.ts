// Type definitions for our data models
export interface Language {
  id: number
  code: string
  name: string
  direction?: string
  is_active?: boolean
  region_code?: string
  region_name?: string
  region_latitude?: string
  region_longitude?: string
  created_by?: string
  created_at?: string
  updated_by?: string
  updated_at?: string
}

export interface Expression {
  id: number
  text: string
  meaning_id?: number
  audio_url?: string
  language_code: string
  region_code?: string
  region_name?: string
  region_latitude?: string
  region_longitude?: string
  tags?: string
  source_type?: string
  source_ref?: string
  review_status?: string
  created_by?: string
  created_at?: string
  updated_by?: string
  updated_at?: string
}

export interface ExpressionVersion {
  id: number
  expression_id: number
  text: string
  meaning_id?: number
  audio_url?: string
  region_name?: string
  region_latitude?: string
  region_longitude?: string
  created_by?: string
  created_at?: string
}

export interface User {
  id: number
  username: string
  email: string
  password_hash: string
  role: string
  created_at?: string
  updated_at?: string
}

// Statistics interface
export interface Statistics {
  total_expressions: number
  total_languages: number
  total_regions: number
}

// Abstract database service class
export abstract class AbstractDatabaseService {
  // Language operations
  abstract getLanguages(): Promise<Language[]>
  abstract getLanguageByCode(code: string): Promise<Language | null>
  abstract createLanguage(language: Partial<Language>): Promise<Language>
  abstract updateLanguage(id: number, language: Partial<Language>): Promise<Language>
  abstract deleteLanguage(id: number): Promise<boolean>

  // Expression operations
  abstract getExpressions(skip?: number, limit?: number, language?: string, meaningId?: number | number[]): Promise<Expression[]>
  abstract getExpressionById(id: number): Promise<Expression | null>
  abstract createExpression(expression: Partial<Expression>): Promise<Expression>
  abstract updateExpression(id: number, expression: Partial<Expression>): Promise<Expression>
  abstract deleteExpression(id: number): Promise<boolean>
  abstract searchExpressions(query: string, fromLang?: string, region?: string, skip?: number, limit?: number): Promise<Expression[]>

  // Expression version operations
  abstract getExpressionVersions(expressionId: number): Promise<ExpressionVersion[]>
  abstract createExpressionVersion(version: Partial<ExpressionVersion>): Promise<ExpressionVersion>

  // UI translations
  abstract getUITranslations(language: string, skip?: number, limit?: number): Promise<any[]>

  // Users
  abstract getUserByUsername(username: string): Promise<User | null>
  abstract getUserByEmail(email: string): Promise<User | null>
  abstract getUserById(id: number): Promise<User | null>
  abstract createUser(user: Partial<User>): Promise<User>
  
  // Statistics
  abstract getStatistics(): Promise<Statistics>
  abstract clearStatisticsCache(): void
}