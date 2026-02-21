<template>
  <div class="p-6 bg-white rounded-lg shadow-md">
    <h2 class="text-xl font-bold mb-4">Dynamic Language Demo</h2>
    
    <div class="mb-4">
      <p class="mb-2">Current language: {{ locale }}</p>
      <p class="mb-2">Home title: {{ $t('home_title') }}</p>
      <p class="mb-2">Nav home: {{ $t('home') }}</p>
    </div>
    
    <div class="mb-4">
      <label class="block text-sm font-medium text-gray-700 mb-1">Test Translation Key</label>
      <input 
        v-model="testKey" 
        type="text" 
        class="w-full px-3 py-2 border border-gray-300 rounded-md"
        placeholder="Enter translation key, e.g. title"
      >
      <p class="mt-1 text-sm text-gray-500">Translation: {{ $t(testKey) }}</p>
    </div>
    
    <div class="flex gap-2">
      <button 
        @click="loadTestLanguage" 
        class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
      >
        Load Test Language
      </button>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

export default {
  name: 'DynamicLanguageDemo',
  setup() {
    const { locale, t } = useI18n()
    const testKey = ref('')
    
    const loadTestLanguage = async () => {
      // This is just a demonstration - in a real app, this would load from backend
      console.log('This would load a dynamic language in a real implementation')
    }
    
    return {
      locale,
      t,
      testKey,
      loadTestLanguage
    }
  }
}
</script>