<template>
  <div
    :class="tableOfContents.length > 0 ? 'max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8' : 'max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8'">
    <div v-if="loading" class="flex justify-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="handbook" :class="tableOfContents.length > 0 ? 'flex gap-6 lg:flex-row flex-col' : ''">
      <!-- Left Sidebar - Table of Contents -->
      <aside v-if="tableOfContents.length > 0" class="handbook-toc hidden lg:block w-64 flex-shrink-0">
        <div class="sticky top-8">
          <div class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">{{ $t('table_of_contents') }}
          </div>
          <div class="toc-list space-y-1">
            <div v-for="item in tableOfContents" :key="item.id"
              :class="['toc-item', `toc-level-${item.level}`, { 'active': activeItemId === item.id }]"
              @click="scrollToSection(item.id)">
              {{ item.text }}
            </div>
          </div>
        </div>
      </aside>

      <!-- Main Content -->
      <main :class="tableOfContents.length > 0 ? 'max-w-4xl flex-1 min-w-0' : 'max-w-4xl'">
        <div class="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-200">
          <!-- Header -->
          <div class="flex flex-col md:flex-row md:justify-between md:items-start gap-4 pb-6 border-b border-gray-100">
            <div class="space-y-3 flex-1">
              <h1 class="text-xl md:text-2xl font-bold text-gray-800"
                v-html="handbook.rendered_title || handbook.title"></h1>
              <p v-if="handbook.rendered_description || handbook.description"
                class="text-sm text-gray-500 max-w-2xl leading-relaxed"
                v-html="handbook.rendered_description || handbook.description"></p>
              <div class="text-[11px] text-gray-400">
                <p v-if="sourceLanguageName">{{ $t('content_lang') }}: {{ sourceLanguageName }}</p>
                <p v-if="handbook.created_by">{{ $t('created_by') }}: {{ handbook.created_by }}</p>
                <p>{{ $t('last_updated') }}: {{ formatDate(handbook.updated_at) }}</p>
              </div>
            </div>

            <!-- Language Switcher & Edit Button -->
            <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
              <!-- Language Switcher -->
              <div class="flex items-center gap-2">
                <span class="text-xs text-gray-400 flex-shrink-0">{{ $t('learn_in') }}: </span>

                <!-- Selected Language Tags -->
                <div class="flex flex-wrap gap-1.5 items-center relative">
                  <span v-for="lang in selectedLanguages" :key="lang.code" class="language-tag"
                    :style="{ '--lang-color': getLanguageColor(lang) }" @click="removeLanguage(lang.code)"
                    :title="$t('remove_language')">
                    <span class="language-dot"></span>
                    {{ lang.name }}
                    <span class="language-remove">×</span>
                  </span>

                  <!-- Add Language Button -->
                  <button class="language-add" @click="showLanguageSelector = !showLanguageSelector"
                    :title="$t('add_language')">
                    +
                  </button>

                  <!-- Language Selector Dropdown -->
                  <div v-if="showLanguageSelector" class="language-selector-dropdown">
                    <div v-for="lang in availableLanguages" :key="lang.code" class="language-option"
                      :style="{ '--lang-color': getLanguageColor(lang) }" @click="addLanguage(lang)">
                      <span class="language-dot"></span>
                      {{ lang.name }}
                    </div>
                  </div>
                </div>
              </div>

              <!-- Edit & Rerender Buttons -->
              <div class="flex items-center gap-2">
                <button v-if="canRerender" @click="handleRerender"
                  class="p-2 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                  :title="$t('rerender_handbook')">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                </button>
                <button v-if="canEdit" @click="goToEdit"
                  class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                  :title="$t('edit_handbook')">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
              </div>
            </div>
          </div>

          <!-- Content -->
          <div ref="contentContainer"
            class="prose prose-blue prose-headings:text-gray-800 prose-p:text-gray-600 prose-strong:text-gray-700 max-w-none leading-loose py-6 markdown-body"
            v-html="handbook.rendered_content || handbook.content"></div>

          <!-- Audio Player Placeholder (Hidden) -->
          <audio ref="audioPlayer" class="hidden"></audio>

          <!-- Expression Group Modal -->
          <ExpressionGroupModal :visible="showExpressionGroupModal" :expression-id="selectedExpressionId"
            :group-id="selectedGroupId" :languages="modalLanguages" @close="showExpressionGroupModal = false"
            @updated="handleExpressionGroupUpdated" />
        </div>
      </main>
      <!-- Mobile TOC Floating Button -->
      <button v-if="handbook && tableOfContents.length > 0"
        class="lg:hidden fixed bottom-6 right-6 z-40 bg-blue-600 text-white p-3 rounded-full shadow-lg hover:bg-blue-700 transition-all flex items-center justify-center"
        @click="showMobileToc = true" :aria-label="$t('table_of_contents')">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7" />
        </svg>
      </button>

      <!-- Mobile TOC Drawer -->
      <Transition enter-active-class="transition ease-out duration-300" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition ease-in duration-200" leave-from-class="opacity-100"
        leave-to-class="opacity-0">
        <div v-if="showMobileToc" class="lg:hidden fixed inset-0 z-50">
          <!-- Backdrop -->
          <div class="absolute inset-0 bg-gray-500 bg-opacity-75" @click="showMobileToc = false"></div>

          <!-- Drawer Panel -->
          <Transition enter-active-class="transition ease-out duration-300 transform"
            enter-from-class="translate-x-full" enter-to-class="translate-x-0"
            leave-active-class="transition ease-in duration-200 transform" leave-from-class="translate-x-0"
            leave-to-class="translate-x-full">
            <div v-if="showMobileToc"
              class="fixed inset-y-0 right-0 max-w-xs w-full bg-white shadow-xl flex flex-col z-50">
              <div class="px-4 py-6 bg-gray-50 border-b border-gray-200 flex justify-between items-center">
                <h2 class="text-lg font-bold text-gray-800">{{ $t('table_of_contents') }}</h2>
                <button @click="showMobileToc = false" class="text-gray-400 hover:text-gray-500">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div class="flex-1 overflow-y-auto px-4 py-6">
                <div class="toc-list space-y-1">
                  <div v-for="item in tableOfContents" :key="item.id"
                    :class="['toc-item', `toc-level-${item.level}`, { 'active': activeItemId === item.id }]"
                    @click="onTocClick(item.id)">
                    {{ item.text }}
                  </div>
                </div>
              </div>
            </div>
          </Transition>
        </div>
      </Transition>
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
import { ref, onMounted, onUnmounted, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { handbooksApi } from '../api/index.ts'
import { languagesApi } from '../api/index.ts'
import { generateLanguageColor } from '../utils/languageUtils'
import ExpressionGroupModal from '../components/ExpressionGroupModal.vue'

export default {
  name: 'HandbookView',
  components: { ExpressionGroupModal },
  props: ['id'],
  setup(props) {
    const router = useRouter()
    const route = router.currentRoute

    // State
    const handbook = ref(null)
    const languages = ref([])
    const instructionLanguages = ref([])
    const showLanguageSelector = ref(false)
    const loading = ref(true)
    const audioPlayer = ref(null)
    const currentUser = ref(null)
    const isInitialized = ref(false)
    const contentContainer = ref(null)
    const tableOfContents = ref([])
    const activeItemId = ref(null)
    const tocObserver = ref(null)

    // Table of contents control
    const showMobileToc = ref(false)

    // Expression group modal
    const showExpressionGroupModal = ref(false)
    const selectedExpressionId = ref(null)
    const selectedGroupId = ref(null)

    // Initialize languages from URL query params or handbook
    const setInitialLanguages = () => {
      const urlTargetLang = route.value.query.target_lang
      if (urlTargetLang) {
        instructionLanguages.value = urlTargetLang.split(',').filter(l => l.trim())
      } else if (handbook.value?.target_lang) {
        instructionLanguages.value = handbook.value.target_lang.split(',').filter(l => l)
      }
    }

    // Update URL with selected languages
    const updateURLLanguages = () => {
      const targetLangParam = instructionLanguages.value.join(',')
      router.replace({
        query: {
          ...route.value.query,
          target_lang: targetLangParam || undefined
        }
      })
    }

    const fetchInitialData = async () => {
      loading.value = true
      try {
        // Fetch languages if not loaded
        if (languages.value.length === 0) {
          const langResult = await languagesApi.getAll()
          languages.value = langResult.success && langResult.data ? langResult.data : []
        }

        // Fetch handbook with target languages in one request
        const targetLangsParam = instructionLanguages.value.join(',')
        console.log('[HandbookView] Fetching handbook data:', {
          handbookId: props.id,
          instructionLanguages: instructionLanguages.value,
          targetLangsParam
        })
        const dataRes = await handbooksApi.getById(props.id, null, targetLangsParam)
        if (dataRes.success && dataRes.data) {
          const data = dataRes.data
          handbook.value = data

          console.log('[HandbookView] Handbook data received:', {
            hasRenderedContent: !!data.rendered_content,
            renderedContentLength: data.rendered_content?.length,
            hasRenderedTitle: !!data.rendered_title,
            isCached: data.is_cached
          })

          // Only set initial languages on first load
          if (!isInitialized.value) {
            setInitialLanguages()
            // Update URL with initial languages
            const urlTargetLang = route.value.query.target_lang
            if (!urlTargetLang && instructionLanguages.value.length > 0) {
              updateURLLanguages()
            }
            isInitialized.value = true
          }

          // Parse table of contents after content is rendered
          await parseTableOfContents()
        }

        // Auth check for edit button
        const userStr = localStorage.getItem('user')
        if (userStr) {
          currentUser.value = JSON.parse(userStr)
        }

      } catch (error) {
        console.error('Failed to load handbook data:', error)
      } finally {
        loading.value = false
      }
    }

    const parseTableOfContents = async (retryCount = 0) => {
      // 防止重复执行
      if (tableOfContents.value.length > 0 && retryCount > 0) {
        return
      }

      if (!handbook.value?.rendered_content) {
        tableOfContents.value = []
        return
      }

      await nextTick()

      const container = contentContainer.value

      if (!container) {
        if (retryCount < 10) {
          setTimeout(() => parseTableOfContents(retryCount + 1), 100)
          return
        }
        tableOfContents.value = []
        return
      }

      const headings = container.querySelectorAll('h1, h2, h3')

      if (headings.length === 0) {
        tableOfContents.value = []
        return
      }

      const toc = []

      headings.forEach((heading) => {
        let id = heading.id
        let text

        // 克隆整个 heading，移除翻译相关的元素，然后获取文本
        const clone = heading.cloneNode(true)

        // 移除翻译相关的 span
        const meaningElements = clone.querySelectorAll('.handbook-meaning-content, .handbook-meaning-title')
        meaningElements.forEach(el => el.remove())

        // 移除音频图标（如果存在）
        const audioIcons = clone.querySelectorAll('.handbook-audio-icon')
        audioIcons.forEach(el => el.remove())

        // 获取文本
        text = clone.textContent.trim()

        const level = parseInt(heading.tagName.charAt(1))

        // If no id, generate one
        if (!id) {
          id = generateId(text)
          heading.id = id
        }

        toc.push({ level, text, id })
      })

      tableOfContents.value = toc

      // Set up scroll observer after TOC is parsed
      setupScrollObserver()
    }

    const generateId = (text) => {
      return text
        .toLowerCase()
        .replace(/[^\w\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim()
    }

    const scrollToSection = (id) => {
      const element = document.getElementById(id)
      if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'start' })
        activeItemId.value = id
      }
    }

    const onTocClick = (id) => {
      scrollToSection(id)
      showMobileToc.value = false
    }

    const setupScrollObserver = () => {
      // Clean up existing observer
      if (tocObserver.value) {
        tocObserver.value.disconnect()
      }

      const container = contentContainer.value
      if (!container) return

      const headings = container.querySelectorAll('h1, h2, h3')

      const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            activeItemId.value = entry.target.id
          }
        })
      }, {
        rootMargin: '-10% 0px -80% 0px',
        threshold: 0
      })

      headings.forEach((heading) => observer.observe(heading))
      tocObserver.value = observer
    }

    // Global helpers for rendered HTML interactions
    window.playHandbookAudio = (url) => {
      if (!url || !audioPlayer.value) return
      audioPlayer.value.src = url
      audioPlayer.value.play()
    }

    window.navigateToExpression = (id) => {
      router.push(`/detail/${id}`)
    }

    const handleExpressionClick = (event) => {
      const { id, meaningId } = event.detail
      selectedExpressionId.value = id
      selectedGroupId.value = meaningId
      showExpressionGroupModal.value = true
    }

    const handleExpressionGroupUpdated = () => {
      // 更新之後無需刷新頁面
      // fetchInitialData()
    }

    const canEdit = computed(() => {
      if (!handbook.value || !currentUser.value) return false
      return handbook.value.user_id === currentUser.value.id || currentUser.value.role === 'admin'
    })

    const canRerender = computed(() => {
      if (!handbook.value || !currentUser.value) return false
      return handbook.value.user_id === currentUser.value.id || currentUser.value.role === 'admin'
    })

    const handleRerender = async () => {
      try {
        loading.value = true
        const rerenderResult = await handbooksApi.rerender(props.id)
        if (!rerenderResult.success) {
          console.error('Rerender failed:', rerenderResult.error || rerenderResult.message)
          alert('Failed to rerender handbook. Please try again.')
          return
        }
        await fetchInitialData()
      } catch (error) {
        console.error('Failed to rerender handbook:', error)
      } finally {
        loading.value = false
      }
    }

    const selectedLanguages = computed(() => {
      return languages.value.filter(lang =>
        instructionLanguages.value.includes(lang.code)
      )
    })

    const modalLanguages = computed(() => {
      const sourceLangCode = handbook.value?.source_lang
      const sourceLang = sourceLangCode ? languages.value.find(l => l.code === sourceLangCode) : null

      let result = []
      if (selectedLanguages.value.length > 0) {
        result = [...selectedLanguages.value]
      } else {
        // Fallback to all loaded languages if selectedLanguages is empty
        result = [...languages.value]
      }

      if (sourceLang && !result.some(l => l.code === sourceLang.code)) {
        result.unshift(sourceLang)
      }

      console.log('modalLanguages computed:', {
        sourceLangCode,
        sourceLang,
        selectedLanguages: selectedLanguages.value,
        languagesLength: languages.value.length,
        resultLength: result.length,
        result: result
      })

      return result
    })

    const availableLanguages = computed(() => {
      let result = [...languages.value]
        .filter(lang =>
          lang.code !== handbook.value?.source_lang &&
          !instructionLanguages.value.includes(lang.code)
        )

      // Apply prefix filter if instruction_lang_prefix is configured
      if (handbook.value?.instruction_lang_prefix) {
        result = result.filter(lang => lang.code.startsWith(handbook.value.instruction_lang_prefix))
      }

      return result.sort((a, b) => a.name.localeCompare(b.name))
    })

    const sourceLanguageName = computed(() => {
      if (!handbook.value?.source_lang) return null
      const lang = languages.value.find(l => l.code === handbook.value.source_lang)
      return lang?.name || handbook.value.source_lang
    })

    const getLanguageColor = (lang) => {
      if (handbook.value?.lang_colors) {
        try {
          const colors = JSON.parse(handbook.value.lang_colors)
          if (colors[lang.code]) {
            return colors[lang.code]
          }
        } catch (e) { }
      }
      return generateLanguageColor(lang.code)
    }

    const addLanguage = (lang) => {
      if (!instructionLanguages.value.includes(lang.code) && instructionLanguages.value.length < 5) {
        instructionLanguages.value.push(lang.code)
        updateURLLanguages()
        fetchInitialData()
      }
      showLanguageSelector.value = false
    }

    const removeLanguage = (langCode) => {
      if (instructionLanguages.value.length > 1) {
        instructionLanguages.value = instructionLanguages.value.filter(
          code => code !== langCode
        )
        updateURLLanguages()
        fetchInitialData()
      }
    }

    const goToEdit = () => {
      router.push(`/handbooks/${props.id}/edit`)
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString()
    }

    onMounted(() => {
      fetchInitialData()
      window.addEventListener('handbook-expression-click', handleExpressionClick)
    })

    watch(() => handbook.value, (newHandbook) => {
      if (newHandbook) {
        document.title = `${newHandbook.rendered_title || newHandbook.title} - langmap`
      }
    })

    watch(() => handbook.value?.rendered_content, (newContent) => {
      if (newContent) {
        parseTableOfContents()
      }
    })

    onUnmounted(() => {
      window.removeEventListener('handbook-expression-click', handleExpressionClick)
      if (tocObserver.value) {
        tocObserver.value.disconnect()
      }
    })

    return {
      handbook,
      loading,
      instructionLanguages,
      selectedLanguages,
      modalLanguages,
      availableLanguages,
      showLanguageSelector,
      audioPlayer,
      canEdit,
      canRerender,
      goToEdit,
      formatDate,
      getLanguageColor,
      addLanguage,
      removeLanguage,
      sourceLanguageName,
      showExpressionGroupModal,
      selectedExpressionId,
      selectedGroupId,
      handleExpressionGroupUpdated,
      handleRerender,
      contentContainer,
      tableOfContents,
      activeItemId,
      scrollToSection,
      onTocClick,
      showMobileToc
    }
  }
}
</script>

<style scoped>
.handbook-toc {
  position: sticky;
  top: 2rem;
  height: fit-content;
  max-height: calc(100vh - 4rem);
  overflow-y: auto;
}

.toc-list {
  font-size: 0.875rem;
}

.toc-item {
  padding: 0.375rem 0.5rem;
  cursor: pointer;
  border-radius: 0.375rem;
  transition: all 0.2s ease;
  color: #6b7280;
  line-height: 1.5;
}

.toc-item.toc-level-1 {
  font-weight: 600;
  margin-top: 0.375rem;
  font-size: 0.9375rem;
}

.toc-item.toc-level-2 {
  padding-left: 1.25rem;
  font-size: 0.875rem;
}

.toc-item.toc-level-3 {
  padding-left: 2rem;
  font-size: 0.8125rem;
}

.toc-item:hover:not(.active) {
  background-color: #f3f4f6;
  color: #374151;
}

.toc-item.active {
  background-color: #eff6ff;
  color: #2563eb;
  border-left: 3px solid #2563eb;
  padding-left: 0.375rem;
}

.toc-item.toc-level-2.active {
  padding-left: 1.125rem;
}

.toc-item.toc-level-3.active {
  padding-left: 1.875rem;
}

/* Image expressions in handbook content */
.markdown-body .handbook-item img {
  max-height: 3rem;
  max-width: 3rem;
  object-fit: contain;
  vertical-align: middle;
  display: inline-block;
}

/* Ensure inline images don't break layout */
.markdown-body .handbook-item {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}
</style>

<style>
/* Image expressions in handbook content - global styles for v-html content */
.markdown-body .handbook-item img,
.markdown-body .handbook-image-expression {
  max-height: 2rem;
  max-width: 2rem;
  object-fit: contain;
  vertical-align: middle;
  display: inline-block;
  border-radius: 0.25rem;
}

/* Ensure inline images don't break layout */
.markdown-body .handbook-item {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}
</style>
