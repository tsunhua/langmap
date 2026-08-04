<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ExpressionPicker from '@/components/expression/ExpressionPicker.vue'
import { ChevronUp, ChevronDown, X, Plus } from 'lucide-vue-next'

defineProps<{
  title: string
  expressions: Array<{ id: number; text: string; language_profile_code: string; position: number }>
  index: number
}>()

const emit = defineEmits<{
  'update:title': [title: string]
  'remove': []
  'move-up': []
  'move-down': []
  'add-expression': [expr: any]
  'remove-expression': [id: number]
  'move-expr-up': [id: number]
  'move-expr-down': [id: number]
}>()

const showPicker = ref(false)
const { t } = useI18n()
</script>

<template>
  <div class="he-section">
    <div class="he-sec-head">
      <span class="he-sec-num">§{{ index + 1 }}</span>
      <input
        :value="title"
        class="he-sec-title"
        :placeholder="t('handbook.sectionTitle')"
        :aria-label="t('handbook.sectionTitle')"
        @input="emit('update:title', ($event.target as HTMLInputElement).value)"
      />
      <div class="he-sec-actions">
        <button class="btn btn-icon btn-ghost btn-sm" :aria-label="t('handbook.moveSectionUp')" @click="emit('move-up')"><ChevronUp :size="14" aria-hidden="true" /></button>
        <button class="btn btn-icon btn-ghost btn-sm" :aria-label="t('handbook.moveSectionDown')" @click="emit('move-down')"><ChevronDown :size="14" aria-hidden="true" /></button>
        <button class="btn btn-icon btn-ghost btn-sm" :aria-label="t('handbook.deleteSection')" @click="emit('remove')"><X :size="14" aria-hidden="true" /></button>
      </div>
    </div>

    <div class="he-expr-list">
      <div v-for="(expr, j) in expressions" :key="expr.id" class="he-expr">
        <span class="he-expr-drag" aria-hidden="true">⠿</span>
        <span class="he-expr-num">{{ String(j + 1).padStart(2, '0') }}</span>
        <span class="he-expr-tx">{{ expr.text }}</span>
        <span class="lang-badge">{{ expr.language_profile_code }}</span>
        <button class="btn btn-icon btn-ghost btn-sm he-up" :title="t('handbook.moveUp')" @click="emit('move-expr-up', expr.id)"><ChevronUp :size="14" aria-hidden="true" /></button>
        <button class="btn btn-icon btn-ghost btn-sm he-down" :title="t('handbook.moveDown')" @click="emit('move-expr-down', expr.id)"><ChevronDown :size="14" aria-hidden="true" /></button>
        <button class="btn btn-icon btn-ghost btn-sm" :aria-label="t('handbook.removeExpression', { text: expr.text })" @click="emit('remove-expression', expr.id)"><X :size="14" aria-hidden="true" /></button>
      </div>
    </div>

    <button class="btn btn-ghost btn-sm" @click="showPicker = !showPicker">
      <Plus :size="14" aria-hidden="true" /> {{ showPicker ? t('handbook.collapsePicker') : t('handbook.addExpression') }}
    </button>

    <ExpressionPicker v-if="showPicker" @select="emit('add-expression', $event); showPicker = false" />
  </div>
</template>

<style scoped>
.he-section { border: 1px solid var(--border); border-radius: 8px; padding: 14px 16px; margin-bottom: 14px; background: var(--surface); }
.he-sec-head { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 10px; padding-bottom: 8px; border-bottom: 1px solid var(--border); }
.he-sec-num { font-family: var(--mono); font-size: 12px; color: var(--accent); }
.he-sec-title { flex: 1; min-width: 0; font-size: 15px; font-weight: 500; border: none; border-bottom: 1px solid transparent; padding: 4px 0; background: transparent; }
.he-sec-title:focus { outline: none; border-bottom-color: var(--accent); }
.he-sec-actions { display: flex; gap: 2px; }
.he-expr-list { margin-bottom: 8px; }
.he-expr { display: grid; grid-template-columns: 18px 26px 1fr auto auto auto auto; align-items: center; gap: 8px; padding: 6px 4px; font-size: 13px; }
.he-expr-drag { cursor: grab; color: var(--muted); font-size: 12px; user-select: none; }
.he-expr-num { font-family: var(--mono); font-size: 11px; color: var(--muted); width: 26px; }
.he-expr-tx { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
</style>
