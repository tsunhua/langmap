<template>
  <div class="audio-recorder bg-slate-50 border border-slate-200 rounded-lg p-4 w-full">
    <div v-if="error" class="text-sm text-red-600 mb-2 flex items-center">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      {{ error }}
    </div>

    <!-- State: Not Recording (Preview if exists) -->
    <div v-if="!isRecording" class="flex items-center gap-3">
      <div v-if="audioUrl" class="flex-1 flex items-center gap-2">
        <audio controls :src="audioUrl" class="h-8 w-full max-w-xs"></audio>
        <button 
          @click="resetRecording" 
          class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-full transition-colors"
          title="Delete Recording"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </button>
      </div>

      <button 
        v-if="!audioUrl" 
        @click="startRecording" 
        class="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-100 text-blue-700 hover:bg-blue-200 rounded-full font-medium transition-colors focus:ring-2 focus:ring-blue-500 focus:outline-none disabled:opacity-50"
        :disabled="!isSupported"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
        </svg>
        {{ $t('record_audio') }}
      </button>

      <div 
        v-if="!audioUrl"
        class="inline-flex items-center justify-center gap-2 px-4 py-2 bg-slate-100 text-slate-700 hover:bg-slate-200 rounded-full font-medium transition-colors focus:ring-2 focus:ring-slate-500 focus:outline-none ml-2 cursor-pointer"
      >
        <label :for="uploadId" class="cursor-pointer flex items-center gap-2 w-full h-full">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
          </svg>
          {{ $t('upload_audio') }}
        </label>
      </div>

      <input 
        :id="uploadId"
        ref="fileInput"
        type="file" 
        accept="audio/*"
        style="display: none;"
        @change="handleFileSelect"
      />

      <div v-if="!isSupported" class="text-xs text-slate-500 ml-2">
        {{ $t('audio_not_supported') }}
      </div>
    </div>

    <!-- State: Recording -->
    <div v-else class="flex flex-col gap-2">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <!-- Pulsing dot -->
          <span class="relative flex h-3 w-3">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
            <span class="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
          </span>
          <span class="font-mono text-sm font-medium text-slate-700">{{ formattedTime }}</span>
          <span class="text-xs text-slate-400">/ 00:15</span>
        </div>
        
        <button 
          @click="stopRecording" 
          class="inline-flex items-center justify-center p-2 bg-red-100 text-red-700 hover:bg-red-200 rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-red-500"
          title="Stop Recording"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8 7a1 1 0 00-1 1v4a1 1 0 001 1h4a1 1 0 001-1V8a1 1 0 00-1-1H8z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>

      <!-- Progress bar -->
      <div class="w-full bg-slate-200 rounded-full h-1.5 mt-2 overflow-hidden">
        <div class="bg-red-500 h-1.5 transition-all duration-100 ease-linear" :style="{ width: `${progressPercentage}%` }"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onBeforeUnmount, watch, nextTick } from 'vue'

const uploadId = `audio-upload-${Math.random().toString(36).substr(2, 9)}`

const props = defineProps({
  existingAudioUrl: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['audio-ready', 'audio-cleared'])

const isSupported = ref(!!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia))
const isRecording = ref(false)
const error = ref('')
const recordingTime = ref(0)
const audioUrl = ref(props.existingAudioUrl)
const fileInput = ref(null)

let mediaRecorder = null
let audioChunks = []
let timerInterval = null
const MAX_DURATION = 15 // seconds

const formattedTime = computed(() => {
  const mins = Math.floor(recordingTime.value / 60).toString().padStart(2, '0')
  const secs = (recordingTime.value % 60).toString().padStart(2, '0')
  return `${mins}:${secs}`
})

const progressPercentage = computed(() => {
  return (recordingTime.value / MAX_DURATION) * 100
})

watch(() => props.existingAudioUrl, (newVal) => {
  if (!isRecording.value && audioChunks.length === 0) {
    audioUrl.value = newVal
  }
})

const startRecording = async () => {
  error.value = ''
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    
    // Determine supported mime type
    let mimeType = 'audio/webm'
    if (!MediaRecorder.isTypeSupported(mimeType)) {
      if (MediaRecorder.isTypeSupported('audio/mp4')) {
        mimeType = 'audio/mp4'
      } else {
        mimeType = '' // fallback to browser default
      }
    }

    const options = mimeType ? { mimeType } : undefined
    mediaRecorder = new MediaRecorder(stream, options)
    audioChunks = []

    mediaRecorder.addEventListener('dataavailable', event => {
      if (event.data.size > 0) {
        audioChunks.push(event.data)
      }
    })

    mediaRecorder.addEventListener('stop', () => {
      // Stop all tracks to release mic
      stream.getTracks().forEach(track => track.stop())
      
      const audioBlob = new Blob(audioChunks, { type: mediaRecorder.mimeType || 'audio/webm' })
      audioUrl.value = URL.createObjectURL(audioBlob)
      
      emit('audio-ready', {
        blob: audioBlob,
        mimeType: audioBlob.type
      })
      
      isRecording.value = false
      clearInterval(timerInterval)
    })

    mediaRecorder.start(200) // Collect data every 200ms
    isRecording.value = true
    recordingTime.value = 0

    // Start timer and enforce max duration
    timerInterval = setInterval(() => {
      recordingTime.value++
      if (recordingTime.value >= MAX_DURATION) {
        stopRecording()
      }
    }, 1000)

  } catch (err) {
    console.error('Error accessing microphone:', err)
    error.value = '无法访问麦克风。请确保您已授予权限。'
  }
}

const stopRecording = () => {
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.stop()
  }
}

const resetRecording = () => {
  audioChunks = []
  if (audioUrl.value && audioUrl.value.startsWith('blob:')) {
    URL.revokeObjectURL(audioUrl.value)
  }
  audioUrl.value = ''
  recordingTime.value = 0
  error.value = ''
  emit('audio-cleared')
}

const triggerFileUpload = () => {
  nextTick(() => {
    if (fileInput.value) {
      fileInput.value.click()
    }
  })
}

const handleFileSelect = (event) => {
  console.log('handleFileSelect called')
  const file = event.target.files[0]
  if (!file) {
    console.log('No file selected')
    return
  }
  
  console.log('File selected:', file.name, file.type, file.size)

  // Validate file type
  if (!file.type.startsWith('audio/')) {
    error.value = '请选择音频文件'
    return
  }

  // Validate file size (max 10MB)
  if (file.size > 10 * 1024 * 1024) {
    error.value = '音频文件大小不能超过 10MB'
    return
  }

  error.value = ''
  const audioBlob = file
  audioUrl.value = URL.createObjectURL(audioBlob)

  emit('audio-ready', {
    blob: audioBlob,
    mimeType: file.type
  })

  // Reset file input so same file can be selected again
  event.target.value = ''
}

onBeforeUnmount(() => {
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.stop()
  }
  if (timerInterval) clearInterval(timerInterval)
  if (audioUrl.value && audioUrl.value.startsWith('blob:')) {
    URL.revokeObjectURL(audioUrl.value)
  }
})
</script>

<style scoped>
/* Optional custom styling */
</style>
