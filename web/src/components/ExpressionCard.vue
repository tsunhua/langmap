<template>
  <router-link :to="{ name: 'Detail', params: { id: item.id } }" class="block no-underline text-inherit">
    <div class="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden hover:shadow-md transition-all duration-200 mx-4 sm:mx-0">
      <div class="p-4">
        <div class="flex justify-between items-start">
          <div>
            <h3 class="text-xl font-semibold text-slate-800">{{ item.text }}</h3>
            <div class="mt-1 text-sm text-slate-600">
              <span class="inline-flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
                </svg>
                {{ getLanguageDisplayName(item.language_code) }}
              </span>
              <span v-if="getRegionDisplayName(item)">
                <span class="mx-2">•</span>
                <span class="inline-flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  {{ getRegionDisplayName(item) }}
                </span>
              </span>
            </div>
          </div>
          <span :class="[
            'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
            item.source_type === 'ai' ? 'bg-sky-100 text-sky-800' : 
            item.source_type === 'user' ? 'bg-blue-100 text-blue-800' : 'bg-green-100 text-green-800'
          ]">
            {{ item.source_type }}
          </span>
        </div>
        
        <div class="mt-4 flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <button 
              v-if="item.audio_url" 
              @click.stop.prevent="playAudio" 
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 py-1 px-3 text-sm flex items-center"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
              </svg>
              {{ $t('expressionCard.play') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </router-link>
</template>

<script>
import { useI18n } from 'vue-i18n'

export default {
  name: 'ExpressionCard',
  props: { 
    item: { 
      type: Object, 
      required: true 
    } 
  },
  setup() {
    const { t } = useI18n()
    return { t }
  },
  methods: {
    playAudio () {
      const audio = new Audio(this.item.audio_url)
      audio.play()
    },
    getLanguageDisplayName(languageCode) {
      // This would ideally come from a global language store or API
      // For now, we'll use a simple mapping for common languages
      const languageMap = {
        'en-US': 'English',
        'zh-CN': '中文 (北京)',
        'zh-TW': '中文 (台北)',
        'es': 'Español',
        'fr': 'Français',
        'ja': '日本語'
      }
      
      // In a real implementation, we would fetch the language data from the backend
      // and use the native_name field. For now, we'll use the static mapping.
      return languageMap[languageCode] || languageCode
    },
    getRegionDisplayName(item) {
      // Use the new region_name field if available
      if (item.region_name) {
        return item.region_name + (item.region_code ? ` (${item.region_code})` : '')
      }
      
      // If region is a JSON string, try to parse it
      if (item.region) {
        try {
          const regionData = JSON.parse(item.region)
          return regionData.name || item.region
        } catch (e) {
          // If it's not valid JSON, return as is
          return item.region
        }
      }
      
      // Return empty if no region data
      return ''
    }
  }
}
</script>