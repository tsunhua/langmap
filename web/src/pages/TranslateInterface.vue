<template>
  <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold mb-6">{{ $t('translate_title') }}</h1>

    <!-- 语言选择器 -->
    <div class="bg-white rounded-lg shadow p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">{{ $t('select_language') }}</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('reference_language') }}</label>
          <select v-model="referenceLanguage"
            class="w-full border border-blue-300 py-3 px-4 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            @change="loadTranslations">
            <option v-for="lang in languages" :key="lang.code" :value="lang.code">
              {{ lang.name }} ({{ lang.code }})
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('target_language') }}</label>
          <select v-model="targetLanguage"
            class="w-full border border-blue-300 py-3 px-4 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            @change="loadTranslations">
            <option value="" disabled>{{ $t('select_target_language') || 'Select target language' }}</option>
            <option v-for="lang in languages" :key="lang.code" :value="lang.code">
              {{ lang.name }} ({{ lang.code }})
            </option>
          </select>
          <div v-if="targetLanguage === referenceLanguage" class="text-red-500 text-sm mt-1">
            {{ $t('same_language_error') }}
          </div>
        </div>
      </div>

      <!-- 进度显示 -->
      <div v-if="targetLanguage && targetLanguage !== referenceLanguage" class="mt-4">
        <div class="flex justify-between mb-1">
          <span class="text-sm font-medium">{{ $t('translation_progress') }}</span>
          <span class="text-sm font-medium">{{ completionPercentage }}%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2.5">
          <div class="bg-blue-600 h-2.5 rounded-full" :style="{ width: completionPercentage + '%' }"></div>
        </div>
        <div class="text-sm text-gray-500 mt-1">
          {{ completionPercentage >= 60 ? $t('language_activated') : $t('language_not_activated') }}
        </div>
      </div>
    </div>

    <!-- 翻译表格 -->
    <div v-if="referenceLanguage && targetLanguage && referenceLanguage !== targetLanguage"
      class="bg-white rounded-lg shadow">
      <!-- 过滤控件 -->
      <div class="p-6 border-b border-gray-200">
        <div class="flex flex-col sm:flex-row gap-4">
          <div class="flex-grow">
            <input v-model="searchQuery" type="text" :placeholder="$t('please_input')"
              class="w-full border border-blue-300 py-3 px-4 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              @input="filterTranslations" />
          </div>
          <div class="flex gap-2">
            <button :class="[
              'px-4 py-2 rounded',
              filterOption === 'all'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            ]" @click="setFilter('all')">
              {{ $t('all') }}
            </button>
            <button :class="[
              'px-4 py-2 rounded',
              filterOption === 'untranslated'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            ]" @click="setFilter('untranslated')">
              {{ $t('untranslated') }}
            </button>
            <button :class="[
              'px-4 py-2 rounded',
              filterOption === 'translated'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            ]" @click="setFilter('translated')">
              {{ $t('translated') }}
            </button>
          </div>
        </div>
      </div>

      <!-- 翻译表格 -->
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 table-fixed">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col"
                class="w-1/6 px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ $t('localization_key') }}
              </th>
              <th scope="col"
                class="w-5/12 px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ getLanguageDisplayName(referenceLanguage) }} ({{ $t('reference_language') }})
              </th>
              <th scope="col"
                class="w-1/12 px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ $t('action') }}
              </th>
              <th scope="col"
                class="w-5/12 px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ getLanguageDisplayName(targetLanguage) }} ({{ $t('target_language') }})
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="key in filteredKeys" :key="key">
              <td class="px-6 py-4 text-sm font-medium text-gray-900 break-words">
                {{ key }}
              </td>
              <td class="px-6 py-4 text-sm text-gray-500 break-words">
                {{ referenceLocale[key] }}
              </td>
              <td class="px-6 py-4 text-center">
                <button @click="copyToTarget(key)" class="text-blue-600 hover:text-blue-800 font-bold"
                  :aria-label="$t('copy_reference_to_target')">
                  &gt;&gt;
                </button>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">
                <input v-model="targetLocale[key]" type="text"
                  class="w-full border border-blue-300 py-2 px-3 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  :placeholder="$t('please_enter_translation')" @input="markAsModified(key)" />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 提交控件 -->
      <div class="p-6 border-t border-gray-200">
        <div class="flex justify-end">
          <button :disabled="modifiedKeys.size === 0" :class="[
            'px-6 py-3 rounded font-medium',
            modifiedKeys.size === 0
              ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
              : 'bg-blue-600 text-white hover:bg-blue-700'
          ]" @click="saveTranslations">
            {{ $t('save_translations', { count: modifiedKeys.size }) }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { fetchLanguages, getLanguageDisplayName, fetchUILocale, saveUILocale, getCurrentUser } from '../services/languageService'
import { useI18n } from 'vue-i18n'

export default {
  name: 'TranslateInterface',
  setup() {
    const { t } = useI18n()
    const route = useRoute()
    const router = useRouter()

    // 语言选择相关
    const languages = ref([])
    const referenceLanguage = ref(route.query.ref || 'en-US')
    const targetLanguage = ref(route.query.target || '')

    // 翻译数据相关（存储完整的 locale JSON 对象）
    const referenceLocale = ref({})
    const targetLocale = ref({})
    const keysToTranslate = ref([])

    // 过滤和搜索相关
    const filterOption = ref('untranslated')
    const searchQuery = ref('')
    const filteredKeys = ref([])

    // 修改状态相关
    const modifiedKeys = ref(new Set())

    // 进度相关
    const completionPercentage = ref(0)

    // 加载语言列表
    const loadLanguages = async () => {
      try {
        languages.value = await fetchLanguages()
      } catch (error) {
        console.error('加载语言列表失败:', error)
      }
    }

    // 加载翻译数据
    const loadTranslations = async () => {
      if (!referenceLanguage.value || !targetLanguage.value || referenceLanguage.value === targetLanguage.value) {
        return
      }

      try {
        // 加载参考语言
        const refUiLocale = await fetchUILocale(referenceLanguage.value)
        referenceLocale.value = refUiLocale?.locale_json || {}

        // 加载目标语言（如果不存在则创建空对象）
        let targetUiLocale = await fetchUILocale(targetLanguage.value)
        targetLocale.value = targetUiLocale?.locale_json || {}

        // 确保目标语言包含参考语言的所有键（使用参考语言作为模板）
        // 只有当目标语言为空或缺少键时才补充
        const refKeys = Object.keys(referenceLocale.value)
        const targetKeys = Object.keys(targetLocale.value)

        if (targetKeys.length === 0) {
          // 目标语言为空，使用参考语言的所有键，但值设为空
          refKeys.forEach(key => {
            targetLocale.value[key] = ''
          })
        }

        // 提取所有需要翻译的键（使用参考语言的键）
        keysToTranslate.value = refKeys.sort()

        // 计算完成度
        calculateCompletion()

        // 初始过滤
        filterTranslations()
      } catch (error) {
        console.error('加载翻译数据失败:', error)
      }
    }

    // 过滤翻译数据
    const filterTranslations = () => {
      let result = [...keysToTranslate.value]

      // 根据搜索关键词筛选
      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        result = result.filter(key =>
          key.toLowerCase().includes(query) ||
          referenceLocale.value[key].toLowerCase().includes(query) ||
          (targetLocale.value[key] && targetLocale.value[key].toLowerCase().includes(query))
        )
      }

      // 根据过滤选项筛选
      if (filterOption.value === 'untranslated') {
        result = result.filter(key => !targetLocale.value[key] || targetLocale.value[key].trim() === '')
      } else if (filterOption.value === 'translated') {
        result = result.filter(key => targetLocale.value[key] && targetLocale.value[key].trim() !== '')
      }

      filteredKeys.value = result
    }

    // 设置过滤选项
    const setFilter = (option) => {
      filterOption.value = option
      filterTranslations()
    }

    // 将参考文本复制到目标文本
    const copyToTarget = (key) => {
      targetLocale.value[key] = referenceLocale.value[key]
      markAsModified(key)
    }

    // 标记为已修改
    const markAsModified = (key) => {
      // 如果值不为空，则标记为已修改
      if (targetLocale.value[key] && targetLocale.value[key].trim() !== '') {
        modifiedKeys.value.add(key)
      } else {
        // 如果值为空，则从修改列表中移除
        modifiedKeys.value.delete(key)
      }
    }

    // 保存翻译
    const saveTranslations = async () => {
      if (modifiedKeys.value.size === 0) return

      try {
        // 保存整个目标语言 locale JSON
        await saveUILocale(targetLanguage.value, targetLocale.value)

        alert(t('translate.saveSuccess', { count: modifiedKeys.value.size }) || `Successfully saved ${modifiedKeys.value.size} translations`)

        // 重置修改列表
        modifiedKeys.value.clear()

        // 重新加载数据以确保一致性
        await loadTranslations()
      } catch (error) {
        console.error('Failed to save translations:', error)
        alert(t('translate.saveError') || 'Failed to save translations')
      }
    }

    // 计算完成度
    const calculateCompletion = () => {
      if (keysToTranslate.value.length === 0) {
        completionPercentage.value = 0
        return
      }

      const translatedCount = keysToTranslate.value.filter(key =>
        targetLocale.value[key] && targetLocale.value[key].trim() !== ''
      ).length
      completionPercentage.value = Math.round((translatedCount / keysToTranslate.value.length) * 100)
    }

    // 监听语言选择变化
    watch([referenceLanguage, targetLanguage], ([newRef, newTarget]) => {
      // 更新 URL
      router.replace({
        query: {
          ...route.query,
          ref: newRef,
          target: newTarget || undefined
        }
      })

      if (newRef && newTarget && newRef !== newTarget) {
        loadTranslations()
      }
    })

    // 监听搜索查询变化
    watch(searchQuery, () => {
      filterTranslations()
    })

    // 监听过滤选项变化
    watch(filterOption, () => {
      filterTranslations()
    })

    // 初始化
    onMounted(async () => {
      await loadLanguages()
      await loadTranslations()
    })

    return {
      // 数据
      languages,
      referenceLanguage,
      targetLanguage,
      referenceLocale,
      targetLocale,
      filteredKeys,
      filterOption,
      searchQuery,
      modifiedKeys,
      completionPercentage,

      // 方法
      t,
      loadTranslations,
      filterTranslations,
      setFilter,
      copyToTarget,
      markAsModified,
      saveTranslations,
      getLanguageDisplayName
    }
  }
}
</script>