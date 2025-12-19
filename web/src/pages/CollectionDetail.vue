<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <!-- Header -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
      <div v-if="loadingCollection" class="animate-pulse space-y-4">
        <div class="h-8 bg-gray-200 rounded w-1/3"></div>
        <div class="h-4 bg-gray-200 rounded w-2/3"></div>
      </div>
      <div v-else-if="collection">
        <div class="flex justify-between items-start mb-4">
          <div>
            <div class="flex items-center gap-3 mb-2">
              <h1 class="text-3xl font-bold text-gray-900">{{ collection.name }}</h1>
              <span v-if="collection.is_public" class="bg-green-100 text-green-800 text-xs px-2 py-0.5 rounded-full">
                {{ $t('collections.public') || 'Public' }}
              </span>
              <span v-else class="bg-gray-100 text-gray-800 text-xs px-2 py-0.5 rounded-full">
                {{ $t('collections.private') || 'Private' }}
              </span>
            </div>
            <p class="text-gray-600">{{ collection.description }}</p>
          </div>
          <div v-if="isOwner" class="flex gap-2">
            <button 
              @click="openEditModal"
              class="text-gray-500 hover:text-blue-600 px-3 py-1 border border-gray-300 rounded hover:bg-gray-50 flex items-center gap-1"
            >
              <span>✏️</span> {{ $t('common.edit') || 'Edit' }}
            </button>
            <button 
              @click="confirmDelete"
              class="text-gray-500 hover:text-red-600 px-3 py-1 border border-gray-300 rounded hover:bg-gray-50 flex items-center gap-1"
            >
              <span>🗑️</span> {{ $t('common.delete') || 'Delete' }}
            </button>
          </div>
        </div>
        <div class="text-sm text-gray-500">
          {{ $t('collections.createdOn') || 'Created on' }}: {{ formatDate(collection.created_at) }}
        </div>
      </div>
      <div v-else class="text-center py-4 text-red-500">
        {{ $t('collections.notFound') || 'Collection not found' }}
      </div>
    </div>

    <!-- Items List -->
    <div class="mb-6">
      <h2 class="text-xl font-bold mb-4 flex items-center gap-2">
        {{ $t('collections.items') || 'Items' }}
        <span v-if="collection.items_count > 0" class="bg-blue-100 text-blue-800 text-sm font-normal px-2.5 py-0.5 rounded-full">
          {{ collection.items_count }}
        </span>
      </h2>

      <div v-if="loadingItems" class="flex justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>

      <div v-else-if="items.length === 0" class="text-center py-12 bg-gray-50 rounded-lg border border-gray-200">
        <p class="text-gray-500">{{ $t('collections.emptyItems') || 'This collection is empty.' }}</p>
        <router-link to="/search" class="text-blue-600 hover:text-blue-800 font-medium mt-2 inline-block">
          {{ $t('collections.browseExpressions') || 'Browse expressions to add' }}
        </router-link>
      </div>

      <div v-else class="space-y-4">
        <div 
          v-for="item in items" 
          :key="item.id"
          class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow"
        >
          <div class="flex justify-between">
            <div class="flex-grow">
              <router-link :to="`/detail/${item.expression_id}`" class="block group">
                <h3 class="text-lg font-medium text-gray-900 group-hover:text-blue-600 mb-1">
                  {{ item.expression?.text || 'Loading...' }}
                </h3>
                <div class="flex gap-2 text-sm text-gray-500 mb-2">
                  <span class="bg-gray-100 px-2 py-0.5 rounded">{{ item.expression?.language_code }}</span>
                  <span v-if="item.expression?.region_name" class="bg-gray-100 px-2 py-0.5 rounded">{{ item.expression?.region_name }}</span>
                </div>
              </router-link>
              <div v-if="item.note" class="bg-yellow-50 p-2 rounded text-sm text-gray-700 mt-2 border-l-4 border-yellow-300">
                {{ item.note }}
              </div>
            </div>
            <div v-if="isOwner" class="ml-4 flex flex-col items-end justify-between">
              <button 
                @click="removeItem(item)"
                class="text-gray-400 hover:text-red-500 p-1"
                :title="$t('collections.removeItem') || 'Remove from collection'"
              >
                ✕
              </button>
            </div>
          </div>
        </div>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="flex justify-center items-center gap-4 mt-8">
          <button 
            @click="prevPage" 
            :disabled="currentPage === 1"
            class="px-4 py-2 border rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            &laquo; {{ $t('common.prev') || 'Prev' }}
          </button>
          <span class="text-sm font-medium">
            {{ currentPage }} / {{ totalPages }}
          </span>
          <button 
            @click="nextPage" 
            :disabled="currentPage === totalPages"
            class="px-4 py-2 border rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ $t('common.next') || 'Next' }} &raquo;
          </button>
        </div>
      </div>
    </div>

    <!-- Edit Modal (Reusing logic if needed, simplify here) -->
    <!-- ... Similar to MyCollections edit modal ... -->
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getCollectionById, getCollectionItems, removeCollectionItem, deleteCollection } from '../services/collectionService'

export default {
  name: 'CollectionDetail',
  setup() {
    const route = useRoute()
    const router = useRouter()
    
    const collectionId = parseInt(route.params.id)
    const collection = ref(null)
    const items = ref([])
    const loadingCollection = ref(true)
    const loadingItems = ref(true)
    
    // Pagination state
    const currentPage = ref(1)
    const itemsPerPage = ref(20)
    const totalPages = computed(() => {
      if (!collection.value || !collection.value.items_count) return 0
      return Math.ceil(collection.value.items_count / itemsPerPage.value)
    })
    
    // Determine if current user is owner (mock check, ideally check user ID from store)
    // For now assuming if they can edit/delete successfully API allows it
    const isOwner = ref(true) // TODO: Implement real check against current user ID

    const fetchCollection = async () => {
      loadingCollection.value = true
      try {
        collection.value = await getCollectionById(collectionId)
        // Check ownership if user info is available
        const token = localStorage.getItem('authToken')
        if (token) {
           // Decoded token logic or user store check
        }
      } catch (error) {
        console.error('Failed to load collection:', error)
      } finally {
        loadingCollection.value = false
      }
    }

    const fetchItems = async () => {
      loadingItems.value = true
      try {
        const skip = (currentPage.value - 1) * itemsPerPage.value
        items.value = await getCollectionItems(collectionId, skip, itemsPerPage.value)
      } catch (error) {
        console.error('Failed to load items:', error)
      } finally {
        loadingItems.value = false
      }
    }

    const nextPage = () => {
      if (currentPage.value < totalPages.value) {
        currentPage.value++
        fetchItems()
      }
    }

    const prevPage = () => {
      if (currentPage.value > 1) {
        currentPage.value--
        fetchItems()
      }
    }

    const removeItem = async (item) => {
      if (confirm('Remove this expression from collection?')) {
        try {
          await removeCollectionItem(collectionId, item.expression_id)
          // Optimistically remove from list
          items.value = items.value.filter(i => i.id !== item.id)
        } catch (error) {
          console.error('Failed to remove item:', error)
          alert('Failed to remove item')
        }
      }
    }

    const confirmDelete = async () => {
      if (confirm('Are you sure you want to delete this collection?')) {
        try {
          await deleteCollection(collectionId)
          router.push('/collections')
        } catch (error) {
          console.error('Failed to delete collection:', error)
          alert('Failed to delete collection')
        }
      }
    }
    
    const openEditModal = () => {
      // Logic to open edit modal (can be shared or separate)
      alert('Edit functionality to be implemented similar to list page')
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString()
    }

    onMounted(() => {
      fetchCollection()
      fetchItems()
    })

    return {
      collection,
      items,
      loadingCollection,
      loadingItems,
      isOwner,
      removeItem,
      confirmDelete,
      openEditModal,
      formatDate,
      currentPage,
      totalPages,
      nextPage,
      prevPage
    }
  }
}
</script>
