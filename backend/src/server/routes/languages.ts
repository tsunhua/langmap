import { Hono } from 'hono'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth } from '../middleware/auth.js'
import { cacheMiddleware, clearCache } from '../middleware/cache.js'
import { createLanguageSchema, updateLanguageSchema } from '../schemas/language.js'

const languagesRoutes = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>()

languagesRoutes.get('/', cacheMiddleware(1800), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const isActive = c.req.query('is_active')
    const isActiveValue = isActive !== undefined ? parseInt(isActive, 10) : undefined
    const languages = await db.getLanguages(isActiveValue)
    return c.json(languages)
  } catch (error: any) {
    console.error('Error in GET /languages:', error)
    return c.json({ error: 'Failed to fetch languages' }, 500)
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

    db.clearStatisticsCache()
    db.clearLanguagesCache()

    return c.json(language, 201)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Error in POST /languages:', error)
    return c.json({ error: 'Failed to create language', details: error.message }, 500)
  }
})

languagesRoutes.put('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()

    if (isNaN(id)) {
      return c.json({ error: 'Invalid language ID' }, 400)
    }

    const languageData = {
      ...body,
      updated_by: body.updated_by || user.username
    }

    const validated = updateLanguageSchema.parse(languageData)
    const language = await db.updateLanguage(id, validated)
    
    if (!language) {
      return c.json({ error: 'Language not found' }, 404)
    }

    db.clearStatisticsCache()
    db.clearLanguagesCache()

    return c.json(language)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Error in PUT /languages/:id:', error)
    return c.json({ error: 'Failed to update language', details: error.message }, 500)
  }
})

languagesRoutes.delete('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'))

    if (isNaN(id)) {
      return c.json({ error: 'Invalid language ID' }, 400)
    }

    const success = await db.deleteLanguage(id)
    if (!success) {
      return c.json({ error: 'Language not found' }, 404)
    }

    db.clearStatisticsCache()
    db.clearLanguagesCache()

    return c.json({ message: 'Language deleted successfully' })
  } catch (error: any) {
    console.error('Error in DELETE /languages/:id:', error)
    return c.json({ error: 'Failed to delete language', details: error.message }, 500)
  }
})

export default languagesRoutes
