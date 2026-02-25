<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="handbook" class="space-y-8">
      <!-- Header -->
      <header class="space-y-4">
        <div class="flex justify-between items-start">
          <h1 class="text-4xl font-extrabold text-gray-900 tracking-tight">{{ handbook.title }}</h1>
          <button 
            v-if="canEdit"
            @click="goToEdit"
            class="px-4 py-2 text-sm font-semibold text-blue-600 bg-blue-50 rounded-xl hover:bg-blue-100 transition-all shadow-sm"
          >
            {{ $t('edit') }}
          </button>
        </div>
        <p class="text-lg text-gray-500 max-w-2xl leading-relaxed">
          {{ handbook.description }}
        </p>
        
        <div class="flex items-center gap-6 pt-4 border-t border-gray-100">
          <div class="flex items-center gap-4">
            <label class="text-sm font-bold text-gray-400 uppercase tracking-widest">{{ $t('handbook_learning_language') || 'Learning Language' }}:</label>
            <select 
              v-model="targetLanguage" 
              class="bg-white border-none text-sm font-bold text-blue-600 focus:ring-2 focus:ring-blue-500 rounded-lg py-1 pl-2 pr-8 shadow-sm cursor-pointer"
            >
              <option v-for="lang in sortedLanguages" :key="lang.code" :value="lang.code">
                {{ lang.name }} ({{ lang.code }})
              </option>
            </select>
          </div>
          <div class="h-4 w-px bg-gray-200"></div>
          <div class="text-[10px] text-gray-400 font-bold uppercase tracking-widest">
            {{ $t('handbook_last_updated') || 'Updated' }}: {{ formatDate(handbook.updated_at) }}
          </div>
        </div>
      </header>

      <!-- Content -->
      <article 
        class="prose prose-blue max-w-none bg-white p-8 md:p-12 rounded-3xl shadow-xl shadow-blue-900/5 border border-gray-100 leading-loose"
        v-html="renderedContent"
      ></article>

      <!-- Audio Player Placeholder (Hidden) -->
      <audio ref="audioPlayer" class="hidden"></audio>
    </div>

    <div v-else class="text-center py-24">
      <div class="text-6xl mb-6">🏜️</div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">{{ $t('handbook_not_found') || 'Handbook Not Found' }}</h2>
      <p class="text-gray-500 mb-8">{{ $t('handbook_not_found_info') || 'The handbook may have been deleted or moved.' }}</p>
      <router-link to="/handbooks" class="text-blue-600 font-medium hover:underline">
        {{ $t('handbook_back_to_list') || 'Back to Handbook List' }}
      </router-link>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import MarkdownIt from 'markdown-it'
import { getHandbookById, getHandbookExpressions } from '../services/handbookService'
import { fetchLanguages } from '../services/languageService'

export default {
  name: 'HandbookView',
  props: ['id'],
  setup(props) {
    const router = useRouter()
    const md = new MarkdownIt({ html: true })
    
    // State
    const handbook = ref(null)
    const languages = ref([])
    const targetLanguage = ref(localStorage.getItem('targetLanguage') || 'zh-CN')
    const expressionsMap = ref({})
    const loading = ref(true)
    const audioPlayer = ref(null)
    const currentUser = ref(null) // Should be fetched from auth store/localstorage

    // Detection Regex for {{exp:ID|mid:MID|text:TEXT|audio:URL}}
    const TAG_REGEX = /\{\{exp:(\d+)\|mid:(\d+)\|text:([^|]+)\|audio:([^}]*)\}\}/g

    const fetchInitialData = async () => {
      loading.value = true
      try {
        // Fetch languages
        languages.value = await fetchLanguages()
        
        // Fetch handbook
        const data = await getHandbookById(props.id)
        handbook.value = data
        
        if (data) {
          // Use the handbook's target_lang if set, otherwise fall back to localStorage
          if (data.target_lang) {
            targetLanguage.value = data.target_lang
          }

          // Detect all MIDs in the content
          const mids = []
          let match
          const contentRegex = /\{\{exp:(\d+)\|mid:(\d+)\|/g
          while ((match = contentRegex.exec(data.content)) !== null) {
            mids.push(parseInt(match[2]))
          }
          
          if (mids.length > 0) {
            await fetchTranslations(mids)
          }
        }

        // Auth check for edit button
        const userStr = localStorage.getItem('user')
        if (userStr) currentUser.value = JSON.parse(userStr)

      } catch (error) {
        console.error('Failed to load handbook data:', error)
      } finally {
        loading.value = false
      }
    }

    const fetchTranslations = async (mids) => {
      if (!mids || mids.length === 0) return
      try {
        const results = await getHandbookExpressions(targetLanguage.value, mids)
        const map = {}
        results.forEach(ex => {
          map[ex.meaning_id] = ex
        })
        expressionsMap.value = map
      } catch (error) {
        console.error('Failed to fetch translations:', error)
      }
    }

    // Watch language change to re-fetch
    watch(targetLanguage, async (newLang) => {
      localStorage.setItem('targetLanguage', newLang)
      if (!handbook.value) return
      
      const mids = []
      let match
      while ((match = TAG_REGEX.exec(handbook.value.content)) !== null) {
        mids.push(parseInt(match[2]))
      }
      
      if (mids.length > 0) {
        await fetchTranslations(mids)
      }
    })

    const renderedContent = computed(() => {
      if (!handbook.value) return ''

      // Process Markdown
      let html = md.render(handbook.value.content)

      // We use a custom function in the global scope to handle clicks for rendered HTML
      window.playHandbookAudio = (url) => {
        if (!url || !audioPlayer.value) return
        audioPlayer.value.src = url
        audioPlayer.value.play()
      }

      return html.replace(TAG_REGEX, (match, exp, mid, originalText, originalAudio) => {
        const translation = expressionsMap.value[mid]

        // Resolve audio: prefer translated expression's first audio record, fallback to original
        let audioUrl = originalAudio
        if (translation && translation.audio_url) {
          try {
            const parsed = JSON.parse(translation.audio_url)
            audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || originalAudio) : originalAudio
          } catch { audioUrl = originalAudio }
        }

        if (translation) {
          // Show original text + [translation] in brackets, same as editor preview
          return `
            <span class="handbook-item inline-flex items-center gap-1 px-1.5 py-0.5 bg-blue-50 text-blue-600 border border-blue-200 rounded text-sm font-bold cursor-pointer hover:bg-blue-100 group"
                  onclick="event.stopPropagation(); window.playHandbookAudio('${audioUrl}')">
              ${originalText}
              <span class="text-gray-400 font-normal text-xs">[${translation.text}]</span>
              <span class="text-[10px] opacity-60 group-hover:opacity-100 transition-opacity">🔊</span>
            </span>
          `
        } else {
          // Fallback: show original text only, slightly dimmed
          return `
            <span class="handbook-item inline-flex items-center gap-1 px-1.5 py-0.5 bg-gray-50 text-gray-600 border border-gray-200 rounded text-sm font-medium cursor-pointer hover:bg-gray-100 group"
                  onclick="event.stopPropagation(); window.playHandbookAudio('${originalAudio}')">
              ${originalText}
              <span class="text-[10px] opacity-40 group-hover:opacity-80 transition-opacity">🔊</span>
            </span>
          `
        }
      })
    })

    const canEdit = computed(() => {
      if (!handbook.value || !currentUser.value) return false
      return handbook.value.user_id === currentUser.value.id || currentUser.value.role === 'admin'
    })

    const sortedLanguages = computed(() => {
      return [...languages.value].sort((a, b) => a.name.localeCompare(b.name))
    })

    const goToEdit = () => {
      router.push(`/handbooks/edit/${props.id}`)
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString()
    }

    onMounted(fetchInitialData)

    return {
      handbook,
      loading,
      targetLanguage,
      sortedLanguages,
      renderedContent,
      audioPlayer,
      canEdit,
      goToEdit,
      formatDate
    }
  }
}
</script>

<style>
/* Global styles for rendered markdown */
.prose h1, .prose h2, .prose h3 {
  color: #111827;
  font-weight: 800;
  margin-top: 2em;
  margin-bottom: 0.8em;
}

.prose p {
  margin-bottom: 1.5em;
  color: #374151;
}

.handbook-item {
  padding: 0 4px;
  border-radius: 4px;
}

.handbook-item:hover {
  background-color: rgba(59, 130, 246, 0.05);
}

.handbook-item.is-fallback:hover {
  background-color: rgba(107, 114, 128, 0.05);
}
</style>
