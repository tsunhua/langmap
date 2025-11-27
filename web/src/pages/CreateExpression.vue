<template>
  <div class="max-w-2xl mx-auto">
    <div class="flex items-center mb-6">
      <button @click="$router.back()" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 px-4 py-2 flex items-center mr-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
        </svg>
        {{ $t('create.back') }}
      </button>
      <h2 class="text-2xl font-bold text-slate-800">{{ $t('create.title') }}</h2>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div class="mb-6">
        <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.text') }} *</label>
        <textarea 
          v-model="text" 
          rows="3" 
          class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4" 
          :placeholder="$t('create.textPlaceholder')"
        ></textarea>
        <p class="text-sm text-slate-500 mt-1">{{ $t('create.textHelp') }}</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.language') }} *</label>
          <input 
            v-model="language" 
            :placeholder="$t('create.languagePlaceholder')" 
            class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4" 
          />
          <p class="text-sm text-slate-500 mt-1">{{ $t('create.languageHelp') }}</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.region') }}</label>
          <input 
            v-model="region" 
            :placeholder="$t('create.regionPlaceholder')" 
            class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4" 
          />
          <p class="text-sm text-slate-500 mt-1">{{ $t('create.regionHelp') }}</p>
        </div>
      </div>

      <div class="mb-6">
        <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.source') }}</label>
        <input 
          v-model="source_ref" 
          :placeholder="$t('create.sourcePlaceholder')" 
          class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4" 
        />
        <p class="text-sm text-slate-500 mt-1">{{ $t('create.sourceHelp') }}</p>
      </div>

      <!-- Associate with existing meaning section -->
      <div class="mb-6 bg-slate-50 rounded-lg p-5">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium text-slate-800">{{ $t('create.associateWithExistingMeaning') }}</h3>
          <button 
            @click="toggleAssociationMode" 
            class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-200 text-slate-700 hover:bg-slate-300 focus:ring-slate-500 px-3 py-1 text-sm"
          >
            {{ associateMode ? $t('detail.cancel') : $t('detail.associateExpressions') }}
          </button>
        </div>

        <div v-if="associateMode">
          <div class="flex items-center gap-3 mb-4">
            <div class="flex-1">
              <input 
                v-model="assocQuery" 
                :placeholder="$t('detail.searchPlaceholder')" 
                class="block w-full rounded-md border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2.5 px-4" 
                @keydown.enter="searchAssociate" 
              />
            </div>
            <button @click="searchAssociate" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2.5">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              {{ $t('detail.search') }}
            </button>
          </div>

          <div>
            <div v-if="assocLoading" class="flex items-center justify-center py-4">
              <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span class="ml-2 text-slate-600">{{ $t('detail.searching') }}</span>
            </div>

            <div v-else-if="assocResults.length === 0" class="text-center py-4 text-slate-500">
              {{ $t('detail.noExpressionsFound') }}
            </div>

            <div v-else class="space-y-2 max-h-60 overflow-y-auto">
              <div 
                v-for="c in assocResults" 
                :key="c && c.id" 
                class="flex gap-3 items-center p-3 bg-white rounded-lg"
              >
                <div class="flex-1">
                  <ExpressionCard :item="c" />
                </div>
                <div>
                  <button 
                    @click="selectExpression(c)" 
                    class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2"
                  >
                    {{ $t('detail.link') }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div v-if="selectedExpression" class="mt-4 p-3 bg-blue-50 rounded-lg">
            <div class="flex justify-between items-start">
              <div>
                <h4 class="font-medium text-slate-800">Selected expression:</h4>
                <ExpressionCard :item="selectedExpression" />
              </div>
              <button @click="clearSelection" class="text-slate-500 hover:text-slate-700">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            
            <div class="mt-3">
              <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('detail.linkToMeaning') }}</label>
              <div class="flex flex-wrap gap-3 mt-2">
                <select v-model="selectedMeaningId" class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 flex-1">
                  <option :value="null">{{ $t('detail.selectMeaning') }}</option>
                  <option v-for="m in selectedExpressionMeanings" :key="m.id" :value="m.id">
                    {{ m.gloss }} — {{ m.description }}
                  </option>
                  <option :value="'__new'">{{ $t('detail.createNew') }}</option>
                </select>
                
                <div v-if="selectedMeaningId === '__new'" class="flex-1">
                  <input 
                    v-model="newMeaningGloss" 
                    :placeholder="$t('detail.newMeaningGloss')" 
                    class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50" 
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex flex-wrap gap-3">
        <button @click="submit" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-6 py-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          {{ $t('create.submit') }}
        </button>
        <button @click="$router.back()" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
          {{ $t('create.cancel') }}
        </button>
      </div>

      <div v-if="error" class="mt-4 p-3 bg-red-50 text-red-700 rounded-lg flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import ExpressionCard from '../components/ExpressionCard.vue'

export default {
  name: 'CreateExpression',
  components: { ExpressionCard },
  setup () {
    const route = useRoute()
    const router = useRouter()
    const { t } = useI18n()
    const text = ref(route.query.text || '')
    const language = ref(route.query.language || '')
    const region = ref(route.query.region || '')
    const source_ref = ref(route.query.source_ref || '')
    const error = ref(null)
    
    // Association mode
    const associateMode = ref(false)
    const assocQuery = ref('')
    const assocResults = ref([])
    const assocLoading = ref(false)
    const selectedExpression = ref(null)
    const selectedExpressionMeanings = ref([])
    const selectedMeaningId = ref(null)
    const newMeaningGloss = ref('')

    function toggleAssociationMode() {
      associateMode.value = !associateMode.value
      if (!associateMode.value) {
        // Reset association data when closing
        assocQuery.value = ''
        assocResults.value = []
        selectedExpression.value = null
        selectedExpressionMeanings.value = []
        selectedMeaningId.value = null
        newMeaningGloss.value = ''
      }
    }

    async function searchAssociate () {
      assocLoading.value = true
      try {
        const params = new URLSearchParams()
        if (assocQuery.value) params.set('q', assocQuery.value)
        const url = `/api/v1/search?${params.toString()}`
        console.debug('Assoc search URL:', url)
        const res = await fetch(url)
        if (!res.ok) throw new Error('search failed')
        assocResults.value = await res.json()
        console.debug('Assoc search returned', assocResults.value.length, 'items')
      } catch (e) {
        error.value = String(e)
        assocResults.value = []
      } finally {
        assocLoading.value = false
      }
    }

    async function selectExpression(expression) {
      selectedExpression.value = expression
      selectedExpressionMeanings.value = []
      selectedMeaningId.value = null
      newMeaningGloss.value = ''
      
      try {
        // Fetch meanings for the selected expression
        const res = await fetch(`/api/v1/expressions/${expression.id}/meanings`)
        if (res.ok) {
          selectedExpressionMeanings.value = await res.json()
        }
      } catch (e) {
        error.value = String(e)
      }
    }

    function clearSelection() {
      selectedExpression.value = null
      selectedExpressionMeanings.value = []
      selectedMeaningId.value = null
      newMeaningGloss.value = ''
    }

    async function submit () {
      error.value = null
      if (!text.value || !language.value) {
        error.value = t('create.requiredError')
        return
      }
      
      try {
        // First create the expression
        const payload = {
          text: text.value,
          language: language.value,
          region: region.value || null,
          source_ref: source_ref.value || null,
        }
        
        const res = await fetch('/api/v1/expressions', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })
        
        if (!res.ok) {
          const txt = await res.text()
          throw new Error(txt || 'create failed')
        }
        
        const created = await res.json()
        
        // If user wants to associate with an existing meaning
        if (selectedExpression.value && selectedMeaningId.value) {
          let mid = selectedMeaningId.value
          
          // If user wants to create a new meaning
          if (mid === '__new') {
            if (!newMeaningGloss.value || newMeaningGloss.value.trim() === '') {
              error.value = 'Please enter a gloss for the new meaning.'
              return
            }
            
            try {
              const pm = await fetch('/api/v1/meanings', {
                method: 'POST', 
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                  gloss: newMeaningGloss.value.trim(), 
                  description: 'Created via UI during expression creation' 
                })
              })
              
              if (!pm.ok) throw new Error('failed to create meaning')
              const newm = await pm.json()
              mid = newm.id
            } catch (e) {
              error.value = String(e)
              return
            }
          }
          
          // Link the newly created expression with the selected meaning
          try {
            const linkRes = await fetch(`/api/v1/meanings/${mid}/link?expression_id=${created.id}`, { 
              method: 'POST' 
            })
            
            if (!linkRes.ok) throw new Error('failed to link expression with meaning')
          } catch (e) {
            error.value = String(e)
            return
          }
        }
        
        // Navigate to detail view for the created expression
        router.push({ name: 'detail', params: { id: created.id } })
      } catch (e) {
        error.value = e.message || String(e)
      }
    }

    return { 
      text, 
      language, 
      region, 
      source_ref, 
      submit, 
      error, 
      t,
      // Association properties
      associateMode,
      assocQuery,
      assocResults,
      assocLoading,
      selectedExpression,
      selectedExpressionMeanings,
      selectedMeaningId,
      newMeaningGloss,
      // Association methods
      toggleAssociationMode,
      searchAssociate,
      selectExpression,
      clearSelection
    }
  }
}
</script>