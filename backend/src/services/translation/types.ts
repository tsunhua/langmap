// Single provider model shared by the planner (structured call) and the
// generative stage, so provider code stays in one place per layer.
export const TRANSLATION_MODEL = '@cf/zai-org/glm-4.7-flash';

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
export type TranslationEvidenceRetrievalStatus = 'matched' | 'no_match' | 'failed' | 'skipped';

export interface TranslationEvidence {
  source_text: string;
  target_text: string;
  // The requested output locale. The reference rows themselves may have a
  // different or missing locale link because retrieval is language-level.
  target_locale_code: string;
  reference_locale_codes?: string[];
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
  retrieval_status: TranslationEvidenceRetrievalStatus;
}

export interface TranslationStreamDeltaEvent {
  type: 'translation_delta';
  text: string;
}

export interface TranslationResult {
  translation: string;
  alternatives: string[];
  // null when the assisted path cannot establish a source (planner unavailable)
  // and falls back to model-only generation; never a fabricated code.
  source_lang_code: string | null;
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
  | 'keyword'
  | 'phrase'
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
  retrieval_spans: PlannerSpan[];
}

// Discriminated result of planTranslation; the Task 1.6 orchestrator consumes
// it directly:
//   ok                    -> source resolved (user-specified or auto-detected); proceed to retrieval
//   confirmation_required -> auto-detect fell below the confidence threshold; ask the user, never guess
//   unavailable           -> source cannot be determined safely; skip retrieval and go model-only
export type PlannerResult =
  | { status: 'ok'; output: PlannerOutput }
  | { status: 'confirmation_required' }
  | { status: 'unavailable' };

export interface RetrievalOutput {
  items: TranslationEvidence[];
  omitted_count: number;
  degraded: boolean;
  retrieval_status: Exclude<TranslationEvidenceRetrievalStatus, 'skipped'>;
}

export interface GenerationOutput {
  translation: string;
  alternatives: string[];
  model_only: boolean;
}
