import { Hono } from 'hono'
import { serveStatic } from 'hono/cloudflare-workers'
import api from './server/api'

const app = new Hono()

// Serve homepage from Cloudflare assets
api.get('/', async (c) => {
  try {
    // @ts-ignore - __STATIC_CONTENT is a Cloudflare global binding
    const htmlContent = await c.ASSETS.get('index.html')
    if (!htmlContent) {
      return c.text('Homepage not found', 404)
    }
    return c.html(htmlContent)
  } catch (error) {
    return c.text('Error serving homepage', 500)
  }
})


// API routes
app.route('/api', api)

export default app