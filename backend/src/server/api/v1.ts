// Hono API routes implementing the same interface as FastAPI backend
import { Hono } from 'hono'
import { createDatabaseService } from '../db'
import * as jose from 'jose'
import bcrypt from 'bcryptjs'

// Create a new Hono app for API v1 routes
const api = new Hono<{ Bindings: any }>()

// Helper function to get database service
const getDB = (c: any) => createDatabaseService(c.env)

// JWT helper functions
const SECRET_KEY = 'your-secret-key-change-in-production' // In production, use env variable

async function signJWT(payload: any): Promise<string> {
  const secret = new TextEncoder().encode(SECRET_KEY)
  const alg = 'HS256'
  
  const jwt = await new jose.SignJWT(payload)
    .setProtectedHeader({ alg })
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(secret)
    
  return jwt
}

async function verifyJWT(token: string): Promise<any> {
  try {
    const secret = new TextEncoder().encode(SECRET_KEY)
    const { payload } = await jose.jwtVerify(token, secret)
    return payload
  } catch (error) {
    return null
  }
}

// Authentication middleware
async function requireAuth(c: any, next: any) {
  const authHeader = c.req.header('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Authentication required' }, 401)
  }
  
  const token = authHeader.substring(7) // Remove 'Bearer ' prefix
  const payload = await verifyJWT(token)
  
  if (!payload) {
    return c.json({ error: 'Invalid or expired token' }, 401)
  }
  
  // Add user info to context
  c.set('user', payload)
  await next()
}

// GET /api/v1/languages
api.get('/languages', async (c) => {
  try {
    console.log('GET /api/v1/languages');
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
    console.log('GET /api/v1/expressions');
    const db = getDB(c)
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    const language = c.req.query('language') || undefined
    
    const expressions = await db.getExpressions(skip, limit, language)
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
    return c.json(expression, 201)
  } catch (error: any) {
    console.error('Error in POST /expressions:', error);
    return c.json({ error: 'Failed to create expression', details: error.message }, 500)
  }
})

// GET /api/v1/expressions/:expr_id
api.get('/expressions/:expr_id', async (c) => {
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
    const translations = await db.getExpressions(0, 100, undefined)
      .then(allExpressions => 
        allExpressions.filter(e => 
          e.id !== exprId && 
          e.language_code !== expression.language_code
        )
      )
    
    return c.json(translations)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id/translations:', error);
    return c.json({ error: 'Failed to fetch expression translations' }, 500)
  }
})

// GET /api/v1/expressions/:expr_id/meanings
api.get('/expressions/:expr_id/meanings', async (c) => {
  try {
    console.log('GET /api/v1/expressions/:expr_id/meanings');
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    
    if (isNaN(exprId)) {
      console.warn('Invalid expression ID:', c.req.param('expr_id'));
      return c.json({ error: 'Invalid expression ID' }, 400)
    }
    
    const meanings = await db.getExpressionMeanings(exprId)
    return c.json(meanings)
  } catch (error: any) {
    console.error('Error in GET /expressions/:expr_id/meanings:', error);
    return c.json({ error: 'Failed to fetch expression meanings' }, 500)
  }
})

// GET /api/v1/search
api.get('/search', async (c) => {
  try {
    console.log('GET /api/v1/search');
    const db = getDB(c)
    const query = c.req.query('q') || ''
    const fromLang = c.req.query('from_lang') || undefined
    const region = c.req.query('region') || undefined
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')
    
    if (!query) {
      console.warn('Query parameter is required');
      return c.json({ error: 'Query parameter is required' }, 400)
    }
    
    const results = await db.searchExpressions(query, fromLang, region, skip, limit)
    return c.json(results)
  } catch (error: any) {
    console.error('Error in GET /search:', error);
    return c.json({ error: 'Failed to search expressions' }, 500)
  }
})

// GET /api/v1/meanings
api.get('/meanings', async (c) => {
  try {
    console.log('GET /api/v1/meanings');
    const db = getDB(c)
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    
    const meanings = await db.getMeanings(skip, limit)
    return c.json(meanings)
  } catch (error: any) {
    console.error('Error in GET /meanings:', error);
    return c.json({ error: 'Failed to fetch meanings' }, 500)
  }
})

// POST /api/v1/meanings
api.post('/meanings', requireAuth, async (c) => {
  try {
    console.log('POST /api/v1/meanings');
    const db = getDB(c)
    const body = await c.req.json()
    console.log('Creating meaning with body:', body);
    
    // Get user info from middleware
    const user = c.get('user');
    const createdBy = user.username;
    
    // Add created_by to the meaning data
    const meaningData = {
      ...body,
      created_by: body.created_by || createdBy
    };
    
    const meaning = await db.createMeaning(meaningData)
    return c.json(meaning, 201)
  } catch (error: any) {
    console.error('Error in POST /meanings:', error);
    return c.json({ error: 'Failed to create meaning' }, 500)
  }
})

// GET /api/v1/meanings/:mid
api.get('/meanings/:mid', async (c) => {
  try {
    console.log('GET /api/v1/meanings/:mid');
    const db = getDB(c)
    const mid = parseInt(c.req.param('mid'))
    
    if (isNaN(mid)) {
      console.warn('Invalid meaning ID:', c.req.param('mid'));
      return c.json({ error: 'Invalid meaning ID' }, 400)
    }
    
    const meaning = await db.getMeaningById(mid)
    if (!meaning) {
      console.warn('Meaning not found:', mid);
      return c.json({ error: 'Meaning not found' }, 404)
    }
    
    return c.json(meaning)
  } catch (error: any) {
    console.error('Error in GET /meanings/:mid:', error);
    return c.json({ error: 'Failed to fetch meaning' }, 500)
  }
})

// GET /api/v1/meanings/:mid/members
api.get('/meanings/:mid/members', async (c) => {
  try {
    console.log('GET /api/v1/meanings/:mid/members');
    const db = getDB(c)
    const mid = parseInt(c.req.param('mid'))
    const limit = parseInt(c.req.query('limit') || '100')
    
    if (isNaN(mid)) {
      console.warn('Invalid meaning ID:', c.req.param('mid'));
      return c.json({ error: 'Invalid meaning ID' }, 400)
    }
    
    const members = await db.getMeaningMembers(mid, limit)
    return c.json(members)
  } catch (error: any) {
    console.error('Error in GET /meanings/:mid/members:', error);
    return c.json({ error: 'Failed to fetch meaning members' }, 500)
  }
})

// POST /api/v1/meanings/:mid/link
api.post('/meanings/:mid/link', requireAuth, async (c) => {
  try {
    console.log('POST /api/v1/meanings/:mid/link');
    const db = getDB(c)
    const mid = parseInt(c.req.param('mid'))
    const body = await c.req.json()
    const { expressionId, note } = body
    
    console.log('Linking expression', expressionId, 'to meaning', mid);
    
    if (isNaN(mid) || isNaN(expressionId)) {
      console.warn('Invalid meaning or expression ID:', { mid, expressionId });
      return c.json({ error: 'Invalid meaning or expression ID' }, 400)
    }
    
    // Get user info from middleware
    const user = c.get('user');
    const createdBy = user.username;
    
    const link = await db.linkExpressionAndMeaning(expressionId, mid, note)
    return c.json(link, 201)
  } catch (error: any) {
    console.error('Error in POST /meanings/:mid/link:', error);
    return c.json({ error: 'Failed to link expression and meaning' }, 500)
  }
})

// GET /api/v1/ui-translations/:language
api.get('/ui-translations/:language', async (c) => {
  try {
    console.log('GET /api/v1/ui-translations/:language');
    const db = getDB(c)
    const language = c.req.param('language')
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '100')
    
    const translations = await db.getUITranslations(language, skip, limit)
    return c.json(translations)
  } catch (error: any) {
    console.error('Error in GET /ui-translations/:language:', error);
    return c.json({ error: 'Failed to fetch UI translations' }, 500)
  }
})

// POST /api/v1/ai/suggest
api.post('/ai/suggest', async (c) => {
  try {
    console.log('POST /api/v1/ai/suggest');
    // This is a mock implementation - in reality, this would call an AI service
    const body = await c.req.json()
    const { text, language } = body
    
    console.log('AI suggestion request:', { text, language });
    
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
    console.error('Error in POST /ai/suggest:', error);
    return c.json({ error: 'Failed to get AI suggestions' }, 500)
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

    // Create user
    const user = await db.createUser({
      username,
      email,
      password_hash,
      role: 'user' // Default role
    })

    // Remove password_hash from response
    const { password_hash: _, ...userResponse } = user

    return c.json({
      success: true,
      data: {
        user: userResponse
      }
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
    })

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

export default api