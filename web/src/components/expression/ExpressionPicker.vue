<script setup lang="ts">
import { ref } from 'vue'
import { useExpressions } from '@/composables/useExpressions'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

const emit = defineEmits<{ select: [expr: { id: string; text: string; lang_code: string }] }>()

const { search } = useExpressions()
const query = ref('')
const results = ref<any[]>([])
const loading = ref(false)
const error = ref('')
const searched = ref(false)

async function doSearch() {
  if (!query.value.trim()) { results.value = []; searched.value = false; return }
  loading.value = true
  error.value = ''
  try {
    results.value = await search(query.value, undefined, 20)
    searched.value = true
  } catch (e: any) {
    error.value = e.response?.data?.error || t('search.loadFailed')
    results.value = []
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="picker">
    <div class="picker-search">
      <input v-model="query" :placeholder="t('components.searchExpressions')" :aria-label="t('components.searchExpressions')" @keydown.enter="doSearch" />
      <button class="btn btn-sm btn-ghost" @click="doSearch">{{ t('components.search') }}</button>
    </div>
    <div class="picker-results">
      <div v-if="loading" class="picker-hint">{{ t('components.searching') }}</div>
      <div v-else-if="error" class="picker-hint err" role="alert">{{ error }}</div>
      <div v-else-if="searched && results.length === 0" class="picker-hint">{{ t('components.noExpressions') }}</div>
      <button
        v-for="r in results"
        :key="r.id"
        class="picker-item"
        @click="emit('select', r)"
      >
        {{ r.text }} <span class="lang-badge">{{ r.lang_code }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.picker { border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; background: var(--surface); }
.picker-search { display: flex; gap: 6px; padding: 8px; border-bottom: 1px solid var(--border); }
.picker-search input { flex: 1; }
.picker-results { max-height: 200px; overflow-y: auto; }
.picker-item {
  display: flex; align-items: center; gap: 8px;
  width: 100%; text-align: left; padding: 6px 10px;
  border: none; background: none; cursor: pointer; font-size: 13px;
  color: var(--fg);
}
.picker-item:hover { background: var(--accent-soft); }
.picker-item:hover .lang-badge { border-color: color-mix(in oklch, var(--accent) 45%, var(--border)); }
.picker-hint { padding: 8px 10px; font-size: 13px; color: var(--muted); }
.picker-hint.err { color: var(--down); }
</style>
