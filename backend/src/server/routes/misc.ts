import { Hono } from 'hono'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { cacheMiddleware, clearCache } from '../middleware/cache.js'
import { success, badRequest, notFound, internalError } from '../utils/response.js'

const miscRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

miscRoutes.get('/heatmap', cacheMiddleware(600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const heatmapData = await db.getHeatmapData()
    return success(c, heatmapData)
  } catch (error: any) {
    console.error('Error in GET /heatmap:', error)
    return internalError(c, 'Failed to fetch heatmap data')
  }
})

miscRoutes.get('/statistics', cacheMiddleware(3600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const statistics = await db.getStatistics()
    return success(c, statistics)
  } catch (error: any) {
    console.error('Error in GET /statistics:', error)
    return internalError(c, 'Failed to fetch statistics')
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
      return badRequest(c, 'Query parameter is required')
    }

    const results = await db.searchExpressions(query, fromLang, region, skip, limit, includeMeanings)
    return success(c, results)
  } catch (error: any) {
    console.error('Error in GET /search:', error)
    return internalError(c, 'Failed to search expressions', error.message)
  }
})

miscRoutes.post('/meanings/merge', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const body = await c.req.json()
    const { source_meaning_id, target_meaning_id } = body

    if (!source_meaning_id || !target_meaning_id) {
      return badRequest(c, 'source_meaning_id and target_meaning_id are required')
    }

    const sourceId = parseInt(source_meaning_id, 10)
    const targetId = parseInt(target_meaning_id, 10)

    if (isNaN(sourceId) || isNaN(targetId)) {
      return badRequest(c, 'Invalid meaning IDs')
    }

    const result = await db.mergeMeaningGroups(sourceId, targetId)
    db.clearStatisticsCache()

    return success(c, { ...result }, '詞句組合併成功')
  } catch (error: any) {
    console.error('Error in POST /meanings/merge:', error)
    return internalError(c, error.message || 'Failed to merge meaning groups')
  }
})

miscRoutes.get('/ui-locale/:language_code', cacheMiddleware(3600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const language_code = c.req.param('language_code')

    const uiLocale = await db.getUILocale(language_code)

    if (!uiLocale) {
      return notFound(c, 'Locale')
    }

    const localeJson = JSON.parse(uiLocale.locale_json)

    return success(c, { ...uiLocale, locale_json: localeJson })
  } catch (error: any) {
    console.error('Error in GET /ui-locale/:language_code:', error)
    return internalError(c, 'Failed to fetch UI locale')
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
      return badRequest(c, 'Invalid locale_json format')
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

    return success(c, { ...savedLocale, locale_json: localeJsonParsed })
  } catch (error: any) {
    console.error('Error in POST /ui-locale/:language_code:', error)
    return internalError(c, 'Failed to save UI locale', error.message)
  }
})

miscRoutes.delete('/ui-locale/:language_code', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const language_code = c.req.param('language_code')

    const success = await db.deleteUILocale(language_code)

    if (!success) {
      return notFound(c, 'Locale')
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

    return success(c, null, 'Locale deleted successfully')
  } catch (error: any) {
    console.error('Error in DELETE /ui-locale/:language_code:', error)
    return internalError(c, 'Failed to delete UI locale', error.message)
  }
})

export default miscRoutes
