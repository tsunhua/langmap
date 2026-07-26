<script setup lang="ts">
import { ArrowUpRight, MapPin, X } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import LangBadge from '@/components/expression/LangBadge.vue'
import HandbookRelationPreview from '@/components/handbook/HandbookRelationPreview.vue'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'

export interface HandbookExpressionDetail {
  id: number
  text: string
  language_code: string
  language_name?: string | null
  region_name?: string | null
  source_type?: string | null
}

defineProps<{
  expression: HandbookExpressionDetail | null
  loading: boolean
  error: string
  graph: MappingGraphResponse | null
  graphLoading: boolean
  graphError: string
}>()

defineEmits<{
  close: []
  selectExpression: [id: number]
}>()

const { t } = useI18n()

function sourceLabel(type?: string | null) {
  if (type === 'auth') return t('handbook.sourceAuthority')
  if (type === 'ai') return t('handbook.sourceAi')
  if (type === 'user') return t('handbook.sourceUser')
  return type || ''
}
</script>

<template>
  <aside
    class="hi-panel"
    :class="{ open: expression || loading || error }"
    :aria-label="t('handbook.expressionInfo')"
    :aria-hidden="!expression && !loading && !error"
  >
    <div class="hi-head">
      <span>{{ t('handbook.expressionInfo') }}</span>
      <button class="hi-close" type="button" :aria-label="t('handbook.closeExpressionInfo')" @click="$emit('close')">
        <X :size="16" aria-hidden="true" />
      </button>
    </div>

    <div v-if="loading" class="hi-status" role="status">
      <span class="hi-skeleton wide"></span>
      <span class="hi-skeleton"></span>
      <span class="hi-skeleton short"></span>
    </div>

    <p v-else-if="error" class="hi-error">{{ error }}</p>

    <div v-else-if="expression" class="hi-body">
      <div class="hi-title-row">
        <h2>{{ expression.text }}</h2>
        <LangBadge :code="expression.language_code" />
      </div>

      <dl class="hi-facts">
        <div>
          <dt>{{ t('handbook.locale') }}</dt>
          <dd>{{ expression.language_name || expression.language_code }}</dd>
        </div>
        <div v-if="expression.region_name">
          <dt>{{ t('handbook.region') }}</dt>
          <dd><MapPin :size="13" aria-hidden="true" />{{ expression.region_name }}</dd>
        </div>
        <div v-if="sourceLabel(expression.source_type)">
          <dt>{{ t('handbook.source') }}</dt>
          <dd>
            <span :class="['src-tag', expression.source_type]">
              {{ sourceLabel(expression.source_type) }}
            </span>
          </dd>
        </div>
      </dl>

      <HandbookRelationPreview
        :graph="graph"
        :loading="graphLoading"
        :error="graphError"
        @select="$emit('selectExpression', $event)"
      />

      <router-link :to="`/mapping/${expression.id}`" class="hi-detail-link">
        {{ t('handbook.viewFullGraph') }}
        <ArrowUpRight :size="15" aria-hidden="true" />
      </router-link>
    </div>

    <div v-else class="hi-empty">
      <p>{{ t('handbook.selectExpression') }}</p>
      <span>{{ t('handbook.expressionInfoHint') }}</span>
    </div>
  </aside>
</template>

<style scoped>
.hi-panel {
  position: sticky;
  top: calc(var(--bar-h) + 24px);
  align-self: start;
  min-width: 0;
  min-height: 220px;
  max-height: calc(100dvh - var(--bar-h) - 48px);
  overflow-y: auto;
  border-left: 1px solid var(--border);
  padding-left: 24px;
}
.hi-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 32px;
  margin-bottom: 20px;
  font-family: var(--mono);
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--muted);
}
.hi-close {
  display: none;
  width: 32px;
  height: 32px;
  place-items: center;
  border: 0;
  border-radius: var(--r);
  background: transparent;
  color: var(--muted);
  cursor: pointer;
}
.hi-close:hover { background: var(--surface-2); color: var(--fg); }
.hi-title-row { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.hi-title-row h2 {
  min-width: 0;
  font-size: 22px;
  line-height: 1.3;
  font-weight: 600;
  letter-spacing: -0.02em;
  overflow-wrap: anywhere;
}
.hi-facts { margin: 24px 0; }
.hi-facts > div {
  display: grid;
  grid-template-columns: 54px minmax(0, 1fr);
  gap: 12px;
  padding: 9px 0;
  border-bottom: 1px solid var(--border);
}
.hi-facts dt { font-family: var(--mono); font-size: 10px; color: var(--faint); }
.hi-facts dd { display: flex; align-items: center; gap: 5px; min-width: 0; font-size: 13px; }
.hi-detail-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-height: 36px;
  margin-top: 14px;
  color: var(--accent);
  font-size: 13px;
  font-weight: 500;
}
.hi-detail-link:hover { text-decoration: underline; text-underline-offset: 3px; }
.hi-empty { padding-top: 12px; }
.hi-empty p { margin-bottom: 6px; font-size: 14px; font-weight: 600; }
.hi-empty span { display: block; max-width: 24ch; color: var(--muted); font-size: 12px; line-height: 1.6; }
.hi-status { display: grid; gap: 10px; padding-top: 6px; }
.hi-skeleton {
  display: block;
  width: 68%;
  height: 12px;
  border-radius: 2px;
  background: var(--surface-2);
}
.hi-skeleton.wide { width: 90%; height: 26px; }
.hi-skeleton.short { width: 44%; }
.hi-error { color: var(--down); font-size: 13px; line-height: 1.5; }

@media (max-width: 1080px) {
  .hi-panel {
    position: fixed;
    inset: var(--bar-h) 0 0 auto;
    z-index: 90;
    width: min(360px, 100%);
    min-height: 0;
    max-height: none;
    padding: 20px;
    border-left: 1px solid var(--border);
    background: var(--bg);
    box-shadow: -12px 0 36px oklch(0.2 0.015 55 / 0.12);
    opacity: 0;
    transform: translateX(12px);
    visibility: hidden;
    pointer-events: none;
    transition: opacity 0.18s ease, transform 0.18s ease, visibility 0.18s;
  }
  .hi-panel.open {
    opacity: 1;
    transform: translateX(0);
    visibility: visible;
    pointer-events: auto;
  }
  .hi-close { display: grid; }
}

@media (max-width: 640px) {
  .hi-panel { width: 100%; padding: 18px 20px; }
  .hi-title-row h2 { font-size: 24px; }
}
</style>
