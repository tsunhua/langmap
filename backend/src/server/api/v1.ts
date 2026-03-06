// Hono API routes implementing the same interface as FastAPI backend
import { Hono, Context, Next } from 'hono'
import { createDatabaseService } from '../db'
import { D1Database, DurableObjectNamespace, R2Bucket } from '@cloudflare/workers-types'
import * as jose from 'jose'
import bcrypt from 'bcryptjs'
import { Resend } from 'resend'

// Define types for our application context
interface JWTPayload {
  id: number
  username: string
  email: string
  role: string
}

// Define types for our environment bindings
interface Bindings {
  DB: D1Database;
  RESEND_API_KEY: string;
  SECRET_KEY: string;
  EXPORT_DO: DurableObjectNamespace;
  EXPORT_BUCKET: R2Bucket;
  AUDIO_BUCKET: R2Bucket;
  R2_ACCOUNT_ID: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
}

// Create a new Hono app for API v1 routes
const api = new Hono<{
  Bindings: Bindings,
  Variables: {
    user: JWTPayload
  }
}>()

// Helper function to get database service
const getDB = (c: any) => createDatabaseService(c.env)

// JWT helper functions
// SECRET_KEY will be accessed from context inside functions

async function signJWT(payload: jose.JWTPayload, secretKey: string): Promise<string> {
  const secret = new TextEncoder().encode(secretKey)
  const alg = 'HS256'

  const jwt = await new jose.SignJWT(payload)
    .setProtectedHeader({ alg })
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(secret)

  return jwt
}

async function verifyJWT(token: string, secretKey: string): Promise<any> {
  try {
    const secret = new TextEncoder().encode(secretKey)
    const { payload } = await jose.jwtVerify(token, secret)
    return payload
  } catch (error) {
    return null
  }
}

// Authentication middleware
async function requireAuth(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Authentication required' }, 401)
  }

  const token = authHeader.substring(7) // Remove 'Bearer ' prefix
  const payload = await verifyJWT(token, c.env.SECRET_KEY)

  if (!payload) {
    return c.json({ error: 'Invalid or expired token' }, 401)
  }

  // Add user info to context
  c.set('user', payload)
  await next()
}

// Admin authentication middleware
async function requireAdmin(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Authentication required' }, 401)
  }

  const token = authHeader.substring(7) // Remove 'Bearer ' prefix
  const payload = await verifyJWT(token, c.env.SECRET_KEY)

  if (!payload) {
    return c.json({ error: 'Invalid or expired token' }, 401)
  }

  // Check if user is admin
  if (payload.role !== 'admin') {
    return c.json({ error: 'Admin access required' }, 403)
  }

  // Add user info to context
  c.set('user', payload)
  await next()
}

/**
 * Workers Cache API Middleware
 * Caches GET requests at the Cloudflare Edge level.
 * @param maxAge TTL in seconds
 */
const cacheMiddleware = (maxAge: number = 3600) => {
  return async (c: Context, next: Next) => {
    // Only cache GET requests and skip caching if not in production/remote dev or if explicit bypass is requested
    if (c.req.method !== 'GET' || c.req.header('Cache-Control') === 'no-cache') {
      return await next()
    }

    const url = new URL(c.req.url)
    // Create a cache key from the request. 
    // We clone the request to ensure we don't consume the body (though GETs don't have bodies)
    const cacheKey = new Request(url.toString(), c.req.raw)
    const cache = (caches as any).default

    try {
      const cachedResponse = await cache.match(cacheKey)
      if (cachedResponse) {
        console.log(`[L2 Cache] Hit: ${url.pathname}${url.search}`);
        return cachedResponse
      }
    } catch (e) {
      console.warn('[L2 Cache] Match error (likely local dev without --remote):', e)
    }

    await next()

    // Cache the response if successful and has content
    if (c.res && c.res.status === 200 && cache) {
      try {
        // Clone the response to avoid consuming the original body stream
        const responseToCache = c.res.clone()
        // Override Cache-Control for the stored version
        responseToCache.headers.set('Cache-Control', `public, max-age=${maxAge}`)

        // Use waitUntil to ensure the cache operation completes after response is sent
        c.executionCtx.waitUntil(cache.put(cacheKey, responseToCache))
        console.log(`[L2 Cache] Miss/Put: ${url.pathname}${url.search}`);
      } catch (e) {
        console.error('[L2 Cache] Put error:', e)
      }
    }
  }
}

// Optional authentication middleware - populates user context if token is present but doesn't block if missing
async function optionalAuth(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization')
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7)
    const payload = await verifyJWT(token, c.env.SECRET_KEY)
    if (payload) {
      c.set('user', payload)
    }
  }
  await next()
}

// GET /api/v1/heatmap
api.get('/heatmap', cacheMiddleware(600), async (c) => {
  try {
    const db = getDB(c)
    const heatmapData = await db.getHeatmapData()
    return c.json({ data: heatmapData })
  } catch (error: any) {
    console.error('Error in GET /heatmap:', error);
    return c.json({ error: 'Failed to fetch heatmap data' }, 500)
  }
})

// GET /api/v1/statistics
api.get('/statistics', cacheMiddleware(3600), async (c) => {
  try {
    const db = getDB(c)
    const statistics = await db.getStatistics()
    return c.json(statistics)
  } catch (error: any) {
    console.error('Error in GET /statistics:', error);
    return c.json({ error: 'Failed to fetch statistics' }, 500)
  }
})

// GET /api/v1/languages
api.get('/languages', cacheMiddleware(1800), async (c) => {
  try {
    console.log('GET /api/v1/languages');
    const db = getDB(c)
    const isActive = c.req.query('is_active')
    const isActiveValue = isActive !== undefined ? parseInt(isActive, 10) : undefined
    const languages = await db.getLanguages(isActiveValue)
    return c.json(languages)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch languages' }, 500)
  }
})

// POST /api/v1/languages
api.post('/languages', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    console.log('Creating language with body:', body);

    // Get user info from middleware
    const user = c.get('user');
    const createdBy = user.username;

    // Add created_by to the language data
    const languageData = {
      ...body,
      created_by: body.created_by || createdBy
    };

    const language = await db.createLanguage(languageData)

    // Clear statistics cache as we've added a new language
    db.clearStatisticsCache();

    return c.json(language, 201)
  } catch (error: any) {
    console.error('Error in POST /languages:', error);
    return c.json({ error: 'Failed to create language', details: error.message }, 500)
  }
})

// PUT /api/v1/languages/:id
api.put('/languages/:id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()

    if (isNaN(id)) {
      return c.json({ error: 'Invalid language ID' }, 400)
    }

    // Get user info from middleware
    const user = c.get('user');
    const updatedBy = user.username;

    // Add updated_by to the language data
    const languageData = {
      ...body,
      updated_by: body.updated_by || updatedBy
    };

    const language = await db.updateLanguage(id, languageData)
    if (!language) {
      return c.json({ error: 'Language not found' }, 404)
    }

    // Clear statistics cache as we've updated a language
    db.clearStatisticsCache();

    return c.json(language)
  } catch (error: any) {
    console.error('Error in PUT /languages/:id:', error);
    return c.json({ error: 'Failed to update language', details: error.message }, 500)
  }
})

// DELETE /api/v1/languages/:id
api.delete('/languages/:id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))

    if (isNaN(id)) {
      return c.json({ error: 'Invalid language ID' }, 400)
    }

    const success = await db.deleteLanguage(id)
    if (!success) {
      return c.json({ error: 'Language not found' }, 404)
    }

    // Clear statistics cache as we've deleted a language
    db.clearStatisticsCache();

    return c.json({ message: 'Language deleted successfully' })
  } catch (error: any) {
    console.error('Error in DELETE /languages/:id:', error);
    return c.json({ error: 'Failed to delete language', details: error.message }, 500)
  }
})

// GET /api/v1/expressions
api.get('/expressions', cacheMiddleware(300), async (c) => {
  try {
    console.log('GET /api/v1/expressions');
    const db = getDB(c)
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    const language = c.req.query('language') || undefined
    const meaningIdParam = c.req.query('meaning_id');
    let meaningId: number | number[] | undefined;
    if (meaningIdParam) {
      if (meaningIdParam.includes(',')) {
        meaningId = meaningIdParam.split(',').map(id => parseInt(id.trim(), 10)).filter(id => !isNaN(id));
      } else {
        meaningId = parseInt(meaningIdParam, 10);
      }
    }
    const tagPrefix = c.req.query('tag') || undefined
    const excludeTagPrefix = c.req.query('exclude_tag') || undefined
    const includeMeanings = c.req.query('include_meanings') === 'true'
    const expressions = await db.getExpressions(skip, limit, language, meaningId, tagPrefix, excludeTagPrefix, includeMeanings)
    return c.json(expressions)
  } catch (error: any) {
    console.error('Error in GET /expressions:', error);
    return c.json({ error: 'Failed to fetch expressions' }, 500)
  }
})

// POST /api/v1/expressions
api.post('/expressions', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    console.log('Creating expression with body:', body);

    // Get user info from middleware
    const user = c.get('user');
    const createdBy = user.username;

    // Add created_by to the expression data
    const expressionData = {
      ...body,
      created_by: body.created_by || createdBy
    };

    const expression = await db.createExpression(expressionData)

    // Clear statistics cache as we've added a new expression
    db.clearStatisticsCache();

    return c.json(expression, 201)
  } catch (error: any) {
    console.error('Error in POST /expressions:', error);
    return c.json({ error: 'Failed to create expression', details: error.message }, 500)
  }
})

// en-GB: 英语（英国）
// en-US: 英语（美国）
// zh-TW: 繁体中文
// zh-CN: 简体中文
// hi-IN: 印地语
// es-ES: 西班牙语
// fr-FR: 法语
// ar-SA: 阿拉伯语
// bn-IN: 孟加拉语
// pt-BR: 巴西葡萄牙语
// ru-RU: 俄语
// ur-PK: 乌尔都语
// id-ID: 印度尼西亚语
// de-DE: 德语
// ja-JP: 日语
// ko-KR: 韩语
// tr-TR: 土耳其语
// it-IT: 意大利语
const LANGUAGE_PRIORITY = [
  'en-GB', 'en-US', 'zh-TW', 'zh-CN',
  'hi-IN', 'es-ES', 'fr-FR', 'ar-SA',
  'bn-IN', 'pt-BR', 'ru-RU', 'ur-PK',
  'id-ID', 'de-DE', 'ja-JP', 'ko-KR',
  'tr-TR', 'it-IT'
];

// POST /api/v1/expressions/batch
api.post('/expressions/batch', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    const { expressions } = body

    if (!expressions || !Array.isArray(expressions)) {
      return c.json({ error: 'Invalid expressions format' }, 400)
    }

    // Get user info from middleware
    const user = c.get('user');
    const username = user.username;

    // 1. Calculate IDs for all input expressions
    const exprsWithIds = expressions.map(expr => {
      if (!expr.text || !expr.language_code) {
        throw new Error('Text and language_code are required for all expressions');
      }
      return {
        ...expr,
        id: db.stableExpressionId(expr.text, expr.language_code),
        created_by: expr.created_by || username
      };
    });

    // 2. Batch lookup existing expressions to find current meaning_id associations
    const existingIds = exprsWithIds.map(e => e.id);
    const existingExprs = await db.getExpressionsByIds(existingIds);
    const existingMap = new Map(existingExprs.map(e => [e.id, e]));

    // 3. Pre-sorting by language priority
    const sortedExprs = [...exprsWithIds].sort((a, b) => {
      const indexA = LANGUAGE_PRIORITY.indexOf(a.language_code);
      const indexB = LANGUAGE_PRIORITY.indexOf(b.language_code);

      const priorityA = indexA === -1 ? 999 : indexA;
      const priorityB = indexB === -1 ? 999 : indexB;

      return priorityA - priorityB;
    });

    // 4. Smart Anchor Selection
    let finalMeaningId: number | undefined;

    // Get existing meaning associations
    const existingMeaningIds = await db.getExpressionMeaningIds(exprsWithIds.map(e => e.id!))

    // First pass: try to find an existing meaning association in sorted order
    for (const expr of sortedExprs) {
      const existingMeanings = existingMeaningIds.get(expr.id!)
      if (existingMeanings && existingMeanings.length > 0) {
        finalMeaningId = existingMeanings[0];
        break;
      }
    }

    // Second pass: fallback to the first sorted expression ID if:
    // - No existing association found, AND
    // - There are multiple expressions (only create meaning for multi-expression groups)
    if (!finalMeaningId && sortedExprs.length > 1) {
      finalMeaningId = sortedExprs[0].id;
    }

    // 5. Batch UPSERT (without meaning_id field)
    const results = await db.upsertExpressions(exprsWithIds);

    return c.json({
      success: true,
      meaning_id: finalMeaningId,
      results
    }, 201);

  } catch (error: any) {
    console.error('Error in POST /expressions/batch:', error);
    return c.json({ error: 'Failed to process batch submission', details: error.message }, 500)
  }
})

// POST /api/v1/expressions/associate
// 智能语义锚点关联 - 自动选择最合适的语义锚点
api.post('/expressions/associate', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    const { expression_ids } = body

    if (!expression_ids || !Array.isArray(expression_ids) || expression_ids.length < 2) {
      return c.json({ error: 'At least 2 expression IDs are required' }, 400)
    }

    const user = c.get('user');
    const username = user.username;

    // 使用智能语义锚点选择
    const meaningId = await db.selectSemanticAnchor(expression_ids);

    if (!meaningId) {
      return c.json({ error: 'Failed to select semantic anchor' }, 500)
    }

    // Create expression_meaning associations
    const now = new Date().toISOString()
    const statements = expression_ids.map(id =>
      (db as any).db.prepare(
        'INSERT OR REPLACE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
      ).bind(`${id}-${meaningId}`, id, meaningId, now)
    );

    await (db as any).db.batch(statements);

    // Clear cache
    db.clearStatisticsCache();
    db.clearHeatmapCache();

    return c.json({
      success: true,
      meaning_id: meaningId,
      updated_count: expression_ids.length
    });

  } catch (error: any) {
    console.error('Error in POST /expressions/associate:', error);
    return c.json({ error: 'Failed to associate expressions', details: error.message }, 500)
  }
})

// GET /api/v1/expressions/:expr_id
api.get('/expressions/:expr_id', cacheMiddleware(300), async (c) => {
  try {
    console.log('GET /api/v1/expressions/:expr_id');
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      console.warn('Invalid expression ID:', c.req.param('expr_id'));
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      console.warn('Expression not found:', exprId);
      return c.json({ error: 'Expression not found' }, 404)
    }

    return c.json(expression)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id:', error);
    return c.json({ error: 'Failed to fetch expression' }, 500)
  }
})

// PATCH /api/v1/expressions/:expr_id
api.patch('/expressions/:expr_id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    const body = await c.req.json()

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    // Check if expression exists first
    const existing = await db.getExpressionById(exprId)
    if (!existing) {
      console.warn('Expression not found for PATCH:', exprId);
      return c.json({ error: 'Expression not found' }, 404)
    }

    // Get user info from middleware
    const user = c.get('user');
    const updatedBy = user.username;

    // Add updated_by to expression data
    const expressionData = {
      ...body,
      updated_by: body.updated_by || updatedBy
    };

    // If text is being changed, use migration logic
    // Otherwise, use simple update
    if (body.text || body.language_code) {
      const expression = await db.migrateExpressionId(exprId, expressionData)
      if (!expression) {
        return c.json({ error: 'Expression not found' }, 404)
      }
      return c.json(expression)
    } else {
      // Simple update (e.g., meaning_id only)
      const expression = await db.updateExpression(exprId, expressionData)
      if (!expression) {
        return c.json({ error: 'Expression not found' }, 404)
      }
      return c.json(expression)
    }
  } catch (error: any) {
    console.error('Error in PATCH /expressions/:expr_id:', error);
    return c.json({ error: 'Failed to update expression', details: error.message }, 500)
  }
})

// DELETE /api/v1/expressions/:expr_id
api.delete('/expressions/:expr_id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const user = c.get('user')
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    // Get the expression to check ownership
    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }

    // Check if user is the creator or an admin
    if (user.role !== 'admin' && expression.created_by !== user.username) {
      return c.json({ error: 'You do not have permission to delete this expression' }, 403)
    }

    const success = await db.deleteExpression(exprId)
    if (!success) {
      return c.json({ error: 'Expression not found' }, 404)
    }

    // Clear statistics cache as we've deleted an expression
    db.clearStatisticsCache();

    // Tell browser to clear its cache for this site to reflect deletion
    c.header('Clear-Site-Data', '"cache"')

    return c.json({ message: 'Expression deleted successfully' })
  } catch (error: any) {
    console.error('Error in DELETE /expressions/:expr_id:', error);
    return c.json({ error: 'Failed to delete expression', details: error.message }, 500)
  }
})

// GET /api/v1/expressions/:expr_id/versions
api.get('/expressions/:expr_id/versions', async (c) => {
  try {
    console.log('GET /api/v1/expressions/:expr_id/versions');
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      console.warn('Invalid expression ID:', c.req.param('expr_id'));
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    const versions = await db.getExpressionVersions(exprId)
    return c.json(versions)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id/versions:', error);
    return c.json({ error: 'Failed to fetch expression versions' }, 500)
  }
})

// GET /api/v1/expressions/:expr_id/translations
api.get('/expressions/:expr_id/translations', async (c) => {
  try {
    console.log('GET /api/v1/expressions/:expr_id/translations');
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    const language_code = c.req.query('language_code')

    if (isNaN(exprId)) {
      console.warn('Invalid expression ID:', c.req.param('expr_id'));
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    // Get the expression first
    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      console.warn('Expression not found:', exprId);
      return c.json({ error: 'Expression not found' }, 404)
    }

    // Find expressions in other languages with the same meaning
    // This is a simplified implementation - in reality, this would involve
    // finding expressions linked to the same meaning(s)
    const meaning_id = expression.meaning_id ? expression.meaning_id : exprId
    const translations = await db.getExpressions(0, 1000, language_code, meaning_id)
      .then(allExpressions =>
        allExpressions.filter(e =>
          e.id !== exprId
        )
      )
    // 從 translations 中獲取一個 meaning_id 數組，要求不重複，並且不等於 meaning_id，且不为undefined
    const meaning_ids = translations.map(e => e.meaning_id).filter((id): id is number => id !== undefined && id !== null && typeof id === 'number').filter((id, index, self) => self.indexOf(id) === index && id !== meaning_id)

    // 如果meaning_ids 非空，那麼需要再次 getExpressions
    if (meaning_ids.length > 0) {
      const translations2 = await db.getExpressions(0, 1000, language_code, meaning_ids)
        .then(allExpressions =>
          allExpressions.filter(e =>
            e.id !== exprId
          )
        )
      // 合併translations2 到 translations 中
      translations.push(...translations2)
    }

    return c.json(translations)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id/translations:', error);
    return c.json({ error: 'Failed to fetch expression translations' }, 500)
  }
})

// POST /api/v1/expressions/:expr_id/meanings
api.post('/expressions/:expr_id/meanings', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    const body = await c.req.json()

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    if (!body.meaning_id) {
      return c.json({ error: 'meaning_id is required' }, 400)
    }

    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }

    const user = c.get('user')
    const username = user.username

    await db.addExpressionMeaning(exprId, body.meaning_id, username)

    return c.json({
      success: true,
      message: 'Meaning added to expression successfully'
    })
  } catch (error: any) {
    console.error('Error in POST /expressions/:expr_id/meanings:', error)
    return c.json({ error: 'Failed to add meaning to expression', details: error.message }, 500)
  }
})

// DELETE /api/v1/expressions/:expr_id/meanings/:meaning_id
api.delete('/expressions/:expr_id/meanings/:meaning_id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    const meaningId = parseInt(c.req.param('meaning_id'))

    if (isNaN(exprId) || isNaN(meaningId)) {
      return c.json({ error: 'Invalid expression ID or meaning ID' }, 400)
    }

    const success = await db.removeExpressionMeaning(exprId, meaningId)
    if (!success) {
      return c.json({ error: 'Expression-meaning relationship not found' }, 404)
    }

    return c.json({
      success: true,
      message: 'Meaning removed from expression successfully'
    })
  } catch (error: any) {
    console.error('Error in DELETE /expressions/:expr_id/meanings/:meaning_id:', error)
    return c.json({ error: 'Failed to remove meaning from expression', details: error.message }, 500)
  }
})

// POST /api/v1/expressions/:expr_id/upload-audio
api.post('/expressions/:expr_id/upload-audio', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))

    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }

    // Verify expression exists and user is owner/admin
    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }

    // Parse multipart/form-data
    const body = await c.req.parseBody()
    const file = body['audio_file']

    if (!file || !(file instanceof File)) {
      return c.json({ error: 'Invalid parameters: audio_file missing or invalid' }, 400)
    }

    // Ensure audio size doesn't exceed 1MB (1048576 bytes)
    if (file.size > 1048576) {
      return c.json({ error: 'Audio file too large. Max size is 1MB.' }, 400)
    }

    const bucketParams = c.env.AUDIO_BUCKET
    if (!bucketParams) {
      console.error('Server missing AUDIO_BUCKET binding')
      return c.json({ error: 'Storage configuration error' }, 500)
    }

    const uuid = crypto.randomUUID()

    // Extrapolate extension from mime content_type
    const extension = file.type === 'audio/mp4' ? 'mp4' : 'webm'
    const objectKey = `expressions/${exprId}/${uuid}.${extension}`

    // Upload via native Binding
    await c.env.AUDIO_BUCKET.put(objectKey, await file.arrayBuffer(), {
      httpMetadata: {
        contentType: file.type
      }
    })

    // CDN URL logic: Use domain prefix + bucket logic.
    const isDev = c.req.url.includes('localhost') || c.req.url.includes('127.0.0.1')
    const cdnUrl = isDev ? `http://localhost:8787/audio-assets/${objectKey}` : `https://audio.langmap.io/${objectKey}`

    // Parse existing audio records
    let audioRecords: Array<{ url: string; speaker: string }> = []
    if (expression.audio_url) {
      try {
        const parsed = JSON.parse(expression.audio_url)
        if (Array.isArray(parsed)) {
          audioRecords = parsed
        } else if (typeof expression.audio_url === 'string' && expression.audio_url.startsWith('http')) {
          // Backward compatibility: Convert legacy single URL string to array
          audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
        }
      } catch (e) {
        // Fallback for unparseable legacy strings
        if (typeof expression.audio_url === 'string' && expression.audio_url.startsWith('http')) {
          audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
        }
      }
    }

    // Enforce 1 record per user rule by removing existing record by this user if any
    const username = c.get('user')?.username || 'Unknown'
    audioRecords = audioRecords.filter(record => record.speaker !== username)

    // Append new record
    audioRecords.push({ url: cdnUrl, speaker: username })

    // Update DB directly
    await db.updateExpression(exprId, {
      audio_url: JSON.stringify(audioRecords),
      updated_by: username,
      updated_at: new Date().toISOString()
    })

    return c.json({
      audio_url: JSON.stringify(audioRecords)
    })

  } catch (error: any) {
    console.error('Error in POST /expressions/:expr_id/upload-audio:', error);
    return c.json({ error: 'Failed to upload audio file' }, 500)
  }
})

// DELETE /api/v1/expressions/:expr_id/audio
api.delete('/expressions/:expr_id/audio', requireAuth, async (c) => {
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

    // The frontend passes the speaker name it wants to delete via query string
    const targetSpeaker = c.req.query('speaker')
    if (!targetSpeaker) {
      return c.json({ error: 'Speaker parameter is required' }, 400)
    }

    // Permission check
    // Only the owner of the audio, an admin, or a super_admin can delete it
    if (
      currentUser.username !== targetSpeaker &&
      currentUser.role !== 'admin' &&
      currentUser.role !== 'super_admin'
    ) {
      return c.json({ error: 'Insufficient permissions to delete this audio' }, 403)
    }

    const db = getDB(c)
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
        // Legacy fallback
        audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
      }
    } catch (e) {
      // Legacy fallback
      audioRecords = [{ url: expression.audio_url, speaker: expression.created_by || 'Unknown' }]
    }

    // Find the record to get its URL and delete the corresponding file from R2
    const targetRecord = audioRecords.find(record => record.speaker === targetSpeaker)
    if (targetRecord && c.env.AUDIO_BUCKET) {
      try {
        const urlObj = new URL(targetRecord.url)
        // Extract object key from pathname.
        // Dev: /audio-assets/expressions/123/... -> expressions/123/...
        // Prod: /expressions/123/... -> expressions/123/...
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

    // Filter out the target speaker
    const updatedRecords = audioRecords.filter(record => record.speaker !== targetSpeaker)

    // D1 driver requires null, not undefined
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
    console.error('Error in DELETE /expressions/:expr_id/audio:', error);
    return c.json({ error: 'Failed to delete audio' }, 500)
  }
})

// GET /api/v1/search
api.get('/search', cacheMiddleware(3600), async (c) => {
  try {
    console.log('GET /api/v1/search');
    const db = getDB(c)
    const query = c.req.query('q') || ''
    const fromLang = c.req.query('from_lang') || undefined
    const region = c.req.query('region') || undefined
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    const includeMeanings = c.req.query('include_meanings') === 'true'

    if (!query) {
      console.warn('Query parameter is required');
      return c.json({ error: 'Query parameter is required' }, 400)
    }

    const results = await db.searchExpressions(query, fromLang, region, skip, limit, includeMeanings)
    return c.json(results)
  } catch (error: any) {
    console.error('Error in GET /search:', error);
    return c.json({ error: 'Failed to search expressions', details: error.message }, 500)
  }
})


// GET /api/v1/ui-translations/:language
api.get('/ui-translations/:language', cacheMiddleware(3600), async (c) => {
  try {
    console.log('GET /api/v1/ui-translations/:language');
    const db = getDB(c)
    const language = c.req.param('language')
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '1000')

    const translations = await db.getUITranslations(language, skip, limit)
    return c.json(translations)
  } catch (error: any) {
    console.error('Error in GET /ui-translations/:language:', error);
    return c.json({ error: 'Failed to fetch UI translations' }, 500)
  }
})

// POST /api/v1/ui-translations/:language
api.post('/ui-translations/:language', requireAuth, async (c) => {
  try {
    console.log('POST /api/v1/ui-translations/:language');
    const db = getDB(c)
    const language = c.req.param('language')
    const body = await c.req.json()
    const { translations } = body

    if (!translations || !Array.isArray(translations)) {
      return c.json({ error: 'Invalid translations format' }, 400)
    }

    // Get user info from middleware
    const user = c.get('user');
    const username = user.username;

    // Use bulk save method for better performance
    const results = await db.saveUITranslations(language, translations, username);

    // Clear statistics cache as we've updated expressions
    db.clearStatisticsCache();

    return c.json({
      success: true,
      message: `Processed ${translations.length} translations`,
      results
    })
  } catch (error: any) {
    console.error('Error in POST /ui-translations/:language:', error);
    return c.json({ error: 'Failed to save UI translations' }, 500)
  }
})

// POST /api/v1/sync-locales
// Sync local JSON locales to database (admin only)
api.post('/sync-locales', requireAdmin, async (c) => {
  try {
    console.log('POST /api/v1/sync-locales');
    const db = getDB(c)
    const body = await c.req.json()
    const { localeData } = body

    if (!localeData || typeof localeData !== 'object') {
      return c.json({ error: 'Invalid localeData format' }, 400)
    }

    // Get user info from middleware
    const user = c.get('user');
    const username = user.username;

    // Sync locales to database
    const results = await db.syncLocalesToDatabase(localeData, username);

    // Clear statistics cache
    db.clearStatisticsCache();

    return c.json({
      success: true,
      results
    })
  } catch (error: any) {
    console.error('Error in POST /sync-locales:', error);
    return c.json({ error: 'Failed to sync locales', details: error.message }, 500)
  }
})

// User Authentication Routes

// POST /api/v1/auth/register
api.post('/auth/register', async (c) => {
  try {
    console.log('POST /api/v1/auth/register');
    const db = getDB(c)
    const body = await c.req.json()
    const { username, email, password } = body

    // Validate input
    if (!username || !email || !password) {
      console.warn('Missing required fields:', { username, email, password });
      return c.json({ error: 'Username, email, and password are required' }, 400)
    }

    // Check if user already exists
    const existingUser = await db.getUserByUsername(username)
    if (existingUser) {
      console.warn('Username already exists:', username);
      return c.json({ error: 'Username already exists' }, 409)
    }

    const existingEmail = await db.getUserByEmail(email)
    if (existingEmail) {
      console.warn('Email already registered:', email);
      return c.json({ error: 'Email already registered' }, 409)
    }

    // Hash password
    const saltRounds = 10
    const password_hash = await bcrypt.hash(password, saltRounds)

    // Create user with email_verified set to false initially
    const user = await db.createUser({
      username,
      email,
      password_hash,
      role: 'user', // Default role
      email_verified: 0
    })

    // Generate email verification token
    const token = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString(); // 1 hour from now

    await db.createEmailVerificationToken(token, user.id, expiresAt);

    // Send verification email
    const resend = new Resend(c.env.RESEND_API_KEY);
    // Use a more robust way to construct the verification URL
    const baseUrl = c.req.url.split('/api')[0];
    const verificationUrl = `${baseUrl}/#/verify-email?token=${token}`;

    try {
      console.log('Sending verification email to:', email);
      const { data, error } = await resend.emails.send({
        from: 'no-reply@langmap.io',
        to: email,
        subject: 'Verify your email address',
        html: `
          <p>Hello ${username},</p>
          <p>Thank you for registering with LangMap! To ensure your account security, please click the button below to verify your email address.</p>
          <p><a href="${verificationUrl}" style="background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Verify Email</a></p>
          <p>If you cannot click the button, please copy the following link and open it in your browser:</p>
          <p>${verificationUrl}</p>
          <p><strong>Note:</strong> This verification link will expire in 1 hour. Please verify your email as soon as possible.</p>
          <p>If you didn't register for a LangMap account, please ignore this email.</p>
          <p>&copy; 2025 LangMap. All rights reserved.</p>
        `
      });

      if (error) {
        console.error('Failed to send verification email:', error);
        console.error('Error details:', {
          name: error.name,
          message: error.message,
          statusCode: error.statusCode
        });
      } else {
        console.log('Verification email sent successfully:', {
          id: data?.id,
          to: data?.to,
          subject: data?.subject
        });
      }
    } catch (emailError: any) {
      console.error('Error sending verification email:', emailError);
      console.error('Error details:', {
        name: emailError?.name,
        message: emailError?.message,
        stack: emailError?.stack
      });
    }

    // Remove password_hash from response
    const { password_hash: _, ...userResponse } = user

    return c.json({
      success: true,
      data: {
        user: userResponse
      },
      message: 'User registered successfully. Please check your email for verification.'
    }, 201)
  } catch (error: any) {
    console.error('Registration error:', error)
    return c.json({ error: 'Failed to register user' }, 500)
  }
})

// POST /api/v1/auth/login
api.post('/auth/login', async (c) => {
  try {
    console.log('POST /api/v1/auth/login');
    const db = getDB(c)
    const body = await c.req.json()
    const { email, password } = body

    // Validate input
    if (!email || !password) {
      console.warn('Missing email or password');
      return c.json({ error: 'Email and password are required' }, 400)
    }

    // Find user by email
    const user = await db.getUserByEmail(email)
    if (!user) {
      console.warn('User not found:', email);
      return c.json({ error: 'Invalid credentials' }, 401)
    }

    // Check if email is verified (email_verified == 1 means verified)
    if (user.email_verified !== 1) {
      console.warn('Email not verified:', email);
      return c.json({ error: 'Please verify your email before logging in' }, 401)
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash)
    if (!isValidPassword) {
      console.warn('Invalid password for user:', email);
      return c.json({ error: 'Invalid credentials' }, 401)
    }

    // Generate JWT token
    const token = await signJWT({
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role
    }, c.env.SECRET_KEY)

    // Remove password_hash from response
    const { password_hash: _, ...userResponse } = user

    return c.json({
      success: true,
      data: {
        token,
        user: userResponse
      }
    })
  } catch (error: any) {
    console.error('Login error:', error)
    return c.json({ error: 'Failed to login' }, 500)
  }
})

// POST /api/v1/auth/logout
api.post('/auth/logout', async (c) => {
  try {
    console.log('POST /api/v1/auth/logout');
    // With JWT, logout is typically handled client-side by deleting the token
    // Server-side, we could implement a token blacklist, but for simplicity
    // we'll just return a success response
    return c.json({
      success: true,
      message: 'Logged out successfully'
    })
  } catch (error: any) {
    console.error('Logout error:', error)
    return c.json({ error: 'Failed to logout' }, 500)
  }
})

// GET /api/v1/auth/verify-email
api.get('/auth/verify-email', async (c) => {
  try {
    console.log('GET /api/v1/auth/verify-email');
    const db = getDB(c);
    const token = c.req.query('token');

    // Validate input
    if (!token) {
      console.warn('Missing verification token');
      return c.json({ error: 'Verification token is required' }, 400);
    }

    // Find token in database
    const verificationToken = await db.getEmailVerificationToken(token);
    if (!verificationToken) {
      console.warn('Invalid verification token:', token);
      return c.json({ error: 'Invalid or expired verification token' }, 400);
    }

    // Check if token is expired
    const now = new Date();
    const expiresAt = new Date(verificationToken.expires_at);
    if (now > expiresAt) {
      console.warn('Expired verification token:', token);
      await db.deleteEmailVerificationToken(token);
      return c.json({ error: 'Verification token has expired' }, 400);
    }

    // Set user email as verified
    await db.setEmailVerified(verificationToken.user_id);

    // Delete the token so it can't be used again
    await db.deleteEmailVerificationToken(token);

    console.log('Email verified successfully for user:', verificationToken.user_id);

    return c.json({
      success: true,
      message: 'Email verified successfully. You can now log in.'
    });
  } catch (error: any) {
    console.error('Email verification error:', error);
    return c.json({ error: 'Failed to verify email' }, 500);
  }
});

// GET /api/v1/users/me
api.get('/users/me', requireAuth, async (c) => {
  try {
    console.log('GET /api/v1/users/me');
    // Get user info from middleware
    const user = c.get('user');

    const db = getDB(c)
    const fullUser = await db.getUserById(user.id)

    if (!fullUser) {
      console.warn('User not found:', user.id);
      return c.json({ error: 'User not found' }, 404)
    }

    // Remove password_hash from response
    const { password_hash: _, ...userResponse } = fullUser

    return c.json({
      success: true,
      data: userResponse
    })
  } catch (error: any) {
    console.error('Get user error:', error)
    return c.json({ error: 'Failed to get user' }, 500)
  }
})



// Export Routes

// POST /api/v1/export
api.post('/export', requireAuth, async (c) => {
  try {
    const body = await c.req.json()
    const { collectionId, format } = body;

    if (!collectionId) {
      return c.json({ error: "collectionId is required" }, 400);
    }

    // Validate format
    const startFormat = format === 'csv' ? 'csv' : 'json';

    const jobId = `exp_${Date.now()}_${crypto.randomUUID()}`;
    const id = c.env.EXPORT_DO.idFromName(jobId);
    const stub = c.env.EXPORT_DO.get(id);

    await stub.fetch("https://do/start", {
      method: "POST",
      body: JSON.stringify({
        jobId,
        collectionId: collectionId.toString(), // ensure string
        format: startFormat
      }),
    });

    return c.json({ jobId, status: "pending" });
  } catch (err: any) {
    console.error("Export start error:", err);
    return c.json({ error: "Failed to start export" }, 500);
  }
})

// GET /api/v1/export/health
api.get('/export/health', async (c) => {
  try {
    const jobId = "health_check";
    const id = c.env.EXPORT_DO.idFromName(jobId);
    const stub = c.env.EXPORT_DO.get(id);
    const res = await stub.fetch("https://do/health");
    const text = await res.text();
    return c.json({ status: res.status, message: text });
  } catch (err: any) {
    return c.json({ error: "Health check failed: " + err.message }, 500);
  }
})

// GET /api/v1/export/:jobId
api.get('/export/:jobId', requireAuth, async (c) => {
  try {
    const jobId = c.req.param('jobId');
    if (!jobId) return c.json({ error: "Job ID required" }, 400);

    const id = c.env.EXPORT_DO.idFromName(jobId);
    const stub = c.env.EXPORT_DO.get(id);

    const res = await stub.fetch("https://do/status");

    if (!res.ok) {
      const errorText = await res.text();
      console.error("DO Error Status:", res.status, errorText);
      if (res.status === 404) {
        return c.json({ error: "Job not found" }, 404);
      }
      return c.json({ error: `Export job error: ${res.status} ${errorText}` }, 500);
    }

    // Safety check for empty body
    const text = await res.text();
    if (!text) {
      console.error("DO returned empty response");
      return c.json({ error: "Empty response from export job" }, 500);
    }

    try {
      const data = JSON.parse(text);
      return c.json(data);
    } catch (e) {
      console.error("Failed to parse DO response:", text);
      return c.json({ error: "Invalid response from export job" }, 500);
    }
  } catch (err: any) {
    console.error("Export status error:", err);
    return c.json({ error: "Failed to check status" }, 500);
  }
})

// GET /api/v1/download
api.get('/download', async (c) => {
  try {
    const key = c.req.query('key');
    if (!key) {
      return c.json({ error: "File key required" }, 400);
    }

    // Security check: ensure key implies it's in exports folder
    if (!key.startsWith('exports/')) {
      return c.json({ error: "Invalid file key" }, 403);
    }

    const object = await c.env.EXPORT_BUCKET.get(key);

    if (object === null) {
      return c.json({ error: "File not found" }, 404);
    }

    const headers = new Headers();
    object.writeHttpMetadata(headers as any);
    headers.set('etag', object.httpEtag);
    headers.set("Content-Disposition", `attachment; filename="${key.split('/').pop()}"`);

    return new Response(object.body as any, {
      headers,
    });
  } catch (err: any) {
    console.error("Download error:", err);
    return c.json({ error: "Failed to download file" }, 500);
  }
})

// Collections API Routes

// GET /api/v1/collections
api.get('/collections', optionalAuth, async (c) => {
  try {
    const db = getDB(c)
    const user = c.get('user') // Optional, from optional auth or session

    const userIdParam = c.req.query('user_id')
    let userId: number | undefined = userIdParam ? parseInt(userIdParam) : undefined

    const isPublicParam = c.req.query('is_public')
    const isPublic = isPublicParam === '1' ? true : (isPublicParam === '0' ? false : undefined)

    // If no specific userId is requested, and user is logged in, and we're not explicitly asking for all public collections
    if (userId === undefined && user && isPublic !== true) {
      userId = user.id
    }

    // Security check: if trying to see private collections, must be the owner
    if (isPublic === false && (!user || userId !== user.id)) {
      return c.json({ error: 'Access denied to private collections' }, 403)
    }

    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')

    const collections = await db.getCollections(userId, isPublic, skip, limit)
    return c.json(collections)
  } catch (error: any) {
    console.error('Error in GET /collections:', error)
    return c.json({ error: 'Failed to fetch collections' }, 500)
  }
})

// POST /api/v1/collections
api.post('/collections', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const user = c.get('user')
    const body = await c.req.json()

    if (!body.name) {
      return c.json({ error: 'Name is required' }, 400)
    }

    const collection = await db.createCollection({
      user_id: user.id,
      name: body.name,
      description: body.description,
      is_public: body.is_public
    })

    return c.json(collection, 201)
  } catch (error: any) {
    console.error('Error in POST /collections:', error)
    return c.json({ error: 'Failed to create collection' }, 500)
  }
})

// Get collections containing an item
api.get('/collections/check-item', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const user = c.get('user')
    const expressionId = parseInt(c.req.query('expression_id') || '0')

    if (!expressionId) {
      return c.json({ error: 'Expression ID is required' }, 400)
    }

    const collectionIds = await db.getCollectionsContainingItem(user.id, expressionId)
    return c.json(collectionIds)
  } catch (error) {
    console.error('Error in GET /collections/check-item:', error)
    return c.json({ error: 'Failed to check collections' }, 500)
  }
})

// GET /api/v1/collections/:id
api.get('/collections/:id', optionalAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)

    const collection = await db.getCollectionById(id)

    if (!collection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    // Check visibility
    if (!collection.is_public) {
      const user = c.get('user')
      if (!user || collection.user_id !== user.id) {
        return c.json({ error: 'Access denied' }, 403)
      }
    }

    return c.json(collection)
  } catch (error: any) {
    console.error('Error in GET /collections/:id:', error)
    return c.json({ error: 'Failed to fetch collection' }, 500)
  }
})

// PUT /api/v1/collections/:id
api.put('/collections/:id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const user = c.get('user')
    const body = await c.req.json()

    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)

    const existing = await db.getCollectionById(id)
    if (!existing) return c.json({ error: 'Collection not found' }, 404)

    if (existing.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }

    const updated = await db.updateCollection(id, body)
    return c.json(updated)
  } catch (error: any) {
    console.error('Error in PUT /collections/:id:', error)
    return c.json({ error: 'Failed to update collection' }, 500)
  }
})

// DELETE /api/v1/collections/:id
api.delete('/collections/:id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const user = c.get('user')

    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)

    const existing = await db.getCollectionById(id)
    if (!existing) return c.json({ error: 'Collection not found' }, 404)

    if (existing.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }

    await db.deleteCollection(id)
    return c.json({ message: 'Collection deleted' })
  } catch (error: any) {
    console.error('Error in DELETE /collections/:id:', error)
    return c.json({ error: 'Failed to delete collection' }, 500)
  }
})

// GET /api/v1/collections/:id/items
api.get('/collections/:id/items', optionalAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')

    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)

    const collection = await db.getCollectionById(id)
    if (!collection) return c.json({ error: 'Collection not found' }, 404)

    // Check visibility
    if (!collection.is_public) {
      const user = c.get('user')
      if (!user || collection.user_id !== user.id) {
        return c.json({ error: 'Access denied' }, 403)
      }
    }

    const items = await db.getCollectionItems(id, skip, limit)

    // We might want to fetch full expression details here or just return items
    // For now, let's fetch expression details for each item
    // Note: Use Promise.all for parallel fetching. Optimization: Add getExpressionsByIds(ids)
    const detailedItems = await Promise.all(items.map(async (item) => {
      const expression = await db.getExpressionById(item.expression_id)
      return {
        ...item,
        expression
      }
    }));

    return c.json(detailedItems)
  } catch (error: any) {
    console.error('Error in GET /collections/:id/items:', error)
    return c.json({ error: 'Failed to fetch collection items' }, 500)
  }
})

// POST /api/v1/collections/:id/items
api.post('/collections/:id/items', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const user = c.get('user')
    const body = await c.req.json()

    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)
    if (!body.expression_id) return c.json({ error: 'expression_id is required' }, 400)

    const collection = await db.getCollectionById(id)
    if (!collection) return c.json({ error: 'Collection not found' }, 404)

    if (collection.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }

    const item = await db.addCollectionItem({
      collection_id: id,
      expression_id: body.expression_id,
      note: body.note
    })

    return c.json(item, 201)
  } catch (error: any) {
    console.error('Error in POST /collections/:id/items:', error)
    return c.json({ error: 'Failed to add item to collection' }, 500)
  }
})

// DELETE /api/v1/collections/:id/items/:expressionId
api.delete('/collections/:id/items/:expressionId', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const expressionId = parseInt(c.req.param('expressionId'))
    const user = c.get('user')

    if (isNaN(id) || isNaN(expressionId)) return c.json({ error: 'Invalid ID' }, 400)

    const collection = await db.getCollectionById(id)
    if (!collection) return c.json({ error: 'Collection not found' }, 404)

    if (collection.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }

    await db.removeCollectionItem(id, expressionId)
    return c.json({ message: 'Item removed from collection' })
  } catch (error: any) {
    console.error('Error in DELETE /collections/:id/items/:expressionId:', error)
    return c.json({ error: 'Failed to remove item from collection' }, 500)
  }
})

// Handbook Routes
// GET /api/v1/handbooks
api.get('/handbooks', cacheMiddleware(300), optionalAuth, async (c) => {
  try {
    const db = getDB(c)
    const user = c.get('user')
    const isPublicParam = c.req.query('is_public')
    const isPublic = isPublicParam !== undefined ? isPublicParam === '1' : undefined
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')

    // If user_id is not specified, use the authenticated user's ID
    // If requesting public handbooks, don't filter by user
    let userId: number | undefined
    if (isPublic) {
      userId = undefined
    } else if (user) {
      userId = user.id
    }

    const handbooks = await db.getHandbooks(userId, isPublic, skip, limit)
    return c.json(handbooks)
  } catch (error: any) {
    console.error('Error in GET /api/v1/handbooks:', error)
    return c.json({ error: 'Failed to fetch handbooks' }, 500)
  }
})

import MarkdownIt from 'markdown-it'

// Helper for handbook rendering
async function renderHandbookInternal(c: Context, handbook: any, targetLang: string) {
  const md = new MarkdownIt({ html: true })
  const db = getDB(c)

  const content = handbook.content || ''
  const title = handbook.title || ''
  const description = handbook.description || ''

  const TEXT_LANG_REGEX = /\{\{text:([^|{}]+)(?:\|lang:([^}]+))?\}\}/g

  // 1. Extract all expression tags
  const expressionsToFetch: { text: string, lang: string, id: number }[] = []
  const fullText = `${title}\n${description}\n${content}`

  TEXT_LANG_REGEX.lastIndex = 0
  let tlMatch
  while ((tlMatch = TEXT_LANG_REGEX.exec(fullText)) !== null) {
    const text = tlMatch[1]
    const lang = tlMatch[2] || handbook.source_lang || 'en'
    const id = db.stableExpressionId(text, lang)
    if (!expressionsToFetch.some(e => e.id === id)) {
      expressionsToFetch.push({ text, lang, id })
    }
  }

  const expressionMap: Record<string, any> = {}
  if (expressionsToFetch.length > 0) {
    const ids = expressionsToFetch.map(e => e.id)
    const expressions = await db.getExpressionsByIds(ids)

    // Explicitly fetch meaning IDs for these expressions
    const meaningIdsMap = await db.getExpressionMeaningIds(ids)

    const allMids: number[] = []
    expressions.forEach(expr => {
      expressionMap[expr.id] = expr
      const mids = meaningIdsMap.get(expr.id) || []
      expr.meanings = mids.map(mid => ({ id: mid })) as any[] // Mock meanings objects
      mids.forEach(mid => {
        if (!allMids.includes(mid)) allMids.push(mid)
      })
    })

    if (allMids.length > 0 && targetLang) {
      // Use the newly optimized batch fetching
      const translations: any[] = await db.getExpressions(0, 1000, targetLang, allMids, undefined, undefined, true)
      translations.forEach((trans: any) => {
        if (trans.meaning_id) {
          expressionMap[`trans_${trans.meaning_id}`] = trans
        } else if (trans.meanings) {
          trans.meanings.forEach((m: any) => {
            if (allMids.includes(m.id)) {
              expressionMap[`trans_${m.id}`] = trans
            }
          })
        }
      })
    }
  }

  // 3. Render helpers
  const renderItem = (id: number, text: string, transList: any[], audioUrl: string) => {
    const meaningsText = transList.length > 0
      ? ` <span class="text-gray-400 font-normal text-xs">[${transList.map(m => m.text).join(', ')}]</span>`
      : ''
    const audioIcon = audioUrl ? ` <span class="text-[10px]">🔊</span>` : ''

    // Return as single line to avoid breaking Markdown headings/blocks
    return `<span class="handbook-item inline-flex items-center gap-1 px-1.5 py-0.5 bg-blue-50 text-blue-600 border border-blue-200 rounded text-sm font-bold cursor-pointer hover:bg-blue-100" onclick="event.stopPropagation(); window.navigateToExpression(${id}); ${audioUrl ? `window.playHandbookAudio('${audioUrl}')` : ''}">${text}${meaningsText}${audioIcon}</span>`
  }

  const renderTextWithTags = (text: string) => {
    if (!text) return ''
    TEXT_LANG_REGEX.lastIndex = 0
    return text.replace(TEXT_LANG_REGEX, (match, term, langMatch) => {
      const lang = langMatch || handbook.source_lang || 'en'
      const id = db.stableExpressionId(term, lang)
      const expr = expressionMap[id]
      if (expr) {
        const translations: any[] = []
        expr.meanings?.forEach((m: any) => {
          if (expressionMap[`trans_${m.id}`]) {
            translations.push(expressionMap[`trans_${m.id}`])
          }
        })
        let audioUrl = ''
        if (expr.audio_url) {
          try {
            const parsed = JSON.parse(expr.audio_url)
            audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || '') : ''
          } catch { }
        }
        return renderItem(id, term, translations, audioUrl)
      }
      return `<span class="text-gray-400 border-b border-dotted border-gray-300">${term}</span>`
    })
  }

  // 4. Perform rendering
  const rendered_title = renderTextWithTags(title)
  const rendered_description = renderTextWithTags(description)

  // Replace tags in content BEFORE markdown rendering to ensure <h2> and other blocks correctly wrap the result
  const preProcessedContent = renderTextWithTags(content)
  const rendered_content = md.render(preProcessedContent)

  return { rendered_title, rendered_description, rendered_content }
}

// GET /api/v1/handbooks/:id/:target_lang?
api.get('/handbooks/:id/:target_lang?', cacheMiddleware(300), optionalAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const user = c.get('user')
    const targetLang = c.req.param('target_lang') || c.req.query('target_lang')

    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)

    const handbook = await db.getHandbookById(id)
    if (!handbook) return c.json({ error: 'Handbook not found' }, 404)

    // Check visibility
    if (!handbook.is_public && (!user || user.id !== handbook.user_id)) {
      return c.json({ error: 'Access denied' }, 403)
    }

    const effectiveTargetLang = targetLang || handbook.target_lang || ''

    // Check Render Cache (only if targetLang is provided or fixed)
    if (effectiveTargetLang) {
      const cachedRender = await db.getHandbookRender(id, effectiveTargetLang)
      if (cachedRender) {
        return c.json({
          ...handbook,
          rendered_title: cachedRender.rendered_title,
          rendered_description: cachedRender.rendered_description,
          rendered_content: cachedRender.rendered_content,
          is_cached: true
        })
      }

      // Not in cache, render it
      try {
        const renders = await renderHandbookInternal(c, handbook, effectiveTargetLang)
        await db.saveHandbookRender({
          handbook_id: id,
          target_lang: effectiveTargetLang,
          ...renders
        })
        return c.json({
          ...handbook,
          ...renders,
          is_cached: false
        })
      } catch (renderError) {
        console.error('Render error:', renderError)
        // Fallback to raw if rendering fails
        return c.json(handbook)
      }
    }

    return c.json(handbook)
  } catch (error: any) {
    console.error('Error in GET /api/v1/handbooks/:id:', error)
    return c.json({ error: 'Failed to fetch handbook' }, 500)
  }
})

// POST /api/v1/handbooks
api.post('/handbooks', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const user = c.get('user')
    const body = await c.req.json()

    if (!body.title || !body.content) {
      return c.json({ error: 'Title and content are required' }, 400)
    }

    const handbook = await db.createHandbook({
      ...body,
      user_id: user.id
    })

    return c.json(handbook, 201)
  } catch (error: any) {
    console.error('Error in POST /api/v1/handbooks:', error)
    return c.json({ error: 'Failed to create handbook' }, 500)
  }
})

// PUT /api/v1/handbooks/:id
api.put('/handbooks/:id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const user = c.get('user')
    const body = await c.req.json()

    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)

    const existing = await db.getHandbookById(id)
    if (!existing) return c.json({ error: 'Handbook not found' }, 404)

    if (existing.user_id !== user.id) {
      return c.json({ error: 'Access denied' }, 403)
    }

    const updated = await db.updateHandbook(id, body)
    return c.json(updated)
  } catch (error: any) {
    console.error('Error in PUT /api/v1/handbooks/:id:', error)
    return c.json({ error: 'Failed to update handbook' }, 500)
  }
})

// DELETE /api/v1/handbooks/:id
api.delete('/handbooks/:id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const id = parseInt(c.req.param('id'))
    const user = c.get('user')

    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400)

    const existing = await db.getHandbookById(id)
    if (!existing) return c.json({ error: 'Handbook not found' }, 404)

    if (existing.user_id !== user.id && user.role !== 'admin') {
      return c.json({ error: 'Access denied' }, 403)
    }

    const success = await db.deleteHandbook(id)
    return c.json({ success })
  } catch (error: any) {
    console.error('Error in DELETE /api/v1/handbooks/:id:', error)
    return c.json({ error: 'Failed to delete handbook' }, 500)
  }
})

export default api
