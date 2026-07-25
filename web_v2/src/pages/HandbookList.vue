<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useHandbooks } from '@/composables/useHandbooks'
import HandbookCard from '@/components/handbook/HandbookCard.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import SegControl from '@/components/ui/SegControl.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const { list } = useHandbooks()

const handbooks = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('new')
const loading = ref(true)
const loadError = ref('')

const filtered = computed(() => {
  if (!searchQuery.value) return handbooks.value
  const q = searchQuery.value.toLowerCase()
  return handbooks.value.filter((h: any) => h.title.toLowerCase().includes(q))
})

async function load() {
  loading.value = true
  loadError.value = ''
  try {
    const data = await list({ sort: sortBy.value, limit: 50 })
    handbooks.value = data.items
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
}

onMounted(load)

async function changeSort() {
  await load()
}
</script>

<template>
  <div class="hb-page">
    <div class="hb-head">
      <h1>手冊</h1>
      <router-link to="/handbook/new/edit" class="btn btn-primary btn-sm">新建手冊</router-link>
    </div>

    <div class="hb-toolbar">
      <SegControl
        v-model="sortBy"
        :options="[{ value: 'new', label: '最新' }, { value: 'hot', label: '熱門' }]"
        @update:model-value="changeSort"
      />
      <SearchBar v-model="searchQuery" placeholder="搜尋手冊…" style="max-width: 300px;" />
    </div>

    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <EmptyState v-else-if="filtered.length === 0" message="找不到手冊" />

    <div v-else class="hb-grid">
      <HandbookCard
        v-for="hb in filtered"
        :key="hb.id"
        v-bind="hb"
      />
    </div>
  </div>
</template>

<style scoped>
.hb-page { max-width: 1000px; margin: 0 auto; }
.hb-head { display: flex; justify-content: space-between; align-items: baseline; gap: 16px; flex-wrap: wrap; margin-bottom: 16px; }
.hb-head h1 { font-size: 22px; font-weight: 600; letter-spacing: -0.02em; }
.hb-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 20px; }
.hb-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 290px), 1fr)); gap: 14px; }
</style>
