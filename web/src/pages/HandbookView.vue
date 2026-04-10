<template>
  <div
    :class="(tableOfContents.length > 0 || isMultiPage) ? 'max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8' : 'max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8'">
    <div v-if="loading" class="flex justify-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="handbook" :class="(tableOfContents.length > 0 || isMultiPage) ? 'flex gap-6 lg:flex-row flex-col' : ''">
      <!-- Navigation Sidebar (Unified TOC & Pages) -->
      <aside v-if="tableOfContents.length > 0 || isMultiPage" class="handbook-navigation hidden lg:block w-64 flex-shrink-0">
        <div class="sticky top-8">
          <div class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
            {{ isMultiPage ? $t('pages') : $t('table_of_contents') }}
          </div>
          
          <div class="nav-list space-y-1">
            <!-- Multi-page navigation -->
            <template v-if="isMultiPage">
              <!-- Introduction -->
              <div 
                :class="['px-3 py-2 rounded-lg cursor-pointer text-sm transition-colors mb-2 border border-transparent shadow-sm flex items-center gap-2', !currentPageId ? 'bg-blue-600 text-white font-medium border-blue-700' : 'text-gray-700 bg-gray-50 hover:bg-gray-100 hover:border-gray-200']"
                @click="goToPage(null)">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                <span>{{ $t('introduction') }}</span>
              </div>

              <div v-for="page in (pages || [])" :key="page?.id">
                <!-- Page Title -->
                <div 
                  :class="['px-3 py-2 rounded-lg cursor-pointer text-sm transition-colors mb-1', currentPageId === page?.id ? 'bg-blue-50 text-blue-700 font-medium' : 'text-gray-600 hover:bg-gray-50']"
                  @click="page && goToPage(page.id)">
                  {{ page?.title }}
                </div>
                
                <!-- Nested headings for active page -->
                <div v-if="currentPageId === page?.id && tableOfContents.length > 0" class="ml-3 mb-2 space-y-1 border-l-2 border-blue-100 pl-1">
                  <template v-for="(item, index) in tableOfContents" :key="item?.id || index">
                    <div v-if="isVisible(item)"
                      :class="['toc-item', `toc-level-${item.level}`, { 'active': activeItemId === item.id }]"
                      @click="handleTocItemClick(item)">
                      <span v-if="hasChildren(item)" class="toc-toggle" @click.stop="toggleCollapse(item.id)">
                        <svg :class="['toc-toggle-icon', { 'collapsed': collapsedItems.has(item.id) }]" viewBox="0 0 24 24"
                          fill="none" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg>
                      </span>
                      <span class="toc-text text-xs">{{ item.text }}</span>
                    </div>
                  </template>
                </div>
              </div>
              
              <!-- Add Page Button -->
              <button v-if="canEdit" @click="goToNewPage"
                class="w-full mt-2 px-3 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-lg transition-colors flex items-center gap-1">
                <span class="text-lg leading-none">+</span> {{ $t('add_page') }}
              </button>
            </template>
            
            <!-- Default single-page TOC -->
            <template v-else>
              <template v-for="(item, index) in tableOfContents" :key="item?.id || index">
                <div v-if="isVisible(item)"
                  :class="['toc-item', `toc-level-${item.level}`, { 'active': activeItemId === item.id }]"
                  @click="handleTocItemClick(item)">
                  <span v-if="hasChildren(item)" class="toc-toggle" @click.stop="toggleCollapse(item.id)">
                    <svg :class="['toc-toggle-icon', { 'collapsed': collapsedItems.has(item.id) }]" viewBox="0 0 24 24"
                      fill="none" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                    </svg>
                  </span>
                  <span class="toc-text">{{ item.text }}</span>
                </div>
              </template>
            </template>
          </div>
        </div>
      </aside>

      <!-- Main Content -->
      <main :class="(tableOfContents.length > 0 || isMultiPage) ? 'max-w-4xl flex-1 min-w-0' : 'max-w-4xl'">
        <div class="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-200">
          <!-- Header -->
          <div class="flex flex-col md:flex-row md:justify-between md:items-start gap-4 pb-6 border-b border-gray-100">
            <div class="space-y-3 flex-1">
              <h1 class="text-xl md:text-2xl font-bold text-gray-800"
                v-html="handbook?.rendered_title || handbook?.title"></h1>
              <p v-if="handbook?.rendered_description || handbook?.description"
                class="text-sm text-gray-500 max-w-2xl leading-relaxed mt-8"
                v-html="handbook?.rendered_description || handbook?.description"></p>
              <div v-if="handbook" class="text-[11px] text-gray-400 mt-4">
                <p v-if="handbook.created_by">{{ $t('created_by') }}: {{ handbook.created_by }}</p>
                <p>{{ $t('last_updated') }}: {{ formatDate(handbook.updated_at) }}</p>
                <p v-if="sourceLanguageName">{{ $t('content_lang') }}: {{ sourceLanguageName }}</p>
                <p v-if="handbook.author">{{ handbook.author }}<span v-if="handbook.published_at"> · {{ handbook.published_at?.substring(0, 4) }}</span></p>
              </div>
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
            </div>

            <!-- Edit Button -->
            <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
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
            v-html="handbook?.rendered_content || handbook?.content"></div>

          <!-- Audio Player Placeholder (Hidden) -->
          <audio ref="audioPlayer" class="hidden"></audio>

          <!-- Expression Group Modal -->
          <ExpressionGroupModal :visible="showExpressionGroupModal" :expression-id="selectedExpressionId"
            :group-id="selectedGroupId" :languages="modalLanguages" @close="showExpressionGroupModal = false"
            @updated="handleExpressionGroupUpdated" />

          <!-- Image Modal -->
          <div v-if="showImageModal" class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50 p-4"
            @click.self="closeImageModal">
            <div class="relative max-w-5xl max-h-[90vh]">
              <button @click="closeImageModal"
                class="absolute -top-4 -right-4 text-white bg-black bg-opacity-50 hover:bg-opacity-70 rounded-full p-2 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
              <img :src="modalImageUrl" class="max-w-full max-h-[85vh] object-contain" alt="Full size handbook image" />
            </div>
          </div>
        </div>

        <!-- Page Navigation -->
        <div v-if="isMultiPage && pages.length > 0" class="flex justify-between items-center py-4 border-t border-gray-100 mt-6">
          <button v-if="prevPage && prevPage.id" @click="goToPage(prevPage.id)"
            class="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800 transition-colors">
            &laquo; {{ $t('prev_page') }}
          </button>
          <span v-else></span>
          <span class="text-xs text-gray-400">{{ currentPageIndex + 1 }} / {{ pages.length }}</span>
          <button v-if="nextPage && nextPage.id" @click="goToPage(nextPage.id)"
            class="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800 transition-colors">
            {{ $t('next_page') }} &raquo;
          </button>
          <span v-else></span>
        </div>
      </main>
      <!-- Mobile TOC Floating Button -->
      <button v-if="handbook && (tableOfContents.length > 0 || isMultiPage)"
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
                <div class="nav-list space-y-1">
                  <!-- Multi-page navigation -->
                  <template v-if="isMultiPage">
                    <!-- Introduction (Mobile) -->
                    <div 
                      :class="['px-3 py-3 rounded-lg cursor-pointer text-sm transition-colors mb-2 flex items-center gap-2', !currentPageId ? 'bg-blue-50 text-blue-700 font-medium' : 'text-gray-600 hover:bg-gray-50']"
                      @click="onPageMobileClick(null)">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                      {{ $t('introduction') }}
                    </div>

                    <div v-for="page in (pages || [])" :key="page?.id">
                      <!-- Page Title -->
                      <div 
                        :class="['px-3 py-2 rounded-lg cursor-pointer text-sm transition-colors mb-1', currentPageId === page?.id ? 'bg-blue-50 text-blue-700 font-medium' : 'text-gray-600 hover:bg-gray-50']"
                        @click="onPageMobileClick(page)">
                        {{ page?.title }}
                      </div>
                      
                      <!-- Nested headings for active page -->
                      <div v-if="currentPageId === page?.id && tableOfContents.length > 0" class="ml-3 mb-2 space-y-1 border-l-2 border-blue-100 pl-1">
                        <template v-for="(item, index) in tableOfContents" :key="item?.id || index">
                          <div v-if="isVisible(item)"
                            :class="['toc-item', `toc-level-${item.level}`, { 'active': activeItemId === item.id }]"
                            @click="onTocMobileClick(item)">
                            <span v-if="hasChildren(item)" class="toc-toggle" @click.stop="toggleCollapse(item.id)">
                              <svg :class="['toc-toggle-icon', { 'collapsed': collapsedItems.has(item.id) }]"
                                viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                              </svg>
                            </span>
                            <span class="toc-text text-xs">{{ item.text }}</span>
                          </div>
                        </template>
                      </div>
                    </div>
                  </template>
                  
                  <!-- Default single-page TOC -->
                  <template v-else>
                    <template v-for="(item, index) in tableOfContents" :key="item?.id || index">
                      <div v-if="isVisible(item)"
                        :class="['toc-item', `toc-level-${item.level}`, { 'active': activeItemId === item.id }]"
                        @click="onTocMobileClick(item)">
                        <span v-if="hasChildren(item)" class="toc-toggle" @click.stop="toggleCollapse(item.id)">
                          <svg :class="['toc-toggle-icon', { 'collapsed': collapsedItems.has(item.id) }]"
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                          </svg>
                        </span>
                        <span class="toc-text">{{ item.text }}</span>
                      </div>
                    </template>
                  </template>
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
import { ref, reactive, onMounted, onUnmounted, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { handbooksApi } from '../api/index.ts'
import { languagesApi } from '../api/index.ts'
import { generateLanguageColor } from '../utils/languageUtils'
import ExpressionGroupModal from '../components/ExpressionGroupModal.vue'

export default {
  name: 'HandbookView',
  components: { ExpressionGroupModal },
  props: ['id', 'pageId'],
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
    const collapsedItems = reactive(new Set())
    const pages = ref([])
    const currentPageId = ref(null)

    // Table of contents control
    const showMobileToc = ref(false)

    // Expression group modal
    const showExpressionGroupModal = ref(false)
    const selectedExpressionId = ref(null)
    const selectedGroupId = ref(null)

    // Image modal
    const showImageModal = ref(false)
    const modalImageUrl = ref('')

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
      tableOfContents.value = [] // Clear TOC immediately on load/switch
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
          targetLangsParam,
          handbookIdType: typeof props.id,
          handbookIdValue: props.id
        })
        const dataRes = await handbooksApi.getById(props.id, null, targetLangsParam)
        if (dataRes.success && dataRes.data) {
          const data = dataRes.data
          console.log('[HandbookView] Full handbook data received:', data)
          handbook.value = data

          console.log('[HandbookView] Handbook data received:', {
            hasRenderedContent: !!data.rendered_content,
            renderedContentLength: data.rendered_content?.length,
            hasRenderedTitle: !!data.rendered_title,
            isCached: data.is_cached,
            handbookId: data.id,
            handbookIdType: typeof data.id,
            handbookTitle: data.title,
            handbookAuthor: data.author,
            handbookHasPages: data.has_pages,
            handbookUser_id: data.user_id
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

          // Populate page list from handbook metadata immediately
          if (data?.has_pages === 1 && data.pages) {
            pages.value = data.pages
            console.log('[HandbookView] Pages initialized from metadata:', pages.value.length)
          }

          // Handle multi-page initial navigation
          if (data?.has_pages === 1) {
            if (props.pageId) {
              currentPageId.value = parseInt(props.pageId)
              const targetLangsParam = instructionLanguages.value.join(',')
              const pageResult = await handbooksApi.getPageById(props.id, props.pageId, targetLangsParam)
              if (pageResult.success && pageResult.data) {
                const pageData = pageResult.data
                handbook.value = {
                  ...data,
                  rendered_title: pageData.rendered_title,
                  rendered_content: pageData.rendered_content,
                  content: pageData.content,
                  title: pageData.title
                }
                console.log('[HandbookView] Current page content loaded:', pageData.id)
              }
            }
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
      // Clear ID cache for every fresh parse to prevent stale suffixing between pages
      _idSeen.clear()

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

      const headings = container.querySelectorAll('h1, h2, h3, h4')

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

    const _idSeen = new Map()
    const generateId = (text) => {
      const base = text
        .toLowerCase()
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim()
      const count = _idSeen.get(base) ?? 0
      _idSeen.set(base, count + 1)
      return count === 0 ? base : `${base}-${count}`
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

    // Collapse helpers
    const toggleCollapse = (id) => {
      if (collapsedItems.has(id)) {
        collapsedItems.delete(id)
      } else {
        collapsedItems.add(id)
      }
    }

    // Determine if a TOC item is a parent (has children below it)
    const hasChildren = (item) => {
      const toc = tableOfContents.value
      const idx = toc.findIndex(t => t?.id === item?.id)
      if (idx === -1) return false
      for (let i = idx + 1; i < toc.length; i++) {
        if (toc[i].level > item.level) return true
        if (toc[i].level <= item.level) break
      }
      return false
    }

    // Determine if a TOC item should be visible (none of its ancestors are collapsed)
    const isVisible = (item) => {
      const toc = tableOfContents.value
      const idx = toc.findIndex(t => t?.id === item?.id)
      if (idx === -1) return true
      let currentLevel = item.level
      for (let i = idx - 1; i >= 0; i--) {
        if (toc[i].level < currentLevel) {
          // Found the nearest ancestor at the next higher level
          if (toc[i] && collapsedItems.has(toc[i].id)) return false
          currentLevel = toc[i].level
          if (currentLevel === 1) break
        }
      }
      return true
    }

    const handleTocItemClick = (item) => {
      scrollToSection(item.id)
    }

    const onTocMobileClick = (item) => {
      scrollToSection(item.id)
      showMobileToc.value = false
    }

    const setupScrollObserver = () => {
      // Clean up existing observer
      if (tocObserver.value) {
        tocObserver.value.disconnect()
      }

      const container = contentContainer.value
      if (!container) return

      const headings = Array.from(container.querySelectorAll('h1, h2, h3, h4'))

      const updateActiveHeading = () => {
        const scrollY = window.scrollY
        const viewportHeight = window.innerHeight
        // Find the last heading whose top is above the 30% mark of the viewport
        let active = null
        for (const heading of headings) {
          const rect = heading.getBoundingClientRect()
          if (rect.top <= viewportHeight * 0.3) {
            active = heading
          } else {
            break
          }
        }
        if (active) {
          activeItemId.value = active.id
        } else if (headings.length > 0 && scrollY < 100) {
          // At the very top, select first heading
          activeItemId.value = headings[0].id
        }
      }

      tocObserver.value = { disconnect: () => window.removeEventListener('scroll', updateActiveHeading) }
      window.addEventListener('scroll', updateActiveHeading, { passive: true })
      // Run once immediately
      updateActiveHeading()
    }

    // Global helpers for rendered HTML interactions
    window.playHandbookAudio = (url) => {
      if (!url || !audioPlayer.value) return
      audioPlayer.value.src = url
      audioPlayer.value.play()
    }

    window.openHandbookImage = (url) => {
      if (!url) return
      modalImageUrl.value = url
      showImageModal.value = true
    }

    const closeImageModal = () => {
      showImageModal.value = false
      modalImageUrl.value = ''
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
      if (!handbook.value || !handbook.value.id || !currentUser.value) return false
      return handbook.value.user_id === currentUser.value.id || currentUser.value.role === 'admin'
    })

    const canRerender = computed(() => {
      if (!handbook.value || !handbook.value.id || !currentUser.value) return false
      return handbook.value.user_id === currentUser.value.id || currentUser.value.role === 'admin'
    })

    const isMultiPage = computed(() => handbook.value?.has_pages === 1)

    const currentPageIndex = computed(() => {
      if (!pages.value.length || !currentPageId.value) return 0
      return pages.value.findIndex(p => p?.id === currentPageId.value)
    })

    const prevPage = computed(() => {
      const idx = currentPageIndex.value
      return idx > 0 ? pages.value[idx - 1] : null
    })

    const nextPage = computed(() => {
      const idx = currentPageIndex.value
      return idx < pages.value.length - 1 ? pages.value[idx + 1] : null
    })

    const handleRerender = async () => {
      try {
        loading.value = true
        const rerenderResult = await handbooksApi.rerender(props.id)
        if (!rerenderResult.success) {
          console.error('Rerender failed:', rerenderResult.error || rerenderResult.message)
          alert(t('rerender_failed'))
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

    const goToPage = (pageId) => {
      const queryStr = route.value.query.target_lang ? '?target_lang=' + route.value.query.target_lang : ''
      if (pageId) {
        router.push(`/handbooks/${props.id}/pages/${pageId}${queryStr}`)
      } else {
        router.push(`/handbooks/${props.id}${queryStr}`)
      }
    }

    const onPageMobileClick = (page) => {
      if (page) {
        goToPage(page.id)
      } else {
        goToPage(null)
      }
      showMobileToc.value = false
    }

    const goToNewPage = () => {
      router.push(`/handbooks/${props.id}/pages/new`)
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString()
    }

    // Capture click events during the capture phase to intercept handbook images and stop propagation
    const captureImageClick = (e) => {
      const target = e.target
      if (target && target.tagName && target.tagName.toLowerCase() === 'img' && target.classList.contains('handbook-image-expression')) {
        e.stopPropagation()
        e.preventDefault()
        if (window.openHandbookImage) {
          window.openHandbookImage(target.src)
        }
      }
    }

    onMounted(() => {
      fetchInitialData()
      window.addEventListener('handbook-expression-click', handleExpressionClick)
      window.addEventListener('click', captureImageClick, true)
    })

    watch(() => handbook.value, (newHandbook) => {
      if (newHandbook && newHandbook.id) {
        console.log('[HandbookView] Setting document title with:', {
          rendered_title: newHandbook.rendered_title,
          title: newHandbook.title,
          hasId: !!newHandbook.id
        })
        document.title = `${newHandbook.rendered_title || newHandbook.title || 'Handbook'} - langmap`
      }
    })

    // Watch for route changes (navigating between pages in the same handbook)
    watch(() => props.id, (newId, oldId) => {
      if (newId !== oldId) {
        isInitialized.value = false
        fetchInitialData()
      }
    })

    watch(() => props.pageId, (newPageId, oldPageId) => {
      if (newPageId !== oldPageId) {
        fetchInitialData()
      }
    })

    watch(() => handbook.value?.rendered_content, (newContent) => {
      if (newContent) {
        parseTableOfContents()
      }
    })

    onUnmounted(() => {
      window.removeEventListener('handbook-expression-click', handleExpressionClick)
      window.removeEventListener('click', captureImageClick, true)
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
      showMobileToc,
      collapsedItems,
      toggleCollapse,
      hasChildren,
      isVisible,
      handleTocItemClick,
      onTocMobileClick,
      showImageModal,
      modalImageUrl,
      closeImageModal,
      pages,
      currentPageId,
      isMultiPage,
      currentPageIndex,
      prevPage,
      nextPage,
      goToPage,
      goToNewPage
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

.toc-item.toc-level-4 {
  padding-left: 2.75rem;
  font-size: 0.75rem;
  color: #9ca3af;
}

.toc-item {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.toc-text {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.toc-toggle {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  padding: 0.125rem;
  border-radius: 0.25rem;
  color: #9ca3af;
  cursor: pointer;
}

.toc-toggle:hover {
  color: #6b7280;
  background-color: #e5e7eb;
}

.toc-toggle-icon {
  width: 0.875rem;
  height: 0.875rem;
  transition: transform 0.2s ease;
}

.toc-toggle-icon.collapsed {
  transform: rotate(-90deg);
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

.toc-item.toc-level-4.active {
  padding-left: 2.625rem;
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
