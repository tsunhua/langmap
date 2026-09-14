<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Check, Circle, LoaderCircle } from 'lucide-vue-next'
import type { TranslationMode, TranslationStage } from '@/api/translation'

const props = defineProps<{
  stage: TranslationStage | null
  mode: TranslationMode | null
  isStreaming: boolean
  error: { message?: string } | null
}>()

const { t } = useI18n()

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

const currentIndex = computed(() => (props.stage ? stages.value.indexOf(props.stage) : -1))

function stateOf(stage: TranslationStage): 'done' | 'active' | 'pending' {
  const index = stages.value.indexOf(stage)
  if (index < 0 || currentIndex.value < 0) return 'pending'
  if (index < currentIndex.value) return 'done'
  if (index === currentIndex.value) return 'active'
  return 'pending'
}
</script>

<template>
  <div
    class="translation-progress"
    :role="error ? 'alert' : 'status'"
    aria-live="polite"
    :data-stage="stage ?? ''"
  >
    <p v-if="error" class="progress-error">{{ error.message || t('phraseTranslate.errorGeneric') }}</p>
    <ol v-else class="stage-list">
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
  </div>
</template>

<style scoped>
.translation-progress {
  min-width: 0;
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
@keyframes stage-spin {
  to {
    transform: rotate(360deg);
  }
}
.progress-error {
  margin: 0;
  color: var(--down);
  font-size: 13px;
}
@media (prefers-reduced-motion: reduce) {
  .stage-spin {
    animation: none;
  }
}
</style>
