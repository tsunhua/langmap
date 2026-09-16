<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Check, Circle, LoaderCircle } from 'lucide-vue-next'
import type {
  TranslationEvidence,
  TranslationLanguageCandidate,
  TranslationEvidenceRetrievalStatus,
  TranslationMode,
  TranslationPlannerSpan,
  TranslationResult,
  TranslationStage,
} from '@/api/translation'

const props = withDefaults(defineProps<{
  stage: TranslationStage | null
  mode: TranslationMode | null
  isStreaming: boolean
  error: { message?: string } | null
  sourceLanguage: TranslationLanguageCandidate | null
  segmentationSpans?: TranslationPlannerSpan[] | null
  evidence: {
    items: TranslationEvidence[]
    omittedCount: number
    degraded: boolean
    retrievalStatus?: TranslationEvidenceRetrievalStatus
  } | null
  targetLocaleCode: string
  translation: string
  result: TranslationResult | null
}>(), {
  segmentationSpans: null,
})

const { t } = useI18n()
const processOpen = ref(true)

const stageLabels = {
  analyzing: 'phraseTranslate.stageAnalyzing',
  retrieving: 'phraseTranslate.stageRetrieving',
  generating: 'phraseTranslate.stageGenerating',
} as const

// The exact-match fast path skips analysis and generation, so it only ever
// shows the retrieving stage; the stage prop drives which stage is active.
const stages = computed<TranslationStage[]>(() =>
  props.mode === 'exact_lookup' ? ['retrieving'] : ['analyzing', 'retrieving', 'generating'],
)

function confidenceLabel(confidence: number): string {
  return `${Math.round(Math.max(0, Math.min(1, confidence)) * 100)}%`
}

const currentLabel = computed(() => {
  if (props.error) return t('phraseTranslate.processFailed')
  if (props.result) return t('phraseTranslate.processCompleted')
  if (props.stage) return t(stageLabels[props.stage])
  return t('phraseTranslate.processStarting')
})

const sourceCode = computed(() => props.sourceLanguage?.code ?? props.result?.source_lang_code ?? '')

const targetCode = computed(() => props.result?.target_locale_code ?? props.targetLocaleCode)

const sourceConfidence = computed(() => {
  const confidence = props.sourceLanguage?.confidence
  return typeof confidence === 'number' ? `${Math.round(confidence * 100)}%` : ''
})

const evidenceTotal = computed(() => {
  if (!props.evidence) return 0
  return props.evidence.items.length + props.evidence.omittedCount
})

const evidencePreview = computed(() => props.evidence?.items.slice(0, 3) ?? [])

const evidenceRemaining = computed(() => {
  if (!props.evidence) return 0
  return Math.max(0, evidenceTotal.value - evidencePreview.value.length)
})

const referenceLocaleCodes = computed(() => {
  const codes = new Set<string>()
  for (const item of props.evidence?.items ?? []) {
    for (const code of item.reference_locale_codes ?? []) codes.add(code)
  }
  return [...codes]
})

const evidenceStatusLabel = computed(() => {
  if (!props.evidence) return ''
  if (props.evidence.retrievalStatus === 'failed' || props.evidence.degraded) {
    return t('phraseTranslate.processEvidenceFailed')
  }
  if (props.evidence.retrievalStatus === 'skipped') return t('phraseTranslate.processEvidenceSkipped')
  if (props.evidence.retrievalStatus === 'no_match') return t('phraseTranslate.processEvidenceNoMatch')
  return ''
})

const resolutionLabel = computed(() => {
  if (!props.result) return ''
  if (props.result.resolution === 'exact_lookup') {
    return t('phraseTranslate.processResolutionExact')
  }
  if (props.result.model_only) return t('phraseTranslate.processResolutionModelOnly')
  return t('phraseTranslate.processResolutionAssisted')
})

watch(
  () => props.isStreaming,
  (isStreaming) => {
    // A new request should be inspectable immediately; after that, preserve
    // the user's choice to collapse the completed process.
    if (isStreaming) processOpen.value = true
  },
)

function syncProcessOpen(event: Event) {
  processOpen.value = (event.currentTarget as HTMLDetailsElement).open
}

const currentIndex = computed(() => (props.stage ? stages.value.indexOf(props.stage) : -1))

function stateOf(stage: TranslationStage): 'done' | 'active' | 'pending' {
  if (props.result) return 'done'
  const index = stages.value.indexOf(stage)
  if (index < 0 || currentIndex.value < 0) return 'pending'
  if (index < currentIndex.value) return 'done'
  if (index === currentIndex.value) return 'active'
  return 'pending'
}
</script>

<template>
  <div class="translation-progress" :data-stage="stage ?? ''">
    <details
      class="translation-process"
      :open="processOpen"
      @toggle="syncProcessOpen"
    >
      <summary class="process-summary">
        <span class="process-heading">{{ t('phraseTranslate.processHeading') }}</span>
        <span class="process-current">{{ currentLabel }}</span>
      </summary>

      <div class="process-body">
        <p v-if="error" class="progress-error" role="alert" aria-live="assertive">
          {{ error.message || t('phraseTranslate.errorGeneric') }}
        </p>
        <p v-else class="process-status" role="status" aria-live="polite">
          {{ currentLabel }}
        </p>

        <ol class="stage-list" :aria-label="t('phraseTranslate.processHeading')">
          <li
            v-for="item in stages"
            :key="item"
            class="stage"
            :data-state="stateOf(item)"
            :aria-current="stateOf(item) === 'active' ? 'step' : undefined"
          >
            <Check v-if="stateOf(item) === 'done'" :size="16" class="stage-icon" aria-hidden="true" />
            <LoaderCircle
              v-else-if="stateOf(item) === 'active'"
              :size="16"
              class="stage-icon"
              :class="{ 'stage-spin': isStreaming }"
              aria-hidden="true"
            />
            <Circle v-else :size="16" class="stage-icon" aria-hidden="true" />
            <span class="stage-text">{{ t(stageLabels[item]) }}</span>
          </li>
        </ol>

        <dl v-if="sourceCode || targetCode || segmentationSpans !== null || evidence" class="process-details">
          <div v-if="sourceCode" class="process-detail-row">
            <dt>{{ t('phraseTranslate.processSource') }}</dt>
            <dd>
              <code>{{ sourceCode }}</code>
              <span v-if="sourceConfidence"> · {{ t('phraseTranslate.processConfidence', { confidence: sourceConfidence }) }}</span>
            </dd>
          </div>
          <div v-if="targetCode" class="process-detail-row">
            <dt>{{ t('phraseTranslate.processTarget') }}</dt>
            <dd><code>{{ targetCode }}</code></dd>
          </div>
          <div v-if="referenceLocaleCodes.length" class="process-detail-row">
            <dt>{{ t('phraseTranslate.processReferenceLocale') }}</dt>
            <dd><code>{{ referenceLocaleCodes.join(', ') }}</code></dd>
          </div>
          <div v-if="evidence" class="process-detail-row">
            <dt>{{ t('phraseTranslate.processEvidence') }}</dt>
            <dd>
              {{ t('phraseTranslate.evidenceCount', { count: evidenceTotal }) }}
              <span v-if="evidenceStatusLabel"> · {{ evidenceStatusLabel }}</span>
            </dd>
          </div>
        </dl>

        <section
          v-if="segmentationSpans !== null"
          class="process-segmentation"
          aria-labelledby="process-segmentation-heading"
        >
          <div class="process-section-heading">
            <h3 id="process-segmentation-heading" class="process-label">
              {{ t('phraseTranslate.processSegmentation') }}
            </h3>
            <span class="process-section-count">
              {{ t('phraseTranslate.processSegmentationCount', { count: segmentationSpans.length }) }}
            </span>
          </div>
          <ul v-if="segmentationSpans.length" class="segmentation-list">
            <li
              v-for="span in segmentationSpans"
              :key="`${span.start}:${span.end}:${span.text}`"
              class="segmentation-item"
            >
              <span class="segmentation-text">{{ span.text }}</span>
              <span class="segmentation-meta">
                <code class="segmentation-reason">{{ span.reason }}</code>
                <span>{{ t('phraseTranslate.processConfidence', { confidence: confidenceLabel(span.confidence) }) }}</span>
                <span>{{ t('phraseTranslate.processSpanOffset', { start: span.start, end: span.end }) }}</span>
              </span>
            </li>
          </ul>
          <p v-else class="process-empty">{{ t('phraseTranslate.processNoSegmentation') }}</p>
        </section>

        <section v-if="translation" class="process-output" aria-labelledby="process-output-heading">
          <h3 id="process-output-heading" class="process-label">{{ t('phraseTranslate.processDraft') }}</h3>
          <p class="process-preview">{{ translation }}</p>
        </section>

        <section v-if="evidencePreview.length" class="process-evidence-block" aria-labelledby="process-evidence-heading">
          <div class="process-section-heading">
            <h3 id="process-evidence-heading" class="process-label">{{ t('phraseTranslate.processRetrieval') }}</h3>
            <span class="process-section-count">
              {{ t('phraseTranslate.evidenceCount', { count: evidenceTotal }) }}
            </span>
          </div>
          <ul class="process-evidence" :aria-label="t('phraseTranslate.evidenceHeading')">
            <li
              v-for="(item, index) in evidencePreview"
              :key="`${item.source_text}:${item.target_text}:${item.path_type}:${index}`"
              class="process-evidence-item"
            >
              <span class="process-evidence-source">{{ item.source_text }}</span>
              <span class="process-evidence-arrow" aria-hidden="true">→</span>
              <span class="process-evidence-target">{{ item.target_text }}</span>
            </li>
            <li v-if="evidenceRemaining > 0" class="process-evidence-more">
              {{ t('phraseTranslate.processMoreEvidence', { count: evidenceRemaining }) }}
            </li>
          </ul>
        </section>

        <p v-if="result" class="process-resolution">
          <span class="process-label">{{ t('phraseTranslate.processResolution') }}</span>
          {{ resolutionLabel }}
        </p>

        <p
          v-if="!sourceCode && segmentationSpans === null && !evidence && !translation && !result && !error"
          class="process-empty"
        >
          {{ t('phraseTranslate.processWaiting') }}
        </p>
      </div>
    </details>
  </div>
</template>

<style scoped>
.translation-progress {
  min-width: 0;
}
.translation-process {
  min-width: 0;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface-2);
}
.process-summary {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  min-width: 0;
  min-height: 44px;
  padding: 0 12px;
  cursor: pointer;
  list-style-position: outside;
}
.process-summary:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.process-heading,
.process-label {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--faint);
}
.process-current {
  min-width: 0;
  overflow-wrap: anywhere;
  color: var(--muted);
  font-size: 13px;
  text-align: right;
}
.process-body {
  display: grid;
  gap: 12px;
  min-width: 0;
  padding: 0 12px 12px;
  border-top: 1px solid var(--border);
}
.process-status {
  margin: 10px 0 0;
  color: var(--muted);
  font-size: 12px;
}
.stage-list {
  display: grid;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.stage {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
  color: var(--muted);
  font-size: 13px;
}
.stage[data-state="done"] {
  color: var(--fg);
}
.stage[data-state="active"] {
  color: var(--fg);
  font-weight: 600;
}
.stage-icon {
  flex: none;
}
.stage-spin {
  animation: stage-spin 1s linear infinite;
}
.process-details {
  display: grid;
  gap: 6px;
  margin: 0;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.process-detail-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 8px;
  min-width: 0;
  font-size: 12px;
}
.process-detail-row dt {
  min-width: 0;
  color: var(--muted);
}
.process-detail-row dd {
  min-width: 0;
  margin: 0;
  overflow-wrap: anywhere;
  color: var(--fg);
  text-align: right;
}
.process-detail-row code {
  font-family: var(--mono);
  font-size: 11px;
}
.process-segmentation,
.process-evidence-block {
  display: grid;
  gap: 8px;
  min-width: 0;
}
.process-section-heading {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
  min-width: 0;
}
.process-section-heading h3 {
  margin: 0;
}
.process-section-count {
  flex: none;
  color: var(--muted);
  font-size: 12px;
}
.segmentation-list {
  display: grid;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.segmentation-item {
  display: grid;
  gap: 4px;
  min-width: 0;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.segmentation-text {
  min-width: 0;
  color: var(--fg);
  font-size: 14px;
  font-weight: 600;
  overflow-wrap: anywhere;
}
.segmentation-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  min-width: 0;
  color: var(--muted);
  font-size: 11px;
}
.segmentation-reason {
  font-family: var(--mono);
  color: var(--accent);
}
.process-output {
  display: grid;
  gap: 6px;
  min-width: 0;
}
.process-output h3 {
  margin: 0;
}
.process-preview {
  margin: 0;
  padding: 10px;
  border-left: 2px solid var(--accent);
  background: var(--surface);
  color: var(--fg);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.process-evidence {
  display: grid;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.process-evidence-item {
  display: flex;
  align-items: baseline;
  gap: 6px;
  min-width: 0;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  color: var(--fg);
  font-size: 12px;
  font-weight: 600;
}
.process-evidence-source,
.process-evidence-target {
  min-width: 0;
  overflow-wrap: anywhere;
}
.process-evidence-arrow {
  flex: none;
  color: var(--muted);
}
.process-evidence-more,
.process-empty,
.process-resolution {
  margin: 0;
  color: var(--muted);
  font-size: 12px;
}
.process-resolution {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: baseline;
}
@keyframes stage-spin {
  to {
    transform: rotate(360deg);
  }
}
.progress-error {
  margin: 10px 0 0;
  color: var(--down);
  font-size: 13px;
}
@media (max-width: 480px) {
  .process-summary {
    align-items: flex-start;
    flex-direction: column;
    justify-content: center;
    gap: 2px;
    padding-block: 8px;
  }
  .process-current {
    text-align: left;
  }
  .process-detail-row {
    grid-template-columns: 1fr;
    gap: 2px;
  }
  .process-detail-row dd {
    text-align: left;
  }
}
@media (prefers-reduced-motion: reduce) {
  .stage-spin {
    animation: none;
  }
}
</style>
