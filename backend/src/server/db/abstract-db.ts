// Type definitions for our data models
export interface Language {
  id: number
  code: string
  name: string
  native_name?: string
  direction?: string
  is_active?: boolean
  region_name?: string
  native_region_name?: string
  latitude?: string
  longitude?: string
  created_by?: number
  created_at?: string
  updated_at?: string
}

export interface Meaning {
  id: number
  gloss?: string
  description?: string
  tags?: string
  created_by?: number
  created_at?: string
}

export interface Expression {
  id: number
  language: string
  region_name?: string
  region_latitude?: string
  region_longitude?: string
  country_code?: string
  country_name?: string
  text: string
  source_type?: string
  source_ref?: string
  audio_url?: string
  created_by?: number
  created_at?: string
  review_status?: string
  auto_approved?: boolean
  tags?: string
}

export interface ExpressionVersion {
  id: number
  expression_id?: number
  language: string
  region_name?: string
  region_latitude?: string
  region_longitude?: string
  country_code?: string
  country_name?: string
  text: string
  source_type?: string
  created_by?: number
  created_at?: string
  review_status?: string
  auto_approved?: boolean
  parent_version_id?: number
}

export interface ExpressionMeaning {
  id: number
  expression_id: number
  meaning_id: number
  created_by?: number
  created_at?: string
  note?: string
  parent_version_id?: number
}

export interface User {
  id: number
  username: string
  role?: string
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
  abstract getExpressions(skip?: number, limit?: number, language?: string): Promise<Expression[]>
  abstract getExpressionById(id: number): Promise<Expression | null>
  abstract createExpression(expression: Partial<Expression>): Promise<Expression>
  abstract updateExpression(id: number, expression: Partial<Expression>): Promise<Expression>
  abstract deleteExpression(id: number): Promise<boolean>
  abstract searchExpressions(query: string, fromLang?: string, region?: string, skip?: number, limit?: number): Promise<Expression[]>

  // Expression version operations
  abstract getExpressionVersions(expressionId: number): Promise<ExpressionVersion[]>
  abstract createExpressionVersion(version: Partial<ExpressionVersion>): Promise<ExpressionVersion>

  // Meaning operations
  abstract getMeanings(skip?: number, limit?: number): Promise<Meaning[]>
  abstract getMeaningById(id: number): Promise<Meaning | null>
  abstract createMeaning(meaning: Partial<Meaning>): Promise<Meaning>
  abstract updateMeaning(id: number, meaning: Partial<Meaning>): Promise<Meaning>
  abstract deleteMeaning(id: number): Promise<boolean>
  abstract getMeaningMembers(meaningId: number, limit?: number): Promise<Expression[]>

  // Expression-Meaning operations
  abstract linkExpressionAndMeaning(expressionId: number, meaningId: number, note?: string): Promise<ExpressionMeaning>
  abstract getExpressionMeanings(expressionId: number): Promise<Meaning[]>
  
  // UI translations
  abstract getUITranslations(language: string, skip?: number, limit?: number): Promise<any[]>

  // Users
  abstract getUserByUsername(username: string): Promise<User | null>
}