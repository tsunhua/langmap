<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold">{{ $t('collections.myCollections') || 'My Collections' }}</h1>
      <button 
        @click="openCreateModal"
        class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 flex items-center gap-2"
      >
        <span class="text-xl">+</span>
        {{ $t('collections.create') || 'Create New' }}
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="collections.length === 0" class="text-center py-12 bg-gray-50 rounded-lg border border-gray-200">
      <h3 class="text-xl font-medium text-gray-900 mb-2">{{ $t('collections.emptyTitle') || 'No collections yet' }}</h3>
      <p class="text-gray-500 mb-6">{{ $t('collections.emptyDesc') || 'Create your first collection to start organizing expressions.' }}</p>
      <button 
        @click="openCreateModal"
        class="text-blue-600 hover:text-blue-800 font-medium"
      >
        {{ $t('collections.createFirst') || 'Create Collection' }}
      </button>
    </div>

    <!-- Collections Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="collection in collections" 
        :key="collection.id"
        class="bg-white rounded-lg shadow border border-gray-200 hover:shadow-md transition-shadow cursor-pointer"
        @click="goToDetail(collection.id)"
      >
        <div class="p-5">
          <div class="flex justify-between items-start mb-2">
            <h3 class="text-lg font-bold text-gray-900 truncate pr-2">{{ collection.name }}</h3>
            <span v-if="collection.is_public" class="bg-green-100 text-green-800 text-xs px-2 py-0.5 rounded-full">
              {{ $t('collections.public') || 'Public' }}
            </span>
            <span v-else class="bg-gray-100 text-gray-800 text-xs px-2 py-0.5 rounded-full">
              {{ $t('collections.private') || 'Private' }}
            </span>
          </div>
          <p class="text-gray-600 text-sm mb-4 line-clamp-2 h-10">
            {{ collection.description || ($t('collections.noDescription') || 'No description') }}
          </p>
          <div class="flex justify-between items-center text-xs text-gray-500">
            <span>{{ formatDate(collection.created_at) }}</span>
            <div class="flex gap-2" @click.stop>
              <button 
                @click="openEditModal(collection)"
                class="hover:text-blue-600 p-1"
                :title="$t('common.edit') || 'Edit'"
              >
                ✏️
              </button>
              <button 
                @click="confirmDelete(collection)"
                class="hover:text-red-600 p-1"
                :title="$t('common.delete') || 'Delete'"
              >
                🗑️
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="currentPage > 1 || collections.length === 20" class="flex justify-center items-center gap-4 mt-8">
      <button 
        @click="prevPage" 
        :disabled="currentPage === 1"
        class="px-4 py-2 border rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        &laquo; {{ $t('common.prev') || 'Prev' }}
      </button>
      <span class="text-sm font-medium">
        {{ $t('common.page') || 'Page' }} {{ currentPage }}
      </span>
      <button 
        @click="nextPage" 
        :disabled="collections.length < 20"
        class="px-4 py-2 border rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {{ $t('common.next') || 'Next' }} &raquo;
      </button>
    </div>

    <!-- Create/Edit Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
        <h2 class="text-xl font-bold mb-4">
          {{ isEditing ? ($t('collections.editTitle') || 'Edit Collection') : ($t('collections.createTitle') || 'New Collection') }}
        </h2>
        
        <form @submit.prevent="saveCollection">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('collections.nameLabel') || 'Name' }} *
            </label>
            <input 
              v-model="form.name" 
              type="text" 
              required
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              :placeholder="$t('collections.namePlaceholder') || 'e.g. My Favorites'"
            />
          </div>
          
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('collections.descLabel') || 'Description' }}
            </label>
            <textarea 
              v-model="form.description" 
              rows="3"
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              :placeholder="$t('collections.descPlaceholder') || 'What is this collection about?'"
            ></textarea>
          </div>
          
          <div class="mb-6">
            <label class="flex items-center cursor-pointer">
              <input 
                v-model="form.is_public" 
                type="checkbox" 
                class="form-checkbox h-4 w-4 text-blue-600 rounded"
              />
              <span class="ml-2 text-sm text-gray-700">{{ $t('collections.makePublic') || 'Make Public' }}</span>
            </label>
          </div>
          
          <div class="flex justify-end gap-3">
            <button 
              type="button" 
              @click="closeModal"
              class="px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50"
            >
              {{ $t('common.cancel') || 'Cancel' }}
            </button>
            <button 
              type="submit" 
              class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              :disabled="submitting"
            >
              {{ submitting ? ($t('common.saving') || 'Saving...') : ($t('common.save') || 'Save') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { getCollections, createCollection, updateCollection, deleteCollection } from '../services/collectionService'

export default {
  name: 'MyCollections',
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
        // Fetch user's collections with pagination
        collections.value = await getCollections({ skip, limit: itemsPerPage.value })
      } catch (error) {
        console.error('Failed to load collections:', error)
        alert('Failed to load collections')
      } finally {
        loading.value = false
      }
    }

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
          await updateCollection(currentId.value, data)
        } else {
          await createCollection(data)
        }
        
        await fetchCollections()
        closeModal()
      } catch (error) {
        console.error('Failed to save collection:', error)
        alert('Failed to save collection')
      } finally {
        submitting.value = false
      }
    }
    
    const confirmDelete = async (collection) => {
      if (confirm(t('collections.deleteConfirm') || `Are you sure you want to delete "${collection.name}"?`)) {
        try {
          await deleteCollection(collection.id)
          await fetchCollections()
        } catch (error) {
          console.error('Failed to delete collection:', error)
          alert('Failed to delete collection')
        }
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
      fetchCollections()
    })
    
    return {
      collections,
      loading,
      showModal,
      isEditing,
      submitting,
      form,
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
