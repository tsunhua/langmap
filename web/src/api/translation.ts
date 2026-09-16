// Types mirror backend/src/services/translation/types.ts. The NDJSON endpoint
// speaks a discriminated event union wrapped in the shared API envelope.
export interface TranslationRequestInput {
  text: string
  source_lang_code: string | null
  source_locale_code: string | null
  target_locale_code: string
}

export interface TranslationLanguageCandidate {
  code: string
  confidence: number
}

export interface TranslationEvidence {
  source_text: string
  target_text: string
  // The requested locale is kept separately from the locale metadata attached
  // to the stored reference expression.
  target_locale_code: string
  reference_locale_codes?: string[]
  path_type: 'direct' | 'two_hop'
  pivot_lang_code?: string
  match_type: 'exact' | 'prefix'
  source_markers: string[]
}

export type TranslationStage = 'analyzing' | 'retrieving' | 'generating'
export type TranslationMode = 'exact_lookup' | 'assisted'
export type TranslationResolution = 'exact_lookup' | 'assisted'
export type TranslationEvidenceRetrievalStatus = 'matched' | 'no_match' | 'failed' | 'skipped'

export interface TranslationStatusEvent {
  type: 'status'
  stage: TranslationStage
  mode: TranslationMode
  request_id: string
}

export interface TranslationSourceLanguageEvent {
  type: 'source_language'
  code: string
  confidence: number
  candidates?: TranslationLanguageCandidate[]
}

export interface TranslationSourceConfirmationEvent {
  type: 'source_confirmation_required'
  candidates: TranslationLanguageCandidate[]
  reason: string
}

export interface TranslationEvidenceEvent {
  type: 'evidence'
  items: TranslationEvidence[]
  omitted_count: number
  degraded: boolean
  retrieval_status: TranslationEvidenceRetrievalStatus
}

export interface TranslationDeltaEvent {
  type: 'translation_delta'
  text: string
}

export interface TranslationResult {
  translation: string
  alternatives: string[]
  source_lang_code: string | null
  target_locale_code: string
  evidence_present: boolean
  model_only: boolean
  resolution: TranslationResolution
  generation_skipped: boolean
}

export interface TranslationResultEvent extends TranslationResult {
  type: 'result'
  request_id: string
}

export interface TranslationErrorEvent {
  type: 'error'
  code: string
  retryable: boolean
  retry_after_seconds?: number
  reset_at?: string
}

export type TranslationStreamEvent =
  | TranslationStatusEvent
  | TranslationSourceLanguageEvent
  | TranslationSourceConfirmationEvent
  | TranslationEvidenceEvent
  | TranslationDeltaEvent
  | TranslationResultEvent
  | TranslationErrorEvent

export interface TranslationSuccessEnvelope {
  success: true
  data: TranslationStreamEvent
}

export interface TranslationErrorEnvelope {
  success: false
  error: string
  message: string
  retryable?: boolean
  retry_after_seconds?: number
  reset_at?: string
}

// Streaming must bypass the shared Axios client: it cannot stream and applies a
// 15s timeout that would abort a slow generation. The composable owns parsing.
export function postTranslation(
  input: TranslationRequestInput,
  options: { signal?: AbortSignal } = {},
): Promise<Response> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' }
  const token = localStorage.getItem('token')
  if (token) headers.Authorization = `Bearer ${token}`

  return fetch('/api/v2/translate', {
    method: 'POST',
    headers,
    body: JSON.stringify(input),
    signal: options.signal,
  })
}
