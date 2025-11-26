<template>
  <div class="min-h-screen -mx-4 sm:-mx-6 lg:-mx-8">
    <!-- Hero Section - Full Width -->
    <div class="relative bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 py-24 px-4 sm:px-6 lg:px-8">
      <!-- Decorative elements -->
      <div class="absolute inset-0 overflow-hidden">
        <div class="absolute -top-40 -right-40 w-80 h-80 bg-blue-400 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-blob"></div>
        <div class="absolute -bottom-40 -left-40 w-80 h-80 bg-purple-400 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-blob animation-delay-2000"></div>
        <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-80 h-80 bg-indigo-400 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-blob animation-delay-4000"></div>
      </div>
      
      <div class="relative max-w-4xl mx-auto text-center">
        <h1 class="text-5xl md:text-6xl font-bold text-slate-900 mb-4">
          Explore the World of 
          <span class="bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">Languages</span>
        </h1>
        <p class="text-xl md:text-2xl text-slate-600 mb-10">
          Discover how expressions vary across regions and cultures
        </p>
        
        <!-- Search Bar -->
        <div class="max-w-2xl mx-auto">
          <div class="flex gap-3 bg-white rounded-2xl shadow-xl p-2">
            <input 
              v-model="searchQuery"
              @keydown.enter="goToSearch"
              placeholder="Search for an expression..."
              class="flex-1 px-6 py-3 text-lg text-slate-800 bg-transparent focus:outline-none"
            />
            <button 
              @click="goToSearch"
              class="px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl font-semibold hover:from-blue-700 hover:to-indigo-700 transition-all shadow-lg hover:shadow-xl"
            >
              Search
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Stats Section -->
    <div class="bg-white border-b border-slate-200 px-4 sm:px-6 lg:px-8">
      <div class="max-w-7xl mx-auto py-12">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
          <div class="p-6">
            <div class="text-4xl font-bold bg-gradient-to-r from-blue-600 to-blue-700 bg-clip-text text-transparent mb-2">{{ stats.totalExpressions }}</div>
            <div class="text-slate-600 font-medium">Total Expressions</div>
          </div>
          <div class="p-6">
            <div class="text-4xl font-bold bg-gradient-to-r from-indigo-600 to-indigo-700 bg-clip-text text-transparent mb-2">{{ stats.totalLanguages }}</div>
            <div class="text-slate-600 font-medium">Languages</div>
          </div>
          <div class="p-6">
            <div class="text-4xl font-bold bg-gradient-to-r from-purple-600 to-purple-700 bg-clip-text text-transparent mb-2">{{ stats.totalRegions }}</div>
            <div class="text-slate-600 font-medium">Regions</div>
          </div>
        </div>
      </div>
    </div>

    <!-- World Language Heatmap -->
    <div class="bg-slate-50 py-16 px-4 sm:px-6 lg:px-8">
      <div class="max-w-7xl mx-auto">
        <h2 class="text-3xl font-bold text-slate-800 mb-3 text-center">
          Global Language Distribution
        </h2>
        <p class="text-slate-600 mb-12 text-center max-w-2xl mx-auto">
          Explore the richness of linguistic expressions across different regions. 
          Larger and brighter circles indicate more expressions in that area.
        </p>
        
        <!-- Map Container -->
        <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-slate-200">
          <div class="relative" style="height: 600px;">
            <!-- SVG World Map Visualization -->
            <svg 
              viewBox="0 0 1000 500" 
              class="w-full h-full"
              preserveAspectRatio="xMidYMid meet"
            >
              <!-- Background -->
              <rect width="1000" height="500" fill="#f8fafc" />
              
              <!-- Simplified world map outline -->
              <g class="continents" stroke="#cbd5e1" stroke-width="1" fill="#e2e8f0">
                <!-- Simplified continent shapes (placeholder) -->
                <path d="M 100 150 Q 150 120, 200 150 L 250 180 Q 280 200, 250 230 L 200 250 Q 150 240, 120 220 Z" opacity="0.3" />
                <path d="M 300 100 L 450 90 L 480 150 L 460 200 L 380 220 L 320 180 Z" opacity="0.3" />
                <path d="M 500 180 Q 550 160, 600 180 L 650 220 Q 680 250, 650 280 L 580 300 Q 520 290, 500 260 Z" opacity="0.3" />
                <path d="M 150 280 L 220 270 L 250 320 L 230 370 L 170 380 L 140 340 Z" opacity="0.3" />
                <path d="M 700 200 Q 750 180, 800 200 L 850 240 L 820 290 L 760 310 L 710 280 Z" opacity="0.3" />
              </g>
              
              <!-- Data points (circles representing language richness) -->
              <g class="data-points">
                <circle 
                  v-for="point in heatmapData" 
                  :key="point.id"
                  :cx="point.x" 
                  :cy="point.y" 
                  :r="point.size"
                  :fill="getHeatColor(point.count)"
                  :opacity="0.6"
                  class="cursor-pointer hover:opacity-90 transition-opacity"
                  @click="selectRegion(point)"
                >
                  <title>{{ point.region }}: {{ point.count }} expressions</title>
                </circle>
              </g>
              
              <!-- Labels for major regions -->
              <g class="labels" fill="#475569" font-size="14" font-weight="500">
                <text 
                  v-for="point in heatmapData.filter(p => p.count > 5)" 
                  :key="'label-' + point.id"
                  :x="point.x" 
                  :y="point.y - point.size - 5"
                  text-anchor="middle"
                  class="pointer-events-none"
                >
                  {{ point.region }}
                </text>
              </g>
            </svg>
            
            <!-- Loading overlay -->
            <div v-if="loading" class="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center">
              <div class="text-center">
                <svg class="animate-spin h-8 w-8 text-blue-600 mx-auto mb-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <p class="text-slate-600">Loading data...</p>
              </div>
            </div>
          </div>
          
          <!-- Legend -->
          <div class="px-6 py-4 bg-slate-50 border-t border-slate-200">
            <div class="flex items-center justify-center gap-6 text-sm">
              <span class="text-slate-600 font-medium">Expression Density:</span>
              <div class="flex items-center gap-2">
                <div class="w-4 h-4 rounded-full bg-blue-200"></div>
                <span class="text-slate-600">Low</span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-4 h-4 rounded-full bg-blue-400"></div>
                <span class="text-slate-600">Medium</span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-4 h-4 rounded-full bg-blue-600"></div>
                <span class="text-slate-600">High</span>
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
          Get Started
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-8 border border-blue-100 hover:shadow-lg transition-shadow cursor-pointer" @click="$router.push({ name: 'search' })">
            <div class="w-12 h-12 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-lg flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-800 mb-2">Search Expressions</h3>
            <p class="text-slate-600 mb-4">Find how words and phrases are expressed across different languages and regions.</p>
            <span class="text-blue-600 font-medium hover:text-blue-700">
              Start Searching →
            </span>
          </div>
          
          <div class="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-8 border border-purple-100 hover:shadow-lg transition-shadow cursor-pointer" @click="$router.push({ name: 'create' })">
            <div class="w-12 h-12 bg-gradient-to-br from-purple-600 to-pink-600 rounded-lg flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-800 mb-2">Add Expression</h3>
            <p class="text-slate-600 mb-4">Contribute to our database by adding expressions from your language or region.</p>
            <span class="text-purple-600 font-medium hover:text-purple-700">
              Add New →
            </span>
          </div>
          
          <div class="bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl p-8 border border-green-100 hover:shadow-lg transition-shadow cursor-pointer">
            <div class="w-12 h-12 bg-gradient-to-br from-green-600 to-emerald-600 rounded-lg flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-800 mb-2">Explore Map</h3>
            <p class="text-slate-600 mb-4">Visualize linguistic diversity on an interactive world map.</p>
            <span class="text-green-600 font-medium hover:text-green-700">
              View Map →
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

export default {
  name: 'Home',
  setup() {
    const router = useRouter()
    const searchQuery = ref('')
    const loading = ref(true)
    const stats = ref({
      totalExpressions: 0,
      totalLanguages: 0,
      totalRegions: 0
    })
    
    // Heatmap data with geographic coordinates (normalized to SVG viewBox)
    const heatmapData = ref([])
    
    // Generate heat color based on count
    const getHeatColor = (count) => {
      if (count < 3) return '#bfdbfe' // blue-200
      if (count < 7) return '#60a5fa' // blue-400
      if (count < 15) return '#3b82f6' // blue-500
      return '#2563eb' // blue-600
    }
    
    const goToSearch = () => {
      if (searchQuery.value.trim()) {
        router.push({ name: 'search', query: { q: searchQuery.value } })
      } else {
        router.push({ name: 'search' })
      }
    }
    
    const selectRegion = (point) => {
      console.log('Selected region:', point)
      // Could navigate to filtered search or show details
      router.push({ name: 'search', query: { region: point.region } })
    }
    
    // Load statistics and heatmap data
    const loadData = async () => {
      loading.value = true
      try {
        // Fetch expressions to calculate stats
        const res = await fetch('/api/v1/expressions?limit=1000')
        if (res.ok) {
          const expressions = await res.json()
          
          // Calculate stats
          const languages = new Set(expressions.map(e => e.language))
          const regions = new Set(expressions.map(e => e.region).filter(r => r))
          
          stats.value = {
            totalExpressions: expressions.length,
            totalLanguages: languages.size,
            totalRegions: regions.size
          }
          
          // Group by region and calculate positions
          const regionCounts = {}
          expressions.forEach(expr => {
            const region = expr.region || 'Global'
            regionCounts[region] = (regionCounts[region] || 0) + 1
          })
          
          // Generate heatmap points with pseudo-geographic distribution
          const regionPositions = generateRegionPositions(Object.keys(regionCounts))
          
          heatmapData.value = Object.entries(regionCounts).map(([region, count], idx) => {
            const pos = regionPositions[region] || { x: 500, y: 250 }
            return {
              id: idx,
              region,
              count,
              x: pos.x,
              y: pos.y,
              size: Math.min(Math.sqrt(count) * 8 + 10, 50)
            }
          })
        }
      } catch (e) {
        console.error('Failed to load data:', e)
      } finally {
        loading.value = false
      }
    }
    
    // Generate pseudo-geographic positions for regions
    const generateRegionPositions = (regions) => {
      const positions = {}
      const regionMap = {
        'China': { x: 700, y: 200 },
        'Spain': { x: 350, y: 180 },
        'Global': { x: 500, y: 250 },
        'USA': { x: 200, y: 180 },
        'UK': { x: 350, y: 140 },
        'France': { x: 370, y: 170 },
        'Germany': { x: 400, y: 150 },
        'Japan': { x: 820, y: 200 },
        'Korea': { x: 780, y: 190 },
        'India': { x: 650, y: 240 },
        'Brazil': { x: 250, y: 320 },
        'Mexico': { x: 150, y: 220 },
        'Canada': { x: 180, y: 120 },
        'Australia': { x: 800, y: 380 },
        'Russia': { x: 600, y: 120 },
      }
      
      regions.forEach((region, idx) => {
        if (regionMap[region]) {
          positions[region] = regionMap[region]
        } else {
          // Random position for unknown regions
          positions[region] = {
            x: 200 + (idx * 73) % 600,
            y: 150 + (idx * 97) % 250
          }
        }
      })
      
      return positions
    }
    
    onMounted(() => {
      loadData()
    })
    
    return {
      searchQuery,
      loading,
      stats,
      heatmapData,
      getHeatColor,
      goToSearch,
      selectRegion
    }
  }
}
</script>
