import { Hono } from 'hono'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'

const exportRoutes = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>()

exportRoutes.post('/', requireAuth, async (c) => {
  try {
    const body = await c.req.json()
    const { collectionId, format } = body

    if (!collectionId) {
      return c.json({ error: "collectionId is required" }, 400)
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

    return c.json({ jobId, status: "pending" })
  } catch (err: any) {
    console.error("Export start error:", err)
    return c.json({ error: "Failed to start export" }, 500)
  }
})

exportRoutes.get('/health', async (c) => {
  try {
    const jobId = "health_check"
    const id = c.env.EXPORT_DO.idFromName(jobId)
    const stub = c.env.EXPORT_DO.get(id)
    const res = await stub.fetch("https://do/health")
    const text = await res.text()
    return c.json({ status: res.status, message: text })
  } catch (err: any) {
    return c.json({ error: "Health check failed: " + err.message }, 500)
  }
})

exportRoutes.get('/:jobId', requireAuth, async (c) => {
  try {
    const jobId = c.req.param('jobId')
    if (!jobId) return c.json({ error: "Job ID required" }, 400)

    const id = c.env.EXPORT_DO.idFromName(jobId)
    const stub = c.env.EXPORT_DO.get(id)

    const res = await stub.fetch("https://do/status")

    if (!res.ok) {
      const errorText = await res.text()
      console.error("DO Error Status:", res.status, errorText)
      if (res.status === 404) {
        return c.json({ error: "Job not found" }, 404)
      }
      return c.json({ error: `Export job error: ${res.status} ${errorText}` }, 500)
    }

    const text = await res.text()
    if (!text) {
      console.error("DO returned empty response")
      return c.json({ error: "Empty response from export job" }, 500)
    }

    try {
      const data = JSON.parse(text)
      return c.json(data)
    } catch (e) {
      console.error("Failed to parse DO response:", text)
      return c.json({ error: "Invalid response from export job" }, 500)
    }
  } catch (err: any) {
    console.error("Export status error:", err)
    return c.json({ error: "Failed to check status" }, 500)
  }
})

export default exportRoutes
