<template>
  <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <h2 class="text-2xl font-bold text-slate-800 mb-2">{{ $t('create_title') }}</h2>
      <p class="text-slate-600 mb-6">{{ $t('add_expression_description') }}</p>

      <div class="mb-4 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" v-model="minimalMode" class="sr-only peer">
            <div
              class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600">
            </div>
            <span class="ml-3 text-sm font-medium text-slate-700">{{ $t('minimal_mode') }}</span>
          </label>
        </div>
      </div>

      <div v-if="!minimalMode" class="mb-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
        <div class="flex items-start gap-3">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600 mt-0.5" fill="none" viewBox="0 0 24 24"
            stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div class="text-sm text-blue-800">
            <p>{{ $t('batch_expression_hint') }}</p>
          </div>
        </div>
      </div>

      <div v-if="minimalMode" class="border border-slate-200 rounded-lg overflow-hidden mb-6">
        <table class="w-full">
          <thead class="bg-slate-50">
            <tr>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider w-1/4">{{
                $t('language') }} *</th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider">{{
                $t('text') }} *</th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider w-1/4">{{
                $t('collections') }}</th>
              <th class="px-4 py-3 w-16"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(expression, index) in expressions" :key="expression.id" class="border-t border-slate-100">
              <td class="px-4 py-3">
                <select v-model="expression.language_code"
                  class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-1.5 px-2 text-sm appearance-none text-slate-800"
                  :disabled="languagesLoading">
                  <option v-if="languagesLoading" value="" disabled>{{ $t('loading_languages') }}</option>
                  <option v-else value="" disabled>{{ $t('select_language') }}</option>
                  <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                    {{ lang.name }} ({{ lang.code }})
                  </option>
                </select>
              </td>
              <td class="px-4 py-3">
                <ImageUploader v-if="expression.language_code === 'image'" :existing-image-url="expression.text"
                  :compact="true" @image-ready="handleImageReady(index, $event)" @image-cleared="handleImageCleared(index)" />
                <textarea v-else v-model="expression.text" rows="1"
                  class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-1.5 px-2 text-sm text-slate-800 resize-none"
                  :placeholder="$t('text_placeholder')"></textarea>
              </td>
              <td class="px-4 py-3">
                <div class="relative">
                  <input :value="getSelectedCollectionNames(expression.collections)"
                    class="block w-full rounded-md border border-slate-300 shadow-sm py-1.5 px-2 pr-8 text-sm bg-slate-100 text-slate-500 cursor-pointer"
                    readonly @click="toggleCollectionSelector(index)" />
                  <div v-if="expression.showCollectionSelector"
                    class="absolute right-1 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-slate-600 cursor-pointer"
                    @click.stop="toggleCollectionSelector(index)">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                      stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </div>
              </td>
              <td class="px-4 py-3">
                <button v-if="expressions.length > 1" @click="removeExpression(index)"
                  class="p-1 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded"
                  :title="$t('remove_expression')">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </td>
            </tr>
          </tbody>
        </table>

        <div v-if="expressions.some(e => e.showCollectionSelector)" class="border-t border-slate-200 p-4 bg-slate-50">
          <div v-if="collectionsLoading" class="text-center py-4 text-slate-500">
            <svg class="animate-spin h-5 w-5 text-blue-500 inline mr-2" xmlns="http://www.w3.org/2000/svg" fill="none"
              viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
              </path>
            </svg>
            {{ $t('loading_collections') }}
          </div>

          <div v-else-if="userCollections.length === 0" class="text-center py-4 text-slate-500">
            <p>{{ $t('no_collections') }}</p>
            <button @click="openCreateCollectionModal(0)" class="mt-2 text-blue-600 hover:text-blue-800">
              {{ $t('create_first_collection') }}
            </button>
          </div>

          <div v-else class="space-y-2 max-h-48 overflow-y-auto">
            <p class="text-sm font-medium text-slate-700 mb-2">{{ $t('select_collections') }}</p>
            <label v-for="collection in userCollections" :key="collection.id"
              class="flex items-center gap-3 p-2 hover:bg-slate-100 rounded cursor-pointer">
              <input type="checkbox" :checked="expressions[activeCollectionIndex]?.collections.includes(collection.id)"
                @change="toggleCollectionSelection(activeCollectionIndex, collection.id)"
                class="form-checkbox h-4 w-4 text-blue-600 rounded" />
              <div class="flex-1">
                <span class="text-slate-800">{{ collection.name }}</span>
                <span class="text-xs text-slate-400 ml-2">({{ collection.items_count || 0 }} {{ $t('items') }})</span>
              </div>
            </label>
          </div>
        </div>
      </div>

      <div v-else v-for="(expression, index) in expressions" :key="expression.id"
        class="mb-6 p-4 border border-slate-200 rounded-lg relative">
        <button v-if="expressions.length > 1" @click="removeExpression(index)"
          class="absolute top-2 right-2 p-1 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded"
          :title="$t('remove_expression')">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('language') }} *</label>
          <div class="flex gap-2">
            <div class="relative flex-1">
              <select v-model="expression.language_code"
                class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3 appearance-none text-slate-800"
                :disabled="languagesLoading" @change="handleLanguageChange(index)">
                <option v-if="languagesLoading" value="" disabled>{{ $t('loading_languages') }}</option>
                <option v-else value="" disabled>{{ $t('select_language') }}</option>
                <option v-for="lang in languages" :key="lang.code" :value="lang.code">
                  {{ lang.name }} ({{ lang.code }})
                </option>
              </select>
              <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </div>
            <button @click="showAddLanguageModal = true"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
              :title="$t('add_language')">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
            </button>
          </div>
        </div>

        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ expression.language_code === 'image' ?
            $t('image') : $t('text') }} *</label>
          <ImageUploader v-if="expression.language_code === 'image'" :existing-image-url="expression.text"
            @image-ready="handleImageReady(index, $event)" @image-cleared="handleImageCleared(index)" />
          <textarea v-else v-model="expression.text" rows="3"
            class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-4 text-slate-800"
            :placeholder="$t('text_placeholder')"></textarea>
        </div>

        <div class="border border-slate-200 rounded-lg">
          <button @click="toggleAdvanced(index)"
            class="w-full flex items-center justify-between p-3 hover:bg-slate-50 transition-colors rounded-lg">
            <span class="text-sm font-medium text-slate-700">{{ $t('advanced_options') }}</span>
            <svg xmlns="http://www.w3.org/2000/svg"
              :class="['h-5 w-5 text-slate-500 transition-transform', expression.showAdvanced ? 'rotate-180' : '']"
              fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          <div v-if="expression.showAdvanced" class="p-4 pt-0 space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('create_region') }}</label>
              <div class="flex gap-2">
                <input v-model="expression.region_display"
                  class="block flex-1 rounded-md border border-slate-300 shadow-sm py-2 px-4 text-slate-500" />
                <button @click="detectLocation(index)"
                  :disabled="expression.detectingLocation || expression.parsingLocation"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                  :title="$t('detect_location')">
                  <svg v-if="expression.detectingLocation || expression.parsingLocation"
                    class="animate-spin h-5 w-5 text-slate-600" xmlns="http://www.w3.org/2000/svg" fill="none"
                    viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                    </path>
                  </svg>
                  <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none"
                    viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M17.657 16.657L13.414 20.9a1 1 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </button>
                <button @click="toggleMapSelector(index)" :disabled="expression.parsingLocation"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                  :title="$t('select_on_map')">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
                  </svg>
                </button>
              </div>

              <div v-if="expression.showMapSelector" class="mt-3 border border-slate-200 rounded-lg overflow-hidden">
                <div :id="`region-map-${index}`" class="w-full h-64"></div>
                <div class="p-3 bg-slate-50 text-sm text-slate-600">
                  {{ $t('click_on_map_to_select') }}
                </div>
              </div>

              <div v-if="expression.parsingLocation" class="mt-2 flex items-center text-sm text-slate-600">
                <svg class="animate-spin h-4 w-4 mr-2 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
                  viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                  </path>
                </svg>
                {{ $t('parsing_location') }}
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('expression_audio_label') }} ({{
                $t('optional') }})</label>
              <AudioRecorder @audio-ready="payload => handleAudioReady(index, payload)"
                @audio-cleared="() => handleAudioCleared(index)" />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">
                {{ $t('collections') }} ({{ $t('optional') }})
              </label>
              <div class="flex gap-2">
                <input :value="getSelectedCollectionNames(expression.collections)"
                  class="block flex-1 rounded-md border border-slate-300 shadow-sm py-2 px-4 bg-slate-100 text-slate-500 cursor-pointer"
                  readonly @click="toggleCollectionSelector(index)" />
                <button @click="toggleCollectionSelector(index)"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                  :title="$t('select_collections')">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                  </svg>
                </button>
                <button @click="openCreateCollectionModal(index)"
                  class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-3"
                  :title="$t('create_collection')">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                </button>
              </div>

              <div v-if="expression.showCollectionSelector" class="mt-3 border border-slate-200 rounded-lg p-3">
                <div v-if="collectionsLoading" class="text-center py-4 text-slate-500">
                  <svg class="animate-spin h-5 w-5 text-blue-500 inline mr-2" xmlns="http://www.w3.org/2000/svg"
                    fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                    </path>
                  </svg>
                  {{ $t('loading_collections') }}
                </div>

                <div v-else-if="userCollections.length === 0" class="text-center py-4 text-slate-500">
                  <p>{{ $t('no_collections') }}</p>
                  <button @click="openCreateCollectionModal(index)" class="mt-2 text-blue-600 hover:text-blue-800">
                    {{ $t('create_first_collection') }}
                  </button>
                </div>

                <div v-else class="space-y-2 max-h-48 overflow-y-auto">
                  <label v-for="collection in userCollections" :key="collection.id"
                    class="flex items-center gap-3 p-2 hover:bg-slate-50 rounded cursor-pointer">
                    <input type="checkbox" :checked="expression.collections.includes(collection.id)"
                      @change="toggleCollectionSelection(index, collection.id)"
                      class="form-checkbox h-4 w-4 text-blue-600 rounded" />
                    <div class="flex-1">
                      <span class="text-slate-800">{{ collection.name }}</span>
                      <span class="text-xs text-slate-400 ml-2">({{ collection.items_count || 0 }} {{ $t('items')
                      }})</span>
                    </div>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <button @click="addExpression"
        class="w-full mb-6 py-3 px-4 border-2 border-dashed border-slate-300 rounded-lg text-slate-600 hover:border-blue-400 hover:text-blue-600 hover:bg-blue-50 transition-colors flex items-center justify-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        {{ $t('add_another_expression') }}
      </button>

      <div class="flex flex-wrap gap-3">
        <button @click="submit" :disabled="submitting"
          class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-6 py-2 disabled:opacity-50 disabled:cursor-not-allowed">
          <svg v-if="submitting" class="animate-spin h-4 w-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none"
            viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
            </path>
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24"
            stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          {{ submitting ? $t('submitting') : $t('submit') }}
        </button>
        <button @click="goBack"
          class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
          {{ $t('cancel') }}
        </button>
      </div>

      <div v-if="error" class="mt-4 p-3 bg-red-50 text-red-700 rounded-lg flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24"
          stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        {{ error }}
      </div>

      <div v-if="success" class="mt-4 p-3 bg-green-50 text-green-700 rounded-lg">
        <div class="flex items-center mb-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24"
            stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          {{ $t('success') }}:
        </div>

        <div v-if="createdExpressions.length > 0" class="flex flex-wrap items-center gap-1">
          <template v-for="(expr, index) in createdExpressions" :key="expr.id">
            <router-link v-if="expr.language_code === 'image'" :to="{ name: 'Detail', params: { id: expr.id } }"
              class="inline-flex items-center">
              <img :src="expr.text" class="h-8 w-8 rounded object-cover" alt="Expression image" />
            </router-link>
            <router-link v-else :to="{ name: 'Detail', params: { id: expr.id } }"
              class="text-blue-600 hover:text-blue-800 hover:underline">
              {{ expr.text }}
            </router-link>
            <span v-if="index < createdExpressions.length - 1" class="text-slate-400">|</span>
          </template>
        </div>
      </div>
    </div>

    <!-- Add Language Modal -->
    <AddLanguageModal :visible="showAddLanguageModal" :adding-language="addingLanguage"
      @close="showAddLanguageModal = false" @add-language="handleAddLanguage" />

    <!-- Create Collection Modal -->
    <div v-if="showCreateCollectionModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
        <h2 class="text-xl font-bold mb-4">{{ $t('new_collection') }}</h2>

        <form @submit.prevent="handleCreateCollection">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('collection_name') }} *
            </label>
            <input v-model="collectionForm.name" type="text" required
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              :placeholder="$t('e_g_my_favorites')" />
          </div>

          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('description') }}
            </label>
            <textarea v-model="collectionForm.description" rows="3"
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              :placeholder="$t('e_g_useful_for_greeting')"></textarea>
          </div>

          <div class="mb-6">
            <label class="flex items-center cursor-pointer">
              <input v-model="collectionForm.is_public" type="checkbox"
                class="form-checkbox h-4 w-4 text-blue-600 rounded" />
              <span class="ml-2 text-sm text-gray-700">{{ $t('public_access') }}</span>
            </label>
          </div>

          <div class="flex justify-end gap-3">
            <button type="button" @click="closeCreateCollectionModal"
              class="px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50">
              {{ $t('cancel') }}
            </button>
            <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              :disabled="creatingCollection">
              {{ creatingCollection ? $t('saving') : $t('save') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { languagesApi } from '../api/index.ts'
import AddLanguageModal from '../components/AddLanguageModal.vue'
import AudioRecorder from '../components/AudioRecorder.vue'
import ImageUploader from '../components/ImageUploader.vue'

let expressionIdCounter = 0

export default {
  name: 'CreateExpressionPage',
  components: { AddLanguageModal, AudioRecorder, ImageUploader },
  setup() {
    const route = useRoute()
    const router = useRouter()
    const { t, locale } = useI18n()

    const expressions = ref([
      {
        id: ++expressionIdCounter,
        text: route.query.text || '',
        language_code: route.query.language_code || '',
        region_input: route.query.region || '',
        region_display: '',
        detectingLocation: false,
        parsingLocation: false,
        showMapSelector: false,
        collections: [],
        showCollectionSelector: false,
        audioBlob: null,
        audioMimeType: null,
        showAdvanced: false
      }
    ])

    const languages = ref([])
    const languagesLoading = ref(false)
    const showAddLanguageModal = ref(false)
    const addingLanguage = ref(false)
    const error = ref(null)
    const success = ref(false)
    const createdExpressions = ref([])
    const submitting = ref(false)
    const globalShowAdvanced = ref(false)
    const minimalMode = ref(false)
    const activeCollectionIndex = ref(null)

    // Collection-related state
    const userCollections = ref([])
    const collectionsLoading = ref(false)
    const showCreateCollectionModal = ref(false)
    const currentExpressionIndex = ref(null)
    const addingToCollections = ref(false)
    const creatingCollection = ref(false)
    const collectionForm = ref({
      name: '',
      description: '',
      is_public: false
    })

    const maps = new Map()
    let L = null

    const updateRegionDisplay = (expression) => {
      if (!expression.region_input) {
        expression.region_display = ''
        return
      }
      try {
        const geoInfo = JSON.parse(expression.region_input)
        expression.region_display = geoInfo.name || expression.region_input
      } catch (e) {
        expression.region_display = expression.region_input
      }
    }

    const getSelectedCollectionNames = (collectionIds) => {
      if (!collectionIds || collectionIds.length === 0) {
        return ''
      }
      return collectionIds
        .map(id => {
          const collection = userCollections.value.find(c => c.id === id)
          return collection ? collection.name : ''
        })
        .filter(name => name !== '')
        .join(', ')
    }

    const loadLanguages = async () => {
      languagesLoading.value = true
      try {
        const result = await languagesApi.getAll()
        if (result.success && result.data) {
          languages.value = result.data
        } else {
          languages.value = []
        }
      } catch (err) {
        console.error('Failed to load languages:', err)
        error.value = 'Failed to load languages: ' + err.message
      } finally {
        languagesLoading.value = false
      }
    }

    const handleAddLanguage = async (languageObj) => {
      try {
        await loadLanguages()
        expressions.value[0].language_code = languageObj.code
        showAddLanguageModal.value = false
      } catch (error) {
        console.error('Error handling added language:', error)
        alert(t('create.addLanguageFailed'))
      }
    }

    const addExpression = () => {
      expressions.value.push({
        id: ++expressionIdCounter,
        text: '',
        language_code: '',
        region_input: '',
        region_display: '',
        detectingLocation: false,
        parsingLocation: false,
        showMapSelector: false,
        collections: [],
        collectionNote: '',
        showCollectionSelector: false,
        audioBlob: null,
        audioMimeType: null,
        showAdvanced: globalShowAdvanced.value
      })
    }

    const toggleAdvanced = (index) => {
      const newState = !expressions.value[index].showAdvanced
      expressions.value[index].showAdvanced = newState
      globalShowAdvanced.value = newState
    }

    watch(
      () => expressions.value.map(e => e.showAdvanced),
      (newValues, oldValues) => {
        if (oldValues) {
          for (let i = 0; i < newValues.length; i++) {
            if (newValues[i] !== oldValues[i]) {
              globalShowAdvanced.value = newValues[i]
              break
            }
          }
        }
      },
      { deep: true }
    )

    const removeExpression = (index) => {
      if (expressions.value[index].showMapSelector) {
        const map = maps.get(expressions.value[index].id)
        if (map) {
          map.remove()
          maps.delete(expressions.value[index].id)
        }
      }
      expressions.value.splice(index, 1)
    }

    const handleAudioReady = (index, payload) => {
      expressions.value[index].audioBlob = payload.blob
      expressions.value[index].audioMimeType = payload.mimeType
    }

    const handleAudioCleared = (index) => {
      expressions.value[index].audioBlob = null
      expressions.value[index].audioMimeType = null
    }

    const handleImageReady = (index, imageUrl) => {
      expressions.value[index].text = imageUrl
    }

    const handleImageCleared = (index) => {
      expressions.value[index].text = ''
    }

    const handleLanguageChange = (index) => {
      const langCode = expressions.value[index].language_code
      if (langCode && expressions.value[index].region_input) {
        const geoInfo = parseGeoInfo(expressions.value[index].region_input)
        if (geoInfo && (!geoInfo.country_code || geoInfo.country_code === '')) {
          const lang = languages.value.find(l => l.code === langCode)
          if (lang && lang.region_code) {
            geoInfo.country_code = lang.region_code
            expressions.value[index].region_input = JSON.stringify(geoInfo)
            updateRegionDisplay(expressions.value[index])
          }
        }
      }
    }

    const parseGeoInfo = (geoString) => {
      if (!geoString) return null
      try {
        return JSON.parse(geoString)
      } catch (e) {
        return { name: geoString, latitude: null, longitude: null }
      }
    }

    const loadUserCollections = async () => {
      collectionsLoading.value = true
      try {
        const token = localStorage.getItem('authToken')
        if (!token) {
          userCollections.value = []
          return
        }

        const response = await fetch('/api/v1/collections', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (!response.ok) {
          throw new Error('Failed to load collections')
        }

        const result = await response.json()
        userCollections.value = result.success ? result.data : result
      } catch (err) {
        console.error('Failed to load collections:', err)
        userCollections.value = []
      } finally {
        collectionsLoading.value = false
      }
    }

    const toggleCollectionSelector = (index) => {
      expressions.value.forEach((expr, i) => {
        if (minimalMode.value) {
          if (i === index) {
            expr.showCollectionSelector = !expr.showCollectionSelector
            activeCollectionIndex.value = i
          } else {
            expr.showCollectionSelector = false
          }
        } else {
          if (i === index) {
            expr.showCollectionSelector = !expr.showCollectionSelector
          }
        }
      })
      if (expressions.value[index].showCollectionSelector && userCollections.value.length === 0) {
        loadUserCollections()
      }
    }

    const toggleCollectionSelection = (exprIndex, collectionId) => {
      const expr = expressions.value[exprIndex]
      const indexInCollections = expr.collections.indexOf(collectionId)
      if (indexInCollections > -1) {
        expr.collections.splice(indexInCollections, 1)
      } else {
        expr.collections.push(collectionId)
      }
    }

    const openCreateCollectionModal = (index) => {
      currentExpressionIndex.value = index
      showCreateCollectionModal.value = true
    }

    const closeCreateCollectionModal = () => {
      showCreateCollectionModal.value = false
      currentExpressionIndex.value = null
    }

    const handleCollectionCreated = async (collection) => {
      await loadUserCollections()
      if (currentExpressionIndex.value !== null) {
        const expr = expressions.value[currentExpressionIndex.value]
        expr.collections.push(collection.id)
        expr.showCollectionSelector = true
      }
      closeCreateCollectionModal()
    }

    const handleCreateCollection = async () => {
      if (!collectionForm.value.name.trim()) {
        return
      }

      creatingCollection.value = true
      try {
        const token = localStorage.getItem('authToken')
        if (!token) {
          alert(t('must_be_logged_in'))
          return
        }

        const response = await fetch('/api/v1/collections', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            name: collectionForm.value.name,
            description: collectionForm.value.description,
            is_public: collectionForm.value.is_public
          })
        })

        if (!response.ok) {
          throw new Error('Failed to create collection')
        }

        const result = await response.json()
        const newCollection = result.success ? result.data : result
        await handleCollectionCreated(newCollection)

        // Reset form
        collectionForm.value = {
          name: '',
          description: '',
          is_public: false
        }
      } catch (err) {
        console.error('Failed to create collection:', err)
        alert(t('create_collection_failed'))
      } finally {
        creatingCollection.value = false
      }
    }

    const loadLeaflet = () => {
      return new Promise((resolve, reject) => {
        if (window.L) {
          resolve()
          return
        }

        const link = document.createElement('link')
        link.rel = 'stylesheet'
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
        link.onload = () => {
          const script = document.createElement('script')
          script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
          script.onload = () => {
            resolve()
          }
          script.onerror = () => {
            reject(new Error('Failed to load Leaflet JS'))
          }
          document.head.appendChild(script)
        }
        link.onerror = () => {
          reject(new Error('Failed to load Leaflet CSS'))
        }
        document.head.appendChild(link)
      })
    }

    const reverseGeocode = async (lat, lon, langCode) => {
      try {
        let nominatimLangCode = 'en';
        if (langCode) {
          nominatimLangCode = langCode.split('-')[0];
        } else if (locale.value) {
          nominatimLangCode = locale.value.split('-')[0];
        }

        const response = await fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&accept-language=${nominatimLangCode}`
        )

        if (response.ok) {
          const data = await response.json()

          if (data.address) {
            const address = data.address
            const locationParts = [
              address.neighbourhood || address.suburb || address.city_district,
              address.village || address.town || address.city,
              address.state_district || address.county || address.state || address.province,
              address.country
            ].filter(part => part)

            const countryCode = address.country_code?.toUpperCase() || null
            const countryName = address.country || null

            let displayName = locationParts.filter(part => part).join(', ')

            if (!displayName || displayName.trim() === '') {
              try {
                const fallbackResponse = await fetch(
                  `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&accept-language=en`
                )

                if (fallbackResponse.ok) {
                  const fallbackData = await fallbackResponse.json()

                  if (fallbackData.address) {
                    const fallbackAddress = fallbackData.address
                    const fallbackLocationParts = [
                      fallbackAddress.neighbourhood || fallbackAddress.suburb || fallbackAddress.city_district,
                      fallbackAddress.village || fallbackAddress.town || fallbackAddress.city,
                      fallbackAddress.state_district || fallbackAddress.county || fallbackAddress.state || fallbackAddress.province,
                      fallbackAddress.country
                    ].filter(part => part)

                    displayName = fallbackLocationParts.filter(part => part).join(', ') || `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                  } else {
                    displayName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                  }
                } else {
                  displayName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
                }
              } catch (e) {
                displayName = `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`
              }
            }

            return {
              name: displayName,
              latitude: parseFloat(lat),
              longitude: parseFloat(lon),
              country_code: countryCode,
              country_name: countryName
            }
          }
        }

        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon),
          country_code: null,
          country_name: null
        }
      } catch (err) {
        console.error('Reverse geocoding failed:', err)
        return {
          name: `${parseFloat(lat).toFixed(4)}, ${parseFloat(lon).toFixed(4)}`,
          latitude: parseFloat(lat),
          longitude: parseFloat(lon),
          country_code: null,
          country_name: null
        }
      }
    }

    const initMap = async (index) => {
      try {
        await loadLeaflet()
        L = window.L

        await new Promise(resolve => setTimeout(resolve, 100))

        const mapElement = document.getElementById(`region-map-${index}`)
        if (!mapElement) {
          console.error('Map element not found')
          return
        }

        const expressionId = expressions.value[index].id
        const existingMap = maps.get(expressionId)
        if (existingMap) {
          existingMap.remove()
          maps.delete(expressionId)
        }

        const map = L.map(`region-map-${index}`).setView([20, 0], 2)

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map)

        maps.set(expressionId, map)

        map.on('click', async (e) => {
          const { lat, lng } = e.latlng
          expressions.value[index].parsingLocation = true

          try {
            const geoInfo = await reverseGeocode(lat, lng, expressions.value[index].language_code)
            expressions.value[index].region_input = JSON.stringify(geoInfo)
            updateRegionDisplay(expressions.value[index])
          } catch (err) {
            console.error('Failed to process map click:', err)
            error.value = t('create.locationParsingFailed')
          } finally {
            expressions.value[index].parsingLocation = false
            expressions.value[index].showMapSelector = false
          }
        })
      } catch (err) {
        console.error('Failed to initialize map:', err)
        error.value = 'Failed to load map: ' + err.message
      }
    }

    const toggleMapSelector = async (index) => {
      expressions.value[index].showMapSelector = !expressions.value[index].showMapSelector
      if (expressions.value[index].showMapSelector) {
        setTimeout(() => {
          initMap(index)
        }, 100)
      } else {
        const map = maps.get(expressions.value[index].id)
        if (map) {
          map.remove()
          maps.delete(expressions.value[index].id)
        }
      }
    }

    const detectLocation = async (index) => {
      expressions.value[index].detectingLocation = true
      error.value = null

      if (!navigator.geolocation) {
        error.value = t('create.geolocationNotSupported')
        expressions.value[index].detectingLocation = false
        return
      }

      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords

          try {
            expressions.value[index].parsingLocation = true
            const geoInfo = await reverseGeocode(latitude, longitude, expressions.value[index].language_code)
            expressions.value[index].region_input = JSON.stringify(geoInfo)
            updateRegionDisplay(expressions.value[index])
          } catch (err) {
            console.error('Location processing failed:', err)
            error.value = t('create.locationParsingFailed')
          } finally {
            expressions.value[index].parsingLocation = false
            expressions.value[index].detectingLocation = false
          }
        },
        (err) => {
          console.error('Geolocation error:', err)
          error.value = t('create.locationDetectionFailed')
          expressions.value[index].detectingLocation = false
        },
        {
          timeout: 10000,
          enableHighAccuracy: true
        }
      )
    }

    async function submit() {
      error.value = null
      success.value = false
      submitting.value = true

      const validExpressions = expressions.value.filter(expr => {
        if (!expr.text || !expr.language_code) {
          return false
        }
        // For image language, validate it's a valid URL
        if (expr.language_code === 'image') {
          try {
            new URL(expr.text)
            return true
          } catch (e) {
            error.value = t('invalid_image_url_format')
            return false
          }
        }
        return true
      })

      if (validExpressions.length === 0) {
        error.value = t('create.requiredError')
        submitting.value = false
        return
      }

      const token = localStorage.getItem('authToken')
      if (!token) {
        error.value = t('must_be_logged_in_to_create_expressions')
        submitting.value = false
        return
      }

      try {
        let createdBy = null
        try {
          const response = await fetch('/api/v1/users/me', {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          })

          if (response.ok) {
            const userData = await response.json()
            createdBy = userData.data.username
          } else if (response.status === 401) {
            error.value = t('session_expired_please_log_in_again')
            localStorage.removeItem('authToken')
            router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
            return
          }
        } catch (e) {
          console.warn('Could not fetch current user info:', e)
        }

        const payloadExpressions = validExpressions.map(expr => {
          let regionData = null
          if (expr.region_input) {
            try {
              regionData = JSON.parse(expr.region_input)
            } catch (e) {
              regionData = { name: expr.region_input }
            }
          }

          return {
            text: expr.text,
            language_code: expr.language_code,
            region_code: regionData?.country_code || null,
            region_name: regionData?.name || null,
            region_latitude: regionData && regionData.latitude !== undefined && regionData.latitude !== null ? regionData.latitude : null,
            region_longitude: regionData && regionData.longitude !== undefined && regionData.longitude !== null ? regionData.longitude : null,
            created_by: createdBy,
            source_type: 'user',
            review_status: 'pending'
          }
        })

        const res = await fetch('/api/v1/expressions/batch', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ expressions: payloadExpressions })
        })

        if (!res.ok) {
          if (res.status === 401) {
            error.value = t('session_expired_please_log_in_again')
            localStorage.removeItem('authToken')
            router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
            return
          }
          const txt = await res.text()
          throw new Error(txt || 'Batch submission failed')
        }

        const result = await res.json()
        console.log('Batch submission result:', result)

        // 适配新的响应格式 { success, data: { meaning_id, results } }
        const createdResults = result.data?.results || result.results || []

        // Save created expressions for display
        createdExpressions.value = createdResults
          .filter(result => result && result.expression && result.expression.id)
          .map(result => result.expression)

        console.log('Created expressions for display:', createdExpressions.value)

        // Process audio uploads if present
        const audioResults = await processAudioUploads(validExpressions, createdResults, token)
        if (audioResults.errors > 0) {
          console.warn('Some audio uploads failed.')
        }

        // Add expressions to collections
        const collectionResults = await addToCollections(validExpressions, createdResults)

        if (collectionResults.errors > 0) {
          if (collectionResults.success > 0) {
            success.value = true
            error.value = t('partial_add_error')
          } else {
            success.value = true
            error.value = t('add_to_collection_error')
          }
        } else {
          success.value = true
        }

        expressions.value.forEach(expr => {
          expr.text = ''
        })
      } catch (e) {
        error.value = e.message || String(e)
      } finally {
        submitting.value = false
      }
    }

    async function processAudioUploads(originalExpressions, createdResults, token) {
      const results = { success: 0, errors: 0 }

      for (let i = 0; i < originalExpressions.length; i++) {
        const original = originalExpressions[i]
        const createdResult = createdResults[i]
        const created = createdResult?.expression

        if (original.audioBlob && created && created.id) {
          try {
            // 1. Upload directly to Worker using Native Bindings
            const formData = new FormData()
            formData.append('audio_file', original.audioBlob, `audio.${original.audioMimeType === 'audio/mp4' ? 'mp4' : 'webm'}`)

            const uploadRes = await fetch(`/api/v1/expressions/${created.id}/upload-audio`, {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${token}`
              },
              body: formData
            })

            if (!uploadRes.ok) {
              const errResult = await uploadRes.json()
              const errData = errResult.success ? errResult.data : errResult
              throw new Error(errData.error || errData.message || 'Direct worker upload failed for expression ' + created.id)
            }

            // The backend upload-audio endpoint now updates the database directly.
            // We no longer need a separate PATCH request to save the audio_url.

            results.success++
          } catch (err) {
            console.error('Audio processing error:', err)
            results.errors++
          }
        }
      }

      return results
    }

    async function addToCollections(originalExpressions, createdResults) {
      const results = { success: 0, errors: 0 }

      for (let i = 0; i < originalExpressions.length; i++) {
        const original = originalExpressions[i]
        const createdResult = createdResults[i]
        const created = createdResult?.expression

        if (original.collections && original.collections.length > 0 && created && created.id) {
          for (const collectionId of original.collections) {
            try {
              const token = localStorage.getItem('authToken')
              const response = await fetch(`/api/v1/collections/${collectionId}/items`, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                  expression_id: created.id
                })
              })

              if (response.ok) {
                results.success++
              } else {
                console.error(`Failed to add expression ${created.id} to collection ${collectionId}`)
                results.errors++
              }
            } catch (err) {
              console.error(`Error adding expression ${created.id} to collection ${collectionId}:`, err)
              results.errors++
            }
          }
        }
      }

      return results
    }

    const goBack = () => {
      router.push('/')
    }

    onMounted(() => {
      loadLanguages()
      loadUserCollections()
      expressions.value.forEach(expr => updateRegionDisplay(expr))
    })

    onUnmounted(() => {
      maps.forEach(map => map.remove())
      maps.clear()
    })

    return {
      expressions,
      languages,
      languagesLoading,
      showAddLanguageModal,
      addingLanguage,
      error,
      success,
      createdExpressions,
      submitting,
      minimalMode,
      activeCollectionIndex,
      addExpression,
      removeExpression,
      handleLanguageChange,
      detectLocation,
      toggleMapSelector,
      submit,
      goBack,
      t,
      handleAddLanguage,
      handleImageReady,
      handleImageCleared,
      // Collection-related
      userCollections,
      collectionsLoading,
      showCreateCollectionModal,
      collectionForm,
      creatingCollection,
      toggleCollectionSelector,
      toggleCollectionSelection,
      openCreateCollectionModal,
      closeCreateCollectionModal,
      handleCollectionCreated,
      handleCreateCollection,
      getSelectedCollectionNames,
      handleAudioReady,
      handleAudioCleared,
      toggleAdvanced
    }
  }
}
</script>
