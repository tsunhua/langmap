<template>
  <div v-if="visible" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click.stop>
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
      <h2 class="text-xl font-bold mb-4">{{ $t('add_to_collection') || 'Add to Collection' }}</h2>
      
      <div v-if="loading" class="flex justify-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>

      <div v-else-if="collections.length === 0" class="text-center py-6 text-gray-500">
        <p class="mb-4">{{ $t('no_collections') || 'You have no collections.' }}</p>
        <button 
          @click="createNewCollection"
          class="text-blue-600 font-medium"
        >
          {{ $t('new_collection') || '+ Create New Collection' }}
        </button>
      </div>

      <div v-else class="max-h-60 overflow-y-auto mb-4 border rounded">
        <div 
          v-for="col in collections" 
          :key="col.id"
          class="flex items-center p-3 hover:bg-gray-50 cursor-pointer border-b last:border-b-0"
          @click="toggleSelection(col.id)"
        >
          <input 
            type="checkbox" 
            :checked="selected.includes(col.id)"
            class="mr-3 h-4 w-4 text-blue-600 rounded"
            readonly
            @click.stop
          />
          <div>
            <div class="font-medium text-gray-900">{{ col.name }}</div>
            <div class="text-xs text-gray-500">
              {{ col.is_public ? $t('public') || 'Public' : $t('private') || 'Private' }} • {{ col.items_count || 0 }} items
            </div>
          </div>
        </div>
      </div>

      <div class="mb-4">
        <label class="block text-sm font-medium text-gray-700 mb-1">
          {{ $t('note_optional') || 'Note (Optional)' }}
        </label>
        <input 
          v-model="note" 
          type="text" 
          class="w-full border border-gray-300 rounded px-3 py-2 text-sm"
          :placeholder="$t('collections_notePlaceholder') || 'e.g. Useful for greeting'"
        />
      </div>

      <div class="flex justify-between items-center">
        <button 
          @click="createNewCollection"
          class="text-blue-600 text-sm font-medium"
        >
          {{ $t('new_collection') || '+ New Collection' }}
        </button>
        
        <div class="flex gap-2">
          <button 
            @click="$emit('close')"
            class="px-3 py-1.5 text-gray-600 hover:bg-gray-100 rounded"
          >
            {{ $t('cancel') || 'Cancel' }}
          </button>
          <button 
            @click="save"
            class="px-3 py-1.5 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
            :disabled="loading || submitting"
          >
            {{ submitting ? $t('saving') || 'Saving...' : ($t('save') || 'Save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { collectionsApi } from '../api/index.ts'

export default {
  name: 'AddToCollectionModal',
  props: {
    visible: {
      type: Boolean,
      required: true
    },
    expressionId: {
      type: [Number, String],
      required: true
    }
  },
  emits: ['close', 'updated'],
  setup(props, { emit }) {
    const { t } = useI18n()
    const router = useRouter()
    
    const collections = ref([])
    const selected = ref([])
    const initialSelected = ref([])
    const loading = ref(false)
    const submitting = ref(false)
    const note = ref('')

    const loadCollections = async () => {
      loading.value = true
      try {
        const [userCollectionsRes, containingIdsRes] = await Promise.all([
          collectionsApi.getAll(),
          collectionsApi.checkItem(props.expressionId)
        ])

        if (userCollectionsRes.success && userCollectionsRes.data) {
          collections.value = userCollectionsRes.data
        }

        if (containingIdsRes.success && containingIdsRes.data) {
          selected.value = [...(containingIdsRes.data || [])]
          initialSelected.value = [...(containingIdsRes.data || [])]
        } else {
          selected.value = []
          initialSelected.value = []
        }
      } catch (err) {
        console.error('Failed to load collections', err)
      } finally {
        loading.value = false
      }
    }

    watch(() => props.visible, (newVal) => {
      if (newVal) {
        loadCollections()
        note.value = ''
      }
    })

    const toggleSelection = (id) => {
      const idx = selected.value.indexOf(id)
      if (idx === -1) {
        selected.value.push(id)
      } else {
        selected.value.splice(idx, 1)
      }
    }

    const createNewCollection = () => {
      if (confirm(t('collections.redirectConfirm') || 'Go to My Collections to create a new one? Current progress won\'t be saved.')) {
        router.push('/collections')
      }
    }

    const save = async () => {
      submitting.value = true
      try {
        const toAdd = selected.value.filter(id => !initialSelected.value.includes(id))
        const toRemove = initialSelected.value.filter(id => !selected.value.includes(id))

        const promises = [
          ...toAdd.map(colId => collectionsApi.addItem(colId, props.expressionId, note.value)),
          ...toRemove.map(colId => collectionsApi.removeItem(colId, props.expressionId))
        ]

        if (promises.length > 0) {
          const results = await Promise.all(promises)
          // Check if any failed
          const failed = results.filter(r => !r.success)
          if (failed.length > 0) {
            console.error('Some operations failed:', failed)
          }
          alert(t('collections.updatedSuccess') || 'Collections updated successfully')
          emit('updated')
        }
      } catch (err) {
        console.error('Failed to update collections', err)
        alert(t('collections.updateError') || 'Failed to update some collections')
      } finally {
        submitting.value = false
      }
    }

    return {
      collections,
      selected,
      loading,
      submitting,
      note,
      toggleSelection,
      createNewCollection,
      save
    }
  }
}
</script>
