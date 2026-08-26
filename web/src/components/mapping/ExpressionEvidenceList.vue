<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { ExpressionLocale, ExpressionReading } from '@/api/expressions'

const props = defineProps<{ locales?: ExpressionLocale[]; attestations?: ExpressionLocale[]; readings: ExpressionReading[] }>()
const { t } = useI18n()

const locales = computed(() => [...(props.locales ?? props.attestations ?? [])].sort((a, b) =>
  a.language_locale_code.localeCompare(b.language_locale_code),
))
const readings = computed(() => [...props.readings].sort((a, b) =>
  a.language_locale_code.localeCompare(b.language_locale_code) || a.scheme.localeCompare(b.scheme) || a.value.localeCompare(b.value),
))
</script>

<template>
  <section v-if="locales.length || readings.length" class="evidence" :aria-label="t('components.evidence')">
    <h4>{{ t('components.evidence') }}</h4>
    <ul>
      <li v-for="locale in locales" :key="locale.language_locale_code" :data-evidence-code="locale.language_locale_code">
        <span class="evidence-kind">{{ t('components.locale') }}</span> <span :title="locale.locale_display_name || locale.language_locale_code">{{ locale.language_locale_code }}<template v-if="locale.locale_display_name"> · {{ locale.locale_display_name }}</template></span>
      </li>
      <li v-for="reading in readings" :key="`${reading.language_locale_code}:${reading.scheme}:${reading.value}`" :data-evidence-code="`${reading.language_locale_code} / ${reading.scheme}`">
        <span class="evidence-kind">{{ t('components.reading') }}</span> <span :title="`${reading.language_locale_code} / ${reading.scheme}`">{{ reading.language_locale_code }}<template v-if="reading.locale_display_name"> · {{ reading.locale_display_name }}</template></span> / {{ reading.scheme }}: {{ reading.value }}
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
</style>
