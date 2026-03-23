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
    const signed = await bucket.presign(fileName, {
      expiresIn: 300, // 5 分钟
      method: 'PUT'
    })

    // 公开访问的 URL
    const publicUrl = `${c.env.IMAGES_PUBLIC_URL}/${fileName}`

    return success(c, {
      upload_url: signed.url,
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
