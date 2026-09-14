import { ref } from 'vue'
import {
  postTranslation,
  type TranslationEvidence,
  type TranslationLanguageCandidate,
  type TranslationMode,
  type TranslationRequestInput,
  type TranslationResult,
  type TranslationStage,
} from '@/api/translation'
import { useLatestRequest } from './useLatestRequest'

export interface TranslationStreamError {
  code: string
  message: string
  retryable: boolean
  resetAt?: string
}

export interface TranslationSourceLanguage {
  code: string
  confidence: number
}

export interface TranslationConfirmation {
  candidates: TranslationLanguageCandidate[]
  reason: string
}

type JsonRecord = Record<string, unknown>

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function asString(value: unknown, fallback = ''): string {
  return typeof value === 'string' ? value : fallback
}

function asNumber(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}

function asStage(value: unknown): TranslationStage | null {
  return value === 'analyzing' || value === 'retrieving' || value === 'generating' ? value : null
}

function asMode(value: unknown): TranslationMode | null {
  return value === 'exact_lookup' || value === 'assisted' ? value : null
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  const out: string[] = []
  for (const item of value as unknown[]) {
    if (typeof item === 'string') out.push(item)
  }
  return out
}

function asCandidates(value: unknown): TranslationLanguageCandidate[] {
  if (!Array.isArray(value)) return []
  return (value as unknown[]).filter(isRecord).map((item) => ({
    code: asString(item.code),
    confidence: asNumber(item.confidence),
  }))
}

function asEvidenceItems(value: unknown): TranslationEvidence[] {
  if (!Array.isArray(value)) return []
  return (value as unknown[]).filter(isRecord).map((item) => {
    const evidence: TranslationEvidence = {
      source_text: asString(item.source_text),
      target_text: asString(item.target_text),
      target_locale_code: asString(item.target_locale_code),
      path_type: item.path_type === 'two_hop' ? 'two_hop' : 'direct',
      match_type: item.match_type === 'prefix' ? 'prefix' : 'exact',
      source_markers: asStringArray(item.source_markers),
    }
    if (typeof item.pivot_lang_code === 'string') evidence.pivot_lang_code = item.pivot_lang_code
    return evidence
  })
}

function asResult(event: JsonRecord): TranslationResult {
  return {
    translation: asString(event.translation),
    alternatives: asStringArray(event.alternatives),
    source_lang_code: typeof event.source_lang_code === 'string' ? event.source_lang_code : null,
    target_locale_code: asString(event.target_locale_code),
    evidence_present: event.evidence_present === true,
    model_only: event.model_only === true,
    resolution: event.resolution === 'exact_lookup' ? 'exact_lookup' : 'assisted',
    generation_skipped: event.generation_skipped === true,
  }
}

function asError(event: JsonRecord): TranslationStreamError {
  // The NDJSON error event carries `code`, but the shared envelope uses `error`.
  const error: TranslationStreamError = {
    code: asString(event.code, asString(event.error, 'TRANSLATION_FAILED')),
    message: asString(event.message),
    retryable: event.retryable === true,
  }
  if (typeof event.reset_at === 'string') error.resetAt = event.reset_at
  return error
}

function isAbortError(cause: unknown): boolean {
  return isRecord(cause) && cause.name === 'AbortError'
}

export function useTranslationStream() {
  const latest = useLatestRequest()

  const requestId = ref<string | null>(null)
  const stage = ref<TranslationStage | null>(null)
  const mode = ref<TranslationMode | null>(null)
  const sourceLanguage = ref<TranslationSourceLanguage | null>(null)
  const confirmation = ref<TranslationConfirmation | null>(null)
  const evidence = ref<TranslationEvidence[]>([])
  const translation = ref('')
  const alternatives = ref<string[]>([])
  const result = ref<TranslationResult | null>(null)
  const error = ref<TranslationStreamError | null>(null)
  const isStreaming = ref(false)

  let activeController: AbortController | null = null

  function resetStreamState() {
    requestId.value = null
    stage.value = null
    mode.value = null
    sourceLanguage.value = null
    confirmation.value = null
    evidence.value = []
    translation.value = ''
    alternatives.value = []
    result.value = null
    error.value = null
  }

  function abortActive() {
    if (!activeController) return
    activeController.abort()
    activeController = null
  }

  // Returns true when the event ends the stream (result, error, confirmation).
  function applyEvent(event: JsonRecord): boolean {
    switch (asString(event.type)) {
      case 'status': {
        const nextStage = asStage(event.stage)
        const nextMode = asMode(event.mode)
        if (nextStage) stage.value = nextStage
        if (nextMode) mode.value = nextMode
        if (typeof event.request_id === 'string') requestId.value = event.request_id
        return false
      }
      case 'source_language':
        sourceLanguage.value = {
          code: asString(event.code),
          confidence: asNumber(event.confidence),
        }
        return false
      case 'source_confirmation_required':
        confirmation.value = {
          candidates: asCandidates(event.candidates),
          reason: asString(event.reason),
        }
        return true
      case 'evidence':
        evidence.value = asEvidenceItems(event.items)
        return false
      case 'translation_delta':
        translation.value += asString(event.text)
        return false
      case 'result': {
        const completed = asResult(event)
        result.value = completed
        translation.value = completed.translation
        alternatives.value = completed.alternatives
        return true
      }
      case 'error':
        error.value = asError(event)
        return true
      default:
        // Unknown types are ignored so newer server events cannot break old clients.
        return false
    }
  }

  function applyEnvelope(rawLine: string): boolean {
    const raw = rawLine.trim()
    if (!raw) return false
    let parsed: unknown
    try {
      parsed = JSON.parse(raw)
    } catch {
      return false
    }
    if (!isRecord(parsed)) return false
    if (parsed.success === false) {
      error.value = asError(parsed)
      return true
    }
    if (parsed.success !== true) return false
    return isRecord(parsed.data) ? applyEvent(parsed.data) : false
  }

  async function readErrorEnvelope(response: Response): Promise<TranslationStreamError> {
    let parsed: unknown = null
    try {
      parsed = await response.json()
    } catch {
      parsed = null
    }
    if (isRecord(parsed) && parsed.success === false) return asError(parsed)
    return {
      code: `HTTP_${response.status}`,
      message: response.statusText || 'Translation request failed.',
      retryable: response.status >= 500,
    }
  }

  async function submit(input: TranslationRequestInput): Promise<void> {
    abortActive()
    const request = latest.begin()
    resetStreamState()
    isStreaming.value = true

    const controller = new AbortController()
    activeController = controller
    let terminated = false

    try {
      let response: Response
      try {
        response = await postTranslation(input, { signal: controller.signal })
      } catch (cause) {
        if (!latest.isCurrent(request)) return
        isStreaming.value = false
        if (isAbortError(cause)) return
        error.value = { code: 'NETWORK_ERROR', message: 'Network request failed.', retryable: true }
        return
      }

      if (!latest.isCurrent(request)) return

      // Pre-stream failures return a normal JSON envelope, not NDJSON.
      if (!response.ok) {
        const preStreamError = await readErrorEnvelope(response)
        if (!latest.isCurrent(request)) return
        error.value = preStreamError
        return
      }

      const body = response.body
      if (!body) {
        error.value = {
          code: 'STREAM_FAILED',
          message: 'Response body is unavailable.',
          retryable: true,
        }
        return
      }

      const reader = body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''

      try {
        while (!terminated) {
          const { done, value } = await reader.read()
          if (!latest.isCurrent(request)) {
            terminated = true
            break
          }
          if (done) break
          buffer += decoder.decode(value, { stream: true })
          let newlineIndex = buffer.indexOf('\n')
          while (newlineIndex >= 0 && !terminated) {
            terminated = applyEnvelope(buffer.slice(0, newlineIndex))
            buffer = buffer.slice(newlineIndex + 1)
            newlineIndex = buffer.indexOf('\n')
          }
        }
        if (!terminated) {
          buffer += decoder.decode()
          if (buffer.trim()) terminated = applyEnvelope(buffer)
        }
        if (terminated) await reader.cancel().catch(() => undefined)
      } catch (cause) {
        if (latest.isCurrent(request) && !isAbortError(cause)) {
          error.value = {
            code: 'STREAM_FAILED',
            message: 'Translation stream failed.',
            retryable: true,
          }
        }
      }
    } finally {
      if (activeController === controller) activeController = null
      if (latest.isCurrent(request)) isStreaming.value = false
    }
  }

  function cancel() {
    abortActive()
    isStreaming.value = false
    // Advance the sequence so any late chunk from the aborted stream is dropped.
    latest.begin()
  }

  function reset() {
    abortActive()
    latest.begin()
    resetStreamState()
    isStreaming.value = false
  }

  return {
    requestId,
    stage,
    mode,
    sourceLanguage,
    confirmation,
    evidence,
    translation,
    alternatives,
    result,
    error,
    isStreaming,
    submit,
    cancel,
    reset,
  }
}
