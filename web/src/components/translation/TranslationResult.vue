<script setup lang="ts">
import { computed, nextTick, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Copy, Pencil, RotateCcw, Send, X } from 'lucide-vue-next'
import type { TranslationEvidence, TranslationResult as TranslationResultData } from '@/api/translation'
import { translationTerms, type TranslationTerm } from '@/utils/translationTerms'
import { useTranslationReference } from '@/composables/useTranslationReference'
import { contentRevision } from '@/utils/contentRevision'

const props = withDefaults(defineProps<{
  translation: string
  result: TranslationResultData | null
  alternatives: string[]
  evidence?: TranslationEvidence[]
  sourceLangCode?: string | null
}>(), { evidence: () => [], sourceLangCode: null })

const emit = defineEmits<{
  retry: []
  edit: []
  'send-to-contribute': []
}>()

const { t } = useI18n()
const copied = ref(false)
let copiedTimer: ReturnType<typeof setTimeout> | undefined

type ResultStatus = 'exact' | 'model_only' | 'assisted'

// One status per result: an exact lookup wins over a (contradictory) model_only
// flag so the two badges can never render together.
const status = computed<ResultStatus | null>(() => {
  if (!props.result) return null
  if (props.result.resolution === 'exact_lookup') return 'exact'
  if (props.result.model_only) return 'model_only'
  return 'assisted'
})
const shownAlternatives = computed(() =>
  props.result?.resolution === 'exact_lookup'
    ? props.alternatives.filter(value => value !== props.translation).slice(0, 2)
    : [],
)
const terms = computed(() => translationTerms(props.translation, props.evidence.filter(item => item.target_text !== props.translation).map(item => item.target_text)))
const lookup = useTranslationReference()
const { selected, reference, loading, failed } = lookup
const translationHost = ref<HTMLElement | null>(null)
const neighbors = computed(() => reference.value?.graph?.nodes.filter(node => node.expression_id !== reference.value?.graph?.root_id) ?? [])
watch(() => [props.translation, props.result, props.evidence, props.sourceLangCode, contentRevision.value], () => lookup.reset())
function selectTerm(term: TranslationTerm) {
  if (!props.result) return
  void lookup.select(term, props.evidence, props.result.target_locale_code, props.sourceLangCode ?? props.result.source_lang_code)
}
function closeReference() {
  if (!selected.value) return
  const start = selected.value.start
  lookup.close()
  void nextTick(() => translationHost.value?.querySelector<HTMLButtonElement>(`[data-start="${start}"]`)?.focus())
}
function sourceLabels(id: string) {
  return reference.value?.graph?.edges
    .filter(edge => edge.source_id === id || edge.target_id === id)
    .flatMap(edge => edge.sources.map(source => `${source.source_id}${source.marker ? ` · ${source.marker}` : ''}`))
    .join(', ') ?? ''
}

// Exact lookups are already canonical mappings, so offering to contribute them
// again would create duplicates. A rewrite-then-contribute flow is deferred.
const canSendToContribute = computed(() =>
  Boolean(props.result) && props.result?.resolution !== 'exact_lookup',
)

async function copy() {
  if (!props.translation) return
  const clipboard = typeof navigator !== 'undefined' ? navigator.clipboard : undefined
  if (!clipboard || typeof clipboard.writeText !== 'function') return
  try {
    await clipboard.writeText(props.translation)
    copied.value = true
    if (copiedTimer) clearTimeout(copiedTimer)
    copiedTimer = setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch {
    copied.value = false
  }
}

function sendToContribute() {
  if (!props.result) return
  emit('send-to-contribute')
}

onUnmounted(() => {
  if (copiedTimer) clearTimeout(copiedTimer)
})
</script>

<template>
  <section class="translation-result" :aria-label="t('phraseTranslate.resultHeading')" @keydown.esc="closeReference">
    <h3 class="result-heading">{{ t('phraseTranslate.resultHeading') }}</h3>
    <p v-if="!result" class="translation" dir="auto">{{ translation }}</p>
    <p v-else ref="translationHost" class="translation" dir="auto"><template v-for="term in terms" :key="`${term.start}:${term.end}`"><button v-if="term.interactive" type="button" class="translation-term" :class="{ selected: selected?.start === term.start }" :data-term="term.text" :data-start="term.start" :aria-label="t('phraseTranslate.lookupTerm', { term: term.text })" :aria-expanded="selected?.start === term.start" :aria-controls="selected ? 'translation-reference' : undefined" @click="selectTerm(term)">{{ term.text }}</button><span v-else>{{ term.text }}</span></template></p>
    <p v-if="result" class="term-hint">{{ t('phraseTranslate.termHint') }}</p>

    <section v-if="selected" id="translation-reference" class="reference-panel" aria-labelledby="reference-heading" :aria-busy="loading">
      <div class="reference-header">
        <h4 id="reference-heading" dir="auto">{{ selected.text }}</h4>
        <button type="button" class="btn btn-icon" :aria-label="t('phraseTranslate.closeReference')" @click="closeReference"><X :size="18" aria-hidden="true" /></button>
      </div>
      <p v-if="loading" role="status">{{ t('phraseTranslate.referenceLoading') }}</p>
      <p v-else-if="failed" role="status">{{ t('phraseTranslate.referenceFailed') }}</p>
      <template v-else>
        <ul v-if="reference?.evidence.length" class="reference-items">
          <li v-for="(item, index) in reference.evidence" :key="index">
            <p dir="auto">{{ item.source_text }} → {{ item.target_text }}</p>
            <p class="reference-meta">{{ t('phraseTranslate.evidenceReferenceLocale') }}: {{ item.reference_locale_codes?.join(' · ') || t('phraseTranslate.referenceLocaleUnknown') }}</p>
            <p v-if="item.source_markers.length" class="reference-meta">{{ item.source_markers.join(' · ') }}</p>
          </li>
        </ul>
        <template v-else-if="reference?.detail">
          <p class="reference-meta">{{ reference.detail.locales.map(item => item.language_locale_code).join(' · ') || t('phraseTranslate.referenceLocaleUnknown') }}</p>
          <p v-for="reading in reference.detail.readings" :key="`${reading.language_locale_code}:${reading.scheme}:${reading.value}:${reading.source_id}`" dir="auto">{{ reading.value }} <span class="reference-meta">{{ reading.scheme }} · {{ reading.language_locale_code }}<template v-if="reading.source_id"> · {{ reading.source_id }}</template></span></p>
          <p v-if="reference.detail.expression.source_name" class="reference-meta">{{ reference.detail.expression.source_name }}</p>
          <ul v-if="neighbors.length" class="reference-items"><li v-for="neighbor in neighbors" :key="neighbor.expression_id"><p dir="auto">{{ neighbor.text }} <span class="reference-meta">{{ neighbor.language_name || neighbor.lang_code }}</span></p><p v-if="sourceLabels(neighbor.expression_id)" class="reference-meta">{{ sourceLabels(neighbor.expression_id) }}</p></li></ul>
          <p v-else>{{ t('phraseTranslate.evidenceEmpty') }}</p>
        </template>
        <p v-else>{{ t('phraseTranslate.evidenceEmpty') }}</p>
        <p v-if="reference?.evidence.length" class="reference-meta">{{ t('phraseTranslate.referenceNotice') }}</p>
      </template>
    </section>

    <p v-if="status" class="result-status">
      <span v-if="status === 'exact'" class="badge">{{ t('phraseTranslate.exactMatch') }}</span>
      <span v-else-if="status === 'model_only'" class="badge">{{ t('phraseTranslate.modelOnly') }}</span>
      <span v-else class="badge badge-ai">{{ t('phraseTranslate.aiAssistedBadge') }}</span>
    </p>

    <details v-if="shownAlternatives.length" class="alternatives">
      <summary class="alternatives-heading">{{ t('phraseTranslate.referenceTranslations') }}</summary>
      <ul>
        <li v-for="(alternative, index) in shownAlternatives" :key="index">{{ alternative }}</li>
      </ul>
    </details>

    <div class="actions">
      <button
        type="button"
        class="btn btn-icon"
        :disabled="!translation"
        data-action="copy"
        :aria-label="t('phraseTranslate.copy')"
        @click="copy"
      >
        <Copy :size="16" aria-hidden="true" />
      </button>
      <span v-if="copied" class="copied" role="status">{{ t('phraseTranslate.copied') }}</span>
      <button type="button" class="btn" data-action="retry" @click="emit('retry')">
        <RotateCcw :size="16" aria-hidden="true" />
        {{ t('phraseTranslate.retry') }}
      </button>
      <button type="button" class="btn" data-action="edit" @click="emit('edit')">
        <Pencil :size="16" aria-hidden="true" />
        {{ t('phraseTranslate.edit') }}
      </button>
      <button
        v-if="canSendToContribute"
        type="button"
        class="btn btn-ghost"
        data-action="send-to-contribute"
        @click="sendToContribute"
      >
        <Send :size="16" aria-hidden="true" />
        {{ t('phraseTranslate.sendToContribute') }}
      </button>
    </div>
  </section>
</template>

<style scoped>
.translation-result {
  display: grid;
  gap: 10px;
  min-width: 0;
}
.result-heading {
  margin: 0;
  font-size: 12px;
  font-family: var(--mono);
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--faint);
}
.translation {
  margin: 0;
  min-width: 0;
  color: var(--fg);
  font-size: 20px;
  line-height: 1.45;
  overflow-wrap: anywhere;
  white-space: pre-wrap;
}
.result-status {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 0;
}
.badge {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  padding: 2px 6px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  color: var(--muted);
  background: var(--surface-2);
}
.badge-ai {
  border-color: color-mix(in oklch, var(--accent) 40%, var(--border));
  color: var(--accent);
  background: var(--accent-soft);
}
.alternatives-heading {
  margin: 0 0 6px;
  font-size: 12px;
  font-weight: 600;
  color: var(--muted);
}
.alternatives ul {
  margin: 0;
  padding-left: 18px;
  min-width: 0;
}
.alternatives li {
  min-width: 0;
  color: var(--fg);
  font-size: 14px;
  line-height: 1.4;
  overflow-wrap: anywhere;
}
.actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  min-width: 0;
}
.actions .btn {
  min-height: 44px;
  padding: 0 14px;
}
.actions .btn-icon {
  min-width: 44px;
  padding: 0;
}
.copied {
  font-size: 12px;
  color: var(--up);
}

/* Inline words keep their natural width so lookup controls do not space out the sentence. */
.translation-term { display: inline-block; min-width: 0; min-height: 44px; max-width: 100%; padding: 0; border: 0; border-radius: var(--r); background: transparent; color: inherit; font: inherit; white-space: pre-wrap; overflow-wrap: anywhere; cursor: pointer; text-align: inherit; }
.translation-term:hover, .translation-term.selected { background: var(--accent-soft); color: var(--accent); }
.translation-term:focus-visible, .reference-panel button:focus-visible, .alternatives summary:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.term-hint { margin: 0; color: var(--muted); font-size: var(--text-meta); }
.reference-panel { min-width: 0; padding: 12px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface-2); overflow-wrap: anywhere; }
.reference-header { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.reference-header h4 { min-width: 0; margin: 0; }
.reference-panel p { margin: 6px 0; white-space: pre-wrap; }
.reference-panel .btn-icon { min-width: 44px; min-height: 44px; }
.reference-items { padding: 0; margin: 8px 0; list-style: none; display: grid; gap: 8px; }
.reference-items li + li { border-top: 1px solid var(--border); padding-top: 8px; }
.reference-meta { font-size: var(--text-meta); color: var(--muted); }
.alternatives summary { min-height: 44px; display: flex; align-items: center; cursor: pointer; }
</style>
