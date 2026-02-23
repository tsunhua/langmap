<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-6">{{ $t('languages_title') }}</h1>

    <!-- Search box -->
    <div class="mb-6">
      <div class="relative">
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="$t('search_languages_placeholder')"
          class="w-full px-4 py-3 pl-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5 absolute left-3 top-3.5 text-gray-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
      </div>
    </div>

    <!-- Language list -->
    <div v-if="loading" class="flex justify-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="filteredLanguages.length === 0" class="text-center py-8 text-gray-500">
      {{ $t('no_languages_found') }}
    </div>

    <div v-else class="space-y-2">
      <router-link
        v-for="lang in filteredLanguages"
        :key="lang.code"
        :to="`/languages/${lang.code}`"
        class="flex items-center justify-between p-4 bg-white border border-gray-200 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-all cursor-pointer group"
      >
        <div class="flex items-center gap-3">
          <span class="text-lg font-medium text-gray-900 group-hover:text-blue-600">
            {{ lang.native_name || lang.name }}
          </span>
          <span class="bg-gray-100 text-gray-600 text-sm px-2 py-1 rounded">
            {{ lang.code }}
          </span>
        </div>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5 text-gray-400 group-hover:text-blue-600"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 5l7 7-7 7"
          />
        </svg>
      </router-link>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { fetchLanguages } from '../services/languageService.js'

export default {
  name: 'LanguageList',
  setup() {
    const languages = ref([])
    const loading = ref(true)
    const searchQuery = ref('')

    const filteredLanguages = computed(() => {
      if (!searchQuery.value) {
        return languages.value
      }
      const query = searchQuery.value.toLowerCase()
      return languages.value.filter(
        lang =>
          (lang.name && lang.name.toLowerCase().includes(query)) ||
          (lang.native_name && lang.native_name.toLowerCase().includes(query)) ||
          (lang.code && lang.code.toLowerCase().includes(query))
      )
    })

    const loadLanguages = async () => {
      try {
        loading.value = true
        languages.value = await fetchLanguages()
      } catch (error) {
        console.error('Failed to load languages:', error)
      } finally {
        loading.value = false
      }
    }

    onMounted(() => {
      loadLanguages()
    })

    return {
      languages,
      loading,
      searchQuery,
      filteredLanguages
    }
  }
}
</script>
