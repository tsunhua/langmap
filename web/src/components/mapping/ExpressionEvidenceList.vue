<script setup lang="ts">
import { computed } from 'vue'
import type { ExpressionReading, LocaleAttestation } from '@/api/expressions'

const props = defineProps<{ attestations: LocaleAttestation[]; readings: ExpressionReading[] }>()

const attestations = computed(() => [...props.attestations].sort((a, b) =>
  a.language_locale_code.localeCompare(b.language_locale_code) || a.created_at.localeCompare(b.created_at) || a.id.localeCompare(b.id),
))
const readings = computed(() => [...props.readings].sort((a, b) =>
  a.language_locale_code.localeCompare(b.language_locale_code) || a.scheme.localeCompare(b.scheme) || a.created_at.localeCompare(b.created_at) || a.id.localeCompare(b.id),
))
</script>

<template>
  <section v-if="attestations.length || readings.length" class="evidence" aria-label="Expression evidence">
    <h4>Evidence</h4>
    <ul>
      <li v-for="attestation in attestations" :key="attestation.id" :data-evidence-code="attestation.language_locale_code">
        <span class="evidence-kind">Locale</span> <span :title="attestation.language_locale_code">{{ attestation.locale_display_name || attestation.language_locale_code }}</span>
      </li>
      <li v-for="reading in readings" :key="reading.id" :data-evidence-code="`${reading.language_locale_code} / ${reading.scheme}`">
        <span class="evidence-kind">Reading</span> <span :title="`${reading.language_locale_code} / ${reading.scheme}`">{{ reading.locale_display_name || reading.language_locale_code }}</span> / {{ reading.scheme }}: {{ reading.value }}
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
