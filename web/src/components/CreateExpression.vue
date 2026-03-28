<template>
  <div v-if="visible" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-xl shadow-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
      <div class="sticky top-0 bg-white border-b border-slate-200 px-6 py-4 flex justify-between items-center">
        <h2 class="text-2xl font-bold text-slate-800">{{ $t('create_title') }}</h2>
        <button @click="$emit('close')" class="text-slate-500 hover:text-slate-700">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <div class="p-6">
        <div class="mb-6">
          <div v-if="language_code !== 'image'">
            <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('text') }} *</label>
            <textarea v-model="text" rows="3"
              class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4"
              :placeholder="$t('text_placeholder')"></textarea>
            <p class="text-sm text-slate-500 mt-1">{{ $t('text_help') }}</p>
          </div>
          <div v-else>
            <label class="block text-sm font-medium text-slate-700 mb-1">图片 *</label>
            <ImageUploader
              :existing-image-url="text"
              @image-ready="handleImageReady"
              @image-cleared="handleImageCleared"
            />
          </div>
        </div>

        <div v-if="language_code !== 'image'" class="mb-6">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('desc_label') || '描述（可選）' }}</label>
          <textarea v-model="desc" rows="3" maxlength="1000"
            class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3 text-sm resize-y"
            :placeholder="$t('expression_desc_placeholder')"></textarea>
          <div class="flex justify-end mt-1">
            <span class="text-xs text-slate-400">{{ desc.length }} / 1000</span>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6" :class="{ 'opacity-50 pointer-events-none': language_code === 'image' }">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('language') }} *</label>
            <div class="flex gap-2">
              <div class="relative flex-1">
                <select v-model="language_code"
                  class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-3 appearance-none"
                  :disabled="languagesLoading">
                  <option v-if="languagesLoading" value="" disabled>{{ $t('loading_languages') }}</option>
                  <option v-else value="" disabled>{{ $t('select_language') }}</option>
                  <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                    {{ lang.name }} ({{ lang.code }})
                  </option>
                </select>
                <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </div>
              </div>
              <button @click="showAddLanguageModal = true"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                :title="$t('add_language')">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              </button>
            </div>
            <p class="text-sm text-slate-500 mt-1">{{ $t('language_help') }}</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create_region') }}</label>
            <div class="flex gap-2">
              <input v-model="region"
                class="block flex-1 rounded-md border border-slate-300 shadow-sm py-3 px-4 bg-slate-100 text-slate-500 cursor-not-allowed" />
              <button @click="detectLocation" :disabled="detectingLocation || parsingLocation"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                :title="$t('detect_location')">
                <svg v-if="detectingLocation || parsingLocation" class="animate-spin h-5 w-5 text-slate-600"
                  xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                  </path>
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none"
                  viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M17.657 16.657L13.414 20.9a1 1 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
              <button @click="toggleMapSelector" :disabled="parsingLocation"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                :title="$t('select_on_map')">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
                </svg>
              </button>
            </div>
            <p class="text-sm text-slate-500 mt-1">{{ $t('region_help') }}</p>

            <!-- 地图选择器 -->
            <div v-if="showMapSelector" class="mt-3 border border-slate-200 rounded-lg overflow-hidden">
              <div id="region-map" class="w-full h-64"></div>
              <div class="p-3 bg-slate-50 text-sm text-slate-600">
                {{ $t('click_on_map_to_select') }}
              </div>
            </div>

            <!-- 解析位置信息加载状态 -->
            <div v-if="parsingLocation" class="mt-2 flex items-center text-sm text-slate-600">
              <svg class="animate-spin h-4 w-4 mr-2 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
                viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                </path>
              </svg>
              {{ $t('parsing_location') }}
            </div>
          </div>
        </div>

        <div class="flex flex-wrap gap-3">
          <button @click="submit"
            class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-6 py-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            {{ $t('expression') }}
          </button>
          <button @click="$emit('close')"
            class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
            {{ $t('cancel') }}
          </button>
        </div>

        <div v-if="error" class="mt-4 p-3 bg-red-50 text-red-700 rounded-lg flex items-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24"
            stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          {{ error }}
        </div>
      </div>

      <!-- Add Language Modal -->
      <AddLanguageModal :visible="showAddLanguageModal" :adding-language="addingLanguage"
        @close="showAddLanguageModal = false" @add-language="handleAddLanguage" />
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { languagesApi, expressionGroupsApi } from '../api/index.ts'
import AddLanguageModal from '../components/AddLanguageModal.vue'
import ImageUploader from '../components/ImageUploader.vue'

export default {
  name: 'CreateExpression',
  components: { AddLanguageModal, ImageUploader },
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    initialGroupId: {
      type: Number,
      default: null
    },
    initialText: {
      type: String,
      default: ''
    }
  },
  emits: ['close', 'expression-created'],
  setup(props, { emit }) {
    const route = useRoute()
    const router = useRouter()
    const { t, locale } = useI18n()
    const text = ref(props.initialText || route.query.text || '')
    const desc = ref('')
    const language_code = ref(route.query.language_code || '')

    // Languages data
    const languages = ref([])
    const languagesLoading = ref(false)

    // Language management
    const showAddLanguageModal = ref(false)
    const addingLanguage = ref(false)

    // Region is now stored as a JSON string containing name, latitude, and longitude
    const regionInput = ref(route.query.region || '')
    const error = ref(null)

    // Location detection
    const detectingLocation = ref(false)
    const parsingLocation = ref(false)

    // Map selector
    const showMapSelector = ref(false)
    let map = null
    let L

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
        const result = await languagesApi.getAll()
        if (result.success && result.data) {
          languages.value = result.data
        } else {
          languages.value = []
        }
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
        language_code.value = languageObj.code

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
        if (language_code.value) {
          // Use the language selected in the form
          langCode = language_code.value;
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

    const handleImageReady = (url) => {
      text.value = url
    }

    const handleImageCleared = () => {
      text.value = ''
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

    async function submit() {
      error.value = null
      if (!text.value || !language_code.value) {
        error.value = t('create.requiredError')
        return
      }

      // Check if user is authenticated
      const token = localStorage.getItem('authToken')
      if (!token) {
        error.value = 'You must be logged in to create expressions'
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

        // Get current user info
        let createdBy = null;
        try {
          const response = await fetch('/api/v1/users/me', {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });

          if (response.ok) {
            const userData = await response.json();
            createdBy = userData.data.username;
          } else if (response.status === 401) {
            // Token is invalid, redirect to login
            error.value = 'Session expired. Please log in again.';
            localStorage.removeItem('authToken');
            router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } });
            return;
          }
        } catch (e) {
          console.warn('Could not fetch current user info:', e);
        }

        // Create the expression
        const payload = {
          text: text.value,
          language_code: language_code.value,
          desc: desc.value || null,
          region_code: regionData?.country_code || null,
          region_name: regionData?.name || null,
          region_latitude: regionData && regionData.latitude !== undefined && regionData.latitude !== null ? regionData.latitude : null,
          region_longitude: regionData && regionData.longitude !== undefined && regionData.longitude !== null ? regionData.longitude : null,
          created_by: createdBy
        }

        const res = await fetch('/api/v1/expressions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify(payload)
        })

        if (!res.ok) {
          if (res.status === 401) {
            // Token is invalid, redirect to login
            error.value = 'Session expired. Please log in again.';
            localStorage.removeItem('authToken');
            router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } });
            return;
          }
          const txt = await res.text()
          throw new Error(txt || 'create failed')
        }

        const result = await res.json()
        const created = result.success ? result.data : result

        // 如果传入了 initialGroupId，则自动关联到该词句组
        if (props.initialGroupId) {
          try {
            const result = await expressionGroupsApi.addToGroup(props.initialGroupId, { expression_id: created.id })

            if (!result.success) {
              if (result.error) {
                // Token is invalid, redirect to login
                error.value = 'Session expired. Please log in again.';
                localStorage.removeItem('authToken');
                router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } });
                return;
              }
              throw new Error(result.error || 'Failed to associate expression to group')
            }
          } catch (e) {
            error.value = String(e)
            return
          }
        }

        // Emit event to notify parent component about the created expression
        emit('expression-created', created)
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
        language_code.value = route.query.language_code || ''
        regionInput.value = route.query.region || ''
        desc.value = ''

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
      desc,
      language_code,
      languages,
      languagesLoading,
      region,
      regionInput,
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
      // Image handling
      handleImageReady,
      handleImageCleared
    }
  }
}
</script>