<template>
  <div class="max-w-6xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold mb-6">{{ $t('translate_title') }}</h1>

    <!-- 管理员同步按钮 -->
    <div v-if="isAdmin" class="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-yellow-800">同步本地翻译</h3>
          <p class="text-sm text-yellow-700 mt-1">
            将本地 JSON 文件中的新增翻译同步到数据库。已存在的翻译不会被覆盖。
          </p>
        </div>
        <button
          @click="syncLocales"
          :disabled="syncing"
          class="px-4 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
        >
          {{ syncing ? '同步中...' : '同步翻译' }}
        </button>
      </div>
      <!-- 同步结果 -->
      <div v-if="syncResult" class="mt-3 text-sm space-y-1">
        <div v-for="(result, lang) in syncResult" :key="lang" class="flex items-center gap-2">
          <span class="font-medium text-yellow-900">{{ lang }}:</span>
          <span class="text-yellow-800">新增 {{ result.added }} 条</span>
          <span v-if="result.skipped > 0" class="text-yellow-600">跳过 {{ result.skipped }} 条</span>
          <span v-if="result.errors && result.errors.length > 0" class="text-red-600">错误: {{ result.errors.join(', ') }}</span>
        </div>
      </div>
    </div>

    <!-- 语言选择器 -->
    <div class="bg-white rounded-lg shadow p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">{{ $t('select_language') }}</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('reference_language') }}</label>
          <select 
            v-model="referenceLanguage" 
            class="w-full border border-blue-300 py-3 px-4 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            @change="loadTranslations"
          >
            <option v-for="lang in languages" :key="lang.code" :value="lang.code">
              {{ lang.name }} ({{ lang.code }})
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('target_language') }}</label>
          <select 
            v-model="targetLanguage" 
            class="w-full border border-blue-300 py-3 px-4 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            @change="loadTranslations"
          >
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
          <div 
            class="bg-blue-600 h-2.5 rounded-full" 
            :style="{ width: completionPercentage + '%' }"
          ></div>
        </div>
        <div class="text-sm text-gray-500 mt-1">
          {{ isActive ? $t('language_activated') : $t('language_not_activated') }}
        </div>
      </div>
    </div>
    
    <!-- 翻译表格 -->
    <div v-if="referenceLanguage && targetLanguage && referenceLanguage !== targetLanguage" class="bg-white rounded-lg shadow">
      <!-- 过滤控件 -->
      <div class="p-6 border-b border-gray-200">
        <div class="flex flex-col sm:flex-row gap-4">
          <div class="flex-grow">
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="$t('search_placeholder')"
              class="w-full border border-blue-300 py-3 px-4 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              @input="filterTranslations"
            />
          </div>
          <div class="flex gap-2">
            <button
              :class="[
                'px-4 py-2 rounded',
                filterOption === 'all' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              ]"
              @click="setFilter('all')"
            >
              {{ $t('all') }}
            </button>
            <button
              :class="[
                'px-4 py-2 rounded',
                filterOption === 'untranslated' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              ]"
              @click="setFilter('untranslated')"
            >
              {{ $t('untranslated') }}
            </button>
            <button
              :class="[
                'px-4 py-2 rounded',
                filterOption === 'translated' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              ]"
              @click="setFilter('translated')"
            >
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
              <th scope="col" class="w-1/6 px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ $t('localization_key') }}
              </th>
              <th scope="col" class="w-5/12 px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ getLanguageDisplayName(referenceLanguage) }} ({{ $t('reference_language') }})
              </th>
              <th scope="col" class="w-1/12 px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ $t('action') }}
              </th>
              <th scope="col" class="w-5/12 px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ getLanguageDisplayName(targetLanguage) }} ({{ $t('target_language') }})
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="item in filteredTranslations" :key="item.id">
              <td class="px-6 py-4 text-sm font-medium text-gray-900 break-words">
                {{ item.key }}
              </td>
              <td class="px-6 py-4 text-sm text-gray-500 break-words">
                {{ item.referenceText }}
              </td>
              <td class="px-6 py-4 text-center">
                <button 
                  @click="copyToTarget(item)" 
                  class="text-blue-600 hover:text-blue-800 font-bold"
                  :aria-label="$t('copy_reference_to_target')"
                >
                  &gt;&gt;
                </button>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">
                <input
                  v-model="item.targetText"
                  type="text"
                  class="w-full border border-blue-300 py-2 px-3 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  :placeholder="$t('please_enter_translation')"
                  @input="markAsModified(item)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <!-- 提交控件 -->
      <div class="p-6 border-t border-gray-200">
        <div class="flex justify-end">
          <button
            :disabled="modifiedItems.length === 0"
            :class="[
              'px-6 py-3 rounded font-medium',
              modifiedItems.length === 0
                ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                : 'bg-blue-600 text-white hover:bg-blue-700'
            ]"
            @click="saveTranslations"
          >
            {{ $t('save_translations', { count: modifiedItems.length }) }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { fetchLanguages, fetchUITranslations, getLanguageDisplayName, saveUITranslations, syncLocalesToDatabase, getCurrentUser } from '../services/languageService'
import { useI18n } from 'vue-i18n'

// 动态导入所有本地 locales 文件
const localeModules = import.meta.glob('../locales/*.json', { eager: true })

// 本地 locales 映射（动态生成）
const localMessages = {}
for (const path in localeModules) {
  const module = localeModules[path]
  const langCode = path.match(/\/([^/]+)\.json$/)?.[1]
  if (langCode && module.default) {
    localMessages[langCode] = module.default
  }
}

export default {
  name: 'TranslateInterface',
  setup() {
    const { t } = useI18n()
    const route = useRoute()
    const router = useRouter()

    // 扁平化嵌套的 JSON 对象
    // { home: { title: "Hi" } } → { "home_title": "Hi" }
    const flattenObject = (obj, prefix = '') => {
      const flattened = {}
      for (const key in obj) {
        const newKey = prefix ? `${prefix}.${key}` : key
        if (typeof obj[key] === 'object' && obj[key] !== null) {
          Object.assign(flattened, flattenObject(obj[key], newKey))
        } else {
          flattened[newKey] = obj[key]
        }
      }
      return flattened
    }

    // 从本地 JSON 加载参考翻译
    const loadLocalReferenceTranslations = (langCode) => {
      const messages = localMessages[langCode]
      if (!messages) {
        console.warn(`No local messages found for language: ${langCode}`)
        return []
      }
      const flattened = flattenObject(messages)
      return Object.entries(flattened).map(([key, text]) => ({
        key,
        text,
        meaning_id: null, // 稍后在合并时设置
        fromLocal: true, // 标记来自本地文件
        langCode // 记录语言代码
      }))
    }

    // 语言选择相关
    const languages = ref([])
    const referenceLanguage = ref(route.query.ref || 'en-US')
    const targetLanguage = ref(route.query.target || '')
    
    // 翻译数据相关
    const referenceTranslations = ref([])
    const targetTranslations = ref([])
    const mergedTranslations = ref([])
    const filteredTranslations = ref([])
    
    // 过滤和搜索相关
    const filterOption = ref('untranslated')
    const searchQuery = ref('')
    
    // 修改状态相关
    const modifiedItems = ref([])
    
    // 进度相关
    const completionPercentage = ref(0)
    const isActive = ref(false)

    // Admin sync state
    const syncing = ref(false)
    const syncResult = ref(null)
    const isAdmin = computed(() => {
      const user = getCurrentUser()
      return user?.role === 'admin'
    })

    // Sync locales to database
    const syncLocales = async () => {
      if (!isAdmin.value) {
        alert('仅管理员可以执行此操作')
        return
      }

      syncing.value = true
      syncResult.value = null

      try {
        // Collect all local data
        const localeData = {}
        for (const [langCode, messages] of Object.entries(localMessages)) {
          localeData[langCode] = messages
        }

        // Call sync API
        const response = await syncLocalesToDatabase(localeData)
        syncResult.value = response.results

        alert('同步完成！')

        // Reload translations
        await loadTranslations()
      } catch (error) {
        console.error('同步失败:', error)
        alert('同步失败：' + (error.response?.data?.error || error.message))
      } finally {
        syncing.value = false
      }
    }

    // 加载语言列表
    const loadLanguages = async () => {
      try {
        languages.value = await fetchLanguages() // 不限制is_active参数
        // Reference language defaults to en-US as initialized, 
        // but target language is left empty to force user selection.
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
        // 加载参考语言：本地 + 数据库覆盖
        if (localMessages[referenceLanguage.value]) {
          // 先加载本地 JSON 作为基础
          const localRef = loadLocalReferenceTranslations(referenceLanguage.value)
          // 再从数据库获取已有的翻译
          const dbRef = await fetchUITranslations(referenceLanguage.value)
          // 合并：本地为基础，数据库翻译覆盖
          referenceTranslations.value = mergeLocalWithDb(localRef, dbRef)
        } else {
          // 没有本地文件，直接从数据库获取
          referenceTranslations.value = await fetchUITranslations(referenceLanguage.value)
        }

        // 加载目标语言：本地 + 数据库覆盖
        if (localMessages[targetLanguage.value]) {
          // 先加载本地 JSON 作为基础
          const localTarget = loadLocalReferenceTranslations(targetLanguage.value)
          // 再从数据库获取已有的翻译
          const dbTarget = await fetchUITranslations(targetLanguage.value)
          // 合并：本地为基础，数据库翻译覆盖
          targetTranslations.value = mergeLocalWithDb(localTarget, dbTarget)
        } else {
          // 没有本地文件，直接从数据库获取
          targetTranslations.value = await fetchUITranslations(targetLanguage.value)
        }

        // 合并数据
        mergeTranslations()

        // 计算完成度
        calculateCompletion()
      } catch (error) {
        console.error('加载翻译数据失败:', error)
      }
    }

    // 合并本地数据和数据库数据（数据库覆盖本地）
    const mergeLocalWithDb = (localData, dbData) => {
      // 创建本地数据的映射
      const localMap = new Map()
      localData.forEach(item => {
        localMap.set(item.key, item)
      })

      // 用数据库数据覆盖本地数据
      const merged = [...localData]
      dbData.forEach(dbItem => {
        let tags = dbItem.tags
        if (typeof tags === 'string') {
          try { tags = JSON.parse(tags) } catch (e) {
            return // 忽略无法解析的 tags
          }
        }

        if (!tags || !Array.isArray(tags) || tags.length === 0) {
          // 没有 tags 的数据不是有效的 UI 翻译，跳过
          return
        }

        // 处理所有 tags，而不仅仅是第一个
        tags.forEach(key => {
          // Check for exact match or langmap. prefix match
          const localKey = key.startsWith('langmap.') ? key.substring(8) : key
          
          if (localMap.has(localKey)) {
            // 找到对应的本地数据，用数据库翻译替换文本
            const index = merged.findIndex(item => item.key === localKey)
            if (index !== -1) {
              merged[index] = {
                ...merged[index],
                text: dbItem.text,
                meaning_id: dbItem.meaning_id || dbItem.id,
                fromLocal: false // 标记为数据库数据
              }
            }
          }
        })
        // 注意：不再添加数据库中有但本地没有的数据
        // 因为我们以本地 JSON 为基准，确保翻译界面只显示有效的 UI key
      })

      return merged
    }
    
    // 合并参考语言和目标语言的翻译数据
    const mergeTranslations = () => {
      const refMap = {}
      const targetMap = {}

      // 创建参考语言的映射
      referenceTranslations.value.forEach(item => {
        if (item.key) {
          // Priority to existing key (from local JSON)
          refMap[item.key] = { 
            text: item.text, 
            key: item.key, 
            id: item.id || item.key, 
            meaningId: item.meaning_id || null, 
            fromLocal: item.fromLocal 
          }
        } else if (item.fromLocal) {
          // Local data fallback (should be covered by item.key above)
          refMap[item.key] = { text: item.text, key: item.key, id: item.key, fromLocal: true }
        } else {
          // Database data without matching local key
          const mid = item.meaning_id || item.id

          let tags = item.tags
          if (typeof tags === 'string') {
            try { tags = JSON.parse(tags) } catch (e) {
              console.error('Failed to parse tags for reference item:', item)
              return
            }
          }

          // Handle tags
          if (tags && tags.length > 0) {
            tags.forEach(tag => {
              // Only process tags starting with 'langmap.'
              if (tag.startsWith('langmap.')) {
                const cleanKey = tag.substring(8)
                refMap[cleanKey] = { text: item.text, key: cleanKey, id: item.id, meaningId: mid, fromLocal: false }
              }
            })
          } else {
            // No valid langmap tags, skip or use fallback if strict mode is off
            // For now, we only want to show langmap keys
            // const fallbackKey = `(no key) ${item.text}`
            // refMap[fallbackKey] = { text: item.text, key: fallbackKey, id: item.id, meaningId: mid, fromLocal: false }
          }
        }
      })

      // 创建目标语言的映射 (按 key 和 meaning_id)
      targetTranslations.value.forEach(item => {
        let tags = item.tags
        if (typeof tags === 'string') {
          try { tags = JSON.parse(tags) } catch (e) {
            return
          }
        }

        // 处理所有标签，而不仅仅是第一个
        if (tags && tags.length > 0) {
          tags.forEach(tag => {
            targetMap[tag] = { text: item.text, meaningId: item.meaning_id }
          })
        }

        // 同时按 meaning_id 存储，以便匹配
        if (item.meaning_id) {
          targetMap[`mid:${item.meaning_id}`] = { text: item.text, meaningId: item.meaning_id }
        }
      })

      // 合并数据
      const merged = []
      for (const key in refMap) {
        const refItem = refMap[key]
        const targetItem = targetMap[key] || targetMap[`mid:${refItem.meaningId}`]

        merged.push({
          id: refItem.id,
          meaning_id: refItem.meaningId || null, // 本地数据为 null
          key: refItem.key,
          referenceText: refItem.text,
          targetText: targetItem?.text || '',
          originalTargetText: targetItem?.text || '',
          fromLocal: refItem.fromLocal || false
        })
      }

      // 按照本地化键排序
      merged.sort((a, b) => a.key.localeCompare(b.key))

      mergedTranslations.value = merged
      filterTranslations()
    }
    
    // 过滤翻译数据
    const filterTranslations = () => {
      let result = [...mergedTranslations.value]
      
      // 根据过滤选项筛选
      if (filterOption.value === 'untranslated') {
        result = result.filter(item => !item.targetText)
      } else if (filterOption.value === 'translated') {
        result = result.filter(item => item.targetText)
      }
      
      // 根据搜索关键词筛选
      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        result = result.filter(item => 
          item.key.toLowerCase().includes(query) ||
          item.referenceText.toLowerCase().includes(query) ||
          (item.targetText && item.targetText.toLowerCase().includes(query))
        )
      }
      
      filteredTranslations.value = result
    }
    
    // 设置过滤选项
    const setFilter = (option) => {
      filterOption.value = option
      filterTranslations()
    }
    
    // 将参考文本复制到目标文本
    const copyToTarget = (item) => {
      item.targetText = item.referenceText
      markAsModified(item)
    }
    
    // 标记为已修改
    const markAsModified = (item) => {
      // 对于本地数据，使用 key 作为唯一标识
      const index = modifiedItems.value.findIndex(i =>
        i.fromLocal ? i.key === item.key : i.meaning_id === item.meaning_id
      )

      // 如果值发生了变化
      if (item.targetText !== item.originalTargetText) {
        if (index === -1) {
          // 添加到修改列表
          modifiedItems.value.push(item)
        }
      } else {
        // 如果修改被撤销，则从列表中移除
        if (index !== -1) {
          modifiedItems.value.splice(index, 1)
        }
      }
    }

    // 保存翻译
    const saveTranslations = async () => {
      if (modifiedItems.value.length === 0) return

      try {
        // 后端会自动处理没有 meaning_id 的情况
        const translationsToSave = modifiedItems.value.map(item => ({
          key: `langmap.${item.key}`, // Add prefix when saving
          text: item.targetText,
          meaning_id: item.meaning_id,
          referenceText: item.fromLocal ? item.referenceText : undefined
        }))

        await saveUITranslations(targetLanguage.value, translationsToSave)

        alert(t('translate.saveSuccess', { count: modifiedItems.value.length }) || `Successfully saved ${modifiedItems.value.length} translations`)

        // 重置修改列表
        modifiedItems.value.forEach(item => {
          item.originalTargetText = item.targetText
        })
        modifiedItems.value = []

        // 重新加载数据以确保一致性
        await loadTranslations()
      } catch (error) {
        console.error('Failed to save translations:', error)
        alert(t('translate.saveError') || 'Failed to save translations')
      }
    }
    
    // 计算完成度
    const calculateCompletion = () => {
      if (mergedTranslations.value.length === 0) {
        completionPercentage.value = 0
        isActive.value = false
        return
      }
      
      const translatedCount = mergedTranslations.value.filter(item => item.targetText).length
      completionPercentage.value = Math.round((translatedCount / mergedTranslations.value.length) * 100)
      isActive.value = completionPercentage.value >= 60
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
      filteredTranslations,
      filterOption,
      searchQuery,
      modifiedItems,
      completionPercentage,
      isActive,

      // Admin sync
      syncing,
      syncResult,
      isAdmin,

      // 方法
      t,
      loadTranslations,
      filterTranslations,
      setFilter,
      copyToTarget,
      markAsModified,
      saveTranslations,
      syncLocales,
      getLanguageDisplayName
    }
  }
}
</script>