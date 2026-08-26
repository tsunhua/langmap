<script setup lang="ts">
import { Star } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

defineProps<{
  id: string
  title: string
  author_username?: string
  section_count: number
  expression_count: number
  score: number
}>()
</script>

<template>
  <router-link :to="`/handbooks/${id}`" class="hb-card">
    <h3>{{ title }}</h3>
    <div class="hb-card-meta"><b>{{ section_count }}</b> {{ t('handbooks.sections') }} · <b>{{ expression_count }}</b> {{ t('components.expression') }}</div>
    <div class="hb-card-foot">
      <span v-if="author_username" class="hb-author">{{ author_username }}</span>
      <span class="hb-score"><Star :size="12" aria-hidden="true" /> {{ score }}</span>
    </div>
  </router-link>
</template>

<style scoped>
.hb-card {
  display: flex; flex-direction: column; gap: 8px;
  padding: 16px; background: var(--surface);
  border: 1px solid var(--border); border-radius: 8px;
  text-decoration: none; color: inherit;
  transition: border-color 0.12s, box-shadow 0.12s;
}
.hb-card:hover { border-color: color-mix(in oklch, var(--accent) 45%, var(--border)); box-shadow: 0 2px 6px oklch(0 0 0 / 0.05); }
.hb-card h3 { font-size: 15px; font-weight: 600; }
.hb-card-meta { font-family: var(--mono); font-size: 11px; color: var(--muted); }
.hb-card-meta b { color: var(--fg); font-weight: 500; }
.hb-card-foot {
  display: flex; justify-content: space-between; align-items: center;
  font-family: var(--mono); font-size: 10px; letter-spacing: 0.04em; text-transform: uppercase;
  color: var(--muted); margin-top: auto; padding-top: 8px; border-top: 1px solid var(--border);
}
.hb-score { color: var(--accent); }
</style>
