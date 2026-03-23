# 图片词句功能实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**目标：** 实现 LangMap 图片表达功能，支持用户上传、压缩、存储和展示图片作为表达式，采用客户端直传 R2 + 预签名 URL 架构。

**架构：**
- **存储**：Cloudflare R2 (langmap-images bucket)，WebP 格式，最大 300KB
- **上传**：客户端直传 R2 (Presigned URL)，避免 Worker 代理
- **识别**：`language_code = 'image'` 标识图片表达式，`text` 存储图片 URL
- **压缩**：前端 Canvas 压缩到 600px 宽度，质量 0.7，目标 < 100KB
- **分发**：Cloudflare CDN 边缘缓存，永久静态缓存 (max-age=31536000)

**技术栈：**
- **后端**：Cloudflare Workers + D1 + R2 + Hono + Zod
- **前端**：Vue 3 + Vite + Tailwind CSS
- **压缩**：HTML5 Canvas API
- **验证**：Zod schema，URL 前缀验证，速率限制

---

## Task 1: 配置 R2 存储桶和后端环境

**Files:**
- Modify: `backend/wrangler.jsonc`

**Step 1: 添加 R2 bucket binding**

修改 `wrangler.jsonc`，在 `r2_buckets` 数组中添加：

```jsonc
{
  "binding": "IMAGES_BUCKET",
  "bucket_name": "langmap-images",
  "preview_bucket_name": "langmap-images"
}
```

完整配置应如下：

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

**Step 2: 更新类型定义**

修改 `backend/src/server/types/bindings.ts`，在 `Bindings` interface 中添加：

```typescript
IMAGES_BUCKET: R2Bucket
```

**Step 3: 添加环境变量**

修改 `backend/wrangler.jsonc`，在 `[vars]` 部分添加：

```toml
[vars]
R2_IMAGES_BUCKET = "langmap-images"
IMAGES_PUBLIC_URL = "https://images.langmap.io"
```

**Step 4: 验证配置**

```bash
cd backend
npx wrangler dev
```

预期：Worker 启动成功，无错误

**Step 5: Commit**

```bash
git add backend/wrangler.jsonc backend/src/server/types/bindings.ts
git commit -m "feat: add R2 images bucket configuration"
```

---

## Task 2: 更新 Expression Schema 支持 Image 语言

**Files:**
- Modify: `backend/src/server/schemas/expression.ts`

**Step 1: 修改 createExpressionSchema**

更新验证逻辑，支持 `language_code = 'image'` 和 URL 验证：

```typescript
export const createExpressionSchema = z.object({
  text: z.string().min(1).max(1000),
  language_code: z.string().min(2).max(36),
  meaning_id: z.number().optional(),
  audio_url: z.string().optional(),
  region_code: z.string().optional()
}).superRefine((data, ctx) => {
  // 当 language_code = "image" 时，text 必须是有效 URL
  if (data.language_code === 'image') {
    if (!data.text.startsWith('http://') && !data.text.startsWith('https://')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '图片 URL 必须以 http:// 或 https:// 开头',
        path: ['text']
      })
    }

    // 验证 URL 域名
    try {
      const url = new URL(data.text)
      if (!url.hostname.endsWith('.langmap.io') && !url.hostname.includes('r2.cloudflarestorage.com')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: '仅允许使用系统生成的图片 URL',
          path: ['text']
        })
      }
    } catch {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '图片 URL 格式无效',
        path: ['text']
      })
    }
  }
})
```

**Step 2: 修改 updateExpressionSchema**

添加相同的 URL 验证：

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
        message: '图片 URL 必须以 http:// 或 https:// 开头',
        path: ['text']
      })
    }

    try {
      const url = new URL(data.text)
      if (!url.hostname.endsWith('.langmap.io') && !url.hostname.includes('r2.cloudflarestorage.com')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: '仅允许使用系统生成的图片 URL',
          path: ['text']
        })
      }
    } catch {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '图片 URL 格式无效',
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

## Task 3: 实现图片上传预签名 URL API

**Files:**
- Create: `backend/src/server/routes/images.ts`
- Modify: `backend/src/server/routes/index.ts`

**Step 1: 创建 images routes**

创建 `backend/src/server/routes/images.ts`：

```typescript
import { Hono } from 'hono'
import { requireAuth } from '../middleware/auth.js'
import { z } from 'zod'
import { success, badRequest, internalError } from '../utils/response.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'

const imagesRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

// 速率限制存储（生产环境应使用 KV 或 Durable Object）
const rateLimiter = new Map<string, { count: number, resetTime: number }>()

// 验证 schema
const uploadPresignSchema = z.object({
  content_type: z.string().regex(/^image\/(webp|jpeg|jpg|png)$/i),
  content_length: z.number().max(1048576) // 最大 1MB
})

imagesRoutes.post('/upload-presign', requireAuth, async (c) => {
  try {
    const user = c.get('user')
    const body = await c.req.json()

    // 验证请求
    const validated = uploadPresignSchema.parse(body)

    // 速率限制（管理员无限制）
    if (user.role !== 'super_admin' && user.role !== 'admin') {
      const now = Date.now()
      const key = `presign:${user.username}`
      const record = rateLimiter.get(key)

      if (record && record.resetTime > now) {
        if (record.count >= 5) {
          return badRequest(c, '请求过于频繁，请稍后再试')
        }
        record.count++
      } else {
        rateLimiter.set(key, { count: 1, resetTime: now + 60000 })
      }
    }

    // 生成唯一文件名
    const fileId = crypto.randomUUID()
    const fileName = `${fileId}.webp`

    // 构建预签名 URL（5分钟有效期）
    const bucket = c.env.IMAGES_BUCKET
    const uploadUrl = await new Request(`https://${bucket.name}.r2.cloudflarestorage.com/${fileName}`, {
      method: 'PUT',
      headers: {
        'Content-Type': validated.content_type
      }
    }).cf({
      // Cloudflare 会自动生成预签名 URL
    })

    // 公开访问的 URL
    const publicUrl = `${c.env.IMAGES_PUBLIC_URL}/${fileName}`

    return success(c, {
      upload_url: uploadUrl.url,
      image_url: publicUrl,
      expires_in: 300,
      file_id: fileId
    })
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, '验证失败', undefined, error.errors)
    }
    console.error('Error in POST /images/upload-presign:', error)
    return internalError(c, error.message || '获取预签名 URL 失败')
  }
})

export { imagesRoutes }
```

**Step 2: 注册路由**

修改 `backend/src/server/routes/index.ts`，添加图片路由：

```typescript
import { Hono } from 'hono'
import { imagesRoutes } from './images.js'

// ... 其他导入

const routes = new Hono()

// 注册路由
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

在 `POST /expressions` 路由中添加图片表达式的速率限制：

```typescript
// 速率限制存储
const expressionRateLimiter = new Map<string, { count: number, resetTime: number, imageCount: number }>()

expressionsRoutes.post('/', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const body = await c.req.json()

    // 验证
    const validated = createExpressionSchema.parse(body)

    // 速率限制（管理员无限制）
    if (user.role !== 'super_admin' && user.role !== 'admin') {
      const now = Date.now()
      const key = `expression:${user.username}`
      const record = expressionRateLimiter.get(key)

      if (record && record.resetTime > now) {
        // 图片表达式额外限制：每分钟最多 10 次
        if (validated.language_code === 'image') {
          if (record.imageCount >= 10) {
            return badRequest(c, '图片表达式创建过于频繁，请稍后再试')
          }
          record.imageCount++
        }

        // 总体限制：每分钟最多 20 次
        if (record.count >= 20) {
          return badRequest(c, '表达式创建过于频繁，请稍后再试')
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

## Task 5: 实现前端图片压缩工具函数

**Files:**
- Create: `web/src/utils/imageCompression.js`

**Step 1: 创建图片压缩工具**

创建 `web/src/utils/imageCompression.js`：

```javascript
/**
 * 压缩图片到指定宽度和质量
 * @param {File} file - 原始图片文件
 * @param {number} maxWidth - 最大宽度（默认 600px）
 * @param {number} quality - 质量 0-1（默认 0.7）
 * @returns {Promise<Blob>} 压缩后的 Blob
 */
export async function compressImage(file, maxWidth = 600, quality = 0.7) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas')
        let { width, height } = img

        // 按比例缩放到 maxWidth
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

        // 转换为 WebP 格式
        canvas.toBlob(
          (blob) => {
            if (blob) {
              resolve(blob)
            } else {
              reject(new Error('压缩失败'))
            }
          },
          'image/webp',
          quality
        )
      } catch (error) {
        reject(error)
      }
    }
    img.onerror = () => reject(new Error('图片加载失败'))
    img.src = URL.createObjectURL(file)
  })
}

/**
 * 压缩图片直到小于指定大小
 * @param {File} file - 原始图片文件
 * @param {number} maxSize - 目标大小（字节）
 * @returns {Promise<{ blob: Blob, iterations: number }>} 压缩结果
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

  // 如果仍然太大，返回最后一次的结果
  const blob = await compressImage(file, 600, 0.6)
  return { blob, iterations }
}

/**
 * 验证图片文件
 * @param {File} file - 待验证的文件
 * @returns {Object} 验证结果 { valid: boolean, error?: string }
 */
export function validateImageFile(file) {
  const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']

  if (!validTypes.includes(file.type)) {
    return {
      valid: false,
      error: '仅支持 JPG、PNG、WebP 格式'
    }
  }

  const maxSize = 5 * 1024 * 1024 // 5MB
  if (file.size > maxSize) {
    return {
      valid: false,
      error: '图片大小不能超过 5MB'
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

## Task 6: 创建前端图片上传组件

**Files:**
- Create: `web/src/components/ImageUploader.vue`

**Step 1: 创建 ImageUploader 组件**

创建 `web/src/components/ImageUploader.vue`：

```vue
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
```

**Step 2: Commit**

```bash
git add web/src/components/ImageUploader.vue
git commit -m "feat: add ImageUploader component"
```

---

## Task 7: 实现前端图片上传 API

**Files:**
- Create: `web/src/api/images.js`

**Step 1: 创建 images API 模块**

创建 `web/src/api/images.js`：

```javascript
import { client } from './client.js'

/**
 * 获取预签名 URL 并上传图片
 * @param {Blob} blob - 图片 Blob
 * @returns {Promise<string>} 公开访问的图片 URL
 */
export async function uploadPresignedUrl(blob) {
  // 1. 获取预签名 URL
  const presignResponse = await client.post('/api/v1/images/upload-presign', {
    content_type: blob.type,
    content_length: blob.size
  })

  const { upload_url, image_url } = presignResponse.data

  // 2. 直接上传到 R2
  const uploadResponse = await fetch(upload_url, {
    method: 'PUT',
    body: blob,
    headers: {
      'Content-Type': blob.type
    }
  })

  if (!uploadResponse.ok) {
    throw new Error('上传失败')
  }

  return image_url
}
```

**Step 2: 导出 API**

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

## Task 8: 修改 CreateExpression 组件支持图片上传

**Files:**
- Modify: `web/src/components/CreateExpression.vue`

**Step 1: 添加 ImageUploader 组件和语言选项**

在模板中修改语言选择器，添加 "image" 选项：

```vue
<select v-model="language_code"
  class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-3 appearance-none"
  :disabled="languagesLoading">
  <option v-if="languagesLoading" value="" disabled>{{ $t('loading_languages') }}</option>
  <option v-else value="" disabled>{{ $t('select_language') }}</option>
  <option v-for="lang in languages" :key="lang.code" :value="lang.code">
    {{ lang.name }} ({{ lang.code }})
  </option>
  <option value="image">📷 图片</option>
</select>
```

**Step 2: 添加条件渲染**

根据 `language_code` 动态切换输入方式：

```vue
<!-- 文本输入 -->
<div v-if="language_code !== 'image'" class="mb-6">
  <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('text') }} *</label>
  <textarea v-model="text" rows="3"
    class="block w-full rounded-md border border-blue-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4"
    :placeholder="$t('text_placeholder')"></textarea>
  <p class="text-sm text-slate-500 mt-1">{{ $t('text_help') }}</p>
</div>

<!-- 图片上传 -->
<div v-else class="mb-6">
  <label class="block text-sm font-medium text-slate-700 mb-1">图片 *</label>
  <ImageUploader
    :existing-image-url="text"
    @image-ready="handleImageReady"
    @image-cleared="handleImageCleared"
  />
</div>
```

**Step 3: 添加脚本逻辑**

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

**Step 4: 清空文本输入**

图片模式时禁用地域选择：

```vue
<div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6" :class="{ 'opacity-50 pointer-events-none': language_code === 'image' }">
```

**Step 5: Commit**

```bash
git add web/src/components/CreateExpression.vue
git commit -m "feat: add image upload support to CreateExpression component"
```

---

## Task 9: 修改 ExpressionCard 组件支持图片显示

**Files:**
- Modify: `web/src/components/ExpressionCard.vue`

**Step 1: 添加图片显示逻辑**

在模板中根据 `language_code` 显示图片或文本：

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
    <!-- 其他内容 -->
  </div>
</template>
```

**Step 2: 添加样式**

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

## Task 10: 添加 "image" 语言到数据库

**Files:**
- Create: `scripts/031_add_image_language.sql`

**Step 1: 创建迁移脚本**

创建 `scripts/031_add_image_language.sql`：

```sql
-- 添加 "image" 语言到 languages 表
INSERT INTO languages (code, name, direction, is_active, created_by, updated_by)
VALUES ('image', 'Image', 'ltr', 1, 'system', 'system');

-- 验证插入
SELECT * FROM languages WHERE code = 'image';
```

**Step 2: 执行迁移**

```bash
npx wrangler d1 execute langmap --local --file=scripts/031_add_image_language.sql
```

**Step 3: 验证数据**

```bash
npx wrangler d1 execute langmap --local --command="SELECT * FROM languages WHERE code = 'image'"
```

预期输出：

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

## Task 11: 创建 R2 Bucket

**Step 1: 创建本地 bucket（开发环境）**

```bash
npx wrangler r2 bucket create langmap-images --preview
```

**Step 2: 创建生产 bucket**

```bash
npx wrangler r2 bucket create langmap-images
```

**Step 3: 验证 bucket**

```bash
npx wrangler r2 bucket list
```

预期输出包含 `langmap-images`

---

## Task 12: 本地测试

**Step 1: 启动开发服务器**

```bash
cd backend
npm run dev
```

**Step 2: 启动前端服务器**

新终端：

```bash
cd web
npm run dev
```

**Step 3: 测试完整流程**

1. 打开浏览器访问 http://localhost:5173
2. 点击创建表达式
3. 选择语言为 "📷 图片"
4. 点击上传区域，选择一张 JPG/PNG 图片
5. 等待压缩和上传
6. 保存表达式
7. 验证图片在列表页正确显示
8. 验证图片在详情页正确显示

**Step 4: 测试边界情况**

- 上传 5MB 以上的大图 → 应显示错误
- 上传非图片文件 → 应显示错误
- 切换语言到 "English" → 应显示文本输入框
- 图片压缩后仍 > 300KB → 应显示错误
- 快速连续上传 → 应触发速率限制

---

## Task 13: 生产部署

**Step 1: 部署后端**

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

**Step 3: 执行生产数据库迁移**

```bash
npx wrangler d1 execute langmap --file=scripts/031_add_image_language.sql
```

**Step 4: 配置自定义域名（可选）**

在 Cloudflare Dashboard 中：
1. 进入 R2 → langmap-images bucket
2. 设置 → 自定义域名
3. 添加域名：images.langmap.io
4. 配置 DNS 记录

---

## Task 14: 功能验证

**Step 1: 验证 API 端点**

```bash
curl -X POST https://your-api.com/api/v1/images/upload-presign \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content_type":"image/webp","content_length":50000}'
```

预期返回：

```json
{
  "upload_url": "https://...",
  "image_url": "https://images.langmap.io/...",
  "expires_in": 300,
  "file_id": "..."
}
```

**Step 2: 验证图片存储**

```bash
npx wrangler r2 object list langmap-images
```

预期显示上传的图片文件

**Step 3: 验证表达式创建**

```bash
curl -X POST https://your-api.com/api/v1/expressions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "https://images.langmap.io/xxx.webp",
    "language_code": "image"
  }'
```

预期返回创建的表达式对象

---

## Task 15: 性能优化监控

**Step 1: 监控压缩性能**

在浏览器 DevTools 中：
- 记录压缩耗时（应在 1-3 秒内）
- 记录压缩后大小（应 < 100KB）
- 记录上传耗时（应在 1-2 秒内）

**Step 2: 监控 API 性能**

在 Cloudflare Dashboard 中：
- 查看 Workers Analytics
- 监控 `/api/v1/images/upload-presign` 端点的响应时间
- 监控 CPU 时间和内存使用

**Step 3: 调整压缩参数（如需要）**

如果压缩耗时过长：
- 降低 `maxWidth` 到 500px
- 降低初始 `quality` 到 0.8

如果压缩后大小过大：
- 降低目标质量到 0.6
- 添加多级压缩逻辑

---

## Task 16: 文档更新

**Files:**
- Modify: `docs/design/features/feat-image-expression.md`

**Step 1: 更新实现状态**

在文档开头修改：

```markdown
## System Reminder

**实现状态**：
- ✅ R2 存储桶/目录配置（图片用）已设置
- ✅ 预签名 URL API 已实现
- ✅ 前端图片上传组件已实现
- ✅ 前端图片压缩逻辑已实现
- ✅ 数据库 `language_code='image'` 插入已完成
- ✅ 前端根据 language_code 动态切换输入方式已实现
```

**Step 2: 添加部署章节**

在文档末尾添加：

```markdown
## 部署记录

**日期**：2026-03-23
**版本**：v1.0.0

**完成事项**：
- R2 bucket 创建完成
- API 端点部署完成
- 前端组件集成完成
- 数据库迁移完成
- 生产环境测试通过

**已知限制**：
- 图片最大尺寸限制为 600px 宽度
- 压缩质量固定为 0.7
- 预签名 URL 有效期为 5 分钟
- 普通用户速率限制：5 次/分钟（预签名），10 次/分钟（创建）
```

**Step 3: Commit**

```bash
git add docs/design/features/feat-image-expression.md
git commit -m "docs: update implementation status and deployment records"
```

---

## Task 17: 标签更新

**Step 1: 创建版本标签**

```bash
git tag -a v1.0.0-image-feature -m "Add image expression feature"
```

**Step 2: 推送标签**

```bash
git push origin v1.0.0-image-feature
```

---

## 总结

本实施计划涵盖了图片词句功能的完整实现，包括：

✅ **后端**：R2 配置、预签名 URL API、schema 验证、速率限制
✅ **前端**：图片压缩工具、上传组件、API 集成、UI 动态切换
✅ **数据库**：添加 "image" 语言
✅ **测试**：本地测试、生产验证、性能监控
✅ **文档**：实现状态更新、部署记录

按照此计划逐步实施，可以实现一个高效、安全、用户友好的图片表达功能。
