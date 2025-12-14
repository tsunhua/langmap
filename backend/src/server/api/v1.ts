// Hono API routes implementing the same interface as FastAPI backend
import { Hono, Context, Next } from 'hono'
import { createDatabaseService } from '../db'
import { D1Database } from '@cloudflare/workers-types'
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

// GET /api/v1/heatmap
api.get('/heatmap', async (c) => {
  try {
    console.log('GET /api/v1/heatmap');
    const db = getDB(c)
    const heatmapData = await db.getHeatmapData()
    console.log('Heatmap data fetched:', heatmapData);
    
    return c.json({
      data: heatmapData
    })
  } catch (error: any) {
    console.error('Error in GET /heatmap:', error);
    return c.json({ error: 'Failed to fetch heatmap data' }, 500)
  }
})

// GET /api/v1/statistics
api.get('/statistics', async (c) => {
  try {
    console.log('GET /api/v1/statistics');
    const db = getDB(c)
    const statistics = await db.getStatistics()
    console.log('Statistics fetched:', statistics);
    
    return c.json(statistics)
  } catch (error: any) {
    console.error('Error in GET /statistics:', error);
    return c.json({ error: 'Failed to fetch statistics' }, 500)
  }
})

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
api.get('/expressions', async (c) => {
  try {
    console.log('GET /api/v1/expressions');
    const db = getDB(c)
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '50')
    const language = c.req.query('language') || undefined
    const meaningIdParam = c.req.query('meaning_id');
    const meaningId = meaningIdParam ? parseInt(meaningIdParam) : undefined
    const expressions = await db.getExpressions(skip, limit, language, meaningId)
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

// PATCH /api/v1/expressions/:expr_id
api.patch('/expressions/:expr_id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    const body = await c.req.json()
    
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }
    
    // Get user info from middleware
    const user = c.get('user');
    const updatedBy = user.username;
    
    // Add updated_by to the expression data
    const expressionData = {
      ...body,
      updated_by: body.updated_by || updatedBy
    };
    
    const expression = await db.updateExpression(exprId, expressionData)
    if (!expression) {
      return c.json({ error: 'Expression not found' }, 404)
    }
    
    return c.json(expression)
  } catch (error: any) {
    console.error('Error in PATCH /expressions/:expr_id:', error);
    return c.json({ error: 'Failed to update expression', details: error.message }, 500)
  }
})

// DELETE /api/v1/expressions/:expr_id
api.delete('/expressions/:expr_id', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const exprId = parseInt(c.req.param('expr_id'))
    
    if (isNaN(exprId)) {
      return c.json({ error: 'Invalid expression ID' }, 400)
    }
    
    const success = await db.deleteExpression(exprId)
    if (!success) {
      return c.json({ error: 'Expression not found' }, 404)
    }
    
    // Clear statistics cache as we've deleted an expression
    db.clearStatisticsCache();
    
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
    const meaning_id = expression.meaning_id? expression.meaning_id : exprId
    const translations = await db.getExpressions(0, 100, language_code, meaning_id)
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


// GET /api/v1/ui-translations/:language
api.get('/ui-translations/:language', async (c) => {
  try {
    console.log('GET /api/v1/ui-translations/:language');
    const db = getDB(c)
    const language = c.req.param('language')
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '200')
    
    const translations = await db.getUITranslations(language, skip, limit)
    return c.json(translations)
  } catch (error: any) {
    console.error('Error in GET /ui-translations/:language:', error);
    return c.json({ error: 'Failed to fetch UI translations' }, 500)
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
    const verificationUrl = `${c.req.url.split('/api')[0]}/#/verify-email?token=${token}`;
    
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
    if (!user.email_verified) {
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

export default api