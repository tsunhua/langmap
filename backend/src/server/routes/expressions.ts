import { Hono } from 'hono'
import { ExpressionService } from '../services/expression.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import { cacheMiddleware, clearCache } from '../middleware/cache.js'
import { createExpressionSchema, updateExpressionSchema, batchExpressionSchema, ensureExpressionsSchema, expressionsQuerySchema } from '../schemas/expression.js'
import { success, created, badRequest, notFound, forbidden, internalError, paginated } from '../utils/response.js'

const expressionsRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

expressionsRoutes.get('/', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)

    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    const langParam = c.req.query('lang')
    const tagPrefix = c.req.query('tag') || undefined
    const excludeTagPrefix = c.req.query('exclude_tag') || undefined

    let languages: string[] | undefined
    if (langParam) {
      languages = langParam.split(',').map(l => l.trim())
    }

    const result = await service.getAll(skip, limit, {
      languages,
      tagPrefix,
      excludeTagPrefix,
      includeMeanings: false,
    })

    const total = result.length < limit ? skip + result.length : (result.length > 0 ? skip + result.length + 1 : skip)
    return paginated(c, result, total, skip, limit)
  } catch (error: any) {
    console.error('Error in GET /expressions:', error)
    return internalError(c, error.message || 'Failed to fetch expressions')
  }
})

expressionsRoutes.post('/', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const body = await c.req.json()

    const validated = createExpressionSchema.parse(body)
    const expression = await service.create(validated, user.username)
    await clearCache(c, '/api/v1/expressions')

    return created(c, expression)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Error in POST /expressions:', error)
    return internalError(c, error.message || 'Failed to create expression')
  }
})

expressionsRoutes.post('/ensure', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const body = await c.req.json()
    const validated = ensureExpressionsSchema.parse(body)

    const results = await db.ensureExpressionsExist(validated.expressions, user.username)
    return success(c, results)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      console.error('[POST /expressions/ensure] Validation error:', JSON.stringify(error.errors, null, 2))
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('[POST /expressions/ensure] Error:', error)
    console.error('[POST /expressions/ensure] Error stack:', error instanceof Error ? error.stack : 'No stack')
    return internalError(c, error.message || 'Failed to ensure expressions')
  }
})

const LANGUAGE_PRIORITY = [
  'en-GB', 'en-US', 'zh-TW', 'zh-CN',
  'hi-IN', 'es-ES', 'fr-FR', 'ar-SA',
  'bn-IN', 'pt-BR', 'ru-RU', 'ur-PK',
  'id-ID', 'de-DE', 'ja-JP', 'ko-KR',
  'tr-TR', 'it-IT'
]

expressionsRoutes.post('/batch', requireAuth, async (c) => {
  console.log('[POST /expressions/batch] START')
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const body = await c.req.json()

    console.log('[POST /expressions/batch] Body:', JSON.stringify(body, null, 2))
    console.log('[POST /expressions/batch] User:', user)

    console.log('[POST /expressions/batch] Parsing with schema...')
    let validated: any
    try {
      validated = batchExpressionSchema.parse(body)
    } catch (parseError: any) {
      console.error('[POST /expressions/batch] Parse error name:', parseError.name)
      console.error('[POST /expressions/batch] Parse error message:', parseError.message)
      console.error('[POST /expressions/batch] Parse error:', parseError)
      if (parseError.name === 'ZodError') {
        console.error('[POST /expressions/batch] ZodError errors:', JSON.stringify(parseError.errors, null, 2))
      }
      throw parseError
    }
    console.log('[POST /expressions/batch] Validated:', JSON.stringify(validated, null, 2))

    const { expressions, ensure_new_group } = validated
    const forceNewGroup = ensure_new_group === true

    console.log('[POST /expressions/batch] Creating exprsWithIds...')
    const exprsWithIds = expressions.map(expr => {
      console.log('[POST /expressions/batch] Processing expression:', expr)
      if (!expr.text || !expr.language_code) {
        throw new Error('Text and language_code are required for all expressions')
      }
      const stableId = db.stableExpressionId(expr.text, expr.language_code)
      console.log('[POST /expressions/batch] Stable ID:', stableId)
      return {
        ...expr,
        id: stableId,
        created_by: expr.created_by || user.username
      }
    })
    console.log('[POST /expressions/batch] exprsWithIds created:', exprsWithIds.length)

    const results = await db.upsertExpressions(exprsWithIds, forceNewGroup)

    const existingIds = exprsWithIds.map(e => e.id!)
    const existingMeaningIds = await db.getExpressionMeaningIds(existingIds)

    let finalMeaningId: number | undefined
    for (const expr of exprsWithIds) {
      const existingMeanings = existingMeaningIds.get(expr.id!)
      if (existingMeanings && existingMeanings.length > 0) {
        finalMeaningId = existingMeanings[0]
        console.log('[POST /expressions/batch] Found meaning_id from expression:', expr.id!, 'meaning_id:', finalMeaningId)
        break
      }
    }

    return created(c, { group_id: finalMeaningId, results })
  } catch (error: any) {
    console.error('[POST /expressions/batch] Caught error')
    console.error('[POST /expressions/batch] Error name:', error.name)
    console.error('[POST /expressions/batch] Error message:', error.message)
    console.error('[POST /expressions/batch] Error:', error)
    if (error instanceof Error) {
      console.error('[POST /expressions/batch] Error stack:', error.stack)
    }

    if (error.name === 'ZodError') {
      console.error('[POST /expressions/batch] Validation error:', JSON.stringify(error.errors, null, 2))
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    return internalError(c, error.message || 'Failed to process batch submission')
  }
})

expressionsRoutes.get('/:expr_id', cacheMiddleware(300), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const exprIdParam = c.req.param('expr_id')

    if (exprIdParam.includes(',')) {
      const ids = exprIdParam.split(',')
        .map(id => parseInt(id.trim(), 10))
        .filter(id => !isNaN(id))

      if (ids.length === 0) {
        return badRequest(c, 'Invalid expression IDs')
      }

      if (ids.length > 100) {
        return badRequest(c, 'Maximum 100 ids allowed per request')
      }

      const expressions = await service.getByIds(ids)
      const meaningIdsMap = await db.getExpressionMeaningIds(ids)

      expressions.forEach(expr => {
        const mids = meaningIdsMap.get(expr.id) || []
        ;(expr as any).groups = mids.map(mid => ({ id: mid }))
      })

      return success(c, expressions)
    }

    const exprId = parseInt(exprIdParam)
    if (isNaN(exprId)) {
      return badRequest(c, 'Invalid expression ID')
    }

    const expression = await service.getById(exprId)
    return success(c, expression)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id:', error)
    return internalError(c, error.message || 'Failed to fetch expression')
  }
})

/**
 * GET /api/v1/expressions/:id/groups
 * Get all groups that an expression belongs to
 */
expressionsRoutes.get('/:id/groups', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'), 10)

    if (isNaN(id)) {
      return badRequest(c, 'Invalid expression ID')
    }

    const langParam = c.req.query('lang')
    const languages = langParam ? langParam.split(',') : undefined

    const groups = await db.groups.getExpressionGroups(id, languages)

    return success(c, groups)
  } catch (error: any) {
    console.error('Error in GET /expressions/:id/groups:', error)
    return internalError(c, 'Failed to fetch expression groups')
  }
})

expressionsRoutes.patch('/:expr_id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const exprId = parseInt(c.req.param('expr_id'))
    const body = await c.req.json()

    if (isNaN(exprId)) {
      return badRequest(c, 'Invalid expression ID')
    }

    const expressionData = {
      ...body,
      updated_by: body.updated_by || user.username
    }

    if (body.text || body.language_code) {
      const expression = await db.migrateExpressionId(exprId, expressionData)
      if (!expression) {
        return notFound(c, 'Expression')
      }
      return success(c, expression)
    } else {
      const validated = updateExpressionSchema.parse(expressionData)
      const expression = await service.update(exprId, validated)
      return success(c, expression)
    }
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return badRequest(c, 'Validation failed', undefined, error.errors)
    }
    console.error('Error in PATCH /expressions/:expr_id:', error)
    return internalError(c, error.message || 'Failed to update expression')
  }
})

expressionsRoutes.delete('/:expr_id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return badRequest(c, 'Invalid expression ID')
    }

    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return notFound(c, 'Expression')
    }

    if (user.role !== 'admin' && expression.created_by !== user.username) {
      return forbidden(c, 'You do not have permission to delete this expression')
    }

    await service.delete(exprId)
    c.header('Clear-Site-Data', '"cache"')

    return success(c, null, 'Expression deleted successfully')
  } catch (error: any) {
    console.error('Error in DELETE /expressions/:expr_id:', error)
    return internalError(c, error.message || 'Failed to delete expression')
  }
})

expressionsRoutes.get('/:expr_id/versions', cacheMiddleware(300), async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return badRequest(c, 'Invalid expression ID')
    }

    const versions = await db.getExpressionVersions(exprId)
    return success(c, versions)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id/versions:', error)
    return internalError(c, 'Failed to fetch expression versions')
  }
})


expressionsRoutes.post('/:expr_id/upload-audio', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return badRequest(c, 'Invalid expression ID')
    }

    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return notFound(c, 'Expression')
    }

    const body = await c.req.parseBody()
    const file = body['audio_file']

    if (!file || !(file instanceof File)) {
      return badRequest(c, 'Invalid parameters: audio_file missing or invalid')
    }

    if (file.size > 1048576) {
      return badRequest(c, 'Audio file too large. Max size is 1MB.')
    }

    if (!c.env.AUDIO_BUCKET) {
      return internalError(c, 'Storage configuration error')
    }

    const uuid = crypto.randomUUID()
    const extension = file.type === 'audio/mp4' ? 'mp4' : 'webm'
    const objectKey = `expressions/${exprId}/${uuid}.${extension}`

    await c.env.AUDIO_BUCKET.put(objectKey, await file.arrayBuffer(), {
      httpMetadata: {
        contentType: file.type
      }
    })

    const isDev = c.req.url.includes('localhost') || c.req.url.includes('127.0.0.1')
    const cdnUrl = isDev ? `http://localhost:8787/audio-assets/${objectKey}` : `https://audio.langmap.io/${objectKey}`

    let audioRecords: Array<{ url: string; speaker: string }> = []
    if (expression.audio_url) {
      try {
        const parsed = JSON.parse(expression.audio_url)
        if (Array.isArray(parsed)) {
          audioRecords = parsed
        } else if (typeof expression.audio_url === 'string' && expression.audio_url.startsWith('http')) {
          audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
        }
      } catch (e) {
        if (typeof expression.audio_url === 'string' && expression.audio_url.startsWith('http')) {
          audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
        }
      }
    }

    const username = c.get('user')?.username || 'Unknown'
    audioRecords = audioRecords.filter(record => record.speaker !== username)
    audioRecords.push({ url: cdnUrl, speaker: username })

    await db.updateExpression(exprId, {
      audio_url: JSON.stringify(audioRecords),
      updated_by: username,
      updated_at: new Date().toISOString()
    })

    return success(c, { audio_url: JSON.stringify(audioRecords) })
  } catch (error: any) {
    console.error('Error in POST /expressions/:expr_id/upload-audio:', error)
    return internalError(c, 'Failed to upload audio file')
  }
})

expressionsRoutes.delete('/:expr_id/audio', requireAuth, async (c) => {
  try {
    const exprIdStr = c.req.param('expr_id')
    const exprId = parseInt(exprIdStr, 10)
    if (isNaN(exprId)) {
      return badRequest(c, 'Invalid expression ID format')
    }

    const currentUser = c.get('user')
    if (!currentUser) {
      return internalError(c, 'Unauthorized')
    }

    const targetSpeaker = c.req.query('speaker')
    if (!targetSpeaker) {
      return badRequest(c, 'Speaker parameter is required')
    }

    if (
      currentUser.username !== targetSpeaker &&
      currentUser.role !== 'admin' &&
      currentUser.role !== 'super_admin'
    ) {
      return forbidden(c, 'Insufficient permissions to delete this audio')
    }

    const db = createDatabaseService(c.env)
    const expression = await db.getExpressionById(exprId)

    if (!expression) {
      return notFound(c, 'Expression')
    }

    if (!expression.audio_url) {
      return badRequest(c, 'No audio exists for this expression')
    }

    let audioRecords: Array<{ url: string, speaker: string }> = []
    try {
      if (expression.audio_url.startsWith('[')) {
        audioRecords = JSON.parse(expression.audio_url)
      } else {
        audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
      }
    } catch (e) {
      audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
    }

    const targetRecord = audioRecords.find(record => record.speaker === targetSpeaker)
    if (targetRecord && c.env.AUDIO_BUCKET) {
      try {
        const urlObj = new URL(targetRecord.url)
        let objectKey = urlObj.pathname
        if (objectKey.startsWith('/audio-assets/')) {
          objectKey = objectKey.substring('/audio-assets/'.length)
        } else if (objectKey.startsWith('/')) {
          objectKey = objectKey.substring(1)
        }
        await c.env.AUDIO_BUCKET.delete(objectKey)
      } catch (err) {
        console.error('Failed to delete file from R2 bucket:', err)
      }
    }

    const updatedRecords = audioRecords.filter(record => record.speaker !== targetSpeaker)
    const newValue = updatedRecords.length > 0 ? JSON.stringify(updatedRecords) : null

    await db.updateExpression(exprId, {
      audio_url: newValue,
      updated_by: currentUser.username,
      updated_at: new Date().toISOString()
    })

    return success(c, { message: 'Audio deleted successfully', audio_url: newValue })
  } catch (error: any) {
    console.error('Error in DELETE /expressions/:expr_id/audio:', error)
    return internalError(c, 'Failed to delete audio')
  }
})

export default expressionsRoutes
