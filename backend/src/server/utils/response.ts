import type { ApiResponse } from '../types/api.js'
import type { ApiError } from '../types/error.js'

export function successResponse<T>(data: T, message?: string): ApiResponse<T> {
  return {
    code: 200,
    message: message || 'Success',
    data
  }
}

export function errorResponse(error: ApiError): ApiResponse {
  return {
    code: error.statusCode,
    message: error.message,
    error: error.code,
    details: error.details
  }
}

export function createResponse<T>(c: any, statusCode: number, data: T, message?: string) {
  return c.json({
    code: statusCode,
    message: message || 'Success',
    data
  }, statusCode)
}
