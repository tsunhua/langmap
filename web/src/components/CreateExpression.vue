<template>
  <div v-if="visible" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-xl shadow-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
      <div class="sticky top-0 bg-white border-b border-slate-200 px-6 py-4 flex justify-between items-center">
        <h2 class="text-2xl font-bold text-slate-800">{{ $t('create.title') }}</h2>
        <button @click="$emit('close')" class="text-slate-500 hover:text-slate-700">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <div class="p-6">
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
            <div class="flex gap-2">
              <div class="relative flex-1">
                <select 
                  v-model="language" 
                  class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-3 appearance-none"
                  :disabled="languagesLoading"
                >
                  <option v-if="languagesLoading" value="" disabled>{{ $t('create.loadingLanguages') }}</option>
                  <option v-else value="" disabled>{{ $t('create.selectLanguage') }}</option>
                  <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                    {{ lang.native_name || lang.name }} ({{ lang.code }})
                  </option>
                </select>
                <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </div>
              </div>
              <button 
                @click="showAddLanguageModal = true"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                :title="$t('create.addLanguage')"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              </button>
            </div>
            <p class="text-sm text-slate-500 mt-1">{{ $t('create.languageHelp') }}</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.region') }}</label>
            <div class="flex gap-2">
              <input 
                v-model="region" 
                :placeholder="$t('create.regionPlaceholder')" 
                class="block flex-1 rounded-md border border-slate-300 shadow-sm py-3 px-4 bg-slate-100 text-slate-500 cursor-not-allowed" 
                readonly
              />
              <button 
                @click="detectLocation"
                :disabled="detectingLocation || parsingLocation"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                :title="$t('create.detectLocation')"
              >
                <svg v-if="detectingLocation || parsingLocation" class="animate-spin h-5 w-5 text-slate-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
              <button 
                @click="toggleMapSelector"
                :disabled="parsingLocation"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                :title="$t('create.selectOnMap')"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
                </svg>
              </button>
            </div>
            <p class="text-sm text-slate-500 mt-1">{{ $t('create.regionHelp') }}</p>
            
            <!-- 地图选择器 -->
            <div v-if="showMapSelector" class="mt-3 border border-slate-200 rounded-lg overflow-hidden">
              <div id="region-map" class="w-full h-64"></div>
              <div class="p-3 bg-slate-50 text-sm text-slate-600">
                {{ $t('create.clickOnMapToSelect') }}
              </div>
            </div>
            
            <!-- 解析位置信息加载状态 -->
            <div v-if="parsingLocation" class="mt-2 flex items-center text-sm text-slate-600">
              <svg class="animate-spin h-4 w-4 mr-2 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {{ $t('create.parsingLocation') }}
            </div>
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

        <!-- Associate with meaning section -->
        <div class="mb-6 bg-slate-50 rounded-lg p-5">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-medium text-slate-800">{{ $t('create.associateWithMeaning') }}</h3>
            <button 
              @click="toggleAssociationMode" 
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-200 text-slate-700 hover:bg-slate-300 focus:ring-slate-500 px-3 py-1 text-sm"
            >
              {{ associateMode ? $t('detail.cancel') : $t('detail.associateExpressions') }}
            </button>
          </div>

          <div v-if="associateMode">
            <!-- Tab navigation for association type -->
            <div class="mb-6">
              <div class="border-b border-slate-200">
                <nav class="-mb-px flex space-x-8">
                  <button
                    @click="associationType = 'existing'"
                    :class="[
                      'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm',
                      associationType === 'existing' 
                        ? 'border-blue-500 text-blue-600' 
                        : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
                    ]"
                  >
                    {{ $t('create.associateWithExistingMeaning') }}
                  </button>
                  <button
                    @click="associationType = 'new'"
                    :class="[
                      'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm',
                      associationType === 'new' 
                        ? 'border-blue-500 text-blue-600' 
                        : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
                    ]"
                  >
                    {{ $t('create.associateWithNewMeaning') }}
                  </button>
                </nav>
              </div>
            </div>

            <!-- Associate with existing meaning -->
            <div v-if="associationType === 'existing'">
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
                    <h4 class="font-medium text-slate-800">{{ $t('create.selectedExpression') }}</h4>
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

            <!-- Associate with new meaning -->
            <div v-else-if="associationType === 'new'">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.meaningGloss') }} *</label>
                  <input 
                    v-model="newMeaningGloss" 
                    :placeholder="$t('create.meaningGlossPlaceholder')" 
                    class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2.5 px-4" 
                  />
                  <p class="text-sm text-slate-500 mt-1">{{ $t('create.meaningGlossHelp') }}</p>
                </div>
                
                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.meaningDescription') }}</label>
                  <textarea 
                    v-model="newMeaningDescription" 
                    rows="3" 
                    :placeholder="$t('create.meaningDescriptionPlaceholder')" 
                    class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2.5 px-4"
                  ></textarea>
                  <p class="text-sm text-slate-500 mt-1">{{ $t('create.meaningDescriptionHelp') }}</p>
                </div>

                <!-- Tags input for new meaning -->
                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.meaningTags') }}</label>
                  <div class="border border-slate-300 rounded-md shadow-sm focus-within:border-blue-500 focus-within:ring-1 focus-within:ring-blue-500">
                    <div class="flex flex-wrap gap-2 p-2">
                      <span 
                        v-for="tag in newMeaningTags" 
                        :key="tag"
                        class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                      >
                        {{ tag }}
                        <button 
                          @click="removeTag(tag)"
                          type="button"
                          class="flex-shrink-0 ml-1 h-4 w-4 rounded-full inline-flex items-center justify-center text-blue-400 hover:bg-blue-200 hover:text-blue-500 focus:outline-none"
                        >
                          <span class="sr-only">Remove tag</span>
                          <svg class="h-2 w-2" stroke="currentColor" fill="none" viewBox="0 0 8 8">
                            <path stroke-linecap="round" stroke-width="1.5" d="M1 1l6 6m0-6L1 7" />
                          </svg>
                        </button>
                      </span>
                      <input 
                        v-model="newMeaningTagInput"
                        @keydown="handleTagInputKeydown"
                        :placeholder="$t('create.meaningTagsPlaceholder')"
                        class="flex-grow border-0 focus:ring-0 focus:outline-none py-1 px-2 text-sm"
                      />
                    </div>
                  </div>
                  <p class="text-sm text-slate-500 mt-1">{{ $t('create.meaningTagsHelp') }}</p>
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
          <button @click="$emit('close')" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
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
      
      <!-- Add Language Modal -->
      <AddLanguageModal 
        :visible="showAddLanguageModal"
        :adding-language="addingLanguage"
        @close="showAddLanguageModal = false"
        @add-language="handleAddLanguage"
      />
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import ExpressionCard from '../components/ExpressionCard.vue'
import { fetchLanguages } from '../services/languageService.js'
import AddLanguageModal from '../components/AddLanguageModal.vue'

export default {
  name: 'CreateExpression',
  components: { ExpressionCard, AddLanguageModal },
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    initialMeaningId: {
      type: Number,
      default: null
    },
    initialText: {
      type: String,
      default: ''
    }
  },
  emits: ['close', 'expression-created'],
  setup (props, { emit }) {
    const route = useRoute()
    const { t, locale } = useI18n()
    const text = ref(props.initialText || route.query.text || '')
    const language = ref(route.query.language || '')
    
    // Languages data
    const languages = ref([])
    const languagesLoading = ref(false)
    
    // Language management
    const showAddLanguageModal = ref(false)
    const addingLanguage = ref(false)
    
    // Region is now stored as a JSON string containing name, latitude, and longitude
    const regionInput = ref(route.query.region || '')
    const source_ref = ref(route.query.source_ref || '')
    const error = ref(null)
    
    // Location detection
    const detectingLocation = ref(false)
    const parsingLocation = ref(false)
    
    // Map selector
    const showMapSelector = ref(false)
    let map = null
    let L
    
    // Association mode
    const associateMode = ref(false)
    const associationType = ref('existing') // 'existing' or 'new'
    const assocQuery = ref('')
    const assocResults = ref([])
    const assocLoading = ref(false)
    const selectedExpression = ref(null)
    const selectedExpressionMeanings = ref([])
    const selectedMeaningId = ref(null)
    const newMeaningGloss = ref('')
    const newMeaningDescription = ref('')
    const newMeaningTags = ref([]) // For new meaning tags
    const newMeaningTagInput = ref('') // For new meaning tag input

    // Geo info structure: { name: string, latitude: number, longitude: number }
    const parseGeoInfo = (geoString) => {
      if (!geoString) return null
      try {
        return JSON.parse(geoString)
      } catch (e) {
        // If it's not JSON, treat it as a plain name
        return { name: geoString, latitude: null, longitude: null }
      }
    }

    // Computed region value for display (only the name part)
    const region = computed({
      get: () => {
        const geoInfo = parseGeoInfo(regionInput.value)
        return geoInfo ? geoInfo.name : ''
      },
      set: (value) => {
        // When setting, preserve existing coordinates if available
        const geoInfo = parseGeoInfo(regionInput.value) || { latitude: null, longitude: null }
        regionInput.value = JSON.stringify({ ...geoInfo, name: value })
      }
    })

    // Load languages from backend
    const loadLanguages = async () => {
      languagesLoading.value = true
      try {
        const langs = await fetchLanguages()
        languages.value = langs
      } catch (err) {
        console.error('Failed to load languages:', err)
        error.value = 'Failed to load languages: ' + err.message
      } finally {
        languagesLoading.value = false
      }
    }

    // Handle add language
    const handleAddLanguage = async (languageObj) => {
      try {
        // Reload languages list
        await loadLanguages()
        
        // Select the newly created language
        language.value = languageObj.code
        
        // Close modal
        showAddLanguageModal.value = false
      } catch (error) {
        console.error('Error handling added language:', error)
        alert(t('create.addLanguageFailed'))
      }
    }

    // Load Leaflet from CDN
    const loadLeaflet = () => {
      return new Promise((resolve, reject) => {
        if (window.L) {
          resolve()
          return
        }
        
        // Load CSS
        const link = document.createElement('link')
        link.rel = 'stylesheet'
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
        link.onload = () => {
          // Load JS
          const script = document.createElement('script')
          script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
          script.onload = () => {
            resolve()
          }
          script.onerror = () => {
            reject(new Error('Failed to load Leaflet JS'))
          }
          document.head.appendChild(script)
        }
        link.onerror = () => {
          reject(new Error('Failed to load Leaflet CSS'))
        }
        document.head.appendChild(link)
      })
    }
    
    // Reverse geocode coordinates to get detailed location info
    const reverseGeocode = async (lat, lon) => {
      try {
        // Prioritize form language, fallback to app language, then to browser language, and finally to 'en'
        let langCode = 'en';
        if (language.value) {
          // Use the language selected in the form
          langCode = language.value;
        } else {
          // Fallback to the app-level language
          if (locale.value) {
            langCode = locale.value;
          } else {
            // Fallback to browser language
            const userLang = navigator.language || 'en';
            langCode = userLang.split('-')[0]; // Extract language code (e.g., 'zh' from 'zh-CN')
          }
        }
        
        // For Nominatim, we need just the language part, not the region
        const nominatimLangCode = langCode.split('-')[0];
        
        console.log(`Requesting location name in language: ${nominatimLangCode}`);
        
        const response = await fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&accept-language=${nominatimLangCode}`
        )
        
        if (response.ok) {
          const data = await response.json()
          console.log('Nominatim response:', data);
          
          if (data.address) {
            const address = data.address
            // Build a hierarchical location name with street/township level details
            const locationParts = [
              address.neighbourhood || address.suburb || address.city_district,
              address.village || address.town || address.city,
              address.state_district || address.county || address.state || address.province,
              address.country
            ].filter(part => part) // Remove falsy values
            
            // Get country information
            const countryCode = address.country_code?.toUpperCase() || null
            const countryName = address.country || null
            
            // If we couldn't get a meaningful name, try with English as fallback
            let displayName = locationParts.filter(part => part).join(', ')
            console.log('Localized name:', displayName);
            
            if (!displayName || displayName.trim() === '') {
              // Try again with English if the localized name is empty
              console.log('Localized name empty, trying English fallback');
              const fallbackResponse = await fetch(
                `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&accept-language=en`
              )
              
              if (fallbackResponse.ok) {
                const fallbackData = await fallbackResponse.json()
                console.log('Fallback response:', fallbackData);
                
                if (fallbackData.address) {
                  const fallbackAddress = fallbackData.address
                  const fallbackLocationParts = [
                    fallbackAddress.neighbourhood || fallbackAddress.suburb || fallbackAddress.city_district,
                    fallbackAddress.village || fallbackAddress.town || fallbackAddress.city,
                    fallbackAddress.state_district || fallbackAddress.county || fallbackAddress.state || fallbackAddress.province,
                    fallbackAddress.country
                  ].filter(part => part)
                  
                  displayName = fallbackLocationParts.filter(part => part).join(', ') || `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                  console.log('English fallback name:', displayName);
                } else {
                  displayName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                }
              } else {
                displayName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
              }
            }
            
            return {
              name: displayName,
              latitude: parseFloat(lat),
              longitude: parseFloat(lon),
              country_code: countryCode,
              country_name: countryName
            }
          }
        }
        // Fallback to coordinates only
        console.log('Falling back to coordinates only');
        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon),
          country_code: null,
          country_name: null
        }
      } catch (err) {
        console.error('Reverse geocoding failed:', err)
        // Fallback to coordinates only
        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon),
          country_code: null,
          country_name: null
        }
      }
    }
    
    // Initialize map for region selection
    const initMap = async () => {
      try {
        await loadLeaflet()
        L = window.L
        
        // Wait for DOM element to be available
        await new Promise(resolve => setTimeout(resolve, 100))
        
        const mapElement = document.getElementById('region-map')
        if (!mapElement) {
          console.error('Map element not found')
          return
        }
        
        // Check if map is already initialized
        if (mapElement._leaflet_id) {
          // If map already exists, remove it first
          if (map) {
            map.remove()
          }
          map = null
        }
        
        // Create map centered on world view
        map = L.map('region-map').setView([20, 0], 2)
        
        // Add tile layer
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map)
        
        // Add click handler
        map.on('click', async (e) => {
          const { lat, lng } = e.latlng
          parsingLocation.value = true
          
          try {
            // Get detailed location info from coordinates
            const geoInfo = await reverseGeocode(lat, lng)
            regionInput.value = JSON.stringify(geoInfo)
          } catch (err) {
            console.error('Failed to process map click:', err)
            error.value = t('create.locationParsingFailed')
          } finally {
            parsingLocation.value = false
            showMapSelector.value = false
          }
        })
      } catch (err) {
        console.error('Failed to initialize map:', err)
        error.value = 'Failed to load map: ' + err.message
      }
    }
    
    // Toggle map selector
    const toggleMapSelector = async () => {
      showMapSelector.value = !showMapSelector.value
      if (showMapSelector.value) {
        // Small delay to ensure DOM is updated
        setTimeout(() => {
          initMap()
        }, 100)
      } else {
        if (map) {
          map.remove()
          map = null
        }
      }
    }
    
    // Detect user location
    const detectLocation = () => {
      detectingLocation.value = true
      error.value = null
      
      if (!navigator.geolocation) {
        error.value = t('create.geolocationNotSupported')
        detectingLocation.value = false
        return
      }
      
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords
          
          try {
            parsingLocation.value = true
            // Use reverse geocoding to get detailed region info with language localization
            const geoInfo = await reverseGeocode(latitude, longitude)
            regionInput.value = JSON.stringify(geoInfo)
          } catch (err) {
            console.error('Location processing failed:', err)
            error.value = t('create.locationParsingFailed')
          } finally {
            parsingLocation.value = false
            detectingLocation.value = false
          }
        },
        (err) => {
          console.error('Geolocation error:', err)
          error.value = t('create.locationDetectionFailed')
          detectingLocation.value = false
        },
        {
          timeout: 10000,
          enableHighAccuracy: true
        }
      )
    }

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
        newMeaningDescription.value = ''
        newMeaningTags.value = []
        newMeaningTagInput.value = ''
        associationType.value = 'existing'
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

    // Tag management functions
    function addTag() {
      if (newMeaningTagInput.value.trim() && !newMeaningTags.value.includes(newMeaningTagInput.value.trim())) {
        newMeaningTags.value.push(newMeaningTagInput.value.trim())
        newMeaningTagInput.value = ''
      }
    }

    function removeTag(tag) {
      newMeaningTags.value = newMeaningTags.value.filter(t => t !== tag)
    }

    function handleTagInputKeydown(event) {
      if (event.key === 'Enter' || event.key === ',') {
        event.preventDefault()
        addTag()
      } else if (event.key === 'Backspace' && !newMeaningTagInput.value && newMeaningTags.value.length > 0) {
        // Remove the last tag when backspace is pressed on empty input
        newMeaningTags.value.pop()
      }
    }

    async function submit () {
      error.value = null
      if (!text.value || !language.value) {
        error.value = t('create.requiredError')
        return
      }
      
      try {
        // Parse region data if it exists
        let regionData = null;
        if (regionInput.value) {
          try {
            regionData = JSON.parse(regionInput.value);
          } catch (e) {
            // If it's not valid JSON, treat as plain string
            regionData = { name: regionInput.value };
          }
        }
        
        // First create the expression
        const payload = {
          text: text.value,
          language: language.value,
          region_name: regionData?.name || null,
          region_latitude: regionData?.latitude !== null ? regionData.latitude.toString() : null,
          region_longitude: regionData?.longitude !== null ? regionData.longitude.toString() : null,
          country_code: regionData?.country_code || null,
          country_name: regionData?.country_name || null,
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
        
        // Handle meaning association based on user choice
        if (associateMode.value) {
          if (associationType.value === 'existing' && selectedExpression.value && selectedMeaningId.value) {
            // Associate with existing meaning
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
          } else if (associationType.value === 'new') {
            // Associate with new meaning
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
                  description: newMeaningDescription.value || '',
                  tags: newMeaningTags.value.length > 0 ? newMeaningTags.value : undefined
                })
              })
              
              if (!pm.ok) throw new Error('failed to create meaning')
              const newm = await pm.json()
              const mid = newm.id
              
              // Link the newly created expression with the new meaning
              const linkRes = await fetch(`/api/v1/meanings/${mid}/link?expression_id=${created.id}`, { 
                method: 'POST' 
              })
              
              if (!linkRes.ok) throw new Error('failed to link expression with meaning')
            } catch (e) {
              error.value = String(e)
              return
            }
          }
        }
        
        // Navigate to detail view for the created expression
        router.push({ name: 'detail', params: { id: created.id } })
      } catch (e) {
        error.value = e.message || String(e)
      }
    }
    
    // Watch for map selector visibility changes
    watch(showMapSelector, (newValue) => {
      if (newValue) {
        setTimeout(() => {
          initMap()
        }, 100)
      } else {
        if (map) {
          map.remove()
          map = null
        }
      }
    })
    
    // Watch for component visibility changes to load languages and reset form
    watch(() => props.visible, (newVisible) => {
      if (newVisible) {
        // Reset form fields when modal opens
        text.value = props.initialText || route.query.text || ''
        language.value = route.query.language || ''
        regionInput.value = route.query.region || ''
        source_ref.value = route.query.source_ref || ''
        
        // Load languages
        loadLanguages()
      }
    })
    
    onMounted(() => {
      // Load languages when component mounts if visible
      if (props.visible) {
        loadLanguages()
      }
    })

    onUnmounted(() => {
      // Clean up map if it exists
      if (map) {
        map.remove()
        map = null
      }
    })

    return { 
      text, 
      language, 
      languages,
      languagesLoading,
      region, 
      regionInput,
      source_ref, 
      submit, 
      error, 
      t,
      // Language management
      showAddLanguageModal,
      addingLanguage,
      handleAddLanguage,
      // Location detection
      detectingLocation,
      parsingLocation,
      detectLocation,
      // Map selector
      showMapSelector,
      toggleMapSelector,
      // Association properties
      associateMode,
      associationType,
      assocQuery,
      assocResults,
      assocLoading,
      selectedExpression,
      selectedExpressionMeanings,
      selectedMeaningId,
      newMeaningGloss,
      newMeaningDescription,
      newMeaningTags,
      newMeaningTagInput,
      // Association methods
      toggleAssociationMode,
      searchAssociate,
      selectExpression,
      clearSelection,
      // Tag management methods
      addTag,
      removeTag,
      handleTagInputKeydown
    }
  }
}
</script>