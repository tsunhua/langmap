<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 mb-6">
      <div>
        <h1 class="text-xl sm:text-2xl font-bold text-gray-900">
          {{ isEditing ? $t('edit_handbook') : $t('handbook_new') }}
        </h1>
      </div>
      <div class="flex items-center gap-2 w-full sm:w-auto">
        <button @click="goBack"
          class="flex-1 sm:flex-none px-4 py-2 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-gray-600 min-h-[44px] cursor-pointer">
          {{ $t('cancel') }}
        </button>
        <button @click="save" :disabled="saving"
          class="flex-1 sm:flex-none px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors font-medium shadow-sm min-h-[44px] cursor-pointer">
          {{ saving ? $t('saving') : $t('save') }}
        </button>
      </div>
    </div>

    <div v-if="hasDraft" class="mb-4 p-4 bg-yellow-50 border border-yellow-200 rounded-xl flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div class="flex items-center gap-3">
        <span class="text-xl">📝</span>
        <div>
          <p class="text-sm font-medium text-yellow-800">{{ $t('draft_found') }}</p>
          <p class="text-xs text-yellow-600">{{ $t('draft_found_hint') }}</p>
        </div>
      </div>
      <div class="flex items-center gap-2 w-full sm:w-auto">
        <button @click="clearDraft" class="flex-1 sm:flex-none px-3 py-2 text-xs text-yellow-700 hover:text-yellow-800 font-medium min-h-[44px] cursor-pointer">
          {{ $t('discard_draft') }}
        </button>
        <button @click="restoreDraft" class="flex-1 sm:flex-none px-4 py-2 text-xs bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 font-medium transition-colors min-h-[44px] cursor-pointer">
          {{ $t('restore_draft') }}
        </button>
      </div>
    </div>

    <div class="max-w-7xl mx-auto space-y-5">
      <div class="bg-white p-5 rounded-2xl shadow-sm border border-gray-200">
        <!-- Title, Description & Language Settings -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-5 mb-4">
          <!-- Left: Title & Description -->
          <div class="space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-700 mb-1.5">
                <span class="text-red-500">*</span> {{ $t('title_label') }}
              </label>
              <input v-model="form.title" type="text"
                class="w-full text-base font-medium border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-2.5 px-3 min-h-[44px]"
                :placeholder="$t('handbook_title_placeholder')" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-700 mb-1.5">{{ $t('description') }}</label>
              <textarea v-model="form.description" rows="2"
                class="w-full border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-2 px-3 text-sm min-h-[44px]"
                ></textarea>
            </div>
          </div>

          <!-- Right: Language Selectors -->
          <div class="space-y-4">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1.5">
                <span class="text-red-500">*</span> {{ $t('content_lang') }}
              </label>
              <select v-model="form.source_lang"
                class="w-full text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-2.5 px-2.5 bg-white min-h-[44px] cursor-pointer">
                <option value="" disabled>{{ $t('select_language') }}</option>
                <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                  {{ lang.name }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1.5">
                <span class="text-red-500">*</span> {{ $t('instruction_lang') }}
              </label>
              <select v-model="form.target_lang"
                class="w-full text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-2.5 px-2.5 bg-white min-h-[44px] cursor-pointer">
                <option value="" disabled>{{ $t('select_language') }}</option>
                <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                  {{ lang.name }}
                </option>
              </select>
            </div>
          </div>
        </div>

        <!-- Content Editor -->
        <div class="mb-6">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            <span class="text-red-500">*</span> {{ $t('handbook_content_label') }}
          </label>

          <div :class="['grid gap-4', showPreview ? 'grid-cols-1 lg:grid-cols-2' : 'grid-cols-1']">
            <!-- Left Column: Editor -->
            <div>
              <!-- Toolbar -->
              <div class="flex flex-wrap items-center gap-1.5 mb-2 p-1.5 bg-gray-50 border border-gray-200 rounded-xl">
                <button @click="undo" :disabled="historyIndex <= 0"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm hover:bg-white rounded transition-colors disabled:opacity-30 cursor-pointer"
                  :title="$t('undo')">↩️</button>
                <button @click="redo" :disabled="historyIndex >= history.length - 1"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm hover:bg-white rounded transition-colors disabled:opacity-30 cursor-pointer"
                  :title="$t('redo')">↪️</button>
                <div class="h-4 w-px bg-gray-300 mx-1"></div>
                <button @click="applyStyle('**', '**')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm font-bold hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('bold')">B</button>
                <button @click="applyStyle('*', '*')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm italic hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('italic')">I</button>
                <button @click="applyStyle('<u>', '</u>')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm underline hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('underline')">U</button>
                <button @click="applyStyle('~~', '~~')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm line-through hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('strikethrough')">S</button>
                <div class="h-4 w-px bg-gray-300 mx-1"></div>
                <button @click="applyStyle('# ')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-xs font-bold hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('heading') + ' 1'">H1</button>
                <button @click="applyStyle('## ')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-xs font-bold hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('heading') + ' 2'">H2</button>
                <button @click="applyStyle('### ')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-xs font-bold hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('heading') + ' 3'">H3</button>
                <div class="h-4 w-px bg-gray-300 mx-1"></div>
                <button @click="applyStyle('- ')" class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('bullet_list')">•</button>
                <button @click="applyStyle('1. ')" class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('numbered_list')">1.</button>
                <button @click="applyStyle('> ')" class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('quote')">"</button>
                <button @click="applyStyle('`', '`')"
                  class="min-w-[36px] min-h-[36px] px-2 py-1 text-sm font-mono hover:bg-white rounded transition-colors cursor-pointer"
                  :title="$t('code')">&lt;/&gt;</button>
                <div class="flex-grow"></div>
                <!-- Preview Toggle -->
                <button @click="showPreview = !showPreview"
                  :class="['min-h-[36px] px-2.5 py-1 text-xs font-medium rounded transition-colors flex items-center gap-1 cursor-pointer', showPreview ? 'bg-blue-100 text-blue-700' : 'text-gray-500 hover:bg-gray-100']"
                  :title="showPreview ? $t('hide_preview') : $t('show_preview')">
                  <svg xmlns="http://www.w3.org/2000/svg" class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </button>
              </div>

              <!-- Expression Search -->
              <div class="relative mb-2">
                <input v-model="searchQuery" type="text"
                  class="w-full pl-8 pr-3 py-2.5 sm:py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs focus:ring-1 focus:ring-blue-500 outline-none focus:bg-white min-h-[44px]"
                  :placeholder="form.source_lang ? `🔍 ${$t('search_in_lang', { lang: form.source_lang })}` : ('🔍 ' + $t('insert_expression'))"
                  @input="search" />

                <!-- Search Results Dropdown -->
                <div v-if="searchQuery && (searchResults.length > 0 || searching)"
                  class="absolute z-50 top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-xl shadow-xl max-h-64 overflow-y-auto custom-scrollbar">
                  <div v-if="searching" class="p-4 text-center">
                    <div
                      class="animate-spin inline-block w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full">
                    </div>
                  </div>
                  <div v-else>
                    <div v-for="expr in searchResults" :key="expr.id"
                      class="p-2 sm:p-2.5 border-b border-gray-50 last:border-none hover:bg-blue-50 cursor-pointer transition-colors min-h-[44px] flex items-center"
                      @click="insertAndClear(expr)">
                      <div class="flex justify-between items-center w-full">
                        <span class="font-bold text-sm text-gray-800">{{ expr.text }}</span>
                        <span class="text-[10px] bg-blue-100 text-blue-600 px-1.5 py-0.5 rounded font-bold uppercase">{{
                          expr.language_code }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="relative group">
                <textarea ref="contentArea" v-model="form.content" rows="12 sm:rows-15 lg:rows-18"
                  class="w-full font-mono text-sm border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 p-3 sm:p-4 transition-all"
                  ></textarea>
                <div
                  class="absolute bottom-3 sm:bottom-4 right-3 sm:right-4 text-[10px] text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity">
                  {{ $t('markdown') }}
                </div>
              </div>
            </div>

            <!-- Right Column: Preview -->
            <div v-if="showPreview" class="bg-white rounded-xl p-4 sm:p-6 shadow-sm border border-gray-200">
              <div class="flex items-center gap-2 mb-4 pb-3 border-b border-gray-100">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-gray-500" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round"
                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                <h3 class="text-sm font-semibold text-gray-700">{{ $t('preview') }}</h3>
                <span v-if="previewLoading"
                  class="ml-auto inline-block w-3 h-3 border border-blue-500 border-t-transparent rounded-full animate-spin"></span>
              </div>

              <div v-if="previewLoading" class="min-h-[150px] flex items-center justify-center">
                <div class="text-center text-gray-500">
                  <div
                    class="animate-spin inline-block w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full mb-2">
                  </div>
                  <p class="text-xs">{{ $t('loading_preview') }}</p>
                </div>
              </div>
              <div v-else>
                <!-- Rendered Header in Preview -->
                <div class="flex flex-col gap-4 pb-6 border-b border-gray-100">
                  <div class="space-y-1.5 flex-1">
                    <h1 class="text-xl sm:text-2xl font-bold text-gray-800" v-html="renderedTitle"></h1>
                    <p v-if="renderedDescription" class="text-sm text-gray-500 max-w-2xl leading-relaxed" v-html="renderedDescription"></p>
                  </div>
                </div>

                <div class="prose prose-blue prose-headings:text-gray-800 prose-p:text-gray-600 prose-strong:text-gray-700 max-w-none leading-loose py-6 markdown-body prose-sm sm:prose-base"
                  v-html="renderedContent"></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Public Toggle -->
        <div class="flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-6 p-4 bg-gray-50 rounded-xl border border-gray-100">
          <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" v-model="form.is_public" class="sr-only peer">
            <div
              class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600">
            </div>
            <span class="ml-3 text-sm font-medium text-gray-700">{{ $t('public_access') }}</span>
          </label>
          <p class="text-[11px] text-gray-400">{{ $t('public_hint') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, onMounted, onBeforeUnmount, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import axios from 'axios'
import MarkdownIt from 'markdown-it'
import { getHandbookById, createHandbook, updateHandbook, stableExpressionId, getExpressionsByIds, getHandbookExpressions } from '../services/handbookService'

export default {
  name: 'HandbookEdit',
  props: ['id'],
  setup(props) {
    const router = useRouter()
    const { t } = useI18n()
    const md = new MarkdownIt({ html: true })

    const isEditing = computed(() => !!props.id)
    const saving = ref(false)
    const showPreview = ref(true)
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

    const storageKey = computed(() => props.id ? `handbook_draft_${props.id}` : 'handbook_draft_new')
    const hasDraft = ref(false)
    // Rendered HTML after fetching translations
    const renderedContent = ref('')
    const renderedTitle = ref('')
    const renderedDescription = ref('')

    // Translated expressions cache for preview { mid: Expression }
    const translationCache = ref({})
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

    // Expression Tag Regex - supports both {{text:xxx|lang:xxx}} and {{xxx}} formats
    const TEXT_LANG_REGEX = /\{\{(?:text:)?([^|}]+)(?:\|lang:([^}]+))?\}\}/g

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

    const checkDraft = () => {
      const draft = localStorage.getItem(storageKey.value)
      if (draft) {
        hasDraft.value = true
        // For new handbooks, restore automatically
        if (!props.id) {
          restoreDraft()
        }
      }
    }

    const restoreDraft = () => {
      const draft = localStorage.getItem(storageKey.value)
      if (draft) {
        try {
          const draftData = JSON.parse(draft)
          Object.assign(form, draftData)
          hasDraft.value = false
          saveToHistory()
        } catch (e) {
          console.error('Failed to parse draft:', e)
        }
      }
    }

    const clearDraft = () => {
      localStorage.removeItem(storageKey.value)
      hasDraft.value = false
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
      const syntax = `{{text:${expr.text}|lang:${expr.language_code}}}`

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

    // Parse all metadata required for preview from content
    const extractRequiredMetadata = async (content, title = '', description = '', sourceLang = '') => {
      const expressionsToFetch = [] // { id, text, lang }
      const fullText = `${title}\n${description}\n${content}`

      let tlMatch
      while ((tlMatch = TEXT_LANG_REGEX.exec(fullText)) !== null) {
        const text = tlMatch[1]
        const lang = tlMatch[2] || sourceLang
        const id = stableExpressionId(text, lang)
        if (!expressionsToFetch.some(e => e.id === id)) {
          expressionsToFetch.push({ id, text, lang })
        }
      }

      return { expressionsToFetch }
    }
    // Store expression data for event handling
    const expressionClickHandlers = ref(new Map())

    // Render helpers for preview
    const renderItem = (id, text, meanings, audioUrl, isTitle = false) => {
      const meaningsText = meanings && meanings.length > 0
        ? (isTitle
          ? `<div class="handbook-meaning-title">[${meanings.map(m => m.text).join('] [')}]</div>`
          : ` <span class="handbook-meaning-content">[${meanings.map(m => m.text).join(', ')}]</span>`)
        : ''
      const audioIcon = audioUrl ? ` <span class="handbook-audio-icon">🔊</span>` : ''

      // Store click handler data
      const key = `expr-${id}`
      expressionClickHandlers.value.set(key, { id, audioUrl })

      return `
        <span class="handbook-item" data-type="${isTitle ? 'title' : 'content'}" data-key="${key}">
          ${text}${meaningsText}${audioIcon}
        </span>
      `
    }

    // Handle click on rendered expressions
    const handleExpressionClick = (event) => {
      const target = event.target.closest('.handbook-item')
      if (!target) return

      const key = target.dataset.key
      const handler = expressionClickHandlers.value.get(key)
      if (!handler) return

      event.stopPropagation()

      if (handler.audioUrl) {
        const audio = new Audio(handler.audioUrl)
        audio.play()
      }

      router.push(`/detail/${handler.id}`)
    }

    // Build preview HTML using cached translations
    const buildRenderedContent = (content, expressionMap, sourceLang = '') => {
      if (!content) return ''
      let html = md.render(content)

      // Replace tags with rendered items
      html = html.replace(TEXT_LANG_REGEX, (match, text, lang) => {
        const actualLang = lang || sourceLang
        const id = stableExpressionId(text, actualLang)
        const expr = expressionMap[id]
        if (expr) {
          // Collect all translations for these meanings in the target language
          const translations = []
          expr.meanings?.forEach(m => {
            if (expressionMap[`trans_${m.id}`]) {
              translations.push(expressionMap[`trans_${m.id}`])
            }
          })

          const audioUrl = expr.audio_url ? (JSON.parse(expr.audio_url)?.[0]?.url || '') : ''
          return renderItem(id, text, translations, audioUrl)
        }
        return `<span class="handbook-item-undefined">${text}</span>`
      })

      return html
    }

    const renderPlainTextTags = (text, expressionMap, isTitle = false, sourceLang = '') => {
      if (!text) return ''
      return text.replace(TEXT_LANG_REGEX, (match, term, lang) => {
        const actualLang = lang || sourceLang
        const id = stableExpressionId(term, actualLang)
        const expr = expressionMap[id]
        if (expr) {
          const translations = []
          expr.meanings?.forEach(m => {
            if (expressionMap[`trans_${m.id}`]) {
              translations.push(expressionMap[`trans_${m.id}`])
            }
          })
          const audioUrl = expr.audio_url ? (JSON.parse(expr.audio_url)?.[0]?.url || '') : ''
          return renderItem(id, term, translations, audioUrl, isTitle)
        }
        return `<span class="handbook-item-undefined">${term}</span>`
      })
    }

    // Update preview: fetch translations if target_lang is set
    const updatePreview = async () => {
      if (!showPreview.value) return

      const { expressionsToFetch } = await extractRequiredMetadata(form.content, form.title, form.description, form.source_lang)

      if (expressionsToFetch.length === 0) {
        renderedContent.value = buildRenderedContent(form.content, {}, form.source_lang)
        renderedTitle.value = renderPlainTextTags(form.title || '', {}, true, form.source_lang)
        renderedDescription.value = renderPlainTextTags(form.description || '', {}, false, form.source_lang)
        return
      }

      const uncachedExprs = expressionsToFetch.filter(e => !(e.id in translationCache.value))

      if (uncachedExprs.length > 0) {
        previewLoading.value = true
        try {
          // Phase 1: Batch fetch all source expressions to get their meanings
          const expressions = await getExpressionsByIds(uncachedExprs.map(e => e.id))
          expressions.forEach(expr => {
            translationCache.value[expr.id] = expr
          })

          // Mark expressions that weren't found
          uncachedExprs.forEach(e => {
            if (!(e.id in translationCache.value)) {
              translationCache.value[e.id] = null
            }
          })
        } catch (error) {
          console.error('Failed to fetch expressions:', error)
        } finally {
          previewLoading.value = false
        }
      }

      // Phase 2: Resolve translations for all collected meanings in target_lang
      const allMids = []
      expressionsToFetch.forEach(e => {
        const expr = translationCache.value[e.id]
        expr?.meanings?.forEach(m => {
          if (!allMids.includes(m.id)) allMids.push(m.id)
        })
      })

      const uncachedMids = allMids.filter(mid => !(`trans_${mid}` in translationCache.value))

      if (uncachedMids.length > 0 && form.target_lang) {
        previewLoading.value = true
        try {
          const translations = await getHandbookExpressions(form.target_lang, uncachedMids)
          console.log('Fetched translations:', { targetLang: form.target_lang, uncachedMids, translations })
          // Map mid to the translated expression
          translations.forEach(trans => {
            // Check if this translation belongs to one of our target meanings
            // The getHandbookExpressions likely returns expressions that HAVE these meanings
            // We need to store it so we can find it by mid
            if (trans.meaning_id) {
              translationCache.value[`trans_${trans.meaning_id}`] = trans
            } else if (trans.meanings) {
              trans.meanings.forEach(m => {
                if (uncachedMids.includes(m.id)) {
                  translationCache.value[`trans_${m.id}`] = trans
                }
              })
            }
          })

          // Mark tried but not found
          uncachedMids.forEach(mid => {
            if (!(`trans_${mid}` in translationCache.value)) {
              translationCache.value[`trans_${mid}`] = null
            }
          })
        } catch (error) {
          console.error('Failed to fetch translations:', error)
        } finally {
          previewLoading.value = false
        }
      }

      renderedContent.value = buildRenderedContent(form.content, translationCache.value, form.source_lang)
      renderedTitle.value = renderPlainTextTags(form.title, translationCache.value, true, form.source_lang)
      renderedDescription.value = renderPlainTextTags(form.description, translationCache.value, false, form.source_lang)

      console.log('Preview update:', {
        targetLang: form.target_lang,
        translationCacheKeys: Object.keys(translationCache.value),
        expressionsToFetchCount: expressionsToFetch.length
      })
    }

    let previewTimeout = null
    // Watch for content and target_lang changes to update preview
    watch([() => form.content, () => form.target_lang, showPreview], () => {
      if (previewTimeout) clearTimeout(previewTimeout)
      previewTimeout = setTimeout(() => {
        updatePreview()
      }, 300)
    })

    // Auto-save watch
    let autoSaveTimeout = null
    watch(form, (newVal) => {
      if (autoSaveTimeout) clearTimeout(autoSaveTimeout)
      autoSaveTimeout = setTimeout(() => {
        localStorage.setItem(storageKey.value, JSON.stringify(newVal))
      }, 1000)
    }, { deep: true })

    const save = async () => {
      if (!form.title.trim()) {
        alert(t('title_required'))
        return
      }
      if (!form.content.trim()) {
        alert(t('content_required'))
        return
      }
      if (!form.source_lang) {
        alert(t('content_lang_required'))
        return
      }
      if (!form.target_lang) {
        alert(t('instruction_lang_required'))
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
        clearDraft()
        router.push('/handbooks')
      } catch (error) {
        console.error('Failed to save handbook:', error)
        alert(t('handbook_save_failed'))
      } finally {
        saving.value = false
      }
    }

    const goBack = () => {
      router.back()
    }

    onMounted(async () => {
      fetchLanguages()
      await fetchHandbook()
      checkDraft()
      updatePreview()

      // Add global click handler for expression items
      document.addEventListener('click', handleExpressionClick)
    })

    onBeforeUnmount(() => {
      document.removeEventListener('click', handleExpressionClick)
    })

    return {
      isEditing,
      saving,
      showPreview,
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
      renderedTitle,
      renderedDescription,
      search,
      insertExpression,
      insertAndClear,
      applyStyle,
      undo,
      redo,
      save,
      goBack,
      hasDraft,
      restoreDraft,
      clearDraft
    }
  }
}
</script>

<style scoped>
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
