<template>
  <div class="relative">
    <router-link :to="{ name: 'Detail', params: { id: item.id } }" class="block no-underline text-inherit">
      <div
        class="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden hover:shadow-md transition-all duration-200 sm:mx-0 cursor-pointer">

        <!-- Top: expression text + actions -->
        <div class="p-4 pb-3 flex justify-between items-start gap-4">
          <div class="flex-1 min-w-0">
            <div v-if="item.language_code === 'image'">
              <img :src="item.text" :class="[
                'cursor-pointer',
                imageSize === 'small' ? 'expression-image-small' : 'expression-image'
              ]" alt="Expression image" @click.stop.prevent="openImageModal(item.text)" />
            </div>
            <div v-else>
              <h3 class="text-lg font-semibold text-slate-800 break-words">{{ item.text }}</h3>
            </div>
          </div>

          <div class="flex items-center gap-1 flex-shrink-0">
            <button @click.stop.prevent="copyText"
              class="inline-flex items-center justify-center rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-200 bg-transparent text-slate-500 hover:bg-slate-50 hover:text-slate-700 focus:ring-slate-500 p-1.5 min-w-[2.25rem]"
              :title="copied ? $t('copied') : $t('copy')">
              <template v-if="!copied">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor" stroke-width="2">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
                  <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" />
                </svg>
              </template>
              <template v-else>
                <span class="text-green-600 font-medium text-xs">{{ $t('copied') }}</span>
              </template>
            </button>
            <button @click.stop.prevent="openCollectionModal"
              class="inline-flex items-center justify-center rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-200 bg-transparent text-slate-500 hover:bg-slate-50 hover:text-slate-700 focus:ring-slate-500 p-1.5"
              :title="$t('add_to_collection')">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                <path
                  d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
            </button>
            <button v-if="canEditDesc" @click.stop.prevent="startEditDesc"
              class="inline-flex items-center justify-center rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-200 bg-transparent text-slate-500 hover:bg-slate-50 hover:text-blue-600 focus:ring-slate-500 p-1.5"
              :title="$t('edit_desc') || '編輯描述'">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button v-if="canDelete" @click.stop.prevent="handleDelete" :disabled="isDeleting"
              class="inline-flex items-center justify-center rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-200 bg-transparent text-slate-500 hover:bg-red-50 hover:text-red-600 hover:border-red-300 focus:ring-red-500 p-1.5 disabled:opacity-50 disabled:cursor-not-allowed"
              :title="$t('delete')">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
            <button v-if="showUnlink" @click.stop.prevent="handleUnlink"
              class="inline-flex items-center justify-center rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-200 bg-transparent text-slate-500 hover:bg-slate-50 hover:text-red-600 focus:ring-slate-500 p-1.5"
              :title="$t('unlink')">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Desc section -->
        <div v-if="isEditingDesc" class="border-t border-slate-100 bg-slate-50 px-4 py-3" @click.stop>
          <textarea v-model="descEditText" rows="3" maxlength="1000"
            class="block w-full rounded-md border border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-2 px-3 text-sm resize-y"
            :placeholder="$t('expression_desc_placeholder')"></textarea>
          <div class="flex justify-between items-center mt-1.5">
            <span class="text-xs text-slate-400">{{ descEditText.length }} / 1000</span>
            <div class="flex gap-2">
              <button @click.stop.prevent="cancelEditDesc"
                class="text-xs text-slate-500 hover:text-slate-700 px-2 py-1 rounded transition-colors">{{ $t('cancel')
                }}</button>
              <button @click.stop.prevent="saveDesc" :disabled="descSaving"
                class="text-xs text-blue-600 hover:text-blue-700 font-medium px-2 py-1 rounded transition-colors disabled:opacity-50">
                {{ $t('save') || '保存' }}
              </button>
            </div>
          </div>
        </div>
        <div v-else-if="editable && renderedDesc"
          class="border-t border-slate-100 bg-slate-50 px-4 py-2.5 prose prose-sm max-w-none text-sm  desc-section"
          @click.stop v-html="renderedDesc"></div>
        <div v-else-if="item.desc"
          class="border-t border-slate-100 bg-slate-50 px-4 py-2.5 text-sm text-slate-500 line-clamp-1">{{ plainDesc }}
        </div>

        <!-- Meta section: language, audio, tags -->
        <div class="border-t border-slate-100 px-4 py-2.5 flex items-end justify-between gap-2">
          <div class="space-y-2 flex-1 min-w-0">
            <!-- Language + region -->
            <div class="text-xs text-slate-500">
              <div @click.stop.prevent="goToLanguageDetail"
                class="inline-flex items-center hover:text-blue-600 hover:underline font-medium transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1" fill="none" viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
                </svg>
                {{ getLanguageDisplayName(item.language_code) }}
              </div>
              <span v-if="getRegionDisplayName(item)">
                <span class="mx-1.5 text-slate-300">•</span>
                <span class="inline-flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  {{ getRegionDisplayName(item) }}
                </span>
              </span>
            </div>

            <!-- Audio -->
            <div class="flex flex-wrap items-center gap-1.5" v-if="audioList.length > 0 || editable">
              <template v-for="(audioItem, index) in audioList" :key="index">
                <div
                  class="inline-flex items-center bg-slate-50 border border-slate-200 rounded-full transition-colors group/pill h-7">
                  <button @click.stop.prevent="playAudio(audioItem, index)"
                    class="inline-flex items-center justify-center text-slate-500 hover:text-blue-600 hover:bg-slate-200 active:bg-slate-300 focus:outline-none p-0.5 ml-0.5 rounded-full transition-colors"
                    :title="$t('play')">
                    <svg v-if="playingIndex !== index" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5"
                      viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
                        clip-rule="evenodd" />
                    </svg>
                    <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" viewBox="0 0 20 20"
                      fill="currentColor">
                      <path fill-rule="evenodd"
                        d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM7 8a1 1 0 012 0v4a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v4a1 1 0 102 0V8a1 1 0 00-1-1z"
                        clip-rule="evenodd" />
                    </svg>
                  </button>
                  <span class="text-[11px] font-medium text-slate-500 px-1.5 cursor-default truncate max-w-[80px]"
                    :title="audioItem.speaker">
                    {{ audioItem.speaker }}
                  </span>

                  <div class="w-1 h-full" v-if="!canDeleteAudio(audioItem.speaker)"></div>

                  <div v-if="canDeleteAudio(audioItem.speaker)"
                    class="w-0 overflow-hidden group-hover/pill:w-6 transition-[width] duration-200 ease-in-out flex items-center justify-end h-full pr-0.5">
                    <button @click.stop.prevent="handleRemoveAudio(audioItem.speaker)"
                      class="flex-shrink-0 flex items-center justify-center text-slate-400 hover:text-red-600 hover:bg-red-100 rounded-full transition-colors w-4 h-4"
                      :title="$t('remove_audio')">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5" fill="none" viewBox="0 0 24 24"
                        stroke="currentColor" stroke-width="2.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                </div>
              </template>
              <template
                v-if="editable && canAddAudio && item.language_code !== 'image' && item.language_code !== 'emoji'">
                <div v-if="showAudioRecorder" class="w-full flex" @click.stop>
                  <AudioRecorder @audio-ready="handleInlineAudioUpload" @audio-cleared="showAudioRecorder = false" />
                </div>
                <button v-else-if="editable && canAddAudio" @click.stop.prevent="showAudioRecorder = true"
                  class="inline-flex items-center text-xs text-blue-600 hover:text-blue-700 bg-blue-50 hover:bg-blue-100 px-2.5 py-1 rounded-full transition-colors font-medium">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                  </svg>
                  {{ $t('add_audio') }}
                </button>
              </template>
            </div>

            <!-- Tags -->
            <div class="flex flex-wrap gap-1 items-center">
              <span v-for="(tag, index) in getTagsList()" :key="index"
                class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-slate-100 text-slate-500">
                {{ tag }}
                <button v-if="editable" @click.prevent="removeTag(tag)"
                  class="ml-1 text-slate-400 hover:text-slate-600 focus:outline-none" title="Remove tag">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd"
                      d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                      clip-rule="evenodd" />
                  </svg>
                </button>
              </span>

              <div v-if="editable" class="inline-flex items-center">
                <div v-if="isAddingTag" class="flex items-center" @click.stop>
                  <input v-model="newTagValue" @keydown.enter.prevent="confirmAddTag"
                    @keydown.esc.prevent="cancelAddTag" @blur="cancelAddTag" ref="newTagInput" placeholder="tag"
                    class="w-20 px-2 py-0.5 text-[11px] rounded border border-slate-300 focus:outline-none focus:ring-1 focus:ring-slate-500"
                    autofocus />
                </div>
                <button v-else @click.prevent="startAddTag"
                  class="inline-flex items-center justify-center w-4 h-4 rounded-full bg-slate-100 border border-dashed border-slate-300 hover:bg-slate-200 hover:border-slate-400 text-slate-400 transition-all focus:outline-none"
                  title="Add tag">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd"
                      d="M10 5a1 1 0 011 1v3h3a1 1 0 110 2h-3v3a1 1 0 11-2 0v-3H6a1 1 0 110-2h3V6a1 1 0 011-1z"
                      clip-rule="evenodd" />
                  </svg>
                </button>
              </div>
            </div>

          </div>
          <span v-if="item.created_by"
            class="flex-shrink-0 inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-slate-50 text-slate-400">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            {{ item.created_by }}
          </span>
        </div>
      </div>
    </router-link>

    <ExpressionGroupModal :visible="!!descModalExpressionId" :expression-id="descModalExpressionId"
      :group-id="descModalGroupId" @close="descModalExpressionId = null; descModalGroupId = null" />

    <AddToCollectionModal :visible="showCollectionModal" :expression-id="item.id"
      @close="showCollectionModal = false" />
    <ConfirmModal v-model="showDeleteAudioModal"
      :message="$t('confirm_delete_audio') || 'Are you sure you want to delete this audio?'" :loading="deletingAudio"
      :loadingText="$t('deleting') || 'Deleting...'" :confirmText="$t('delete') || 'Delete'"
      @confirm="executeRemoveAudio" />

    <!-- Image Modal -->
    <div v-if="showImageModal" class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50 p-4"
      @click.self="closeImageModal">
      <div class="relative max-w-5xl max-h-[90vh]">
        <button @click="closeImageModal"
          class="absolute -top-4 -right-4 text-white bg-black bg-opacity-50 hover:bg-opacity-70 rounded-full p-2 transition-colors">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
        <img :src="modalImageUrl" class="max-w-full max-h-[85vh] object-contain" alt="Full size expression image" />
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { languagesApi } from '../api/index.ts'
import { stableExpressionId } from '../api/handbooks.ts'
import AddToCollectionModal from './AddToCollectionModal.vue'
import AudioRecorder from './AudioRecorder.vue'
import ConfirmModal from './ConfirmModal.vue'
import ExpressionGroupModal from './ExpressionGroupModal.vue'
import MarkdownIt from 'markdown-it'
import DOMPurify from 'dompurify'

const md = new MarkdownIt({ html: false, linkify: true, breaks: true })
const TEXT_LANG_REGEX = /\{\{(?:text:)?([^|}]+)(?:\|([^}]+))?(?:\|([^}]+))?\}\}/g

function parseTagParams(param1, param2, defaultLang) {
  let lang = defaultLang
  let mid = undefined
  if (param1) {
    if (param1.startsWith('mid:')) mid = parseInt(param1.substring(4))
    else if (param1.startsWith('lang:')) lang = param1.substring(5)
  }
  if (param2) {
    if (param2.startsWith('mid:')) mid = parseInt(param2.substring(4))
    else if (param2.startsWith('lang:')) lang = param2.substring(5)
  }
  return { lang, mid }
}

export default {
  name: 'ExpressionCard',
  components: { AddToCollectionModal, AudioRecorder, ConfirmModal, ExpressionGroupModal },
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
    },
    imageSize: {
      type: String,
      default: 'large'
    }
  },
  emits: ['update-tags', 'unlink', 'delete'],
  setup(props, { emit }) {
    const { t } = useI18n()
    const router = useRouter()
    const showCollectionModal = ref(false)
    const showAudioRecorder = ref(false)
    const showImageModal = ref(false)
    const modalImageUrl = ref('')

    // Audio Delete Confirm
    const showDeleteAudioModal = ref(false)
    const audioToDeleteSpeaker = ref('')
    const deletingAudio = ref(false)

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

    const plainDesc = computed(() => {
      if (!props.item.desc) return ''
      const text = props.item.desc.replace(/[#*_`~\[\]()]/g, '').trim()
      return text.length > 100 ? text.slice(0, 100) + '...' : text
    })

    // Desc editing state
    const isEditingDesc = ref(false)
    const descEditText = ref('')
    const descSaving = ref(false)
    const renderedDesc = ref('')

    const canEditDesc = computed(() => {
      if (!props.editable || !currentUser.value) return false
      return currentUser.value.username === props.item.created_by
    })

    const descModalExpressionId = ref(null)
    const descModalGroupId = ref(null)

    const handleDescExpressionClick = (event) => {
      const { id, meaningId } = event.detail
      descModalExpressionId.value = id
      descModalGroupId.value = meaningId || null
    }
    window.addEventListener('handbook-expression-click', handleDescExpressionClick)

    async function renderDescMarkdown() {
      const desc = props.item.desc
      if (!desc) {
        renderedDesc.value = ''
        return
      }

      TEXT_LANG_REGEX.lastIndex = 0
      const hasTags = TEXT_LANG_REGEX.test(desc)
      TEXT_LANG_REGEX.lastIndex = 0

      if (!hasTags) {
        renderedDesc.value = DOMPurify.sanitize(md.render(desc))
        return
      }

      const sourceLang = props.item.language_code || ''

      const htmlPlaceholders = {}
      TEXT_LANG_REGEX.lastIndex = 0
      const descWithPlaceholders = desc.replace(TEXT_LANG_REGEX, (m) => {
        const index = Object.keys(htmlPlaceholders).length
        const placeholder = `DESC_EXPR_${index}`
        htmlPlaceholders[placeholder] = m
        return placeholder
      })

      const renderedMarkdown = md.render(descWithPlaceholders)

      const finalHtml = renderedMarkdown.replace(/DESC_EXPR_\d+/g, (placeholder) => {
        const originalTag = htmlPlaceholders[placeholder]
        if (!originalTag) return placeholder
        TEXT_LANG_REGEX.lastIndex = 0
        return originalTag.replace(TEXT_LANG_REGEX, (m, term, param1, param2) => {
          const { lang } = parseTagParams(param1, param2, sourceLang)
          const id = stableExpressionId(term.trim(), lang)

          return `<span class="handbook-item" data-type="content" data-expression-id="${id}" onclick="event.stopPropagation(); window.dispatchEvent(new CustomEvent('handbook-expression-click', { detail: { id: ${id} } }))">${term.trim()}</span>`
        })
      })

      renderedDesc.value = DOMPurify.sanitize(finalHtml, {
        ADD_ATTR: ['onclick', 'data-expression-id', 'data-type']
      })
    }

    function startEditDesc() {
      descEditText.value = props.item.desc || ''
      isEditingDesc.value = true
    }

    function cancelEditDesc() {
      isEditingDesc.value = false
      descEditText.value = ''
    }

    function extractExpressionsFromDesc(descText, sourceLang) {
      const expressions = []
      TEXT_LANG_REGEX.lastIndex = 0
      let match
      while ((match = TEXT_LANG_REGEX.exec(descText)) !== null) {
        const text = match[1].trim()
        const param1 = match[2]
        const param2 = match[3]
        const { lang } = parseTagParams(param1, param2, sourceLang)
        if (!expressions.some(e => e.text === text && e.language_code === lang)) {
          expressions.push({ text, language_code: lang })
        }
      }
      return expressions
    }

    async function saveDesc() {
      const token = localStorage.getItem('authToken')
      if (!token) return
      descSaving.value = true
      try {
        const expressionsToCreate = extractExpressionsFromDesc(descEditText.value, props.item.language_code || '')
        if (expressionsToCreate.length > 0) {
          const ensureRes = await fetch('/api/v1/expressions/ensure', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify({ expressions: expressionsToCreate })
          })
          if (!ensureRes.ok) {
            console.error('Failed to ensure expressions exist')
          }
        }

        const res = await fetch(`/api/v1/expressions/${props.item.id}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
          body: JSON.stringify({ desc: descEditText.value || null })
        })
        if (!res.ok) throw new Error('Failed to update description')
        const response = await res.json()
        const updated = response.data || response
        props.item.desc = updated.desc
        isEditingDesc.value = false
        renderDescMarkdown()
      } catch (e) {
        console.error('Error updating desc:', e)
      } finally {
        descSaving.value = false
      }
    }

    watch(() => props.item.desc, () => {
      if (props.editable) renderDescMarkdown()
    }, { immediate: true })

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
        router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
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

    const handleRemoveAudio = (speaker) => {
      audioToDeleteSpeaker.value = speaker
      showDeleteAudioModal.value = true
    }

    const executeRemoveAudio = async () => {
      deletingAudio.value = true
      const speaker = audioToDeleteSpeaker.value
      const token = localStorage.getItem('authToken')
      if (!token) {
        deletingAudio.value = false
        return
      }

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
        showDeleteAudioModal.value = false
      } catch (err) {
        console.error('Error removing audio:', err)
      } finally {
        deletingAudio.value = false
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

    const openImageModal = (imageUrl) => {
      modalImageUrl.value = imageUrl
      showImageModal.value = true
    }

    const closeImageModal = () => {
      showImageModal.value = false
      modalImageUrl.value = ''
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
      window.removeEventListener('handbook-expression-click', handleDescExpressionClick)
    })

    return {
      t,
      copied,
      plainDesc,
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
      showDeleteAudioModal,
      deletingAudio,
      executeRemoveAudio,
      playAudio,
      playingIndex,
      audioList,
      canAddAudio,
      canDeleteAudio,
      showImageModal,
      modalImageUrl,
      openImageModal,
      closeImageModal,
      isEditingDesc,
      canEditDesc,
      descEditText,
      descSaving,
      renderedDesc,
      startEditDesc,
      cancelEditDesc,
      saveDesc,
      descModalExpressionId,
      descModalGroupId
    }
  },
  methods: {
    getLanguageDisplayName(code) {
      return languagesApi.getLanguageDisplayName(code)
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

<style scoped>
.expression-image {
  width: 100%;
  max-width: 240px;
  max-height: 240px;
  height: auto;
  border-radius: 8px;
  object-fit: contain;
}

.expression-image-small {
  width: 100%;
  max-width: 80px;
  max-height: 80px;
  height: auto;
  border-radius: 8px;
  object-fit: contain;
}

:deep(.desc-section .handbook-item) {
  color: #475569;
  cursor: pointer;
}

:deep(.desc-section .handbook-item:hover) {
  color: #3b82f6;
}

:deep(.desc-section .handbook-meaning-content) {
  font-size: 0.85em;
}
</style>