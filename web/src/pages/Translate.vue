<template>
  <div class="max-w-6xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold mb-6">翻译界面</h1>
    
    <!-- 语言选择器 -->
    <div class="bg-white rounded-lg shadow p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">选择语言</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">参考语言</label>
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
          <label class="block text-sm font-medium text-gray-700 mb-1">目标语言</label>
          <select 
            v-model="targetLanguage" 
            class="w-full border border-blue-300 py-3 px-4 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            @change="loadTranslations"
          >
            <option v-for="lang in languages" :key="lang.code" :value="lang.code">
              {{ lang.name }} ({{ lang.code }})
            </option>
          </select>
          <div v-if="targetLanguage === referenceLanguage" class="text-red-500 text-sm mt-1">
            参考语言和目标语言不能相同
          </div>
        </div>
      </div>
      
      <!-- 进度显示 -->
      <div v-if="targetLanguage && targetLanguage !== referenceLanguage" class="mt-4">
        <div class="flex justify-between mb-1">
          <span class="text-sm font-medium">翻译进度</span>
          <span class="text-sm font-medium">{{ completionPercentage }}%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2.5">
          <div 
            class="bg-blue-600 h-2.5 rounded-full" 
            :style="{ width: completionPercentage + '%' }"
          ></div>
        </div>
        <div class="text-sm text-gray-500 mt-1">
          {{ isActive ? '语言已激活' : '语言未激活（完成度需达到60%）' }}
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
              placeholder="搜索本地化键..."
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
              全部
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
              未翻译
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
              已翻译
            </button>
          </div>
        </div>
      </div>
      
      <!-- 翻译表格 -->
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                本地化键
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ getLanguageDisplayName(referenceLanguage) }} (参考)
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                {{ getLanguageDisplayName(targetLanguage) }} (目标)
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="item in filteredTranslations" :key="item.key">
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                {{ item.key }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ item.referenceText }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <input
                  v-model="item.targetText"
                  type="text"
                  class="w-full border border-blue-300 py-2 px-3 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="请输入翻译"
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
            保存翻译 ({{ modifiedItems.length }})
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, computed, watch } from 'vue'
import { fetchLanguages, fetchUITranslations, getLanguageDisplayName } from '../services/languageService'

export default {
  name: 'Translate',
  setup() {
    // 语言选择相关
    const languages = ref([])
    const referenceLanguage = ref('en-US')
    const targetLanguage = ref('')
    
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
    
    // 加载语言列表
    const loadLanguages = async () => {
      try {
        languages.value = await fetchLanguages() // 不限制is_active参数
        // 默认目标语言为列表中的第二个语言（如果不是英语）
        if (languages.value.length > 1) {
          targetLanguage.value = languages.value[1].code
        } else if (languages.value.length > 0) {
          targetLanguage.value = languages.value[0].code
        }
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
        // 并行获取参考语言和目标语言的翻译数据
        const [refData, targetData] = await Promise.all([
          fetchUITranslations(referenceLanguage.value),
          fetchUITranslations(targetLanguage.value)
        ])
        
        referenceTranslations.value = refData
        targetTranslations.value = targetData
        
        // 合并数据
        mergeTranslations()
        
        // 计算完成度
        calculateCompletion()
      } catch (error) {
        console.error('加载翻译数据失败:', error)
      }
    }
    
    // 合并参考语言和目标语言的翻译数据
    const mergeTranslations = () => {
      const refMap = {}
      const targetMap = {}
      
      // 创建参考语言的映射
      referenceTranslations.value.forEach(item => {
        // 解析tags字段（JSON字符串）
        let tags
        try {
          tags = JSON.parse(item.tags)
        } catch (e) {
          console.error('Failed to parse tags for reference item:', item)
          return
        }
        
        if (tags && tags.length > 0) {
          refMap[tags[0]] = item.text
        }
      })
      
      // 创建目标语言的映射
      targetTranslations.value.forEach(item => {
        // 解析tags字段（JSON字符串）
        let tags
        try {
          tags = JSON.parse(item.tags)
        } catch (e) {
          console.error('Failed to parse tags for target item:', item)
          return
        }
        
        if (tags && tags.length > 0) {
          targetMap[tags[0]] = item.text
        }
      })
      
      // 合并数据
      const merged = []
      for (const key in refMap) {
        merged.push({
          key,
          referenceText: refMap[key],
          targetText: targetMap[key] || '',
          originalTargetText: targetMap[key] || ''
        })
      }
      
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
    
    // 标记为已修改
    const markAsModified = (item) => {
      // 检查是否已经在修改列表中
      const index = modifiedItems.value.findIndex(i => i.key === item.key)
      
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
      // 这里应该实现保存翻译的逻辑
      console.log('保存翻译:', modifiedItems.value)
      alert(`将保存 ${modifiedItems.value.length} 条翻译`)
      
      // 重置修改列表
      modifiedItems.value.forEach(item => {
        item.originalTargetText = item.targetText
      })
      modifiedItems.value = []
      
      // 重新计算完成度
      calculateCompletion()
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
    watch([referenceLanguage, targetLanguage], () => {
      if (referenceLanguage.value && targetLanguage.value && referenceLanguage.value !== targetLanguage.value) {
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
      
      // 方法
      loadTranslations,
      filterTranslations,
      setFilter,
      markAsModified,
      saveTranslations,
      getLanguageDisplayName
    }
  }
}
</script>

<style scoped>
/* 可以在这里添加特定的样式 */
</style>