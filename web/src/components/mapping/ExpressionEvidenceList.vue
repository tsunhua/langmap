<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { regionFromLocale } from '@/utils/localeRegion'
import { readingSchemeLabel } from '@/utils/readingLabel'
import type { ExpressionLocale, ExpressionReading } from '@/api/expressions'

const props = defineProps<{ locales?: ExpressionLocale[]; attestations?: ExpressionLocale[]; readings: ExpressionReading[] }>()
const { t } = useI18n()

const locales = computed(() => [...(props.locales ?? props.attestations ?? [])].sort((a, b) =>
  a.language_locale_code.localeCompare(b.language_locale_code),
))
const readings = computed(() => [...props.readings].sort((a, b) =>
  a.language_locale_code.localeCompare(b.language_locale_code) || a.scheme.localeCompare(b.scheme) || a.value.localeCompare(b.value),
))

function readingLocaleLabel(reading: ExpressionReading) {
  const region = regionFromLocale(reading.language_locale_code)
  if (reading.locale_display_name) return region ? `${region} · ${reading.locale_display_name}` : reading.locale_display_name
  return region ?? reading.language_locale_code
}
</script>

<template>
  <section v-if="locales.length || readings.length" class="evidence" :aria-label="t('components.evidence')">
    <h4>{{ t('components.evidence') }}</h4>
    <ul>
      <li v-for="locale in locales" :key="locale.language_locale_code" :data-evidence-code="locale.language_locale_code">
        <span class="evidence-kind">{{ t('components.locale') }}</span> <span :title="locale.language_locale_code">{{ locale.locale_display_name || locale.language_locale_code }}</span>
      </li>
      <li
        v-for="reading in readings"
        :key="`${reading.language_locale_code}:${reading.scheme}:${reading.value}`"
        :data-evidence-code="`${reading.language_locale_code} / ${reading.scheme}`"
        class="rx-item"
      >
        <span class="evidence-kind rx-kind">{{ t('components.reading') }}</span>
        <span class="rx-value" :title="`${reading.language_locale_code} / ${reading.scheme}`">{{ reading.value }}</span>
        <span class="rx-meta">{{ readingLocaleLabel(reading) }}<span class="rx-scheme">/ {{ readingSchemeLabel(reading.scheme) }}</span></span>
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
  display: flex;
  align-items: baseline;
  gap: 8px;
  min-width: 0;
  flex-wrap: wrap;
}
.rx-kind { flex: none; }
.rx-value { flex: 0 1 auto; font-weight: 600; color: var(--fg); }
.rx-meta {
  margin-left: auto;
  flex: none;
  font-family: var(--mono);
  font-size: 11px;
  color: var(--muted);
  white-space: nowrap;
}
.rx-scheme { color: var(--faint); margin-left: 6px; }
</style>
