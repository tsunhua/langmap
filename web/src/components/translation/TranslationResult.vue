<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { X } from 'lucide-vue-next'
import type { TranslationEvidence, TranslationResult as TranslationResultData } from '@/api/translation'
import { translationTerms, type TranslationTerm } from '@/utils/translationTerms'
import { useTranslationReference } from '@/composables/useTranslationReference'
import { contentRevision } from '@/utils/contentRevision'

const props = withDefaults(defineProps<{
  translation: string
  result: TranslationResultData | null
  evidence?: TranslationEvidence[]
  sourceLangCode?: string | null
}>(), { evidence: () => [], sourceLangCode: null })

const { t } = useI18n()
const terms = computed(() =>
  translationTerms(
    props.translation,
    props.evidence.filter(item => item.target_text !== props.translation).map(item => item.target_text),
  ),
)
const lookup = useTranslationReference()
const { selected, reference, loading, failed } = lookup
const translationHost = ref<HTMLElement | null>(null)
const neighbors = computed(() =>
  reference.value?.graph?.nodes.filter(node => node.expression_id !== reference.value?.graph?.root_id) ?? [],
)

watch(
  () => [props.translation, props.result, props.evidence, props.sourceLangCode, contentRevision.value],
  () => lookup.reset(),
)

function selectTerm(term: TranslationTerm) {
  if (!props.result) return
  if (selected.value?.start === term.start && selected.value.text === term.text) {
    closeReference()
    return
  }
  void lookup.select(
    term,
    props.evidence,
    props.result.target_locale_code,
    props.sourceLangCode ?? props.result.source_lang_code,
  )
}

function closeReference() {
  if (!selected.value) return
  const start = selected.value.start
  lookup.close()
  void nextTick(() => translationHost.value?.querySelector<HTMLButtonElement>(`[data-start="${start}"]`)?.focus())
}
</script>

<template>
  <section class="translation-result" :aria-label="t('phraseTranslate.resultHeading')" @keydown.esc="closeReference">
    <h3 class="result-heading">{{ t('phraseTranslate.resultHeading') }}</h3>
    <p v-if="!result" class="translation" dir="auto">{{ translation }}</p>
    <p v-else ref="translationHost" class="translation" dir="auto">
      <template v-for="term in terms" :key="`${term.start}:${term.end}`">
        <button
          v-if="term.interactive"
          type="button"
          class="translation-term"
          :class="{ selected: selected?.start === term.start }"
          :data-term="term.text"
          :data-start="term.start"
          :aria-label="t('phraseTranslate.lookupTerm', { term: term.text })"
          :aria-expanded="selected?.start === term.start"
          :aria-controls="selected?.start === term.start ? 'translation-reference' : undefined"
          @click="selectTerm(term)"
        >{{ term.text }}</button><span v-else>{{ term.text }}</span>
      </template>
    </p>
    <p v-if="result" class="term-hint">{{ t('phraseTranslate.termHint') }}</p>

    <section
      v-if="selected"
      id="translation-reference"
      class="reference-panel"
      aria-labelledby="reference-heading"
      :aria-busy="loading"
    >
      <div class="reference-header">
        <h4 id="reference-heading" dir="auto">{{ selected.text }}</h4>
        <button type="button" class="btn btn-icon" :aria-label="t('phraseTranslate.closeReference')" @click="closeReference">
          <X :size="18" aria-hidden="true" />
        </button>
      </div>
      <p v-if="loading" role="status">{{ t('phraseTranslate.referenceLoading') }}</p>
      <p v-else-if="failed" role="status">{{ t('phraseTranslate.referenceFailed') }}</p>
      <template v-else>
        <ul v-if="reference?.evidence.length" class="mapping-list">
          <li v-for="(item, index) in reference.evidence" :key="index" dir="auto">
            <span>{{ item.source_text }}</span>
            <span class="mapping-arrow" aria-hidden="true">↔</span>
            <span>{{ item.target_text }}</span>
          </li>
        </ul>
        <ul v-else-if="neighbors.length" class="mapping-list">
          <li v-for="neighbor in neighbors" :key="neighbor.expression_id" dir="auto">
            <span>{{ neighbor.text }}</span>
            <span class="mapping-language">{{ neighbor.language_name || neighbor.lang_code }}</span>
          </li>
        </ul>
        <p v-else>{{ t('phraseTranslate.evidenceEmpty') }}</p>
      </template>
    </section>
  </section>
</template>

<style scoped>
.translation-result {
  display: grid;
  gap: 10px;
  min-width: 0;
  padding: 0;
  border: 0;
  background: transparent;
}
.result-heading {
  margin: 0;
  color: var(--muted);
  font-size: 13px;
  font-weight: 600;
}
.translation {
  margin: 0;
  min-width: 0;
  color: var(--fg);
  font-size: 20px;
  line-height: 1.5;
  overflow-wrap: anywhere;
  white-space: pre-wrap;
}
.translation-term {
  display: inline-block;
  min-width: 0;
  min-height: 44px;
  max-width: 100%;
  padding: 0;
  border: 0;
  border-radius: var(--r);
  background: transparent;
  color: inherit;
  font: inherit;
  text-decoration: underline dotted color-mix(in oklch, var(--accent) 70%, transparent);
  text-underline-offset: 3px;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  cursor: pointer;
  text-align: inherit;
}
.translation-term:hover, .translation-term.selected { background: var(--accent-soft); color: var(--accent); }
.translation-term:focus-visible, .reference-panel button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.term-hint { margin: 0; color: var(--muted); font-size: var(--text-meta); }
.reference-panel {
  min-width: 0;
  padding-top: 10px;
  border-top: 1px solid var(--border);
  overflow-wrap: anywhere;
}
.reference-header { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.reference-header h4 { min-width: 0; margin: 0; font-size: 16px; }
.reference-panel p { margin: 8px 0 0; white-space: pre-wrap; }
.reference-panel .btn-icon { min-width: 44px; min-height: 44px; }
.mapping-list {
  display: grid;
  gap: 8px;
  margin: 8px 0 0;
  padding: 0;
  list-style: none;
}
.mapping-list li {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr);
  align-items: center;
  gap: 8px;
  min-width: 0;
  padding: 8px 0;
  border-top: 1px solid var(--border);
  line-height: 1.4;
  overflow-wrap: anywhere;
}
.mapping-list li:first-child { border-top: 0; }
.mapping-arrow { color: var(--muted); }
.mapping-language { color: var(--muted); font-size: var(--text-meta); text-align: end; }
@media (max-width: 480px) {
  .mapping-list li { grid-template-columns: minmax(0, 1fr); gap: 4px; }
  .mapping-arrow { display: none; }
  .mapping-language { text-align: start; }
}
</style>
