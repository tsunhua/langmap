import { Hono } from 'hono'
import api from './server/api'

const app = new Hono()

// 正确的路由配置应该是：
app.route('/api', api);

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
          return assetResponse;
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
      return await c.env.ASSETS.fetch(new Request(indexPath));
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
    console.error('Error serving page:', error);
    return c.text('Error serving page', 500);
  }
});


export default app