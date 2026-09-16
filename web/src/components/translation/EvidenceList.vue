<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { TranslationEvidence, TranslationEvidenceRetrievalStatus } from '@/api/translation'

defineProps<{
  items: TranslationEvidence[]
  omittedCount?: number
  degraded?: boolean
  retrievalStatus?: TranslationEvidenceRetrievalStatus
}>()

const { t } = useI18n()

function pathLabel(item: TranslationEvidence): string {
  if (item.path_type === 'direct') return `${item.source_text} → ${item.target_text}`
  return `${item.source_text} → (${item.pivot_lang_code ?? ''}) → ${item.target_text}`
}
</script>

<template>
  <details class="evidence-list">
    <summary class="evidence-summary">
      <span class="evidence-heading">{{ t('phraseTranslate.evidenceHeading') }}</span>
      <span class="evidence-count">{{ t('phraseTranslate.evidenceCount', { count: items.length }) }}</span>
    </summary>

    <p v-if="retrievalStatus === 'failed' || degraded" class="evidence-degraded">
      {{ t('phraseTranslate.evidenceDegraded') }}
    </p>
    <p v-else-if="retrievalStatus === 'skipped'" class="evidence-degraded">
      {{ t('phraseTranslate.evidenceSkipped') }}
    </p>
    <p v-if="(omittedCount ?? 0) > 0" class="evidence-omitted">
      {{ t('phraseTranslate.evidenceOmitted', { count: omittedCount }) }}
    </p>
    <p v-if="!items.length" class="evidence-empty">{{ t('phraseTranslate.evidenceEmpty') }}</p>

    <ul v-else class="evidence-items">
      <li
        v-for="(item, index) in items"
        :key="`${item.source_text}:${item.target_text}:${item.path_type}:${index}`"
        class="evidence-item"
      >
        <p class="evidence-pair">
          <span class="evidence-source">{{ item.source_text }}</span>
          <span class="evidence-arrow" aria-hidden="true">→</span>
          <span class="evidence-target">{{ item.target_text }}</span>
        </p>
        <p class="evidence-path">
          <span class="evidence-path-label">{{ t('phraseTranslate.evidencePath') }}:</span>
          <span class="evidence-path-value">{{ pathLabel(item) }}</span>
          <span class="evidence-path-type">
            {{ item.path_type === 'direct' ? t('phraseTranslate.evidenceDirect') : t('phraseTranslate.evidenceTwoHop') }}
          </span>
        </p>
        <p class="evidence-meta">
          <span class="evidence-match">
            {{ item.match_type === 'exact' ? t('phraseTranslate.matchExact') : t('phraseTranslate.matchPrefix') }}
          </span>
          <span
            v-if="item.source_markers.length"
            class="evidence-markers"
            :title="item.source_markers.join(', ')"
          >
            {{ item.source_markers.join(' · ') }}
          </span>
          <span v-if="item.reference_locale_codes?.length" class="evidence-locales">
            {{ t('phraseTranslate.evidenceReferenceLocale') }}: {{ item.reference_locale_codes.join(' · ') }}
          </span>
        </p>
      </li>
    </ul>
  </details>
</template>

<style scoped>
.evidence-list {
  min-width: 0;
  border-top: 1px solid var(--border);
  padding-top: 10px;
}
.evidence-summary {
  display: flex;
  align-items: baseline;
  gap: 8px;
  min-height: 44px;
  cursor: pointer;
  min-width: 0;
}
.evidence-heading {
  font-size: 12px;
  font-family: var(--mono);
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--faint);
}
.evidence-count {
  font-size: 12px;
  color: var(--muted);
}
.evidence-degraded {
  margin: 6px 0;
  font-size: 12px;
  color: var(--muted);
}
.evidence-empty {
  margin: 6px 0;
  font-size: 12px;
  color: var(--muted);
}
.evidence-omitted {
  margin: 6px 0;
  font-size: 12px;
  color: var(--muted);
}
.evidence-items {
  display: grid;
  gap: 10px;
  margin: 8px 0 0;
  padding: 0;
  list-style: none;
}
.evidence-item {
  display: grid;
  gap: 4px;
  min-width: 0;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.evidence-pair {
  display: flex;
  align-items: baseline;
  gap: 6px;
  margin: 0;
  min-width: 0;
  font-weight: 600;
  color: var(--fg);
}
.evidence-source,
.evidence-target {
  min-width: 0;
  overflow-wrap: anywhere;
}
.evidence-arrow {
  flex: none;
  color: var(--muted);
}
.evidence-path,
.evidence-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  margin: 0;
  min-width: 0;
  font-size: 12px;
  color: var(--muted);
}
.evidence-path-value {
  min-width: 0;
  overflow-wrap: anywhere;
}
.evidence-path-label {
  color: var(--faint);
}
.evidence-path-type {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--faint);
}
.evidence-markers {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--muted);
}
</style>
