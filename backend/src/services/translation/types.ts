export interface TranslationRequest {
  text: string;
  source_lang_code: string | null;
  source_locale_code: string | null;
  target_locale_code: string;
}

export interface TranslationLanguageCandidate {
  code: string;
  confidence: number;
}

export interface SourceLanguageResult {
  code: string;
  confidence: number;
  candidates?: TranslationLanguageCandidate[];
}

export type EvidencePathType = 'direct' | 'two_hop';
export type EvidenceMatchType = 'exact' | 'prefix';

export interface TranslationEvidence {
  source_text: string;
  target_text: string;
  target_locale_code: string;
  path_type: EvidencePathType;
  pivot_lang_code?: string;
  match_type: EvidenceMatchType;
  source_markers: string[];
}

export type TranslationStage = 'analyzing' | 'retrieving' | 'generating';
export type TranslationMode = 'exact_lookup' | 'assisted';
export type TranslationResolution = 'exact_lookup' | 'assisted';

export interface TranslationStreamStatusEvent {
  type: 'status';
  stage: TranslationStage;
  mode: TranslationMode;
  request_id: string;
}

export interface TranslationStreamSourceLanguageEvent {
  type: 'source_language';
  code: string;
  confidence: number;
  candidates?: TranslationLanguageCandidate[];
}

export interface TranslationStreamSourceConfirmationEvent {
  type: 'source_confirmation_required';
  candidates: TranslationLanguageCandidate[];
  reason: string;
}

export interface TranslationStreamEvidenceEvent {
  type: 'evidence';
  items: TranslationEvidence[];
  omitted_count: number;
  degraded: boolean;
}

export interface TranslationStreamDeltaEvent {
  type: 'translation_delta';
  text: string;
}

export interface TranslationResult {
  translation: string;
  alternatives: string[];
  source_lang_code: string;
  target_locale_code: string;
  evidence_present: boolean;
  model_only: boolean;
  resolution: TranslationResolution;
  generation_skipped: boolean;
}

export interface TranslationStreamResultEvent extends TranslationResult {
  type: 'result';
  request_id: string;
}

export interface TranslationStreamErrorEvent {
  type: 'error';
  code: string;
  retryable: boolean;
  retry_after_seconds?: number;
  reset_at?: string;
}

export type TranslationStreamEvent =
  | TranslationStreamStatusEvent
  | TranslationStreamSourceLanguageEvent
  | TranslationStreamSourceConfirmationEvent
  | TranslationStreamEvidenceEvent
  | TranslationStreamDeltaEvent
  | TranslationStreamResultEvent
  | TranslationStreamErrorEvent;

export type PlannerUncertaintyReason =
  | 'unknown_term'
  | 'idiom'
  | 'proper_noun'
  | 'domain_term'
  | 'context_ambiguity';

export interface PlannerSpan {
  start: number;
  end: number;
  text: string;
  reason: PlannerUncertaintyReason;
  confidence: number;
}

export interface PlannerOutput {
  source_lang_code: string | null;
  source_confidence: number;
  uncertain_spans: PlannerSpan[];
}

export interface RetrievalOutput {
  items: TranslationEvidence[];
  omitted_count: number;
  degraded: boolean;
}

export interface GenerationOutput {
  translation: string;
  alternatives: string[];
  model_only: boolean;
}