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
              <select v-model="form.content_lang"
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
              <div class="flex items-center gap-2">
                <div class="flex flex-wrap gap-1.5 items-center relative">
                  <span 
                    v-for="lang in selectedInstructionLanguages" 
                    :key="lang.code"
                    class="language-tag"
                    :style="{ '--lang-color': getLanguageColor(lang) }"
                    @click="openColorPicker(lang.code)"
                    :title="$t('customize_color')"
                  >
                    <span class="language-dot"></span>
                    {{ lang.name }}
                    <span class="language-remove" @click.stop="removeInstructionLanguage(lang.code)" :title="$t('remove_language')">×</span>
                  </span>
                  
                  <button 
                    class="language-add"
                    @click="showInstructionLanguageSelector = !showInstructionLanguageSelector"
                    :title="$t('add_language')"
                  >
                    +
                  </button>
                  
                  <div v-if="showInstructionLanguageSelector" class="language-selector-dropdown">
                    <div 
                      v-for="lang in availableInstructionLanguages" 
                      :key="lang.code"
                      class="language-option"
                      :style="{ '--lang-color': getLanguageColor(lang) }"
                      @click="addInstructionLanguage(lang)"
                    >
                      <span class="language-dot"></span>
                      {{ lang.name }}
                    </div>
                  </div>
                </div>
                
                <!-- Color Picker Modal -->
                <div v-if="showColorPicker" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center" @click="closeColorPicker">
                  <div class="bg-white p-6 rounded-xl shadow-xl max-w-sm w-full mx-4" @click.stop>
                    <h3 class="text-lg font-semibold mb-4">{{ $t('customize_color') }}</h3>
                    <p class="text-sm text-gray-600 mb-3">{{ selectedLanguageForColor?.name }}</p>
                    <div class="flex items-center gap-4 mb-4">
                      <input 
                        type="color" 
                        v-model="tempColor"
                        class="w-16 h-16 cursor-pointer border-0 rounded-lg"
                      />
                      <div class="flex-1">
                        <input 
                          type="text" 
                          v-model="tempColor"
                          class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm uppercase"
                          maxlength="7"
                        />
                        <p class="text-xs text-gray-400 mt-1">{{ $t('color_hex_format') }}</p>
                      </div>
                    </div>
                    <div class="flex justify-end gap-2">
                      <button 
                        @click="resetColorToDefault"
                        class="px-4 py-2 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
                      >
                        {{ $t('reset_to_default') }}
                      </button>
                      <button 
                        @click="saveColor"
                        class="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        {{ $t('save') }}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
              <input v-model="form.instruction_lang_prefix" type="text"
                class="mt-2 w-full text-xs border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-2 px-2 min-h-[44px]"
                :placeholder="$t('lang_code_prefix')" />
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
              <!-- Expression Search with Preview Toggle -->
              <div class="flex gap-2 mb-2">
                <div class="relative flex-1">
                  <input v-model="searchQuery" type="text"
                    class="w-full pl-8 pr-3 py-2.5 sm:py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs focus:ring-1 focus:ring-blue-500 outline-none focus:bg-white min-h-[44px]"
                    :placeholder="form.content_lang ? `🔍 ${$t('search_in_lang', { lang: form.content_lang })}` : ('🔍 ' + $t('insert_expression'))"
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
                <button @click="showPreview = !showPreview"
                  :class="['min-h-[44px] px-3 py-1 text-xs font-medium rounded-lg transition-colors flex items-center gap-1 cursor-pointer border shrink-0', showPreview ? 'bg-blue-50 text-blue-700 border-blue-200' : 'text-gray-500 hover:bg-gray-50 border-gray-200']"
                  :title="showPreview ? $t('hide_preview') : $t('show_preview')">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
                    <path v-if="showPreview" stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
                    <path v-else stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                    <path v-if="!showPreview" stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  <span class="hidden sm:inline">{{ showPreview ? $t('hide_preview') : $t('show_preview') }}</span>
                </button>
              </div>

              <MdEditor
                ref="mdEditorRef"
                v-model="form.content"
                :preview="false"
                :htmlPreview="false"
                :noUploadImg="true"
                :toolbarsExclude="['preview', 'htmlPreview', 'mermaid', 'katex', 'github']"
                placeholder="Write your content here. Use {{word}}, {{text:word|lang:en-US}} or {{text:word|mid:123}} to insert expressions."
                class="border border-gray-200 rounded-xl overflow-hidden"
                :style="{ height: showPreview ? '700px' : '760px' }"
              />
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
import { useRouter, onBeforeRouteLeave } from 'vue-router'
import { useI18n } from 'vue-i18n'
import axios from 'axios'
import MarkdownIt from 'markdown-it'
import { MdEditor } from 'md-editor-v3'
import 'md-editor-v3/lib/style.css'
import { getHandbookById, createHandbook, updateHandbook, stableExpressionId, getExpressionsByIds, getHandbookExpressions } from '../services/handbookService'
import { generateLanguageColor } from '../utils/languageUtils'

export default {
  name: 'HandbookEdit',
  components: { MdEditor },
  props: ['id'],
  setup(props) {
    const router = useRouter()
    const { t } = useI18n()
    const md = new MarkdownIt({
      html: true,
      breaks: true,
      linkify: false
    })

    const isEditing = computed(() => !!props.id)
    const saving = ref(false)
    const showPreview = ref(true)
    const previewLoading = ref(false)
    const mdEditorRef = ref(null)

    // Available languages for selectors
    const languages = ref([])

    const form = reactive({
      title: '',
      description: '',
      content: '',
      content_lang: '',
      instruction_langs: [],
      is_public: false,
      instruction_lang_prefix: '',
      lang_colors: {}
    })

    const storageKey = computed(() => props.id ? `handbook_draft_${props.id}` : 'handbook_draft_new')
    const hasDraft = ref(false)
    const isInitializing = ref(true)
    const baselineJson = ref('')

    const DRAFT_VERSION = 1

    const snapshotForm = () => ({
      title: form.title,
      description: form.description,
      content: form.content,
      content_lang: form.content_lang,
      instruction_langs: Array.isArray(form.instruction_langs) ? [...form.instruction_langs] : [],
      is_public: !!form.is_public,
      instruction_lang_prefix: form.instruction_lang_prefix,
      lang_colors: form.lang_colors && typeof form.lang_colors === 'object' ? form.lang_colors : {}
    })

    const snapshotJson = () => JSON.stringify(snapshotForm())

    const readDraftData = () => {
      const raw = localStorage.getItem(storageKey.value)
      if (!raw) return null
      try {
        const parsed = JSON.parse(raw)
        if (parsed && typeof parsed === 'object' && parsed.data && parsed.__meta) {
          return parsed.data
        }
        // Backward compatibility: old format stored the form object directly
        return parsed
      } catch (e) {
        console.error('Failed to parse draft:', e)
        return null
      }
    }

    const writeDraftData = (data) => {
      const payload = {
        __meta: {
          version: DRAFT_VERSION,
          savedAt: Date.now(),
          handbookId: props.id || null
        },
        data
      }
      localStorage.setItem(storageKey.value, JSON.stringify(payload))
    }

    const showInstructionLanguageSelector = ref(false)
    
    // Color picker state
    const showColorPicker = ref(false)
    const selectedLanguageForColor = ref(null)
    const tempColor = ref('#000000')

    const availableInstructionLanguages = computed(() => {
      let result = languages.value.filter(lang => 
        lang.code !== form.content_lang &&
        !form.instruction_langs.includes(lang.code)
      )

      if (form.instruction_lang_prefix) {
        const prefixes = form.instruction_lang_prefix.split(',').map(p => p.trim()).filter(p => p)
        result = result.filter(lang => prefixes.some(prefix => lang.code.startsWith(prefix)))
      }

      return result.sort((a, b) => a.name.localeCompare(b.name))
    })

    const selectedInstructionLanguages = computed(() => {
      return languages.value.filter(lang => 
        form.instruction_langs.includes(lang.code)
      )
    })
    const getLanguageColor = (lang) => {
      if (form.lang_colors && form.lang_colors[lang.code]) {
        return form.lang_colors[lang.code]
      }
      return generateLanguageColor(lang.code)
    }

    const addInstructionLanguage = (lang) => {
      if (!form.instruction_langs.includes(lang.code) && form.instruction_langs.length < 5) {
        form.instruction_langs.push(lang.code)
        updatePreview()
      }
      showInstructionLanguageSelector.value = false
    }

    const removeInstructionLanguage = (langCode) => {
      if (form.instruction_langs.length > 1) {
        form.instruction_langs = form.instruction_langs.filter(code => code !== langCode)
        updatePreview()
      }
    }
    
    const openColorPicker = (langCode) => {
      selectedLanguageForColor.value = languages.value.find(l => l.code === langCode)
      tempColor.value = form.lang_colors[langCode] || generateLanguageColor(langCode)
      showColorPicker.value = true
    }
    
    const closeColorPicker = () => {
      showColorPicker.value = false
      selectedLanguageForColor.value = null
      tempColor.value = '#000000'
    }
    
    const saveColor = () => {
      if (selectedLanguageForColor.value && tempColor.value) {
        const hexColor = tempColor.value.startsWith('#') ? tempColor.value : `#${tempColor.value}`
        if (!form.lang_colors) {
          form.lang_colors = {}
        }
        form.lang_colors[selectedLanguageForColor.value.code] = hexColor
        updatePreview()
      }
      closeColorPicker()
    }
    
    const resetColorToDefault = () => {
      if (selectedLanguageForColor.value) {
        if (form.lang_colors) {
          delete form.lang_colors[selectedLanguageForColor.value.code]
        }
        updatePreview()
      }
      closeColorPicker()
    }

    // Rendered HTML after fetching translations
    const renderedContent = ref('')
    const renderedTitle = ref('')
    const renderedDescription = ref('')

    // Translated expressions cache for preview { mid: Expression }
    const translationCache = ref({})

    // Search state
    const searchQuery = ref('')
    const searchResults = ref([])
    const searching = ref(false)
    let searchTimeout = null

    // Expression Tag Regex - supports {{text:xxx|lang:xxx}}, {{text:xxx|mid:123}}, {{text:xxx|lang:xxx|mid:123}}, {{xxx}}
    const TEXT_LANG_REGEX = /\{\{(?:text:)?([^|}]+)(?:\|([^}]+))?(?:\|([^}]+))?\}\}/g

    // Parse param1/param2 into lang and mid, matching backend logic
    const parseTagParams = (param1, param2, defaultLang) => {
      let lang = defaultLang
      let mid = undefined
      if (param1) {
        if (param1.startsWith('mid:')) mid = parseInt(param1.substring(4))
        else if (param1.startsWith('lang:')) lang = param1.substring(5)
      }
      if (param2) {
        if (param2.startsWith('mid:')) mid = parseInt(param2.substring(4))
        else if (param2.startsWith('lang:')) lang = param2.substring(5)
      }
      return { lang, mid }
    }

    const fetchLanguages = async () => {
      try {
        const response = await axios.get('/api/v1/languages')
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
          form.content_lang = data.source_lang || ''
          form.instruction_langs = data.target_lang 
            ? data.target_lang.split(',').filter(l => l) 
            : []
          form.is_public = !!data.is_public
          form.instruction_lang_prefix = data.instruction_lang_prefix || ''
          
          if (data.lang_colors) {
            try {
              form.lang_colors = JSON.parse(data.lang_colors)
            } catch (e) {
              form.lang_colors = {}
            }
          }

        }
      } catch (error) {
        console.error('Failed to fetch handbook:', error)
        router.push('/handbooks')
      }
    }

    const checkDraft = () => {
      const draftData = readDraftData()
      if (!draftData) {
        hasDraft.value = false
        return
      }

      // New handbook: auto-restore during initialization; do not show banner
      if (!props.id) {
        restoreDraft({ setBaseline: true })
        hasDraft.value = false
        return
      }

      // Existing handbook: show banner only if draft differs from server baseline
      try {
        const draftJson = JSON.stringify(draftData)
        hasDraft.value = !!baselineJson.value && draftJson !== baselineJson.value
      } catch (e) {
        hasDraft.value = true
      }
    }

    const restoreDraft = ({ setBaseline = false } = {}) => {
      const draftData = readDraftData()
      if (!draftData) return

      const prevInit = isInitializing.value
      isInitializing.value = true
      try {
        Object.assign(form, draftData)
        hasDraft.value = false
        if (setBaseline) {
          baselineJson.value = snapshotJson()
        }
      } finally {
        isInitializing.value = prevInit
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
          // Filter by content_lang if set
          if (form.content_lang) {
            params.from_lang = form.content_lang
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

    const insertTextAtCursor = (text) => {
      const editor = mdEditorRef.value
      const view = editor && typeof editor.getEditorView === 'function' ? editor.getEditorView() : null
      if (view && view.state && typeof view.dispatch === 'function') {
        const tr = view.state.replaceSelection(text)
        view.dispatch(tr)
        view.focus()
        return
      }

      // Fallback
      form.content = (form.content || '') + text
    }

    const insertExpression = (expr) => {
      const syntax = `{{text:${expr.text}|lang:${expr.language_code}}}`
      insertTextAtCursor(syntax)
    }

    const insertAndClear = (expr) => {
      insertExpression(expr)
      searchQuery.value = ''
      searchResults.value = []
    }

    // Parse all metadata required for preview from content
    const extractRequiredMetadata = async (content, title = '', description = '', sourceLang = '') => {
      const expressionsToFetch = [] // { id, text, lang }
      const meaningIdsToFetch = new Set()

      // Pre-wrap title if it doesn't contain tags (match backend behavior)
      let titleToExtract = title
      TEXT_LANG_REGEX.lastIndex = 0
      const hasTags = TEXT_LANG_REGEX.test(title)
      if (!hasTags && sourceLang) {
        titleToExtract = `{{text:${title.replace(/\{/g, '\\{').replace(/\}/g, '\\}')}|lang:${sourceLang}}}`
      }

      const fullText = `${titleToExtract}\n${description}\n${content}`

      TEXT_LANG_REGEX.lastIndex = 0
      let tlMatch
      while ((tlMatch = TEXT_LANG_REGEX.exec(fullText)) !== null) {
        const text = tlMatch[1]
        const param1 = tlMatch[2]
        const param2 = tlMatch[3]
        const { lang, mid } = parseTagParams(param1, param2, sourceLang)

        const id = stableExpressionId(text, lang)
        if (!expressionsToFetch.some(e => e.id === id)) {
          expressionsToFetch.push({ id, text, lang })
        }
        if (mid) {
          meaningIdsToFetch.add(mid)
        }
      }

      return { expressionsToFetch, meaningIdsToFetch: Array.from(meaningIdsToFetch) }
    }
    // Store expression data for event handling
    const expressionClickHandlers = ref(new Map())

    const renderItem = (id, text, meanings, audioUrl, isTitle = false, meaningId = null) => {
      let meaningsHtml = ''
      if (meanings && meanings.length > 0) {
        const translationsByTargetLang = {}
        meanings.forEach(m => {
          if (!m.targetLang) return
          if (!translationsByTargetLang[m.targetLang]) {
            translationsByTargetLang[m.targetLang] = []
          }
          translationsByTargetLang[m.targetLang].push(m.text)
        })

        const hasTranslations = Object.keys(translationsByTargetLang).length > 0
        if (hasTranslations) {
          const separator = isTitle ? ' / ' : ', '
          if (isTitle) {
            meaningsHtml = ` <span class="handbook-meaning-title">
              ${Object.entries(translationsByTargetLang).map(([langCode, texts]) => {
                const color = getLanguageColor({ code: langCode })
                const langClass = langCode.replace('.', '-')
                return `<span class="lang-${langClass}" style="color: ${color}">${texts.join(separator)}</span>`
              }).join(' ')}
            </span>`
          } else {
            meaningsHtml = ` <span class="handbook-meaning-content">
              ${Object.entries(translationsByTargetLang).map(([langCode, texts]) => {
                const color = getLanguageColor({ code: langCode })
                const langClass = langCode.replace('.', '-')
                return `<span class="lang-${langClass}" style="color: ${color}">${texts.join(separator)}</span>`
              }).join(' ')}
            </span>`
          }
        }
      }

      const audioIcon = audioUrl ? ` <span class="handbook-audio-icon">🔊</span>` : ''

      const key = `expr-${id}`
      expressionClickHandlers.value.set(key, { id, audioUrl })

      return `<span class="handbook-item" data-type="${isTitle ? 'title' : 'content'}" data-key="${key}" data-meaning-id="${meaningId || ''}">${text}${meaningsHtml}${audioIcon}</span>`
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

    const buildRenderedContent = (content, expressionMap, sourceLang = '') => {
      if (!content) return ''

      // Placeholder approach: replace {{...}} tags with placeholders FIRST,
      // run markdown on clean text, then substitute rendered HTML back.
      // This matches backend logic and avoids nested-span issues.
      const htmlPlaceholders = {}
      TEXT_LANG_REGEX.lastIndex = 0
      const contentWithPlaceholders = content.replace(TEXT_LANG_REGEX, (match) => {
        const index = Object.keys(htmlPlaceholders).length
        const placeholder = `HANDBOOK_ITEM_${index}`
        htmlPlaceholders[placeholder] = match
        return placeholder
      })

      // Render markdown on placeholder-substituted content
      const renderedMarkdown = md.render(contentWithPlaceholders)

      // Substitute each placeholder with its fully rendered HTML span
      const finalContent = renderedMarkdown.replace(/HANDBOOK_ITEM_\d+/g, (match) => {
        const originalTag = htmlPlaceholders[match]
        if (originalTag) {
          TEXT_LANG_REGEX.lastIndex = 0
          return originalTag.replace(TEXT_LANG_REGEX, (m, term, param1, param2) => {
            const { lang, mid } = parseTagParams(param1, param2, sourceLang)

            const id = stableExpressionId(term, lang)
            const expr = expressionMap[id]
            if (expr) {
              const midsToUse = mid ? [mid] : (expr.meanings?.map(m => m.id) || [])
              const translations = collectTranslations(expressionMap, midsToUse)
              let audioUrl = ''
              if (expr.audio_url) {
                try { audioUrl = JSON.parse(expr.audio_url)?.[0]?.url || '' } catch {}
              }
              return renderItem(id, term, translations, audioUrl, false, mid || (expr.meanings?.[0]?.id))
            }
            return `<span class="handbook-item-undefined">${term}</span>`
          })
        }
        return match
      })

      return finalContent
    }

    // Helper: collect translations for given meaning IDs across all instruction languages
    const collectTranslations = (expressionMap, meaningIds) => {
      const translations = []
      meaningIds.forEach(mid => {
        form.instruction_langs.forEach(targetLang => {
          const cacheKey = `trans_${targetLang}_${mid}`
          if (expressionMap[cacheKey] && expressionMap[cacheKey].text) {
            translations.push({ text: expressionMap[cacheKey].text, targetLang })
          }
        })
      })
      return translations
    }

    const renderPlainTextTags = (text, expressionMap, isTitle = false, sourceLang = '') => {
      if (!text) return ''
      TEXT_LANG_REGEX.lastIndex = 0
      return text.replace(TEXT_LANG_REGEX, (match, term, param1, param2) => {
        const { lang, mid } = parseTagParams(param1, param2, sourceLang)

        const id = stableExpressionId(term, lang)
        const expr = expressionMap[id]
        if (expr) {
          const midsToUse = mid ? [mid] : (expr.meanings?.map(m => m.id) || [])
          const translations = collectTranslations(expressionMap, midsToUse)
          let audioUrl = ''
          if (expr.audio_url) {
            try { audioUrl = JSON.parse(expr.audio_url)?.[0]?.url || '' } catch {}
          }
          return renderItem(id, term, translations, audioUrl, isTitle, mid || (expr.meanings?.[0]?.id))
        }
        return `<span class="handbook-item-undefined">${term}</span>`
      })
    }

    // Update preview: fetch translations if instruction_lang is set
    const updatePreview = async () => {
      if (!showPreview.value) return

      const { expressionsToFetch, meaningIdsToFetch } = await extractRequiredMetadata(form.content, form.title, form.description, form.content_lang)

      if (expressionsToFetch.length === 0) {
        renderedContent.value = buildRenderedContent(form.content, {}, form.content_lang)
        renderedTitle.value = renderPlainTextTags(form.title || '', {}, true, form.content_lang)
        renderedDescription.value = renderPlainTextTags(form.description || '', {}, false, form.content_lang)
        return
      }

      // Phase 1: Fetch source expressions
      const uncachedExprs = expressionsToFetch.filter(e => !(e.id in translationCache.value))

      if (uncachedExprs.length > 0) {
        previewLoading.value = true
        try {
          const expressions = await getExpressionsByIds(uncachedExprs.map(e => e.id))
          expressions.forEach(expr => {
            translationCache.value[expr.id] = expr
          })
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

      // Phase 2: Collect all unique meaning IDs
      const allMids = [...meaningIdsToFetch]
      expressionsToFetch.forEach(e => {
        const expr = translationCache.value[e.id]
        expr?.meanings?.forEach(m => {
          if (!allMids.includes(m.id)) allMids.push(m.id)
        })
      })

      // Phase 3: Fetch translations for all target languages
      if (allMids.length > 0 && form.instruction_langs.length > 0) {
        previewLoading.value = true
        try {
          for (const targetLang of form.instruction_langs) {
            const translations = await getHandbookExpressions(targetLang, allMids)
            
            // Merge multiple translations for same meaning_id using | separator (match backend)
            const transByMeaning = {}
            translations.forEach(trans => {
              const mids = trans.meanings?.map(m => m.id).filter(id => allMids.includes(id)) || []
              if (mids.length === 0 && trans.meaning_id) mids.push(trans.meaning_id)
              
              mids.forEach(mid => {
                if (!transByMeaning[mid]) {
                  transByMeaning[mid] = { text: '', audio_url: trans.audio_url || '' }
                }
                transByMeaning[mid].text = transByMeaning[mid].text
                  ? `${transByMeaning[mid].text} | ${trans.text}`
                  : trans.text
              })
            })

            // Store merged results
            Object.entries(transByMeaning).forEach(([mid, merged]) => {
              const cacheKey = `trans_${targetLang}_${mid}`
              translationCache.value[cacheKey] = merged
            })
            
            allMids.forEach(mid => {
              const cacheKey = `trans_${targetLang}_${mid}`
              if (!(cacheKey in translationCache.value)) {
                translationCache.value[cacheKey] = null
              }
            })
          }
        } catch (error) {
          console.error('Failed to fetch translations:', error)
        } finally {
          previewLoading.value = false
        }
      }

      renderedContent.value = buildRenderedContent(form.content, translationCache.value, form.content_lang)
      renderedTitle.value = renderPlainTextTags(form.title, translationCache.value, true, form.content_lang)
      renderedDescription.value = renderPlainTextTags(form.description, translationCache.value, false, form.content_lang)
    }

    let previewTimeout = null
    watch([() => form.content, showPreview], () => {
      if (isInitializing.value) return
      if (previewTimeout) clearTimeout(previewTimeout)
      previewTimeout = setTimeout(() => {
        updatePreview()
      }, 300)
    })

    // Auto-save watch
    let autoSaveTimeout = null
    let pendingDraft = null
    let pendingDraftJson = ''

    const flushDraft = () => {
      if (isInitializing.value) return

      // Always snapshot "now" to avoid relying on watcher timing
      pendingDraft = snapshotForm()
      pendingDraftJson = JSON.stringify(pendingDraft)

      if (baselineJson.value && pendingDraftJson === baselineJson.value) {
        localStorage.removeItem(storageKey.value)
        hasDraft.value = false
        pendingDraft = null
        pendingDraftJson = ''
        return
      }

      writeDraftData(pendingDraft)
      pendingDraft = null
      pendingDraftJson = ''
    }

    watch(form, () => {
      if (isInitializing.value) return
      if (autoSaveTimeout) clearTimeout(autoSaveTimeout)
      pendingDraft = snapshotForm()
      pendingDraftJson = JSON.stringify(pendingDraft)
      autoSaveTimeout = setTimeout(() => {
        flushDraft()
      }, 300)
    }, { deep: true, flush: 'sync' })

    const save = async () => {
      if (!form.title.trim()) {
        alert(t('title_required'))
        return
      }
      if (!form.content.trim()) {
        alert(t('content_required'))
        return
      }
      if (!form.content_lang) {
        alert(t('content_lang_required'))
        return
      }
      if (!form.instruction_langs || form.instruction_langs.length === 0) {
        alert(t('instruction_lang_required'))
        return
      }

      saving.value = true
      try {
        const payload = {
          title: form.title,
          description: form.description,
          content: form.content,
          source_lang: form.content_lang || null,
          target_lang: form.instruction_langs.length > 0 ? form.instruction_langs.join(',') : null,
          is_public: form.is_public,
          instruction_lang_prefix: form.instruction_lang_prefix || null,
          lang_colors: JSON.stringify(form.lang_colors || {})
        }
        if (isEditing.value) {
          await updateHandbook(props.id, payload)
        } else {
          await createHandbook(payload)
        }
        baselineJson.value = snapshotJson()
        clearDraft()
        router.push('/handbooks')
      } catch (error) {
        console.error('Failed to save handbook:', error)
        alert(t('handbook_save_failed'))
      } finally {
        saving.value = false
        previewLoading.value = false
      }
    }

    const goBack = () => {
      router.back()
    }

    onMounted(async () => {
      isInitializing.value = true
      await fetchLanguages()
      await fetchHandbook()

      if (props.id && form.instruction_langs.length === 0) {
        const defaultLang = languages.value.find(l => l.code === 'zh-CN')
        if (defaultLang && defaultLang.code !== form.content_lang) {
          form.instruction_langs = [defaultLang.code]
        }
      }

      // Establish baseline after server/default initialization
      baselineJson.value = snapshotJson()

      checkDraft()
      updatePreview()
      isInitializing.value = false

      window.addEventListener('beforeunload', flushDraft)
      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') flushDraft()
      })

      document.addEventListener('click', handleExpressionClick)
    })

    onBeforeUnmount(() => {
      window.removeEventListener('beforeunload', flushDraft)
      document.removeEventListener('click', handleExpressionClick)
    })

    onBeforeRouteLeave(() => {
      flushDraft()
      return true
    })

    return {
      isEditing,
      saving,
      showPreview,
      previewLoading,
      form,
      languages,
      availableInstructionLanguages,
      selectedInstructionLanguages,
      showInstructionLanguageSelector,
      searchQuery,
      searchResults,
      searching,
      mdEditorRef,
      renderedContent,
      renderedTitle,
      renderedDescription,
      search,
      insertExpression,
      insertAndClear,
      save,
      goBack,
      hasDraft,
      restoreDraft,
      clearDraft,
      getLanguageColor,
      addInstructionLanguage,
      removeInstructionLanguage,
      showColorPicker,
      selectedLanguageForColor,
      tempColor,
      openColorPicker,
      closeColorPicker,
      saveColor,
      resetColorToDefault
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
