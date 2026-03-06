<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
    <div v-if="loading" class="flex justify-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="handbook" class="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-200">
      <!-- Header -->
      <div class="flex justify-between items-start gap-6 pb-6 border-b border-gray-100">
        <div class="space-y-1.5 flex-1">
          <h1 class="text-2xl font-bold text-gray-800" v-html="handbook.rendered_title || handbook.title"></h1>
          <p v-if="handbook.rendered_description || handbook.description" class="text-sm text-gray-500 max-w-2xl leading-relaxed" 
             v-html="handbook.rendered_description || handbook.description"></p>
          <p class="text-[11px] text-gray-400">{{ $t('last_updated') }}: {{ formatDate(handbook.updated_at) }}</p>
        </div>

        <!-- Language Switcher -->
        <div class="flex items-center gap-2 flex-shrink-0">
          <span class="text-xs text-gray-400">{{ $t('learn_in') }}</span>
          <select v-model="instructionLanguage"
            class="border border-gray-200 rounded-lg text-xs text-gray-600 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 py-1.5 px-2 bg-white cursor-pointer">
            <option v-for="lang in sortedLanguages" :key="lang.code" :value="lang.code">
              {{ lang.name }}
            </option>
          </select>
        </div>

        <!-- Edit Button -->
        <button v-if="canEdit" @click="goToEdit"
          class="px-4 py-2 text-sm border border-gray-200 rounded-lg text-gray-600 hover:text-blue-600 hover:bg-blue-50 transition-colors">
          {{ $t('edit_handbook') }}
        </button>
      </div>

      <!-- Content -->
      <div class="prose prose-blue prose-headings:text-gray-800 prose-p:text-gray-600 prose-strong:text-gray-700 max-w-none leading-loose py-6 markdown-body"
           v-html="handbook.rendered_content || handbook.content"></div>

      <!-- Audio Player Placeholder (Hidden) -->
      <audio ref="audioPlayer" class="hidden"></audio>
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
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { getHandbookById } from '../services/handbookService'
import { fetchLanguages } from '../services/languageService'

export default {
  name: 'HandbookView',
  props: ['id'],
  setup(props) {
    const router = useRouter()

    // State
    const handbook = ref(null)
    const languages = ref([])
    const instructionLanguage = ref(localStorage.getItem('instructionLanguage') || 'zh-CN')
    const loading = ref(true)
    const audioPlayer = ref(null)
    const currentUser = ref(null)

    const fetchInitialData = async () => {
      loading.value = true
      try {
        // Fetch languages if not loaded
        if (languages.value.length === 0) {
          languages.value = await fetchLanguages()
        }

        // Fetch handbook with pre-rendered content from backend
        const data = await getHandbookById(props.id, instructionLanguage.value)
        
        if (data) {
          handbook.value = data
        }

        // Auth check for edit button
        const userStr = localStorage.getItem('user')
        if (userStr) currentUser.value = JSON.parse(userStr)

      } catch (error) {
        console.error('Failed to load handbook data:', error)
      } finally {
        loading.value = false
      }
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

    // Watch for instruction language changes to re-fetch pre-rendered content from backend
    watch(instructionLanguage, (newLang) => {
      localStorage.setItem('instructionLanguage', newLang)
      fetchInitialData()
    })

    const canEdit = computed(() => {
      if (!handbook.value || !currentUser.value) return false
      return handbook.value.user_id === currentUser.value.id || currentUser.value.role === 'admin'
    })

    const sortedLanguages = computed(() => {
      return [...languages.value].sort((a, b) => a.name.localeCompare(b.name))
    })

    const goToEdit = () => {
      router.push(`/handbooks/${props.id}/edit`)
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString()
    }

    onMounted(fetchInitialData)

    return {
      handbook,
      loading,
      instructionLanguage,
      sortedLanguages,
      audioPlayer,
      canEdit,
      goToEdit,
      formatDate
    }
  }
}
</script>
