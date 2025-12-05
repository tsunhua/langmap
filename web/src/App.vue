<template>
  <div id="app" class="min-h-screen flex flex-col">
    <header class="py-6 px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between max-w-7xl mx-auto">
        <router-link to="/" class="no-underline">
          <h1 class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent font-poppins">
            LangMap
          </h1>
        </router-link>
        <div class="flex items-center gap-6">
          <nav class="flex items-center gap-6">
            <router-link 
              to="/" 
              class="text-slate-600 hover:text-slate-900 font-medium transition-colors"
              active-class="text-blue-600"
            >
              {{ $t('nav.home') }}
            </router-link>
            <router-link 
              to="/search" 
              class="text-slate-600 hover:text-slate-900 font-medium transition-colors"
              active-class="text-blue-600"
            >
              {{ $t('nav.search') }}
            </router-link>
          </nav>
          
          <!-- Combined Auth/Profile Button -->
          <div class="relative" ref="authDropdown">
            <button 
              v-if="isLoggedIn"
              @click="toggleUserDropdown" 
              class="flex items-center text-slate-600 hover:text-slate-900 font-medium transition-colors px-2 py-1 rounded-md hover:bg-slate-100"
              aria-haspopup="true"
              :aria-expanded="userDropdownOpen"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span class="mr-1">{{ $t('nav.profile') }}</span>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="userDropdownOpen ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'" />
              </svg>
            </button>
            
            <button
              v-else
              @click="$router.push('/login')"
              class="flex items-center text-slate-600 hover:text-slate-900 font-medium transition-colors px-2 py-1 rounded-md hover:bg-slate-100"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
              </svg>
              <span class="mr-1">{{ $t('nav.login') }}</span>
            </button>
            
            <!-- User Dropdown Menu -->
            <div 
              v-if="isLoggedIn"
              v-show="userDropdownOpen" 
              class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 ring-1 ring-black ring-opacity-5 z-50"
              role="menu"
            >
              <router-link
                to="/profile"
                class="block px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                role="menuitem"
                @click="userDropdownOpen = false"
              >
                {{ $t('nav.profile') }}
              </router-link>
              <button
                @click="handleLogout"
                class="block w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                role="menuitem"
              >
                {{ $t('nav.logout') }}
              </button>
            </div>
          </div>
          
          <!-- Language selector dropdown -->
          <div class="relative" ref="langDropdown">
            <button 
              @click="toggleLangDropdown" 
              class="flex items-center text-slate-600 hover:text-slate-900 font-medium transition-colors px-2 py-1 rounded-md hover:bg-slate-100"
              aria-haspopup="true"
              :aria-expanded="langDropdownOpen"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
              </svg>
              <span class="mr-1">{{ currentLanguageName }}</span>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="langDropdownOpen ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'" />
              </svg>
            </button>
            
            <div 
              v-show="langDropdownOpen" 
              class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 ring-1 ring-black ring-opacity-5 z-50"
              role="menu"
            >
              <button
                v-for="(lang, code) in availableLanguages"
                :key="code"
                @click="switchLanguage(code)"
                class="block w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                :class="{ 'bg-blue-50 text-blue-600': code === currentLanguage }"
                role="menuitem"
              >
                {{ lang }}
                <span v-if="code === currentLanguage" class="float-right">
                  ✓
                </span>
              </button>
              <!-- Add new language option -->
              <div class="border-t border-slate-200 mt-1 pt-1">
                <button
                  @click="showAddLanguageModal = true"
                  class="block w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-100 font-medium"
                  role="menuitem"
                >
                  + Add New Language
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
    
    <!-- Add Language Modal -->
    <AddLanguageModal 
      :visible="showAddLanguageModal"
      :adding-language="addingLanguage"
      @close="showAddLanguageModal = false"
      @add-language="handleAddLanguage"
    />
    
    <main class="py-6 flex-1">
      <router-view />
    </main>
    <footer class="py-6 border-t border-slate-200 text-center text-slate-500 text-sm mt-auto">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <p>{{ $t('footer.copyright', { year: new Date().getFullYear() }) }}</p>
      </div>
    </footer>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
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
    const userDropdownOpen = ref(false)
    const userDropdown = ref(null)
    const router = useRouter()

    const { t, locale } = useI18n();
    
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
    
    // Toggle language dropdown
    const toggleLangDropdown = () => {
      langDropdownOpen.value = !langDropdownOpen.value
    }
    
    // Toggle user dropdown
    const toggleUserDropdown = () => {
      userDropdownOpen.value = !userDropdownOpen.value
    }
    
    // Switch language
    const switchLanguage = async (langCode) => {
      locale.value = langCode
      localStorage.setItem('langmap-lang', langCode)
      langDropdownOpen.value = false
      
      // If it's a dynamic language, load its translations
      const { loadLanguage } = await import('./i18n.js')
      await loadLanguage(langCode)
    }
    
    // Handle logout
    const handleLogout = async () => {
      try {
        const token = localStorage.getItem('authToken')
        if (token) {
          // Call logout API
          await fetch('/api/v1/auth/logout', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${token}`
            }
          })
        }
        
        // Remove token and update state
        localStorage.removeItem('authToken')
        isLoggedIn.value = false
        currentUser.value = {}
        userDropdownOpen.value = false
        
        // Notify about auth state change
        window.dispatchEvent(new CustomEvent('auth-state-changed', { detail: { isLoggedIn: false } }))
        
        // Redirect to login
        router.push('/login')
      } catch (error) {
        console.error('Logout error:', error)
      }
    }
    
    // Close dropdowns when clicking outside
    const handleClickOutside = (event) => {
      if (langDropdown.value && !langDropdown.value.contains(event.target)) {
        langDropdownOpen.value = false
      }
      
      if (userDropdown.value && !userDropdown.value.contains(event.target)) {
        userDropdownOpen.value = false
      }
    }
    
    // Handle add language
    const handleAddLanguage = async (language) => {
      try {
        // Add to available languages
        availableLanguages.value[language.code] = language.native_name || language.name
        
        // Switch to the new language
        await switchLanguage(language.code)
        
        // Close modal
        showAddLanguageModal.value = false
      } catch (error) {
        console.error('Error handling added language:', error)
        alert('Failed to process the new language. Please try again.')
      }
    }
    
    // Check if user is logged in
    const checkAuthStatus = async () => {
      const token = localStorage.getItem('authToken')
      if (token) {
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
          } else {
            // If unauthorized, remove token
            if (response.status === 401) {
              localStorage.removeItem('authToken')
              isLoggedIn.value = false
              currentUser.value = {}
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
    
    // Load saved language preference
    onMounted(async () => {
      // Check auth status
      await checkAuthStatus()
      
      // Listen for auth state changes
      window.addEventListener('auth-state-changed', handleAuthStateChange)
      
      // Fetch dynamic languages from backend
      try {
        const languages = await fetchLanguages()
        languages.forEach(lang => {
          availableLanguages.value[lang.code] = lang.native_name || lang.name
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
    
    onUnmounted(() => {
      document.removeEventListener('click', handleClickOutside)
      window.removeEventListener('auth-state-changed', handleAuthStateChange)
    })
    
    return {
      langDropdownOpen,
      langDropdown,
      userDropdownOpen,
      userDropdown,
      availableLanguages,
      currentLanguageName,
      toggleLangDropdown,
      toggleUserDropdown,
      switchLanguage,
      handleLogout,
      currentLanguage: locale,
      handleAddLanguage,
      t,
      
      // User state
      isLoggedIn,
      currentUser,
      
      // Language management
      showAddLanguageModal,
      addingLanguage
    }
  }
}
</script>