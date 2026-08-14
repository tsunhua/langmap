<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useHandbooks } from '@/composables/useHandbooks'
import HandbookCard from '@/components/handbook/HandbookCard.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import SegControl from '@/components/ui/SegControl.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'

const { list } = useHandbooks()
const { t } = useI18n()

const handbooks = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('new')
const loading = ref(true)
const loadError = ref('')
let loadRequest = 0

const filtered = computed(() => {
  if (!searchQuery.value) return handbooks.value
  const q = searchQuery.value.toLowerCase()
  return handbooks.value.filter((h: any) => h.title.toLowerCase().includes(q))
})

async function load() {
  const request = ++loadRequest
  const requestedSort = sortBy.value
  loading.value = true
  loadError.value = ''
  try {
    const data = await list({ sort: requestedSort, limit: 50 })
    if (request !== loadRequest) return
    handbooks.value = data.items
  } catch (e: any) {
    if (request !== loadRequest) return
    loadError.value = e.response?.data?.error || t('handbooks.loadFailed')
  } finally {
    if (request === loadRequest) loading.value = false
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
      <h1>{{ t('handbooks.title') }}</h1>
      <router-link to="/handbook/new/edit" class="btn btn-primary btn-sm">{{ t('handbooks.create') }}</router-link>
    </div>

    <div class="hb-toolbar">
      <SegControl
        v-model="sortBy"
        :options="[{ value: 'new', label: t('handbooks.newest') }, { value: 'hot', label: t('handbooks.popular') }]"
        @update:model-value="changeSort"
      />
      <SearchBar v-model="searchQuery" :placeholder="t('handbooks.searchPlaceholder')" style="max-width: 300px;" />
    </div>

    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <EmptyState v-else-if="filtered.length === 0" :message="t('handbooks.noResults')" />

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
.hb-page { max-width: 1000px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.hb-head { display: flex; justify-content: space-between; align-items: baseline; gap: 16px; flex-wrap: wrap; margin-bottom: var(--space-base); }
.hb-head h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; }
.hb-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: var(--space-md); }
.hb-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 290px), 1fr)); gap: 14px; }
</style>
