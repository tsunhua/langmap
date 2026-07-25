<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useLanguages } from '@/composables/useLanguages'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import StatBox from '@/components/ui/StatBox.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const route = useRoute()
const code = computed(() => route.params.code as string)

const { loading, detail, expressions } = useLanguages()

const lang = ref<any>(null)
const exprs = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('hot')
const loadError = ref('')

const filtered = computed(() => {
  if (!searchQuery.value) return exprs.value
  const q = searchQuery.value.toLowerCase()
  return exprs.value.filter((e: any) => e.text.toLowerCase().includes(q))
})

async function load() {
  lang.value = null
  loadError.value = ''
  try {
    lang.value = await detail(code.value)
    const data = await expressions(code.value, { sort: sortBy.value, limit: 100 })
    exprs.value = data.items
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  }
}

onMounted(load)
watch(code, load)

const subtitle = computed(() => {
  const parts = []
  if (lang.value?.family) parts.push(lang.value.family)
  if (lang.value?.status_text) parts.push(lang.value.status_text)
  if (lang.value?.region_name) parts.push(lang.value.region_name)
  return parts.join(' · ')
})

async function changeSort(sort: string) {
  sortBy.value = sort
  try {
    const data = await expressions(code.value, { sort, limit: 100 })
    exprs.value = data.items
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  }
}
</script>

<template>
  <LoadingSpinner v-if="loading && !lang" />

  <EmptyState v-else-if="loadError" :message="loadError" />

  <div v-else-if="lang" class="ld-page">
    <router-link to="/languages" class="ld-back">← 語言</router-link>

    <div class="ld-title">
      <h1>{{ lang.name }}</h1>
      <span class="lang-badge">{{ lang.code }}</span>
    </div>
    <p class="ld-sub" v-if="subtitle">{{ subtitle }}</p>

    <div class="ld-stats">
      <StatBox :label="'詞句'" :value="lang.expression_count" />
      <StatBox :label="'已映射'" :value="lang.mapped_expression_count" />
    </div>

    <div class="ld-toolbar">
      <SearchBar v-model="searchQuery" placeholder="搜尋詞句…" style="flex: 1;" />
      <div class="ld-sort">
        <button :class="['btn btn-sm', sortBy === 'hot' ? 'btn-primary' : 'btn-ghost']" @click="changeSort('hot')">熱門</button>
        <button :class="['btn btn-sm', sortBy === 'new' ? 'btn-primary' : 'btn-ghost']" @click="changeSort('new')">最新</button>
        <button :class="['btn btn-sm', sortBy === 'alpha' ? 'btn-primary' : 'btn-ghost']" @click="changeSort('alpha')">字母</button>
      </div>
    </div>

    <EmptyState v-if="filtered.length === 0" message="找不到詞句" />

    <div v-else class="ld-list">
      <ExpressionRow
        v-for="expr in filtered"
        :key="expr.id"
        v-bind="expr"
      />
    </div>
  </div>
</template>

<style scoped>
.ld-page { max-width: 900px; margin: 0 auto; }
.ld-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); display: inline-block; margin-bottom: 12px; }
.ld-back:hover { color: var(--fg); }
.ld-title { display: flex; align-items: baseline; gap: 12px; flex-wrap: wrap; margin-bottom: 6px; }
.ld-title h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; }
.ld-stats { display: flex; gap: 28px; flex-wrap: wrap; padding: 14px 0 18px; border-bottom: 1px solid var(--border); margin-bottom: 18px; }
.ld-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 16px; }
.ld-sort { display: flex; gap: 4px; }
.ld-list { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.ld-sub { font-size: 13px; color: var(--muted); margin-top: 4px; }
</style>
