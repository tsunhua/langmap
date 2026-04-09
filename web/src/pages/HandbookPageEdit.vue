<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
    <div class="mb-4 text-sm text-gray-500">
      <router-link to="/handbooks" class="hover:text-blue-600">{{ $t('handbook_title') }}</router-link>
      <span class="mx-1">/</span>
      <router-link :to="`/handbooks/${id}`" class="hover:text-blue-600">{{ handbookTitle || '...' }}</router-link>
      <span class="mx-1">/</span>
      <span class="text-gray-700">{{ isEditing ? $t('edit_page') : $t('add_page') }}</span>
    </div>

    <div v-if="hasDraft"
      class="mb-4 p-4 bg-yellow-50 border border-yellow-200 rounded-xl flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div class="flex items-center gap-3">
        <span class="text-xl">📝</span>
        <div>
          <p class="text-sm font-medium text-yellow-800">{{ $t('draft_found') }}</p>
          <p class="text-xs text-yellow-600">{{ $t('draft_found_hint') }}</p>
        </div>
      </div>
      <div class="flex items-center gap-2 w-full sm:w-auto">
        <button @click="clearDraft"
          class="flex-1 sm:flex-none px-3 py-2 text-xs text-yellow-700 hover:text-yellow-800 font-medium min-h-[44px] cursor-pointer">
          {{ $t('discard_draft') }}
        </button>
        <button @click="restoreDraft"
          class="flex-1 sm:flex-none px-4 py-2 text-xs bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 font-medium transition-colors min-h-[44px] cursor-pointer">
          {{ $t('restore_draft') }}
        </button>
      </div>
    </div>

    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 mb-6">
      <div class="flex-1 w-full">
        <input v-model="pageTitle" type="text"
          class="w-full text-xl font-bold text-gray-900 border-none outline-none bg-transparent"
          :placeholder="$t('page_title_placeholder') || 'Page Title'" />
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

    <div class="bg-white p-5 rounded-2xl shadow-sm border border-gray-200">
      <div :class="['grid gap-4', showPreview ? 'grid-cols-1 lg:grid-cols-2' : 'grid-cols-1']">
        <div>
          <div class="flex gap-2 mb-2">
            <div class="relative flex-1">
              <input v-model="searchQuery" type="text"
                class="w-full pl-8 pr-3 py-2.5 sm:py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs focus:ring-1 focus:ring-blue-500 outline-none focus:bg-white min-h-[44px]"
                :placeholder="sourceLang ? `🔍 ${$t('search_in_lang', { lang: sourceLang })}` : ('🔍 ' + $t('insert_expression'))"
                @input="search" />

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
                      <span v-if="expr.language_code !== 'image'" class="font-bold text-sm text-gray-800">{{ expr.text }}</span>
                      <img v-else :src="expr.text" class="h-12 w-12 object-contain rounded" alt="expression image" />
                      <span
                        class="text-[10px] bg-blue-100 text-blue-600 px-1.5 py-0.5 rounded font-bold uppercase">{{
                        expr.language_code }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <button @click="showPreview = !showPreview"
              :class="['min-h-[44px] px-3 py-1 text-xs font-medium rounded-lg transition-colors flex items-center gap-1 cursor-pointer border shrink-0', showPreview ? 'bg-blue-50 text-blue-700 border-blue-200' : 'text-gray-500 hover:bg-gray-50 border-gray-200']"
              :title="showPreview ? $t('hide_preview') : $t('show_preview')">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                stroke="currentColor" class="w-4 h-4">
                <path v-if="showPreview" stroke-linecap="round" stroke-linejoin="round"
                  d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
                <path v-else stroke-linecap="round" stroke-linejoin="round"
                  d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                <path v-if="!showPreview" stroke-linecap="round" stroke-linejoin="round"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span class="hidden sm:inline">{{ showPreview ? $t('hide_preview') : $t('show_preview') }}</span>
            </button>
          </div>

          <MdEditor ref="mdEditorRef" v-model="pageContent" :preview="false" :htmlPreview="false"
            :noUploadImg="true" :toolbarsExclude="['preview', 'htmlPreview', 'mermaid', 'katex', 'github']"
            placeholder="Write your content here. Use {{word}}, {{text:word|lang:en-US}} or {{text:word|mid:123}} to insert expressions."
            class="border border-gray-200 rounded-xl overflow-hidden"
            :style="{ height: showPreview ? '700px' : '760px' }" />
        </div>

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
          <div v-else-if="previewHtml">
            <h1 class="text-xl sm:text-2xl font-bold text-gray-800 mb-4 pb-4 border-b border-gray-100" v-html="previewHtml.title || ''"></h1>
            <div
              class="prose prose-blue prose-headings:text-gray-800 prose-p:text-gray-600 prose-strong:text-gray-700 max-w-none leading-loose markdown-body prose-sm sm:prose-base"
              v-html="previewHtml.content || ''"></div>
          </div>
          <div v-else class="text-center text-gray-400 py-12">
            <p class="text-sm">{{ $t('no_preview') || 'Preview will appear here' }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onBeforeUnmount, computed, watch } from 'vue'
import { useRouter, onBeforeRouteLeave } from 'vue-router'
import { useI18n } from 'vue-i18n'
import axios from 'axios'
import { MdEditor } from 'md-editor-v3'
import 'md-editor-v3/lib/style.css'
import { handbooksApi } from '../api/index.ts'

export default {
  name: 'HandbookPageEdit',
  components: { MdEditor },
  props: ['id', 'pageId'],
  setup(props) {
    const router = useRouter()
    const { t } = useI18n()

    const isEditing = computed(() => !!props.pageId)
    const saving = ref(false)
    const showPreview = ref(false)
    const previewLoading = ref(false)
    const mdEditorRef = ref(null)

    const handbookTitle = ref('')
    const sourceLang = ref('')
    const targetLang = ref('')
    const pageTitle = ref('')
    const pageContent = ref('')
    const previewHtml = ref(null)

    const storageKey = computed(() => `handbook-page-draft-${props.id}-${props.pageId || 'new'}`)
    const hasDraft = ref(false)
    const isInitializing = ref(true)
    const baselineJson = ref('')

    const DRAFT_VERSION = 1

    const snapshotForm = () => ({
      pageTitle: pageTitle.value,
      pageContent: pageContent.value
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
          handbookId: props.id || null,
          pageId: props.pageId || null
        },
        data
      }
      localStorage.setItem(storageKey.value, JSON.stringify(payload))
    }

    const searchQuery = ref('')
    const searchResults = ref([])
    const searching = ref(false)
    let searchTimeout = null

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
          if (sourceLang.value) {
            params.from_lang = sourceLang.value
          }
          const response = await axios.get('/api/v1/search', { params })
          const searchData = response.data.data || response.data || []
          searchResults.value = Array.isArray(searchData) ? searchData : []
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
      pageContent.value = (pageContent.value || '') + text
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

    const fetchPreview = async () => {
      if (!showPreview.value || saving.value) return

      previewLoading.value = true
      try {
        const result = await handbooksApi.previewPage(props.id, {
          title: pageTitle.value,
          content: pageContent.value,
          source_lang: sourceLang.value || undefined,
          target_lang: targetLang.value || undefined
        })
        if (result.success && result.data) {
          previewHtml.value = result.data
        } else {
          previewHtml.value = null
        }
      } catch (error) {
        console.error('Preview error:', error)
        previewHtml.value = null
      } finally {
        previewLoading.value = false
      }
    }

    let previewTimeout = null
    watch([pageContent, pageTitle, showPreview], () => {
      if (isInitializing.value) return
      if (previewTimeout) clearTimeout(previewTimeout)
      previewTimeout = setTimeout(() => {
        fetchPreview()
      }, 500)
    })

    let autoSaveTimeout = null
    let pendingDraft = null
    let pendingDraftJson = ''

    const flushDraft = () => {
      if (isInitializing.value) return

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

    watch([pageTitle, pageContent], () => {
      if (isInitializing.value) return
      if (autoSaveTimeout) clearTimeout(autoSaveTimeout)
      pendingDraft = snapshotForm()
      pendingDraftJson = JSON.stringify(pendingDraft)
      autoSaveTimeout = setTimeout(() => {
        flushDraft()
      }, 300)
    })

    const checkDraft = () => {
      const draftData = readDraftData()
      if (!draftData) {
        hasDraft.value = false
        return
      }

      if (!props.pageId) {
        restoreDraft({ setBaseline: true })
        hasDraft.value = false
        return
      }

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
        pageTitle.value = draftData.pageTitle || ''
        pageContent.value = draftData.pageContent || ''
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

    const fetchHandbook = async () => {
      if (!props.id) return
      try {
        const result = await handbooksApi.getById(props.id)
        if (result.success && result.data) {
          const data = result.data
          handbookTitle.value = data.title || ''
          sourceLang.value = data.source_lang || ''
          targetLang.value = data.target_lang || ''
        }
      } catch (error) {
        console.error('Failed to fetch handbook:', error)
        router.push('/handbooks')
      }
    }

    const fetchPage = async () => {
      if (!props.pageId) return
      try {
        const result = await handbooksApi.getPageById(props.id, props.pageId)
        if (result.success && result.data) {
          const data = result.data
          pageTitle.value = data.title || ''
          pageContent.value = data.content || ''
        }
      } catch (error) {
        console.error('Failed to fetch page:', error)
        router.push(`/handbooks/${props.id}`)
      }
    }

    const save = async () => {
      if (!pageTitle.value.trim()) {
        alert(t('title_required'))
        return
      }

      saving.value = true
      try {
        const payload = {
          title: pageTitle.value,
          content: pageContent.value
        }
        let newPageId
        if (isEditing.value) {
          const updateResult = await handbooksApi.updatePage(props.id, props.pageId, payload)
          if (!updateResult.success) {
            console.error('Update failed:', updateResult.error || updateResult.message)
            alert(t('handbook_save_failed'))
            return
          }
          newPageId = props.pageId
        } else {
          const createResult = await handbooksApi.createPage(props.id, payload)
          if (!createResult.success) {
            console.error('Create failed:', createResult.error || createResult.message)
            alert(t('handbook_save_failed'))
            return
          }
          newPageId = createResult.data.id
        }
        baselineJson.value = snapshotJson()
        clearDraft()
        router.push(`/handbooks/${props.id}/pages/${newPageId}`)
      } catch (error) {
        console.error('Failed to save page:', error)
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
      await fetchHandbook()
      await fetchPage()

      baselineJson.value = snapshotJson()

      checkDraft()
      isInitializing.value = false

      window.addEventListener('beforeunload', flushDraft)
      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') flushDraft()
      })
    })

    onBeforeUnmount(() => {
      window.removeEventListener('beforeunload', flushDraft)
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
      previewHtml,
      handbookTitle,
      sourceLang,
      pageTitle,
      pageContent,
      searchQuery,
      searchResults,
      searching,
      mdEditorRef,
      search,
      insertAndClear,
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

<style>
.markdown-body .handbook-item img,
.markdown-body .handbook-image-expression {
  max-height: 3rem;
  max-width: 3rem;
  object-fit: contain;
  vertical-align: middle;
  display: inline-block;
  border-radius: 0.25rem;
}

.markdown-body .handbook-item {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}
</style>
