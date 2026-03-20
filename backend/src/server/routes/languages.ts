import { Hono } from 'hono'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { cacheMiddleware, clearCache } from '../middleware/cache.js'
import { createLanguageSchema, updateLanguageSchema } from '../schemas/language.js'
import { success, created, badRequest, notFound, internalError } from '../utils/response.js'

const languagesRoutes = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>()

languagesRoutes.get('/:code/stats', cacheMiddleware(600), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const code = c.req.param('code')
    const stats = await db.languages.getLanguageStats(code)
    if (!stats) {
      return success(c, { expression_count: 0 })
    }
    return success(c, stats)
  } catch (error: any) {
    console.error('Error in GET /languages/:code/stats:', error)
    return internalError(c, 'Failed to fetch language stats')
  }
})

languagesRoutes.get('/', cacheMiddleware(1800), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const isActive = c.req.query('is_active')
    const isActiveValue = isActive !== undefined ? parseInt(isActive, 10) : undefined
    const languages = await db.getLanguages(isActiveValue)
    return success(c, languages)
  } catch (error: any) {
    console.error('Error in GET /languages:', error)
    return internalError(c, 'Failed to fetch languages')
  }
})

languagesRoutes.post('/', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const body = await c.req.json()

    const languageData = {
      ...body,
      created_by: body.created_by || user.username
    }

    const validated = createLanguageSchema.parse(languageData)
    const language = await db.createLanguage(validated)

    db.clearLanguagesCache()
    await clearCache(c, '/api/v1/languages')

    return created(c, language)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', error.message, error.errors)
    }
    console.error('Error in POST /languages:', error)
    return internalError(c, 'Failed to create language', error.message)
  }
})

languagesRoutes.put('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()

    if (isNaN(id)) {
      return badRequest(c, 'Invalid language ID')
    }

    const languageData = {
      ...body,
      updated_by: body.updated_by || user.username
    }

    const validated = updateLanguageSchema.parse(languageData)
    const language = await db.updateLanguage(id, validated)

    if (!language) {
      return notFound(c, 'Language')
    }

    db.clearLanguagesCache()
    await clearCache(c, `/api/v1/languages/${language.code}/stats`)

    return success(c, language)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', error.message, error.errors)
    }
    console.error('Error in PUT /languages/:id:', error)
    return internalError(c, 'Failed to update language', error.message)
  }
})

languagesRoutes.delete('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'))

    if (isNaN(id)) {
      return badRequest(c, 'Invalid language ID')
    }

    const languages = await db.getLanguages()
    const language = languages.find(l => l.id === id)
    if (!language) {
      return notFound(c, 'Language')
    }

    const success = await db.deleteLanguage(id)
    if (!success) {
      return notFound(c, 'Language')
    }

    db.clearLanguagesCache()
    await clearCache(c, '/api/v1/languages')
    if (language.code) {
      await clearCache(c, `/api/v1/languages/${language.code}/stats`)
    }

    return success(c, null, 'Language deleted successfully')
  } catch (error: any) {
    console.error('Error in DELETE /languages/:id:', error)
    return internalError(c, 'Failed to delete language', error.message)
  }
})

export default languagesRoutes
