<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import type { ExpressionEdge } from '@/api/expressions'
import { useI18n } from 'vue-i18n'

const props = defineProps<{ edges: ExpressionEdge[]; submitting: boolean; error?: string }>()
const emit = defineEmits<{ close: []; confirm: [edgeIds: string[]] }>()
const selected = ref(new Set<string>())
const { t } = useI18n()
watch(() => props.edges, () => { selected.value = new Set() })
const orderedEdges = computed(() => [...props.edges].sort((a, b) => (b.score ?? 0) - (a.score ?? 0) || (a.created_at ?? '').localeCompare(b.created_at ?? '') || a.edge_id.localeCompare(b.edge_id)))
function toggle(id: string) { const next = new Set(selected.value); next.has(id) ? next.delete(id) : next.add(id); selected.value = next }
function confirm() { if (selected.value.size) emit('confirm', [...selected.value].sort((a, b) => a.localeCompare(b))) }
</script>

<template>
  <div class="split-backdrop" role="presentation" @click.self="emit('close')">
    <section class="split-dialog" role="dialog" aria-modal="true" aria-labelledby="split-title">
      <h2 id="split-title">{{ t('splitDialog.title') }}</h2>
      <p class="warning">{{ t('splitDialog.warning') }}</p>
      <fieldset><legend>{{ t('splitDialog.selectMappings') }}</legend>
        <label v-for="edge in orderedEdges" :key="edge.edge_id" class="edge-option">
          <input type="checkbox" :checked="selected.has(edge.edge_id)" @change="toggle(edge.edge_id)">
          <span>{{ edge.neighbor_text }} <small>({{ edge.neighbor_lang_code }}, {{ t('splitDialog.score', { score: edge.score }) }})</small></span>
        </label>
      </fieldset>
      <p v-if="error" role="alert" class="error">{{ error }}</p>
      <div class="actions"><button class="btn btn-sm" type="button" @click="emit('close')">{{ t('common.cancel') }}</button><button data-action="confirm-split" class="btn btn-primary btn-sm" type="button" :disabled="!selected.size || submitting" @click="confirm">{{ submitting ? t('splitDialog.splitting') : t('splitDialog.title') }}</button></div>
    </section>
  </div>
</template>

<style scoped>
.split-backdrop { position: fixed; inset: 0; z-index: 110; display: grid; place-items: center; padding: 16px; background: oklch(0 0 0 / .35); }
.split-dialog { width: min(100%, 520px); max-height: min(80dvh, 640px); overflow: auto; padding: 20px; background: var(--surface); border: 1px solid var(--border); border-radius: var(--r); }
h2 { margin: 0; font-size: 18px; }.warning { margin: 10px 0; color: var(--down); line-height: 1.5; }.edge-option { display: flex; gap: 8px; align-items: flex-start; padding: 10px 0; min-height: 44px; }.edge-option small { color: var(--muted); }.actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 16px; }.error { color: var(--down); }
</style>
