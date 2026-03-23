<template>
  <div class="image-uploader">
    <div v-if="error" class="text-sm text-red-600 mb-2 flex items-center">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      {{ error }}
    </div>

    <!-- 状态：未上传 -->
    <div v-if="!imageUrl" class="upload-area" @click="triggerFileInput" @dragover.prevent @drop.prevent="handleDrop">
      <div class="upload-content">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-slate-400 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
        <p class="text-slate-600 font-medium">{{ uploading ? '压缩上传中...' : '点击上传图片' }}</p>
        <p class="text-slate-400 text-sm mt-1">或拖拽图片到此处</p>
        <p class="text-slate-400 text-xs mt-2">支持 JPG、PNG、WebP，最大 5MB（自动压缩）</p>
      </div>
    </div>

    <!-- 状态：已上传 -->
    <div v-else class="preview-area">
      <img :src="imageUrl" class="preview-image" alt="Preview" />
      <button @click="clearImage" class="clear-btn" title="删除图片">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <input
      ref="fileInput"
      type="file"
      accept="image/jpeg,image/jpg,image/png,image/webp"
      style="display: none;"
      @change="handleFileSelect"
    />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { compressToSize, validateImageFile } from '../utils/imageCompression.js'
import { uploadPresignedUrl } from '../api/images.ts'

const props = defineProps({
  existingImageUrl: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['image-ready', 'image-cleared'])

const fileInput = ref(null)
const imageUrl = ref(props.existingImageUrl)
const error = ref('')
const uploading = ref(false)

watch(() => props.existingImageUrl, (newVal) => {
  imageUrl.value = newVal
})

const triggerFileInput = () => {
  if (uploading.value) return
  fileInput.value?.click()
}

const handleFileSelect = async (event) => {
  const file = event.target.files?.[0]
  if (file) {
    await processFile(file)
  }
}

const handleDrop = async (event) => {
  const file = event.dataTransfer.files?.[0]
  if (file) {
    await processFile(file)
  }
}

const processFile = async (file) => {
  error.value = ''

  // 验证文件
  const validation = validateImageFile(file)
  if (!validation.valid) {
    error.value = validation.error
    return
  }

  try {
    uploading.value = true

    // 压缩图片
    const { blob, iterations } = await compressToSize(file, 100 * 1024)

    if (blob.size > 300 * 1024) {
      error.value = '压缩后图片仍然过大，请选择其他图片'
      uploading.value = false
      return
    }

    // 上传到 R2
    const url = await uploadPresignedUrl(blob)

    imageUrl.value = url
    emit('image-ready', url)

  } catch (err) {
    console.error('Image upload error:', err)
    error.value = err.message || '上传失败，请重试'
  } finally {
    uploading.value = false
  }
}

const clearImage = () => {
  imageUrl.value = ''
  error.value = ''
  emit('image-cleared')
}
</script>

<style scoped>
.image-uploader {
  width: 100%;
}

.upload-area {
  border: 2px dashed #cbd5e1;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
  background-color: #f8fafc;
}

.upload-area:hover {
  border-color: #3b82f6;
  background-color: #eff6ff;
}

.upload-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.preview-area {
  position: relative;
  width: 100%;
  border-radius: 8px;
  overflow: hidden;
}

.preview-image {
  width: 100%;
  max-width: 600px;
  height: auto;
  display: block;
  border-radius: 8px;
}

.clear-btn {
  position: absolute;
  top: 8px;
  right: 8px;
  background-color: rgba(255, 255, 255, 0.9);
  border: none;
  border-radius: 50%;
  padding: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.clear-btn:hover {
  background-color: #fee2e2;
}

.clear-btn svg {
  color: #ef4444;
}
</style>
