<template>
  <div class="smart-search-container">
    <div class="search-input-area">
      <input v-model="searchQuery" :placeholder="$t('search_placeholder')" class="search-input"
        @input="handleSearchInput" />
    </div>

    <div v-if="searched" class="search-results">
      <div class="create-new-option" @click="handleCreateNew">
        <div class="create-new-content">
          <svg xmlns="http://www.w3.org/2000/svg" class="create-icon" fill="none" viewBox="0 0 24 24"
            stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          <span class="create-text">{{ $t('add_expression') }}: "{{ searchQuery }}"</span>
        </div>
      </div>

      <div v-if="loading" class="search-status">
        <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
          viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
        </svg>
        <span class="ml-2 text-slate-600">{{ $t('searching') }}</span>
      </div>

      <div v-if="!loading && hasResults" class="existing-results">
        <div v-for="result in searchResults" :key="result.id" class="search-result-item">
            <div class="result-content">
              <div class="result-text">{{ result.text }}</div>
              <div class="result-meta">
                <span class="language-tag">{{ getLanguageDisplayName(result.language_code) }}</span>
                <span v-if="result.region_name" class="region-tag">
                  {{ result.region_name }}
                </span>
              </div>
            </div>
          <div class="result-actions">
            <button v-if="isAlreadyAssociated(result)" disabled class="action-btn associated-btn">
              {{ $t('associated') }}
            </button>
            <button v-else @click="handleAssociate(result)" class="action-btn associate-btn">
              {{ $t('associate') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="!loading && noResults" class="no-results-hint">
        {{ $t('no_expressions_found') }}
      </div>
    </div>
  </div>
</template>

<script>
import { ref, watch, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { languagesApi } from '../api/index.ts'

export default {
  name: 'SmartSearch',
  props: {
    excludeId: {
      type: Number,
      default: null
    },
    targetMeaningId: {
      type: Number,
      default: null
    },
    currentMeaningIds: {
      type: Array,
      default: () => []
    }
  },
  emits: ['create-new', 'associate'],
  setup(props, { emit }) {
    const { t } = useI18n()
    const searchQuery = ref('')
    const searchResults = ref([])
    const loading = ref(false)
    const searched = ref(false)

    let searchDebounceTimer = null

    const hasResults = computed(() => {
      return searchResults.value && searchResults.value.length > 0
    })

    const noResults = computed(() => {
      return searchResults.value && searchResults.value.length === 0
    })

    const handleSearchInput = () => {
      clearTimeout(searchDebounceTimer)

      if (!searchQuery.value || searchQuery.value.trim() === '') {
        searchResults.value = []
        searched.value = false
        return
      }

      searchDebounceTimer = setTimeout(() => {
        performSearch()
      }, 500)
    }

    const performSearch = async () => {
      loading.value = true
      searched.value = true

      try {
        const params = new URLSearchParams()
        params.set('q', searchQuery.value)
        params.set('include_meanings', 'true')

        const url = `/api/v1/search?${params.toString()}`
        const res = await fetch(url)

        if (!res.ok) {
          throw new Error('search failed')
        }

        const response = await res.json()
        // 适配新的API响应格式 { success, data }
        let results = response.data || response || []
        results = Array.isArray(results) ? results : []

        if (props.excludeId) {
          results = results.filter(r => r.id !== props.excludeId)
        }

        searchResults.value = results
      } catch (e) {
        console.error('Search error:', e)
        searchResults.value = []
      } finally {
        loading.value = false
      }
    }

    const handleCreateNew = () => {
      if (searchQuery.value && searchQuery.value.trim()) {
        emit('create-new', searchQuery.value.trim())
      }
    }

    const handleAssociate = (result) => {
      emit('associate', result)
    }

    const isAlreadyAssociated = (result) => {
      if (!props.currentMeaningIds || props.currentMeaningIds.length === 0) {
        return false
      }
      if (!result.meanings || result.meanings.length === 0) {
        return false
      }
      const resultMeaningIds = result.meanings.map(m => m.id)
      return resultMeaningIds.some(id => props.currentMeaningIds.includes(id))
    }

    watch(() => props.excludeId, () => {
      if (searched.value && searchQuery.value) {
        performSearch()
      }
    })

    return {
      searchQuery,
      searchResults,
      loading,
      searched,
      hasResults,
      noResults,
      handleSearchInput,
      handleCreateNew,
      handleAssociate,
      isAlreadyAssociated,
      getLanguageDisplayName: (code) => languagesApi.getLanguageDisplayName(code),
      t
    }
  }
}
</script>

<style scoped>
.smart-search-container {
  width: 100%;
}

.search-input-area {
  margin-bottom: 1rem;
}

.search-input {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 1px solid #cbd5e1;
  border-radius: 0.5rem;
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s;
}

.search-input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
}

.search-results {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.create-new-option {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  padding: 1rem;
  border-radius: 0.75rem;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 2px 4px rgba(59, 130, 246, 0.2);
}

.create-new-option:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(59, 130, 246, 0.3);
}

.create-new-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.create-icon {
  width: 1.25rem;
  height: 1.25rem;
  flex-shrink: 0;
}

.create-text {
  font-weight: 600;
  font-size: 1rem;
}

.search-status {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
  color: #64748b;
}

.existing-results {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.search-result-item {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 0.75rem;
  padding: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  transition: box-shadow 0.2s;
}

.search-result-item:hover {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.result-content {
  flex: 1;
  min-width: 0;
}

.result-text {
  font-weight: 600;
  color: #1e293b;
  font-size: 1rem;
  margin-bottom: 0.25rem;
}

.result-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.language-tag {
  background: #f1f5f9;
  color: #475569;
  padding: 0.125rem 0.5rem;
  border-radius: 0.375rem;
  font-weight: 500;
  font-size: 0.75rem;
}

.region-tag {
  color: #64748b;
}

.result-actions {
  flex-shrink: 0;
}

.action-btn {
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-weight: 500;
  font-size: 0.875rem;
  transition: all 0.2s;
  border: none;
  cursor: pointer;
}

.associate-btn {
  background: #3b82f6;
  color: white;
}

.associate-btn:hover {
  background: #2563eb;
}

.associated-btn {
  background: #e2e8f0;
  color: #94a3b8;
  cursor: not-allowed;
}

.no-results-hint {
  text-align: center;
  padding: 1.5rem;
  color: #64748b;
  font-size: 0.875rem;
}
</style>
