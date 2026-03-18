import { Hono } from 'hono'
import { ExpressionService } from '../services/expression.js'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import { cacheMiddleware } from '../middleware/cache.js'
import { createExpressionSchema, updateExpressionSchema, batchExpressionSchema, ensureExpressionsSchema, addMeaningSchema, expressionsQuerySchema } from '../schemas/expression.js'

const expressionsRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

expressionsRoutes.get('/', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    const language = c.req.query('language') || undefined
    const meaningIdParam = c.req.query('meaning_id')
    let meaningId: number | number[] | undefined
    if (meaningIdParam) {
      if (meaningIdParam.includes(',')) {
        meaningId = meaningIdParam.split(',').map(id => parseInt(id.trim(), 10)).filter(id => !isNaN(id))
      } else {
        meaningId = parseInt(meaningIdParam, 10)
      }
    }
    const tagPrefix = c.req.query('tag') || undefined
    const excludeTagPrefix = c.req.query('exclude_tag') || undefined
    const includeMeanings = c.req.query('include_meanings') === 'true'

    const expressions = await service.getAll(skip, limit, {
      language,
      meaningId,
      tagPrefix,
      excludeTagPrefix,
      includeMeanings
    })

    return c.json(expressions)
  } catch (error: any) {
    console.error('Error in GET /expressions:', error)
    return c.json({ error: error.message || 'Failed to fetch expressions' }, error.statusCode || 500)
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
    
    return c.json(expression, 201)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Error in POST /expressions:', error)
    return c.json({ error: error.message || 'Failed to create expression' }, error.statusCode || 500)
  }
})

expressionsRoutes.post('/ensure', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const body = await c.req.json()
    const validated = ensureExpressionsSchema.parse(body)
    
    const results = await db.ensureExpressionsExist(validated.expressions, user.username)
    return c.json(results)
  } catch (error: any) {
    if (error.name === 'ZodError') {
      console.error('[POST /expressions/ensure] Validation error:', JSON.stringify(error.errors, null, 2))
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('[POST /expressions/ensure] Error:', error)
    console.error('[POST /expressions/ensure] Error stack:', error instanceof Error ? error.stack : 'No stack')
    return c.json({ error: error.message || 'Failed to ensure expressions' }, 500)
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

    const { expressions, ensure_new_meaning } = validated
    const forceNewMeaning = ensure_new_meaning === true

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

    const existingIds = exprsWithIds.map(e => e.id!)
    const existingExprs = await db.getExpressionsByIds(existingIds)
    const existingMap = new Map(existingExprs.map(e => [e.id, e]))

    const sortedExprs = [...exprsWithIds].sort((a, b) => {
      const indexA = LANGUAGE_PRIORITY.indexOf(a.language_code)
      const indexB = LANGUAGE_PRIORITY.indexOf(b.language_code)
      const priorityA = indexA === -1 ? 999 : indexA
      const priorityB = indexB === -1 ? 999 : indexB
      return priorityA - priorityB
    })

    let finalMeaningId: number | undefined
    const existingMeaningIds = await db.getExpressionMeaningIds(exprsWithIds.map(e => e.id!))

    for (const expr of sortedExprs) {
      const existingMeanings = existingMeaningIds.get(expr.id!)
      if (existingMeanings && existingMeanings.length > 0) {
        finalMeaningId = existingMeanings[0]
        break
      }
    }

    if (!finalMeaningId && sortedExprs.length > 1) {
      finalMeaningId = sortedExprs[0].id
    }

    const results = await db.upsertExpressions(exprsWithIds, forceNewMeaning)

    return c.json({
      success: true,
      meaning_id: finalMeaningId,
      results
    }, 201)
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
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    return c.json({ error: error.message || 'Failed to process batch submission' }, 500)
  }
})

expressionsRoutes.post('/associate', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const body = await c.req.json()

    const { expression_ids } = body
    if (!expression_ids || !Array.isArray(expression_ids) || expression_ids.length < 2) {
      return c.json({ error: 'At least 2 expression IDs are required' }, 400)
    }

    const meaningId = await db.selectSemanticAnchor(expression_ids)
    if (!meaningId) {
      return c.json({ error: 'Failed to select semantic anchor' }, 500)
    }

    const now = new Date().toISOString()
    const statements = expression_ids.map(id =>
      db.db.prepare(
        'INSERT OR REPLACE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${id}-${meaningId}`, id, meaningId, now)
    )

    await db.db.batch(statements)
    db.clearStatisticsCache()
    db.clearHeatmapCache()

    return c.json({
      success: true,
      meaning_id: meaningId,
      updated_count: expression_ids.length
    })
  } catch (error: any) {
    console.error('Error in POST /expressions/associate:', error)
    return c.json({ error: error.message || 'Failed to associate expressions' }, 500)
  }
})

expressionsRoutes.get('/:expr_id', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const exprIdParam = c.req.param('expr_id')

    if (exprIdParam.includes(',')) {
      const ids = exprIdParam.split(',')
        .map(id => parseInt(id.trim(), 10))
        .filter(id => !isNaN(id))

      if (ids.length === 0) {
        return c.json({ error: 'Invalid expression IDs' }, 400)
      }

      if (ids.length > 100) {
        return c.json({ error: 'Maximum 100 ids allowed per request' }, 400)
      }

      const expressions = await service.getByIds(ids)
      const meaningIdsMap = await db.getExpressionMeaningIds(ids)

      expressions.forEach(expr => {
        const mids = meaningIdsMap.get(expr.id) || []
        expr.meanings = mids.map(mid => ({ id: mid })) as any
      })

      return c.json(expressions)
    }

    const exprId = parseInt(exprIdParam)
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const expression = await service.getById(exprId)
    return c.json(expression)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id:', error)
    return c.json({ error: error.message || 'Failed to fetch expression' }, error.statusCode || 500)
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
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const expressionData = {
      ...body,
      updated_by: body.updated_by || user.username
    }

    if (body.text || body.language_code) {
      const expression = await db.migrateExpressionId(exprId, expressionData)
      if (!expression) {
        return c.json({ error: 'Expression not found' }, 404)
      }
      return c.json(expression)
    } else {
      const validated = updateExpressionSchema.parse(expressionData)
      const expression = await service.update(exprId, validated)
      return c.json(expression)
    }
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Error in PATCH /expressions/:expr_id:', error)
    return c.json({ error: error.message || 'Failed to update expression' }, error.statusCode || 500)
  }
})

expressionsRoutes.delete('/:expr_id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const user = c.get('user')
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }

    if (user.role !== 'admin' && expression.created_by !== user.username) {
      return c.json({ error: 'You do not have permission to delete this expression' }, 403)
    }

    await service.delete(exprId)
    c.header('Clear-Site-Data', '"cache"')

    return c.json({ message: 'Expression deleted successfully' })
  } catch (error: any) {
    console.error('Error in DELETE /expressions/:expr_id:', error)
    return c.json({ error: error.message || 'Failed to delete expression' }, error.statusCode || 500)
  }
})

expressionsRoutes.get('/:expr_id/versions', async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const versions = await db.getExpressionVersions(exprId)
    return c.json(versions)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id/versions:', error)
    return c.json({ error: 'Failed to fetch expression versions' }, 500)
  }
})

expressionsRoutes.post('/:expr_id/meanings', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const exprId = parseInt(c.req.param('expr_id'))
    const body = await c.req.json()
    const validated = addMeaningSchema.parse(body)

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const user = c.get('user')
    await service.addMeaning(exprId, validated.meaning_id, user.username)

    return c.json({
      success: true,
      message: 'Meaning added to expression successfully'
    })
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return c.json({ error: 'Validation failed', details: error.errors }, 400)
    }
    console.error('Error in POST /expressions/:expr_id/meanings:', error)
    return c.json({ error: 'Failed to add meaning to expression' }, 500)
  }
})

expressionsRoutes.delete('/:expr_id/meanings/:meaning_id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const service = new ExpressionService(db)
    const exprId = parseInt(c.req.param('expr_id'))
    const meaningId = parseInt(c.req.param('meaning_id'))

    if (isNaN(exprId) || isNaN(meaningId)) {
      return c.json({ error: 'Invalid expression ID or meaning ID' }, 400)
    }

    await service.removeMeaning(exprId, meaningId)

    return c.json({
      success: true,
      message: 'Meaning removed from expression successfully'
    })
  } catch (error: any) {
    console.error('Error in DELETE /expressions/:expr_id/meanings/:meaning_id:', error)
    return c.json({ error: 'Failed to remove meaning from expression' }, 500)
  }
})

expressionsRoutes.post('/:expr_id/upload-audio', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }

    const body = await c.req.parseBody()
    const file = body['audio_file']

    if (!file || !(file instanceof File)) {
      return c.json({ error: 'Invalid parameters: audio_file missing or invalid' }, 400)
    }

    if (file.size > 1048576) {
      return c.json({ error: 'Audio file too large. Max size is 1MB.' }, 400)
    }

    if (!c.env.AUDIO_BUCKET) {
      return c.json({ error: 'Storage configuration error' }, 500)
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

    return c.json({ audio_url: JSON.stringify(audioRecords) })
  } catch (error: any) {
    console.error('Error in POST /expressions/:expr_id/upload-audio:', error)
    return c.json({ error: 'Failed to upload audio file' }, 500)
  }
})

expressionsRoutes.delete('/:expr_id/audio', requireAuth, async (c) => {
  try {
    const exprIdStr = c.req.param('expr_id')
    const exprId = parseInt(exprIdStr, 10)
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID format' }, 400)
    }

    const currentUser = c.get('user')
    if (!currentUser) {
      return c.json({ error: 'Unauthorized' }, 401)
    }

    const targetSpeaker = c.req.query('speaker')
    if (!targetSpeaker) {
      return c.json({ error: 'Speaker parameter is required' }, 400)
    }

    if (
      currentUser.username !== targetSpeaker &&
      currentUser.role !== 'admin' &&
      currentUser.role !== 'super_admin'
    ) {
      return c.json({ error: 'Insufficient permissions to delete this audio' }, 403)
    }

    const db = createDatabaseService(c.env)
    const expression = await db.getExpressionById(exprId)

    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }

    if (!expression.audio_url) {
      return c.json({ error: 'No audio exists for this expression' }, 400)
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

    return c.json({
      message: 'Audio deleted successfully',
      audio_url: newValue
    })
  } catch (error: any) {
    console.error('Error in DELETE /expressions/:expr_id/audio:', error)
    return c.json({ error: 'Failed to delete audio' }, 500)
  }
})

export default expressionsRoutes
