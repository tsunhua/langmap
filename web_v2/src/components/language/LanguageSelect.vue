<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useLanguagesStore } from '@/stores/languages'

const props = defineProps<{
  modelValue: string[]
}>()
const emit = defineEmits<{ 'update:modelValue': [value: string[]] }>()

const store = useLanguagesStore()
const open = ref(false)
const query = ref('')
const inputRef = ref<HTMLInputElement>()

const selected = computed(() => props.modelValue)

const filtered = computed(() => {
  const q = query.value.toLowerCase()
  return store.languages
    .filter(l => !selected.value.includes(l.code))
    .filter(l => !q || l.name.toLowerCase().includes(q) || l.code.toLowerCase().includes(q))
    .slice(0, 20)
})

function add(code: string) {
  emit('update:modelValue', [...selected.value, code])
  query.value = ''
}

function remove(code: string) {
  emit('update:modelValue', selected.value.filter(c => c !== code))
}

function handleClickOutside(e: MouseEvent) {
  if (!(e.target as HTMLElement).closest('.lang-select')) {
    open.value = false
  }
}

onMounted(() => {
  store.fetchLanguages()
  document.addEventListener('click', handleClickOutside)
})
onUnmounted(() => document.removeEventListener('click', handleClickOutside))
</script>

<template>
  <div class="lang-select">
    <div class="lang-select-tagwrap" @click="inputRef?.focus()">
      <span v-for="code in selected" :key="code" class="lang-tag">
        {{ code }}
        <button @click.stop="remove(code)">✕</button>
      </span>
      <input
        ref="inputRef"
        v-model="query"
        class="lang-select-input"
        placeholder="篩選語言…"
        @focus="open = true"
      />
    </div>
    <div v-if="open && filtered.length" class="lang-select-dropdown">
      <button
        v-for="l in filtered"
        :key="l.code"
        class="lang-opt"
        @click="add(l.code)"
      >
        {{ l.name }} ({{ l.code }})
      </button>
    </div>
  </div>
</template>

<style scoped>
.lang-select { position: relative; }
.lang-select-tagwrap {
  display: flex; flex-wrap: wrap; gap: 4px;
  padding: 4px 8px; border: 1px solid #EDE5D8;
  border-radius: 4px; background: #fff; min-height: 32px; cursor: text;
}
.lang-tag {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 1px 6px; border-radius: 3px;
  background: #F5E6D3; font-size: 12px;
}
.lang-tag button { border: none; background: none; cursor: pointer; font-size: 10px; color: #4A6FA5; }
.lang-select-input { border: none; outline: none; font-size: 13px; flex: 1; min-width: 80px; }
.lang-select-dropdown {
  position: absolute; top: 100%; left: 0; right: 0;
  max-height: 200px; overflow-y: auto;
  background: #fff; border: 1px solid #EDE5D8;
  border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  z-index: 50;
}
.lang-opt {
  display: block; width: 100%; text-align: left;
  padding: 6px 10px; border: none; background: none;
  font-size: 13px; cursor: pointer;
}
.lang-opt:hover { background: #F5F0E8; }
</style>
