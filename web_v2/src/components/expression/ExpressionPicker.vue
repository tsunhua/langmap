<script setup lang="ts">
import { ref } from 'vue'
import { useExpressions } from '@/composables/useExpressions'

const emit = defineEmits<{ select: [expr: { id: number; text: string; language_code: string }] }>()

const { search } = useExpressions()
const query = ref('')
const results = ref<any[]>([])
const loading = ref(false)

async function doSearch() {
  if (!query.value.trim()) { results.value = []; return }
  loading.value = true
  try {
    results.value = await search(query.value, undefined, 20)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="picker">
    <div class="picker-search">
      <input v-model="query" placeholder="搜尋詞句…" @keydown.enter="doSearch" />
      <button class="btn btn-sm btn-ghost" @click="doSearch">搜尋</button>
    </div>
    <div class="picker-results">
      <button
        v-for="r in results"
        :key="r.id"
        class="picker-item"
        @click="emit('select', r)"
      >
        {{ r.text }} <span class="lang-badge">{{ r.language_code }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.picker { border: 1px solid #EDE5D8; border-radius: 4px; overflow: hidden; }
.picker-search { display: flex; gap: 6px; padding: 8px; border-bottom: 1px solid #EDE5D8; }
.picker-search input { flex: 1; }
.picker-results { max-height: 200px; overflow-y: auto; }
.picker-item {
  display: flex; align-items: center; gap: 8px;
  width: 100%; text-align: left; padding: 6px 10px;
  border: none; background: none; cursor: pointer; font-size: 13px;
}
.picker-item:hover { background: #F5F0E8; }
</style>
