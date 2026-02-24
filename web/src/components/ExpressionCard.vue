<template>
  <div class="relative">
    <router-link :to="{ name: 'Detail', params: { id: item.id } }" class="block no-underline text-inherit">
      <div class="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden hover:shadow-md transition-all duration-200 mx-4 sm:mx-0 cursor-pointer">
      <div class="p-4 flex justify-between items-start gap-4">
        <div class="flex-1 min-w-0">
          <h3 class="text-xl font-semibold text-slate-800 break-words">{{ item.text }}</h3>
          <div class="mt-1 text-sm text-slate-600">
            <div
              @click.stop.prevent="goToLanguageDetail"
              class="inline-flex items-center hover:text-blue-600 hover:underline font-medium transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
              </svg>
              {{ getLanguageDisplayName(item.language_code) }}
            </div>
              <span v-if="getRegionDisplayName(item)">
                <span class="mx-2">•</span>
                <span class="inline-flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  {{ getRegionDisplayName(item) }}
                </span>
              </span>
            </div>
            <!-- 显示所有标签 -->
            <div class="mt-2 flex flex-wrap gap-1 items-center">
              <span
                v-for="(tag, index) in getTagsList()"
                :key="index"
                class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
              >
                {{ tag }}
                <button
                  v-if="editable"
                  @click.prevent="removeTag(tag)"
                  class="ml-1 text-blue-600 hover:text-blue-900 focus:outline-none"
                  title="Remove tag"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                  </svg>
                </button>
              </span>

              <!-- Add Tag UI -->
              <div v-if="editable" class="inline-flex items-center">
                <div v-if="isAddingTag" class="flex items-center">
                  <input
                    v-model="newTagValue"
                    @keydown.enter.prevent="confirmAddTag"
                    @keydown.esc.prevent="cancelAddTag"
                    @blur="cancelAddTag"
                    ref="newTagInput"
                    placeholder="tag"
                    class="w-20 px-2 py-0.5 text-xs rounded border border-blue-300 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    autofocus
                  />
                </div>
                <button
                  v-else
                  @click.prevent="startAddTag"
                  class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-500 transition-colors focus:outline-none"
                  title="Add tag"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 5a1 1 0 011 1v3h3a1 1 0 110 2h-3v3a1 1 0 11-2 0v-3H6a1 1 0 110-2h3V6a1 1 0 011-1z" clip-rule="evenodd" />
                  </svg>
                </button>
              </div>
            </div>
          </div>

        <div class="flex flex-col items-end gap-3 flex-shrink-0">
          <span
             v-if="item.created_by"
             class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            {{ item.created_by }}
          </span>

          <div class="flex items-center gap-2">
            <button
              v-if="item.audio_url"
              @click.stop.prevent="playAudio"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 p-1.5 text-sm min-w-[3rem]"
              :title="$t('play')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
              </svg>
            </button>
            <button
              @click.stop.prevent="copyText"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 p-1.5 text-sm min-w-[3rem]"
              :title="copied ? $t('copied') : $t('copy')"
            >
              <template v-if="!copied">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
                  <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" />
                </svg>
              </template>
              <template v-else>
                <span class="text-green-600 font-medium">{{ $t('copied') }}</span>
              </template>
            </button>
            <button
              @click.stop.prevent="openCollectionModal"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 p-1.5 text-sm min-w-[3rem]"
              :title="$t('add_to_collection')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
            </button>
            <button
              v-if="canDelete"
              @click.stop.prevent="handleDelete"
              :disabled="isDeleting"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-red-50 hover:text-red-600 hover:border-red-300 focus:ring-red-500 p-1.5 text-sm min-w-[3rem] disabled:opacity-50 disabled:cursor-not-allowed"
              :title="$t('delete')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
            <button
              v-if="showUnlink"
              @click.stop.prevent="handleUnlink"
              class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 hover:text-red-600 focus:ring-slate-500 p-1.5 text-sm min-w-[3rem]"
              :title="$t('unlink')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
    </router-link>
    <AddToCollectionModal
      :visible="showCollectionModal"
      :expression-id="item.id"
      @close="showCollectionModal = false"
    />
  </div>
</template>

<script>
import { ref, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { getLanguageDisplayName } from '../services/languageService.js'
import AddToCollectionModal from './AddToCollectionModal.vue'

export default {
  name: 'ExpressionCard',
  components: { AddToCollectionModal },
  props: {
    item: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      default: false
    },
    showUnlink: {
      type: Boolean,
      default: false
    },
    itemId: {
      type: Number,
      default: null
    },
    canDelete: {
      type: Boolean,
      default: false
    },
    isDeleting: {
      type: Boolean,
      default: false
    }
  },
  emits: ['update-tags', 'unlink', 'delete'],
  data() {
    return {
      playing: false
    }
  },
  setup(props, { emit }) {
    const { t } = useI18n()
    const router = useRouter()
    const showCollectionModal = ref(false)

    // Copy functionality
    const copied = ref(false)
    let copyTimeout = null

    const copyText = async () => {
      try {
        await navigator.clipboard.writeText(props.item.text)
        copied.value = true
        // Reset after 2 seconds
        if (copyTimeout) clearTimeout(copyTimeout)
        copyTimeout = setTimeout(() => {
          copied.value = false
        }, 2000)
      } catch (err) {
        console.error('Failed to copy text:', err)
      }
    }

    const handleUnlink = () => {
      emit('unlink', props.item)
    }

    const handleDelete = () => {
      emit('delete', props.item)
    }

    // Tag management state
    const isAddingTag = ref(false)
    const newTagValue = ref('')

    const openCollectionModal = () => {
      const token = localStorage.getItem('authToken')
      if (!token) {
        router.push('/login')
        return
      }
      showCollectionModal.value = true
    }

    const removeTag = (tagToRemove) => {
      const currentTags = getTagsList(props.item)
      const newTags = currentTags.filter(t => t !== tagToRemove)
      emit('update-tags', newTags)
    }

    const startAddTag = () => {
      isAddingTag.value = true
      newTagValue.value = ''
      // Focus will be handled by template via autofocus
    }

    const confirmAddTag = () => {
      const tag = newTagValue.value.trim()
      if (tag) {
        const currentTags = getTagsList(props.item)
        if (!currentTags.includes(tag)) {
          const newTags = [...currentTags, tag]
          emit('update-tags', newTags)
        }
      }
      isAddingTag.value = false
      newTagValue.value = ''
    }

    const cancelAddTag = () => {
      isAddingTag.value = false
      newTagValue.value = ''
    }

    const goToLanguageDetail = () => {
      router.push({ name: 'LanguageDetail', params: { code: props.item.language_code } })
    }

    // Clean up timeout on unmount
    onUnmounted(() => {
      if (copyTimeout) {
        clearTimeout(copyTimeout)
      }
    })

    return {
      t,
      copied,
      copyText,
      showCollectionModal,
      openCollectionModal,
      handleUnlink,
      handleDelete,
      isAddingTag,
      newTagValue,
      removeTag,
      startAddTag,
      confirmAddTag,
      cancelAddTag,
      goToLanguageDetail
    }
  },
  methods: {
    playAudio () {
      const audio = new Audio(this.item.audio_url)
      this.playing = true
      audio.play()
      audio.addEventListener('ended', () => {
        this.playing = false
      })
      audio.addEventListener('error', () => {
        this.playing = false
      })
    },
    getLanguageDisplayName(code) {
      return getLanguageDisplayName(code)
    },
    getRegionDisplayName(item) {
      // Use the new region_name field if available
      if (item.region_name) {
        return item.region_name + (item.region_code ? ` (${item.region_code})` : '')
      }
      
      // If region is a JSON string, try to parse it
      if (item.region) {
        try {
          const regionData = JSON.parse(item.region)
          return regionData.name || item.region
        } catch (e) {
          // If it's not valid JSON, return as is
          return item.region
        }
      }
      
      // Return empty if no region data
      return ''
    },
    // 获取标签列表
    getTagsList() {
      // Helper specific to formatting for display, 
      // but simpler to use the static one we define for setup too if we want
      // or just call this.item processing here.
      if (!this.item.tags) return [];
      try {
        const tags = JSON.parse(this.item.tags);
        return Array.isArray(tags) ? tags : [];
      } catch (e) {
        return [];
      }
    }
  }
}

// Private helper for setup since methods aren't available there easily without context
function getTagsList(item) {
  if (!item.tags) return [];
  try {
    const tags = JSON.parse(item.tags);
    return Array.isArray(tags) ? tags : [];
  } catch (e) {
    return [];
  }
}
</script>