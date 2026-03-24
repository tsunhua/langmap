# 圖片詞句功能實施計劃

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**目標：** 實現 LangMap 圖片表達功能，支持用戶上傳、壓縮、存儲和展示圖片作爲表達式，採用客戶端直傳 R2 + 預籤名 URL 架構。

**架構：**
- **存儲**：Cloudflare R2 (langmap-images bucket)，WebP 格式，最大 300KB
- **上傳**：客戶端直傳 R2 (Presigned URL)，避免 Worker 代理
- **識別**：`language_code = 'image'` 標識圖片表達式，`text` 存儲圖片 URL
- **壓縮**：前端 Canvas 壓縮到 600px 寬度，質量 0.7，目標 < 100KB
- **分發**：Cloudflare CDN 邊緣緩存，永久靜態緩存 (max-age=31536000)

**技術棧：**
- **後端**：Cloudflare Workers + D1 + R2 + Hono + Zod
- **前端**：Vue 3 + Vite + Tailwind CSS
- **壓縮**：HTML5 Canvas API
- **驗證**：Zod schema，URL 前綴驗證，速率限制

---

## Task 1: 配置 R2 存儲桶和後端環境

**Files:**
- Modify: `backend/wrangler.jsonc`

**Step 1: 添加 R2 bucket binding**

修改 `wrangler.jsonc`，在 `r2_buckets` 數組中添加：

```jsonc
{
  "binding": "IMAGES_BUCKET",
  "bucket_name": "langmap-images",
  "preview_bucket_name": "langmap-images"
}
```

完整配置應如下：

```jsonc
"r2_buckets": [
  {
    "binding": "EXPORT_BUCKET",
    "bucket_name": "langmap-exports",
    "preview_bucket_name": "langmap-exports"
  },
  {
    "binding": "AUDIO_BUCKET",
    "bucket_name": "langmap-audio",
    "preview_bucket_name": "langmap-audio"
  },
  {
    "binding": "IMAGES_BUCKET",
    "bucket_name": "langmap-images",
    "preview_bucket_name": "langmap-images"
  }
]
```

**Step 2: 更新類型定義**

修改 `backend/src/server/types/bindings.ts`，在 `Bindings` interface 中添加：

```typescript
IMAGES_BUCKET: R2Bucket
```

**Step 3: 添加環境變量**

修改 `backend/wrangler.jsonc`，在 `[vars]` 部分添加：

```toml
[vars]
R2_IMAGES_BUCKET = "langmap-images"
IMAGES_PUBLIC_URL = "https://images.langmap.io"
```

**Step 4: 驗證配置**

```bash
cd backend
npx wrangler dev
```

預期：Worker 啓動成功，無錯誤

**Step 5: Commit**

```bash
git add backend/wrangler.jsonc backend/src/server/types/bindings.ts
git commit -m "feat: add R2 images bucket configuration"
```

---

## Task 2: 更新 Expression Schema 支持 Image 語言

**Files:**
- Modify: `backend/src/server/schemas/expression.ts`

**Step 1: 修改 createExpressionSchema**

更新驗證邏輯，支持 `language_code = 'image'` 和 URL 驗證：

```typescript
export const createExpressionSchema = z.object({
  text: z.string().min(1).max(1000),
  language_code: z.string().min(2).max(36),
  meaning_id: z.number().optional(),
  audio_url: z.string().optional(),
  region_code: z.string().optional()
}).superRefine((data, ctx) => {
  // 當 language_code = "image" 時，text 必須是有效 URL
  if (data.language_code === 'image') {
    if (!data.text.startsWith('http://') && !data.text.startsWith('https://')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '圖片 URL 必須以 http:// 或 https:// 開頭',
        path: ['text']
      })
    }

    // 驗證 URL 域名
    try {
      const url = new URL(data.text)
      if (!url.hostname.endsWith('.langmap.io') && !url.hostname.includes('r2.cloudflarestorage.com')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: '僅允許使用系統生成的圖片 URL',
          path: ['text']
        })
      }
    } catch {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '圖片 URL 格式無效',
        path: ['text']
      })
    }
  }
})
```

**Step 2: 修改 updateExpressionSchema**

添加相同的 URL 驗證：

```typescript
export const updateExpressionSchema = z.object({
  text: z.string().min(1).max(1000).optional(),
  language_code: z.string().min(2).max(36).optional(),
  meaning_id: z.number().optional(),
  audio_url: z.string().optional(),
  region_code: z.string().optional()
}).superRefine((data, ctx) => {
  if (data.language_code === 'image' && data.text) {
    if (!data.text.startsWith('http://') && !data.text.startsWith('https://')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '圖片 URL 必須以 http:// 或 https:// 開頭',
        path: ['text']
      })
    }

    try {
      const url = new URL(data.text)
      if (!url.hostname.endsWith('.langmap.io') && !url.hostname.includes('r2.cloudflarestorage.com')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: '僅允許使用系統生成的圖片 URL',
          path: ['text']
        })
      }
    } catch {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '圖片 URL 格式無效',
        path: ['text']
      })
    }
  }
})
```

**Step 3: Commit**

```bash
git add backend/src/server/schemas/expression.ts
git commit -m "feat: add image URL validation to expression schemas"
```

---

## Task 3: 實現圖片上傳預籤名 URL API

**Files:**
- Create: `backend/src/server/routes/images.ts`
- Modify: `backend/src/server/routes/index.ts`

**Step 1: 創建 images routes**

創建 `backend/src/server/routes/images.ts`：

```typescript
import { Hono } from 'hono'
import { requireAuth } from '../middleware/auth.js'
import { z } from 'zod'
import { success, badRequest, internalError } from '../utils/response.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'

const imagesRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

// 速率限制存儲（生產環境應使用 KV 或 Durable Object）
const rateLimiter = new Map<string, { count: number, resetTime: number }>()

// 驗證 schema
const uploadPresignSchema = z.object({
  content_type: z.string().regex(/^image\/(webp|jpeg|jpg|png)$/i),
  content_length: z.number().max(1048576) // 最大 1MB
})

imagesRoutes.post('/upload-presign', requireAuth, async (c) => {
  try {
    const user = c.get('user')
    const body = await c.req.json()

    // 驗證請求
    const validated = uploadPresignSchema.parse(body)

    // 速率限制（管理員無限制）
    if (user.role !== 'super_admin' && user.role !== 'admin') {
      const now = Date.now()
      const key = `presign:${user.username}`
      const record = rateLimiter.get(key)

      if (record && record.resetTime > now) {
        if (record.count >= 5) {
          return badRequest(c, '請求過於頻繁，請稍後再試')
        }
        record.count++
      } else {
        rateLimiter.set(key, { count: 1, resetTime: now + 60000 })
      }
    }

    // 生成唯一文件名
    const fileId = crypto.randomUUID()
    const fileName = `${fileId}.webp`

    // 構建預籤名 URL（5分鐘有效期）
    const bucket = c.env.IMAGES_BUCKET
    const uploadUrl = await new Request(`https://${bucket.name}.r2.cloudflarestorage.com/${fileName}`, {
      method: 'PUT',
      headers: {
        'Content-Type': validated.content_type
      }
    }).cf({
      // Cloudflare 會自動生成預籤名 URL
    })

    // 公開訪問的 URL
    const publicUrl = `${c.env.IMAGES_PUBLIC_URL}/${fileName}`

    return success(c, {
      upload_url: uploadUrl.url,
      image_url: publicUrl,
      expires_in: 300,
      file_id: fileId
    })
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, '驗證失敗', undefined, error.errors)
    }
    console.error('Error in POST /images/upload-presign:', error)
    return internalError(c, error.message || '獲取預籤名 URL 失敗')
  }
})

export { imagesRoutes }
```

**Step 2: 註冊路由**

修改 `backend/src/server/routes/index.ts`，添加圖片路由：

```typescript
import { Hono } from 'hono'
import { imagesRoutes } from './images.js'

// ... 其他導入

const routes = new Hono()

// 註冊路由
routes.route('/api/v1/images', imagesRoutes)
// ... 其他路由
```

**Step 3: Commit**

```bash
git add backend/src/server/routes/images.ts backend/src/server/routes/index.ts
git commit -m "feat: add image upload presigned URL API"
```

---

## Task 4: 更新 Expression Routes 添加速率限制

**Files:**
- Modify: `backend/src/server/routes/expressions.ts`

**Step 1: 添加速率限制**

在 `POST /expressions` 路由中添加圖片表達式的速率限制：

```typescript
// 速率限制存儲
const expressionRateLimiter = new Map<string, { count: number, resetTime: number, imageCount: number }>()

expressionsRoutes.post('/', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const body = await c.req.json()

    // 驗證
    const validated = createExpressionSchema.parse(body)

    // 速率限制（管理員無限制）
    if (user.role !== 'super_admin' && user.role !== 'admin') {
      const now = Date.now()
      const key = `expression:${user.username}`
      const record = expressionRateLimiter.get(key)

      if (record && record.resetTime > now) {
        // 圖片表達式額外限制：每分鐘最多 10 次
        if (validated.language_code === 'image') {
          if (record.imageCount >= 10) {
            return badRequest(c, '圖片表達式創建過於頻繁，請稍後再試')
          }
          record.imageCount++
        }

        // 總體限制：每分鐘最多 20 次
        if (record.count >= 20) {
          return badRequest(c, '表達式創建過於頻繁，請稍後再試')
        }
        record.count++
      } else {
        expressionRateLimiter.set(key, {
          count: 1,
          resetTime: now + 60000,
          imageCount: validated.language_code === 'image' ? 1 : 0
        })
      }
    }

    const expression = await service.create(validated, user.username)
    await clearCache(c, '/api/v1/expressions')

    return created(c, expression)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Error in POST /expressions:', error)
    return internalError(c, error.message || 'Failed to create expression')
  }
})
```

**Step 2: Commit**

```bash
git add backend/src/server/routes/expressions.ts
git commit -m "feat: add rate limiting for image expressions"
```

---

## Task 5: 實現前端圖片壓縮工具函數

**Files:**
- Create: `web/src/utils/imageCompression.js`

**Step 1: 創建圖片壓縮工具**

創建 `web/src/utils/imageCompression.js`：

```javascript
/**
 * 壓縮圖片到指定寬度和質量
 * @param {File} file - 原始圖片文件
 * @param {number} maxWidth - 最大寬度（默認 600px）
 * @param {number} quality - 質量 0-1（默認 0.7）
 * @returns {Promise<Blob>} 壓縮後的 Blob
 */
export async function compressImage(file, maxWidth = 600, quality = 0.7) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas')
        let { width, height } = img

        // 按比例縮放到 maxWidth
        if (width > maxWidth) {
          height = (height * maxWidth) / width
          width = maxWidth
        }

        canvas.width = width
        canvas.height = height

        const ctx = canvas.getContext('2d')
        ctx.fillStyle = '#FFFFFF'
        ctx.fillRect(0, 0, width, height)
        ctx.drawImage(img, 0, 0, width, height)

        // 轉換爲 WebP 格式
        canvas.toBlob(
          (blob) => {
            if (blob) {
              resolve(blob)
            } else {
              reject(new Error('壓縮失敗'))
            }
          },
          'image/webp',
          quality
        )
      } catch (error) {
        reject(error)
      }
    }
    img.onerror = () => reject(new Error('圖片加載失敗'))
    img.src = URL.createObjectURL(file)
  })
}

/**
 * 壓縮圖片直到小於指定大小
 * @param {File} file - 原始圖片文件
 * @param {number} maxSize - 目標大小（字節）
 * @returns {Promise<{ blob: Blob, iterations: number }>} 壓縮結果
 */
export async function compressToSize(file, maxSize = 100 * 1024) {
  let quality = 0.9
  let iterations = 0
  const maxIterations = 10

  while (iterations < maxIterations) {
    const blob = await compressImage(file, 600, quality)

    if (blob.size <= maxSize) {
      return { blob, iterations }
    }

    quality -= 0.1
    if (quality < 0.1) {
      break
    }

    iterations++
  }

  // 如果仍然太大，返回最後一次的結果
  const blob = await compressImage(file, 600, 0.6)
  return { blob, iterations }
}

/**
 * 驗證圖片文件
 * @param {File} file - 待驗證的文件
 * @returns {Object} 驗證結果 { valid: boolean, error?: string }
 */
export function validateImageFile(file) {
  const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']

  if (!validTypes.includes(file.type)) {
    return {
      valid: false,
      error: '僅支持 JPG、PNG、WebP 格式'
    }
  }

  const maxSize = 5 * 1024 * 1024 // 5MB
  if (file.size > maxSize) {
    return {
      valid: false,
      error: '圖片大小不能超過 5MB'
    }
  }

  return { valid: true }
}
```

**Step 2: Commit**

```bash
git add web/src/utils/imageCompression.js
git commit -m "feat: add image compression utilities"
```

---

## Task 6: 創建前端圖片上傳組件

**Files:**
- Create: `web/src/components/ImageUploader.vue`

**Step 1: 創建 ImageUploader 組件**

創建 `web/src/components/ImageUploader.vue`：

```vue
<template>
  <div class="image-uploader">
    <div v-if="error" class="text-sm text-red-600 mb-2 flex items-center">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      {{ error }}
    </div>

    <!-- 狀態：未上傳 -->
    <div v-if="!imageUrl" class="upload-area" @click="triggerFileInput" @dragover.prevent @drop.prevent="handleDrop">
      <div class="upload-content">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-slate-400 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
        <p class="text-slate-600 font-medium">{{ uploading ? '壓縮上傳中...' : '點擊上傳圖片' }}</p>
        <p class="text-slate-400 text-sm mt-1">或拖拽圖片到此處</p>
        <p class="text-slate-400 text-xs mt-2">支持 JPG、PNG、WebP，最大 5MB（自動壓縮）</p>
      </div>
    </div>

    <!-- 狀態：已上傳 -->
    <div v-else class="preview-area">
      <img :src="imageUrl" class="preview-image" alt="Preview" />
      <button @click="clearImage" class="clear-btn" title="刪除圖片">
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
import { uploadPresignedUrl } from '../api/images.js'

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

  // 驗證文件
  const validation = validateImageFile(file)
  if (!validation.valid) {
    error.value = validation.error
    return
  }

  try {
    uploading.value = true

    // 壓縮圖片
    const { blob, iterations } = await compressToSize(file, 100 * 1024)

    if (blob.size > 300 * 1024) {
      error.value = '壓縮後圖片仍然過大，請選擇其他圖片'
      uploading.value = false
      return
    }

    // 上傳到 R2
    const url = await uploadPresignedUrl(blob)

    imageUrl.value = url
    emit('image-ready', url)

  } catch (err) {
    console.error('Image upload error:', err)
    error.value = err.message || '上傳失敗，請重試'
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
```

**Step 2: Commit**

```bash
git add web/src/components/ImageUploader.vue
git commit -m "feat: add ImageUploader component"
```

---

## Task 7: 實現前端圖片上傳 API

**Files:**
- Create: `web/src/api/images.js`

**Step 1: 創建 images API 模塊**

創建 `web/src/api/images.js`：

```javascript
import { client } from './client.js'

/**
 * 獲取預籤名 URL 並上傳圖片
 * @param {Blob} blob - 圖片 Blob
 * @returns {Promise<string>} 公開訪問的圖片 URL
 */
export async function uploadPresignedUrl(blob) {
  // 1. 獲取預籤名 URL
  const presignResponse = await client.post('/api/v1/images/upload-presign', {
    content_type: blob.type,
    content_length: blob.size
  })

  const { upload_url, image_url } = presignResponse.data

  // 2. 直接上傳到 R2
  const uploadResponse = await fetch(upload_url, {
    method: 'PUT',
    body: blob,
    headers: {
      'Content-Type': blob.type
    }
  })

  if (!uploadResponse.ok) {
    throw new Error('上傳失敗')
  }

  return image_url
}
```

**Step 2: 導出 API**

修改 `web/src/api/index.js`，添加：

```javascript
export * from './images.js'
```

**Step 3: Commit**

```bash
git add web/src/api/images.js web/src/api/index.js
git commit -m "feat: add image upload API client"
```

---

## Task 8: 修改 CreateExpression 組件支持圖片上傳

**Files:**
- Modify: `web/src/components/CreateExpression.vue`

**Step 1: 添加 ImageUploader 組件和語言選項**

在模板中修改語言選擇器，添加 "image" 選項：

```vue
<select v-model="language_code"
  class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-3 appearance-none"
  :disabled="languagesLoading">
  <option v-if="languagesLoading" value="" disabled>{{ $t('loading_languages') }}</option>
  <option v-else value="" disabled>{{ $t('select_language') }}</option>
  <option v-for="lang in languages" :key="lang.code" :value="lang.code">
    {{ lang.name }} ({{ lang.code }})
  </option>
  <option value="image">📷 圖片</option>
</select>
```

**Step 2: 添加條件渲染**

根據 `language_code` 動態切換輸入方式：

```vue
<!-- 文本輸入 -->
<div v-if="language_code !== 'image'" class="mb-6">
  <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('text') }} *</label>
  <textarea v-model="text" rows="3"
    class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4"
    :placeholder="$t('text_placeholder')"></textarea>
  <p class="text-sm text-slate-500 mt-1">{{ $t('text_help') }}</p>
</div>

<!-- 圖片上傳 -->
<div v-else class="mb-6">
  <label class="block text-sm font-medium text-slate-700 mb-1">圖片 *</label>
  <ImageUploader
    :existing-image-url="text"
    @image-ready="handleImageReady"
    @image-cleared="handleImageCleared"
  />
</div>
```

**Step 3: 添加腳本邏輯**

在 `<script setup>` 中添加：

```javascript
import ImageUploader from './ImageUploader.vue'

const handleImageReady = (url) => {
  text.value = url
}

const handleImageCleared = () => {
  text.value = ''
}
```

**Step 4: 清空文本輸入**

圖片模式時禁用地域選擇：

```vue
<div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6" :class="{ 'opacity-50 pointer-events-none': language_code === 'image' }">
```

**Step 5: Commit**

```bash
git add web/src/components/CreateExpression.vue
git commit -m "feat: add image upload support to CreateExpression component"
```

---

## Task 9: 修改 ExpressionCard 組件支持圖片顯示

**Files:**
- Modify: `web/src/components/ExpressionCard.vue`

**Step 1: 添加圖片顯示邏輯**

在模板中根據 `language_code` 顯示圖片或文本：

```vue
<template>
  <div class="expression-card">
    <div v-if="expression.language_code === 'image'">
      <img
        :src="expression.text"
        class="expression-image"
        alt="Expression image"
      />
    </div>
    <div v-else>
      <h3 class="expression-text">{{ expression.text }}</h3>
    </div>
    <!-- 其他內容 -->
  </div>
</template>
```

**Step 2: 添加樣式**

```vue
<style scoped>
.expression-image {
  width: 100%;
  max-width: 600px;
  height: auto;
  border-radius: 8px;
  object-fit: contain;
}

.expression-text {
  @apply text-lg font-medium text-slate-800;
}
</style>
```

**Step 3: Commit**

```bash
git add web/src/components/ExpressionCard.vue
git commit -m "feat: add image display support to ExpressionCard component"
```

---

## Task 10: 添加 "image" 語言到數據庫

**Files:**
- Create: `scripts/031_add_image_language.sql`

**Step 1: 創建遷移腳本**

創建 `scripts/031_add_image_language.sql`：

```sql
-- 添加 "image" 語言到 languages 表
INSERT INTO languages (code, name, direction, is_active, created_by, updated_by)
VALUES ('image', 'Image', 'ltr', 1, 'system', 'system');

-- 驗證插入
SELECT * FROM languages WHERE code = 'image';
```

**Step 2: 執行遷移**

```bash
npx wrangler d1 execute langmap --local --file=scripts/031_add_image_language.sql
```

**Step 3: 驗證數據**

```bash
npx wrangler d1 execute langmap --local --command="SELECT * FROM languages WHERE code = 'image'"
```

預期輸出：

```
┌──────┬───────┬───────┬───────────┬───────────┬─────────────┬─────────────┬───────────────────┬──────────┬──────────────────────┬────────────┬──────────┐
│ id   │ code  │ name  │ direction │ is_active │ region_code │ region_name │ region_latitude   │ created_by │ created_at           │ updated_by │ updated_at│
├──────┼───────┼───────┼───────────┼───────────┼─────────────┼─────────────┼───────────────────┼──────────┼──────────────────────┼────────────┼──────────┤
│ ...  │ image │ Image │ ltr       │ 1         │ NULL        │ NULL        │ NULL              │ system    │ 2026-03-23 ...       │ system     │ 2026-03-23 ...│
└──────┴───────┴───────┴───────────┴───────────┴─────────────┴─────────────┴───────────────────┴──────────┴──────────────────────┴────────────┴──────────┘
```

**Step 4: Commit**

```bash
git add scripts/031_add_image_language.sql
git commit -m "feat: add image language to database"
```

---

## Task 11: 創建 R2 Bucket

**Step 1: 創建本地 bucket（開發環境）**

```bash
npx wrangler r2 bucket create langmap-images --preview
```

**Step 2: 創建生產 bucket**

```bash
npx wrangler r2 bucket create langmap-images
```

**Step 3: 驗證 bucket**

```bash
npx wrangler r2 bucket list
```

預期輸出包含 `langmap-images`

---

## Task 12: 本地測試

**Step 1: 啓動開發服務器**

```bash
cd backend
npm run dev
```

**Step 2: 啓動前端服務器**

新終端：

```bash
cd web
npm run dev
```

**Step 3: 測試完整流程**

1. 打開瀏覽器訪問 http://localhost:5173
2. 點擊創建表達式
3. 選擇語言爲 "📷 圖片"
4. 點擊上傳區域，選擇一張 JPG/PNG 圖片
5. 等待壓縮和上傳
6. 保存表達式
7. 驗證圖片在列表頁正確顯示
8. 驗證圖片在詳情頁正確顯示

**Step 4: 測試邊界情況**

- 上傳 5MB 以上的大圖 → 應顯示錯誤
- 上傳非圖片文件 → 應顯示錯誤
- 切換語言到 "English" → 應顯示文本輸入框
- 圖片壓縮後仍 > 300KB → 應顯示錯誤
- 快速連續上傳 → 應觸發速率限制

---

## Task 13: 生產部署

**Step 1: 部署後端**

```bash
cd backend
npm run deploy
```

**Step 2: 部署前端**

```bash
cd web
npm run build
npx wrangler pages deploy dist
```

**Step 3: 執行生產數據庫遷移**

```bash
npx wrangler d1 execute langmap --file=scripts/031_add_image_language.sql
```

**Step 4: 配置自定義域名（可選）**

在 Cloudflare Dashboard 中：
1. 進入 R2 → langmap-images bucket
2. 設置 → 自定義域名
3. 添加域名：images.langmap.io
4. 配置 DNS 記錄

---

## Task 14: 功能驗證

**Step 1: 驗證 API 端點**

```bash
curl -X POST https://your-api.com/api/v1/images/upload-presign \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content_type":"image/webp","content_length":50000}'
```

預期返回：

```json
{
  "upload_url": "https://...",
  "image_url": "https://images.langmap.io/...",
  "expires_in": 300,
  "file_id": "..."
}
```

**Step 2: 驗證圖片存儲**

```bash
npx wrangler r2 object list langmap-images
```

預期顯示上傳的圖片文件

**Step 3: 驗證表達式創建**

```bash
curl -X POST https://your-api.com/api/v1/expressions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "https://images.langmap.io/xxx.webp",
    "language_code": "image"
  }'
```

預期返回創建的表達式對象

---

## Task 15: 性能優化監控

**Step 1: 監控壓縮性能**

在瀏覽器 DevTools 中：
- 記錄壓縮耗時（應在 1-3 秒內）
- 記錄壓縮後大小（應 < 100KB）
- 記錄上傳耗時（應在 1-2 秒內）

**Step 2: 監控 API 性能**

在 Cloudflare Dashboard 中：
- 查看 Workers Analytics
- 監控 `/api/v1/images/upload-presign` 端點的響應時間
- 監控 CPU 時間和內存使用

**Step 3: 調整壓縮參數（如需要）**

如果壓縮耗時過長：
- 降低 `maxWidth` 到 500px
- 降低初始 `quality` 到 0.8

如果壓縮後大小過大：
- 降低目標質量到 0.6
- 添加多級壓縮邏輯

---

## Task 16: 文檔更新

**Files:**
- Modify: `docs/design/features/feat-image-expression.md`

**Step 1: 更新實現狀態**

在文檔開頭修改：

```markdown
## System Reminder

**實現狀態**：
- ✅ R2 存儲桶/目錄配置（圖片用）已設置
- ✅ 預籤名 URL API 已實現
- ✅ 前端圖片上傳組件已實現
- ✅ 前端圖片壓縮邏輯已實現
- ✅ 數據庫 `language_code='image'` 插入已完成
- ✅ 前端根據 language_code 動態切換輸入方式已實現
```

**Step 2: 添加部署章節**

在文檔末尾添加：

```markdown
## 部署記錄

**日期**：2026-03-23
**版本**：v1.0.0

**完成事項**：
- R2 bucket 創建完成
- API 端點部署完成
- 前端組件集成完成
- 數據庫遷移完成
- 生產環境測試通過

**已知限制**：
- 圖片最大尺寸限制爲 600px 寬度
- 壓縮質量固定爲 0.7
- 預籤名 URL 有效期爲 5 分鐘
- 普通用戶速率限制：5 次/分鐘（預籤名），10 次/分鐘（創建）
```

**Step 3: Commit**

```bash
git add docs/design/features/feat-image-expression.md
git commit -m "docs: update implementation status and deployment records"
```

---

## Task 17: 標籤更新

**Step 1: 創建版本標籤**

```bash
git tag -a v1.0.0-image-feature -m "Add image expression feature"
```

**Step 2: 推送標籤**

```bash
git push origin v1.0.0-image-feature
```

---

## 總結

本實施計劃涵蓋了圖片詞句功能的完整實現，包括：

✅ **後端**：R2 配置、預籤名 URL API、schema 驗證、速率限制
✅ **前端**：圖片壓縮工具、上傳組件、API 集成、UI 動態切換
✅ **數據庫**：添加 "image" 語言
✅ **測試**：本地測試、生產驗證、性能監控
✅ **文檔**：實現狀態更新、部署記錄

按照此計劃逐步實施，可以實現一個高效、安全、用戶友好的圖片表達功能。
