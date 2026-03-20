import { Context } from 'hono'

export interface SuccessResponse<T = any> {
  success: true
  data: T
  message?: string
}

export interface ErrorResponse {
  success: false
  error: string
  message?: string
  details?: any
}

export const success = <T = any>(c: Context, data: T, message?: string, status: number = 200) => {
  return c.json<SuccessResponse<T>>({
    success: true,
    data,
    message
  }, status)
}

export const created = <T = any>(c: Context, data: T, message?: string) => {
  return c.json<SuccessResponse<T>>({
    success: true,
    data,
    message
  }, 201)
}

export const noContent = (c: Context) => {
  return c.newResponse(null, 204)
}

export const badRequest = (c: Context, error: string, message?: string, details?: any) => {
  return c.json<ErrorResponse>({
    success: false,
    error,
    message,
    details
  }, 400)
}

export const unauthorized = (c: Context, error: string = 'Unauthorized', message?: string) => {
  return c.json<ErrorResponse>({
    success: false,
    error,
    message
  }, 401)
}

export const forbidden = (c: Context, error: string = 'Forbidden', message?: string) => {
  return c.json<ErrorResponse>({
    success: false,
    error,
    message
  }, 403)
}

export const notFound = (c: Context, resource: string = 'Resource') => {
  return c.json<ErrorResponse>({
    success: false,
    error: 'NOT_FOUND',
    message: `${resource} not found`
  }, 404)
}

export const conflict = (c: Context, error: string, message?: string, details?: any) => {
  return c.json<ErrorResponse>({
    success: false,
    error,
    message,
    details
  }, 409)
}

export const unprocessable = (c: Context, error: string, message?: string, details?: any) => {
  return c.json<ErrorResponse>({
    success: false,
    error,
    message,
    details
  }, 422)
}

export const internalError = (c: Context, error: string = 'Internal server error', message?: string) => {
  return c.json<ErrorResponse>({
    success: false,
    error: 'INTERNAL_SERVER_ERROR',
    message: message || error
  }, 500)
}

export const paginated = <T = any>(
  c: Context,
  data: T[],
  total: number,
  skip: number,
  limit: number
) => {
  return c.json<SuccessResponse<{
    items: T[]
    total: number
    skip: number
    limit: number
    hasMore: boolean
  }>>({
    success: true,
    data: {
      items: data,
      total,
      skip,
      limit,
      hasMore: skip + limit < total
    }
  })
}
