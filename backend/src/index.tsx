import { Hono } from 'hono'
import api from './server/api'
import type { R2Bucket } from '@cloudflare/workers-types'

// Define types for our environment bindings
interface Bindings {
  DB: D1Database;
  ASSETS: any;
  RESEND_API_KEY: string;
  IMAGES_BUCKET: R2Bucket;
}

const app = new Hono<{ Bindings: Bindings }>()

// 正确的路由配置应该是：
app.route('/api', api);

// 图片资产代理
app.get('/image-assets/*', async (c) => {
  if (!c.env?.IMAGES_BUCKET) {
    return new Response('Storage configuration error', { status: 500 })
  }

  const key = c.req.path.replace('/image-assets/', '')

  try {
    const object = await c.env.IMAGES_BUCKET.get(key)

    if (!object) {
      return new Response('Not found', { status: 404 })
    }

    const headers = new Headers()
    object.writeHttpMetadata(headers)
    headers.set('etag', object.httpEtag)

    return new Response(object.body, headers)
  } catch (error) {
    console.error('Error serving image:', error)
    return new Response('Error serving image', { status: 500 })
  }
})

// 处理所有非API路由，返回前端应用
app.get('*', async (c) => {
  try {
    // 首先尝试从ASSETS获取请求的资源
    // @ts-ignore - ASSETS is a Cloudflare global binding
    if (c.env?.ASSETS) {
      try {
        // @ts-ignore - ASSETS is a Cloudflare global binding
        const assetResponse = await c.env.ASSETS.fetch(
          new Request(c.req.url, c.req.raw)
        );
        // 如果找到了静态资源（状态码不是404），则返回该资源
        if (assetResponse && assetResponse.status !== 404) {
          const url = new URL(c.req.url);
          const path = url.pathname;

          // 创建一个带有新Headers的Response
          const newResponse = new Response(assetResponse.body, assetResponse);

          if (path.startsWith('/assets/')) {
            //assets下的资源通常带有哈希值，可以长期缓存
            newResponse.headers.set('Cache-Control', 'public, max-age=31536000, immutable');
          } else if (path.startsWith('/icons/')) {
            //图标资源缓存1天
            newResponse.headers.set('Cache-Control', 'public, max-age=86400');
          } else if (path === '/' || path.endsWith('/index.html') || path === '/manifest.json') {
            //入口文件不缓存，确保应用更新
            newResponse.headers.set('Cache-Control', 'no-cache');
          } else {
            //其他静态资源缓存1小时
            newResponse.headers.set('Cache-Control', 'public, max-age=3600');
          }

          return newResponse;
        }
      } catch (error) {
        console.log('Asset not found in ASSETS, falling back to index.html');
      }
    }

    // 如果没有找到静态资源，则返回index.html（SPA路由处理）
    // @ts-ignore - ASSETS is a Cloudflare global binding
    if (c.env?.ASSETS) {
      const indexPath = new URL('/index.html', c.req.url).href;
      // @ts-ignore - ASSETS is a Cloudflare global binding
      const indexResponse = await c.env.ASSETS.fetch(new Request(indexPath));
      if (indexResponse) {
        const res = new Response(indexResponse.body, indexResponse);
        res.headers.set('Cache-Control', 'no-cache');
        return res;
      }
      return indexResponse;
    }

    // 开发环境后备方案
    return c.html(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>LangMap</title>
      </head>
      <body>
        <div id="app"></div>
        <script type="module" src="/assets/index-CX5XgOcg.js"></script>
      </body>
      </html>
    `);
  } catch (error) {
    console.error('Error serving static file:', error);
    return c.html('<h1>Error serving static file</h1>', 500);
  }
})

export { ExportDO } from './do/ExportDO'
export default app