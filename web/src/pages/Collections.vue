<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold text-gray-900">{{ $t('collections') }}</h1>
      <button v-if="isLoggedIn && activeTab === 'my'" @click="openCreateModal"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 shadow-sm transition-all">
        <span class="text-xl">+</span>
        {{ $t('new_collection') }}
      </button>
    </div>

    <!-- Tabs -->
    <div class="flex border-b border-gray-200 mb-8 space-x-8">
      <button v-if="isLoggedIn" @click="activeTab = 'my'"
        :class="['pb-4 text-sm font-medium transition-colors relative', activeTab === 'my' ? 'text-blue-600' : 'text-gray-500 hover:text-gray-700']">
        {{ $t('my_collections') }}
        <div v-if="activeTab === 'my'" class="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600"></div>
      </button>
      <button @click="activeTab = 'shared'"
        :class="['pb-4 text-sm font-medium transition-colors relative', activeTab === 'shared' ? 'text-blue-600' : 'text-gray-500 hover:text-gray-700']">
        {{ $t('shared_collections') }}
        <div v-if="activeTab === 'shared'" class="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600"></div>
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="collections.length === 0"
      class="text-center py-16 bg-gray-50 rounded-2xl border border-dashed border-gray-300">
      <div class="text-4xl mb-4">📂</div>
      <h3 class="text-xl font-medium text-gray-900 mb-2">{{ $t('no_collections_found') }}</h3>
      <p v-if="activeTab === 'my'" class="text-gray-500 mb-6">{{ $t('empty_info') }}</p>
      <button v-if="isLoggedIn && activeTab === 'my'" @click="openCreateModal"
        class="text-blue-600 hover:text-blue-800 font-semibold">
        {{ $t('new_collection') }}
      </button>
    </div>

    <!-- Collections Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="collection in collections" :key="collection.id"
        class="group bg-white rounded-xl shadow-sm border border-gray-200 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 cursor-pointer overflow-hidden flex flex-col"
        @click="goToDetail(collection.id)">
        <div class="p-6 flex-grow">
          <div class="flex justify-between items-start mb-3">
            <h3 class="text-lg font-bold text-gray-900 group-hover:text-blue-600 transition-colors truncate pr-2">
              {{ collection.name }}
            </h3>
            <span v-if="collection.is_public"
              class="bg-green-100 text-green-800 text-[10px] uppercase tracking-wider font-bold px-2 py-0.5 rounded-full">
              {{ $t('public') }}
            </span>
          </div>
          <p v-if="collection.description" class="text-gray-600 text-sm mb-4 line-clamp-3 leading-relaxed">
            {{ collection.description }}
          </p>
          <div class="flex items-center gap-2 text-xs text-gray-400 font-medium">
            <span>{{ collection.items_count || 0 }} {{ $t('items') }}</span>
          </div>
        </div>
        <div
          class="px-6 py-4 bg-gray-50 border-t border-gray-100 flex justify-between items-center text-[10px] text-gray-400 uppercase tracking-widest font-bold">
          <span>{{ formatDate(collection.created_at) }}</span>
          <div v-if="isLoggedIn && activeTab === 'my'" class="flex gap-3" @click.stop>
            <button @click="openEditModal(collection)" class="hover:text-blue-600 transition-colors">
              {{ $t('edit') }}
            </button>
            <button @click="confirmDelete(collection)" class="hover:text-red-600 transition-colors">
              {{ $t('delete') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="currentPage > 1 || collections.length === itemsPerPage"
      class="flex justify-center items-center gap-4 mt-12 pb-8">
      <button @click="prevPage" :disabled="currentPage === 1"
        class="px-5 py-2 border border-gray-200 rounded-xl hover:bg-gray-50 disabled:opacity-30 disabled:cursor-not-allowed text-sm font-medium transition-colors">
        &laquo; {{ $t('prev') }}
      </button>
      <span class="text-sm font-semibold bg-gray-100 px-4 py-2 rounded-lg text-gray-700">
        {{ $t('page') }} {{ currentPage }}
      </span>
      <button @click="nextPage" :disabled="collections.length < itemsPerPage"
        class="px-5 py-2 border border-gray-200 rounded-xl hover:bg-gray-50 disabled:opacity-30 disabled:cursor-not-allowed text-sm font-medium transition-colors">
        {{ $t('next') }} &raquo;
      </button>
    </div>

    <!-- Create/Edit Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
        <h2 class="text-xl font-bold mb-4">
          {{ isEditing ? $t('edit_collection') : $t('new_collection') }}
        </h2>

        <form @submit.prevent="saveCollection">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('collection_name') }} *
            </label>
            <input v-model="form.name" type="text" required
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              :placeholder="$t('collection_desc_placeholder')" />
          </div>

          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('description') }}
            </label>
            <textarea v-model="form.description" rows="3"
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              :placeholder="$t('collection_desc_placeholder')"></textarea>
          </div>

          <div class="mb-6">
            <label class="flex items-center cursor-pointer">
              <input v-model="form.is_public" type="checkbox" class="form-checkbox h-4 w-4 text-blue-600 rounded" />
              <span class="ml-2 text-sm text-gray-700">{{ $t('public_access') }}</span>
            </label>
          </div>

          <div class="flex justify-end gap-3">
            <button type="button" @click="closeModal"
              class="px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50">
              {{ $t('cancel') || 'Cancel' }}
            </button>
            <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              :disabled="submitting">
              {{ submitting ? ($t('saving') || 'Saving...') : ($t('save') || 'Save') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <ConfirmModal v-model="showDeleteModal" :message="deleteMessage" :loading="deleting"
      :loadingText="$t('deleting') || 'Deleting...'" :confirmText="$t('delete') || 'Delete'" @confirm="executeDelete" />
  </div>
</template>

<script>
import { ref, onMounted, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { collectionsApi } from '../api/index.ts'
import ConfirmModal from '../components/ConfirmModal.vue'

export default {
  name: 'Collections',
  components: { ConfirmModal },
  setup() {
    const router = useRouter()
    const { t } = useI18n()

    // State
    const collections = ref([])
    const loading = ref(true)
    const showModal = ref(false)
    const isEditing = ref(false)
    const submitting = ref(false)
    const currentId = ref(null)
    const activeTab = ref('my')
    const isLoggedIn = ref(!!localStorage.getItem('authToken'))

    // Delete Confirmation
    const showDeleteModal = ref(false)
    const itemToDelete = ref(null)
    const deleteMessage = ref('')
    const deleting = ref(false)

    const form = reactive({
      name: '',
      description: '',
      is_public: false
    })

    // Pagination state
    const currentPage = ref(1)
    const itemsPerPage = ref(20)

    // Load collections
    const fetchCollections = async () => {
      loading.value = true
      try {
        const skip = (currentPage.value - 1) * itemsPerPage.value
        const params = { skip, limit: itemsPerPage.value }

        if (activeTab.value === 'shared') {
          params.isPublic = true
        } else {
          // If tab is 'my' but not logged in (shouldn't happen with UI guards but for safety)
          if (!isLoggedIn.value) {
            collections.value = []
            return
          }
        }

        const result = await collectionsApi.getAll(params)
        if (result.success && result.data) {
          collections.value = result.data
        }
      } catch (error) {
        console.error('Failed to load collections:', error)
      } finally {
        loading.value = false
      }
    }

    watch(activeTab, () => {
      currentPage.value = 1
      fetchCollections()
    })

    const nextPage = () => {
      if (collections.value.length === itemsPerPage.value) {
        currentPage.value++
        fetchCollections()
      }
    }

    const prevPage = () => {
      if (currentPage.value > 1) {
        currentPage.value--
        fetchCollections()
      }
    }

    // Modal handlers
    const openCreateModal = () => {
      isEditing.value = false
      currentId.value = null
      form.name = ''
      form.description = ''
      form.is_public = false
      showModal.value = true
    }

    const openEditModal = (collection) => {
      isEditing.value = true
      currentId.value = collection.id
      form.name = collection.name
      form.description = collection.description || ''
      form.is_public = !!collection.is_public
      showModal.value = true
    }

    const closeModal = () => {
      showModal.value = false
    }

    // CRUD Operations
    const saveCollection = async () => {
      if (!form.name.trim()) return

      submitting.value = true
      try {
        const data = {
          name: form.name,
          description: form.description,
          is_public: form.is_public
        }

        if (isEditing.value) {
          const updateResult = await collectionsApi.update(currentId.value, data)
          if (!updateResult.success) {
            console.error('Update failed:', updateResult.error || updateResult.message)
            alert(updateResult.error || updateResult.message || 'Failed to update collection')
            submitting.value = false
            return
          }
        } else {
          const createResult = await collectionsApi.create(data)
          if (!createResult.success) {
            console.error('Create failed:', createResult.error || createResult.message)
            alert(createResult.error || createResult.message || 'Failed to create collection')
            submitting.value = false
            return
          }
        }

        await fetchCollections()
        closeModal()
      } catch (error) {
        console.error('Failed to save collection:', error)
      } finally {
        submitting.value = false
      }
    }

    const confirmDelete = (collection) => {
      itemToDelete.value = collection
      deleteMessage.value = t('collections.deleteConfirm')
      showDeleteModal.value = true
    }

    const executeDelete = async () => {
      if (!itemToDelete.value) return
      deleting.value = true
      try {
        const deleteResult = await collectionsApi.delete(itemToDelete.value.id)
        if (!deleteResult.success) {
          console.error('Delete failed:', deleteResult.error || deleteResult.message)
          alert(deleteResult.error || deleteResult.message || 'Failed to delete collection')
          deleting.value = false
          return
        }
        await fetchCollections()
        showDeleteModal.value = false
      } catch (error) {
        console.error('Failed to delete collection:', error)
      } finally {
        deleting.value = false
      }
    }

    const goToDetail = (id) => {
      router.push(`/collections/${id}`)
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString()
    }

    onMounted(() => {
      if (!isLoggedIn.value) {
        activeTab.value = 'shared'
      }
      fetchCollections()
    })

    return {
      collections,
      loading,
      showModal,
      isEditing,
      submitting,
      form,
      activeTab,
      isLoggedIn,
      itemsPerPage,
      showDeleteModal,
      deleteMessage,
      deleting,
      executeDelete,
      openCreateModal,
      openEditModal,
      closeModal,
      saveCollection,
      confirmDelete,
      goToDetail,
      formatDate,
      currentPage,
      nextPage,
      prevPage
    }
  }
}
</script>
