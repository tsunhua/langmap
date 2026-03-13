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
      <!-- Left column: current item + translations as a unified list -->
      <div class="lg:col-span-2 space-y-4 sm:space-y-6">
        <h3 class="text-xl font-bold text-slate-800">{{ $t('expression_details') }}</h3>
        <ExpressionCard :item="item" :key="item.id" :editable="true" :can-delete="canDeleteExpression"
          :is-deleting="deleting" @update-tags="handleTagsUpdate" @delete="handleDelete" />

        <div v-if="meanings.length > 0" class="space-y-4">
          <h3 class="text-lg font-bold text-slate-800">{{ $t('associated_expression_groups') }}</h3>
          <nav class="flex flex-wrap gap-2" role="tablist">
            <!-- Meaning group tabs -->
            <button v-for="(meaning, index) in meanings" :key="meaning.id" @click="setActiveTab(meaning.id)" :class="[
              'px-2.5 sm:px-4 py-2 sm:py-3 font-medium text-sm rounded-lg transition-colors',
              activeTab === meaning.id
                ? 'bg-blue-600 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            ]" role="tab" :aria-selected="activeTab === meaning.id">
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
              @create-new="handleSmartSearchCreateNew"
              @associate="handleSmartSearchAssociate"
            />
          </div>

          <!-- Meaning group tab contents -->
          <div v-if="currentMeaning && activeTab !== 'search'" role="tabpanel">
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
                <button v-if="!groupSearchModes.has(currentMeaning.id)" @click="toggleGroupSearch(currentMeaning.id)"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-2 text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                  {{ $t('associate_expressions') }}
                </button>
                <button v-else @click="toggleGroupSearch(currentMeaning.id)"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3 py-2 text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  {{ $t('cancel') }}
                </button>
              </div>

              <div v-if="groupSearchModes.has(currentMeaning.id)"
                class="border-b border-slate-200 bg-slate-50 px-4 sm:px-6 py-4">
                <SmartSearch
                  :exclude-id="item ? item.id : null"
                  :target-meaning-id="currentMeaning.id"
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
                    <button @click="removeFromGroup(member.id, currentMeaning.id)"
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
          <button v-if="!globalSearchMode" @click="toggleGlobalSearch()"
            class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            {{ $t('search_and_associate') }}
          </button>
          <button v-else @click="toggleGlobalSearch()"
            class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2 mt-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            {{ $t('cancel') }}
          </button>

          <div v-if="globalSearchMode" class="mt-4 bg-slate-50 rounded-lg p-4">
            <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 mb-3">
              <div class="flex-1">
                <input v-model="globalSearchQuery" :placeholder="$t('please_input')"
                  class="block w-full rounded-md border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3"
                  @keydown.enter="searchGlobal()" />
              </div>
              <button @click="searchGlobal()"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <span class="hidden sm:inline ml-1">{{ $t('search') }}</span>
              </button>
            </div>

            <div v-if="globalSearchLoading" class="flex items-center justify-center py-3">
              <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
                viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                </path>
              </svg>
              <span class="ml-2 text-slate-600">{{ $t('searching') }}</span>
            </div>

            <div v-else-if="globalSearchResults && globalSearchResults.length > 0" class="space-y-2">
              <div v-for="c in globalSearchResults" :key="c && c.id"
                class="flex gap-3 items-center p-2 bg-white rounded-lg">
                <div v-if="c && item && c.id !== item.id" class="flex-1">
                  <ExpressionCard :item="c" />
                </div>
                <div v-if="c && item && c.id !== item.id">
                  <button @click="openMeaningSelection(c)"
                    class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-1.5 text-sm">
                    {{ $t('associate') }}
                  </button>
                </div>
              </div>
            </div>

            <div v-else-if="globalSearchSearched" class="text-center py-3 text-slate-500 text-sm">
              {{ $t('no_expressions_found') }}
              <div class="mt-3">
                <button @click="openCreateExpressionModal(globalSearchQuery)"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-1.5 text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                  {{ $t('add_expression') }}
                </button>
              </div>
            </div>
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
    <CreateExpression :visible="showCreateExpressionModal" :initial-meaning-id="currentMeaningIdForAssociation"
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
            <div v-for="meaning in otherMeanings" :key="meaning.id"
              @click="mergeMeaningGroups(meaning.id)"
              class="border border-slate-200 rounded-lg p-4 hover:border-blue-300 hover:bg-blue-50 transition-colors cursor-pointer">
              <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                <div class="flex-1 min-w-0">
                  <h4 class="font-semibold text-slate-800">#{{ getMeaningIndex(meaning.id) }}</h4>
                  <p class="text-sm text-slate-500 mt-1">
                    {{ meaning.members.length }} {{ $t('expressions') }}
                  </p>
                  <p class="text-sm text-slate-600 mt-1 truncate">
                    {{ getMeaningDisplayText(meaning) }}
                  </p>
                  <p class="text-xs text-slate-400 mt-1">
                    {{ $t('created_by') }}: {{ meaning.created_by || $t('anonymous') }}
                  </p>
                </div>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400 sm:flex-shrink-0"
                  fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>

            <div v-if="otherMeanings.length === 0" class="text-center py-8">
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
    
    <!-- Meaning Selection Modal -->
    <div v-if="showMeaningSelection && selectedExpressionForAssociation"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-lg max-w-2xl w-full max-h-[80vh] flex flex-col">
        <div
          class="border-b border-slate-200 px-4 sm:px-6 py-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
          <div>
            <h3 class="text-lg font-bold text-slate-800">{{ $t('select_meaning_group') }}</h3>
            <p class="text-slate-500 text-sm mt-1">
              {{ $t('select_meaning_to_associate') }}: <strong>"{{ selectedExpressionForAssociation.text }}"</strong>
            </p>
          </div>
          <button @click="closeMeaningSelection"
            class="text-slate-400 hover:text-slate-600 transition-colors self-start">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto px-4 sm:px-6 py-4">
          <div v-if="expressionMeaningsLoading" class="flex items-center justify-center py-8">
            <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
              viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
              </path>
            </svg>
            <span class="ml-2 text-slate-600">{{ $t('loading') }}</span>
          </div>

          <div v-else-if="expressionMeanings.length > 0" class="space-y-3">
            <div v-for="meaning in expressionMeanings" :key="meaning.id"
              class="border border-slate-200 rounded-lg p-4 hover:border-blue-300 hover:bg-blue-50 transition-colors cursor-pointer"
              @click="associateToSelectedMeaning(meaning.id)">
              <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                <div class="flex-1 min-w-0">
                  <h4 class="font-semibold text-slate-800 truncate">{{ getMeaningDisplayText(meaning) }}</h4>
                  <p class="text-sm text-slate-500 mt-1">{{ $t('created_by') }}: {{ meaning.created_by ||
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
            <p class="mt-2 text-slate-500">{{ $t('no_meaning_groups_for_expression') }}</p>
            <p class="mt-1 text-sm text-slate-400">{{ $t('create_new_group_with_this_expression') }}</p>
            <button @click="associateToNewMeaning"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-4 py-2 mt-3">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              {{ $t('create_new_meaning_group') }}
            </button>
          </div>
        </div>

        <div class="border-t border-slate-200 px-4 sm:px-6 py-4">
          <button @click="closeMeaningSelection"
            class="w-full inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
            {{ $t('cancel') }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { getLanguageDisplayName } from '../services/languageService.js'
import ExpressionCard from '../components/ExpressionCard.vue'
import VersionHistory from '../components/VersionHistory.vue'
import CreateExpression from '../components/CreateExpression.vue'
import SmartSearch from '../components/SmartSearch.vue'

export default {
  name: 'Detail',
  components: { ExpressionCard, VersionHistory, CreateExpression, SmartSearch },
  props: ['id'],
  setup(props) {
    const route = useRoute()
    const router = useRouter()
    const { t } = useI18n()
    const item = ref(null)
    const loading = ref(false)
    const transLoading = ref(false)
    const translations = ref([])
    const meanings = ref([])
    const currentUser = ref(null)
    const deleting = ref(false)

    // Group-specific association mode
    const groupSearchModes = ref(new Set())
    
    // 词句组合并模态框
    const showMergeGroupsModal = ref(false)
    const sourceMeaningId = ref(null)
    const targetMeaningId = ref(null)
    const mergeLoading = ref(false)
    const mergeMessage = ref('')
    
    // Global search mode for when no groups exist
    const globalSearchMode = ref(false)
    const globalSearchQuery = ref('')
    const globalSearchResults = ref([])
    const globalSearchLoading = ref(false)
    const globalSearchSearched = ref(false)
    const globalSearchMessage = ref('')

    // Meaning selection mode
    const showMeaningSelection = ref(false)
    const selectedExpressionForAssociation = ref(null)
    const expressionMeanings = ref([])
    const expressionMeaningsLoading = ref(false)

    // Tab navigation
    const activeTab = ref(null)

    // Get current meaning to display
    const currentMeaning = computed(() => {
      if (!meanings.value || meanings.value.length === 0) return null
      if (activeTab.value === 'search') return null

      const found = meanings.value.find(m => m.id === activeTab.value)
      if (found) return found

      // Fallback to first meaning if activeTab is not found but we have meanings
      if (!activeTab.value || activeTab.value === 'null') return meanings.value[0]

      return null
    })

    const currentMembers = computed(() => {
      const m = currentMeaning.value
      const members = m?.members || []
      if (!item.value) return members
      
      const currentItem = members.find(m => m.id === item.value.id)
      const otherMembers = members.filter(m => m.id !== item.value.id)
      
      return currentItem ? [currentItem, ...otherMembers] : otherMembers
    })

    // 获取其他词句组（排除当前词句组）
    const otherMeanings = computed(() => {
      if (!sourceMeaningId.value) return []
      return meanings.value.filter(m => m.id !== sourceMeaningId.value)
    })
    
    // Set active tab
    
    // Set active tab
    function setActiveTab(tabId) {
      activeTab.value = tabId
    }

    // Create expression modal
    const showCreateExpressionModal = ref(false)
    const currentMeaningIdForAssociation = ref(null)
    const initialTextForCreation = ref('')



    const linkedIds = computed(() => {
      const s = new Set()
      if (item.value && item.value.id) s.add(item.value.id)
      for (const m of meanings.value || []) {
        if (m && m.members) {
          for (const mem of m.members) {
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
        item.value = await res.json()
        // fetch translations via server-side meaning grouping
        transLoading.value = true
        try {
          const tr = await fetch(`/api/v1/expressions/${props.id}/translations`)
          if (tr.ok) {
            translations.value = await tr.json()
          } else {
            translations.value = []
          }
        } catch (e) {
          console.warn('translations fetch failed', e)
          translations.value = []
        } finally {
          transLoading.value = false
        }
        // fetch meanings for this expression
        try {
          const rawMeanings = item.value.meanings || []
          // Deduplicate by ID
          const meaningsData = []
          const seenIds = new Set()
          for (const m of rawMeanings) {
            if (m && m.id && !seenIds.has(m.id)) {
              meaningsData.push(m)
              seenIds.add(m.id)
            }
          }

          const loadedMeanings = []

          // 为每个 meaning 获取其关联的所有词句
          for (const meaning of meaningsData) {
            try {
              const membersRes = await fetch(`/api/v1/expressions?meaning_id=${meaning.id}&skip=0&limit=100`)
              if (membersRes.ok) {
                const members = await membersRes.json()
                loadedMeanings.push({
                  id: meaning.id,
                  created_by: meaning.created_by,
                  created_at: meaning.created_at,
                  members: members
                })
              }
            } catch (e) {
              console.error(`Failed to fetch members for meaning ${meaning.id}:`, e)
            }
          }
          meanings.value = loadedMeanings
        } catch (e) {
          console.error('Failed to load meanings:', e)
          meanings.value = []
        }

        // Set initial active tab
        if (meanings.value.length > 0) {
          activeTab.value = meanings.value[0].id
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
    function toggleGroupSearch(meaningId) {
      const modes = groupSearchModes.value
      if (modes.has(meaningId)) {
        modes.delete(meaningId)
      } else {
        modes.add(meaningId)
      }
    }

    // Toggle global search mode
    function toggleGlobalSearch() {
      globalSearchMode.value = !globalSearchMode.value
      if (globalSearchMode.value) {
        globalSearchQuery.value = ''
        globalSearchResults.value = []
        globalSearchSearched.value = false
      }
    }

    // Global search function
    async function searchGlobal() {
      globalSearchLoading.value = true
      globalSearchSearched.value = false
      globalSearchMessage.value = ''

      try {
        const params = new URLSearchParams()
        if (globalSearchQuery.value) params.set('q', globalSearchQuery.value)
        const url = `/api/v1/search?${params.toString()}`

        const res = await fetch(url)
        if (!res.ok) throw new Error('search failed')

        globalSearchResults.value = await res.json()
        globalSearchSearched.value = true
      } catch (e) {
        globalSearchMessage.value = String(e)
        globalSearchResults.value = []
        globalSearchSearched.value = true
      } finally {
        globalSearchLoading.value = false
      }
    }

    // Associate globally (will create new meaning group)
    async function associateGlobally(target) {
      globalSearchMessage.value = ''

      const token = localStorage.getItem('authToken')
      if (!token) {
        globalSearchMessage.value = t('must_be_logged_in_to_associate')
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
                id: target.id,
                text: target.text,
                language_code: target.language_code
              }
            ]
          })
        })

        if (!batchRes.ok) {
          const errorData = await batchRes.json()
          throw new Error(errorData.error || 'Failed to associate expressions')
        }

        const result = await batchRes.json()
        globalSearchMessage.value = t('expressions_processed', { count: 2, meaningId: result.meaning_id })

        // Refresh to show updated list
        await load()

        // Reset global search
        globalSearchQuery.value = ''
        globalSearchResults.value = []
        globalSearchSearched.value = false
        globalSearchMode.value = false
      } catch (e) {
        console.error('Association error:', e)
        globalSearchMessage.value = String(e)
      }
    }

    // Open meaning selection modal
    async function openMeaningSelection(target, targetMeaningId = null) {
      selectedExpressionForAssociation.value = target
      expressionMeanings.value = []
      expressionMeaningsLoading.value = true
      showMeaningSelection.value = true

      try {
        // Fetch the target expression's meanings
        const res = await fetch(`/api/v1/expressions/${target.id}`)
        if (!res.ok) throw new Error('Failed to fetch expression')

        const exprData = await res.json()
        const meaningsData = exprData.meanings || []

        // Fetch members for each meaning
        const loadedMeanings = []
        for (const meaning of meaningsData) {
          try {
            const membersRes = await fetch(`/api/v1/expressions?meaning_id=${meaning.id}&skip=0&limit=100`)
            if (membersRes.ok) {
              const members = await membersRes.json()
              loadedMeanings.push({
                id: meaning.id,
                created_by: meaning.created_by,
                created_at: meaning.created_at,
                members: members
              })
            }
          } catch (e) {
            console.error(`Failed to fetch members for meaning ${meaning.id}:`, e)
          }
        }
        expressionMeanings.value = loadedMeanings
      } catch (e) {
        console.error('Error fetching expression meanings:', e)
        expressionMeanings.value = []
      } finally {
        expressionMeaningsLoading.value = false
      }
    }

    // Close meaning selection modal
    function closeMeaningSelection() {
      showMeaningSelection.value = false
      selectedExpressionForAssociation.value = null
      expressionMeanings.value = []
    }

    // Associate to selected meaning
    async function associateToSelectedMeaning(meaningId) {
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/expressions/${item.value.id}/meanings`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            meaning_id: meaningId
          })
        })

        if (!res.ok) {
          const errorData = await res.json()
          throw new Error(errorData.error || 'Failed to associate to meaning group')
        }

        // Refresh to show updated list
        await load()
        closeMeaningSelection()
      } catch (e) {
        console.error('Error associating to meaning:', e)
        alert(t('failed_to_associate_to_meaning'))
      }
    }

    // Associate to new meaning (using batch)
    async function associateToNewMeaning() {
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
            ]
          })
        })

        if (!batchRes.ok) {
          const errorData = await batchRes.json()
          throw new Error(errorData.error || 'Failed to associate expressions')
        }

        const result = await batchRes.json()

        // Refresh to show updated list
        await load()
        closeMeaningSelection()

        // Reset search
        if (globalSearchMode.value) {
          globalSearchQuery.value = ''
          globalSearchResults.value = []
          globalSearchSearched.value = false
        }
      } catch (e) {
        console.error('Association error:', e)
        alert(t('failed_to_associate_expressions'))
      }
    }

    // Open all meanings modal
    async function openAllMeaningsModal() {
      allMeanings.value = []
      allMeaningsLoading.value = true
      showAllMeaningsModal.value = true

      try {
        const res = await fetch('/api/v1/meanings?skip=0&limit=100')
        if (!res.ok) throw new Error('Failed to fetch meanings')

        allMeanings.value = await res.json()
      } catch (e) {
        console.error('Error fetching all meanings:', e)
        alert(t('failed_to_fetch_meaning_groups'))
      } finally {
        allMeaningsLoading.value = false
      }
    }

    // Close all meanings modal
    function closeAllMeaningsModal() {
      showAllMeaningsModal.value = false
      allMeanings.value = []
    }

    // Get display text for meaning group (show member texts instead of ID)
    function getMeaningDisplayText(meaning) {
      if (meaning.members && meaning.members.length > 0) {
        // Get up to 5 member texts, join with " / "
        const memberTexts = meaning.members
          .slice(0, 5)
          .map(m => m.text)
          .join(' / ')
        return memberTexts
      }
      // Fallback if no members
      return t('expression_group')
    }
    
    // 获取词句组在列表中的索引
    function getMeaningIndex(meaningId) {
      return meanings.value.findIndex(m => m.id === meaningId) + 1
    }
    
    // 打开词句组合并模态框
    function openMergeGroupsModal() {
      if (!currentMeaning.value) {
        console.warn('Cannot open merge modal: currentMeaning is null')
        return
      }
      sourceMeaningId.value = currentMeaning.value.id
      targetMeaningId.value = null
      mergeMessage.value = ''
      showMergeGroupsModal.value = true
    }
    
    // 关闭词句组合并模态框
    function closeMergeGroupsModal() {
      showMergeGroupsModal.value = false
      sourceMeaningId.value = null
      targetMeaningId.value = null
      mergeMessage.value = ''
    }
    
    // 执行词句组合并
    async function mergeMeaningGroups(targetMeaningIdParam) {
      if (!sourceMeaningId.value) return
      
      // 前端验证
      if (sourceMeaningId.value === targetMeaningIdParam) {
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
        const res = await fetch('/api/v1/meanings/merge', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            source_meaning_id: sourceMeaningId.value,
            target_meaning_id: targetMeaningIdParam
          })
        })
        
        if (!res.ok) {
          const errorData = await res.json()
          throw new Error(errorData.error || 'Failed to merge meaning groups')
        }
        
        const result = await res.json()
        
        // 关闭模态框
        closeMergeGroupsModal()
        
        // 刷新数据
        await load()
        
        // 切换到目标词句组
        setActiveTab(targetMeaningIdParam.toString())
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
      if (!confirm(t('confirm_unlink'))) return

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
          body: JSON.stringify({ meaning_id: null })
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
      currentMeaningIdForAssociation.value = activeTab.value !== 'search' ? activeTab.value : (meanings.value && meanings.value.length > 0 ? meanings.value[0].id : null);
      initialTextForCreation.value = searchText;
      showCreateExpressionModal.value = true;
    }

    // Handle SmartSearch create-new event (from search and associate tab)
    function handleSmartSearchCreateNew(searchText) {
      openCreateExpressionModal(searchText)
    }

    // Handle SmartSearch associate event (from search and associate tab)
    function handleSmartSearchAssociate(result) {
      openMeaningSelection(result)
    }

    // Handle SmartSearch create-new event (from within a group)
    function handleGroupSearchCreateNew(searchText) {
      openCreateExpressionModalForGroup(currentMeaning.value.id, searchText)
    }

    // Handle SmartSearch associate event (from within a group)
    async function handleGroupSearchAssociate(result) {
      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/expressions/${item.value.id}/meanings`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            meaning_id: currentMeaning.value.id
          })
        })

        if (!res.ok) {
          const errorData = await res.json()
          throw new Error(errorData.error || 'Failed to associate to meaning group')
        }

        // Refresh to show updated list
        await load()

        // Close search mode for this group
        toggleGroupSearch(currentMeaning.value.id)
      } catch (e) {
        console.error('Error associating to meaning:', e)
        alert(t('failed_to_associate_to_meaning'))
      }
    }

    // Open create expression modal for specific group
    function openCreateExpressionModalForGroup(meaningId, searchText = '') {
      currentMeaningIdForAssociation.value = meaningId;
      initialTextForCreation.value = searchText;
      showCreateExpressionModal.value = true;
    }

    // Remove expression from a group
    async function removeFromGroup(expressionId, meaningId) {
      if (!confirm(t('confirm_remove_from_group'))) return;

      const token = localStorage.getItem('authToken')
      if (!token) {
        alert(t('login_required'))
        return
      }

      try {
        const res = await fetch(`/api/v1/expressions/${expressionId}/meanings/${meaningId}`, {
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

      // Refresh to show newly created expression
      await load();
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

      if (!confirm(t('confirm_delete_expression'))) {
        return
      }

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
      translations,
      transLoading,
      meanings,
      linkedIds,
      isLinked,
      getLanguageDisplayName,
      // Group search
      groupSearchModes,
      toggleGroupSearch,
      handleGroupSearchCreateNew,
      handleGroupSearchAssociate,
      // 词句组合并
      showMergeGroupsModal,
      sourceMeaningId,
      targetMeaningId,
      mergeLoading,
      mergeMessage,
      openMergeGroupsModal,
      closeMergeGroupsModal,
      mergeMeaningGroups,
      otherMeanings,
      getMeaningIndex,
      // Global search
      globalSearchMode,
      globalSearchQuery,
      globalSearchResults,
      globalSearchLoading,
      globalSearchSearched,
      globalSearchMessage,
      toggleGlobalSearch,
      searchGlobal,
      associateGlobally,
      // Meaning selection
      showMeaningSelection,
      selectedExpressionForAssociation,
      expressionMeanings,
      expressionMeaningsLoading,
      openMeaningSelection,
      closeMeaningSelection,
      associateToSelectedMeaning,
      associateToNewMeaning,
      getMeaningDisplayText,
      // SmartSearch handlers
      handleSmartSearchCreateNew,
      handleSmartSearchAssociate,
      // Tab navigation
      activeTab,
      setActiveTab,
      currentMeaning,
      currentMembers,
      // Create expression modal
      showCreateExpressionModal,
      currentMeaningIdForAssociation,
      initialTextForCreation,
      openCreateExpressionModal,
      openCreateExpressionModalForGroup,
      handleExpressionCreated,
      removeFromGroup,
      handleTagsUpdate,
      unlink,
      // Delete expression
      canDeleteExpression,
      deleting,
      handleDelete
    }
  }
}
</script>