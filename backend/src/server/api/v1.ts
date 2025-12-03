// Hono API routes implementing the same interface as FastAPI backend
import { Hono } from 'hono'
import { createDatabaseService } from '../db'

// Create a new Hono app for API v1 routes
const api = new Hono<{ Bindings: any }>()

// Helper function to get database service
const getDB = (c: any) => createDatabaseService(c.env)

// GET /api/v1/languages
api.get('/languages', async (c) => {
  try {
    const db = getDB(c)
    const languages = await db.getLanguages()
    return c.json(languages)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch languages' }, 500)
  }
})

// GET /api/v1/expressions
api.get('/expressions', async (c) => {
  try {
    const db = getDB(c)
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    const language = c.req.query('language') || undefined
    
    const expressions = await db.getExpressions(skip, limit, language)
    return c.json(expressions)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch expressions' }, 500)
  }
})

// POST /api/v1/expressions
api.post('/expressions', async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    
    const expression = await db.createExpression(body)
    return c.json(expression, 201)
  } catch (error: any) {
    return c.json({ error: 'Failed to create expression' }, 500)
  }
})

// GET /api/v1/expressions/:expr_id
api.get('/expressions/:expr_id', async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }
    
    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }
    
    return c.json(expression)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch expression' }, 500)
  }
})

// GET /api/v1/expressions/:expr_id/versions
api.get('/expressions/:expr_id/versions', async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }
    
    const versions = await db.getExpressionVersions(exprId)
    return c.json(versions)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch expression versions' }, 500)
  }
})

// GET /api/v1/expressions/:expr_id/translations
api.get('/expressions/:expr_id/translations', async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }
    
    // Get the expression first
    const expression = await db.getExpressionById(exprId)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }
    
    // Find expressions in other languages with the same meaning
    // This is a simplified implementation - in reality, this would involve
    // finding expressions linked to the same meaning(s)
    const translations = await db.getExpressions(0, 100, undefined)
      .then(allExpressions => 
        allExpressions.filter(e => 
          e.id !== exprId && 
          e.language_code !== expression.language_code
        )
      )
    
    return c.json(translations)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch expression translations' }, 500)
  }
})

// GET /api/v1/expressions/:expr_id/meanings
api.get('/expressions/:expr_id/meanings', async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }
    
    const meanings = await db.getExpressionMeanings(exprId)
    return c.json(meanings)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch expression meanings' }, 500)
  }
})

// GET /api/v1/search
api.get('/search', async (c) => {
  try {
    const db = getDB(c)
    const query = c.req.query('q') || ''
    const fromLang = c.req.query('from_lang') || undefined
    const region = c.req.query('region') || undefined
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    
    if (!query) {
      return c.json({ error: 'Query parameter is required' }, 400)
    }
    
    const results = await db.searchExpressions(query, fromLang, region, skip, limit)
    return c.json(results)
  } catch (error: any) {
    console.error('Error searching expressions:', error)
    return c.json({ error: 'Failed to search expressions' }, 500)
  }
})

// GET /api/v1/meanings
api.get('/meanings', async (c) => {
  try {
    const db = getDB(c)
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    
    const meanings = await db.getMeanings(skip, limit)
    return c.json(meanings)
  } catch (error: any) {
    console.error('Error fetching meanings:', error)
    return c.json({ error: 'Failed to fetch meanings' }, 500)
  }
})

// POST /api/v1/meanings
api.post('/meanings', async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    
    const meaning = await db.createMeaning(body)
    return c.json(meaning, 201)
  } catch (error: any) {
    return c.json({ error: 'Failed to create meaning' }, 500)
  }
})

// GET /api/v1/meanings/:mid
api.get('/meanings/:mid', async (c) => {
  try {
    const db = getDB(c)
    const mid = parseInt(c.req.param('mid'))
    
    if (isNaN(mid)) {
      return c.json({ error: 'Invalid meaning ID' }, 400)
    }
    
    const meaning = await db.getMeaningById(mid)
    if (!meaning) {
      return c.json({ error: 'Meaning not found' }, 404)
    }
    
    return c.json(meaning)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch meaning' }, 500)
  }
})

// GET /api/v1/meanings/:mid/members
api.get('/meanings/:mid/members', async (c) => {
  try {
    const db = getDB(c)
    const mid = parseInt(c.req.param('mid'))
    const limit = parseInt(c.req.query('limit') || '100')
    
    if (isNaN(mid)) {
      return c.json({ error: 'Invalid meaning ID' }, 400)
    }
    
    const members = await db.getMeaningMembers(mid, limit)
    return c.json(members)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch meaning members' }, 500)
  }
})

// POST /api/v1/meanings/:mid/link
api.post('/meanings/:mid/link', async (c) => {
  try {
    const db = getDB(c)
    const mid = parseInt(c.req.param('mid'))
    const body = await c.req.json()
    const { expressionId, note } = body
    
    if (isNaN(mid) || isNaN(expressionId)) {
      return c.json({ error: 'Invalid meaning or expression ID' }, 400)
    }
    
    const link = await db.linkExpressionAndMeaning(expressionId, mid, note)
    return c.json(link, 201)
  } catch (error: any) {
    return c.json({ error: 'Failed to link expression and meaning' }, 500)
  }
})

// GET /api/v1/ui-translations/:language
api.get('/ui-translations/:language', async (c) => {
  try {
    const db = getDB(c)
    const language = c.req.param('language')
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '100')
    
    const translations = await db.getUITranslations(language, skip, limit)
    return c.json(translations)
  } catch (error: any) {
    return c.json({ error: 'Failed to fetch UI translations' }, 500)
  }
})

// POST /api/v1/ai/suggest
api.post('/ai/suggest', async (c) => {
  try {
    // This is a mock implementation - in reality, this would call an AI service
    const body = await c.req.json()
    const { text, language } = body
    
    // Mock suggestions
    const suggestions = [
      { 
        text: `${text} (suggested variation 1)`,
        language,
        confidence: 0.8
      },
      {
        text: `${text} (suggested variation 2)`,
        language,
        confidence: 0.6
      }
    ]
    
    return c.json(suggestions)
  } catch (error: any) {
    return c.json({ error: 'Failed to get AI suggestions' }, 500)
  }
})

export default api