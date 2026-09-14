<script setup lang="ts">
import { computed, onUnmounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { Copy, Pencil, RotateCcw, Send } from 'lucide-vue-next'
import type { TranslationResult as TranslationResultData } from '@/api/translation'

const props = defineProps<{
  translation: string
  result: TranslationResultData | null
  alternatives: string[]
}>()

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
const shownAlternatives = computed(() => props.alternatives.slice(0, 2))

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
  <section class="translation-result" :aria-label="t('phraseTranslate.resultHeading')">
    <h3 class="result-heading">{{ t('phraseTranslate.resultHeading') }}</h3>
    <p class="translation">{{ translation }}</p>

    <p v-if="status" class="result-status">
      <span v-if="status === 'exact'" class="badge">{{ t('phraseTranslate.exactMatch') }}</span>
      <span v-else-if="status === 'model_only'" class="badge">{{ t('phraseTranslate.modelOnly') }}</span>
      <span v-else class="badge badge-ai">{{ t('phraseTranslate.aiAssistedBadge') }}</span>
    </p>

    <div v-if="shownAlternatives.length" class="alternatives">
      <h4 class="alternatives-heading">{{ t('phraseTranslate.referenceTranslations') }}</h4>
      <ul>
        <li v-for="(alternative, index) in shownAlternatives" :key="index">{{ alternative }}</li>
      </ul>
    </div>

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
</style>
