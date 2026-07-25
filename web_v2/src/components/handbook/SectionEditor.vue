<script setup lang="ts">
import { ref } from 'vue'
import ExpressionPicker from '@/components/expression/ExpressionPicker.vue'

defineProps<{
  title: string
  expressions: Array<{ id: number; text: string; language_code: string; position: number }>
  index: number
}>()

const emit = defineEmits<{
  'update:title': [title: string]
  'remove': []
  'move-up': []
  'move-down': []
  'add-expression': [expr: any]
  'remove-expression': [id: number]
}>()

const showPicker = ref(false)
</script>

<template>
  <div class="he-section">
    <div class="he-sec-head">
      <span class="he-sec-num">§{{ index + 1 }}</span>
      <input
        :value="title"
        class="he-sec-title"
        placeholder="章節標題"
        @input="emit('update:title', ($event.target as HTMLInputElement).value)"
      />
      <div class="he-sec-actions">
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('move-up')" title="上移">▲</button>
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('move-down')" title="下移">▼</button>
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('remove')" title="刪除">✕</button>
      </div>
    </div>

    <div class="he-expr-list">
      <div v-for="(expr, j) in expressions" :key="expr.id" class="he-expr">
        <span class="he-expr-num">{{ String(j + 1).padStart(2, '0') }}</span>
        <span class="he-expr-tx">{{ expr.text }}</span>
        <span class="lang-badge">{{ expr.language_code }}</span>
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('remove-expression', expr.id)">✕</button>
      </div>
    </div>

    <button class="btn btn-ghost btn-sm" @click="showPicker = !showPicker">
      {{ showPicker ? '收起' : '+ 新增詞句' }}
    </button>

    <ExpressionPicker v-if="showPicker" @select="emit('add-expression', $event); showPicker = false" />
  </div>
</template>

<style scoped>
.he-section { border: 1px solid #EDE5D8; border-radius: 4px; padding: 12px; margin-bottom: 12px; }
.he-sec-head { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.he-sec-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: #4A6FA5; }
.he-sec-title { flex: 1; font-size: 15px; font-weight: 500; border: none; border-bottom: 1px solid #EDE5D8; padding: 4px 0; }
.he-sec-actions { display: flex; gap: 2px; }
.he-expr { display: flex; align-items: center; gap: 8px; padding: 4px 8px; font-size: 13px; }
.he-expr-num { font-family: "IBM Plex Mono", monospace; font-size: 11px; color: #4A6FA5; width: 24px; }
.he-expr-tx { flex: 1; }
</style>
