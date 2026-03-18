import { Context, Next } from 'hono'
import { ApiError, InternalServerError } from '../types/error.js'

export async function errorHandler(c: Context, next: Next) {
  try {
    await next()
  } catch (error) {
    console.error('[ErrorHandler] Error:', error)

    if (error instanceof ApiError) {
      return c.json({
        error: error.code,
        message: error.message,
        details: error.details
      }, error.statusCode)
    }

    if (error instanceof Error) {
      console.error('Unhandled error:', {
        name: error.name,
        message: error.message,
        stack: error.stack
      })
      return c.json({
        error: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred'
      }, 500)
    }

    return c.json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected error occurred'
    }, 500)
  }
}
