<script setup lang="ts">
import { ArrowLeftRight } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

defineProps<{
  id: string | number
  type?: string
  left_text: string
  left_lang: string
  right_text?: string
  right_lang?: string
  author?: string
  created_at?: string
}>()

function timeAgo(dateStr?: string): string {
  if (!dateStr) return ''
  const diff = Date.now() - new Date(dateStr).getTime()
  const min = Math.floor(diff / 60000)
  if (min < 1) return t('components.justNow')
  if (min < 60) return t('components.minutesAgo', { count: min })
  const hr = Math.floor(min / 60)
  if (hr < 24) return t('components.hoursAgo', { count: hr })
  return t('components.daysAgo', { count: Math.floor(hr / 24) })
}
</script>

<template>
  <router-link :to="`/mapping/${id}`" class="new-row">
    <span :class="['new-kind', { expr: type === 'expression' }]">
      {{ type === 'expression' ? t('components.expression') : t('components.mapping') }}
    </span>
    <span class="new-body">
      <span class="new-pair">
        <span class="tx">{{ left_text }}</span>
        <template v-if="type !== 'expression' && right_text">
          <span class="arrow"><ArrowLeftRight :size="12" aria-hidden="true" /></span>
          <span class="tx">{{ right_text }}</span>
        </template>
      </span>
      <span class="lang-badge">
        {{ type === 'expression' || !right_lang ? left_lang : `${left_lang} · ${right_lang}` }}
      </span>
    </span>
    <span class="new-meta">
      <template v-if="timeAgo(created_at)">{{ timeAgo(created_at) }} · </template>@{{ author || t('components.anonymous') }}
    </span>
  </router-link>
</template>

<style scoped>
.new-row {
  display: grid;
  grid-template-columns: 92px 1fr auto;
  gap: 12px;
  align-items: center;
  padding: 11px 0;
  border-bottom: 1px solid var(--border);
  color: inherit;
  text-decoration: none;
  cursor: pointer;
}
.new-row:last-child { border-bottom: none; }
.new-row:hover .tx { color: var(--accent); }
.new-kind {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--accent);
  border: 1px solid color-mix(in oklch, var(--accent) 40%, var(--border));
  padding: 2px 7px;
  border-radius: 2px;
  justify-self: start;
  background: var(--accent-soft);
}
.new-kind.expr { color: var(--edge); border-color: color-mix(in oklch, var(--edge) 35%, var(--border)); background: color-mix(in oklch, var(--edge) 8%, var(--surface)); }
.new-body { display: flex; align-items: baseline; gap: 8px; min-width: 0; flex-wrap: wrap; }
.new-pair {
  font-size: 14px;
  white-space: normal;
  overflow-wrap: anywhere;
  min-width: 0;
  flex: 1 1 auto;
}
.new-pair .arrow { color: var(--faint); margin: 0 4px; }
.new-pair .arrow { display: inline-flex; align-items: center; }
.new-pair .tx { font-weight: 500; transition: color 0.12s; }
.new-body .lang-badge { margin-left: auto; }
.new-meta {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  white-space: nowrap;
}
@media (max-width: 640px) {
  .new-row { grid-template-columns: auto 1fr; gap: 8px; }
  .new-meta { white-space: normal; grid-column: 1 / -1; }
  .new-kind { font-size: 8px; }
}
</style>
