<template>
  <div class="max-w-5xl mx-auto">
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <h2 class="text-2xl font-bold text-slate-800 mb-2">{{ $t('create_title') }}</h2>
      <p class="text-slate-600 mb-6">{{ $t('add_expression_description') }}</p>

      <div class="mb-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
        <div class="flex items-start gap-3">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div class="text-sm text-blue-800">
            <p>{{ $t('batch_expression_hint') }}</p>
          </div>
        </div>
      </div>

      <div v-for="(expression, index) in expressions" :key="expression.id" class="mb-6 p-4 border border-slate-200 rounded-lg relative">
        <button
          v-if="expressions.length > 1"
          @click="removeExpression(index)"
          class="absolute top-2 right-2 p-1 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded"
          :title="$t('remove_expression')"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('language') }} *</label>
          <div class="flex gap-2">
            <div class="relative flex-1">
              <select
                v-model="expression.language_code"
                class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3 appearance-none text-slate-800"
                :disabled="languagesLoading"
                @change="handleLanguageChange(index)"
              >
                <option v-if="languagesLoading" value="" disabled>{{ $t('loading_languages') }}</option>
                <option v-else value="" disabled>{{ $t('select_language') }}</option>
                <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                  {{ lang.name }} ({{ lang.code }})
                </option>
              </select>
              <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </div>
            <button
              @click="showAddLanguageModal = true"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
              :title="$t('add_language')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
            </button>
          </div>
        </div>

        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('text') }} *</label>
          <textarea
            v-model="expression.text"
            rows="3"
            class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-4 text-slate-800"
            :placeholder="$t('text_placeholder')"
          ></textarea>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create_region') }}</label>
          <div class="flex gap-2">
            <input
              v-model="expression.region_display"
              class="block flex-1 rounded-md border border-slate-300 shadow-sm py-2 px-4 bg-slate-100 text-slate-500 cursor-not-allowed"
              readonly
            />
            <button
              @click="detectLocation(index)"
              :disabled="expression.detectingLocation || expression.parsingLocation"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
              :title="$t('detect_location')"
            >
              <svg v-if="expression.detectingLocation || expression.parsingLocation" class="animate-spin h-5 w-5 text-slate-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1 1 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </button>
            <button
              @click="toggleMapSelector(index)"
              :disabled="expression.parsingLocation"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
              :title="$t('select_on_map')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
              </svg>
            </button>
          </div>

          <div v-if="expression.showMapSelector" class="mt-3 border border-slate-200 rounded-lg overflow-hidden">
            <div :id="`region-map-${index}`" class="w-full h-64"></div>
            <div class="p-3 bg-slate-50 text-sm text-slate-600">
              {{ $t('click_on_map_to_select') }}
            </div>
          </div>

          <div v-if="expression.parsingLocation" class="mt-2 flex items-center text-sm text-slate-600">
            <svg class="animate-spin h-4 w-4 mr-2 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            {{ $t('parsing_location') }}
          </div>
        </div>
      </div>

      <button
        @click="addExpression"
        class="w-full mb-6 py-3 px-4 border-2 border-dashed border-slate-300 rounded-lg text-slate-600 hover:border-blue-400 hover:text-blue-600 hover:bg-blue-50 transition-colors flex items-center justify-center gap-2"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        {{ $t('add_another_expression') }}
      </button>

      <div class="flex flex-wrap gap-3">
        <button @click="submit" :disabled="submitting" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-6 py-2 disabled:opacity-50 disabled:cursor-not-allowed">
          <svg v-if="submitting" class="animate-spin h-4 w-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          {{ submitting ? $t('submitting') : $t('submit') }}
        </button>
        <button @click="goBack" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
          {{ $t('cancel') }}
        </button>
      </div>

      <div v-if="error" class="mt-4 p-3 bg-red-50 text-red-700 rounded-lg flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        {{ error }}
      </div>

      <div v-if="success" class="mt-4 p-3 bg-green-50 text-green-700 rounded-lg flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        {{ $t('success') }}
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
</template>

<script>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { fetchLanguages } from '../services/languageService.js'
import AddLanguageModal from '../components/AddLanguageModal.vue'

let expressionIdCounter = 0

export default {
  name: 'CreateExpressionPage',
  components: { AddLanguageModal },
  setup() {
    const route = useRoute()
    const router = useRouter()
    const { t, locale } = useI18n()

    const expressions = ref([
      {
        id: ++expressionIdCounter,
        text: route.query.text || '',
        language_code: route.query.language_code || '',
        region_input: route.query.region || '',
        region_display: '',
        detectingLocation: false,
        parsingLocation: false,
        showMapSelector: false
      }
    ])

    const languages = ref([])
    const languagesLoading = ref(false)
    const showAddLanguageModal = ref(false)
    const addingLanguage = ref(false)
    const error = ref(null)
    const success = ref(false)
    const submitting = ref(false)

    const maps = new Map()
    let L = null

    const updateRegionDisplay = (expression) => {
      if (!expression.region_input) {
        expression.region_display = ''
        return
      }
      try {
        const geoInfo = JSON.parse(expression.region_input)
        expression.region_display = geoInfo.name || expression.region_input
      } catch (e) {
        expression.region_display = expression.region_input
      }
    }

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

    const handleAddLanguage = async (languageObj) => {
      try {
        await loadLanguages()
        expressions.value[0].language_code = languageObj.code
        showAddLanguageModal.value = false
      } catch (error) {
        console.error('Error handling added language:', error)
        alert(t('create.addLanguageFailed'))
      }
    }

    const addExpression = () => {
      expressions.value.push({
        id: ++expressionIdCounter,
        text: '',
        language_code: '',
        region_input: '',
        region_display: '',
        detectingLocation: false,
        parsingLocation: false,
        showMapSelector: false
      })
    }

    const removeExpression = (index) => {
      if (expressions.value[index].showMapSelector) {
        const map = maps.get(expressions.value[index].id)
        if (map) {
          map.remove()
          maps.delete(expressions.value[index].id)
        }
      }
      expressions.value.splice(index, 1)
    }

    const handleLanguageChange = (index) => {
      const langCode = expressions.value[index].language_code
      if (langCode && expressions.value[index].region_input) {
        const geoInfo = parseGeoInfo(expressions.value[index].region_input)
        if (geoInfo && (!geoInfo.country_code || geoInfo.country_code === '')) {
          const lang = languages.value.find(l => l.code === langCode)
          if (lang && lang.region_code) {
            geoInfo.country_code = lang.region_code
            expressions.value[index].region_input = JSON.stringify(geoInfo)
            updateRegionDisplay(expressions.value[index])
          }
        }
      }
    }

    const parseGeoInfo = (geoString) => {
      if (!geoString) return null
      try {
        return JSON.parse(geoString)
      } catch (e) {
        return { name: geoString, latitude: null, longitude: null }
      }
    }

    const loadLeaflet = () => {
      return new Promise((resolve, reject) => {
        if (window.L) {
          resolve()
          return
        }

        const link = document.createElement('link')
        link.rel = 'stylesheet'
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
        link.onload = () => {
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

    const reverseGeocode = async (lat, lon, langCode) => {
      try {
        let nominatimLangCode = 'en';
        if (langCode) {
          nominatimLangCode = langCode.split('-')[0];
        } else if (locale.value) {
          nominatimLangCode = locale.value.split('-')[0];
        }

        const response = await fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&accept-language=${nominatimLangCode}`
        )

        if (response.ok) {
          const data = await response.json()

          if (data.address) {
            const address = data.address
            const locationParts = [
              address.neighbourhood || address.suburb || address.city_district,
              address.village || address.town || address.city,
              address.state_district || address.county || address.state || address.province,
              address.country
            ].filter(part => part)

            const countryCode = address.country_code?.toUpperCase() || null
            const countryName = address.country || null

            let displayName = locationParts.filter(part => part).join(', ')

            if (!displayName || displayName.trim() === '') {
              try {
                const fallbackResponse = await fetch(
                  `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&accept-language=en`
                )

                if (fallbackResponse.ok) {
                  const fallbackData = await fallbackResponse.json()

                  if (fallbackData.address) {
                    const fallbackAddress = fallbackData.address
                    const fallbackLocationParts = [
                      fallbackAddress.neighbourhood || fallbackAddress.suburb || fallbackAddress.city_district,
                      fallbackAddress.village || fallbackAddress.town || fallbackAddress.city,
                      fallbackAddress.state_district || fallbackAddress.county || fallbackAddress.state || fallbackAddress.province,
                      fallbackAddress.country
                    ].filter(part => part)

                    displayName = fallbackLocationParts.filter(part => part).join(', ') || `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                  } else {
                    displayName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                  }
                } else {
                  displayName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                }
              } catch (e) {
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

        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon),
          country_code: null,
          country_name: null
        }
      } catch (err) {
        console.error('Reverse geocoding failed:', err)
        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon),
          country_code: null,
          country_name: null
        }
      }
    }

    const initMap = async (index) => {
      try {
        await loadLeaflet()
        L = window.L

        await new Promise(resolve => setTimeout(resolve, 100))

        const mapElement = document.getElementById(`region-map-${index}`)
        if (!mapElement) {
          console.error('Map element not found')
          return
        }

        const expressionId = expressions.value[index].id
        const existingMap = maps.get(expressionId)
        if (existingMap) {
          existingMap.remove()
          maps.delete(expressionId)
        }

        const map = L.map(`region-map-${index}`).setView([20, 0], 2)

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map)

        maps.set(expressionId, map)

        map.on('click', async (e) => {
          const { lat, lng } = e.latlng
          expressions.value[index].parsingLocation = true

          try {
            const geoInfo = await reverseGeocode(lat, lng, expressions.value[index].language_code)
            expressions.value[index].region_input = JSON.stringify(geoInfo)
            updateRegionDisplay(expressions.value[index])
          } catch (err) {
            console.error('Failed to process map click:', err)
            error.value = t('create.locationParsingFailed')
          } finally {
            expressions.value[index].parsingLocation = false
            expressions.value[index].showMapSelector = false
          }
        })
      } catch (err) {
        console.error('Failed to initialize map:', err)
        error.value = 'Failed to load map: ' + err.message
      }
    }

    const toggleMapSelector = async (index) => {
      expressions.value[index].showMapSelector = !expressions.value[index].showMapSelector
      if (expressions.value[index].showMapSelector) {
        setTimeout(() => {
          initMap(index)
        }, 100)
      } else {
        const map = maps.get(expressions.value[index].id)
        if (map) {
          map.remove()
          maps.delete(expressions.value[index].id)
        }
      }
    }

    const detectLocation = async (index) => {
      expressions.value[index].detectingLocation = true
      error.value = null

      if (!navigator.geolocation) {
        error.value = t('create.geolocationNotSupported')
        expressions.value[index].detectingLocation = false
        return
      }

      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords

          try {
            expressions.value[index].parsingLocation = true
            const geoInfo = await reverseGeocode(latitude, longitude, expressions.value[index].language_code)
            expressions.value[index].region_input = JSON.stringify(geoInfo)
            updateRegionDisplay(expressions.value[index])
          } catch (err) {
            console.error('Location processing failed:', err)
            error.value = t('create.locationParsingFailed')
          } finally {
            expressions.value[index].parsingLocation = false
            expressions.value[index].detectingLocation = false
          }
        },
        (err) => {
          console.error('Geolocation error:', err)
          error.value = t('create.locationDetectionFailed')
          expressions.value[index].detectingLocation = false
        },
        {
          timeout: 10000,
          enableHighAccuracy: true
        }
      )
    }

    async function submit() {
      error.value = null
      success.value = false
      submitting.value = true

      const validExpressions = expressions.value.filter(expr => expr.text && expr.language_code)

      if (validExpressions.length === 0) {
        error.value = t('create.requiredError')
        submitting.value = false
        return
      }

      const token = localStorage.getItem('authToken')
      if (!token) {
        error.value = 'You must be logged in to create expressions'
        submitting.value = false
        return
      }

      try {
        let createdBy = null
        try {
          const response = await fetch('/api/v1/users/me', {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          })

          if (response.ok) {
            const userData = await response.json()
            createdBy = userData.data.username
          } else if (response.status === 401) {
            error.value = 'Session expired. Please log in again.'
            localStorage.removeItem('authToken')
            router.push('/login')
            return
          }
        } catch (e) {
          console.warn('Could not fetch current user info:', e)
        }

        const payloadExpressions = validExpressions.map(expr => {
          let regionData = null
          if (expr.region_input) {
            try {
              regionData = JSON.parse(expr.region_input)
            } catch (e) {
              regionData = { name: expr.region_input }
            }
          }

          return {
            text: expr.text,
            language_code: expr.language_code,
            region_code: regionData?.country_code || null,
            region_name: regionData?.name || null,
            region_latitude: regionData && regionData.latitude !== undefined && regionData.latitude !== null ? regionData.latitude : null,
            region_longitude: regionData && regionData.longitude !== undefined && regionData.longitude !== null ? regionData.longitude : null,
            created_by: createdBy,
            source_type: 'user',
            review_status: 'pending'
          }
        })

        const res = await fetch('/api/v1/expressions/batch', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ expressions: payloadExpressions })
        })

        if (!res.ok) {
          if (res.status === 401) {
            error.value = 'Session expired. Please log in again.'
            localStorage.removeItem('authToken')
            router.push('/login')
            return
          }
          const txt = await res.text()
          throw new Error(txt || 'Batch submission failed')
        }

        const result = await res.json()
        console.log('Batch submission result:', result)
        success.value = true
      } catch (e) {
        error.value = e.message || String(e)
      } finally {
        submitting.value = false
      }
    }

    const goBack = () => {
      router.push('/')
    }

    onMounted(() => {
      loadLanguages()
      expressions.value.forEach(expr => updateRegionDisplay(expr))
    })

    onUnmounted(() => {
      maps.forEach(map => map.remove())
      maps.clear()
    })

    return {
      expressions,
      languages,
      languagesLoading,
      showAddLanguageModal,
      addingLanguage,
      error,
      success,
      submitting,
      addExpression,
      removeExpression,
      handleLanguageChange,
      detectLocation,
      toggleMapSelector,
      submit,
      goBack,
      t,
      handleAddLanguage
    }
  }
}
</script>
