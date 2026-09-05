<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { readingSchemeLabel } from '@/utils/readingLabel'
import { groupReadings, hasMultipleReadingSchemes, uniqueReadingLocaleLabels, uniqueReadingLocaleCodes } from '@/utils/readingGroups'
import type { ExpressionLocale, ExpressionReading } from '@/api/expressions'

const props = defineProps<{ locales?: ExpressionLocale[]; attestations?: ExpressionLocale[]; readings: ExpressionReading[] }>()
const { t } = useI18n()

const locales = computed(() => [...(props.locales ?? props.attestations ?? [])].sort((a, b) =>
  a.language_locale_code.localeCompare(b.language_locale_code),
))
const readingGroups = computed(() => groupReadings(props.readings))
const showReadingScheme = computed(() => hasMultipleReadingSchemes(readingGroups.value))

function readingLocalesLabel(readings: ExpressionReading[]) {
  return uniqueReadingLocaleLabels(readings).join(', ')
}

function readingLocalesTitle(readings: ExpressionReading[]) {
  return uniqueReadingLocaleCodes(readings).join(', ')
}
</script>

<template>
  <section v-if="locales.length || readingGroups.length" class="evidence" :aria-label="t('components.evidence')">
    <h4>{{ t('components.evidence') }}</h4>
    <ul>
      <li v-for="locale in locales" :key="locale.language_locale_code" :data-evidence-code="locale.language_locale_code">
        <span class="evidence-kind">{{ t('components.locale') }}</span> <span :title="locale.language_locale_code">{{ locale.locale_display_name || locale.language_locale_code }}</span>
      </li>
      <li
        v-for="group in readingGroups"
        :key="`${group.scheme}:${group.value}`"
        :data-evidence-code="`${group.scheme} / ${group.value}`"
        class="rx-item"
      >
        <span class="evidence-kind rx-kind">{{ t('components.reading') }}</span>
        <span class="rx-value">{{ group.value }}</span>
        <span class="rx-meta" :title="readingLocalesTitle(group.readings)">
          <span v-if="showReadingScheme" class="rx-scheme">{{ readingSchemeLabel(group.scheme) }} · </span>
          <span class="rx-locales">({{ readingLocalesLabel(group.readings) }})</span>
        </span>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.evidence { border-top: 1px solid var(--border); padding-top: 10px; }
h4 { margin: 0; font-size: 12px; font-family: var(--mono); letter-spacing: .04em; text-transform: uppercase; color: var(--faint); }
ul { list-style: none; padding: 0; margin: 6px 0 0; display: grid; gap: 4px; }
li { min-width: 0; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }
.evidence-kind { color: var(--muted); font-family: var(--mono); font-size: 10px; }
.rx-item {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  align-items: baseline;
  gap: 2px 8px;
  min-width: 0;
}
.rx-kind { flex: none; }
.rx-value { min-width: 0; font-weight: 600; color: var(--fg); overflow-wrap: anywhere; }
.rx-meta {
  grid-column: 2;
  min-width: 0;
  font-family: var(--mono);
  font-size: 11px;
  color: var(--muted);
  line-height: 1.45;
  overflow-wrap: anywhere;
}
.rx-scheme { color: var(--faint); }
.rx-locales { color: var(--muted); }
</style>
