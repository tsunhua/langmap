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
            <!-- Audio Row -->
            <div class="mt-3 flex flex-wrap items-center gap-2" v-if="audioList.length > 0 || editable">
              <template v-for="(audioItem, index) in audioList" :key="index">
                <div class="inline-flex items-center bg-slate-50 border border-slate-200 rounded-full transition-colors group/pill h-8">
                  <button @click.stop.prevent="playAudio(audioItem, index)" class="inline-flex items-center justify-center text-slate-600 hover:text-blue-600 hover:bg-slate-200 active:bg-slate-300 focus:outline-none p-1 ml-0.5 rounded-full transition-colors" :title="$t('play')">
                    <svg v-if="playingIndex !== index" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
                    </svg>
                    <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM7 8a1 1 0 012 0v4a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v4a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                  </button>
                  <span class="text-xs font-medium text-slate-600 px-1.5 cursor-default truncate max-w-[100px]" :title="audioItem.speaker">
                    {{ audioItem.speaker }}
                  </span>
                  
                  <!-- Spacer when non-editable or no delete rights, or just padding -->
                  <div class="w-1.5 h-full" v-if="!canDeleteAudio(audioItem.speaker)"></div>

                  <!-- X Button Container (Zero width until hover/focus) -->
                  <div v-if="canDeleteAudio(audioItem.speaker)" class="w-0 overflow-hidden group-hover/pill:w-7 transition-[width] duration-200 ease-in-out flex items-center justify-end h-full pr-1">
                    <button @click.stop.prevent="handleRemoveAudio(audioItem.speaker)" class="flex-shrink-0 flex items-center justify-center text-slate-400 hover:text-red-600 hover:bg-red-100 rounded-full transition-colors w-5 h-5" :title="$t('remove_audio')">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                </div>
              </template>
              <template v-if="editable && canAddAudio">
                <div v-if="showAudioRecorder" class="w-full flex" @click.stop.prevent>
                  <AudioRecorder @audio-ready="handleInlineAudioUpload" @audio-cleared="showAudioRecorder = false" />
                </div>
                <button v-else-if="editable && canAddAudio" @click.stop.prevent="showAudioRecorder = true" class="inline-flex items-center text-sm text-blue-600 hover:text-blue-700 bg-blue-50 hover:bg-blue-100 px-3 py-1.5 rounded-full transition-colors font-medium">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                  </svg>
                  {{ $t('add_audio') }}
                </button>
              </template>
            </div>

            <!-- Tags -->
            <div class="mt-3 flex flex-wrap gap-1 items-center">
              <span
                v-for="(tag, index) in getTagsList()"
                :key="index"
                class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600"
              >
                {{ tag }}
                <button
                  v-if="editable"
                  @click.prevent="removeTag(tag)"
                  class="ml-1 text-slate-500 hover:text-slate-800 focus:outline-none"
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
                    class="w-20 px-2 py-0.5 text-xs rounded border border-slate-300 focus:outline-none focus:ring-1 focus:ring-slate-500"
                    autofocus
                  />
                </div>
                <button
                  v-else
                  @click.prevent="startAddTag"
                  class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-slate-50 border border-dashed border-slate-300 hover:bg-slate-100 hover:border-slate-400 text-slate-500 transition-all focus:outline-none"
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
import { ref, watch, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { getLanguageDisplayName } from '../services/languageService.js'
import AddToCollectionModal from './AddToCollectionModal.vue'
import AudioRecorder from './AudioRecorder.vue'

export default {
  name: 'ExpressionCard',
  components: { AddToCollectionModal, AudioRecorder },
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
  setup(props, { emit }) {
    const { t } = useI18n()
    const router = useRouter()
    const showCollectionModal = ref(false)
    const showAudioRecorder = ref(false)

    // Current user info
    const currentUser = ref(null)
    const loadUser = () => {
      try {
        // App.vue saves user info as 'user'
        const userInfo = localStorage.getItem('user')
        if (userInfo) {
          currentUser.value = JSON.parse(userInfo)
        }
      } catch (e) {
        console.error('Failed to parse user info', e)
      }
    }
    loadUser()

    // Parse audio list
    const audioList = ref([])
    const updateAudioList = () => {
      if (!props.item.audio_url) {
        audioList.value = []
        return
      }
      try {
        const parsed = JSON.parse(props.item.audio_url)
        if (Array.isArray(parsed)) {
          audioList.value = parsed
        } else if (typeof props.item.audio_url === 'string' && props.item.audio_url.startsWith('http')) {
          audioList.value = [{ url: props.item.audio_url, speaker: props.item.created_by || 'Unknown' }]
        } else {
          audioList.value = []
        }
      } catch (e) {
        if (typeof props.item.audio_url === 'string' && props.item.audio_url.startsWith('http')) {
          audioList.value = [{ url: props.item.audio_url, speaker: props.item.created_by || 'Unknown' }]
        } else {
          audioList.value = []
        }
      }
    }
    
    // Watch for changes in audio_url (moved below)

    const canAddAudio = ref(false)
    const updateCanAddAudio = () => {
      if (!currentUser.value) {
        canAddAudio.value = false
        return
      }
      // Can add if user doesn't already have an audio record
      canAddAudio.value = !audioList.value.some(a => a.speaker === currentUser.value.username)
    }
    updateCanAddAudio()

    watch(() => props.item.audio_url, () => {
      updateAudioList()
      updateCanAddAudio()
    }, { immediate: true })

    const canDeleteAudio = (speaker) => {
      if (!props.editable || !currentUser.value) return false
      return currentUser.value.role === 'admin' || currentUser.value.role === 'super_admin' || currentUser.value.username === speaker
    }

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

    const handleInlineAudioUpload = async (payload) => {
      const token = localStorage.getItem('authToken')
      if (!token) return

      try {
        // 1. Upload directly to Worker
        const formData = new FormData()
        formData.append('audio_file', payload.blob, `audio.${payload.mimeType === 'audio/mp4' ? 'mp4' : 'webm'}`)

        const uploadRes = await fetch(`/api/v1/expressions/${props.item.id}/upload-audio`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`
          },
          body: formData
        })

        if (!uploadRes.ok) throw new Error('Native binding upload failed')
        const { audio_url } = await uploadRes.json()
        props.item.audio_url = audio_url // Update parent data optimistically
        updateAudioList()
        updateCanAddAudio()
        showAudioRecorder.value = false

      } catch (err) {
        console.error('Audio processing error:', err)
        alert('Failed to upload audio')
      }
    }

    const handleRemoveAudio = async (speaker) => {
      if (!confirm(t('confirm_delete', { item: 'audio' }))) return

      const token = localStorage.getItem('authToken')
      if (!token) return

      try {
        const updateRes = await fetch(`/api/v1/expressions/${props.item.id}/audio?speaker=${encodeURIComponent(speaker)}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (!updateRes.ok) throw new Error('Failed to delete audio')
        
        const { audio_url } = await updateRes.json()
        props.item.audio_url = audio_url
        updateAudioList()
        updateCanAddAudio()
      } catch (err) {
        console.error('Error removing audio:', err)
      }
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

    const playingIndex = ref(-1)
    let audioInstance = null

    const playAudio = (audioItem, index) => {
      if (!audioItem || !audioItem.url) return
      
      if (audioInstance && playingIndex.value === index) {
        audioInstance.pause()
        audioInstance.currentTime = 0
        playingIndex.value = -1
        return
      }

      if (audioInstance) {
        audioInstance.pause()
        audioInstance.currentTime = 0
      }

      audioInstance = new Audio(audioItem.url)
      audioInstance.addEventListener('ended', () => {
        playingIndex.value = -1
      })
      audioInstance.addEventListener('error', () => {
        playingIndex.value = -1
      })

      audioInstance.play().catch(e => {
        console.error('Playback error:', e);
        playingIndex.value = -1;
      })
      playingIndex.value = index
    }

    // Clean up timeout and audio on unmount
    onUnmounted(() => {
      if (copyTimeout) {
        clearTimeout(copyTimeout)
      }
      if (audioInstance) {
        audioInstance.pause()
        audioInstance = null
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
      goToLanguageDetail,
      showAudioRecorder,
      handleInlineAudioUpload,
      handleRemoveAudio,
      playAudio,
      playingIndex,
      audioList,
      canAddAudio,
      canDeleteAudio
    }
  },
  methods: {
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