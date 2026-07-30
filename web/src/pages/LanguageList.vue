<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useLanguages } from '@/composables/useLanguages'
import LanguageCard from '@/components/language/LanguageCard.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import StatBox from '@/components/ui/StatBox.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import LanguageCreateDialog from '@/components/language/LanguageCreateDialog.vue'
import { useI18n } from 'vue-i18n'
import { Plus } from 'lucide-vue-next'

const { loading, list } = useLanguages()
const { t } = useI18n()

const languages = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('count')
const loadError = ref('')
const createDialogOpen = ref(false)
const createButton = ref<HTMLButtonElement>()

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

async function loadLanguages() {
  loadError.value = ''
  try {
    languages.value = await list()
  } catch (e: any) {
    loadError.value = e.response?.data?.error || t('languagesPage.loadFailed')
  }
}

function closeCreateDialog() {
  createDialogOpen.value = false
  createButton.value?.focus()
}

async function handleLanguageCreated() {
  await loadLanguages()
}

onMounted(loadLanguages)
</script>

<template>
  <div class="lg-page">
    <div class="lg-head">
      <div class="lg-heading">
        <h1>{{ t('languagesPage.title') }}</h1>
        <p class="lg-sub">{{ t('languagesPage.subtitle') }}</p>
      </div>
      <button
        ref="createButton"
        class="btn btn-primary lg-create"
        type="button"
        @click="createDialogOpen = true"
      >
        <Plus :size="16" aria-hidden="true" />
        {{ t('languagesPage.addLanguage') }}
      </button>
    </div>

    <div class="lg-stats">
      <StatBox :label="t('languagesPage.languageCount')" :value="languages.length" />
      <StatBox :label="t('languagesPage.expressionCount')" :value="totalExpressions.toLocaleString()" />
    </div>

    <div class="lg-toolbar">
      <SearchBar v-model="searchQuery" :placeholder="t('languagesPage.searchPlaceholder')" style="flex: 1;" />
      <div class="lg-sort">
        <button :class="{ on: sortBy === 'count' }" @click="sortBy = 'count'">{{ t('languagesPage.sortCount') }}</button>
        <button :class="{ on: sortBy === 'alpha' }" @click="sortBy = 'alpha'">{{ t('languagesPage.sortAlphabetical') }}</button>
      </div>
    </div>

    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <EmptyState v-else-if="filtered.length === 0" :message="t('languagesPage.noResults')" />

    <div v-else class="lg-list">
      <LanguageCard
        v-for="lang in filtered"
        :key="lang.code"
        v-bind="lang"
      />
    </div>

    <LanguageCreateDialog
      :open="createDialogOpen"
      :return-focus="createButton"
      @created="handleLanguageCreated"
      @close="closeCreateDialog"
    />
  </div>
</template>

<style scoped>
.lg-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.lg-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 24px; }
.lg-heading { min-width: 0; }
.lg-head h1 { font-size: 22px; font-weight: 600; letter-spacing: -0.02em; }
.lg-sub { font-size: 13px; color: var(--muted); margin: 6px 0 0; }
.lg-create { flex: none; }
.lg-stats { display: flex; gap: 28px; flex-wrap: wrap; padding: 14px 0 18px; border-bottom: 1px solid var(--border); margin-bottom: 18px; }
.lg-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 16px; }
.lg-sort { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.lg-sort button { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; border: none; background: var(--surface); color: var(--muted); cursor: pointer; height: 30px; padding: 0 16px; transition: background 0.15s, color 0.15s; }
.lg-sort button:hover { color: var(--fg); }
.lg-sort button.on { background: var(--fg); color: var(--surface); }
.lg-list { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }

@media (max-width: 640px) {
  .lg-page { padding-right: 16px; padding-left: 16px; }
  .lg-head { align-items: stretch; flex-direction: column; gap: 16px; }
  .lg-create { justify-content: center; width: 100%; }
}
</style>
