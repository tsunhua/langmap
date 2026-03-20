import { Context, Next } from 'hono'

export const cacheMiddleware = (maxAge: number = 3600) => {
  return async (c: Context, next: Next) => {
    if (c.req.method !== 'GET' || c.req.header('Cache-Control') === 'no-cache') {
      return await next()
    }

    const url = new URL(c.req.url)
    const cacheKey = new Request(url.toString(), c.req.raw)
    const cache = (caches as any).default

    try {
      const cachedResponse = await cache.match(cacheKey)
      if (cachedResponse) {
        console.log(`[L2 Cache] Hit: ${url.pathname}${url.search}`)
        return cachedResponse
      }
    } catch (e) {
      console.warn('[L2 Cache] Match error (likely local dev without --remote):', e)
    }

    await next()

    if (c.res && c.res.status === 200 && cache) {
      try {
        const responseToCache = c.res.clone()
        responseToCache.headers.set('Cache-Control', `public, max-age=${maxAge}`)
        c.executionCtx.waitUntil(cache.put(cacheKey, responseToCache))
        console.log(`[L2 Cache] Miss/Put: ${url.pathname}${url.search}`)
      } catch (e) {
        console.error('[L2 Cache] Put error:', e)
      }
    }
  }
}

export async function clearCache(c: Context, pattern: string) {
  try {
    const cache = (caches as any).default
    if (cache) {
      const url = new URL(pattern, c.req.url)
      const cacheKey = new Request(url.toString())
      await cache.delete(cacheKey)
      console.log(`[L2 Cache] Cleared cache for ${pattern}`)
    }
  } catch (e) {
    console.warn('[L2 Cache] Failed to clear cache:', e)
  }
}
