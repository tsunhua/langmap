<template>
  <div v-if="visible" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full">
      <div class="px-6 py-4 border-b border-slate-200">
        <h3 class="text-lg font-medium text-slate-900">{{ $t('create.addLanguage') }}</h3>
      </div>
      <form @submit.prevent="handleAddLanguage" class="px-6 py-4">
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.languageCode') }}</label>
          <input 
            v-model="formData.code" 
            type="text" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            :placeholder="$t('create.languageCodePlaceholder')"
            required
          >
          <p class="mt-1 text-xs text-slate-500">{{ $t('create.languageCodeHelp') }}</p>
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.languageName') }}</label>
          <input 
            v-model="formData.name" 
            type="text" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            :placeholder="$t('create.languageNamePlaceholder')"
            required
          >
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.nativeName') }}</label>
          <input 
            v-model="formData.native_name" 
            type="text" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            :placeholder="$t('create.nativeNamePlaceholder')"
          >
        </div>
        <div class="mb-6">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create.textDirection') }}</label>
          <select 
            v-model="formData.direction" 
            class="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="ltr">{{ $t('create.ltr') }}</option>
            <option value="rtl">{{ $t('create.rtl') }}</option>
          </select>
        </div>
        <div class="flex justify-end gap-3">
          <button 
            type="button" 
            @click="close"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-md transition-colors"
          >
            {{ $t('create.cancel') }}
          </button>
          <button 
            type="submit" 
            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md transition-colors"
            :disabled="addingLanguage"
          >
            {{ addingLanguage ? $t('create.addingLanguage') : $t('create.addLanguage') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import { ref, reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { createLanguage } from '../services/languageService.js'

export default {
  name: 'AddLanguageModal',
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    addingLanguage: {
      type: Boolean,
      default: false
    }
  },
  emits: ['close', 'add-language'],
  setup(props, { emit }) {
    const { t } = useI18n()
    
    const formData = reactive({
      code: '',
      name: '',
      native_name: '',
      direction: 'ltr'
    })
    
    const handleAddLanguage = async () => {
      if (!formData.code || !formData.name) return
      
      try {
        const languageObj = await createLanguage(formData)
        emit('add-language', languageObj)
        
        // Reset form
        formData.code = ''
        formData.name = ''
        formData.native_name = ''
        formData.direction = 'ltr'
      } catch (error) {
        console.error('Error adding language:', error)
        alert(t('create.addLanguageFailed'))
      }
    }
    
    const close = () => {
      emit('close')
    }
    
    // Reset form when modal is closed
    watch(() => props.visible, (newVal) => {
      if (!newVal) {
        formData.code = ''
        formData.name = ''
        formData.native_name = ''
        formData.direction = 'ltr'
      }
    })
    
    return {
      formData,
      handleAddLanguage,
      close
    }
  }
}
</script>