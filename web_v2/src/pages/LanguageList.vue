<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useLanguages } from '@/composables/useLanguages'
import LanguageCard from '@/components/language/LanguageCard.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import StatBox from '@/components/ui/StatBox.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'

const { loading, list } = useLanguages()

const languages = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('count')

const filtered = computed(() => {
  let result = languages.value
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter((l: any) =>
      l.name.toLowerCase().includes(q) || l.code.toLowerCase().includes(q)
    )
  }
  if (sortBy.value === 'alpha') {
    result = [...result].sort((a: any, b: any) => a.name.localeCompare(b.name))
  } else {
    result = [...result].sort((a: any, b: any) => b.expression_count - a.expression_count)
  }
  return result
})

const totalExpressions = computed(() => languages.value.reduce((s: number, l: any) => s + l.expression_count, 0))

onMounted(async () => {
  languages.value = await list()
})
</script>

<template>
  <div class="lg-page">
    <h1>語言列表</h1>
    <p style="color: #4A6FA5; margin: 8px 0 20px;">探索所有語言的詞句與映射</p>

    <div class="lg-stats">
      <StatBox :label="'種語言'" :value="languages.length" />
      <StatBox :label="'詞句'" :value="totalExpressions.toLocaleString()" />
    </div>

    <div class="lg-toolbar">
      <SearchBar v-model="searchQuery" placeholder="搜尋語言…" style="flex: 1;" />
      <div class="lg-sort">
        <button :class="['btn btn-sm', sortBy === 'count' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'count'">數量</button>
        <button :class="['btn btn-sm', sortBy === 'alpha' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'alpha'">A–Z</button>
      </div>
    </div>

    <LoadingSpinner v-if="loading" />

    <div v-else class="lg-list">
      <LanguageCard
        v-for="lang in filtered"
        :key="lang.code"
        v-bind="lang"
      />
    </div>
  </div>
</template>

<style scoped>
.lg-page { max-width: 900px; margin: 0 auto; }
.lg-stats { display: flex; gap: 12px; margin-bottom: 20px; }
.lg-toolbar { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; }
.lg-sort { display: flex; gap: 4px; }
.lg-list { background: #fff; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
</style>
