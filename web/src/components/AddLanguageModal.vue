<template>
  <div v-if="visible" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 overflow-y-auto">
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full my-8 mx-auto max-h-[calc(100vh-2rem)] overflow-hidden flex flex-col">
      <div class="px-6 py-4 border-b border-slate-200">
        <h3 class="text-lg font-medium text-slate-900">{{ $t('add_language') }}</h3>
      </div>
      <form @submit.prevent="handleAddLanguage" class="px-6 py-4 overflow-y-auto flex-grow">
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('language_code') }}</label>
          <input 
            v-model="formData.code" 
            type="text" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          >
          <p class="mt-1 text-xs text-slate-500">{{ $t('language_code_help') }}</p>
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('language_name') }}</label>
          <input 
            v-model="formData.name" 
            type="text" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          >
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('language_group_name') }}</label>
          <input 
            v-model="formData.group_name" 
            type="text" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
          <p class="mt-1 text-xs text-slate-500">{{ $t('language_group_name_help') }}</p>
        </div>

        
        <!-- Region Information Section -->
        <div class="mb-4 border border-slate-200 rounded-lg p-4">
          <h4 class="text-md font-medium text-slate-800 mb-3">{{ $t('region_information') }}</h4>
          
          <!-- Map Selection -->
          <div class="mb-4">
            <button
              type="button"
              @click="toggleMapSelector"
              class="w-full px-3 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 flex items-center justify-center gap-2 mb-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
              </svg>
              {{ showMapSelector ? $t('hide_map') : $t('select_on_map') }}
            </button>
            
            <div v-show="showMapSelector" id="region-map" class="w-full h-64 rounded-md"></div>
          </div>
          
          <!-- Region Details -->
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('region_name') }}</label>
              <input 
                v-model="formData.region_name" 
                type="text" 
                class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
            </div>
            

            
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('latitude') }}</label>
                <input 
                  v-model="formData.latitude" 
                  type="text" 
                  class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
              </div>
              <div>
                <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('longitude') }}</label>
                <input 
                  v-model="formData.longitude" 
                  type="text" 
                  class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
              </div>
            </div>
          </div>
        </div>
        
        <div class="mb-6">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('text_direction') }}</label>
          <select 
            v-model="formData.direction" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="ltr">{{ $t('create_ltr') }}</option>
            <option value="rtl">{{ $t('create_rtl') }}</option>
          </select>
        </div>
        <div class="flex justify-end gap-3">
          <button 
            type="button" 
            @click="close"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-md transition-colors"
          >
            {{ $t('cancel') }}
          </button>
          <button 
            type="submit" 
            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md transition-colors"
            :disabled="addingLanguage"
          >
            {{ addingLanguage ? $t('adding') : $t('add_language') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import { ref, reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { languagesApi } from '../api/index.ts'

export default {
  name: 'AddLanguageModal',
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    addingLanguage: {
      type: Boolean,
      default: false
    }
  },
  emits: ['close', 'add-language'],
  setup(props, { emit }) {
    const { t } = useI18n()
    
    const formData = reactive({
      code: '',
      name: '',
      group_name: '',
      region_name: '',
      region_code: '',
      latitude: '',
      longitude: '',
      direction: 'ltr'
    })
    
    // Map selection
    const showMapSelector = ref(false)
    let map = null
    let L
    
    const handleAddLanguage = async () => {
      if (!formData.code || !formData.name) return
      
      try {
        const result = await languagesApi.create({
          code: formData.code,
          name: formData.name,
          is_active: 1
        })

        if (result.success && result.data) {
          const languageObj = result.data
          // Reset form
          formData.code = ''
          formData.name = ''
          formData.group_name = ''
          formData.region_name = ''
          formData.region_code = ''
          formData.latitude = ''
          formData.longitude = ''
          formData.direction = 'ltr'

          emit('add-language', languageObj)
        } else {
          console.error('Add language failed:', result.error || result.message)
          alert('Failed to add language. Please try again.')
        }
      } catch (error) {
        console.error('Error adding language:', error)
        alert(t('create.addLanguageFailed'))
      }
    }
    
    const close = () => {
      // Clean up map when closing modal
      if (map) {
        map.remove()
        map = null
      }
      showMapSelector.value = false
      emit('close')
    }
    
    // Reset form when modal is closed
    watch(() => props.visible, (newVal) => {
      if (!newVal) {
        formData.code = ''
        formData.name = ''
        formData.group_name = ''
        formData.region_name = ''
        formData.region_code = ''
        formData.latitude = ''
        formData.longitude = ''
        formData.direction = 'ltr'
        
        // Clean up map when closing modal
        if (map) {
          map.remove()
          map = null
        }
        showMapSelector.value = false
      }
    })
    
    // Load Leaflet library dynamically
    const loadLeaflet = () => {
      return new Promise((resolve, reject) => {
        // Check if already loaded
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
    
    // Reverse geocode coordinates to get location info
    const reverseGeocode = async (lat, lon) => {
      try {
        const response = await fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&accept-language=en`
        )
        
        if (response.ok) {
          const data = await response.json()

          // print log
          console.log('Reverse geocoding result:', data)

          if (data.address) {
            const address = data.address
            // Get city-level information
            const cityName = address.city || address.town || address.village || address.municipality || null
            const countryName = address.country || null
            const regionCode = address.country_code? address.country_code.toUpperCase() : null
            
            // Combine for region name
            let regionName = cityName
            if (cityName && countryName) {
              regionName = `${cityName}, ${countryName}`
            } else if (!regionName) {
              regionName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
            }

            return {
              name: regionName,
              latitude: parseFloat(lat),
              longitude: parseFloat(lon),
              region_code: regionCode,
            }
          }
        }
        // Fallback to coordinates only
        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon)
        }
      } catch (err) {
        console.error('Reverse geocoding failed:', err)
        // Fallback to coordinates only
        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon)
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
          
          try {
            // Get location info from coordinates
            const locationInfo = await reverseGeocode(lat, lng)
            
            // Update form data
            formData.region_name = locationInfo.name
            formData.region_code = locationInfo.region_code
            formData.latitude = locationInfo.latitude.toFixed(6)
            formData.longitude = locationInfo.longitude.toFixed(6)
          } catch (err) {
            console.error('Failed to process map click:', err)
          }
        })
      } catch (err) {
        console.error('Failed to initialize map:', err)
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
    
    return {
      formData,
      showMapSelector,
      handleAddLanguage,
      close,
      toggleMapSelector
    }
  }
}
</script>