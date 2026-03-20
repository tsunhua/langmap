import { Hono } from 'hono'
import { cors } from 'hono/cors'
import v1Api from './v1-new.js'

const api = new Hono()

api.use('*', cors())

api.route('/v1', v1Api)

export default api
