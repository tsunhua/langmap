export interface ApiResponse<T = any> {
  code?: number
  message: string
  data?: T
  error?: string
  details?: any
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  skip: number
  limit: number
}
