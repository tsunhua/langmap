export interface ApiResponse<T = any> {
  success: boolean
  data: T
  message?: string
  error?: string
  details?: any
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  skip: number
  limit: number
}

export interface ApiError {
  status?: number
  message: string
  data?: any
}
