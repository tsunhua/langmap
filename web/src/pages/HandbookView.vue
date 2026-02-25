<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="handbook" class="space-y-8">
      <!-- Header -->
      <header class="space-y-3">
        <!-- Title row with top-right icon toolbar -->
        <div class="flex justify-between items-start gap-4">
          <div>
            <h1 class="text-4xl font-extrabold text-gray-900 tracking-tight">{{ handbook.title }}</h1>
            <p v-if="handbook.description" class="mt-2 text-base text-gray-500 max-w-2xl leading-relaxed">{{ handbook.description }}</p>
            <p class="mt-2 text-[11px] text-gray-400">{{ $t('handbook_last_updated') || 'Updated' }}: {{ formatDate(handbook.updated_at) }}</p>
          </div>

          <!-- Top-right icon toolbar -->
          <div class="flex items-center gap-0.5 flex-shrink-0 mt-1">
            <!-- Language switcher: globe icon + compact select -->
            <div class="flex items-center gap-1 px-2 py-1 rounded hover:bg-gray-50 transition-colors" :title="$t('handbook_learning_language') || 'Learning Language'">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-gray-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18ZM3.6 9h16.8M3.6 15h16.8M12 3a14.4 14.4 0 0 1 0 18M12 3a14.4 14.4 0 0 0 0 18" />
              </svg>
              <span class="text-xs text-gray-400">{{ $t('handbook_learn_in') || 'Learn in' }}</span>
              <select
                v-model="targetLanguage"
                class="border-none bg-transparent text-xs text-gray-600 focus:ring-0 focus:outline-none cursor-pointer p-0 appearance-none"
                style="background-image: none;"
              >
                <option v-for="lang in sortedLanguages" :key="lang.code" :value="lang.code">
                  {{ lang.name }}
                </option>
              </select>
            </div>

            <!-- Edit button (icon only) -->
            <button
              v-if="canEdit"
              @click="goToEdit"
              class="p-1 rounded text-gray-500 hover:text-blue-600 hover:bg-blue-50 transition-colors"
              :title="$t('edit')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487a2.25 2.25 0 1 1 3.182 3.182L7.5 20.213l-4.5 1 1-4.5L16.862 4.487Z" />
              </svg>
            </button>
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
