<template>
  <div class="max-w-7xl mx-auto">
    <div v-if="loading" class="flex items-center justify-center py-12">
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
      <div class="lg:col-span-2 space-y-6">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="border-b border-slate-200 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-800">{{ $t('expression_details') }}</h3>
          </div>
          <div class="p-3">
            <ExpressionCard :item="item" :key="item.id" :editable="true" :can-delete="canDeleteExpression"
              :is-deleting="deleting" @update-tags="handleTagsUpdate" @delete="handleDelete" />
          </div>
        </div>

        <div v-if="meanings.length > 0" class="space-y-4">
          <h3 class="text-lg font-bold text-slate-800">{{ $t('associated_expression_groups') }}</h3>
          <nav class="flex flex-wrap gap-2" role="tablist">
            <!-- Meaning group tabs -->
            <button v-for="(meaning, index) in meanings" :key="meaning.id" @click="setActiveTab(meaning.id)" :class="[
              'px-4 py-3 font-medium text-sm rounded-lg transition-colors',
              activeTab === meaning.id
                ? 'bg-blue-600 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            ]" role="tab" :aria-selected="activeTab === meaning.id">
              #{{ index + 1 }}
            </button>

            <!-- Search and associate tab (last) -->
            <button @click="setActiveTab('search')" :class="[
              'px-4 py-3 font-medium text-sm rounded-lg transition-colors',
              activeTab === 'search'
                ? 'bg-blue-600 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            ]" role="tab" :aria-selected="activeTab === 'search'">
              {{ $t('search_and_associate') }}
            </button>
          </nav>

          <!-- Search and associate tab content -->
          <div v-show="activeTab === 'search'" role="tabpanel">
            <div v-if="searchOtherExpressionsMode" class="border border-slate-200 rounded-lg bg-slate-50 p-4 mb-4">
              <div class="flex items-center gap-3 mb-3">
                <div class="flex-1">
                  <input v-model="searchOtherExpressionsQuery" :placeholder="$t('please_input')"
                    class="block w-full rounded-md border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3"
                    @keydown.enter="searchOtherExpressions()" />
                </div>
                <button @click="searchOtherExpressions()"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-2">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  {{ $t('search') }}
                </button>
              </div>

              <div v-if="searchOtherExpressionsLoading" class="flex items-center justify-center py-3">
                <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
                  viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                  </path>
                </svg>
                <span class="ml-2 text-slate-600">{{ $t('searching') }}</span>
              </div>

              <div v-else-if="searchOtherExpressionsResults && searchOtherExpressionsResults.length > 0"
                class="mt-3 space-y-3">
                <div v-for="expr in searchOtherExpressionsResults" :key="expr.id"
                  class="bg-white rounded-lg border border-slate-200 overflow-hidden">
                  <div @click="toggleExpressionExpansion(expr.id)"
                    class="p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                    <div class="flex items-center justify-between">
                      <div class="flex-1">
                        <div class="font-semibold text-slate-800">{{ expr.text }}</div>
                        <div class="text-sm text-slate-500 mt-1">
                          <span>{{ getLanguageDisplayName(expr.language_code) }}</span>
                          <span v-if="expr.region_name" class="ml-2">• {{ expr.region_name }}</span>
                        </div>
                      </div>
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400 transition-transform"
                        :class="{ 'rotate-180': expandedExpressionId === expr.id }" fill="none" viewBox="0 0 24 24"
                        stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </div>
                  </div>

                  <!-- Expanded meaning groups -->
                  <div v-if="expandedExpressionId === expr.id" class="border-t border-slate-200 bg-slate-50 p-3">
                    <div v-if="expr.meanings && expr.meanings.length > 0" class="space-y-2">
                      <div class="text-xs text-slate-500 mb-2">{{ $t('expression_groups') }}:</div>
                      <div v-for="meaning in expr.meanings" :key="meaning.id"
                        class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium cursor-pointer transition-colors"
                        :class="isAlreadyInGroup(meaning.id) ? 'bg-slate-100 text-slate-500' : 'bg-blue-100 text-blue-700 hover:bg-blue-200'"
                        @click.stop="!isAlreadyInGroup(meaning.id) && associateToSearchResultGroup(meaning.id)">
                        <span>{{ getMeaningDisplayText(meaning) }}</span>
                        <span v-if="isAlreadyInGroup(meaning.id)" class="text-xs">({{ $t('already_in_group') }})</span>
                      </div>
                    </div>
                    <div v-else class="text-sm text-slate-500">
                      {{ $t('no_meaning_groups_for_expression') }}
                    </div>
                  </div>
                </div>
              </div>

              <div v-else-if="searchOtherExpressionsSearched" class="text-center py-3 text-slate-500 text-sm">
                {{ $t('no_expressions_found') }}
              </div>
            </div>
          </div>

          <!-- Meaning group tab contents -->
          <div v-if="currentMeaning && activeTab !== 'search'" role="tabpanel">
            <div class="bg-white rounded-xl shadow-sm border border-slate-200">
              <div class="border-b border-slate-200 px-6 py-4 flex justify-between items-center">
                <span class="text-slate-600">{{ currentMembers.length }} {{
                  $t('expressions') }}</span>
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
                class="border-b border-slate-200 bg-slate-50 px-6 py-4">
                <div class="flex items-center gap-3">
                  <div class="flex-1">
                    <input v-model="groupSearchQueries[currentMeaning.id]" :placeholder="$t('please_input')"
                      class="block w-full rounded-md border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3"
                      @keydown.enter="searchInGroup(currentMeaning.id)" />
                  </div>
                  <button @click="searchInGroup(currentMeaning.id)"
                    class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                      stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    {{ $t('search') }}
                  </button>
                </div>

                <div v-if="groupSearchLoading[currentMeaning.id]" class="flex items-center justify-center py-3">
                  <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
                    viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                    </path>
                  </svg>
                  <span class="ml-2 text-slate-600">{{ $t('searching') }}</span>
                </div>

                <div
                  v-else-if="groupSearchResults[currentMeaning.id] && groupSearchResults[currentMeaning.id].length > 0"
                  class="mt-3 space-y-2">
                  <div v-for="c in groupSearchResults[currentMeaning.id]" :key="c && c.id"
                    class="flex gap-3 items-center p-2 bg-white rounded-lg">
                    <div v-if="c && item && c.id !== item.id" class="flex-1">
                      <ExpressionCard :item="c" />
                    </div>
                    <div v-if="c && item && c.id !== item.id && !isLinked(c.id)">
                      <button @click="openMeaningSelection(c, currentMeaning.id)"
                        class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-1.5 text-sm">
                        {{ $t('link') }}
                      </button>
                    </div>
                  </div>
                </div>

                <div v-else-if="groupSearchSearched[currentMeaning.id]" class="text-center py-3 text-slate-500 text-sm">
                  {{ $t('no_expressions_found') }}
                </div>
              </div>

              <div class="p-4">
                <div v-if="currentMembers.length > 0" class="space-y-2">
                  <div v-for="member in currentMembers" :key="member.id"
                    class="flex items-center gap-3 py-2 border-b border-slate-100 last:border-0">
                    <div class="flex-1">
                      <ExpressionCard :item="member" />
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
            <div class="flex items-center gap-3 mb-3">
              <div class="flex-1">
                <input v-model="globalSearchQuery" :placeholder="$t('please_input')"
                  class="block w-full rounded-md border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3"
                  @keydown.enter="searchGlobal()" />
              </div>
              <button @click="searchGlobal()"
                class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                {{ $t('search') }}
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
            </div>
          </div>
        </div>
      </div>

      <!-- Right column: version history -->
      <div class="lg:col-span-1">
        <VersionHistory :expressionId="id" />
      </div>
    </div>

    <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
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
      @close="showCreateExpressionModal = false" @expression-created="handleExpressionCreated" />

    <!-- Meaning Selection Modal -->
    <div v-if="showMeaningSelection && selectedExpressionForAssociation"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-xl shadow-lg max-w-2xl w-full mx-4 max-h-[80vh] flex flex-col">
        <div class="border-b border-slate-200 px-6 py-4 flex justify-between items-center">
          <div>
            <h3 class="text-lg font-bold text-slate-800">{{ $t('select_meaning_group') }}</h3>
            <p class="text-slate-500 text-sm mt-1">
              {{ $t('select_meaning_to_associate') }}: <strong>"{{ selectedExpressionForAssociation.text }}"</strong>
            </p>
          </div>
          <button @click="closeMeaningSelection" class="text-slate-400 hover:text-slate-600 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto px-6 py-4">
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
              <div class="flex justify-between items-center">
                <div>
                  <h4 class="font-semibold text-slate-800">{{ $t('expression_group', { id: meaning.id }) }}</h4>
                  <p class="text-sm text-slate-500 mt-1">{{ $t('created_by') }}: {{ meaning.created_by ||
                    $t('anonymous') }}</p>
                </div>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
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

        <div class="border-t border-slate-200 px-6 py-4">
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

export default {
  name: 'Detail',
  components: { ExpressionCard, VersionHistory, CreateExpression },
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
    const groupSearchQueries = ref({})
    const groupSearchResults = ref({})
    const groupSearchLoading = ref({})
    const groupSearchSearched = ref({})
    const groupSearchMessages = ref({})

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

    // Search other expressions mode
    const searchOtherExpressionsMode = ref(false)
    const searchOtherExpressionsQuery = ref('')
    const searchOtherExpressionsResults = ref([])
    const searchOtherExpressionsLoading = ref(false)
    const searchOtherExpressionsSearched = ref(false)
    const expandedExpressionId = ref(null)

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
      return members
    })

    // Set active tab and reset expansion
    function setActiveTab(tabId) {
      activeTab.value = tabId
      expandedExpressionId.value = null
      // Automatically enable search mode when switching to search tab
      if (tabId === 'search' && !searchOtherExpressionsMode.value) {
        searchOtherExpressionsMode.value = true
      }
    }

    // Create expression modal
    const showCreateExpressionModal = ref(false)
    const currentMeaningIdForAssociation = ref(null)



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
                  members: members.filter(m => m.id !== item.value.id)
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
        // Initialize empty state
        if (!groupSearchQueries.value[meaningId]) {
          groupSearchQueries.value[meaningId] = ''
        }
        if (!groupSearchResults.value[meaningId]) {
          groupSearchResults.value[meaningId] = []
        }
        if (!groupSearchSearched.value[meaningId]) {
          groupSearchSearched.value[meaningId] = false
        }
      }
    }

    // Search in specific group
    async function searchInGroup(meaningId) {
      groupSearchLoading.value[meaningId] = true
      groupSearchSearched.value[meaningId] = false
      groupSearchMessages.value[meaningId] = ''

      try {
        const params = new URLSearchParams()
        const query = groupSearchQueries.value[meaningId] || ''
        if (query) params.set('q', query)
        const url = `/api/v1/search?${params.toString()}`

        const res = await fetch(url)
        if (!res.ok) throw new Error('search failed')

        groupSearchResults.value[meaningId] = await res.json()
        groupSearchSearched.value[meaningId] = true
      } catch (e) {
        groupSearchMessages.value[meaningId] = String(e)
        groupSearchResults.value[meaningId] = []
        groupSearchSearched.value[meaningId] = true
      } finally {
        groupSearchLoading.value[meaningId] = false
      }
    }

    // Associate to specific group
    async function associateToGroup(target, meaningId) {
      groupSearchMessages.value[meaningId] = ''

      const token = localStorage.getItem('authToken')
      if (!token) {
        groupSearchMessages.value[meaningId] = t('must_be_logged_in_to_associate')
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
                language_code: target.language_code,
                meaning_id: meaningId
              }
            ]
          })
        })

        if (!batchRes.ok) {
          const errorData = await batchRes.json()
          throw new Error(errorData.error || 'Failed to associate expressions')
        }

        const result = await batchRes.json()
        groupSearchMessages.value[meaningId] = t('expressions_processed', { count: 2, meaningId: result.meaning_id })

        // Refresh to show updated list
        await load()

        // Reset search for this group
        groupSearchQueries.value[meaningId] = ''
        groupSearchResults.value[meaningId] = []
        groupSearchSearched.value[meaningId] = false
      } catch (e) {
        console.error('Association error:', e)
        groupSearchMessages.value[meaningId] = String(e)
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
        expressionMeanings.value = exprData.meanings || []
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

    // Check if current expression is already in a group
    function isAlreadyInGroup(meaningId) {
      return meanings.value && meanings.value.some(m => m.id === meaningId)
    }

    // Toggle search other expressions mode
    function toggleSearchOtherExpressions() {
      searchOtherExpressionsMode.value = !searchOtherExpressionsMode.value
      if (searchOtherExpressionsMode.value) {
        searchOtherExpressionsQuery.value = ''
        searchOtherExpressionsResults.value = []
        searchOtherExpressionsSearched.value = false
        expandedExpressionId.value = null
      }
    }

    // Toggle expression expansion
    function toggleExpressionExpansion(exprId) {
      if (expandedExpressionId.value === exprId) {
        expandedExpressionId.value = null
      } else {
        expandedExpressionId.value = exprId
      }
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

    // Search other expressions
    async function searchOtherExpressions() {
      searchOtherExpressionsLoading.value = true
      searchOtherExpressionsSearched.value = false

      try {
        const params = new URLSearchParams()
        const query = searchOtherExpressionsQuery.value || ''
        if (query) params.set('q', query)
        params.set('include_meanings', 'true')
        const url = `/api/v1/search?${params.toString()}`

        const res = await fetch(url)
        if (!res.ok) throw new Error('search failed')

        const results = await res.json()

        // Fetch members for each meaning in the results
        for (const expr of results) {
          if (expr.meanings && expr.meanings.length > 0) {
            for (const meaning of expr.meanings) {
              try {
                const membersRes = await fetch(`/api/v1/expressions?meaning_id=${meaning.id}&skip=0&limit=100`)
                if (membersRes.ok) {
                  const members = await membersRes.json()
                  meaning.members = members
                }
              } catch (e) {
                console.error(`Failed to fetch members for meaning ${meaning.id}:`, e)
                meaning.members = []
              }
            }
          }
        }

        searchOtherExpressionsResults.value = results
        searchOtherExpressionsSearched.value = true
      } catch (e) {
        console.error('Search error:', e)
        searchOtherExpressionsResults.value = []
        searchOtherExpressionsSearched.value = true
      } finally {
        searchOtherExpressionsLoading.value = false
      }
    }

    // Associate to a meaning from search results
    async function associateToSearchResultGroup(meaningId) {
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

        // Reset search
        searchOtherExpressionsQuery.value = ''
        searchOtherExpressionsResults.value = []
        searchOtherExpressionsSearched.value = false
        searchOtherExpressionsMode.value = false
      } catch (e) {
        console.error('Error associating to meaning:', e)
        alert(t('failed_to_associate_to_meaning'))
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
    function openCreateExpressionModal() {
      currentMeaningIdForAssociation.value = activeTab.value !== 'search' ? activeTab.value : (meanings.value && meanings.value.length > 0 ? meanings.value[0].id : null);
      showCreateExpressionModal.value = true;
    }

    // Open create expression modal for specific group
    function openCreateExpressionModalForGroup(meaningId) {
      currentMeaningIdForAssociation.value = meaningId;
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

        // Redirect to home after successful deletion
        router.push('/')
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
      groupSearchQueries,
      groupSearchResults,
      groupSearchLoading,
      groupSearchSearched,
      groupSearchMessages,
      toggleGroupSearch,
      searchInGroup,
      associateToGroup,
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
      // Search other expressions
      searchOtherExpressionsMode,
      searchOtherExpressionsQuery,
      searchOtherExpressionsResults,
      searchOtherExpressionsLoading,
      searchOtherExpressionsSearched,
      toggleSearchOtherExpressions,
      searchOtherExpressions,
      associateToSearchResultGroup,
      isAlreadyInGroup,
      expandedExpressionId,
      toggleExpressionExpansion,
      getMeaningDisplayText,
      // Tab navigation
      activeTab,
      setActiveTab,
      currentMeaning,
      currentMembers,
      getMeaningDisplayText,
      // Create expression modal
      showCreateExpressionModal,
      currentMeaningIdForAssociation,
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