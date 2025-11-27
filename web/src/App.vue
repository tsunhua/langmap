<template>
  <div id="app" class="flex-1 flex flex-col">
    <header class="py-6 px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between max-w-7xl mx-auto">
        <router-link to="/" class="no-underline">
          <h1 class="text-3xl font-bold text-slate-800 hover:text-blue-600 transition-colors">Langmap</h1>
        </router-link>
        <div class="flex items-center gap-6">
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
            </div>
          </div>
          
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
            <router-link 
              to="/expressions/new" 
              class="inline-flex items-center justify-center px-4 py-2 rounded-md bg-blue-600 text-white hover:bg-blue-700 font-medium transition-colors"
            >
              {{ $t('nav.addExpression') }}
            </router-link>
          </nav>
        </div>
      </div>
    </header>
    <main class="py-6 flex-1">
      <router-view />
    </main>
  </div>
  <footer class="py-6 border-t border-slate-200 text-center text-slate-500 text-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <p>{{ $t('footer.copyright', { year: new Date().getFullYear() }) }}</p>
    </div>
  </footer>
</template>

<script>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'

export default {
  name: 'App',
  setup() {
    const { locale } = useI18n()
    const langDropdownOpen = ref(false)
    const langDropdown = ref(null)
    
    // Available languages
    const availableLanguages = {
      en: 'English',
      'zh-CN': '简体中文',
      'zh-TW': '傳統中文',
      es: 'Español',
      fr: 'Français',
      ja: '日本語'
    }
    
    // Get current language name
    const currentLanguageName = computed(() => {
      return availableLanguages[locale.value] || 'English'
    })
    
    // Toggle language dropdown
    const toggleLangDropdown = () => {
      langDropdownOpen.value = !langDropdownOpen.value
    }
    
    // Switch language
    const switchLanguage = (langCode) => {
      locale.value = langCode
      localStorage.setItem('langmap-lang', langCode)
      langDropdownOpen.value = false
    }
    
    // Close dropdown when clicking outside
    const handleClickOutside = (event) => {
      if (langDropdown.value && !langDropdown.value.contains(event.target)) {
        langDropdownOpen.value = false
      }
    }
    
    // Load saved language preference
    onMounted(() => {
      const savedLang = localStorage.getItem('langmap-lang')
      if (savedLang && availableLanguages[savedLang]) {
        locale.value = savedLang
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
      currentLanguage: locale
    }
  }
}
</script>