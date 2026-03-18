import { Hono } from 'hono'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { cacheMiddleware, clearCache } from '../middleware/cache.js'

const miscRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

miscRoutes.get('/heatmap', cacheMiddleware(600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const heatmapData = await db.getHeatmapData()
    return c.json({ data: heatmapData })
  } catch (error: any) {
    console.error('Error in GET /heatmap:', error)
    return c.json({ error: 'Failed to fetch heatmap data' }, 500)
  }
})

miscRoutes.get('/statistics', cacheMiddleware(3600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const statistics = await db.getStatistics()
    return c.json(statistics)
  } catch (error: any) {
    console.error('Error in GET /statistics:', error)
    return c.json({ error: 'Failed to fetch statistics' }, 500)
  }
})

miscRoutes.get('/search', cacheMiddleware(3600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const query = c.req.query('q') || ''
    const fromLang = c.req.query('from_lang') || undefined
    const region = c.req.query('region') || undefined
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    const includeMeanings = c.req.query('include_meanings') === 'true'

    if (!query) {
      return c.json({ error: 'Query parameter is required' }, 400)
    }

    const results = await db.searchExpressions(query, fromLang, region, skip, limit, includeMeanings)
    return c.json(results)
  } catch (error: any) {
    console.error('Error in GET /search:', error)
    return c.json({ error: 'Failed to search expressions', details: error.message }, 500)
  }
})

miscRoutes.post('/meanings/merge', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const body = await c.req.json()
    const { source_meaning_id, target_meaning_id } = body

    if (!source_meaning_id || !target_meaning_id) {
      return c.json({ error: 'source_meaning_id and target_meaning_id are required' }, 400)
    }

    const sourceId = parseInt(source_meaning_id, 10)
    const targetId = parseInt(target_meaning_id, 10)

    if (isNaN(sourceId) || isNaN(targetId)) {
      return c.json({ error: 'Invalid meaning IDs' }, 400)
    }

    const result = await db.mergeMeaningGroups(sourceId, targetId)
    db.clearStatisticsCache()

    return c.json({
      success: true,
      message: '詞句組合併成功',
      ...result
    })
  } catch (error: any) {
    console.error('Error in POST /meanings/merge:', error)
    return c.json({ error: error.message || 'Failed to merge meaning groups' }, 500)
  }
})

miscRoutes.get('/ui-locale/:language_code', cacheMiddleware(3600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const language_code = c.req.param('language_code')

    const uiLocale = await db.getUILocale(language_code)

    if (!uiLocale) {
      return c.json({ error: 'Locale not found' }, 404)
    }

    const localeJson = JSON.parse(uiLocale.locale_json)

    return c.json({
      ...uiLocale,
      locale_json: localeJson
    })
  } catch (error: any) {
    console.error('Error in GET /ui-locale/:language_code:', error)
    return c.json({ error: 'Failed to fetch UI locale' }, 500)
  }
})

miscRoutes.post('/ui-locale/:language_code', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const language_code = c.req.param('language_code')
    const user = c.get('user')
    const body = await c.req.json()
    const { locale_json } = body

    if (!locale_json || typeof locale_json !== 'object') {
      return c.json({ error: 'Invalid locale_json format' }, 400)
    }

    const savedLocale = await db.saveUILocale(language_code, JSON.stringify(locale_json), user.username)

    try {
      const cache = (caches as any).default
      if (cache) {
        const cacheUrl = new URL(`/api/v1/ui-locale/${language_code}`, c.req.url)
        const cacheKey = new Request(cacheUrl.toString())
        await cache.delete(cacheKey)
        console.log(`[L2 Cache] Cleared cache for ${language_code}`)
      }
    } catch (e) {
      console.warn('[L2 Cache] Failed to clear cache:', e)
    }

    const localeJsonParsed = JSON.parse(savedLocale.locale_json)

    return c.json({
      success: true,
      data: {
        ...savedLocale,
        locale_json: localeJsonParsed
      }
    })
  } catch (error: any) {
    console.error('Error in POST /ui-locale/:language_code:', error)
    return c.json({ error: 'Failed to save UI locale', details: error.message }, 500)
  }
})

miscRoutes.delete('/ui-locale/:language_code', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const language_code = c.req.param('language_code')

    const success = await db.deleteUILocale(language_code)

    if (!success) {
      return c.json({ error: 'Locale not found' }, 404)
    }

    try {
      const cache = (caches as any).default
      if (cache) {
        const cacheUrl = new URL(`/api/v1/ui-locale/${language_code}`, c.req.url)
        const cacheKey = new Request(cacheUrl.toString())
        await cache.delete(cacheKey)
        console.log(`[L2 Cache] Cleared cache for ${language_code}`)
      }
    } catch (e) {
      console.warn('[L2 Cache] Failed to clear cache:', e)
    }

    return c.json({
      success: true,
      message: 'Locale deleted successfully'
    })
  } catch (error: any) {
    console.error('Error in DELETE /ui-locale/:language_code:', error)
    return c.json({ error: 'Failed to delete UI locale', details: error.message }, 500)
  }
})

export default miscRoutes
