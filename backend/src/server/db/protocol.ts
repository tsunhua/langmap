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
  email_verified?: number
  created_at?: string
  updated_at?: string
}

export interface Collection {
  id: number
  user_id: number
  name: string
  description?: string
  is_public: boolean
  created_at: number
  updated_at: number
  items_count?: number
}

export interface CollectionItem {
  id: number
  collection_id: number
  expression_id: number
  note?: string
  created_at: number
}

// Statistics interface
export interface Statistics {
  total_expressions: number
  total_languages: number
  total_regions: number
}

// Heatmap data interface
export interface HeatmapData {
  language_code: string
  language_name: string
  region_code: string | null
  region_name: string | null
  count: number
  latitude: string | null
  longitude: string | null
}

// Abstract database service class
export abstract class AbstractDatabaseService {
  // Language operations
  abstract getLanguages(isActive?: number): Promise<Language[]>
  abstract getLanguageByCode(code: string): Promise<Language | null>
  abstract createLanguage(language: Partial<Language>): Promise<Language>
  abstract updateLanguage(id: number, language: Partial<Language>): Promise<Language>
  abstract deleteLanguage(id: number): Promise<boolean>

  // Expression operations
  abstract getExpressions(skip?: number, limit?: number, language?: string, meaningId?: number | number[], tagPrefix?: string, excludeTagPrefix?: string): Promise<Expression[]>
  abstract getExpressionById(id: number): Promise<Expression | null>
  abstract getExpressionsByIds(ids: number[]): Promise<Expression[]>
  abstract createExpression(expression: Partial<Expression>): Promise<Expression>
  abstract upsertExpressions(expressions: Partial<Expression>[]): Promise<Array<{ id: number, expression?: Expression, error?: string }>>
  abstract updateExpression(id: number, expression: Partial<Expression>): Promise<Expression>
  abstract deleteExpression(id: number): Promise<boolean>
  abstract migrateExpressionId(oldId: number, newExpression: Partial<Expression>): Promise<Expression>
  abstract searchExpressions(query: string, fromLang?: string, region?: string, skip?: number, limit?: number): Promise<Expression[]>

  // Expression version operations
  abstract getExpressionVersions(expressionId: number): Promise<ExpressionVersion[]>
  abstract createExpressionVersion(version: Partial<ExpressionVersion>): Promise<ExpressionVersion>

  // UI translations
  abstract getUITranslations(language: string, skip?: number, limit?: number): Promise<any[]>
  abstract saveUITranslation(language: string, key: string, text: string, username: string, meaningId?: number): Promise<void>
  abstract saveUITranslations(language: string, translations: Array<{ key: string, text: string, meaning_id?: number }>, username: string): Promise<Array<{ key: string, error?: string }>>
  abstract syncLocalesToDatabase(localeData: Record<string, any>, username: string): Promise<Record<string, { added: number, skipped: number, errors: string[] }>>
  abstract calculateUITranslationCompletion(languageCode: string): Promise<number>


  // Users
  abstract getUserByUsername(username: string): Promise<User | null>
  abstract getUserByEmail(email: string): Promise<User | null>
  abstract getUserById(id: number): Promise<User | null>
  abstract createUser(user: Partial<User>): Promise<User>

  // Email verification
  abstract createEmailVerificationToken(token: string, userId: number, expiresAt: string): Promise<void>
  abstract getEmailVerificationToken(token: string): Promise<{ user_id: number, expires_at: string } | null>
  abstract deleteEmailVerificationToken(token: string): Promise<void>
  abstract setEmailVerified(userId: number): Promise<void>

  // Statistics
  abstract getStatistics(): Promise<Statistics>
  abstract clearStatisticsCache(): void

  // Heatmap
  abstract getHeatmapData(): Promise<HeatmapData[]>
  abstract clearHeatmapCache(): void

  // Collections
  abstract getCollections(userId?: number, isPublic?: boolean, skip?: number, limit?: number): Promise<Collection[]>
  abstract getCollectionById(id: number): Promise<Collection | null>
  abstract createCollection(collection: Partial<Collection>): Promise<Collection>
  abstract updateCollection(id: number, collection: Partial<Collection>): Promise<Collection>
  abstract deleteCollection(id: number): Promise<boolean>
  abstract getCollectionsContainingItem(userId: number, expressionId: number): Promise<number[]>

  // Collection Items
  abstract getCollectionItems(collectionId: number, skip?: number, limit?: number): Promise<CollectionItem[]>
  abstract addCollectionItem(item: Partial<CollectionItem>): Promise<CollectionItem>
  abstract removeCollectionItem(collectionId: number, expressionId: number): Promise<boolean>
  abstract getCollectionItem(collectionId: number, expressionId: number): Promise<CollectionItem | null>
  abstract stableExpressionId(text: string, languageCode: string): number
}
