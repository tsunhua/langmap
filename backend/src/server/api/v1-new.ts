import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { errorHandler } from '../error/handler.js'
import type { Bindings } from '../types/bindings.js'
import apiRoutes from '../routes/index.js'

const api = new Hono<{ Bindings: Bindings }>()

api.use('*', cors())
api.onError(errorHandler)

api.route('/', apiRoutes)

export default api
