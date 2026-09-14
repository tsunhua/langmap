import { computed, onUnmounted, ref } from 'vue'
import {
  postTranslation,
  type TranslationErrorEnvelope,
  type TranslationErrorEvent,
  type TranslationEvidence,
  type TranslationLanguageCandidate,
  type TranslationMode,
  type TranslationRequestInput,
  type TranslationResult,
  type TranslationResultEvent,
  type TranslationStage,
  type TranslationStreamEvent,
  type TranslationSuccessEnvelope,
} from '@/api/translation'
import { useLatestRequest } from './useLatestRequest'

export interface TranslationStreamError {
  code: string
  message: string
  retryable: boolean
  retryAfterSeconds?: number
  resetAt?: string
}

export interface TranslationConfirmation {
  candidates: TranslationLanguageCandidate[]
  reason: string
}

// The evidence event carries truncation and degradation alongside the items so
// the UI can surface them (spec 9.4.8). Keep the bundle nullable: no evidence
// event has arrived yet.
export interface TranslationEvidenceState {
  items: TranslationEvidence[]
  omittedCount: number
  degraded: boolean
}

const STREAM_EVENT_TYPES = new Set<string>([
  'status',
  'source_language',
  'source_confirmation_required',
  'evidence',
  'translation_delta',
  'result',
  'error',
])

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function asString(value: unknown, fallback = ''): string {
  return typeof value === 'string' ? value : fallback
}

function isTranslationStreamEvent(value: unknown): value is TranslationStreamEvent {
  return isRecord(value) && typeof value.type === 'string' && STREAM_EVENT_TYPES.has(value.type)
}

function isTranslationErrorEnvelope(value: unknown): value is TranslationErrorEnvelope {
  return isRecord(value) && value.success === false && typeof value.error === 'string'
}

function isTranslationSuccessEnvelope(value: unknown): value is TranslationSuccessEnvelope {
  return isRecord(value) && value.success === true && isTranslationStreamEvent(value.data)
}

function isAbortError(cause: unknown): boolean {
  return isRecord(cause) && cause.name === 'AbortError'
}

function errorFromEvent(event: TranslationErrorEvent): TranslationStreamError {
  const error: TranslationStreamError = {
    code: event.code,
    message: '',
    retryable: event.retryable,
  }
  if (typeof event.retry_after_seconds === 'number') {
    error.retryAfterSeconds = event.retry_after_seconds
  }
  if (typeof event.reset_at === 'string') error.resetAt = event.reset_at
  return error
}

function errorFromEnvelope(envelope: TranslationErrorEnvelope): TranslationStreamError {
  const error: TranslationStreamError = {
    code: envelope.error,
    message: asString(envelope.message),
    retryable: envelope.retryable === true,
  }
  if (typeof envelope.retry_after_seconds === 'number') {
    error.retryAfterSeconds = envelope.retry_after_seconds
  }
  if (typeof envelope.reset_at === 'string') error.resetAt = envelope.reset_at
  return error
}

function resultFromEvent(event: TranslationResultEvent): TranslationResult {
  return {
    translation: event.translation,
    alternatives: event.alternatives,
    source_lang_code: event.source_lang_code,
    target_locale_code: event.target_locale_code,
    evidence_present: event.evidence_present,
    model_only: event.model_only,
    resolution: event.resolution,
    generation_skipped: event.generation_skipped,
  }
}

export function useTranslationStream() {
  const latest = useLatestRequest()

  const requestId = ref<string | null>(null)
  const stage = ref<TranslationStage | null>(null)
  const mode = ref<TranslationMode | null>(null)
  const sourceLanguage = ref<TranslationLanguageCandidate | null>(null)
  const confirmation = ref<TranslationConfirmation | null>(null)
  const evidence = ref<TranslationEvidenceState | null>(null)
  const translation = ref('')
  const alternatives = ref<string[]>([])
  const result = ref<TranslationResult | null>(null)
  const error = ref<TranslationStreamError | null>(null)
  const isStreaming = ref(false)

  const resetAt = computed(() => error.value?.resetAt ?? null)
  const retryAfterSeconds = computed(() => error.value?.retryAfterSeconds ?? null)

  let activeController: AbortController | null = null

  function resetStreamState() {
    requestId.value = null
    stage.value = null
    mode.value = null
    sourceLanguage.value = null
    confirmation.value = null
    evidence.value = null
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
  // Typing against the exported union makes exhaustiveness catch contract drift.
  function applyEvent(event: TranslationStreamEvent): boolean {
    switch (event.type) {
      case 'status':
        stage.value = event.stage
        mode.value = event.mode
        requestId.value = event.request_id
        return false
      case 'source_language':
        sourceLanguage.value = { code: event.code, confidence: event.confidence }
        return false
      case 'source_confirmation_required':
        confirmation.value = { candidates: event.candidates, reason: event.reason }
        return true
      case 'evidence':
        evidence.value = {
          items: event.items,
          omittedCount: event.omitted_count ?? 0,
          degraded: event.degraded ?? false,
        }
        return false
      case 'translation_delta':
        translation.value += event.text
        return false
      case 'result': {
        const completed = resultFromEvent(event)
        result.value = completed
        translation.value = completed.translation
        alternatives.value = completed.alternatives
        return true
      }
      case 'error':
        error.value = errorFromEvent(event)
        return true
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
    if (isTranslationErrorEnvelope(parsed)) {
      error.value = errorFromEnvelope(parsed)
      return true
    }
    if (isTranslationSuccessEnvelope(parsed)) return applyEvent(parsed.data)
    return false
  }

  async function readErrorEnvelope(response: Response): Promise<TranslationStreamError> {
    let parsed: unknown = null
    try {
      parsed = await response.json()
    } catch {
      parsed = null
    }
    if (isTranslationErrorEnvelope(parsed)) return errorFromEnvelope(parsed)
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
        // Flush a final line the server sent without a trailing newline.
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

  onUnmounted(() => {
    abortActive()
    isStreaming.value = false
    // Cancel any in-flight generation so the server stops working after teardown.
    latest.begin()
  })

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
    resetAt,
    retryAfterSeconds,
    isStreaming,
    submit,
    cancel,
    reset,
  }
}
