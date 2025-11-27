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
          
          <!-- Language selector dropdown -->
          <div class="relative" ref="langDropdown">
            <button 
              @click="toggleLangDropdown" 
              class="flex items-center text-slate-600 hover:text-slate-900 font-medium transition-colors"
              aria-haspopup="true"
              :aria-expanded="langDropdownOpen"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
              </svg>
              {{ currentLanguageName }}
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
    <div v-if="showAddLanguageModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full">
        <div class="px-6 py-4 border-b border-slate-200">
          <h3 class="text-lg font-medium text-slate-900">Add New Language</h3>
        </div>
        <form @submit.prevent="addNewLanguage" class="px-6 py-4">
          <div class="mb-4">
            <label class="block text-sm font-medium text-slate-700 mb-1">Language Code</label>
            <input 
              v-model="newLanguage.code" 
              type="text" 
              class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="e.g. custom-lang, toki-pona"
              required
            >
            <p class="mt-1 text-xs text-slate-500">Custom code for your language (can be non-standard)</p>
          </div>
          <div class="mb-4">
            <label class="block text-sm font-medium text-slate-700 mb-1">Language Name</label>
            <input 
              v-model="newLanguage.name" 
              type="text" 
              class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="e.g. Custom Language"
              required
            >
          </div>
          <div class="mb-4">
            <label class="block text-sm font-medium text-slate-700 mb-1">Native Name</label>
            <input 
              v-model="newLanguage.native_name" 
              type="text" 
              class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="e.g. Native Language Name"
            >
          </div>
          <div class="mb-6">
            <label class="block text-sm font-medium text-slate-700 mb-1">Text Direction</label>
            <select 
              v-model="newLanguage.direction" 
              class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="ltr">Left to Right (LTR)</option>
              <option value="rtl">Right to Left (RTL)</option>
            </select>
          </div>
          <div class="flex justify-end gap-3">
            <button 
              type="button" 
              @click="showAddLanguageModal = false"
              class="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-md transition-colors"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md transition-colors"
              :disabled="addingLanguage"
            >
              {{ addingLanguage ? 'Adding...' : 'Add Language' }}
            </button>
          </div>
        </form>
      </div>
    </div>
    
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
import { fetchLanguages, createLanguage } from './services/languageService.js'

export default {
  name: 'App',
  setup() {
    const { locale } = useI18n()
    const langDropdownOpen = ref(false)
    const langDropdown = ref(null)
    
    // Language management
    const showAddLanguageModal = ref(false)
    const addingLanguage = ref(false)
    const newLanguage = ref({
      code: '',
      name: '',
      native_name: '',
      direction: 'ltr'
    })
    
    // Available languages - start with static ones
    const availableLanguages = ref({
      en: 'English',
      'zh-CN': '简体中文',
      'zh-TW': '傳統中文',
      es: 'Español',
      fr: 'Français',
      ja: '日本語'
    })
    
    // Get current language name
    const currentLanguageName = computed(() => {
      return availableLanguages.value[locale.value] || 'English'
    })
    
    // Toggle language dropdown
    const toggleLangDropdown = () => {
      langDropdownOpen.value = !langDropdownOpen.value
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
    
    // Close dropdown when clicking outside
    const handleClickOutside = (event) => {
      if (langDropdown.value && !langDropdown.value.contains(event.target)) {
        langDropdownOpen.value = false
      }
    }
    
    // Add new language
    const addNewLanguage = async () => {
      if (!newLanguage.value.code || !newLanguage.value.name) return
      
      addingLanguage.value = true
      try {
        const language = await createLanguage(newLanguage.value)
        
        // Add to available languages
        availableLanguages.value[language.code] = language.native_name || language.name
        
        // Switch to the new language
        await switchLanguage(language.code)
        
        // Reset form and close modal
        newLanguage.value = {
          code: '',
          name: '',
          native_name: '',
          direction: 'ltr'
        }
        showAddLanguageModal.value = false
      } catch (error) {
        console.error('Error adding language:', error)
        alert('Failed to add language. Please try again.')
      } finally {
        addingLanguage.value = false
      }
    }
    
    // Load saved language preference
    onMounted(async () => {
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
        if (!['en', 'zh-CN', 'zh-TW', 'es', 'fr', 'ja'].includes(savedLang)) {
          const { loadLanguage } = await import('./i18n.js')
          await loadLanguage(savedLang)
        }
      }
      
      document.addEventListener('click', handleClickOutside)
    })
    
    onUnmounted(() => {
      document.removeEventListener('click', handleClickOutside)
    })
    
    return {
      langDropdownOpen,
      langDropdown,
      availableLanguages,
      currentLanguageName,
      toggleLangDropdown,
      switchLanguage,
      currentLanguage: locale,
      
      // Language management
      showAddLanguageModal,
      addingLanguage,
      newLanguage,
      addNewLanguage
    }
  }
}
</script>