<template>
  <div id="app" class="min-h-screen flex flex-col">
    <!-- Mobile sidebar overlay -->
    <div v-if="isMobile && mobileMenuOpen" class="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
      @click="mobileMenuOpen = false"></div>

    <!-- Mobile sidebar -->
    <div v-if="isMobile"
      class="fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform transition-transform duration-300 ease-in-out lg:hidden"
      :class="{ 'translate-x-0': mobileMenuOpen, '-translate-x-full': !mobileMenuOpen }">
      <div class="flex items-center justify-between p-4 border-b">
        <router-link to="/" class="no-underline" @click="mobileMenuOpen = false">
          <h1
            class="text-xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent font-poppins">
            LangMap
          </h1>
        </router-link>
        <button @click="mobileMenuOpen = false" class="p-2 rounded-md text-slate-600 hover:text-slate-900">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      <nav class="p-4">
        <router-link to="/" class="flex items-center gap-2 py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100"
          active-class="text-blue-600 bg-blue-50" @click="mobileMenuOpen = false">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          {{ $t('home') }}
        </router-link>
        <router-link to="/search"
          class="flex items-center gap-2 py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 mt-2"
          active-class="text-blue-600 bg-blue-50" @click="mobileMenuOpen = false">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          {{ $t('search') }}
        </router-link>

        <router-link 
          to="/create-expression" 
          class="flex items-center gap-2 py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 mt-2"
          active-class="text-blue-600 bg-blue-50"
          @click="mobileMenuOpen = false"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          {{ $t('create_title') }}
        </router-link>

        <router-link 
          to="/collections" 
          class="flex items-center gap-2 py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 mt-2"
          active-class="text-blue-600 bg-blue-50"
          @click="mobileMenuOpen = false"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
          </svg>
          {{ $t('collections') }}
        </router-link>
        <router-link 
          to="/handbooks" 
          class="flex items-center gap-2 py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 mt-2"
          active-class="text-blue-600 bg-blue-50"
          @click="mobileMenuOpen = false"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332 0.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5S19.832 5.477 21 6.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332 0.477-4.5 1.253" />
          </svg>
          {{ $t('handbook_title') }}
        </router-link>
        
         <router-link
           to="/languages"
           class="flex items-center gap-2 py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 mt-2"
           active-class="text-blue-600 bg-blue-50"
           @click="mobileMenuOpen = false"
         >
           <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
             <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
           </svg>
           {{ $t('languages_title') }}
         </router-link>

        <!-- Mobile Auth Buttons -->
        <div class="pt-4 mt-4 border-t border-slate-200">
          <template v-if="isLoggedIn">
            <router-link to="/profile"
              class="block py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100"
              @click="mobileMenuOpen = false">
              <div class="flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                {{ $t('profile') }}
              </div>
            </router-link>
            <button @click="handleLogoutMobile"
              class="block w-full text-left py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 mt-2">
              <div class="flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
                </svg>
                {{ $t('logout') }}
              </div>
            </button>
          </template>
          <template v-else>
            <router-link to="/login"
              class="block py-2 px-4 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100"
              @click="mobileMenuOpen = false">
              <div class="flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
                </svg>
                {{ $t('login') }}
              </div>
            </router-link>
          </template>
        </div>
      </nav>
    </div>

     <header class="py-4 px-4 sm:px-6 lg:px-8">
       <div class="flex items-center justify-between max-w-7xl mx-auto">
        <div class="flex items-center gap-6">
          <!-- Mobile menu button -->
          <button v-if="isMobile" @click="mobileMenuOpen = true"
            class="p-2 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 lg:hidden">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>

          <router-link to="/" class="no-underline ml-8 lg:ml-12">
            <h1
              class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent font-poppins">
              LangMap
              <span
                class="ml-1 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                Beta
              </span>
            </h1>
          </router-link>

          <!-- Desktop navigation -->
          <nav class="hidden lg:flex items-center gap-6 mt-2">
            <router-link to="/" class="flex items-center gap-1.5 font-medium transition-colors text-slate-600 hover:text-slate-900"
              active-class="!text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              {{ $t('home') }}
            </router-link>
            <router-link to="/search" class="flex items-center gap-1.5 font-medium transition-colors text-slate-600 hover:text-slate-900"
              active-class="!text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              {{ $t('search') }}
            </router-link>

            <!-- create-expression -->
            <router-link to="/create-expression" class="flex items-center gap-1.5 font-medium transition-colors text-slate-600 hover:text-slate-900"
              active-class="!text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              {{ $t('create_title') }}
            </router-link>

            <!-- Resources Dropdown -->
            <div class="relative" ref="resourcesDropdown">
              <button @click="toggleResourcesDropdown"
                class="flex items-center gap-1.5 font-medium transition-colors text-slate-600 hover:text-slate-900 px-2 py-1 rounded-md hover:bg-slate-100"
                aria-haspopup="true" :aria-expanded="resourcesDropdownOpen">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
                <span>{{ $t('resources') || 'Resources' }}</span>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    :d="resourcesDropdownOpen ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'" />
                </svg>
              </button>

              <div v-show="resourcesDropdownOpen"
                class="absolute left-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 ring-1 ring-black ring-opacity-5 z-50"
                role="menu">
                <router-link to="/collections" class="flex items-center px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                  role="menuitem" @click="resourcesDropdownOpen = false">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                  </svg>
                  {{ $t('collections') || 'Collections' }}
                </router-link>
                <router-link to="/handbooks" class="flex items-center px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                  role="menuitem" @click="resourcesDropdownOpen = false">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332 0.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5S19.832 5.477 21 6.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332 0.477-4.5 1.253" />
                  </svg>
                  {{ $t('handbook_title') }}
                </router-link>
                <router-link to="/languages" class="flex items-center px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                  role="menuitem" @click="resourcesDropdownOpen = false">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                  </svg>
                  {{ $t('languages_title') }}
                </router-link>
              </div>
            </div>

          </nav>
        </div>

        <div class="flex items-center ml-auto ml-12 mt-2">
          <!-- Combined Auth/Profile Button - Hidden on mobile as it's in a sidebar -->
          <div class="hidden lg:block">
            <router-link v-if="isLoggedIn" to="/profile"
              class="flex items-center text-slate-600 hover:text-slate-900 font-medium transition-colors px-2 py-1 rounded-md hover:bg-slate-100"
              active-class="!text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span>{{ $t('profile') }}</span>
            </router-link>

            <router-link v-else to="/login"
              class="flex items-center text-slate-600 hover:text-slate-900 font-medium transition-colors px-2 py-1 rounded-md hover:bg-slate-100"
              active-class="!text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
              </svg>
              <span>{{ $t('login') }}</span>
            </router-link>
          </div>

          <!-- Language selector dropdown -->
          <div class="relative ml-6" ref="langDropdown">
            <button @click="toggleLangDropdown"
              class="flex items-center text-slate-600 hover:text-slate-900 font-medium transition-colors px-2 py-1 rounded-md hover:bg-slate-100"
              aria-haspopup="true" :aria-expanded="langDropdownOpen">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
              </svg>
              <span class="mr-1">{{ currentLanguageName }}</span>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  :d="langDropdownOpen ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'" />
              </svg>
            </button>

            <div v-show="langDropdownOpen"
              class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 ring-1 ring-black ring-opacity-5 z-50"
              role="menu">
              <button v-for="(lang, code) in availableLanguages" :key="code" @click="switchLanguage(code)"
                class="block w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                :class="{ 'bg-blue-50 text-blue-600': code === currentLanguage }" role="menuitem">
                {{ lang }}
                <span v-if="code === currentLanguage" class="float-right">
                  ✓
                </span>
              </button>

              <!-- Assist Translation Link -->
              <div class="border-t border-slate-200 mt-1 pt-1">
                <router-link to="/translate-interface"
                  class="block w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                  role="menuitem" @click="langDropdownOpen = false">
                  {{ $t('assist_translation') }}
                </router-link>
              </div>

              <!-- Add new language option -->
              <div class="border-t border-slate-200 mt-1 pt-1">
                <button @click="handleAddLanguageClick"
                  class="block w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                  role="menuitem">
                  {{ $t('add_language') }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>

    <!-- Add Language Modal -->
    <AddLanguageModal :visible="showAddLanguageModal" :adding-language="addingLanguage"
      @close="showAddLanguageModal = false" @add-language="handleAddLanguage" />

    <main class="py-6 flex-1">
      <router-view />
    </main>
    <footer class="py-6 border-t border-slate-200 text-center text-slate-500 text-sm mt-auto">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-center gap-4">
          <p>{{ $t('footer_copyright', { year: new Date().getFullYear() }) }}</p>
          <span>|</span>
          <router-link to="/about" class="hover:text-slate-700 transition-colors">
            {{ $t('about') }}
          </router-link>
        </div>
      </div>
    </footer>
  </div>
</template>

<script>
import { ref, onMounted, onBeforeUnmount, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter, useRoute } from 'vue-router'
import { fetchLanguages, createLanguage } from './services/languageService.js'
import AddLanguageModal from './components/AddLanguageModal.vue'

export default {
  name: 'App',
  components: {
    AddLanguageModal
  },
  setup() {
    // const { locale } = useI18n()
    const langDropdownOpen = ref(false)
    const langDropdown = ref(null)
    const resourcesDropdownOpen = ref(false)
    const resourcesDropdown = ref(null)
    const router = useRouter()
    const mobileMenuOpen = ref(false)
    const isMobile = ref(false)
    const route = useRoute()

    const { t, locale } = useI18n();

    // Update document title based on current route and language
    const updateDocumentTitle = () => {
      // For home page, use home.title; for others, use nav.* titles
      let pageTitle;
      if (route.name === 'Home') {
        pageTitle = t('home_title');
        pageTitle = `LangMap - ${pageTitle}`;
      } else {
        const routeTitleMap = {
          'Search': t('search'),
          'AboutUs': t('about'),
          'Login': t('login'),
          'Profile': t('profile'),
          'Collections': t('collections'),
          'HandbookList': t('handbook_title'),
          'HandbookView': t('handbook_title'),
          'HandbookEdit': t('edit_handbook')
        };
        pageTitle = routeTitleMap[route.name] || t('home');
        pageTitle = `${pageTitle} - LangMap`;
      }

      document.title = pageTitle;
    }

    // Watch for route and language changes to update document title
    watch([route, locale], updateDocumentTitle)

    // User state
    const isLoggedIn = ref(false)
    const currentUser = ref({})

    // Language management
    const showAddLanguageModal = ref(false)
    const addingLanguage = ref(false)

    // Available languages - start with static ones
    const availableLanguages = ref({
      'en-US': 'English',
      'zh-CN': '中文 (北京)',
      'zh-TW': '中文 (台北)',
      'es': 'Español',
      'fr': 'Français',
      'ja': '日本語'
    })

    // Get current language name
    const currentLanguageName = computed(() => {
      return availableLanguages.value[locale.value] || 'English'
    })

    // Check if device is mobile
    const checkIsMobile = () => {
      isMobile.value = window.innerWidth < 1024 // Tailwind's lg breakpoint
    }

    // Toggle language dropdown
    const toggleLangDropdown = () => {
      langDropdownOpen.value = !langDropdownOpen.value
    }

    // Toggle resources dropdown
    const toggleResourcesDropdown = () => {
      resourcesDropdownOpen.value = !resourcesDropdownOpen.value
    }

    // Switch language
    const switchLanguage = async (langCode) => {

      // Save preference
      localStorage.setItem('langmap-lang', langCode)
      langDropdownOpen.value = false

      // If it's a dynamic language, load its translations FIRST
      const { loadLanguage } = await import('./i18n.js')
      await loadLanguage(langCode)

      // THEN switch the locale
      locale.value = langCode

      // Refresh available languages to only show active ones
      try {
        const languages = await fetchLanguages(1) // 只获取活跃的语言
        const newAvailableLanguages = {}
        languages.forEach(lang => {
          newAvailableLanguages[lang.code] = lang.native_name || lang.name
        })
        availableLanguages.value = newAvailableLanguages
      } catch (error) {
        console.error('Failed to refresh available languages:', error)
      }
    }

    // Handle logout
    const handleLogout = async () => {
      try {
        const token = localStorage.getItem('authToken')
        if (token) {
          // Call logout API
          const response = await fetch('/api/v1/auth/logout', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${token}`
            }
          })

          // If token is invalid/expired, still proceed with local logout
          if (response.status === 401) {
            console.warn('Token expired during logout');
          }
        }

        // Remove token and user info from localStorage
        localStorage.removeItem('authToken')
        localStorage.removeItem('user')
        isLoggedIn.value = false
        currentUser.value = {}
        userDropdownOpen.value = false

        // Notify about auth state change
        window.dispatchEvent(new CustomEvent('auth-state-changed', { detail: { isLoggedIn: false } }))

        // Redirect to login
        router.push('/login')
      } catch (error) {
        console.error('Logout error:', error)
        // Even if API fails, still do local logout
        localStorage.removeItem('authToken')
        localStorage.removeItem('user')
        isLoggedIn.value = false
        currentUser.value = {}
        router.push('/login')
      }
    }

    // Handle logout for mobile
    const handleLogoutMobile = async () => {
      mobileMenuOpen.value = false
      await handleLogout()
    }

    // Close dropdowns when clicking outside
    const handleClickOutside = (event) => {
      if (langDropdown.value && !langDropdown.value.contains(event.target)) {
        langDropdownOpen.value = false
      }

      if (resourcesDropdown.value && !resourcesDropdown.value.contains(event.target)) {
        resourcesDropdownOpen.value = false
      }
    }

    // Handle add language
    const handleAddLanguage = async (language) => {
      // 检查用户是否已登录
      if (!isLoggedIn.value) {
        router.push('/login');
        return;
      }

      try {
        // Add to available languages
        availableLanguages.value[language.code] = language.native_name || language.name

        // Close modal
        showAddLanguageModal.value = false
      } catch (error) {
        console.error('Error handling added language:', error)
        alert('Failed to process the new language. Please try again.')
      }
    }

    // 处理添加语言点击事件
    const handleAddLanguageClick = () => {
      // 检查用户是否已经登录
      if (!isLoggedIn.value) {
        // 如果没有登录则跳转到登录页面
        router.push('/login');
        return;
      }

      // 如果已经登录则显示添加语言模态框
      showAddLanguageModal.value = true;
    }

    // Check if user is logged in
    const checkAuthStatus = async () => {
      const token = localStorage.getItem('authToken')
      const userStr = localStorage.getItem('user')

      if (token) {
        // First, try to load user from localStorage for immediate display
        if (userStr) {
          try {
            currentUser.value = JSON.parse(userStr)
            isLoggedIn.value = true
          } catch (e) {
            console.error('Failed to parse user from localStorage:', e)
          }
        }

        // Then verify with the server
        try {
          const response = await fetch('/api/v1/users/me', {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          })

          const data = await response.json()

          if (response.ok) {
            isLoggedIn.value = true
            currentUser.value = data.data
            // Update localStorage with fresh data
            localStorage.setItem('user', JSON.stringify(data.data))
          } else {
            // If unauthorized, remove token
            if (response.status === 401) {
              localStorage.removeItem('authToken')
              localStorage.removeItem('user')
              isLoggedIn.value = false
              currentUser.value = {}
              // Redirect to login
              router.push('/login')
            }
          }
        } catch (error) {
          console.error('Error checking auth status:', error)
        }
      } else {
        isLoggedIn.value = false
        currentUser.value = {}
      }
    }

    // Handle auth state change events
    const handleAuthStateChange = (event) => {
      if (event.detail.isLoggedIn) {
        // User just logged in, refresh auth status
        checkAuthStatus()
      } else {
        // User logged out
        isLoggedIn.value = false
        currentUser.value = {}
      }
    }

    // Initialize app
    const initializeApp = async () => {
      try {
        // Check authentication status
        await checkAuthStatus()

        // Fetch available languages (only active ones)
        const languages = await fetchLanguages(1) // 只获取活跃的语言

        const newAvailableLanguages = {}
        languages.forEach(lang => {
          newAvailableLanguages[lang.code] = lang.native_name || lang.name
        })
        availableLanguages.value = newAvailableLanguages

        // Load dynamic language if needed
        const { loadLanguage } = await import('./i18n.js')
        await loadLanguage(locale.value)

        console.log('[App] App initialized successfully')
      } catch (error) {
        console.error('[App] Failed to initialize app:', error)
      }
    }

    // Load saved language preference
    onMounted(async () => {
      // Check if device is mobile
      checkIsMobile()
      window.addEventListener('resize', checkIsMobile)

      // Initialize app
      await initializeApp()

      // Set initial document title
      updateDocumentTitle()

      // Listen for auth state changes
      window.addEventListener('auth-state-changed', handleAuthStateChange)

      // Fetch dynamic languages from backend and filter out inactive ones
      try {
        const languages = await fetchLanguages()

        languages.forEach(lang => {
          // Only add active languages to availableLanguages
          if (lang.is_active === 1) {
            availableLanguages.value[lang.code] = lang.native_name || lang.name
          }
        })
      } catch (error) {
        console.error('Error fetching languages:', error)
      }

      // Load saved language preference
      const savedLang = localStorage.getItem('langmap-lang')

      if (savedLang && availableLanguages.value[savedLang]) {
        locale.value = savedLang

        // If it's a dynamic language, load its translations
        if (!['en-US', 'zh-CN', 'zh-TW', 'es', 'fr', 'ja'].includes(savedLang)) {
          const { loadLanguage } = await import('./i18n.js')
          await loadLanguage(savedLang)
        }
      }

      document.addEventListener('click', handleClickOutside)
    })

    onBeforeUnmount(() => {
      document.removeEventListener('click', handleClickOutside)
      window.removeEventListener('auth-state-changed', handleAuthStateChange)
      window.removeEventListener('resize', checkIsMobile)
    })

    return {
      // Reactive refs
      langDropdownOpen,
      langDropdown,
      resourcesDropdownOpen,
      resourcesDropdown,
      isLoggedIn,
      currentUser,
      showAddLanguageModal,
      addingLanguage,
      availableLanguages,
      currentLanguageName,
      mobileMenuOpen,
      isMobile,

      // Methods
      toggleLangDropdown,
      toggleResourcesDropdown,
      switchLanguage,
      handleLogout,
      handleLogoutMobile,
      handleAddLanguage,
      handleAddLanguageClick,

      // Other
      currentLanguage: locale,
      t
    }
  }
}
</script>