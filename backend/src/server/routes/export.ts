import { Hono } from 'hono'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { success, badRequest, notFound, internalError } from '../utils/response.js'

const exportRoutes = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>()

exportRoutes.post('/', requireAuth, async (c) => {
  try {
    const body = await c.req.json()
    const { collectionId, format } = body

    if (!collectionId) {
      return badRequest(c, "collectionId is required")
    }

    const startFormat = format === 'csv' ? 'csv' : 'json'

    const jobId = `exp_${Date.now()}_${crypto.randomUUID()}`
    const id = c.env.EXPORT_DO.idFromName(jobId)
    const stub = c.env.EXPORT_DO.get(id)

    await stub.fetch("https://do/start", {
      method: "POST",
      body: JSON.stringify({
        jobId,
        collectionId: collectionId.toString(),
        format: startFormat
      }),
    })

    return success(c, { jobId, status: "pending" })
  } catch (err: any) {
    console.error("Export start error:", err)
    return internalError(c, "Failed to start export")
  }
})

exportRoutes.get('/health', async (c) => {
  try {
    const jobId = "health_check"
    const id = c.env.EXPORT_DO.idFromName(jobId)
    const stub = c.env.EXPORT_DO.get(id)
    const res = await stub.fetch("https://do/health")
    const text = await res.text()
    return success(c, { status: res.status, message: text })
  } catch (err: any) {
    return internalError(c, "Health check failed: " + err.message)
  }
})

exportRoutes.get('/:jobId', requireAuth, async (c) => {
  try {
    const jobId = c.req.param('jobId')
    if (!jobId) return badRequest(c, "Job ID required")

    const id = c.env.EXPORT_DO.idFromName(jobId)
    const stub = c.env.EXPORT_DO.get(id)

    const res = await stub.fetch("https://do/status")

    if (!res.ok) {
      const errorText = await res.text()
      console.error("DO Error Status:", res.status, errorText)
      if (res.status === 404) {
        return notFound(c, "Export job")
      }
      return internalError(c, `Export job error: ${res.status} ${errorText}`)
    }

    const text = await res.text()
    if (!text) {
      console.error("DO returned empty response")
      return internalError(c, "Empty response from export job")
    }

    try {
      const data = JSON.parse(text)
      return success(c, data)
    } catch (e) {
      console.error("Failed to parse DO response:", text)
      return internalError(c, "Invalid response from export job")
    }
  } catch (err: any) {
    console.error("Export status error:", err)
    return internalError(c, "Failed to check status")
  }
})

export default exportRoutes
