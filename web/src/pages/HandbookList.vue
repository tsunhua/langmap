<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold text-gray-900">{{ $t('handbook_title') || 'Handbooks' }}</h1>
      <button v-if="isLoggedIn && activeTab === 'my'" @click="goToCreate"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 shadow-sm transition-all">
        <span class="text-xl">+</span>
        {{ $t('handbook_new') || 'New Handbook' }}
      </button>
    </div>

    <!-- Tabs -->
    <div class="flex border-b border-gray-200 mb-8 space-x-8">
      <button v-if="isLoggedIn" @click="activeTab = 'my'"
        :class="['pb-4 text-sm font-medium transition-colors relative', activeTab === 'my' ? 'text-blue-600' : 'text-gray-500 hover:text-gray-700']">
        {{ $t('handbook_my') || 'My Handbooks' }}
        <div v-if="activeTab === 'my'" class="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600"></div>
      </button>
      <button @click="activeTab = 'shared'"
        :class="['pb-4 text-sm font-medium transition-colors relative', activeTab === 'shared' ? 'text-blue-600' : 'text-gray-500 hover:text-gray-700']">
        {{ $t('handbook_shared') || 'Shared Handbooks' }}
        <div v-if="activeTab === 'shared'" class="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600"></div>
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="handbooks.length === 0"
      class="text-center py-16 bg-gray-50 rounded-2xl border border-dashed border-gray-300">
      <div class="text-4xl mb-4">📖</div>
      <h3 class="text-xl font-medium text-gray-900 mb-2">{{ $t('handbook_none_found') || 'No handbooks found' }}</h3>
      <p v-if="activeTab === 'my'" class="text-gray-500 mb-6">{{ $t('handbook_empty_info') || 'Start creating your first learning manual!' }}</p>
      <button v-if="isLoggedIn && activeTab === 'my'" @click="goToCreate"
        class="text-blue-600 hover:text-blue-800 font-semibold">
        {{ $t('handbook_new') || 'New Handbook' }}
      </button>
    </div>

    <!-- Handbooks Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="handbook in handbooks" :key="handbook.id"
        class="group bg-white rounded-xl shadow-sm border border-gray-200 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 cursor-pointer overflow-hidden flex flex-col"
        @click="goToView(handbook.id)">
        <div class="p-6 flex-grow">
          <div class="flex justify-between items-start mb-3 gap-2">
            <h3 class="text-lg font-bold text-gray-900 group-hover:text-blue-600 transition-colors line-clamp-2 flex-1 min-w-0 leading-tight">
              {{ handbook.title }}
            </h3>
            <span v-if="handbook.is_public"
              class="bg-green-100 text-green-800 text-[10px] uppercase tracking-wider font-bold px-2 py-0.5 rounded-full flex-shrink-0 ml-2">
              {{ $t('public') }}
            </span>
          </div>
          <p v-if="handbook.description" class="text-gray-600 text-sm mb-2 line-clamp-3 leading-relaxed">
            {{ handbook.description }}
          </p>
          <div class="flex flex-wrap gap-1 mb-3">
            <span v-if="handbook.source_lang"
              class="bg-purple-50 text-purple-700 text-[10px] px-1.5 py-0.5 rounded border border-purple-100">
              {{ getLanguageName(handbook.source_lang) }}
            </span>
            <span v-for="lang in getTargetLangs(handbook.target_langs || handbook.target_lang)" :key="lang"
              class="bg-blue-50 text-blue-700 text-[10px] px-1.5 py-0.5 rounded border border-blue-100">
              {{ getLanguageName(lang) }}
            </span>
          </div>
        </div>
        <div
          class="px-6 py-4 bg-gray-50 border-t border-gray-100 flex justify-between items-center text-[10px] text-gray-400 uppercase tracking-widest font-bold">
          <span>{{ formatDate(handbook.created_at) }}</span>
          <div v-if="isLoggedIn && activeTab === 'my'" class="flex gap-3" @click.stop>
            <button @click="goToEdit(handbook.id)" class="hover:text-blue-600 transition-colors">
              {{ $t('edit') }}
            </button>
            <button @click="confirmDelete(handbook)" class="hover:text-red-600 transition-colors">
              {{ $t('delete') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="currentPage > 1 || handbooks.length === itemsPerPage"
      class="flex justify-center items-center gap-4 mt-12 pb-8">
      <button @click="prevPage" :disabled="currentPage === 1"
        class="px-5 py-2 border border-gray-200 rounded-xl hover:bg-gray-50 disabled:opacity-30 disabled:cursor-not-allowed text-sm font-medium transition-colors">
        &laquo; {{ $t('prev') }}
      </button>
      <span class="text-sm font-semibold bg-gray-100 px-4 py-2 rounded-lg text-gray-700">
        {{ $t('page') }} {{ currentPage }}
      </span>
      <button @click="nextPage" :disabled="handbooks.length < itemsPerPage"
        class="px-5 py-2 border border-gray-200 rounded-xl hover:bg-gray-50 disabled:opacity-30 disabled:cursor-not-allowed text-sm font-medium transition-colors">
        {{ $t('next') }} &raquo;
      </button>
    </div>

    <!-- Confirm Modal -->
    <ConfirmModal
      v-model="showDeleteModal"
      :message="$t('handbook_delete_confirm') || 'Are you sure you want to delete this handbook?'"
      :loading="deleting"
      :loadingText="$t('deleting') || 'Deleting...'"
      :confirmText="$t('delete') || 'Delete'"
      @confirm="executeDelete"
    />
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '../stores/index.ts'
import { handbooksApi, languagesApi } from '../api/index.ts'
import ConfirmModal from '../components/ConfirmModal.vue'

export default {
  name: 'HandbookList',
  components: { ConfirmModal },
  setup() {
    const router = useRouter()
    const { t } = useI18n()
    const authStore = useAuthStore()

    // State
    const handbooks = ref([])
    const loading = ref(true)
    const activeTab = ref('my')
    const isLoggedIn = computed(() => authStore.isAuthenticated)

    // Delete Confirmation
    const showDeleteModal = ref(false)
    const handbookToDelete = ref(null)
    const deleting = ref(false)

    // Pagination state
    const currentPage = ref(1)
    const itemsPerPage = ref(12)

    // Load handbooks
    const fetchHandbooks = async () => {
      loading.value = true
      try {
        const skip = (currentPage.value - 1) * itemsPerPage.value
        const params = { skip, limit: itemsPerPage.value }

        if (activeTab.value === 'shared') {
          params.is_public = 1
        } else {
          // For 'my' tab, we get all handbooks for the current user (handled by backend)
          // Backend will return empty array if user is not authenticated
        }

        console.log('[HandbookList] Fetching handbooks:', { activeTab: activeTab.value, isAuthenticated: authStore.isAuthenticated, params })

        const result = await handbooksApi.getAll(params)
        if (result.success && result.data) {
          handbooks.value = result.data
        } else {
          handbooks.value = []
        }
      } catch (error) {
        console.error('Failed to load handbooks:', error)
        handbooks.value = []
      } finally {
        loading.value = false
      }
    }

    watch(activeTab, () => {
      currentPage.value = 1
      fetchHandbooks()
    })

    watch(() => authStore.isAuthenticated, () => {
      if (activeTab.value === 'my' && authStore.isAuthenticated) {
        fetchHandbooks()
      }
    })

    const nextPage = () => {
      if (handbooks.value.length === itemsPerPage.value) {
        currentPage.value++
        fetchHandbooks()
      }
    }

    const prevPage = () => {
      if (currentPage.value > 1) {
        currentPage.value--
        fetchHandbooks()
      }
    }

    const goToCreate = () => {
      router.push('/handbooks/edit')
    }

    const goToEdit = (id) => {
      router.push(`/handbooks/${id}/edit`)
    }

    const goToView = (id) => {
      router.push(`/handbooks/${id}`)
    }

    const confirmDelete = (handbook) => {
      handbookToDelete.value = handbook
      showDeleteModal.value = true
    }

    const executeDelete = async () => {
      if (!handbookToDelete.value) return
      deleting.value = true
      try {
        const deleteResult = await handbooksApi.delete(handbookToDelete.value.id)
        if (!deleteResult.success) {
          console.error('Delete failed:', deleteResult.error || deleteResult.message)
          alert('Failed to delete handbook. Please try again.')
          deleting.value = false
          return
        }
        await fetchHandbooks()
        showDeleteModal.value = false
      } catch (error) {
        console.error('Failed to delete handbook:', error)
      } finally {
        deleting.value = false
      }
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString()
    }

    const getTargetLangs = (targetLang) => {
      if (!targetLang) return []
      return targetLang.split(',').map(lang => lang.trim()).filter(lang => lang)
    }

    const getLanguageName = (code) => {
      return languagesApi.getLanguageDisplayName(code)
    }

    onMounted(() => {
      if (!authStore.isAuthenticated) {
        activeTab.value = 'shared'
      }
      fetchHandbooks()
    })

    return {
      handbooks,
      loading,
      activeTab,
      isLoggedIn,
      itemsPerPage,
      goToCreate,
      goToEdit,
      goToView,
      confirmDelete,
      showDeleteModal,
      deleting,
      executeDelete,
      formatDate,
      getTargetLangs,
      getLanguageName,
      currentPage,
      nextPage,
      prevPage
    }
  }
}
</script>
