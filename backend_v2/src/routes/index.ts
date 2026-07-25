import { Hono } from 'hono';
import stub from './_stub';

const api = new Hono();
api.route('/', stub);
export default api;
