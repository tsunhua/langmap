<template>
  <div class="min-h-screen">
    <!-- Hero Section - Full Width -->
    <div class="relative bg-slate-50 px-4 sm:px-6 lg:px-8">
      <!-- Title -->
      <div class="relative max-w-4xl mx-auto text-center pt-6 sm:pt-10 pb-4 z-10">
        <h1 class="text-4xl md:text-5xl font-bold text-slate-900 mb-2">
          <span class="bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">{{ $t('home_title')
          }}</span>
        </h1>
      </div>

      <!-- Search Bar -->
      <div class="relative max-w-2xl mx-auto pb-6 z-10">
        <div class="flex gap-3 bg-white rounded-2xl shadow-xl p-2">
          <input v-model="searchQuery" @keyup.enter.prevent="goToSearch" :placeholder="$t('placeholder')"
            class="flex-1 px-6 py-3 text-lg text-slate-800 bg-transparent focus:outline-none" />
          <button @click="goToSearch"
            class="flex items-center px-4 sm:px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl font-semibold hover:from-blue-700 hover:to-indigo-700 transition-all shadow-lg hover:shadow-xl">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <span class="hidden sm:inline ml-2">{{ $t('search') }}</span>
          </button>
        </div>
      </div>

      <!-- Floating Expressions - Background Layer -->
      <div class="h-48 relative">
        <FloatingExpressions />
      </div>
    </div>

    <!-- Stats Section -->
    <div class="bg-white border-b border-slate-200 px-4 sm:px-6 lg:px-8">
      <div class="max-w-7xl mx-auto py-12">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
          <div class="p-6">
            <div
              class="text-4xl font-bold bg-gradient-to-r from-blue-600 to-blue-700 bg-clip-text text-transparent mb-2">
              {{ stats.totalExpressions }}</div>
            <div class="text-slate-600 font-medium">{{ $t('total_expressions') }}</div>
          </div>
          <div class="p-6">
            <div
              class="text-4xl font-bold bg-gradient-to-r from-indigo-600 to-indigo-700 bg-clip-text text-transparent mb-2">
              {{ stats.totalLanguages }}</div>
            <div class="text-slate-600 font-medium">{{ $t('languages') }}</div>
          </div>
          <div class="p-6">
            <div
              class="text-4xl font-bold bg-gradient-to-r from-purple-600 to-purple-700 bg-clip-text text-transparent mb-2">
              {{ stats.totalRegions }}</div>
            <div class="text-slate-600 font-medium">{{ $t('regions') }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- World Language Heatmap -->
    <div class="bg-slate-50 py-16 px-4 sm:px-6 lg:px-8">
      <div class="max-w-7xl mx-auto">
        <h2 class="text-3xl font-bold text-slate-800 mb-3 text-center">
          {{ $t('map_title') }}
        </h2>
        <p class="text-slate-600 mb-12 text-center max-w-2xl mx-auto">
          {{ $t('explore_map_description') }}
        </p>

        <!-- Map Container -->
        <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-slate-200 p-2 relative z-0">
          <div id="map" class="w-full rounded-xl" style="height: 600px;"></div>

          <!-- Loading overlay -->
          <div v-if="loading"
            class="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center rounded-xl">
            <div class="text-center">
              <svg class="animate-spin h-8 w-8 text-blue-600 mx-auto mb-2" xmlns="http://www.w3.org/2000/svg"
                fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                </path>
              </svg>
              <p class="text-slate-600">{{ $t('loading_map') }}</p>
            </div>
          </div>

          <!-- Legend -->
          <div class="px-6 py-4 bg-slate-50 border-t border-slate-200 rounded-b-xl">
            <div class="flex items-center justify-center gap-6 text-sm">
              <span class="text-slate-600 font-medium">{{ $t('expression_density') }}:</span>
              <div class="flex items-center gap-2">
                <div class="w-4 h-4 rounded-full bg-blue-200"></div>
                <span class="text-slate-600">{{ $t('low') }} (&lt;5k)</span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-4 h-4 rounded-full bg-blue-400"></div>
                <span class="text-slate-600">{{ $t('medium') }} (&lt;50k)</span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-4 h-4 rounded-full bg-blue-600"></div>
                <span class="text-slate-600">{{ $t('high') }} (≥50k)</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="bg-white py-16 px-4 sm:px-6 lg:px-8">
      <div class="max-w-7xl mx-auto">
        <h2 class="text-3xl font-bold text-slate-800 mb-12 text-center">
          {{ $t('get_started') }}
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div
            class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-8 border border-blue-100 hover:shadow-lg transition-shadow cursor-pointer"
            @click="scrollToSearch">
            <div
              class="w-12 h-12 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-lg flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-800 mb-2">{{ $t('search_expressions') }}</h3>
            <p class="text-slate-600 mb-4">{{ $t('search_expressions_desc') }}</p>
            <span class="text-blue-600 font-medium hover:text-blue-700">
              {{ $t('start_searching') }}
            </span>
          </div>

          <div
            class="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-8 border border-purple-100 hover:shadow-lg transition-shadow cursor-pointer"
            @click="handleAddExpressionClick">
            <div
              class="w-12 h-12 bg-gradient-to-br from-purple-600 to-pink-600 rounded-lg flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-800 mb-2">{{ $t('add_expression') }}</h3>
            <p class="text-slate-600 mb-4">{{ $t('add_expression_description') }}</p>
            <span class="text-purple-600 font-medium hover:text-purple-700">
              {{ $t('add_new') }}
            </span>
          </div>

          <!-- <div class="bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl p-8 border border-green-100 hover:shadow-lg transition-shadow cursor-pointer" @click="scrollToMap">
            <div class="w-12 h-12 bg-gradient-to-br from-green-600 to-emerald-600 rounded-lg flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 104 0 2 2 0 012-2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-800 mb-2">{{ $t('explore_map') }}</h3>
            <p class="text-slate-600 mb-4">{{ $t('explore_map_description') }}</p>
            <span class="text-green-600 font-medium hover:text-green-700">
              {{ $t('view_map') }}
            </span>
          </div> -->

          <div
            class="bg-gradient-to-br from-orange-50 to-amber-50 rounded-xl p-8 border border-orange-100 hover:shadow-lg transition-shadow cursor-pointer"
            @click="$router.push('/handbooks')">
            <div
              class="w-12 h-12 bg-gradient-to-br from-orange-600 to-amber-600 rounded-lg flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332 0.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5S19.832 5.477 21 6.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332 0.477-4.5 1.253" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-800 mb-2">{{ $t('handbook_title') }}</h3>
            <p class="text-slate-600 mb-4">{{ $t('handbook_empty_info') }}</p>
            <span class="text-orange-600 font-medium hover:text-orange-700">
              {{ $t('get_started') }} →
            </span>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import FloatingExpressions from '../components/FloatingExpressions.vue'

export default {
  name: 'Home',
  components: {
    FloatingExpressions
  },
  setup() {
    const router = useRouter()
    const { t } = useI18n()
    const searchQuery = ref('')
    const loading = ref(true)
    const stats = ref({
      totalExpressions: 0,
      totalLanguages: 0,
      totalRegions: 0
    })

    let map = null
    let markers = []
    let L

    // Generate heat color based on count
    const getHeatColor = (count) => {
      if (count < 5000) return '#bfdbfe' // blue-200 (low)
      if (count < 50000) return '#60a5fa' // blue-400 (medium)
      return '#2563eb' // blue-600 (high)
    }

    const goToSearch = () => {
      if (searchQuery.value.trim()) {
        router.push({ name: 'Search', query: { q: searchQuery.value.trim() } })
      } else {
        router.push({ name: 'Search' })
      }
    }

    const selectRegion = (region) => {
      console.log('Selected region:', region)
      // Could navigate to filtered search or show details
      router.push({ name: 'Search', query: { region: region } })
    }

    const handleAddExpressionClick = () => {
      console.log('Add expression button clicked');
      const isAuthenticated = !!localStorage.getItem('authToken');

      if (!isAuthenticated) {
        console.log('User not authenticated, redirecting to login');
        router.push('/login');
        return;
      }

      console.log('User authenticated, navigating to create page');
      router.push('/create-expression');
    }

    // 滚动到顶部搜索框
    const scrollToSearch = () => {
      // 获取顶部搜索框元素
      const searchBox = document.querySelector('.relative.max-w-4xl.mx-auto .flex.gap-3.bg-white.rounded-2xl.shadow-xl.p-2');

      if (searchBox) {
        // 平滑滚动到搜索框
        searchBox.scrollIntoView({ behavior: 'smooth' });

        // 聚焦到搜索输入框
        const searchInput = searchBox.querySelector('input');
        if (searchInput) {
          searchInput.focus();
        }
      }
    }

    // 滚动到世界语言分布图
    const scrollToMap = () => {
      // 获取世界语言分布图部分的标题元素
      const mapSection = document.querySelector('.bg-slate-50.py-16.px-4.sm\\:px-6.lg\\:px-8');

      if (mapSection) {
        // 平滑滚动到地图部分
        mapSection.scrollIntoView({ behavior: 'smooth' });
      }
    }

    // Create map markers for each language
    const createMarkers = (languageData) => {
      if (!map || !L) return

      // Clear existing markers
      markers.forEach(marker => map.removeLayer(marker))
      markers = []

      // Add new markers
      languageData.forEach(point => {
        if (point.lat && point.lng) {
          const marker = L.circleMarker([point.lat, point.lng], {
            radius: point.count < 5000 ? 8 : point.count < 50000 ? 16 : 24,
            fillColor: getHeatColor(point.count),
            color: "#1e40af",
            weight: 1,
            opacity: 0.8,
            fillOpacity: 0.6
          }).addTo(map)

          // Bind tooltip to show information on hover
          marker.bindTooltip(`
            <div>
              <b>${t('region')}:</b> ${point.regionName || t('unknown')}<br>
              <b>${t('language')}:</b> ${point.languageName}<br>
              <b>${t('expressions')}:</b> ${point.count}
            </div>
          `, {
            direction: 'top',
            offset: [0, -10],
            permanent: false,
            sticky: true,
            opacity: 0.9
          });

          // Bind popup with the same information
          marker.bindPopup(`
            <div>
              <b>${t('region')}:</b> ${point.regionName || t('unknown')}<br>
              <b>${t('language')}:</b> ${point.languageName}<br>
              <b>${t('expressions')}:</b> ${point.count}
            </div>
          `);

          // Remove click handler to make heatmap non-clickable
          // marker.on('click', () => selectRegion(point.languageCode))

          markers.push(marker)
        }
      })
    }

    // Initialize the map
    const initMap = () => {
      if (typeof window === 'undefined' || !window.L) return false

      L = window.L

      // Create map instance with zoom constraints
      map = L.map('map', {
        minZoom: 2,  // Prevent zooming out too far
        maxBounds: L.latLngBounds(
          L.latLng(-85, -180), // Southwest corner
          L.latLng(85, 180)    // Northeast corner
        )
      }).setView([20, 0], 2)

      // Add OpenStreetMap tiles
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        minZoom: 2
      }).addTo(map)

      return true
    }

    // Heatmap data with geographic coordinates
    const heatmapData = ref([])

    // Load statistics and heatmap data
    const loadData = async () => {
      loading.value = true
      try {
        // Fetch statistics from the new dedicated endpoint
        console.log('Fetching statistics from /api/v1/statistics');
        const statsRes = await fetch('/api/v1/statistics')
        console.log('Statistics response status:', statsRes.status);
        console.log('Statistics response ok?', statsRes.ok);

        // Fetch heatmap data from the new dedicated endpoint
        console.log('Fetching heatmap data from /api/v1/heatmap');
        const heatmapRes = await fetch('/api/v1/heatmap')
        console.log('Heatmap response status:', heatmapRes.status);
        console.log('Heatmap response ok?', heatmapRes.ok);

        if (statsRes.ok) {
          const statsData = await statsRes.json()
          console.log('Received statistics data:', statsData);
          stats.value = {
            totalExpressions: statsData.total_expressions,
            totalLanguages: statsData.total_languages,
            totalRegions: statsData.total_regions
          }
          console.log('Updated stats value:', stats.value);
        } else {
          console.error('Failed to fetch statistics, status:', statsRes.status);
          const errorText = await statsRes.text();
          console.error('Error response:', errorText);
        }

        if (heatmapRes.ok) {
          const heatmapResult = await heatmapRes.json()
          const heatmapPoints = heatmapResult.data || []

          heatmapData.value = heatmapPoints.map(point => ({
            languageCode: point.language_code,
            languageName: point.language_name,
            regionCode: point.region_code,
            regionName: point.region_name,
            count: point.count,
            lat: point.latitude ? parseFloat(point.latitude) : 0,
            lng: point.longitude ? parseFloat(point.longitude) : 0
          }))

          // Create markers on the map
          if (map) {
            createMarkers(heatmapData.value)
          }
        } else {
          console.error('Failed to fetch heatmap data, status:', heatmapRes.status);
          const errorText = await heatmapRes.text();
          console.error('Error response:', errorText);
        }
      } catch (e) {
        console.error('Failed to load data:', e)
      } finally {
        loading.value = false
      }
    }

    // Load Leaflet from CDN if not already loaded
    const loadLeaflet = () => {
      return new Promise((resolve) => {
        if (window.L) {
          resolve()
          return
        }

        // Load CSS
        const link = document.createElement('link')
        link.rel = 'stylesheet'
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
        document.head.appendChild(link)

        // Load JS
        const script = document.createElement('script')
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
        script.onload = () => {
          resolve()
        }
        document.body.appendChild(script)
      })
    }

    onMounted(async () => {
      await loadLeaflet()
      if (initMap()) {
        loadData()
      }
    })

    onUnmounted(() => {
      // Clean up map instance
      if (map) {
        map.remove()
      }
    })

    return {
      searchQuery,
      loading,
      stats,
      goToSearch,
      selectRegion,
      handleAddExpressionClick,
      scrollToSearch,
      scrollToMap,
      loadData
    }
  }
}
</script>