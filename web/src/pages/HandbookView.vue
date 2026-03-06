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
import { getHandbookById, getHandbookExpressions, stableExpressionId, getExpressionById } from '../services/handbookService'
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
    const TEXT_LANG_REGEX = /\{\{text:([^|]+)\|lang:([^}]+)\}\}/g

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

          // Detect all Text/Lang entries in the content
          const expressionsToFetch = []

          let match
          const tlRegex = /\{\{text:([^|]+)\|lang:([^}]+)\}\}/g
          while ((match = tlRegex.exec(data.content)) !== null) {
            const id = stableExpressionId(match[1], match[2])
            expressionsToFetch.push({ id, text: match[1], lang: match[2] })
          }

          if (expressionsToFetch.length > 0) {
            await fetchMetadata(expressionsToFetch)
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

    const fetchMetadata = async (expressionsToFetch) => {
      try {
        // Phase 1: Fetch source expressions
        const sourcePromises = expressionsToFetch.map(e => {
          if (!expressionsMap.value[e.id]) {
            return getExpressionById(e.id).then(ex => {
              expressionsMap.value[e.id] = ex
              return ex
            }).catch(() => null)
          }
          return Promise.resolve(expressionsMap.value[e.id])
        })

        const sourceExprs = await Promise.all(sourcePromises)

        // Phase 2: Fetch translations for target_lang
        const mids = []
        sourceExprs.forEach(expr => {
          expr?.meanings?.forEach(m => {
            if (!mids.includes(m.id)) mids.push(m.id)
          })
        })

        if (mids.length > 0 && instructionLanguage.value) {
          const translations = await getHandbookExpressions(instructionLanguage.value, mids)
          translations.forEach(trans => {
            if (trans.meaning_id) {
              expressionsMap.value[`trans_${trans.meaning_id}`] = trans
            } else if (trans.meanings) {
              trans.meanings.forEach(m => {
                if (mids.includes(m.id)) {
                  expressionsMap.value[`trans_${m.id}`] = trans
                }
              })
            }
          })
        }
      } catch (error) {
        console.error('Failed to fetch metadata:', error)
      }
    }

    // Watch language change to re-fetch
    watch(instructionLanguage, async (newLang) => {
      localStorage.setItem('instructionLanguage', newLang)
      if (!handbook.value) return

      const expressionsToFetch = []
      let match
      const tlRegex = /\{\{text:([^|]+)\|lang:([^}]+)\}\}/g
      while ((match = tlRegex.exec(handbook.value.content)) !== null) {
        const id = stableExpressionId(match[1], match[2])
        expressionsToFetch.push({ id, text: match[1], lang: match[2] })
      }

      if (expressionsToFetch.length > 0) {
        await fetchMetadata(expressionsToFetch)
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

      // Helper to render an expression item
      const renderItem = (id, text, meanings, audioUrl) => {
        const meaningsText = meanings && meanings.length > 0
          ? ` <span class="text-gray-400 font-normal text-xs">[${meanings.map(m => m.text).join(', ')}]</span>`
          : ''
        const audioIcon = audioUrl ? `<span class="text-[10px]">🔊</span>` : ''

        return `
          <span class="handbook-item inline-flex items-center gap-1 px-1.5 py-0.5 bg-blue-50 text-blue-600 border border-blue-200 rounded text-sm font-bold cursor-pointer hover:bg-blue-100"
                onclick="event.stopPropagation(); window.navigateToExpression(${id}); ${audioUrl ? `window.playHandbookAudio('${audioUrl}')` : ''}">
            ${text}${meaningsText}${audioIcon}
          </span>
        `
      }

      // Render text:lang format
      let result = html.replace(TEXT_LANG_REGEX, (match, text, lang) => {
        const id = stableExpressionId(text, lang)
        const expr = expressionsMap.value[id]
        if (expr) {
          const translations = []
          expr.meanings?.forEach(m => {
            if (expressionsMap.value[`trans_${m.id}`]) {
              translations.push(expressionsMap.value[`trans_${m.id}`])
            }
          })

          let audioUrl = ''
          if (expr.audio_url) {
            try {
              const parsed = JSON.parse(expr.audio_url)
              audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || '') : ''
            } catch { audioUrl = '' }
          }
          return renderItem(id, text, translations, audioUrl)
        }
        return `<span class="text-gray-400 border-b border-dotted border-gray-300">${text}</span>`
      })

      return result
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
