<template>
  <div class="bg-white rounded-lg shadow-sm border border-slate-200">
    <div class="border-b border-slate-200 px-4 py-3">
      <h4 class="font-semibold text-slate-800">{{ $t('version_history') }}</h4>
    </div>
    
    <div class="p-3">
      <div v-if="loading" class="flex items-center justify-center py-8">
        <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="ml-2 text-slate-600">{{ $t('loading_versions') }}</span>
      </div>
      
      <div v-else>
        <div v-if="versions.length === 0" class="relative">
          <!-- Vertical line -->
          <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-slate-200"></div>
          
          <div class="space-y-6">
            <div class="relative pl-12">
              <!-- Timeline dot -->
              <div class="absolute left-2 top-4 w-4 h-4 rounded-full bg-blue-500 border-4 border-white shadow"></div>
              
              <!-- Version card (using current expression data) -->
              <div class="border border-slate-200 rounded-lg p-4 hover:bg-slate-50 transition-colors">
                <div class="flex justify-between items-start mb-2">
                  <div class="text-slate-800 font-medium">{{ expression && expression.text ? expression.text : 'N/A' }}</div>
                  <div class="text-xs text-slate-500">
                    {{ expression && expression.created_at ? formatDate(expression.created_at) : 'N/A' }}
                  </div>
                </div>
                
                <div class="text-xs text-slate-500 flex flex-wrap items-center mb-3">
                  <span class="inline-flex items-center mr-3">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    {{ expression && expression.created_by ? expression.created_by : $t('anonymous') }}
                  </span>
                </div>
                
                <div class="mt-3 p-2 bg-slate-50 rounded text-sm text-slate-600">
                  {{ $t('current_version') }}
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Timeline view -->
        <div v-else class="relative">
          <!-- Vertical line -->
          <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-slate-200"></div>
          
          <div class="space-y-6">
            <div 
              v-for="(v, index) in versions" 
              :key="v.id" 
              class="relative pl-12"
            >
              <!-- Timeline dot -->
              <div class="absolute left-2 top-4 w-4 h-4 rounded-full bg-blue-500 border-4 border-white shadow"></div>
              
              <!-- Version card -->
              <div class="border border-slate-200 rounded-lg p-4 hover:bg-slate-50 transition-colors">
                <div class="flex justify-between items-start mb-2">
                  <div class="text-slate-800 font-medium">{{ v.text }}</div>
                  <div class="text-xs text-slate-500">
                    {{ formatDate(v.created_at) }}
                  </div>
                </div>
                
                <div class="text-xs text-slate-500 flex flex-wrap items-center mb-3">
                  <span class="inline-flex items-center mr-3">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    {{ v.created_by || $t('anonymous') }}
                  </span>
                  
                  <span class="inline-flex items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                    {{ v.source_type }}
                  </span>
                </div>
                
                <!-- Diff view for changes compared to previous version -->
                <div v-if="index < versions.length - 1" class="border-t border-slate-100 pt-3">
                  <h5 class="text-xs font-semibold text-slate-700 mb-2">{{ $t('changes') }}:</h5>
                  <div class="space-y-1">
                    <!-- Text change -->
                    <div v-if="v.text !== versions[index + 1].text" class="flex items-start">
                      <span class="text-yellow-600 font-mono mr-2">📝</span>
                      <span class="text-slate-600 text-sm flex-1">
                        <span class="font-medium">{{ $t('text') }}: </span>
                        "{{ versions[index + 1].text }}" → "{{ v.text }}"
                      </span>
                    </div>
                    
                    <!-- Audio URL change -->
                    <div v-if="v.audio_url !== versions[index + 1].audio_url" class="flex items-start">
                      <span class="text-blue-600 font-mono mr-2">🔊</span>
                      <span class="text-slate-600 text-sm flex-1">
                        <span class="font-medium">{{ $t('audio') }}: </span>
                        <span v-if="versions[index + 1].audio_url" class="line-through">"{{ versions[index + 1].audio_url }}"</span>
                        <span v-else class="italic">{{ $t('none') }}</span>
                        <span class="mx-1">→</span>
                        <span v-if="v.audio_url">"{{ v.audio_url }}"</span>
                        <span v-else class="italic">{{ $t('none') }}</span>
                      </span>
                    </div>
                    
                    <!-- Region change -->
                    <div v-if="v.region_name !== versions[index + 1].region_name || 
                               v.region_latitude !== versions[index + 1].region_latitude || 
                               v.region_longitude !== versions[index + 1].region_longitude" class="flex items-start">
                      <span class="text-green-600 font-mono mr-2">📍</span>
                      <span class="text-slate-600 text-sm flex-1">
                        <span class="font-medium">{{ $t('location') }}: </span>
                        <span v-if="versions[index + 1].region_name">
                          {{ versions[index + 1].region_name }}({{ versions[index + 1].region_latitude }}, {{ versions[index + 1].region_longitude }})
                        </span>
                        <span v-else class="italic">{{ $t('none') }}</span>
                        <span class="mx-1">→</span>
                        <span v-if="v.region_name">
                          {{ v.region_name }}({{ v.region_latitude }}, {{ v.region_longitude }})
                        </span>
                        <span v-else class="italic">{{ $t('none') }}</span>
                      </span>
                    </div>
                  </div>
                </div>
                
                <div v-if="v.change_summary" class="mt-3 p-2 bg-slate-50 rounded text-sm text-slate-600">
                  {{ v.change_summary }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'

export default {
  name: 'VersionHistory',
  props: ['expressionId'],
  setup (props) {
    const { t, locale } = useI18n()
    const versions = ref([])
    const loading = ref(false)
    const expression = ref(null)

    // Map custom locale codes to valid BCP 47 language tags for date formatting
    const getValidLocale = (localeCode) => {
      const localeMapping = {
        'cieh-tc': 'zh-TW',
        'nan-TW': 'zh-TW',
        'yue-HK': 'zh-HK',
        'nan-x-cha': 'zh-CN'
      }
      return localeMapping[localeCode] || localeCode || 'en-US'
    }

    const formatDate = (dateString) => {
      const options = { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric', 
        hour: '2-digit', 
        minute: '2-digit',
        timeZoneName: 'short'
      }
      const validLocale = getValidLocale(locale.value)
      
      let date
      try {
        if (dateString && dateString.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/)) {
          date = new Date(dateString + 'Z')
        } else {
          date = new Date(dateString)
        }
        return date.toLocaleString(validLocale, options)
      } catch (e) {
        console.warn(`Failed to format date with locale ${validLocale}, falling back to en-US`, e)
        return date.toLocaleString('en-US', options)
      }
    }

    async function load () {
      loading.value = true
      try {
        // 获取表达式基本信息
        const exprRes = await fetch(`/api/v1/expressions/${props.expressionId}`)
        if (exprRes.ok) {
          expression.value = await exprRes.json()
        }

        // 获取版本历史
        const res = await fetch(`/api/v1/expressions/${props.expressionId}/versions`)
        if (!res.ok) {
          versions.value = []
          return
        }
        versions.value = await res.json()
        // Sort versions by created_at in descending order (newest first)
        versions.value.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      } catch (e) {
        console.warn(e)
      } finally {
        loading.value = false
      }
    }

    onMounted(load)
    return { versions, loading, formatDate, t, expression }
  }
}
</script>