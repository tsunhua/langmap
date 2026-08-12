<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'
const { t } = useI18n()

const props = defineProps<{
  graph: MappingGraphResponse | null
  loading: boolean
  error: string
}>()

defineEmits<{
  select: [id: string]
}>()

const directNodes = computed(() =>
  (props.graph?.nodes ?? [])
    .filter(node => node.depth === 1)
    .slice(0, 8),
)

const directCount = computed(() => props.graph?.layer_counts[1] ?? 0)
</script>

<template>
  <section class="hr-preview" aria-labelledby="hr-title">
    <div class="hr-heading">
      <h3 id="hr-title">{{ t('components.relatedExpressions') }}</h3>
      <span v-if="graph && directCount">{{ directCount }}</span>
    </div>

    <div v-if="loading" class="hr-loading" role="status" :aria-label="t('components.loadingRelated')">
      <span></span>
      <span></span>
      <span></span>
    </div>

    <p v-else-if="error" class="hr-error">{{ error }}</p>

    <p v-else-if="graph && directCount === 0" class="hr-empty">
      {{ t('components.noDirectMappings') }}
    </p>

    <div v-else-if="graph" class="hr-graph" role="group" :aria-label="t('components.relatedExpressions')">
      <ul class="hr-branches" :aria-label="t('components.directMappingList')">
        <li v-for="node in directNodes" :key="node.expression_id">
          <button type="button" @click="$emit('select', node.expression_id)">
            <span>{{ node.text }}</span>
            <small>{{ node.lang_code }}</small>
          </button>
        </li>
      </ul>

      <p v-if="directCount > directNodes.length" class="hr-more">
        {{ t('components.moreMappings', { count: directCount - directNodes.length }) }}
      </p>
    </div>
  </section>
</template>

<style scoped>
.hr-preview {
  padding-top: 18px;
  border-top: 1px solid var(--border);
}
.hr-heading {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 14px;
}
.hr-heading h3 { font-size: 13px; font-weight: 600; }
.hr-heading span { font-family: var(--mono); font-size: 9px; color: var(--muted); }
.hr-graph { min-width: 0; }
.hr-branches button {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  width: 100%;
  min-width: 0;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  text-align: left;
}
.hr-branches button span {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.hr-branches button small {
  flex: 0 0 auto;
  font-family: var(--mono);
  font-size: 9px;
  color: var(--muted);
  font-weight: 400;
}
.hr-branches {
  display: grid;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.hr-branches li { min-width: 0; }
.hr-branches button {
  min-height: 38px;
  padding: 7px 9px;
  color: var(--fg);
  cursor: pointer;
  transition: border-color 0.12s, background 0.12s;
}
.hr-branches button:hover { border-color: var(--edge); background: var(--surface-2); }
.hr-branches button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.hr-loading { display: grid; gap: 8px; }
.hr-loading span {
  display: block;
  height: 38px;
  border-radius: var(--r);
  background: var(--surface-2);
}
.hr-loading span:first-child { width: 86%; }
.hr-loading span:nth-child(2) { width: 72%; margin-left: 28px; }
.hr-loading span:last-child { width: 78%; margin-left: 28px; }
.hr-error { color: var(--down); font-size: 12px; }
.hr-empty, .hr-more { color: var(--muted); font-size: 11px; line-height: 1.5; }
.hr-more { margin: 10px 0 0; }
</style>
