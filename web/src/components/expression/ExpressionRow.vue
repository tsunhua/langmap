<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { SearchFormOf } from '@/api/expressions'

const props = withDefaults(defineProps<{
  id: string
  text: string
  lang_code?: string
  language_profile_code?: string
  language_name?: string
  region_name?: string
  mapping_count?: number
  source_type?: string
  showLanguage?: boolean
  form_of?: SearchFormOf[]
}>(), { showLanguage: true, form_of: () => [] })

const { t } = useI18n()

const formSummaries = computed(() =>
  (props.form_of ?? []).map((item) => {
    const features = item.features.map((feature) => feature.name).filter(Boolean).join(' ')
    return {
      lemmaId: item.lemma.id,
      label: features ? `${features} ← ${item.lemma.text}` : `← ${item.lemma.text}`,
      aria: t('morphology.formOfAria', {
        lemma: item.lemma.text,
        features: features || item.lemma.text,
      }),
    }
  }),
)
</script>

<template>
  <router-link :to="`/mapping/${id}`" :class="['ex-row', { 'ex-row--no-lang': !showLanguage }]">
    <span class="ex-main">
      <span class="ex-tx">{{ text }}</span>
      <span v-if="formSummaries.length" class="ex-forms">
        <span
          v-for="item in formSummaries"
          :key="item.lemmaId"
          class="ex-form"
          :aria-label="item.aria"
        >{{ item.label }}</span>
      </span>
    </span>
    <span v-if="showLanguage" class="ex-lc"><span class="lang-badge" :title="language_profile_code || lang_code">{{ language_name || language_profile_code || lang_code }}</span></span>
    <span class="ex-region">{{ region_name || '-' }}</span>
    <span v-if="source_type" class="ex-src">
      <span :class="['src-tag', source_type]">{{ source_type }}</span>
    </span>
    <span v-if="mapping_count !== undefined" class="ex-maps">{{ mapping_count }}</span>
  </router-link>
</template>

<style scoped>
.ex-row {
  display: grid;
  grid-template-columns: minmax(0,1fr) 70px 100px auto 60px;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-bottom: 1px solid var(--border);
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.ex-row--no-lang { grid-template-columns: minmax(0,1fr) 100px auto 60px; }
.ex-row:last-child { border-bottom: none; }
.ex-row:hover { background: var(--bg); }
.ex-row:hover .ex-tx { color: var(--accent); }
.ex-main { min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.ex-tx { font-size: 18px; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ex-forms { min-width: 0; display: flex; flex-wrap: wrap; gap: 2px 10px; }
.ex-form { font-size: 12px; color: var(--muted); min-width: 0; overflow-wrap: anywhere; }
.ex-region { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ex-maps { font-family: var(--mono); font-variant-numeric: tabular-nums; color: var(--accent); font-size: 15px; text-align: right; white-space: nowrap; }
@media (max-width: 640px) {
  .ex-row { grid-template-columns: 1fr auto auto; gap: 6px; padding: 8px 10px; }
  .ex-row--no-lang { grid-template-columns: 1fr auto; }
  .ex-region, .ex-src { display: none; }
}
</style>
