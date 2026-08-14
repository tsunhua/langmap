<script setup lang="ts">
import { ref, watch } from 'vue'
import { X } from 'lucide-vue-next'

const props = defineProps<{
  modelValue: string
  placeholder?: string
}>()
const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const input = ref<HTMLInputElement>()
const text = ref('')
const tags = ref<string[]>([])

watch(() => props.modelValue, (val) => {
  tags.value = val ? val.split(',').map(t => t.trim()).filter(Boolean) : []
}, { immediate: true })

function emitValue() {
  emit('update:modelValue', tags.value.join(','))
}

function addTag(raw: string) {
  const t = raw.trim().replace(/^[, ]+|[, ]+$/g, '')
  if (!t || tags.value.includes(t)) return
  tags.value.push(t)
  emitValue()
}

function removeTag(i: number) {
  tags.value.splice(i, 1)
  emitValue()
  input.value?.focus()
}

function onInput() {
  const val = text.value
  const m = val.match(/^(.+?)[, ]/)
  if (m) {
    addTag(m[1])
    text.value = val.slice(m[0].length)
  }
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Backspace' && text.value === '' && tags.value.length > 0) {
    removeTag(tags.value.length - 1)
    e.preventDefault()
  }
  if (e.key === 'Enter') {
    e.preventDefault()
    if (text.value.trim()) {
      addTag(text.value.trim())
      text.value = ''
    }
  }
}

function onPaste(e: ClipboardEvent) {
  const data = e.clipboardData?.getData('text') || ''
  if (/[,]/.test(data)) {
    e.preventDefault()
    const parts = data.split(/[,]+/).map(s => s.trim()).filter(Boolean)
    for (const p of parts) addTag(p)
  }
}
</script>

<template>
  <div class="tag-input" @click="input?.focus()">
    <span v-for="(t, i) in tags" :key="i" class="tag-chip">
      <span class="tag-text">{{ t }}</span>
      <button class="tag-remove" :aria-label="`Remove tag ${t}`" @click.stop="removeTag(i)">
        <X :size="12" />
      </button>
    </span>
    <input
      ref="input"
      v-model="text"
      class="tag-field"
      :placeholder="tags.length === 0 ? (placeholder || '') : ''"
      :aria-label="placeholder"
      @input="onInput"
      @keydown="onKeydown"
      @paste="onPaste"
    />
  </div>
</template>

<style scoped>
.tag-input {
  display: flex;
  flex-wrap: wrap;
  gap: 3px;
  align-items: center;
  min-height: 48px;
  padding: 5px 8px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--bg);
  cursor: text;
}
.tag-input:focus-within {
  border-color: var(--accent);
}
.tag-chip {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  min-height: 32px;
  padding: 0 6px 0 10px;
  border-radius: 4px;
  background: var(--accent-soft);
  color: var(--accent);
  font-size: 13px;
  font-weight: 500;
  line-height: 1;
}
.tag-text {
  max-width: 60px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.tag-remove {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  border: none;
  background: none;
  color: var(--accent);
  cursor: pointer;
  border-radius: 3px;
  padding: 0;
}
.tag-remove:hover {
  background: color-mix(in oklch, var(--accent) 20%, transparent);
}
.tag-field {
  flex: 1;
  min-width: 50px;
  border: none;
  background: none;
  outline: none;
  font-size: 16px;
  color: var(--fg);
  padding: 0;
  min-height: 32px;
}
.tag-field::placeholder {
  color: var(--muted);
}
</style>
