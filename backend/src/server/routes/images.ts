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

imagesRoutes.post('/upload', requireAuth, async (c) => {
  try {
    const user = c.get('user')

    // 速率限制（管理员无限制）
    if (user.role !== 'super_admin' && user.role !== 'admin') {
      const now = Date.now()
      const key = `upload:${user.username}`
      const record = rateLimiter.get(key)

      if (record && record.resetTime > now) {
        if (record.count >= 10) {
          return badRequest(c, '请求过于频繁，请稍后再试')
        }
        record.count++
      } else {
        rateLimiter.set(key, { count: 1, resetTime: now + 60000 })
      }
    }

    // 使用 formData 而不是 parseBody
    const formData = await c.req.formData()
    const file = formData.get('image_file')

    if (!file || !(file instanceof File)) {
      console.error('File not found or invalid. formData keys:', Array.from(formData.keys()))
      return badRequest(c, '图片文件缺失或无效')
    }

    // 验证文件类型和大小
    const validTypes = ['image/webp', 'image/jpeg', 'image/jpg', 'image/png']
    if (!validTypes.includes(file.type)) {
      return badRequest(c, '仅支持 JPG、PNG、WebP 格式')
    }

    if (file.size > 1048576) {
      return badRequest(c, '图片大小不能超过 1MB')
    }

    // 生成唯一文件名
    const fileId = crypto.randomUUID()
    const fileName = `${fileId}.webp`

    // 上传到 R2
    await c.env.IMAGES_BUCKET.put(fileName, await file.arrayBuffer(), {
      httpMetadata: {
        contentType: file.type
      }
    })

    // 公开访问的 URL
    const isDev = c.req.url.includes('localhost') || c.req.url.includes('127.0.0.1')
    const publicUrl = isDev ? `http://localhost:8787/image-assets/${fileName}` : `https://images.langmap.io/${fileName}`

    return success(c, {
      image_url: publicUrl,
      file_id: fileId
    })
  } catch (error: any) {
    console.error('Error in POST /images/upload:', error)
    console.error('Error stack:', error.stack)
    return internalError(c, error.message || '上传图片失败')
  }
})

export { imagesRoutes }
