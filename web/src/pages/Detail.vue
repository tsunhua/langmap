<template>
   <div class="max-w-7xl mx-auto">
     <div v-if="loading" class="flex items-center justify-center py-12">
      <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span class="ml-2 text-slate-600">{{ $t('loading') }}</span>
    </div>
    
    <div v-else-if="item" class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Left column: current item + translations as a unified list -->
      <div class="lg:col-span-2 space-y-6">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="border-b border-slate-200 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-800">{{ $t('expression_details') }}</h3>
          </div>
          <div class="p-3">
            <ExpressionCard
              :item="item"
              :key="item.id"
              :editable="true"
              :can-delete="canDeleteExpression"
              :is-deleting="deleting"
              @update-tags="handleTagsUpdate"
              @delete="handleDelete"
            />
          </div>
        </div>
        
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="border-b border-slate-200 px-6 py-4 flex justify-between items-center">
            <h3 class="text-xl font-bold text-slate-800">{{ $t('associated_expressions') }}
              <span class="text-slate-500 ml-2">({{ translations.length }})</span>
            </h3>

            <button 
              v-if="!associateMode" 
              @click="associateMode = true" 
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 flex items-center"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              {{ $t('associate_expressions') }}
            </button>
            <button 
              v-else 
              @click="associateMode = false" 
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2 flex items-center"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
              {{ $t('cancel') }}
            </button>
          </div>
          
          <div class="p-3">
            <div v-if="associateMode" class="bg-slate-50 rounded-lg p-5 mb-6">
              <div class="flex items-center gap-3 mb-4">
                <div class="flex-1">
                  <input 
                    v-model="assocQuery" 
                    :placeholder="$t('search_placeholder')" 
                    class="block w-full rounded-md border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2.5 px-4" 
                    @keydown.enter="searchAssociate" 
                  />
                </div>
                <button @click="searchAssociate" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2.5">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  {{ $t('search') }}
                </button>
              </div>
              
              <div>
                <div v-if="assocLoading" class="flex items-center justify-center py-4">
                  <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span class="ml-2 text-slate-600">{{ $t('searching') }}</span>
                </div>
                
                <div v-else-if="assocSearched && assocResults.length === 0" class="text-center py-4 text-slate-500">
                  {{ $t('no_expressions_found') }}
                  <div class="mt-4">
                    <button 
                      @click="openCreateExpressionModal"
                      class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                      </svg>
                      {{ $t('expression') }}
                    </button>
                  </div>
                </div>
                
                <div v-else class="space-y-2">
                  <div 
                    v-for="c in assocResults" 
                    :key="c && c.id" 
                    class="flex gap-3 items-center p-3 bg-white rounded-lg"
                  >
                    <div v-if="c && item && c.id !== item.id" class="flex-1">
                      <ExpressionCard :item="c" />
                    </div>
                    <div v-if="c && item && c.id !== item.id">
                      <button 
                        v-if="!isLinked(c.id)" 
                        @click="associateWith(c)" 
                        class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2"
                      >
                        {{ $t('link') }}
                      </button>
                      <span v-else class="text-slate-500 px-4 py-2">
                        {{ $t('already_linked') }}
                      </span>
                    </div>
                  </div>
                  
                  <div v-if="assocMsg" class="p-3 rounded-lg bg-green-50 text-green-700">
                    {{ assocMsg }}
                  </div>
                  <div v-if="assocHasCurrent" class="p-3 rounded-lg bg-amber-50 text-amber-700">
                    {{ $t('includes_current') }}
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Associated expressions list -->
            <div>
              <div v-if="translations.length === 0" class="text-center py-8 text-slate-500">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
                <p class="mt-2">{{ $t('no_meanings') }}</p>
                <button 
                  @click="associateMode = true" 
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-3"
                >
                  {{ $t('associate_expressions') }}
                </button>
              </div>
              
              <div v-else class="space-y-2">
                <div 
                  v-for="expr in translations" 
                  :key="expr.id" 
                  class="flex items-center gap-3 py-1 rounded-lg"
                >
                  <div class="flex-1">
                    <ExpressionCard 
                      :item="expr" 
                      :show-unlink="expr.id !== item.id"
                      :item-id="item.id"
                      @unlink="unlink"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Right column: version history -->
      <div class="lg:col-span-1">
        <VersionHistory :expressionId="id" />
      </div>
    </div>
    
    <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <h3 class="text-xl font-semibold text-slate-800 mt-4">{{ $t('expression_not_found') }}</h3>
      <p class="text-slate-600 mt-2">{{ $t('expression_not_found_info') }}</p>
      <button 
        @click="$router.push({ name: 'Home' })" 
        class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-4"
      >
        {{ $t('back_to_search') }}
      </button>
    </div>
    
    <!-- Create Expression Modal -->
    <CreateExpression 
      :visible="showCreateExpressionModal"
      :initial-meaning-id="currentMeaningIdForAssociation"
      :initial-text="assocQuery"
      @close="showCreateExpressionModal = false"
      @expression-created="handleExpressionCreated"
    />

  </div>
</template>

<script>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import ExpressionCard from '../components/ExpressionCard.vue'
import VersionHistory from '../components/VersionHistory.vue'
import CreateExpression from '../components/CreateExpression.vue'

export default {
  name: 'Detail',
  components: { ExpressionCard, VersionHistory, CreateExpression },
  props: ['id'],
  setup (props) {
    const route = useRoute()
    const router = useRouter()
    const { t } = useI18n()
    const item = ref(null)
    const loading = ref(false)
    const transLoading = ref(false)
    const translations = ref([])
    const meanings = ref([])
    const currentUser = ref(null)
    const deleting = ref(false)
    
    // Association mode
    const associateMode = ref(false)
    const assocQuery = ref('')
    const assocResults = ref([])
    const assocLoading = ref(false)
    const assocMsg = ref('')
    const assocHasCurrent = ref(false)
    const assocSearched = ref(false) // 新增状态，标记是否已搜索过
    
    // Create expression modal
    const showCreateExpressionModal = ref(false)
    const currentMeaningIdForAssociation = ref(null)


    
    const linkedIds = computed(() => {
      const s = new Set()
      if (item.value && item.value.id) s.add(item.value.id)
      for (const m of meanings.value || []) {
        if (m && m.members) {
          for (const mem of m.members) {
            if (mem && mem.id) s.add(mem.id)
          }
        }
      }
      return s
    })

    // safe helper to check if an id is linked
    function isLinked (id) {
      try {
        return linkedIds && linkedIds.value && typeof linkedIds.value.has === 'function' ? linkedIds.value.has(id) : false
      } catch (e) {
        return false
      }
    }

    async function load () {
      loading.value = true
      try {
        const res = await fetch(`/api/v1/expressions/${props.id}`)
        if (!res.ok) throw new Error('not found')
        item.value = await res.json()
        // fetch translations via server-side meaning grouping
        transLoading.value = true
        try {
          const tr = await fetch(`/api/v1/expressions/${props.id}/translations`)
          if (tr.ok) {
            translations.value = await tr.json()
          } else {
            translations.value = []
          }
        } catch (e) {
          console.warn('translations fetch failed', e)
          translations.value = []
        } finally {
          transLoading.value = false
        }
        // fetch meanings for this expression and their members
        try {
          // 如果当前表达式有meaning_id，则获取meaning表达式
          if (item.value.meaning_id) {
            const mr = await fetch(`/api/v1/expressions/${item.value.meaning_id}`)
            if (mr.ok) {
              const meaningExpr = await mr.json()
              // 设置meaning，模仿原来的格式
              meanings.value = [{
                id: meaningExpr.id,
                text: meaningExpr.text,
                language_code: meaningExpr.language_code,
                description: meaningExpr.description || '',
                members: translations.value
              }]
            } else {
              meanings.value = []
            }
          } else {
            // 如果没有meaning_id，则当前表达式本身就是meaning
            meanings.value = [{
              id: item.value.id,
              text: item.value.text,
              language_code: item.value.language_code,
              description: item.value.description || '',
              members: translations.value
            }]
          }
        } catch (e) {
          meanings.value = []
        }
      } catch (e) {
        console.warn(e)
      } finally {
        loading.value = false
      }
    }

    async function searchAssociate () {
      assocLoading.value = true
      assocMsg.value = ''
      try {
        const params = new URLSearchParams()
        if (assocQuery.value) params.set('q', assocQuery.value)
        const url = `/api/v1/search?${params.toString()}`
        console.debug('Assoc search URL:', url)
        const res = await fetch(url)
        if (!res.ok) throw new Error('search failed')
        assocResults.value = await res.json()
        console.debug('Assoc search returned', assocResults.value.length, 'items')
        assocMsg.value = t('found_candidates', { count: assocResults.value.length })
        assocSearched.value = true // 标记已搜索
      } catch (e) {
        assocMsg.value = String(e)
        assocResults.value = []
        assocSearched.value = true // 即使出错也标记已搜索
      } finally {
        assocLoading.value = false
      }
    }

    async function associateWith (target) {
      assocMsg.value = ''

      // Check if user is authenticated
      const token = localStorage.getItem('authToken')
      if (!token) {
        assocMsg.value = t('must_be_logged_in_to_associate')
        return
      }

      try {
        // Verify target expression exists before attempting to link
        const verifyRes = await fetch(`/api/v1/expressions/${target.id}`)
        if (!verifyRes.ok) {
          assocMsg.value = t('target_expression_not_found')
          return
        }
        const verifiedTarget = await verifyRes.json()
        if (!verifiedTarget) {
          assocMsg.value = t('target_expression_no_longer_exists')
          return
        }

        // 使用智能语义锚点选择 API
        // 收集所有需要关联的表达式 ID（包括当前表达式、目标表达式，以及它们现有的 meaning_id 指向的表达式）
        const expressionIds = new Set([props.id, target.id])

        // 添加当前表达式的 meaning_id（如果存在）
        if (item.value.meaning_id) {
          expressionIds.add(item.value.meaning_id)
        }

        // 添加目标表达式的 meaning_id（如果存在）
        if (verifiedTarget.meaning_id) {
          expressionIds.add(verifiedTarget.meaning_id)
        }

        // 调用智能语义锚点选择 API
        const associateRes = await fetch('/api/v1/expressions/associate', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ expression_ids: Array.from(expressionIds) })
        })

        if (!associateRes.ok) {
          const errorData = await associateRes.json()
          throw new Error(errorData.error || 'Failed to associate expressions')
        }

        const result = await associateRes.json()
        assocMsg.value = t('linked_with_anchor', { anchorId: result.meaning_id })

        // refresh translations and meanings
        await load()
      } catch (e) {
        console.error('Association error:', e)
        assocMsg.value = String(e)
      }
    }

    async function handleTagsUpdate(newTags) {
      if (!item.value) return

      try {
        const token = localStorage.getItem('authToken')
        if (!token) {
          // Ideally show a toast or alert
          console.warn('Login required to update tags')
          return
        }

        const res = await fetch(`/api/v1/expressions/${props.id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            tags: JSON.stringify(newTags)
          })
        })

        if (!res.ok) throw new Error(t('failed_to_update_tags'))

        // Update local item
        item.value.tags = JSON.stringify(newTags)

      } catch (e) {
        console.error('Error updating tags:', e)
        alert(t('failed_to_update_tags'))
      }
    }

    async function unlink(target) {
      if (!confirm(t('confirm_unlink'))) return

      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/expressions/${target.id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ meaning_id: null })
        })

        if (!res.ok) throw new Error(t('failed_to_unlink'))

        // Refresh to show updated list
        await load()
      } catch (e) {
        console.error('Error unlinking:', e)
        alert(t('failed_to_unlink'))
      }
    }

    // Open create expression modal
    function openCreateExpressionModal() {
      // Pass the current meaning's id to the modal
      currentMeaningIdForAssociation.value = (meanings.value && meanings.value.length > 0 ? meanings.value[0].id : null);
      showCreateExpressionModal.value = true;
    }

    // Handle expression created event from the modal
    async function handleExpressionCreated(createdExpression) {
      showCreateExpressionModal.value = false;
      assocMsg.value = t('expression_created_linked');

      // Refresh the page data to show the newly created expression
      await load();

      // Reset search results and query
      assocResults.value = [];
      assocQuery.value = '';
      assocSearched.value = false; // 重置搜索状态
    }

    // Load current user
    async function loadCurrentUser() {
      const token = localStorage.getItem('authToken')
      if (!token) {
        currentUser.value = null
        return
      }

      try {
        const response = await fetch('/api/v1/users/me', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (response.ok) {
          const result = await response.json()
          currentUser.value = result.data
        } else {
          currentUser.value = null
        }
      } catch (e) {
        console.warn('Failed to load current user:', e)
        currentUser.value = null
      }
    }

    // Check if current user can delete the expression
    const canDeleteExpression = computed(() => {
      if (!currentUser.value || !item.value) {
        return false
      }

      // Admin can delete any expression
      if (currentUser.value.role === 'admin') {
        return true
      }

      // Creator can delete their own expression
      return item.value.created_by === currentUser.value.username
    })

    // Handle delete expression
    async function handleDelete() {
      if (!item.value) return

      if (!confirm(t('confirm_delete_expression'))) {
        return
      }

      deleting.value = true
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        deleting.value = false
        return
      }

      try {
        const response = await fetch(`/api/v1/expressions/${item.value.id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (!response.ok) {
          if (response.status === 403) {
            alert(t('delete_permission_denied'))
          } else if (response.status === 404) {
            alert(t('expression_not_found'))
          } else {
            const error = await response.json()
            alert(error.error || t('delete_failed'))
          }
          deleting.value = false
          return
        }

        // Redirect to home after successful deletion
        router.push('/')
      } catch (e) {
        console.error('Error deleting expression:', e)
        alert(t('delete_failed'))
        deleting.value = false
      }
    }

    onMounted(() => {
      load()
      loadCurrentUser()
    })
    // when the route param `id` changes the same component instance is reused by the router;
    // watch the prop and reload the details when it changes
    watch(() => props.id, (newId, oldId) => {
      if (newId !== oldId) load()
    })
    return {
      item,
      loading,
      translations,
      transLoading,
      associateMode,
      assocQuery,
      assocResults,
      assocLoading,
      assocMsg,
      meanings,
      linkedIds,
      assocHasCurrent,
      isLinked,
      searchAssociate,
      associateWith,
      // Create expression modal
      showCreateExpressionModal,
      currentMeaningIdForAssociation,
      openCreateExpressionModal,
      handleExpressionCreated,
      // 新增的搜索状态
      assocSearched,
      handleTagsUpdate,
      unlink,
      // Delete expression
      canDeleteExpression,
      deleting,
      handleDelete
      }
    }
}
</script>