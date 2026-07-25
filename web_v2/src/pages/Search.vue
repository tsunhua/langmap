<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useSearch } from '@/composables/useSearch'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import LanguageSelect from '@/components/language/LanguageSelect.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const route = useRoute()
const { search } = useSearch()

const query = ref((route.query.q as string) || '')
const langs = ref<string[]>([])
const sortBy = ref('hot')
const results = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const searched = ref(false)
const loadError = ref('')

async function doSearch() {
  if (!query.value.trim()) {
    results.value = []
    return
  }
  loading.value = true
  loadError.value = ''
  try {
    const data = await search(query.value, {
      lang: langs.value.join(','),
      sort: sortBy.value,
      limit: 50,
    })
    results.value = data.items
    total.value = data.total
    searched.value = true
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '搜尋失敗'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (query.value) doSearch()
})
</script>

<template>
  <div class="se-page">
    <div class="se-hero">
      <h1>搜尋</h1>
      <div class="se-qrow">
        <SearchBar v-model="query" placeholder="搜尋詞句…" :large="true" @search="doSearch" />
        <LanguageSelect v-model="langs" />
      </div>
    </div>

    <div v-if="searched || loading" class="se-meta">
      <span class="se-count">{{ total }} 個結果</span>
      <div class="se-sort">
        <button :class="['btn btn-sm', sortBy === 'hot' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'hot'; doSearch()">熱門</button>
        <button :class="['btn btn-sm', sortBy === 'new' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'new'; doSearch()">最新</button>
        <button :class="['btn btn-sm', sortBy === 'alpha' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'alpha'; doSearch()">字母</button>
      </div>
    </div>

    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <EmptyState v-else-if="searched && results.length === 0" message="找不到結果" />

    <div v-else-if="results.length" class="se-list">
      <ExpressionRow
        v-for="r in results"
        :key="r.id"
        v-bind="r"
      />
    </div>

    <p v-else class="se-hint">輸入關鍵字開始搜尋</p>
  </div>
</template>

<style scoped>
.se-page { max-width: 900px; margin: 0 auto; }
.se-hero { margin-bottom: 20px; }
.se-hero h1 { margin-bottom: 16px; }
.se-qrow { display: flex; gap: 12px; }
.se-qrow > :first-child { flex: 1; }
.se-meta { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.se-count { font-size: 13px; color: #4A6FA5; }
.se-sort { display: flex; gap: 4px; }
.se-list { background: #fff; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.se-hint { text-align: center; padding: 40px; color: #4A6FA5; }
</style>
