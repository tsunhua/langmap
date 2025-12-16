<script>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { fetchLanguages } from '../services/languageService.js'
import AddLanguageModal from '../components/AddLanguageModal.vue'

export default {
  name: 'CreateExpression',
  components: { AddLanguageModal },
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
    const router = useRouter()
    const { t, locale } = useI18n()
    const text = ref(props.initialText || route.query.text || '')
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

    async function submit () {
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
            router.push('/login');
            return;
          }
        } catch (e) {
          console.warn('Could not fetch current user info:', e);
        }
        
        // Create the expression
        const payload = {
          text: text.value,
          language_code: language_code.value,
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
            router.push('/login');
            return;
          }
          const txt = await res.text()
          throw new Error(txt || 'create failed')
        }
        
        const created = await res.json()
        
        // 如果传入了 initialMeaningId，则自动关联
        if (props.initialMeaningId) {
          try {
            const updateRes = await fetch(`/api/v1/expressions/${created.id}`, {
              method: 'PATCH',
              headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
              },
              body: JSON.stringify({ 
                meaning_id: props.initialMeaningId,
                updated_by: createdBy
              })
            })
            
            if (!updateRes.ok) {
              if (updateRes.status === 401) {
                // Token is invalid, redirect to login
                error.value = 'Session expired. Please log in again.';
                localStorage.removeItem('authToken');
                router.push('/login');
                return;
              }
              throw new Error('failed to update expression with meaning')
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
      toggleMapSelector
    }
  }
}
</script>