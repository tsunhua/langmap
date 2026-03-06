<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
    <div v-if="loading" class="flex justify-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="handbook" class="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-200">
      <!-- Header -->
      <div class="flex justify-between items-start gap-6 pb-6 border-b border-gray-100">
        <div class="space-y-1.5 flex-1">
          <h1 class="text-3xl font-bold text-gray-900">{{ handbook.title }}</h1>
          <p v-if="handbook.description" class="text-sm text-gray-500 max-w-2xl leading-relaxed">{{ handbook.description
            }}</p>
          <p class="text-[11px] text-gray-400">{{ $t('last_updated') }}: {{ formatDate(handbook.updated_at) }}</p>
        </div>

        <!-- Language Switcher -->
        <div class="flex items-center gap-2 flex-shrink-0">
          <span class="text-xs text-gray-400">{{ $t('learn_in') }}</span>
          <select v-model="instructionLanguage"
            class="border border-gray-200 rounded-lg text-xs text-gray-600 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-1.5 px-2 bg-white cursor-pointer">
            <option v-for="lang in sortedLanguages" :key="lang.code" :value="lang.code">
              {{ lang.name }}
            </option>
          </select>
        </div>

        <!-- Edit Button -->
        <button v-if="canEdit" @click="goToEdit"
          class="px-4 py-2 text-sm border border-gray-200 rounded-lg text-gray-600 hover:text-blue-600 hover:bg-blue-50 transition-colors">
          {{ $t('edit_handbook') }}
        </button>
      </div>

      <!-- Content -->
      <div class="prose prose-blue prose-sm max-w-none leading-loose py-6 markdown-body" v-html="renderedContent"></div>

      <!-- Audio Player Placeholder (Hidden) -->
      <audio ref="audioPlayer" class="hidden"></audio>
    </div>

    <div v-else class="text-center py-24">
      <div class="bg-white p-8 md:p-12 rounded-2xl shadow-sm border border-gray-200 max-w-md mx-auto">
        <div class="text-6xl mb-6">🏜️</div>
        <h2 class="text-2xl font-bold text-gray-900 mb-2">{{ $t('handbook_not_found') }}</h2>
        <p class="text-gray-500 mb-8">{{ $t('handbook_not_found_info') }}</p>
        <router-link to="/handbooks" class="text-blue-600 font-medium hover:underline">
          {{ $t('handbook_back_to_list') }}
        </router-link>
      </div>
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
    const instructionLanguage = ref(localStorage.getItem('instructionLanguage') || 'zh-CN')
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
            instructionLanguage.value = data.target_lang
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
        const results = await getHandbookExpressions(instructionLanguage.value, mids)
        const map = {}
        results.forEach(ex => {
          map[ex.id] = ex
        })
        expressionsMap.value = map
      } catch (error) {
        console.error('Failed to fetch translations:', error)
      }
    }

    // Watch language change to re-fetch
    watch(instructionLanguage, async (newLang) => {
      localStorage.setItem('instructionLanguage', newLang)
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

      window.navigateToExpression = (id) => {
        router.push(`/detail/${id}`)
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
          const audioIcon = audioUrl ? `<span class="text-[10px]">🔊</span>` : ''
          return `
            <span class="handbook-item inline-flex items-center gap-1 px-1.5 py-0.5 bg-blue-50 text-blue-600 border border-blue-200 rounded text-sm font-bold cursor-pointer hover:bg-blue-100"
                  onclick="event.stopPropagation(); window.navigateToExpression(${exp}); ${audioUrl ? `window.playHandbookAudio('${audioUrl}')` : ''}">
              ${originalText}
              <span class="text-gray-400 font-normal text-xs">[${translation.text}]</span>
              ${audioIcon}
            </span>
          `
        } else {
          // Fallback: show original text only, same as editor preview
          const audioIcon = originalAudio ? `<span class="text-[10px]">🔊</span>` : ''
          return `
            <span class="handbook-item inline-flex items-center gap-1 px-1.5 py-0.5 bg-blue-50 text-blue-600 border border-blue-200 rounded text-sm font-bold cursor-pointer hover:bg-blue-100"
                  onclick="event.stopPropagation(); window.navigateToExpression(${exp}); ${originalAudio ? `window.playHandbookAudio('${originalAudio}')` : ''}">
              ${originalText}
              ${audioIcon}
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
      instructionLanguage,
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

<style scoped>
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
