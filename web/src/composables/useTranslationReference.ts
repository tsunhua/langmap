import { onUnmounted, ref } from 'vue'
import { getExpression, getMappingGraph, type ExpressionDetail } from '@/api/expressions'
import { getLanguageLocale } from '@/api/languageIdentity'
import type { TranslationEvidence } from '@/api/translation'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'
import type { TranslationTerm } from '@/utils/translationTerms'
import { contentRevision } from '@/utils/contentRevision'

export interface TranslationReference {
  evidence: TranslationEvidence[]
  detail: ExpressionDetail | null
  graph: MappingGraphResponse | null
}
export function useTranslationReference() {
  const selected = ref<TranslationTerm | null>(null)
  const reference = ref<TranslationReference | null>(null)
  const loading = ref(false)
  const failed = ref(false)
  const cache = new Map<string, TranslationReference>()
  const localeLanguages = new Map<string, string>()
  const inflight = new Map<string, { controller: AbortController; promise: Promise<TranslationReference> }>()
  let sequence = 0
  let activeKey: string | null = null
  let context = ''

  function abortExcept(key?: string) {
    for (const [pendingKey, pending] of inflight) {
      if (pendingKey === key) continue
      pending.controller.abort()
      inflight.delete(pendingKey)
    }
  }
  function close() {
    sequence += 1
    abortExcept()
    activeKey = null
    selected.value = null
    reference.value = null
    loading.value = false
    failed.value = false
  }
  function reset() {
    close()
    cache.clear()
    context = ''
    localeLanguages.clear()
  }
  async function select(term: TranslationTerm, evidence: TranslationEvidence[], locale: string, sourceLanguage: string | null) {
    const nextContext = JSON.stringify([locale, sourceLanguage, contentRevision.value])
    if (context !== nextContext) { reset(); context = nextContext }
    const key = JSON.stringify([nextContext, term.text])
    const request = ++sequence
    abortExcept(key)
    activeKey = key
    selected.value = term
    reference.value = null
    failed.value = false
    loading.value = false
    const matching = evidence.filter(item => item.target_text === term.text)
    if (matching.length) {
      reference.value = { evidence: matching, detail: null, graph: null }
      return
    }
    const cached = cache.get(key)
    if (cached) { reference.value = cached; return }
    loading.value = true
    let pending = inflight.get(key)
    if (!pending) {
      const controller = new AbortController()
      const promise = (async () => {
        const langCode = localeLanguages.get(locale) ?? (await getLanguageLocale(locale, controller.signal)).lang_code
        if (controller.signal.aborted) throw new DOMException('Aborted', 'AbortError')
        localeLanguages.set(locale, langCode)
        const identity = { lang_code: langCode, text: term.text }
        const [detail, graph] = await Promise.all([
          getExpression(identity, undefined, controller.signal),
          getMappingGraph(identity, 1, undefined, sourceLanguage ?? undefined, controller.signal),
        ])
        return { evidence: [], detail, graph }
      })()
      pending = { controller, promise }
      inflight.set(key, pending)
    }
    try {
      const value = await pending.promise
      if (!pending.controller.signal.aborted) cache.set(key, value)
      if (sequence === request && activeKey === key) reference.value = value
    } catch (cause) {
      if (sequence === request && activeKey === key && !pending.controller.signal.aborted) {
        // A missing expression is a valid empty lookup, distinct from a failed request.
        const status = (cause as { response?: { status?: number } } | null)?.response?.status
        failed.value = status !== 404
        reference.value = { evidence: [], detail: null, graph: null }
        if (status === 404) cache.set(key, reference.value)
      }
    } finally {
      if (inflight.get(key) === pending) inflight.delete(key)
      if (sequence === request) loading.value = false
    }
  }
  onUnmounted(reset)
  return { selected, reference, loading, failed, select, close, reset }
}
