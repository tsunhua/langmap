<template>
  <div class="max-w-7xl mx-auto">
    <div class="flex items-center mb-6">
      <button @click="$router.push({ name: 'search' })" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 px-4 py-2 flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
        </svg>
        Back to Search
      </button>
    </div>
    
    <div v-if="loading" class="flex items-center justify-center py-12">
      <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span class="ml-2 text-slate-600">Loading expression details...</span>
    </div>
    
    <div v-else-if="item" class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Left column: current item + translations as a unified list -->
      <div class="lg:col-span-2 space-y-6">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="border-b border-slate-200 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-800">Expression Details</h3>
          </div>
          <div class="p-3">
            <ExpressionCard :item="item" :key="item.id" />
          </div>
        </div>
        
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="border-b border-slate-200 px-6 py-4 flex justify-between items-center">
            <h3 class="text-xl font-bold text-slate-800">Associated Meanings</h3>
            <button 
              v-if="!associateMode" 
              @click="associateMode = true" 
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 flex items-center"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              Associate Expressions
            </button>
            <button 
              v-else 
              @click="associateMode = false" 
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2 flex items-center"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
              Cancel
            </button>
          </div>
          
          <div class="p-3">
            <div v-if="associateMode" class="bg-slate-50 rounded-lg p-5 mb-6">
              <div class="flex items-center gap-3 mb-4">
                <div class="flex-1">
                  <input 
                    v-model="assocQuery" 
                    placeholder="Search expressions to associate..." 
                    class="block w-full rounded-md border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2.5 px-4" 
                    @keydown.enter="searchAssociate" 
                  />
                </div>
                <button @click="searchAssociate" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2.5">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  Search
                </button>
              </div>
              
              <div>
                <div v-if="assocLoading" class="flex items-center justify-center py-4">
                  <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span class="ml-2 text-slate-600">Searching...</span>
                </div>
                
                <div v-else-if="assocResults.length === 0" class="text-center py-4 text-slate-500">
                  No expressions found. Try different search terms.
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
                        Link
                      </button>
                      <span v-else class="text-slate-500 px-4 py-2">
                        Already linked
                      </span>
                    </div>
                  </div>
                  
                  <div v-if="assocMsg" class="p-3 rounded-lg bg-green-50 text-green-700">
                    {{ assocMsg }}
                  </div>
                  <div v-if="assocHasCurrent" class="p-3 rounded-lg bg-amber-50 text-amber-700">
                    Search results include the current expression.
                  </div>
                  
                  <div class="pt-4 border-t border-slate-200 mt-4">
                    <label class="block text-sm font-medium text-slate-700 mb-1 font-semibold">Link to meaning:</label>
                    <div class="flex flex-wrap gap-3 mt-2">
                      <select v-model="selectedMeaningId" class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 flex-1">
                        <option :value="null">-- Select meaning --</option>
                        <option v-for="m in meanings" :key="m.id" :value="m.id">
                          {{ m.gloss }} — {{ m.description }}
                        </option>
                        <option :value="'__new'">Create new meaning…</option>
                      </select>
                      
                      <div v-if="selectedMeaningId === '__new'" class="flex-1">
                        <input 
                          v-model="newMeaningGloss" 
                          placeholder="New meaning gloss" 
                          class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50" 
                        />
                        <button 
                          @click="createMeaning" 
                          class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-2 w-full"
                        >
                          Create Meaning
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Meanings list -->
            <div>
              <div v-if="meanings.length === 0" class="text-center py-8 text-slate-500">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
                <p class="mt-2">No meanings associated with this expression</p>
                <button 
                  @click="associateMode = true" 
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-3"
                >
                  Associate with meanings
                </button>
              </div>
              
              <div v-else class="space-y-4">
                <div 
                  v-for="m in meanings" 
                  :key="m.id" 
                  class="border border-slate-200 rounded-lg overflow-hidden"
                >
                  <div class="bg-slate-50 px-5 py-3 flex justify-between items-center">
                    <div class="font-semibold text-slate-800">
                      {{ m.gloss }} 
                      <span class="font-normal text-slate-600">
                        {{ m.description ? '— ' + m.description : '' }}
                      </span>
                      <span class="text-slate-500 ml-2">
                        ({{ m.members ? m.members.length - 1 : 0 }} expressions)
                      </span>
                    </div>
                    <button 
                      @click="toggleMeaning(m.id)" 
                      class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 py-1 px-3 text-sm"
                    >
                      {{ isExpanded(m.id) ? 'Collapse' : 'Expand' }}
                    </button>
                  </div>
                  
                  <div v-show="isExpanded(m.id)" class="p-4 bg-white">
                    <div v-if="!m.members || m.members.length === 0" class="text-slate-500 py-2">
                      No associated expressions.
                    </div>
                    <div v-else class="space-y-2">
                      <div 
                        v-for="mem in m.members.filter(m => item && m && m.id !== item.id)" 
                        :key="mem.id" 
                        class="flex items-center gap-3 py-1 rounded-lg"
                      >
                        <div class="flex-1">
                          <ExpressionCard :item="mem" />
                        </div>
                      </div>
                    </div>
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
      <h3 class="text-xl font-semibold text-slate-800 mt-4">Expression not found</h3>
      <p class="text-slate-600 mt-2">The requested expression could not be found</p>
      <button 
        @click="$router.push({ name: 'home' })" 
        class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-4"
      >
        Back to Search
      </button>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, watch, computed } from 'vue'
import VersionHistory from '../components/VersionHistory.vue'
import ExpressionCard from '../components/ExpressionCard.vue'

export default {
  name: 'Detail',
  components: { VersionHistory, ExpressionCard },
  props: ['id'],
  setup (props) {
    const item = ref(null)
    const loading = ref(false)
    const translations = ref([])
    const transLoading = ref(false)
    const associateMode = ref(false)
    const assocQuery = ref('')
    const assocResults = ref([])
    const assocLoading = ref(false)
    const assocMsg = ref('')
    const meanings = ref([])
    const selectedMeaningId = ref(null)
    const newMeaningGloss = ref('')
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

    // whether the assoc search returned the current item
    const assocHasCurrent = computed(() => {
      try {
        if (!assocResults.value || !item.value) return false
        return assocResults.value.some(r => r && r.id === item.value.id)
      } catch (e) {
        return false
      }
    })

    // safe helper to check if an id is linked
    function isLinked (id) {
      try {
        return linkedIds && linkedIds.value && typeof linkedIds.value.has === 'function' ? linkedIds.value.has(id) : false
      } catch (e) {
        return false
      }
    }

    // collapse/expand state for meanings (object map for reactivity)
    const expanded = ref({})
    function toggleMeaning (mid) {
      const m = expanded.value || {}
      m[mid] = !m[mid]
      expanded.value = { ...m }
    }
    function isExpanded (mid) {
      return !!(expanded.value && expanded.value[mid])
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
          const mr = await fetch(`/api/v1/expressions/${props.id}/meanings`)
          if (mr.ok) {
            const list = await mr.json()
            // for each meaning fetch its members
            for (const m of list) {
              try {
                const mm = await fetch(`/api/v1/meanings/${m.id}/members`)
                if (mm.ok) {
                  m.members = await mm.json()
                } else {
                  m.members = []
                }
              } catch (e) {
                m.members = []
              }
            }
            meanings.value = list
          } else meanings.value = []
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
        assocMsg.value = `Found ${assocResults.value.length} candidates.`
      } catch (e) {
        assocMsg.value = String(e)
        assocResults.value = []
      } finally {
        assocLoading.value = false
      }
    }

    async function createMeaning () {
      assocMsg.value = ''
      if (!newMeaningGloss.value || newMeaningGloss.value.trim() === '') {
        assocMsg.value = 'Please enter a gloss for the new meaning.'
        return null
      }
      try {
        const pm = await fetch('/api/v1/meanings', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ gloss: newMeaningGloss.value.trim(), description: 'Created via UI' })
        })
        if (!pm.ok) throw new Error('failed to create meaning')
        const newm = await pm.json()
        // attach empty members (will refresh on next load)
        newm.members = []
        meanings.value.push(newm)
        selectedMeaningId.value = newm.id
        newMeaningGloss.value = ''
        assocMsg.value = 'Created new meaning and selected it.'
        return newm
      } catch (e) {
        assocMsg.value = String(e)
        return null
      }
    }

    async function associateWith (target) {
      assocMsg.value = ''
      try {
        let mid = selectedMeaningId.value
        // if user chose to create new meaning via selector value '__new', use createMeaning
        if (mid === '__new') {
          const nm = await createMeaning()
          if (!nm) throw new Error('failed to create new meaning')
          mid = nm.id
        }
        // if still no mid, fallback to first meaning or create one from item text
        if (!mid) {
          if (meanings.value && meanings.value.length > 0) {
            mid = meanings.value[0].id
          } else {
            const pm = await fetch('/api/v1/meanings', {
              method: 'POST', headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ gloss: item.value.text, description: 'Created via UI association' })
            })
            if (!pm.ok) throw new Error('failed to create meaning')
            const newm = await pm.json()
            mid = newm.id
          }
        }

        // link current expression
        const link1 = await fetch(`/api/v1/meanings/${mid}/link?expression_id=${props.id}`, { method: 'POST' })
        if (!link1.ok) throw new Error('failed to link current expression')
        // link target expression
        const link2 = await fetch(`/api/v1/meanings/${mid}/link?expression_id=${target.id}`, { method: 'POST' })
        if (!link2.ok) throw new Error('failed to link target expression')

        assocMsg.value = 'Linked successfully.'
        // refresh translations and meanings
        await load()
      } catch (e) {
        assocMsg.value = String(e)
      }
    }

    onMounted(load)
    // when the route param `id` changes the same component instance is reused by the router;
    // watch the prop and reload the details when it changes
    watch(() => props.id, (newId, oldId) => {
      if (newId !== oldId) load()
    })
    return { item, loading, translations, transLoading, associateMode, assocQuery, assocResults, assocLoading, assocMsg, meanings, linkedIds, assocHasCurrent, isLinked, searchAssociate, associateWith, selectedMeaningId, newMeaningGloss, createMeaning, toggleMeaning, isExpanded }
  }
}
</script>