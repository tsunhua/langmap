// Hono API routes implementing the same interface as FastAPI backend
// This is the main entry point for API v1 routes
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { errorHandler } from '../middleware/error.js'
import type { Bindings } from '../types/bindings.js'
import apiRoutes from '../routes/index.js'

const api = new Hono<{ Bindings: Bindings }>()

api.use('*', cors())
api.use('*', errorHandler)

api.route('/', apiRoutes)

export default api
