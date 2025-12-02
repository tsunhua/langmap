import { Hono } from 'hono'
import { cors } from 'hono/cors'
import v1Api from './v1'

// Create a new Hono app for API routes
const api = new Hono()

// Add CORS middleware
api.use('*', cors())

// Mount v1 API routes
api.route('/v1', v1Api)

export default api