import api from './client'
import type { LocaleHints } from './languageIdentity'

export interface MorphologicalFeature {
  code: string
  name: string
  name_en: string
  sort_order: number
}

export interface MorphologicalDimension {
  code: string
  name: string
  name_en: string
  sort_order: number
  features: MorphologicalFeature[]
}

export interface MorphologicalFeaturesResponse {
  dimensions: MorphologicalDimension[]
}

export interface FormEdgeExpressionSummary {
  id: string
  text: string
  lang_code: string
  language_name: string
}

export interface FormEdgeFeature {
  code: string
  name: string
  dimension_code: string
}

export interface FormEdgeAsForm {
  edge_id: string
  lemma: FormEdgeExpressionSummary
  features: FormEdgeFeature[]
}

export interface FormEdgeAsLemma {
  edge_id: string
  form: FormEdgeExpressionSummary
  features: FormEdgeFeature[]
}

export interface ExpressionFormEdges {
  as_form: FormEdgeAsForm[]
  as_lemma: FormEdgeAsLemma[]
  as_form_truncated: boolean
  as_form_omitted_count: number
  as_lemma_truncated: boolean
  as_lemma_omitted_count: number
}

export interface CreateFormEdgeInput {
  lemma_expression_id: string
  features?: string[]
}

export interface CreateFormEdgeResult extends FormEdgeAsForm {
  created: boolean
}

const path = (id: string) => `/expressions/${encodeURIComponent(id)}`
const unwrap = <T>(result: { data: { data: T } }) => result.data.data

function hintParams(hints?: LocaleHints): { ui_locale?: string; secondary_ui_locale?: string } {
  const params: { ui_locale?: string; secondary_ui_locale?: string } = {}
  if (hints?.ui_locale) params.ui_locale = hints.ui_locale
  if (hints?.secondary_ui_locale) params.secondary_ui_locale = hints.secondary_ui_locale
  return params
}

export async function listMorphologicalFeatures(
  hints?: LocaleHints,
  signal?: AbortSignal,
): Promise<MorphologicalFeaturesResponse> {
  return unwrap<MorphologicalFeaturesResponse>(
    await api.get('/morphological-features', { params: hintParams(hints), signal }),
  )
}

export async function getExpressionFormEdges(
  id: string,
  options: { limit?: number } & LocaleHints = {},
  signal?: AbortSignal,
): Promise<ExpressionFormEdges> {
  const { limit = 50, ...hints } = options
  return unwrap<ExpressionFormEdges>(
    await api.get(`${path(id)}/form-edges`, { params: { limit, ...hintParams(hints) }, signal }),
  )
}

export async function createFormEdge(
  id: string,
  input: CreateFormEdgeInput,
  hints?: LocaleHints,
  signal?: AbortSignal,
): Promise<CreateFormEdgeResult> {
  return unwrap<CreateFormEdgeResult>(
    await api.post(`${path(id)}/form-edges`, input, { params: hintParams(hints), signal }),
  )
}
