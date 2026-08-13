interface ApiErrorResponse {
  response?: {
    data?: {
      error?: string
      message?: string
    }
  }
}

export function apiErrorMessage(cause: unknown, fallback: string) {
  const response = (cause as ApiErrorResponse).response?.data
  if (response?.message || response?.error) return response.message || response.error || fallback
  return cause instanceof Error && cause.message ? cause.message : fallback
}
