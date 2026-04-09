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
  group_name?: string
  created_by?: string
  created_at?: string
  updated_by?: string
  updated_at?: string
}

export interface Expression {
  id: number
  text: string
  desc?: string | null
  audio_url?: string | null
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

export interface Meaning {
  id: number
  text: string
  language_code: string
  created_by?: string
  created_at?: string
}

export interface ExpressionMeaning {
  id: string
  expression_id: number
  meaning_id: number
  created_at?: string
}

export interface ExpressionGroup {
  id: number
  expressions: Expression[]
  created_by?: string
  created_at?: string
}

export interface ExpressionVersion {
  id: number
  expression_id: number
  text: string
  desc?: string | null
  meaning_id?: number // @deprecated 使用 expression_meaning 表建立关联，此字段已废弃
  audio_url?: string | null
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
  is_public: number
  created_at: string
  updated_at?: string
  items_count?: number
}

export interface CollectionItem {
  id: number
  collection_id: number
  expression_id: number
  note?: string
  created_at: string
}

export interface Handbook {
  id: number
  user_id: number
  title: string
  description?: string
  content: string
  source_lang?: string
  target_lang?: string
  is_public: number
  created_at: string
  updated_at: string
  renders?: string
  lang_colors?: string
  created_by?: string
  author?: string
  published_at?: string
  has_pages?: number
}

export interface HandbookPage {
  id: number
  handbook_id: number
  title: string
  content: string
  sort_order: number
  created_at: string
  updated_at: string
  renders?: string
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

// UI Locale interface
export interface UILocale {
  id: number
  language_code: string
  locale_json: string
  created_by?: string
  created_at?: string
  updated_by?: string
  updated_at?: string
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
  abstract getExpressions(skip?: number, limit?: number, languages?: string[], tagPrefix?: string, excludeTagPrefix?: string): Promise<Expression[]>
  abstract getExpressionById(id: number): Promise<Expression | null>
  abstract getExpressionsByIds(ids: number[]): Promise<Expression[]>
  abstract getExpressionsGroups(expressionIds: number[], languages?: string[]): Promise<Map<number, ExpressionGroup[]>>
  abstract createExpression(expression: Partial<Expression>): Promise<Expression>
  abstract ensureExpressionsExist(expressions: Array<{ text: string, language_code: string }>, username: string): Promise<Record<string, number>>
  abstract upsertExpressions(expressions: Partial<Expression>[], forceNewMeaning?: boolean, targetMeaningId?: number): Promise<Array<{ id: number, expression?: Expression, error?: string }>>
  abstract updateExpression(id: number, expression: Partial<Expression>): Promise<Expression>
  abstract deleteExpression(id: number): Promise<boolean>
  abstract migrateExpressionId(oldId: number, newExpression: Partial<Expression>): Promise<Expression>
  abstract selectSemanticAnchor(expressionIds: number[]): Promise<number | null>
  abstract searchExpressions(query: string, fromLang?: string, region?: string, skip?: number, limit?: number): Promise<Expression[]>

  // Meaning operations
  abstract getMeaningsByExpressionId(expressionId: number): Promise<Meaning[]>
  abstract getExpressionMeaningIds(expressionIds: number[]): Promise<Map<number, number[]>>
  abstract addExpressionMeaning(expressionId: number, meaningId: number, username: string): Promise<void>
  abstract removeExpressionMeaning(expressionId: number, meaningId: number): Promise<boolean>

  // ExpressionGroup operations
  abstract getGroupExpressions(groupId: number, languages?: string[]): Promise<Expression[]>
  abstract getGroupInfo(groupId: number, languages?: string[]): Promise<ExpressionGroup | null>
  abstract getExpressionGroups(expressionId: number, languages?: string[]): Promise<ExpressionGroup[]>
  abstract addToGroup(expressionId: number, groupId: number, username: string): Promise<boolean>
  abstract removeFromGroup(expressionId: number, groupId: number): Promise<boolean>
  abstract createGroup(anchorExpressionId: number, username: string): Promise<number>
  abstract batchAddToGroup(expressionIds: number[], groupId: number, username: string): Promise<number>
  abstract mergeGroups(sourceGroupId: number, targetGroupId: number): Promise<{ success: boolean, merged_count: number }>
  abstract deleteGroup(groupId: number): Promise<boolean>
  abstract listGroups(skip?: number, limit?: number, languages?: string[]): Promise<ExpressionGroup[]>
  abstract searchGroups(query: string, skip?: number, limit?: number, languages?: string[]): Promise<ExpressionGroup[]>

  // Expression version operations
  abstract getExpressionVersions(expressionId: number): Promise<ExpressionVersion[]>
  abstract createExpressionVersion(version: Partial<ExpressionVersion>): Promise<ExpressionVersion>

  // UI locales (NEW - replaces UI translations)
  abstract getUILocale(languageCode: string): Promise<UILocale | null>
  abstract saveUILocale(languageCode: string, localeJson: string, username: string): Promise<UILocale>
  abstract deleteUILocale(languageCode: string): Promise<boolean>


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

  // Handbooks
  abstract getHandbooks(userId?: number, isPublic?: boolean, skip?: number, limit?: number): Promise<Handbook[]>
  abstract getHandbookById(id: number): Promise<Handbook | null>
  abstract createHandbook(handbook: Partial<Handbook>): Promise<Handbook>
  abstract updateHandbook(id: number, handbook: Partial<Handbook>): Promise<Handbook>
  abstract deleteHandbook(id: number): Promise<boolean>

  // Handbook Renders
  abstract getHandbookRender(id: number, targetLang: string): Promise<any | null>
  abstract saveHandbookRender(renderData: {
    handbook_id: number;
    target_lang: string;
    rendered_title: string;
    rendered_description?: string;
    rendered_content: string;
  }): Promise<void>
  abstract invalidateHandbookRenders(id: number): Promise<void>

  // Handbook Pages
  abstract getHandbookPages(handbookId: number): Promise<HandbookPage[]>
  abstract getHandbookPageById(id: number): Promise<HandbookPage | null>
  abstract getHandbookPageSummaries(handbookId: number): Promise<Array<{ id: number; title: string; sort_order: number }>>
  abstract createHandbookPage(page: Partial<HandbookPage>): Promise<HandbookPage>
  abstract updateHandbookPage(id: number, page: Partial<HandbookPage>): Promise<HandbookPage>
  abstract deleteHandbookPage(id: number): Promise<boolean>
  abstract reorderHandbookPages(pages: Array<{ id: number; sort_order: number }>): Promise<void>

  // Handbook Page Renders
  abstract getHandbookPageRender(id: number, targetLang: string): Promise<any | null>
  abstract saveHandbookPageRender(renderData: {
    page_id: number;
    target_lang: string;
    rendered_title: string;
    rendered_content: string;
  }): Promise<void>
  abstract invalidateHandbookPageRenders(id: number): Promise<void>

  abstract stableExpressionId(text: string, language_code: string): number
  abstract formatTimestamps<T extends Record<string, any>>(obj: T): T

  // Query objects for direct access
  abstract get expressions(): any
  abstract get users(): any
  abstract get collections(): any
  abstract get meanings(): any
  abstract get languages(): any
  abstract get handbooks(): any
  abstract get groups(): any
}
