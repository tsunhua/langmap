<template>
  <div v-if="visible" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-2 sm:p-4" @click.self="close">
    <div class="bg-white rounded-xl shadow-xl max-w-sm sm:max-w-lg w-full max-h-[90vh] sm:max-h-[80vh] overflow-hidden flex flex-col mx-2">
      <div class="px-4 py-3 sm:px-6 sm:py-4 border-b border-slate-200 flex justify-between items-center">
        <div class="flex items-center gap-3">
          <h3 class="text-base sm:text-lg font-bold text-slate-800">{{ $t('expression_group_details') }}</h3>
          <button
            @click="goToDetail"
            class="px-2 py-1.5 sm:px-3 text-xs sm:text-sm font-medium text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            {{ $t('more') }}
          </button>
        </div>
        <button @click="close" class="text-slate-400 hover:text-slate-600 transition-colors">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <div class="flex-1 overflow-y-auto p-3 sm:p-4">
        <div v-if="loading" class="flex items-center justify-center py-8">
          <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>

        <div v-else>
          <div v-if="showTabs" class="flex gap-1 mb-3 overflow-x-auto pb-1">
            <button
              v-for="group in groups"
              :key="group.id"
              @click="selectGroup(group.id)"
              :class="[
                'px-3 py-1.5 text-xs sm:text-sm font-medium rounded-lg whitespace-nowrap transition-colors',
                currentGroupId === group.id
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              ]"
            >
              #{{ groups.indexOf(group) + 1 }}
            </button>
          </div>

          <button
            v-if="!showNewRow"
            @click="addNewRow"
            class="w-full py-2 mb-3 border-2 border-dashed border-slate-300 text-slate-500 hover:border-blue-400 hover:text-blue-600 rounded-lg transition-colors flex items-center justify-center gap-1 text-sm"
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
                  <th class="px-2 py-2 text-left text-[10px] sm:text-xs font-semibold text-slate-600 uppercase tracking-wider w-20 sm:w-1/3">{{ $t('language') }}</th>
                  <th class="px-2 py-2 text-left text-[10px] sm:text-xs font-semibold text-slate-600 uppercase tracking-wider">{{ $t('expression') }}</th>
                  <th class="px-2 py-2 w-12 sm:w-16"></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="expr in expressions" :key="expr.id" class="border-t border-slate-100">
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <span class="text-xs sm:text-sm text-slate-600">{{ getLanguageName(expr.language_code) }}</span>
                  </td>
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <span class="text-xs sm:text-sm text-slate-800 break-words">{{ expr.text }}</span>
                  </td>
                  <td class="px-2 py-2 sm:px-3 sm:py-2"></td>
                </tr>
                <tr v-for="(pendingExpr, index) in pendingExpressions" :key="'pending-' + index" class="border-t border-slate-100 bg-yellow-50">
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <span class="text-xs sm:text-sm text-slate-600">{{ getLanguageName(pendingExpr.language_code) }}</span>
                  </td>
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <span class="text-xs sm:text-sm text-slate-800 break-words">{{ pendingExpr.text }}</span>
                  </td>
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <button
                      @click="removePendingExpression(index)"
                      class="p-1 text-red-500 hover:bg-red-100 rounded transition-colors"
                      :title="$t('remove')"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </td>
                </tr>
                <tr v-if="showNewRow" class="border-t border-slate-100 bg-blue-50">
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <select
                      v-model="newRowLanguage"
                      class="w-full px-2 py-1.5 text-xs sm:text-sm border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="">{{ $t('please_select_language') }}</option>
                      <option v-for="lang in displayLanguages" :key="lang.code" :value="lang.code">
                        {{ lang.name }}
                      </option>
                    </select>
                  </td>
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <input
                      v-model="newRowText"
                      type="text"
                      :placeholder="$t('please_enter_expression')"
                      class="w-full px-2 py-1.5 text-xs sm:text-sm border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      @keydown.enter="addToPending"
                    />
                  </td>
                  <td class="px-2 py-2 sm:px-3 sm:py-2">
                    <div class="flex items-center gap-1">
                      <button
                        @click="addToPending"
                        :disabled="adding"
                        class="p-1 text-green-600 hover:bg-green-100 rounded transition-colors"
                        :title="$t('add')"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
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

          <div v-if="pendingExpressions.length > 0" class="mt-3 flex items-center gap-2">
            <button
              @click="submitAllPending"
              :disabled="adding"
              class="flex-1 py-2 px-3 bg-blue-600 text-white text-xs sm:text-sm font-medium rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {{ $t('submit') }}
            </button>
            <button
              @click="cancelAll"
              :disabled="adding"
              class="px-3 py-2 text-slate-600 text-xs sm:text-sm font-medium rounded-lg border border-slate-300 hover:bg-slate-50 disabled:opacity-50 transition-colors"
            >
              {{ $t('cancel') }}
            </button>
          </div>

          <p v-if="message" :class="['mt-3 text-xs sm:text-sm', messageType === 'error' ? 'text-red-600' : 'text-green-600']">
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
    groupId: {
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
    const groups = ref([])
    const currentGroupId = ref(null)
    const pendingExpressions = ref([])
    const showNewRow = ref(false)
    const newRowLanguage = ref('')
    const newRowText = ref('')
    const adding = ref(false)
    const message = ref('')
    const messageType = ref('success')

    const hasGroup = computed(() => {
      return props.groupId !== null && props.groupId !== undefined
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
        groupId: props.groupId,
        languages: props.languages,
        displayLanguagesLength: displayLanguages.value.length
      })
      try {
        if (!props.expressionId) {
          expressions.value = []
          groups.value = []
          return
        }

        const languageCodes = displayLanguages.value.map(l => l.code).join(',')
        const url = languageCodes
          ? `/api/v1/expressions/${props.expressionId}/groups?lang=${languageCodes}`
          : `/api/v1/expressions/${props.expressionId}/groups`

        const res = await fetch(url)
        if (!res.ok) {
          console.error('Failed to fetch expression groups')
          expressions.value = []
          groups.value = []
          return
        }

        const result = await res.json()
        groups.value = result.success ? result.data : result

        if (groups.value.length === 0) {
          expressions.value = []
          return
        }

        currentGroupId.value = props.groupId || groups.value[0].id
      } catch (e) {
        console.error('Failed to fetch group members:', e)
        expressions.value = []
        groups.value = []
      } finally {
        loading.value = false
      }
    }

    const selectGroup = (groupId) => {
      currentGroupId.value = groupId
    }

    watch(currentGroupId, (newGroupId) => {
      const group = groups.value.find(g => g.id === newGroupId)
      if (group && group.expressions) {
        expressions.value = group.expressions
      } else {
        expressions.value = []
      }
    })

    const showTabs = computed(() => {
      return groups.value.length > 1
    })

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

    const addToPending = () => {
      if (!newRowLanguage.value || !newRowText.value) {
        message.value = t('please_fill_all_fields')
        messageType.value = 'error'
        return
      }

      pendingExpressions.value.push({
        language_code: newRowLanguage.value,
        text: newRowText.value
      })

      newRowLanguage.value = ''
      newRowText.value = ''
      message.value = t('added_to_pending_list')
      messageType.value = 'success'
    }

    const removePendingExpression = (index) => {
      pendingExpressions.value.splice(index, 1)
    }

    const cancelAll = () => {
      pendingExpressions.value = []
      message.value = ''
      close()
    }

    const submitAllPending = async () => {
      if (pendingExpressions.value.length === 0) {
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

        if (props.groupId) {
          const promises = pendingExpressions.value.map(pending =>
            fetch('/api/v1/expressions', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
              },
              body: JSON.stringify({
                text: pending.text,
                language_code: pending.language_code,
                group_id: props.groupId
              })
            })
          )

          const results = await Promise.all(promises)
          const errors = results.filter(res => !res.ok)

          if (errors.length > 0) {
            message.value = t('some_expressions_failed')
            messageType.value = 'error'
          } else {
            message.value = t('all_expressions_added_successfully')
            messageType.value = 'success'
            pendingExpressions.value = []
            await fetchGroupMembers()
            emit('updated')
            close()
          }
        } else {
          const currentGroup = groups.value.find(g => g.id === currentGroupId.value)
          if (!currentGroup) {
            message.value = t('failed_to_add_expressions')
            messageType.value = 'error'
            return
          }

          const existingExprs = currentGroup.expressions || []
          const allExprs = [
            ...existingExprs.map(e => ({
              id: e.id,
              text: e.text,
              language_code: e.language_code
            })),
            ...pendingExpressions.value.map(p => ({
              text: p.text,
              language_code: p.language_code
            }))
          ]

          const batchRes = await fetch('/api/v1/expressions/batch', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
              expressions: allExprs
            })
          })

          if (!batchRes.ok) {
            const errorData = await batchRes.json()
            throw new Error(errorData.error || t('failed_to_create_meaning_group'))
          }

          message.value = t('all_expressions_added_successfully')
          messageType.value = 'success'
          pendingExpressions.value = []
          await fetchGroupMembers()
          emit('updated')
          close()
        }
      } catch (e) {
        console.error('Error submitting pending expressions:', e)
        message.value = e.message || t('failed_to_add_expressions')
        messageType.value = 'error'
      } finally {
        adding.value = false
      }
    }

    const cancelNewRow = () => {
      showNewRow.value = false
      newRowLanguage.value = ''
      newRowText.value = ''
      message.value = ''
    }

    const close = () => {
      showNewRow.value = false
      newRowLanguage.value = ''
      newRowText.value = ''
      pendingExpressions.value = []
      message.value = ''
      emit('close')
    }

    const goToDetail = () => {
      if (props.expressionId) {
        window.open(`/#/detail/${props.expressionId}`, '_blank')
      }
    }

    watch(() => props.visible, (newVal) => {
      if (newVal) {
        pendingExpressions.value = []
        fetchGroupMembers()
      }
    })

    return {
      loading,
      expressions,
      groups,
      currentGroupId,
      pendingExpressions,
      showNewRow,
      newRowLanguage,
      newRowText,
      adding,
      message,
      messageType,
      hasGroup,
      displayLanguages,
      showTabs,
      fetchGroupMembers,
      getLanguageName,
      selectGroup,
      addNewRow,
      cancelNewRow,
      addToPending,
      removePendingExpression,
      cancelAll,
      submitAllPending,
      close,
      goToDetail
    }
  }
}
</script>
