import api from './client'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'
import type { LocaleHints } from './languageIdentity'
import { contentRevision } from '@/utils/contentRevision'
import { encodeExpressionTextWithHomograph } from '@/utils/expressionUrl'

export interface ExpressionSource { type: string; name: string; ref?: string }
export interface ExpressionLocale { language_locale_code: string; locale_display_name?: string }
export interface LocaleAttestation extends ExpressionLocale { id?: string; expression_id?: string; created_by_username?: string | null; source_id?: string | null; source_ref?: string | null; created_at?: string }
export interface ExpressionReading extends ExpressionLocale { scheme: string; value: string; source_id?: string | null }
export interface ExpressionDetail {
  expression: { id: string; lang_code: string; text: string; homograph_index: number; source_type: string | null; source_name: string | null; language_name?: string | null; created_by_username?: string | null }
  locales: ExpressionLocale[]
  /** Compatibility alias for callers written before locale links were renamed. */
  attestations: ExpressionLocale[]
  readings: ExpressionReading[]
}
export interface ExpressionEdge { edge_id: string; neighbor_id: string; neighbor_lang_code: string; neighbor_text: string; relation_mask?: number; score?: number; source?: string; created_at?: string }
export interface SearchFormOf {
  lemma: { id: string; text: string; lang_code: string; homograph_index?: number }
  features: Array<{ code: string; name: string }>
}
export interface SearchHit {
  id: string
  text: string
  lang_code: string
  homograph_index?: number
  language_profile_code?: string
  language_name?: string
  mapping_count?: number
  source_type?: string
  region_name?: string
  form_of?: SearchFormOf[]
}
export interface CursorPage<T> { items: T[]; next_cursor: string | null; has_more: boolean }
export type Page<T> = CursorPage<T>

/** Stable natural key for addressing an expression; numeric ids remain accepted for legacy callers. */
export interface ExpressionKeyInput { lang_code: string; text: string; homograph_index?: number }
export type ExpressionTarget = ExpressionKeyInput | string | number

export const targetPath = (target: ExpressionTarget) =>
  typeof target === 'object' && target !== null
    ? `/expressions/${encodeURIComponent(target.lang_code)}/${encodeExpressionTextWithHomograph(target.text, target.homograph_index ?? 1)}`
    : `/expressions/${encodeURIComponent(String(target))}`
const unwrap = <T>(result: { data: { data: T } }) => result.data.data

function hintParams(hints?: LocaleHints): Record<string, string | number> {
  const params: Record<string, string | number> = { _content_revision: contentRevision.value }
  if (hints?.ui_locale) params.ui_locale = hints.ui_locale
  if (hints?.secondary_ui_locale) params.secondary_ui_locale = hints.secondary_ui_locale
  return params
}

export async function getExpression(target: ExpressionTarget, hints?: LocaleHints, signal?: AbortSignal): Promise<ExpressionDetail> {
  const params = hintParams(hints)
  const detail = unwrap<Omit<ExpressionDetail, 'attestations'>>(await api.get(targetPath(target), { params, signal }))
  return { ...detail, attestations: detail.locales }
}
export async function getMappingGraph(target: ExpressionTarget, hops: 1 | 2 | 3 = 1, hints?: LocaleHints, targetLanguage?: string, signal?: AbortSignal): Promise<MappingGraphResponse> {
  return unwrap<MappingGraphResponse>(await api.get(`${targetPath(target)}/graph`, { params: { hops, ...(targetLanguage ? { target_language: targetLanguage } : {}), ...hintParams(hints) }, signal }))
}
export async function getExpressionEdges(target: ExpressionTarget, limit = 50, cursor?: string | number, signal?: AbortSignal): Promise<CursorPage<ExpressionEdge>> {
  return unwrap<CursorPage<ExpressionEdge>>(await api.get(`${targetPath(target)}/edges`, { params: { limit, ...(cursor ? { cursor } : {}) }, signal }))
}
export async function createExpression(input: { lang_code: string; text: string; language_locale_code?: string }, signal?: AbortSignal): Promise<{ expression: { id: string; lang_code: string; text: string; homograph_index: number }; created: boolean }> {
  return unwrap(await api.post('/expressions', input, { signal }))
}
export async function putExpressionLocale(target: ExpressionTarget, localeCode: string, signal?: AbortSignal): Promise<ExpressionLocale> {
  return unwrap(await api.put(`${targetPath(target)}/locales/${encodeURIComponent(localeCode)}`, {}, { signal }))
}
export async function deleteExpressionLocale(target: ExpressionTarget, localeCode: string, signal?: AbortSignal): Promise<void> {
  await api.delete(`${targetPath(target)}/locales/${encodeURIComponent(localeCode)}`, { signal })
}
export async function createLocaleAttestation(target: ExpressionTarget, input: { language_locale_code: string; source?: ExpressionSource }, signal?: AbortSignal) {
  return putExpressionLocale(target, input.language_locale_code, signal)
}
export async function createReading(target: ExpressionTarget, input: { language_locale_code: string; scheme: string; value: string; source?: ExpressionSource }, signal?: AbortSignal) {
  return unwrap(await api.post(`${targetPath(target)}/readings`, input, { signal }))
}
export async function splitExpression(target: ExpressionTarget, edgeIds: string[], signal?: AbortSignal): Promise<{ target_expression_id: string; target: { lang_code: string; text: string; homograph_index: number } }> {
  return unwrap(await api.post(`${targetPath(target)}/split`, { edge_ids: edgeIds }, { signal }))
}
