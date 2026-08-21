import api from './client'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'
import type { LocaleHints } from './languageIdentity'

export interface ExpressionSource { type: string; name: string; ref?: string }
export interface LocaleAttestation { id: string; expression_id: string; language_locale_code: string; locale_display_name?: string; created_by_username?: string | null; source_id: string | null; source_ref: string | null; created_at: string }
export interface ExpressionReading extends LocaleAttestation { scheme: string; value: string }
export interface ExpressionDetail {
  expression: { id: string; lang_code: string; text: string; source_type: string | null; source_name: string | null; language_name?: string | null; created_by_username?: string | null }
  attestations: LocaleAttestation[]
  readings: ExpressionReading[]
}
export interface ExpressionEdge { edge_id: string; neighbor_id: string; neighbor_lang_code: string; neighbor_text: string; score: number; source: string; created_at: string }
export interface SearchFormOf {
  lemma: { id: string; text: string; lang_code: string }
  features: Array<{ code: string; name: string }>
}
export interface SearchHit {
  id: string
  text: string
  lang_code: string
  language_profile_code?: string
  language_name?: string
  mapping_count?: number
  source_type?: string
  region_name?: string
  form_of?: SearchFormOf[]
}
export interface Page<T> { items: T[]; total: number; skip: number; limit: number; hasMore: boolean }

const path = (id: string) => `/expressions/${encodeURIComponent(id)}`
const unwrap = <T>(result: { data: { data: T } }) => result.data.data

function hintParams(hints?: LocaleHints): { ui_locale?: string; secondary_ui_locale?: string } {
  const params: { ui_locale?: string; secondary_ui_locale?: string } = {}
  if (hints?.ui_locale) params.ui_locale = hints.ui_locale
  if (hints?.secondary_ui_locale) params.secondary_ui_locale = hints.secondary_ui_locale
  return params
}

export async function getExpression(id: string, hints?: LocaleHints, signal?: AbortSignal): Promise<ExpressionDetail> {
  const params = hintParams(hints)
  const config = Object.keys(params).length ? { params, signal } : { signal }
  return unwrap<ExpressionDetail>(await api.get(path(id), config))
}
export async function getMappingGraph(id: string, hops: 1 | 2 | 3 = 1, hints?: LocaleHints, signal?: AbortSignal): Promise<MappingGraphResponse> {
  return unwrap<MappingGraphResponse>(await api.get(`${path(id)}/mappings`, { params: { hops, ...hintParams(hints) }, signal }))
}
export async function getExpressionEdges(id: string, limit = 50, offset = 0, signal?: AbortSignal): Promise<Page<ExpressionEdge>> {
  return unwrap<Page<ExpressionEdge>>(await api.get(`${path(id)}/edges`, { params: { limit, offset }, signal }))
}
export async function createExpression(input: { lang_code: string; text: string; language_locale_code?: string }, signal?: AbortSignal) {
  return unwrap(await api.post('/expressions', input, { signal }))
}
export async function createLocaleAttestation(id: string, input: { language_locale_code: string; source?: ExpressionSource }, signal?: AbortSignal) {
  return unwrap(await api.post(`${path(id)}/locale-attestations`, input, { signal }))
}
export async function createReading(id: string, input: { language_locale_code: string; scheme: string; value: string; source?: ExpressionSource }, signal?: AbortSignal) {
  return unwrap(await api.post(`${path(id)}/readings`, input, { signal }))
}
export async function splitExpression(id: string, edgeIds: string[], signal?: AbortSignal): Promise<{ target_expression_id: string }> {
  return unwrap(await api.post(`${path(id)}/split`, { edge_ids: edgeIds }, { signal }))
}
