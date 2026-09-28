<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { LoaderCircle } from 'lucide-vue-next'
import type { TranslationResult, TranslationStage } from '@/api/translation'
const props = defineProps<{
  stage: TranslationStage | null
  isStreaming: boolean
  error: { message?: string } | null
  result: TranslationResult | null
}>()
const { t } = useI18n()
const labels = { analyzing: 'phraseTranslate.stageAnalyzing', retrieving: 'phraseTranslate.stageRetrieving', generating: 'phraseTranslate.stageGenerating' } as const
const currentLabel = computed(() => {
  if (props.error) return props.error.message || t('phraseTranslate.errorGeneric')
  if (props.result) return t('phraseTranslate.processCompleted')
  if (!props.isStreaming) return t('phraseTranslate.processStopped')
  return props.stage ? t(labels[props.stage]) : t('phraseTranslate.processStarting')
})
</script>
<template>
  <div class="translation-progress" :data-stage="stage ?? ''">
    <LoaderCircle v-if="isStreaming" class="stage-spin" :size="16" aria-hidden="true" />
    <p :class="error ? 'progress-error' : 'process-status'" :role="error ? 'alert' : 'status'" :aria-live="error ? 'assertive' : 'polite'">{{ currentLabel }}</p>
  </div>
</template>
<style scoped>
.translation-progress { display: flex; align-items: center; gap: 8px; min-width: 0; color: var(--muted); font-size: var(--text-meta); }
.translation-progress p { margin: 0; }
.progress-error { color: var(--down); }
.stage-spin { flex: none; animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) { .stage-spin { animation: none; } }
</style>
