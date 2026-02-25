<template>
  <div class="max-w-6xl mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold text-gray-900">
        {{ isEditing ? $t('handbook_edit') : $t('handbook_new') }}
      </h1>
      <div class="flex gap-4">
        <button 
          @click="goBack"
          class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-all"
        >
          {{ $t('cancel') }}
        </button>
        <button 
          @click="save"
          :disabled="saving"
          class="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-all font-medium shadow-md"
        >
          {{ saving ? $t('saving') : $t('save') }}
        </button>
      </div>
    </div>

    <div class="max-w-4xl mx-auto space-y-6">
      <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
        <!-- Title -->
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">{{ $t('handbook_title_label') }}</label>
          <input 
            v-model="form.title"
            type="text"
            class="w-full text-lg font-medium border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-3"
            :placeholder="$t('handbook_title_placeholder')"
          />
        </div>

        <!-- Description -->
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">{{ $t('description') }}</label>
          <textarea 
            v-model="form.description"
            rows="2"
            class="w-full border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            :placeholder="$t('handbook_description_placeholder')"
          ></textarea>
        </div>

        <!-- Language Settings -->
        <div class="mb-6 grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-1">
              {{ $t('handbook_source_lang') || 'Writing Language' }}
            </label>
            <p class="text-xs text-gray-400 mb-2">{{ $t('handbook_source_lang_hint') || 'The language used in this handbook content' }}</p>
            <select 
              v-model="form.source_lang"
              class="w-full border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-2"
            >
              <option value="">{{ $t('handbook_lang_auto') || 'Any Language' }}</option>
              <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                {{ lang.name }} ({{ lang.code }})
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-1">
              {{ $t('handbook_target_lang') || 'Learning Language' }}
            </label>
            <p class="text-xs text-gray-400 mb-2">{{ $t('handbook_target_lang_hint') || 'Default language for reading & previewing expressions' }}</p>
            <select 
              v-model="form.target_lang"
              class="w-full border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-2"
            >
              <option value="">{{ $t('handbook_lang_auto') || 'Any Language' }}</option>
              <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                {{ lang.name }} ({{ lang.code }})
              </option>
            </select>
          </div>
        </div>

        <!-- Content Editor -->
        <div class="mb-6">
          <div class="flex justify-between items-center mb-2">
            <label class="block text-sm font-semibold text-gray-700">{{ $t('handbook_content_label') }}</label>
            <div class="flex gap-2">
              <button 
                @click="previewMode = false"
                :class="['px-3 py-1 text-xs font-medium rounded-md transition-all', !previewMode ? 'bg-blue-100 text-blue-700' : 'text-gray-500 hover:bg-gray-100']"
              >
                {{ $t('handbook_write') }}
              </button>
              <button 
                @click="switchToPreview"
                :class="['px-3 py-1 text-xs font-medium rounded-md transition-all', previewMode ? 'bg-blue-100 text-blue-700' : 'text-gray-500 hover:bg-gray-100']"
              >
                {{ $t('handbook_preview') }}
                <span v-if="previewLoading" class="ml-1 inline-block w-2 h-2 border border-blue-500 border-t-transparent rounded-full animate-spin"></span>
              </button>
            </div>
          </div>

          <!-- Toolbar (Visible only in Write mode) -->
          <div v-if="!previewMode" class="flex flex-wrap items-center gap-1 mb-2 p-1.5 bg-gray-50 border border-gray-200 rounded-xl overflow-x-auto">
            <button @click="undo" :disabled="historyIndex <= 0" class="px-2 py-1 text-sm hover:bg-white rounded transition-colors disabled:opacity-30" title="Undo">↩️</button>
            <button @click="redo" :disabled="historyIndex >= history.length - 1" class="px-2 py-1 text-sm hover:bg-white rounded transition-colors disabled:opacity-30" title="Redo">↪️</button>
            <div class="h-4 w-px bg-gray-300 mx-1"></div>
            <button @click="applyStyle('**', '**')" class="px-2 py-1 text-sm font-bold hover:bg-white rounded transition-colors" title="Bold">B</button>
            <button @click="applyStyle('*', '*')" class="px-2 py-1 text-sm italic hover:bg-white rounded transition-colors" title="Italic">I</button>
            <button @click="applyStyle('<u>', '</u>')" class="px-2 py-1 text-sm underline hover:bg-white rounded transition-colors" title="Underline">U</button>
            <button @click="applyStyle('~~', '~~')" class="px-2 py-1 text-sm line-through hover:bg-white rounded transition-colors" title="Strikethrough">S</button>
            <div class="h-4 w-px bg-gray-300 mx-1"></div>
            <button @click="applyStyle('# ')" class="px-2 py-1 text-xs font-bold hover:bg-white rounded transition-colors">H1</button>
            <button @click="applyStyle('## ')" class="px-2 py-1 text-xs font-bold hover:bg-white rounded transition-colors">H2</button>
            <button @click="applyStyle('### ')" class="px-2 py-1 text-xs font-bold hover:bg-white rounded transition-colors">H3</button>
            <div class="h-4 w-px bg-gray-300 mx-1"></div>
            <button @click="applyStyle('- ')" class="px-2 py-1 text-sm hover:bg-white rounded transition-colors" title="Bullet List">•</button>
            <button @click="applyStyle('1. ')" class="px-2 py-1 text-sm hover:bg-white rounded transition-colors" title="Numbered List">1.</button>
            <button @click="applyStyle('> ')" class="px-2 py-1 text-sm hover:bg-white rounded transition-colors" title="Quote">"</button>
            <button @click="applyStyle('`', '`')" class="px-2 py-1 text-sm font-mono hover:bg-white rounded transition-colors" title="Code">&lt;/&gt;</button>
          </div>

          <!-- Expression Search (separate row, below toolbar, no overflow clipping) -->
          <div v-if="!previewMode" class="relative mb-2">
            <input 
              v-model="searchQuery"
              type="text"
              class="w-full pl-8 pr-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs focus:ring-1 focus:ring-blue-500 outline-none focus:bg-white"
              :placeholder="form.source_lang ? `🔍 Search & insert expression in ${form.source_lang}...` : ('🔍 ' + ($t('handbook_insert_expression') || 'Search & insert expression...'))"
              @input="search"
            />

            <!-- Search Results Dropdown -->
            <div v-if="searchQuery && (searchResults.length > 0 || searching)" class="absolute z-50 top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-xl shadow-xl max-h-64 overflow-y-auto custom-scrollbar">
              <div v-if="searching" class="p-4 text-center">
                <div class="animate-spin inline-block w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full"></div>
              </div>
              <div v-else>
                <div 
                  v-for="expr in searchResults" 
                  :key="expr.id"
                  class="p-2 border-b border-gray-50 last:border-none hover:bg-blue-50 cursor-pointer transition-colors"
                  @click="insertAndClear(expr)"
                >
                  <div class="flex justify-between items-center">
                    <span class="font-bold text-sm text-gray-800">{{ expr.text }}</span>
                    <span class="text-[10px] bg-blue-100 text-blue-600 px-1 rounded font-bold uppercase">{{ expr.language_code }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="!previewMode" class="relative group">
            <textarea 
              ref="contentArea"
              v-model="form.content"
              rows="18"
              class="w-full font-mono text-sm border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 p-4 transition-all"
              :placeholder="$t('handbook_content_placeholder')"
            ></textarea>
            <div class="absolute bottom-4 right-4 text-[10px] text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity">
              Markdown Supported
            </div>
          </div>
          
          <!-- Preview Mode -->
          <div v-else>
            <div v-if="previewLoading" class="w-full min-h-[200px] flex items-center justify-center border border-gray-200 rounded-xl bg-gray-50">
              <div class="text-center text-gray-500">
                <div class="animate-spin inline-block w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full mb-2"></div>
                <p class="text-sm">{{ $t('handbook_loading_preview') || 'Loading translations...' }}</p>
              </div>
            </div>
            <div v-else class="w-full min-h-[450px] border border-gray-200 rounded-xl p-8 bg-gray-50 prose prose-blue prose-sm max-w-none markdown-body" v-html="renderedContent"></div>
            <p v-if="form.target_lang" class="text-xs text-gray-400 mt-2">
              {{ $t('handbook_preview_lang_hint') || 'Preview shows translations in' }}: <strong>{{ form.target_lang }}</strong>
            </p>
          </div>
        </div>

        <!-- Public Toggle -->
        <div class="flex items-center gap-6 p-4 bg-gray-50 rounded-xl border border-gray-100">
           <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" v-model="form.is_public" class="sr-only peer">
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            <span class="ml-3 text-sm font-medium text-gray-700">{{ $t('public_access') }}</span>
          </label>
          <p class="text-[11px] text-gray-400">{{ $t('handbook_public_hint') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import axios from 'axios'
import MarkdownIt from 'markdown-it'
import { getHandbookById, createHandbook, updateHandbook, getHandbookExpressions } from '../services/handbookService'

export default {
  name: 'HandbookEdit',
  props: ['id'],
  setup(props) {
    const router = useRouter()
    const { t } = useI18n()
    const md = new MarkdownIt({ html: true })
    
    const isEditing = computed(() => !!props.id)
    const saving = ref(false)
    const previewMode = ref(false)
    const previewLoading = ref(false)
    const contentArea = ref(null)
    
    // Available languages for selectors
    const languages = ref([])

    const form = reactive({
      title: '',
      description: '',
      content: '',
      source_lang: '',
      target_lang: '',
      is_public: false
    })

    // Translated expressions cache for preview { mid: Expression }
    const translationCache = ref({})
    // Rendered HTML after fetching translations
    const renderedContent = ref('')

    // History for Undo/Redo
    const history = ref([])
    const historyIndex = ref(-1)
    
    const saveToHistory = () => {
      if (historyIndex.value < history.value.length - 1) {
        history.value.splice(historyIndex.value + 1)
      }
      if (history.value.length >= 50) {
        history.value.shift()
      } else {
        historyIndex.value++
      }
      history.value.push(JSON.stringify(form))
    }

    const undo = () => {
      if (historyIndex.value > 0) {
        historyIndex.value--
        const state = JSON.parse(history.value[historyIndex.value])
        Object.assign(form, state)
      }
    }

    const redo = () => {
      if (historyIndex.value < history.value.length - 1) {
        historyIndex.value++
        const state = JSON.parse(history.value[historyIndex.value])
        Object.assign(form, state)
      }
    }

    // Search state
    const searchQuery = ref('')
    const searchResults = ref([])
    const searching = ref(false)
    let searchTimeout = null

    // Expression Tag Regex
    const TAG_REGEX = /\{\{exp:(\d+)\|mid:(\d+)\|text:([^|]+)\|audio:([^}]*)\}\}/g

    const fetchLanguages = async () => {
      try {
        const response = await axios.get('/api/v1/languages', { params: { is_active: 1 } })
        languages.value = response.data || []
      } catch (error) {
        console.error('Failed to fetch languages:', error)
      }
    }

    const fetchHandbook = async () => {
      if (!props.id) return
      try {
        const data = await getHandbookById(props.id)
        if (data) {
          form.title = data.title
          form.description = data.description || ''
          form.content = data.content
          form.source_lang = data.source_lang || ''
          form.target_lang = data.target_lang || ''
          form.is_public = !!data.is_public
          saveToHistory()
        }
      } catch (error) {
        console.error('Failed to fetch handbook:', error)
        router.push('/handbooks')
      }
    }

    const search = () => {
      if (searchTimeout) clearTimeout(searchTimeout)
      if (!searchQuery.value.trim()) {
        searchResults.value = []
        return
      }

      searchTimeout = setTimeout(async () => {
        searching.value = true
        try {
          const params = { q: searchQuery.value, limit: 10 }
          // Filter by source_lang if set
          if (form.source_lang) {
            params.from_lang = form.source_lang
          }
          const response = await axios.get('/api/v1/search', { params })
          searchResults.value = response.data
        } catch (error) {
          console.error('Search error:', error)
        } finally {
          searching.value = false
        }
      }, 500)
    }

    const insertExpression = (expr) => {
      const syntax = `{{exp:${expr.id}|mid:${expr.meaning_id || expr.id}|text:${expr.text}|audio:${expr.audio_url || ''}}}`
      
      const el = contentArea.value
      if (!el) {
        form.content += syntax
        return
      }

      const start = el.selectionStart
      const end = el.selectionEnd
      const text = form.content
      form.content = text.substring(0, start) + syntax + text.substring(end)
      saveToHistory()
      
      setTimeout(() => {
        el.focus()
        const newPos = start + syntax.length
        el.setSelectionRange(newPos, newPos)
      }, 0)
    }

    const applyStyle = (prefix, suffix = '') => {
      const el = contentArea.value
      if (!el) return

      const start = el.selectionStart
      const end = el.selectionEnd
      const selectedText = form.content.substring(start, end)
      const replacement = prefix + selectedText + suffix
      
      form.content = form.content.substring(0, start) + replacement + form.content.substring(end)
      saveToHistory()
      
      setTimeout(() => {
        el.focus()
        const newStart = start + prefix.length
        const newEnd = newStart + selectedText.length
        el.setSelectionRange(newStart, newEnd)
      }, 0)
    }

    const insertAndClear = (expr) => {
      insertExpression(expr)
      searchQuery.value = ''
      searchResults.value = []
    }

    // Parse all mid values from content
    const extractMeaningIds = (content) => {
      const ids = []
      const regex = /\{\{exp:\d+\|mid:(\d+)\|/g
      let match
      while ((match = regex.exec(content)) !== null) {
        const mid = parseInt(match[1])
        if (!ids.includes(mid)) ids.push(mid)
      }
      return ids
    }

    // Build preview HTML using cached translations
    const buildRenderedContent = (expressionMap) => {
      let html = md.render(form.content)

      window.playHandbookAudio = (url) => {
        if (!url) return
        const audio = new Audio(url)
        audio.play()
      }

      return html.replace(TAG_REGEX, (match, exp, mid, originalText, originalAudio) => {
        const translated = expressionMap[parseInt(mid)]
        
        if (translated) {
          // Show original text with a bracketed translation annotation
          const audioUrl = translated.audio_url 
            ? (JSON.parse(translated.audio_url)?.[0]?.url || '') 
            : (originalAudio || '')
          const translatedText = translated.text
          
          return `
            <span class="inline-flex items-center gap-1 px-1.5 py-0.5 bg-blue-50 text-blue-600 border border-blue-200 rounded text-sm font-bold cursor-pointer hover:bg-blue-100" 
                  onclick="event.stopPropagation(); window.playHandbookAudio('${audioUrl}')">
              ${originalText}
              <span class="text-gray-400 font-normal text-xs">[${translatedText}]</span>
              <span class="text-[10px]">🔊</span>
            </span>
          `
        } else {
          // Fallback: show original text without translation
          return `
            <span class="inline-flex items-center gap-1 px-1.5 py-0.5 bg-blue-50 text-blue-600 border border-blue-200 rounded text-sm font-bold cursor-pointer hover:bg-blue-100" 
                  onclick="event.stopPropagation(); window.playHandbookAudio('${originalAudio}')">
              ${originalText}
              <span class="text-[10px]">🔊</span>
            </span>
          `
        }
      })
    }

    // Switch to preview: fetch translations if target_lang is set
    const switchToPreview = async () => {
      previewMode.value = true

      if (!form.target_lang) {
        // No target lang, just render without translations
        renderedContent.value = buildRenderedContent({})
        return
      }

      const meaningIds = extractMeaningIds(form.content)
      if (meaningIds.length === 0) {
        renderedContent.value = buildRenderedContent({})
        return
      }

      // Find which IDs we haven't cached yet
      const uncachedIds = meaningIds.filter(id => !(id in translationCache.value))

      if (uncachedIds.length > 0) {
        previewLoading.value = true
        try {
          const expressions = await getHandbookExpressions(form.target_lang, uncachedIds)
          // Map by meaning_id for easy lookup
          expressions.forEach(expr => {
            if (expr.meaning_id) {
              translationCache.value[expr.meaning_id] = expr
            }
          })
          // Mark fetched but missing as null
          uncachedIds.forEach(id => {
            if (!(id in translationCache.value)) {
              translationCache.value[id] = null
            }
          })
        } catch (error) {
          console.error('Failed to fetch translations for preview:', error)
        } finally {
          previewLoading.value = false
        }
      }

      renderedContent.value = buildRenderedContent(translationCache.value)
    }

    const save = async () => {
      if (!form.title.trim()) {
        alert(t('handbook_title_required') || 'Title is required')
        return
      }
      if (!form.content.trim()) {
        alert(t('handbook_content_required') || 'Content is required')
        return
      }

      saving.value = true
      try {
        const payload = {
          title: form.title,
          description: form.description,
          content: form.content,
          source_lang: form.source_lang || null,
          target_lang: form.target_lang || null,
          is_public: form.is_public
        }
        if (isEditing.value) {
          await updateHandbook(props.id, payload)
        } else {
          await createHandbook(payload)
        }
        router.push('/handbooks')
      } catch (error) {
        console.error('Failed to save handbook:', error)
        alert(t('handbook_save_failed') || 'Failed to save handbook')
      } finally {
        saving.value = false
      }
    }

    const goBack = () => {
      router.back()
    }

    onMounted(() => {
      fetchLanguages()
      fetchHandbook()
    })

    return {
      isEditing,
      saving,
      previewMode,
      previewLoading,
      form,
      languages,
      searchQuery,
      searchResults,
      searching,
      history,
      historyIndex,
      contentArea,
      renderedContent,
      search,
      insertExpression,
      insertAndClear,
      applyStyle,
      undo,
      redo,
      switchToPreview,
      save,
      goBack
    }
  }
}
</script>

<style scoped>
.markdown-body {
  font-size: 15px;
  line-height: 1.6;
}

:deep(.markdown-body h1) { font-size: 1.875rem; font-weight: 800; margin-top: 1.5rem; margin-bottom: 1rem; border-bottom: 1px solid #e5e7eb; padding-bottom: 0.5rem; }
:deep(.markdown-body h2) { font-size: 1.5rem; font-weight: 700; margin-top: 1.5rem; margin-bottom: 0.75rem; }
:deep(.markdown-body h3) { font-size: 1.25rem; font-weight: 600; margin-top: 1.25rem; margin-bottom: 0.5rem; }
:deep(.markdown-body p) { margin-bottom: 1rem; }
:deep(.markdown-body ul) { list-style-type: disc; padding-left: 1.5rem; margin-bottom: 1rem; }
:deep(.markdown-body ol) { list-style-type: decimal; padding-left: 1.5rem; margin-bottom: 1rem; }
:deep(.markdown-body code) { background-color: #f3f4f6; padding: 0.2rem 0.4rem; border-radius: 0.25rem; font-size: 0.875em; }
:deep(.markdown-body blockquote) { border-left: 4px solid #e5e7eb; padding-left: 1rem; color: #6b7280; font-style: italic; }

.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #E5E7EB;
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #D1D5DB;
}
</style>
