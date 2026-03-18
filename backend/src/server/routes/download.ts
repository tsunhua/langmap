import { Hono } from 'hono'
import type { Bindings } from '../../bindings.js'
import { badRequest, notFound, internalError } from '../utils/response.js'

const downloadRoutes = new Hono<{ Bindings: Bindings }>()

downloadRoutes.get('/', async (c) => {
  try {
    const key = c.req.query('key')
    if (!key) {
      return badRequest(c, "File key required")
    }

    if (!key.startsWith('exports/')) {
      return internalError(c, "Invalid file key", undefined, 403)
    }

    const object = await c.env.EXPORT_BUCKET.get(key)

    if (object === null) {
      return notFound(c, "File")
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
    return internalError(c, "Failed to download file")
  }
})

export default downloadRoutes
