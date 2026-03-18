import { Hono } from 'hono'
import type { Bindings } from '../../bindings.js'

const downloadRoutes = new Hono<{ Bindings: Bindings }>()

downloadRoutes.get('/', async (c) => {
  try {
    const key = c.req.query('key')
    if (!key) {
      return c.json({ error: "File key required" }, 400)
    }

    if (!key.startsWith('exports/')) {
      return c.json({ error: "Invalid file key" }, 403)
    }

    const object = await c.env.EXPORT_BUCKET.get(key)

    if (object === null) {
      return c.json({ error: "File not found" }, 404)
    }

    const headers = new Headers()
    object.writeHttpMetadata(headers as any)
    headers.set('etag', object.httpEtag)
    headers.set("Content-Disposition", `attachment; filename="${key.split('/').pop()}"`)

    return new Response(object.body as any, {
      headers,
    })
  } catch (err: any) {
    console.error("Download error:", err)
    return c.json({ error: "Failed to download file" }, 500)
  }
})

export default downloadRoutes
