<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
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
const total = ref(0)
const searchQuery = ref('')
const sortBy = ref('hot')

const filtered = computed(() => {
  if (!searchQuery.value) return exprs.value
  const q = searchQuery.value.toLowerCase()
  return exprs.value.filter((e: any) => e.text.toLowerCase().includes(q))
})

onMounted(async () => {
  lang.value = await detail(code.value)
  const data = await expressions(code.value, { sort: sortBy.value, limit: 100 })
  exprs.value = data.items
  total.value = data.total
})

async function changeSort(sort: string) {
  sortBy.value = sort
  const data = await expressions(code.value, { sort, limit: 100 })
  exprs.value = data.items
  total.value = data.total
}
</script>

<template>
  <LoadingSpinner v-if="loading && !lang" />

  <div v-else-if="lang" class="ld-page">
    <router-link to="/languages" class="ld-back">← 語言</router-link>

    <div class="ld-title">
      <h1>{{ lang.name }}</h1>
      <span class="lang-badge">{{ lang.code }}</span>
    </div>

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
.ld-back { font-size: 14px; display: inline-block; margin-bottom: 12px; }
.ld-title { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
.ld-stats { display: flex; gap: 12px; margin-bottom: 20px; }
.ld-toolbar { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; }
.ld-sort { display: flex; gap: 4px; }
.ld-list { background: #fff; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
</style>
