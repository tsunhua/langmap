<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
    <div v-if="loading" class="flex items-center justify-center py-8 sm:py-12">
      <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
        viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
        </path>
      </svg>
      <span class="ml-2 text-slate-600">{{ $t('loading') }}</span>
    </div>

    <div v-else-if="item" class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Left column: current item + meaning groups -->
      <div class="lg:col-span-2 space-y-4 sm:space-y-6">
        <h3 class="text-xl font-bold text-slate-800">{{ $t('expression_details') }}</h3>
        <ExpressionCard :item="item" :key="item.id" :editable="true" :can-delete="canDeleteExpression"
          :is-deleting="deleting" @update-tags="handleTagsUpdate" @delete="handleDelete" />

        <div v-if="groups.length > 0" class="space-y-4">
          <h3 class="text-lg font-bold text-slate-800">{{ $t('associated_expression_groups') }}</h3>
          <nav class="flex flex-wrap gap-2" role="tablist">
            <!-- Group tabs -->
            <button v-for="(group, index) in groups" :key="group.id" @click="setActiveTab(group.id)" :class="[
              'px-2.5 sm:px-4 py-2 sm:py-3 font-medium text-sm rounded-lg transition-colors',
              activeTab === group.id
                ? 'bg-blue-600 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            ]" role="tab" :aria-selected="activeTab === group.id">
              #{{ index + 1 }}
            </button>

            <!-- Search and associate tab (last) -->
            <button @click="setActiveTab('search')" :class="[
              'px-2.5 sm:px-4 py-2 sm:py-3 font-medium text-sm rounded-lg transition-colors',
              activeTab === 'search'
                ? 'bg-blue-600 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            ]" role="tab" :aria-selected="activeTab === 'search'">
              {{ $t('search_and_associate') }}
            </button>
          </nav>

          <!-- Search and associate tab content -->
          <div v-show="activeTab === 'search'" role="tabpanel">
            <SmartSearch
              :exclude-id="item ? item.id : null"
              :current-group-ids="currentGroupIds"
              @create-new="handleSmartSearchCreateNew"
              @associate="handleSmartSearchAssociate"
            />
          </div>

          <!-- Group tab contents -->
          <div v-if="currentGroup && activeTab !== 'search'" role="tabpanel">
            <div class="bg-white rounded-xl shadow-sm border border-slate-200">
              <div
                class="border-b border-slate-200 px-3 sm:px-6 py-3 sm:py-4 flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-3">
                <div class="flex items-center">
                  <span class="text-slate-600 text-sm sm:text-base">{{ currentMembers.length }} {{
                    $t('expressions') }}</span>
                  <button @click="openMergeGroupsModal()"
                    class="ml-2 text-slate-400 hover:text-blue-600 transition-colors"
                    :title="$t('merge_groups')">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                      stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4 4" />
                    </svg>
                  </button>
                </div>
                <button v-if="!groupSearchModes.has(currentGroup.id)" @click="toggleGroupSearch(currentGroup.id)"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-2 text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                  {{ $t('associate_expressions') }}
                </button>
                <button v-else @click="toggleGroupSearch(currentGroup.id)"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3 py-2 text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  {{ $t('cancel') }}
                </button>
              </div>

              <div v-if="groupSearchModes.has(currentGroup.id)"
                class="border-b border-slate-200 bg-slate-50 px-4 sm:px-6 py-4">
                <SmartSearch
                  :exclude-id="item ? item.id : null"
                  :target-group-id="currentGroup.id"
                  :current-group-ids="[currentGroup.id]"
                  @create-new="handleGroupSearchCreateNew"
                  @associate="handleGroupSearchAssociate"
                />
              </div>

              <div class="p-4">
                <div v-if="currentMembers.length > 0" class="space-y-2">
                  <div v-for="member in currentMembers" :key="member.id"
                    class="flex items-center gap-3 py-1.5 sm:py-2 border-b border-slate-100 last:border-0">
                    <div class="flex-1 min-w-0">
                      <div v-if="member.id === item.id" class="bg-blue-50 rounded-lg border border-blue-200 p-2 sm:p-3">
                        <div class="flex items-center gap-2">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-blue-600" fill="none"
                            viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                          <span class="font-semibold text-slate-800">{{ member.text }}</span>
                        </div>
                        <div class="mt-1 text-sm text-slate-600">
                          <span>{{ getLanguageDisplayName(member.language_code) }}</span>
                          <span v-if="member.region_name" class="ml-2">• {{ member.region_name }}</span>
                        </div>
                      </div>
                      <ExpressionCard v-else :item="member" />
                    </div>
                    <button @click="removeFromGroup(member.id, currentGroup.id)"
                      class="text-slate-400 hover:text-red-600 transition-colors" :title="$t('remove_from_group')">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24"
                        stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6M6 18l9-6" />
                      </svg>
                    </button>
                  </div>
                </div>
                <div v-else class="text-center py-4 text-slate-500 text-sm">
                  {{ $t('no_other_expressions_in_group') }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="text-center py-8 text-slate-500">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none"
            viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M6.343 6.343l-.707.707m12.728 0l-.707.707M6.343 17.657l3.636-3.636m-1.414 1.414l3.636-3.636m0 5.657V19a2 2 0 002-2H5a2 2 0 00-2 2v-3.172" />
          </svg>
          <p class="mt-2">{{ $t('no_associated_groups') }}</p>
          <button v-if="!noGroupSearchMode" @click="toggleNoGroupSearch()"
            class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            {{ $t('search_and_associate') }}
          </button>
          <button v-else @click="toggleNoGroupSearch()"
            class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2 mt-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            {{ $t('cancel') }}
          </button>

          <div v-if="noGroupSearchMode" class="mt-4 bg-slate-50 rounded-lg p-4">
            <SmartSearch
              :exclude-id="item ? item.id : null"
              :current-group-ids="[]"
              @create-new="handleSmartSearchCreateNew"
              @associate="handleSmartSearchAssociate"
            />
          </div>
        </div>
      </div>

      <!-- Right column: version history -->
      <div class="lg:col-span-1">
        <VersionHistory :expressionId="id" />
      </div>
    </div>

    <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 sm:p-12 text-center">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24"
        stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <h3 class="text-xl font-semibold text-slate-800 mt-4">{{ $t('expression_not_found') }}</h3>
      <p class="text-slate-600 mt-2">{{ $t('expression_not_found_info') }}</p>
      <button @click="$router.push({ name: 'Home' })"
        class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-4">
        {{ $t('back_to_search') }}
      </button>
    </div>

    <!-- Create Expression Modal -->
    <CreateExpression :visible="showCreateExpressionModal" :initial-group-id="currentGroupIdForAssociation"
      :initial-text="initialTextForCreation" @close="showCreateExpressionModal = false"
      @expression-created="handleExpressionCreated" />

    <!-- 词句组合并模态框 -->
    <div v-if="showMergeGroupsModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-lg max-w-2xl w-full max-h-[80vh] flex flex-col">
        <div
          class="border-b border-slate-200 px-4 sm:px-6 py-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
          <div>
            <h3 class="text-lg font-bold text-slate-800">{{ $t('merge_groups') }}</h3>
            <p class="text-slate-500 text-sm mt-1">
              {{ $t('merge_groups_description') }}
            </p>
          </div>
          <button @click="closeMergeGroupsModal"
            class="text-slate-400 hover:text-slate-600 transition-colors self-start">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto px-4 sm:px-6 py-4">
          <div v-if="mergeLoading" class="flex items-center justify-center py-8">
            <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
              viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
              </path>
            </svg>
            <span class="ml-2 text-slate-600">{{ $t('loading') }}</span>
          </div>

          <div v-else-if="mergeMessage" class="text-center py-8">
            <p class="text-slate-600">{{ mergeMessage }}</p>
          </div>

          <div v-else class="space-y-3">
            <div v-for="group in otherGroups" :key="group.id"
              @click="mergeGroups(group.id)"
              class="border border-slate-200 rounded-lg p-4 hover:border-blue-300 hover:bg-blue-50 transition-colors cursor-pointer">
              <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                <div class="flex-1 min-w-0">
                  <h4 class="font-semibold text-slate-800">#{{ getGroupIndex(group.id) }}</h4>
                  <p class="text-sm text-slate-500 mt-1">
                    {{ group.members.length }} {{ $t('expressions') }}
                  </p>
                  <p class="text-sm text-slate-600 mt-1 truncate">
                    {{ getGroupDisplayText(group) }}
                  </p>
                  <p class="text-xs text-slate-400 mt-1">
                    {{ $t('created_by') }}: {{ group.created_by || $t('anonymous') }}
                  </p>
                </div>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400 sm:flex-shrink-0"
                  fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>

            <div v-if="otherGroups.length === 0" class="text-center py-8">
              <p class="text-slate-500">{{ $t('no_other_groups_to_merge') }}</p>
            </div>
          </div>
        </div>

        <div class="border-t border-slate-200 px-4 sm:px-6 py-4">
          <button @click="closeMergeGroupsModal"
            class="w-full inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
            {{ $t('cancel') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Group Selection Modal -->
    <div v-if="showGroupSelection && selectedExpressionForAssociation"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-lg max-w-2xl w-full max-h-[80vh] flex flex-col">
        <div
          class="border-b border-slate-200 px-4 sm:px-6 py-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
          <div>
            <h3 class="text-lg font-bold text-slate-800">{{ $t('select_expression_group') }}</h3>
            <p class="text-slate-500 text-sm mt-1">
              {{ $t('select_group_to_associate') }}: <strong>"{{ selectedExpressionForAssociation.text }}"</strong>
            </p>
          </div>
          <button @click="closeGroupSelection"
            class="text-slate-400 hover:text-slate-600 transition-colors self-start">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto px-4 sm:px-6 py-4">
          <div v-if="expressionGroupsLoading" class="flex items-center justify-center py-8">
            <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
              viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
              </path>
            </svg>
            <span class="ml-2 text-slate-600">{{ $t('loading') }}</span>
          </div>

          <div v-else-if="expressionGroups.length > 0" class="space-y-3">
            <div v-for="group in expressionGroups" :key="group.id"
              class="border border-slate-200 rounded-lg p-4 hover:border-blue-300 hover:bg-blue-50 transition-colors cursor-pointer"
              @click="associateToSelectedGroup(group.id)">
              <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                <div class="flex-1 min-w-0">
                  <h4 class="font-semibold text-slate-800 truncate">{{ getGroupDisplayText(group) }}</h4>
                  <p class="text-sm text-slate-500 mt-1">{{ $t('created_by') }}: {{ group.created_by ||
                    $t('anonymous') }}</p>
                </div>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400 sm:flex-shrink-0" fill="none"
                  viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-8">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none"
              viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M6.343 6.343l-.707.707m12.728 0l-.707.707M6.343 17.657l3.636-3.636m-1.414 1.414l3.636-3.636m0 5.657V19a2 2 0 002-2H5a2 2 0 00-2 2v-3.172" />
            </svg>
            <p class="mt-2 text-slate-500">{{ $t('no_expression_groups_for_expression') }}</p>
            <p class="mt-1 text-sm text-slate-400">{{ $t('create_new_group_with_this_expression') }}</p>
            <button @click="associateToNewGroup"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-3">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              {{ $t('create_new_expression_group') }}
            </button>
          </div>
        </div>

        <div class="border-t border-slate-200 px-4 sm:px-6 py-4">
          <button @click="closeGroupSelection"
            class="w-full inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
            {{ $t('cancel') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Confirm Modal -->
    <ConfirmModal
      v-model="showConfirmModal"
      :message="confirmMessage"
      :loading="confirmLoading"
      @confirm="executeConfirm"
    />
  </div>
</template>

<script>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { languagesApi } from '../api/index.ts'
import ExpressionCard from '../components/ExpressionCard.vue'
import VersionHistory from '../components/VersionHistory.vue'
import CreateExpression from '../components/CreateExpression.vue'
import SmartSearch from '../components/SmartSearch.vue'
import ConfirmModal from '../components/ConfirmModal.vue'

export default {
  name: 'Detail',
  components: { ExpressionCard, VersionHistory, CreateExpression, SmartSearch, ConfirmModal },
  props: ['id'],
  setup(props) {
    const route = useRoute()
    const router = useRouter()
    const { t } = useI18n()
    const item = ref(null)
    const loading = ref(false)
    const groups = ref([])
    const currentUser = ref(null)
    const deleting = ref(false)

    // Confirm Modal config
    const showConfirmModal = ref(false)
    const confirmType = ref('')
    const confirmMessage = ref('')
    const confirmPayload = ref(null)
    const confirmLoading = ref(false)

    async function executeConfirm() {
      confirmLoading.value = true
      try {
        if (confirmType.value === 'unlink') {
          await executeUnlink()
        } else if (confirmType.value === 'removeFromGroup') {
          await executeRemoveFromGroup()
        } else if (confirmType.value === 'delete') {
          await executeDelete()
        }
        showConfirmModal.value = false
      } finally {
        confirmLoading.value = false
      }
    }

    // Group-specific association mode
    const groupSearchModes = ref(new Set())
    
    // 词句组合并模态框
    const showMergeGroupsModal = ref(false)
    const sourceGroupId = ref(null)
    const targetGroupId = ref(null)
    const mergeLoading = ref(false)
    const mergeMessage = ref('')

    // Search mode for when no groups exist
    const noGroupSearchMode = ref(false)

    // Group selection mode
    const showGroupSelection = ref(false)
    const selectedExpressionForAssociation = ref(null)
    const expressionGroups = ref([])
    const expressionGroupsLoading = ref(false)

    // Tab navigation
    const activeTab = ref(null)

    // Get current group to display
    const currentGroup = computed(() => {
      if (!groups.value || groups.value.length === 0) return null

      const found = groups.value.find(g => g.id === activeTab.value)
      
      // Fallback to first group if activeTab is not found but we have groups
      if (!activeTab.value || activeTab.value === 'null') return groups.value[0]

      return null
    })

    const currentMembers = computed(() => {
      const g = currentGroup.value
      const members = g?.members || []
      if (!item.value) return members

      const currentItem = members.find(member => member.id === item.value.id)
      const otherMembers = members.filter(member => member.id !== item.value.id)

      return currentItem ? [currentItem, ...otherMembers] : otherMembers
    })

    const currentGroupIds = computed(() => {
      if (!groups.value || groups.value.length === 0) return []
      return groups.value.map(g => g.id)
    })

    // 获取其他词句组（排除当前词句组）
    const otherGroups = computed(() => {
      if (!sourceGroupId.value) return []
      return groups.value.filter(g => g.id !== sourceGroupId.value)
    })
    
    // Set active tab
    
    // Set active tab
    function setActiveTab(tabId) {
      activeTab.value = tabId
    }

    // Create expression modal
    const showCreateExpressionModal = ref(false)
    const currentGroupIdForAssociation = ref(null)
    const initialTextForCreation = ref('')
    const shouldAssociateWithCurrent = ref(false)

    const linkedIds = computed(() => {
      const s = new Set()
      if (item.value && item.value.id) s.add(item.value.id)
      for (const g of groups.value || []) {
        if (g && g.members) {
          for (const mem of g.members) {
            if (mem && mem.id) s.add(mem.id)
          }
        }
      }
      return s
    })

    // safe helper to check if an id is linked
    function isLinked(id) {
      try {
        return linkedIds && linkedIds.value && typeof linkedIds.value.has === 'function' ? linkedIds.value.has(id) : false
      } catch (e) {
        return false
      }
    }

    async function load() {
      loading.value = true
      try {
        const res = await fetch(`/api/v1/expressions/${props.id}`)
        if (!res.ok) throw new Error('not found')
        const response = await res.json()
        // 适配新的API响应格式 { success, data }
        item.value = response.data || response

        // fetch groups for this expression
        try {
          const rawGroups = item.value.groups || []
          // Deduplicate by ID
          const groupsData = []
          const seenIds = new Set()
          for (const g of rawGroups) {
            if (g && g.id && !seenIds.has(g.id)) {
              groupsData.push(g)
              seenIds.add(g.id)
            }
          }

          const loadedGroups = []

          // 为每个 group 获取其关联的所有词句
          for (const group of groupsData) {
            try {
              const membersRes = await fetch(`/api/v1/expressions?group_id=${group.id}&skip=0&limit=100`)
              if (membersRes.ok) {
                const response = await membersRes.json()
                // 适配新的分页响应格式 { success, data: { items, total, skip, limit, hasMore } }
                const members = response.data?.items || response || []
                loadedGroups.push({
                  id: group.id,
                  created_by: group.created_by,
                  created_at: group.created_at,
                  members: Array.isArray(members) ? members : []
                })
              }
            } catch (e) {
              console.error(`Failed to fetch members for group ${group.id}:`, e)
              loadedGroups.push({
                id: group.id,
                created_by: group.created_by,
                created_at: group.created_at,
                members: []
              })
            }
          }
          groups.value = loadedGroups
        } catch (e) {
          console.error('Failed to load groups:', e)
          groups.value = []
        }

        // Set initial active tab
        if (groups.value.length > 0) {
          activeTab.value = groups.value[0].id
        } else {
          activeTab.value = 'search'
        }
      } catch (e) {
        console.warn(e)
      } finally {
        loading.value = false
      }
    }

    // Toggle group search mode
    function toggleGroupSearch(groupId) {
      const modes = groupSearchModes.value
      if (modes.has(groupId)) {
        modes.delete(groupId)
      } else {
        modes.add(groupId)
      }
    }

    // Toggle search mode for when no groups exist
    function toggleNoGroupSearch() {
      noGroupSearchMode.value = !noGroupSearchMode.value
    }

    // Open group selection modal
    async function openGroupSelection(target, targetGroupId = null) {
      selectedExpressionForAssociation.value = target
      expressionGroups.value = []
      expressionGroupsLoading.value = true
      showGroupSelection.value = true

      try {
        // Fetch the target expression's groups
        const res = await fetch(`/api/v1/expressions/${target.id}`)
        if (!res.ok) throw new Error('Failed to fetch expression')

        const response = await res.json()
        // 适配新的API响应格式 { success, data }
        const exprData = response.data || response
        const groupsData = exprData.groups || []

        // Fetch members for each group
        const loadedGroups = []
        for (const group of groupsData) {
          try {
            const membersRes = await fetch(`/api/v1/expressions?group_id=${group.id}&skip=0&limit=100`)
            if (membersRes.ok) {
              const response = await membersRes.json()
              // 适配新的分页响应格式 { success, data: { items, total, skip, limit, hasMore } }
              const members = response.data?.items || response || []
              loadedGroups.push({
                id: group.id,
                created_by: group.created_by,
                created_at: group.created_at,
                members: Array.isArray(members) ? members : []
              })
            }
          } catch (e) {
            console.error(`Failed to fetch members for group ${group.id}:`, e)
            loadedGroups.push({
              id: group.id,
              created_by: group.created_by,
              created_at: group.created_at,
              members: []
            })
          }
        }
        expressionGroups.value = loadedGroups
      } catch (e) {
        console.error('Error fetching expression groups:', e)
        expressionGroups.value = []
      } finally {
        expressionGroupsLoading.value = false
      }
    }

    // Close group selection modal
    function closeGroupSelection() {
      showGroupSelection.value = false
      selectedExpressionForAssociation.value = null
      expressionGroups.value = []
    }

    // Associate to selected group
    async function associateToSelectedGroup(groupId) {
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/expressions/${item.value.id}/associate`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            group_id: groupId
          })
        })

        if (!res.ok) {
          const errorData = await res.json()
          throw new Error(errorData.error || 'Failed to associate to expression group')
        }

        // Refresh to show updated list
        await load()
        closeGroupSelection()
      } catch (e) {
        console.error('Error associating to group:', e)
        alert(t('failed_to_associate_to_group'))
      }
    }

    // Associate to new group (using batch)
    async function associateToNewGroup() {
      if (!selectedExpressionForAssociation.value) return

      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const batchRes = await fetch('/api/v1/expressions/batch', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            expressions: [
              {
                id: item.value.id,
                text: item.value.text,
                language_code: item.value.language_code
              },
              {
                id: selectedExpressionForAssociation.value.id,
                text: selectedExpressionForAssociation.value.text,
                language_code: selectedExpressionForAssociation.value.language_code
              }
            ],
            ensure_new_group: true
          })
        })

        if (!batchRes.ok) {
          const errorData = await batchRes.json()
          throw new Error(errorData.error || 'Failed to associate expressions')
        }

        const result = await batchRes.json()

        // Refresh to show updated list
        await load()
        closeGroupSelection()

        // Close search mode if open
        if (noGroupSearchMode.value) {
          noGroupSearchMode.value = false
        }
      } catch (e) {
        console.error('Association error:', e)
        alert(t('failed_to_associate_expressions'))
      }
    }

    // Open all groups modal
    async function openAllGroupsModal() {
      allGroups.value = []
      allGroupsLoading.value = true
      showAllGroupsModal.value = true

      try {
        const res = await fetch('/api/v1/groups?skip=0&limit=100')
        if (!res.ok) throw new Error('Failed to fetch groups')

        const response = await res.json()
        // 适配新的分页响应格式 { success, data: { items, total, skip, limit, hasMore } }
        let allGroupsList = response.data?.items || response.data || response || []
        allGroups.value = Array.isArray(allGroupsList) ? allGroupsList : []
      } catch (e) {
        console.error('Error fetching all groups:', e)
        alert(t('failed_to_fetch_expression_groups'))
      } finally {
        allGroupsLoading.value = false
      }
    }

    // Close all groups modal
    function closeAllGroupsModal() {
      showAllGroupsModal.value = false
      allGroups.value = []
    }

    // Get display text for expression group (show member texts instead of ID)
    function getGroupDisplayText(group) {
      if (group.members && group.members.length > 0) {
        // Get up to 5 member texts, join with " / "
        const memberTexts = group.members
          .slice(0, 5)
          .map(m => m.text)
          .join(' / ')
        return memberTexts
      }
      // Fallback if no members
      return t('expression_group')
    }
    
    // 获取词句组在列表中的索引
    function getGroupIndex(groupId) {
      return groups.value.findIndex(g => g.id === groupId) + 1
    }
    
    // 打开词句组合并模态框
    function openMergeGroupsModal() {
      if (!currentGroup.value) {
        console.warn('Cannot open merge modal: currentGroup is null')
        return
      }
      sourceGroupId.value = currentGroup.value.id
      targetGroupId.value = null
      mergeMessage.value = ''
      showMergeGroupsModal.value = true
    }
    
    // 关闭词句组合并模态框
    function closeMergeGroupsModal() {
      showMergeGroupsModal.value = false
      sourceGroupId.value = null
      targetGroupId.value = null
      mergeMessage.value = ''
    }
    
    // 执行词句组合并
    async function mergeGroups(targetGroupIdParam) {
      if (!sourceGroupId.value) return
      
      // 前端验证
      if (sourceGroupId.value === targetGroupIdParam) {
        mergeMessage.value = t('cannot_merge_to_same_group')
        return
      }
      
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }
      
      mergeLoading.value = true
      mergeMessage.value = ''
      
      try {
        const res = await fetch('/api/v1/groups/merge', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            source_group_id: sourceGroupId.value,
            target_group_id: targetGroupIdParam
          })
        })
        
        if (!res.ok) {
          const errorData = await res.json()
          throw new Error(errorData.error || 'Failed to merge expression groups')
        }
        
        const result = await res.json()
        
        // 关闭模态框
        closeMergeGroupsModal()
        
        // 刷新数据
        await load()
        
        // 切换到目标词句组
        setActiveTab(targetGroupIdParam.toString())
      } catch (e) {
        console.error('Merge error:', e)
        mergeMessage.value = String(e)
      } finally {
        mergeLoading.value = false
      }
    }

    async function handleTagsUpdate(newTags) {
      if (!item.value) return

      try {
        const token = localStorage.getItem('authToken')
        if (!token) {
          // Ideally show a toast or alert
          console.warn('Login required to update tags')
          return
        }

        const res = await fetch(`/api/v1/expressions/${props.id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            tags: JSON.stringify(newTags)
          })
        })

        if (!res.ok) throw new Error(t('failed_to_update_tags'))

        // Update local item
        item.value.tags = JSON.stringify(newTags)

      } catch (e) {
        console.error('Error updating tags:', e)
        alert(t('failed_to_update_tags'))
      }
    }

    async function unlink(target) {
      confirmType.value = 'unlink'
      confirmPayload.value = target
      confirmMessage.value = t('confirm_unlink')
      showConfirmModal.value = true
    }

    async function executeUnlink() {
      const target = confirmPayload.value
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/expressions/${target.id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ group_id: null })
        })

        if (!res.ok) throw new Error(t('failed_to_unlink'))

        // Refresh to show updated list
        await load()
      } catch (e) {
        console.error('Error unlinking:', e)
        alert(t('failed_to_unlink'))
      }
    }

    // Open create expression modal
    function openCreateExpressionModal(searchText = '') {
      currentGroupIdForAssociation.value = activeTab.value !== 'search' ? activeTab.value : (groups.value && groups.value.length > 0 ? groups.value[0].id : null);
      initialTextForCreation.value = searchText;
      showCreateExpressionModal.value = true;
    }

    // Handle SmartSearch create-new event (from search and associate tab)
    async function handleSmartSearchCreateNew(searchText) {
      // 如果当前没有任何词句组，使用批量关联API让后端创建新的group_id
      if (!groups.value || groups.value.length === 0) {
        const token = localStorage.getItem('authToken')
        if (!token) {
          alert(t('login_required'))
          return
        }

        try {
          // 直接打开创建弹窗，但在创建后会使用batch API进行关联
          currentGroupIdForAssociation.value = null
          initialTextForCreation.value = searchText
          showCreateExpressionModal.value = true

          // 存储一个标记，表示这是从没有词句组的情况创建的
          shouldAssociateWithCurrent.value = true
        } catch (e) {
          console.error('Error preparing to create expression:', e)
          alert(t('failed_to_add_expression'))
        }
      } else {
        // 如果已有词句组，让用户选择关联到哪个词句组
        currentGroupIdForAssociation.value = null
        initialTextForCreation.value = searchText
        showCreateExpressionModal.value = true
        shouldAssociateWithCurrent.value = false
      }
    }

    // Handle SmartSearch associate event (from search and associate tab)
    function handleSmartSearchAssociate(result) {
      openGroupSelection(result)
    }

    // Handle SmartSearch create-new event (from within a group)
    function handleGroupSearchCreateNew(searchText) {
      openCreateExpressionModalForGroup(currentGroup.value.id, searchText)
    }

    // Handle SmartSearch associate event (from within a group)
    async function handleGroupSearchAssociate(result) {
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/expressions/${result.id}/associate`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            group_id: currentGroup.value.id
          })
        })

        if (!res.ok) {
          const errorData = await res.json()
          throw new Error(errorData.error || 'Failed to associate to expression group')
        }

        // Refresh to show updated list
        await load()

        // Close search mode for this group
        toggleGroupSearch(currentGroup.value.id)
      } catch (e) {
        console.error('Error associating to group:', e)
        alert(t('failed_to_associate_to_group'))
      }
    }

    // Open create expression modal for specific group
    function openCreateExpressionModalForGroup(groupId, searchText = '') {
      currentGroupIdForAssociation.value = groupId;
      initialTextForCreation.value = searchText;
      showCreateExpressionModal.value = true;
    }

    // Remove expression from a group
    async function removeFromGroup(expressionId, groupId) {
      confirmType.value = 'removeFromGroup'
      confirmPayload.value = { expressionId, groupId }
      confirmMessage.value = t('confirm_remove_from_group')
      showConfirmModal.value = true
    }

    async function executeRemoveFromGroup() {
      const { expressionId, groupId } = confirmPayload.value
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/groups/${groupId}/expressions/${expressionId}`, {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          }
        })

        if (!res.ok) {
          throw new Error(t('failed_to_remove_from_group'))
        }

        // Refresh to show updated list
        await load()
      } catch (e) {
        console.error('Error removing from group:', e)
        alert(t('failed_to_remove_from_group'))
      }
    }

    // Handle expression created event from modal
    async function handleExpressionCreated(createdExpression) {
      showCreateExpressionModal.value = false;

      // 如果标记为需要与当前词句关联，使用batch API
      if (shouldAssociateWithCurrent.value && item.value) {
        const token = localStorage.getItem('authToken')
        if (!token) {
          await load()
          return
        }

        try {
          const batchRes = await fetch('/api/v1/expressions/batch', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
              expressions: [
                {
                  id: item.value.id,
                  text: item.value.text,
                  language_code: item.value.language_code
                },
                {
                  id: createdExpression.id,
                  text: createdExpression.text,
                  language_code: createdExpression.language_code
                }
              ],
              ensure_new_group: true
            })
          })

          if (!batchRes.ok) {
            const errorData = await batchRes.json()
            console.error('Failed to associate expressions:', errorData)
          }
        } catch (e) {
          console.error('Error associating expressions:', e)
        }
      }

      // Refresh to show newly created expression
      await load();
      shouldAssociateWithCurrent.value = false
    }

    // Load current user
    async function loadCurrentUser() {
      const token = localStorage.getItem('authToken')
      if (!token) {
        currentUser.value = null
        return
      }

      try {
        const response = await fetch('/api/v1/users/me', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (response.ok) {
          const result = await response.json()
          currentUser.value = result.data
        } else {
          currentUser.value = null
        }
      } catch (e) {
        console.warn('Failed to load current user:', e)
        currentUser.value = null
      }
    }

    // Check if current user can delete the expression
    const canDeleteExpression = computed(() => {
      if (!currentUser.value || !item.value) {
        return false
      }

      // Admin can delete any expression
      if (currentUser.value.role === 'admin') {
        return true
      }

      // Creator can delete their own expression
      return item.value.created_by === currentUser.value.username
    })

    // Handle delete expression
    async function handleDelete() {
      if (!item.value) return

      confirmType.value = 'delete'
      confirmMessage.value = t('confirm_delete_expression')
      showConfirmModal.value = true
    }

    async function executeDelete() {
      deleting.value = true
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        deleting.value = false
        return
      }

      try {
        const response = await fetch(`/api/v1/expressions/${item.value.id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (!response.ok) {
          if (response.status === 403) {
            alert(t('delete_permission_denied'))
          } else if (response.status === 404) {
            alert(t('expression_not_found'))
          } else {
            const error = await response.json()
            alert(error.error || t('delete_failed'))
          }
          deleting.value = false
          return
        }

        // Redirect to previous page after successful deletion
        router.back()
      } catch (e) {
        console.error('Error deleting expression:', e)
        alert(t('delete_failed'))
        deleting.value = false
      }
    }

    onMounted(() => {
      load()
      loadCurrentUser()
    })
    // when the route param `id` changes the same component instance is reused by the router;
    // watch the prop and reload the details when it changes
    watch(() => props.id, (newId, oldId) => {
      if (newId !== oldId) load()
    })
    return {
      item,
      loading,
      groups,
      linkedIds,
      isLinked,
      getLanguageDisplayName: (code) => languagesApi.getLanguageDisplayName(code),
      // Group search
      groupSearchModes,
      toggleGroupSearch,
      handleGroupSearchCreateNew,
      handleGroupSearchAssociate,
      // 词句组合并
      showMergeGroupsModal,
      sourceGroupId,
      targetGroupId,
      mergeLoading,
      mergeMessage,
      openMergeGroupsModal,
      closeMergeGroupsModal,
      mergeGroups,
      otherGroups,
      getGroupIndex,
      // No group search
      noGroupSearchMode,
      toggleNoGroupSearch,
      // Group selection
      showGroupSelection,
      selectedExpressionForAssociation,
      expressionGroups,
      expressionGroupsLoading,
      openGroupSelection,
      closeGroupSelection,
      associateToSelectedGroup,
      associateToNewGroup,
      getGroupDisplayText,
      // SmartSearch handlers
      handleSmartSearchCreateNew,
      handleSmartSearchAssociate,
      // Tab navigation
      activeTab,
      setActiveTab,
      currentGroup,
      currentMembers,
      // Create expression modal
      showCreateExpressionModal,
      currentGroupIdForAssociation,
      initialTextForCreation,
      shouldAssociateWithCurrent,
      openCreateExpressionModal,
      openCreateExpressionModalForGroup,
      handleExpressionCreated,
      removeFromGroup,
      handleTagsUpdate,
      unlink,
      // Delete expression
      canDeleteExpression,
      deleting,
      handleDelete,
      showConfirmModal,
      confirmMessage,
      confirmLoading,
      executeConfirm
    }
  }
}
</script>