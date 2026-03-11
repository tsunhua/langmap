<template>
  <div v-if="visible" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" @click.self="close">
    <div class="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[80vh] overflow-hidden flex flex-col">
      <div class="px-6 py-4 border-b border-slate-200 flex justify-between items-center">
        <h3 class="text-lg font-bold text-slate-800">{{ $t('expression_group_details') }}</h3>
        <div class="flex items-center gap-2">
          <button 
            @click="goToDetail"
            class="px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            {{ $t('more') }}
          </button>
          <button @click="close" class="text-slate-400 hover:text-slate-600 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>

      <div class="flex-1 overflow-y-auto p-4">
        <div v-if="loading" class="flex items-center justify-center py-8">
          <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>

        <div v-else>
          
          <button 
            v-if="!showNewRow"
            @click="addNewRow"
            class="w-full py-2 mb-3 border-2 border-dashed border-slate-300 text-slate-500 hover:border-blue-400 hover:text-blue-600 rounded-lg transition-colors flex items-center justify-center gap-1"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            {{ $t('add_row') }}
          </button>

          <div class="border border-slate-200 rounded-lg overflow-hidden">
            <table class="w-full">
              <thead class="bg-slate-50">
                <tr>
                  <th class="px-3 py-2 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider w-1/3">{{ $t('language') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider">{{ $t('expression') }}</th>
                  <th class="px-3 py-2 w-16"></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="expr in expressions" :key="expr.id" class="border-t border-slate-100">
                  <td class="px-3 py-2">
                    <span class="text-sm text-slate-600">{{ getLanguageName(expr.language_code) }}</span>
                  </td>
                  <td class="px-3 py-2">
                    <span class="text-sm text-slate-800">{{ expr.text }}</span>
                  </td>
                  <td class="px-3 py-2"></td>
                </tr>
                <tr v-if="showNewRow" class="border-t border-slate-100 bg-blue-50">
                  <td class="px-3 py-2">
                    <select 
                      v-model="newRowLanguage"
                      class="w-full px-2 py-1.5 text-sm border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="">{{ $t('please_select_language') }}</option>
                      <option v-for="lang in displayLanguages" :key="lang.code" :value="lang.code">
                        {{ lang.name }}
                      </option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <input 
                      v-model="newRowText"
                      type="text"
                      :placeholder="$t('please_enter_expression')"
                      class="w-full px-2 py-1.5 text-sm border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      @keydown.enter="confirmNewRow"
                    />
                  </td>
                  <td class="px-3 py-2">
                    <div class="flex items-center gap-1">
                      <button 
                        @click="confirmNewRow"
                        :disabled="adding"
                        class="p-1 text-green-600 hover:bg-green-100 rounded transition-colors"
                        :title="$t('confirm')"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                      </button>
                      <button 
                        @click="cancelNewRow"
                        :disabled="adding"
                        class="p-1 text-slate-400 hover:bg-slate-200 rounded transition-colors"
                        :title="$t('cancel')"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <p v-if="message" :class="['mt-3 text-sm', messageType === 'error' ? 'text-red-600' : 'text-green-600']">
            {{ message }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

export default {
  name: 'ExpressionGroupModal',
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    expressionId: {
      type: Number,
      default: null
    },
    meaningId: {
      type: Number,
      default: null
    },
    languages: {
      type: Array,
      default: () => []
    }
  },
  emits: ['close', 'updated'],
  setup(props, { emit }) {
    const router = useRouter()
    const { t } = useI18n()

    const loading = ref(false)
    const expressions = ref([])
    const showNewRow = ref(false)
    const newRowLanguage = ref('')
    const newRowText = ref('')
    const adding = ref(false)
    const message = ref('')
    const messageType = ref('success')

    const hasMeaningGroup = computed(() => {
      return props.meaningId !== null && props.meaningId !== undefined
    })

    const displayLanguages = computed(() => {
      console.log('ExpressionGroupModal displayLanguages:', {
        propsLanguages: props.languages,
        propsLanguagesLength: props.languages?.length,
        languagesArray: Array.isArray(props.languages) ? props.languages : 'not array'
      })
      
      if (!props.languages || !Array.isArray(props.languages) || props.languages.length === 0) {
        return []
      }
      return props.languages
    })

    const fetchGroupMembers = async () => {
      loading.value = true
      console.log('fetchGroupMembers called:', {
        visible: props.visible,
        expressionId: props.expressionId,
        meaningId: props.meaningId,
        languages: props.languages,
        displayLanguagesLength: displayLanguages.value.length
      })
      try {
        if (props.meaningId) {
          const res = await fetch(`/api/v1/expressions?meaning_id=${props.meaningId}&skip=0&limit=100`)
          if (res.ok) {
            expressions.value = await res.json()
          } else {
            expressions.value = []
          }
        } 
        else if (props.expressionId) {
          const res = await fetch(`/api/v1/expressions/${props.expressionId}`)
          if (res.ok) {
            const expr = await res.json()
            expressions.value = [expr]
          } else {
            expressions.value = []
          }
        }
        else {
          expressions.value = []
        }
      } catch (e) {
        console.error('Failed to fetch group members:', e)
        expressions.value = []
      } finally {
        loading.value = false
      }
    }

    const getLanguageName = (code) => {
      const lang = props.languages.find(l => l.code === code)
      return lang ? lang.name : code
    }

    const addNewRow = () => {
      showNewRow.value = true
      newRowLanguage.value = ''
      newRowText.value = ''
      message.value = ''
    }

    const cancelNewRow = () => {
      showNewRow.value = false
      newRowLanguage.value = ''
      newRowText.value = ''
      message.value = ''
    }

    const confirmNewRow = async () => {
      if (!newRowLanguage.value || !newRowText.value) {
        message.value = t('please_fill_all_fields')
        messageType.value = 'error'
        return
      }

      const exists = expressions.value.some(e => e.language_code === newRowLanguage.value)
      if (exists) {
        message.value = t('language_already_exists')
        messageType.value = 'error'
        return
      }

      adding.value = true
      message.value = ''

      try {
        const token = localStorage.getItem('authToken')
        if (!token) {
          message.value = t('login_required')
          messageType.value = 'error'
          return
        }

        // If meaningId exists, add directly to the meaning group
        if (props.meaningId) {
          const res = await fetch('/api/v1/expressions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
              text: newRowText.value,
              language_code: newRowLanguage.value,
              meaning_id: props.meaningId
            })
          })

          if (!res.ok) {
            const errorData = await res.json()
            throw new Error(errorData.error || 'Failed to add expression')
          }
        } else {
          // If no meaningId, create a new meaning group with both expressions
          const existingExpr = expressions.value[0]
          const batchRes = await fetch('/api/v1/expressions/batch', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
              expressions: [
                {
                  id: existingExpr.id,
                  text: existingExpr.text,
                  language_code: existingExpr.language_code
                },
                {
                  text: newRowText.value,
                  language_code: newRowLanguage.value
                }
              ]
            })
          })

          if (!batchRes.ok) {
            const errorData = await batchRes.json()
            throw new Error(errorData.error || 'Failed to create meaning group')
          }
        }

        message.value = t('translation_added_successfully')
        messageType.value = 'success'

        cancelNewRow()
        await fetchGroupMembers()
        emit('updated')
      } catch (e) {
        console.error('Error adding expression:', e)
        message.value = e.message || t('failed_to_add_expression')
        messageType.value = 'error'
      } finally {
        adding.value = false
      }
    }

    const close = () => {
      showNewRow.value = false
      newRowLanguage.value = ''
      newRowText.value = ''
      message.value = ''
      emit('close')
    }

    const goToDetail = () => {
      if (props.expressionId) {
        router.push(`/detail/${props.expressionId}`)
      }
      close()
    }

    watch(() => props.visible, (newVal) => {
      if (newVal) {
        fetchGroupMembers()
      }
    })

    return {
      loading,
      expressions,
      showNewRow,
      newRowLanguage,
      newRowText,
      adding,
      message,
      messageType,
      hasMeaningGroup,
      displayLanguages,
      fetchGroupMembers,
      getLanguageName,
      addNewRow,
      cancelNewRow,
      confirmNewRow,
      close,
      goToDetail
    }
  }
}
</script>
