import { Context } from 'hono'
import { ZodError } from 'zod'
import { ApiError } from '../types/error.js'
import { ErrorResponse } from '../utils/response.js'

/**
 * Global Error Handler for Hono.
 * Attach using: app.onError(errorHandler)
 */
export const errorHandler = (err: Error, c: Context) => {
  console.error('[GlobalErrorHandler]', err.name, err.message)
  
  // Detailed logging in development environment
  if (err instanceof Error && err.stack) {
    console.error(err.stack)
  }

  // Handle custom API errors
  if (err instanceof ApiError) {
    return c.json<ErrorResponse>({
      success: false,
      error: err.code,
      message: err.message,
      details: err.details
    }, err.statusCode as any)
  }

  // Automatically catch and format Zod validation errors
  if (err instanceof ZodError) {
    return c.json<ErrorResponse>({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Validation failed',
      details: (err as any).errors
    }, 400)
  }

  // Handle SyntaxError for bad JSON strings (often thrown by c.req.json())
  if (err instanceof SyntaxError && 'status' in err === false) {
    return c.json<ErrorResponse>({
      success: false,
      error: 'BAD_REQUEST',
      message: 'Invalid JSON payload'
    }, 400)
  }

  // Fallback for unexpected internal errors
  return c.json<ErrorResponse>({
    success: false,
    error: 'INTERNAL_SERVER_ERROR',
    message: 'An unexpected internal error occurred'
  }, 500)
}
